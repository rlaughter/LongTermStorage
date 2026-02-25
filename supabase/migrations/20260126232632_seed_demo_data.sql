/*
  # K-12 Records System - Demo Seed Data

  Creates demo tenant, departments, programs, and retention rules for local development and testing.

  ## Data Created
  
  ### Demo Tenant
  - State Education Agency tenant
  
  ### Organization Units
  - State agency and 3 school districts
  
  ### Departments
  - Human Resources, Federal Programs, Special Education, Finance
  
  ### Programs
  - HR Documents, Title I, Special Education Services, Financial Records
  
  ### Retention Rules
  - 7 year, 10 year, and indefinite retention examples
  
  ## Notes
  - User profiles and role assignments will be created when users sign up
  - Adjust the data as needed for your environment
*/

-- Insert demo tenant
insert into tenants (id, name, code, status) values
  ('00000000-0000-0000-0000-000000000001', 'State Education Agency', 'SEA-DEMO', 'ACTIVE')
on conflict (id) do nothing;

-- Insert organization units
insert into organization_units (id, tenant_id, parent_id, name, type, code, status) values
  ('00000000-0000-0000-0001-000000000001', '00000000-0000-0000-0000-000000000001', null, 'State Education Agency', 'STATE', 'SEA', 'ACTIVE'),
  ('00000000-0000-0000-0001-000000000002', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0001-000000000001', 'Central School District', 'DISTRICT', 'CENTRAL-001', 'ACTIVE'),
  ('00000000-0000-0000-0001-000000000003', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0001-000000000001', 'Riverside School District', 'DISTRICT', 'RIVERSIDE-002', 'ACTIVE'),
  ('00000000-0000-0000-0001-000000000004', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0001-000000000001', 'Mountain View School District', 'DISTRICT', 'MOUNTAIN-003', 'ACTIVE')
on conflict (id) do nothing;

-- Insert departments
insert into departments (id, tenant_id, name, code, status) values
  ('00000000-0000-0000-0002-000000000001', '00000000-0000-0000-0000-000000000001', 'Human Resources', 'HR', 'ACTIVE'),
  ('00000000-0000-0000-0002-000000000002', '00000000-0000-0000-0000-000000000001', 'Federal Programs', 'FED-PROG', 'ACTIVE'),
  ('00000000-0000-0000-0002-000000000003', '00000000-0000-0000-0000-000000000001', 'Special Education', 'SPED', 'ACTIVE'),
  ('00000000-0000-0000-0002-000000000004', '00000000-0000-0000-0000-000000000001', 'Finance', 'FINANCE', 'ACTIVE')
on conflict (id) do nothing;

-- Insert programs
insert into programs (id, tenant_id, department_id, name, code, description, status) values
  ('00000000-0000-0000-0003-000000000001', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0002-000000000001', 'Human Resources Documents', 'HR-DOCS', 'Employee records and HR documentation', 'ACTIVE'),
  ('00000000-0000-0000-0003-000000000002', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0002-000000000002', 'Title I Program', 'TITLE-I', 'Title I federal program documentation', 'ACTIVE'),
  ('00000000-0000-0000-0003-000000000003', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0002-000000000003', 'Special Education Services', 'SPED-SERVICES', 'Special education IEPs and related documents', 'ACTIVE'),
  ('00000000-0000-0000-0003-000000000004', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0002-000000000004', 'Financial Records', 'FIN-RECORDS', 'Financial documents and audit trails', 'ACTIVE')
on conflict (id) do nothing;

-- Note: Retention rules will be created by users since they require created_by to reference an actual user
-- We'll create placeholder retention rules using a system UUID
-- In production, these should be created by actual admin users

-- Create a helper function to get or create a system user ID for seed data
do $$
declare
  system_user_id uuid;
begin
  -- Try to get the first authenticated user, or use a placeholder
  select id into system_user_id from auth.users limit 1;
  
  if system_user_id is null then
    -- Use a placeholder UUID for seed data
    -- In production, actual users will create these
    system_user_id := '00000000-0000-0000-0000-000000000000';
  end if;

  -- Insert retention rules if a user exists
  if exists (select 1 from auth.users where id = system_user_id) then
    insert into retention_rules (tenant_id, department_id, program_id, category, name, retention_period_years, description, auto_delete_enabled, status, created_by) values
      ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0002-000000000001', '00000000-0000-0000-0003-000000000001', 'PERSONNEL', 'Employee Records - 7 Year', 7, 'Standard employee records retention', false, 'ACTIVE', system_user_id),
      ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0002-000000000002', '00000000-0000-0000-0003-000000000002', 'GRANTS', 'Title I Grant Documents - 10 Year', 10, 'Federal program grant documentation', false, 'ACTIVE', system_user_id),
      ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0002-000000000003', '00000000-0000-0000-0003-000000000003', 'IEP', 'Special Education IEPs - Indefinite', 999, 'Special education IEPs kept indefinitely', false, 'ACTIVE', system_user_id),
      ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0002-000000000004', '00000000-0000-0000-0003-000000000004', 'AUDIT', 'Financial Audit Records - 10 Year', 10, 'Financial audit and compliance records', false, 'ACTIVE', system_user_id)
    on conflict (tenant_id, department_id, program_id, category) do nothing;
  end if;
end $$;
