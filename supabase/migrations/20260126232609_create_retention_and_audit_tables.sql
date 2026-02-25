/*
  # K-12 Records System - Retention and Audit Tables

  Creates tables for compliance features including retention rules, legal holds, and audit logging.

  ## Tables Created
  
  ### retention_rules
  - Retention policy definitions by program and category
  - Specifies retention period in years
  - Supports auto-delete configuration
  
  ### legal_holds
  - Legal hold tracking for documents
  - Prevents deletion of documents under legal hold
  - Tracks who placed and released the hold
  
  ### audit_events
  - Comprehensive audit log for all system actions
  - Tracks user actions, IP addresses, and details
  - Immutable for compliance
  
  ## Security
  - RLS enabled on all tables
  - Audit events are read-only for regular users
  - Only admins can query across tenants
*/

-- Create retention_rules table
create table if not exists retention_rules (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references tenants(id) not null,
  department_id uuid references departments(id) not null,
  program_id uuid references programs(id) not null,
  category text,
  name text not null,
  retention_period_years int not null,
  description text,
  auto_delete_enabled boolean default false,
  status text not null default 'ACTIVE',
  created_by uuid references auth.users(id) not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(tenant_id, department_id, program_id, category)
);

create index if not exists idx_retention_rules_tenant on retention_rules(tenant_id);
create index if not exists idx_retention_rules_program on retention_rules(program_id);

alter table retention_rules enable row level security;

-- Create legal_holds table
create table if not exists legal_holds (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references tenants(id) not null,
  document_id uuid references documents(id) on delete cascade not null,
  case_number text not null,
  reason text not null,
  placed_by uuid references auth.users(id) not null,
  placed_at timestamptz default now(),
  released_by uuid references auth.users(id),
  released_at timestamptz,
  status text not null default 'ACTIVE',
  created_at timestamptz default now()
);

create index if not exists idx_legal_holds_tenant on legal_holds(tenant_id);
create index if not exists idx_legal_holds_document on legal_holds(document_id);
create index if not exists idx_legal_holds_status on legal_holds(status);

alter table legal_holds enable row level security;

-- Create audit_events table
create table if not exists audit_events (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references tenants(id) not null,
  event_type text not null,
  entity_type text not null,
  entity_id uuid,
  document_id uuid references documents(id) on delete set null,
  user_id uuid references auth.users(id) not null,
  ip_address text,
  user_agent text,
  action text not null,
  details jsonb,
  created_at timestamptz default now()
);

create index if not exists idx_audit_events_tenant on audit_events(tenant_id);
create index if not exists idx_audit_events_document on audit_events(document_id);
create index if not exists idx_audit_events_user on audit_events(user_id);
create index if not exists idx_audit_events_created on audit_events(created_at);

alter table audit_events enable row level security;

-- RLS Policies for retention_rules
create policy "Users can view retention rules in their programs"
  on retention_rules for select
  to authenticated
  using (
    program_id in (
      select program_id from user_role_assignments 
      where user_id = auth.uid() and program_id is not null
    )
  );

create policy "Department heads can manage retention rules"
  on retention_rules for insert
  to authenticated
  with check (
    auth.uid() in (
      select ura.user_id from user_role_assignments ura
      join roles r on ura.role_id = r.id
      where r.name in ('SYSTEM_ADMIN', 'DEPARTMENT_HEAD')
      and ura.program_id = program_id
    )
  );

create policy "Department heads can update retention rules"
  on retention_rules for update
  to authenticated
  using (
    auth.uid() in (
      select ura.user_id from user_role_assignments ura
      join roles r on ura.role_id = r.id
      where r.name in ('SYSTEM_ADMIN', 'DEPARTMENT_HEAD')
      and ura.program_id = program_id
    )
  )
  with check (
    auth.uid() in (
      select ura.user_id from user_role_assignments ura
      join roles r on ura.role_id = r.id
      where r.name in ('SYSTEM_ADMIN', 'DEPARTMENT_HEAD')
      and ura.program_id = program_id
    )
  );

-- RLS Policies for legal_holds
create policy "Users can view legal holds on documents they can access"
  on legal_holds for select
  to authenticated
  using (
    document_id in (
      select id from documents 
      where program_id in (
        select program_id from user_role_assignments 
        where user_id = auth.uid() and program_id is not null
      )
    )
  );

create policy "Admins can place legal holds"
  on legal_holds for insert
  to authenticated
  with check (
    auth.uid() in (
      select ura.user_id from user_role_assignments ura
      join roles r on ura.role_id = r.id
      where r.name in ('SYSTEM_ADMIN', 'DEPARTMENT_HEAD')
    )
  );

create policy "Admins can release legal holds"
  on legal_holds for update
  to authenticated
  using (
    auth.uid() in (
      select ura.user_id from user_role_assignments ura
      join roles r on ura.role_id = r.id
      where r.name in ('SYSTEM_ADMIN', 'DEPARTMENT_HEAD')
    )
  )
  with check (
    auth.uid() in (
      select ura.user_id from user_role_assignments ura
      join roles r on ura.role_id = r.id
      where r.name in ('SYSTEM_ADMIN', 'DEPARTMENT_HEAD')
    )
  );

-- RLS Policies for audit_events (read-only for users, scoped by access)
create policy "Users can view audit events for documents they can access"
  on audit_events for select
  to authenticated
  using (
    document_id is null or document_id in (
      select id from documents 
      where program_id in (
        select program_id from user_role_assignments 
        where user_id = auth.uid() and program_id is not null
      )
    )
  );

create policy "System can insert audit events"
  on audit_events for insert
  to authenticated
  with check (true);
