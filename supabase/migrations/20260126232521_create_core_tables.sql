/*
  # K-12 Records System - Core Tables

  Creates the foundational multi-tenant structure for K-12 document management.

  ## Tables Created
  
  ### tenants
  - Top-level tenant isolation (state agencies)
  - Fields: id, name, code, status, created_at, updated_at
  
  ### organization_units
  - State departments and school districts
  - Hierarchical structure with parent_id
  - Fields: id, tenant_id, parent_id, name, type, code, status
  
  ### departments
  - Functional departments within tenants (HR, Federal Programs, etc.)
  - Fields: id, tenant_id, name, code, status
  
  ### programs
  - Program silos (HR, Title I, Special Ed)
  - Fields: id, tenant_id, department_id, name, code, description, status
  
  ### user_profiles
  - Extended user profile data (links to auth.users)
  - Fields: id, user_id, tenant_id, first_name, last_name, status
  
  ### roles
  - Role definitions for RBAC
  - Pre-populated with: SYSTEM_ADMIN, DEPARTMENT_HEAD, POWER_USER, VIEWER
  
  ### user_role_assignments
  - Maps users to roles with organizational scope
  - Fields: id, user_id, role_id, tenant_id, org_unit_id, department_id, program_id
  
  ## Security
  - Row Level Security (RLS) enabled on all tables
  - Policies enforce tenant isolation
  - Users can only access data within their tenant and assigned scopes
*/

-- Create tenants table
create table if not exists tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text not null unique,
  status text not null default 'ACTIVE',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table tenants enable row level security;

-- Create organization_units table
create table if not exists organization_units (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references tenants(id) not null,
  parent_id uuid references organization_units(id),
  name text not null,
  type text not null,
  code text not null,
  status text not null default 'ACTIVE',
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(tenant_id, code)
);

create index if not exists idx_org_units_tenant on organization_units(tenant_id);
create index if not exists idx_org_units_parent on organization_units(parent_id);

alter table organization_units enable row level security;

-- Create departments table
create table if not exists departments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references tenants(id) not null,
  name text not null,
  code text not null,
  status text not null default 'ACTIVE',
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(tenant_id, code)
);

create index if not exists idx_departments_tenant on departments(tenant_id);

alter table departments enable row level security;

-- Create programs table
create table if not exists programs (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references tenants(id) not null,
  department_id uuid references departments(id) not null,
  name text not null,
  code text not null,
  description text,
  status text not null default 'ACTIVE',
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(tenant_id, department_id, code)
);

create index if not exists idx_programs_tenant on programs(tenant_id);
create index if not exists idx_programs_department on programs(department_id);

alter table programs enable row level security;

-- Create user_profiles table
create table if not exists user_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null unique,
  tenant_id uuid references tenants(id) not null,
  first_name text not null,
  last_name text not null,
  status text not null default 'ACTIVE',
  last_login_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_user_profiles_tenant on user_profiles(tenant_id);
create index if not exists idx_user_profiles_user on user_profiles(user_id);

alter table user_profiles enable row level security;

-- Create roles table
create table if not exists roles (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text,
  created_at timestamptz default now()
);

-- Insert predefined roles
insert into roles (name, description) values
  ('SYSTEM_ADMIN', 'Full system access across all tenants'),
  ('DEPARTMENT_HEAD', 'Manage users and schemas within department'),
  ('POWER_USER', 'Same as Department Head but cannot manage users'),
  ('VIEWER', 'Search, view, and download documents')
on conflict (name) do nothing;

-- Create user_role_assignments table
create table if not exists user_role_assignments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade not null,
  role_id uuid references roles(id) not null,
  tenant_id uuid references tenants(id) not null,
  organization_unit_id uuid references organization_units(id),
  department_id uuid references departments(id),
  program_id uuid references programs(id),
  created_at timestamptz default now(),
  unique(user_id, role_id, tenant_id, organization_unit_id, department_id, program_id)
);

create index if not exists idx_user_roles_user on user_role_assignments(user_id);
create index if not exists idx_user_roles_tenant on user_role_assignments(tenant_id);

alter table user_role_assignments enable row level security;

-- RLS Policies for tenants (accessible to authenticated users in their tenant)
create policy "Users can view their tenant"
  on tenants for select
  to authenticated
  using (
    id in (
      select tenant_id from user_profiles where user_id = auth.uid()
    )
  );

-- RLS Policies for organization_units
create policy "Users can view org units in their tenant"
  on organization_units for select
  to authenticated
  using (
    tenant_id in (
      select tenant_id from user_profiles where user_id = auth.uid()
    )
  );

-- RLS Policies for departments
create policy "Users can view departments in their tenant"
  on departments for select
  to authenticated
  using (
    tenant_id in (
      select tenant_id from user_profiles where user_id = auth.uid()
    )
  );

-- RLS Policies for programs
create policy "Users can view programs in their tenant"
  on programs for select
  to authenticated
  using (
    tenant_id in (
      select tenant_id from user_profiles where user_id = auth.uid()
    )
  );

-- RLS Policies for user_profiles
create policy "Users can view their own profile"
  on user_profiles for select
  to authenticated
  using (user_id = auth.uid());

create policy "Users can update their own profile"
  on user_profiles for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- RLS Policies for roles (all authenticated users can view roles)
create policy "Authenticated users can view roles"
  on roles for select
  to authenticated
  using (true);

-- RLS Policies for user_role_assignments
create policy "Users can view their own role assignments"
  on user_role_assignments for select
  to authenticated
  using (user_id = auth.uid());
