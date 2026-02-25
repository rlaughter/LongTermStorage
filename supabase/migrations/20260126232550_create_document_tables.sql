/*
  # K-12 Records System - Document Management Tables

  Creates tables for document storage, folders, metadata, and versioning.

  ## Tables Created
  
  ### folders
  - Optional folder structure for organizing documents
  - Hierarchical with parent_id
  - Scoped by tenant, org_unit, department, program
  
  ### documents
  - Core document records with metadata
  - Links to Supabase Storage for file storage
  - Fields for employee_id, student_id, school_year, campus, category
  - Status tracking for processing
  
  ### document_versions
  - Version history for documents
  - Tracks each version with storage path
  
  ### metadata_schemas
  - Schema definitions per program and category
  - Defines custom metadata fields
  
  ### metadata_schema_fields
  - Field definitions for metadata schemas
  - Includes field type, validation rules, required flag
  
  ### document_metadata
  - Key-value metadata storage for documents
  - Links to metadata schema fields
  
  ## Security
  - RLS enabled on all tables
  - Users can only access documents in programs they have access to
  - Program siloing is strictly enforced
*/

-- Create folders table
create table if not exists folders (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references tenants(id) not null,
  organization_unit_id uuid references organization_units(id) not null,
  department_id uuid references departments(id) not null,
  program_id uuid references programs(id) not null,
  parent_id uuid references folders(id),
  name text not null,
  description text,
  created_by uuid references auth.users(id) not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_folders_tenant on folders(tenant_id);
create index if not exists idx_folders_program on folders(program_id);
create index if not exists idx_folders_parent on folders(parent_id);

alter table folders enable row level security;

-- Create documents table
create table if not exists documents (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references tenants(id) not null,
  organization_unit_id uuid references organization_units(id) not null,
  department_id uuid references departments(id) not null,
  program_id uuid references programs(id) not null,
  folder_id uuid references folders(id),
  filename text not null,
  original_filename text not null,
  file_type text not null,
  file_size_bytes bigint not null,
  storage_path text not null,
  mime_type text not null,
  status text not null default 'ACTIVE',
  extracted_text text,
  employee_id text,
  student_id text,
  school_year text,
  campus text,
  category text,
  document_date date,
  uploaded_by uuid references auth.users(id) not null,
  uploaded_at timestamptz default now(),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_documents_tenant on documents(tenant_id);
create index if not exists idx_documents_program on documents(program_id);
create index if not exists idx_documents_folder on documents(folder_id);
create index if not exists idx_documents_employee_id on documents(employee_id);
create index if not exists idx_documents_student_id on documents(student_id);
create index if not exists idx_documents_school_year on documents(school_year);
create index if not exists idx_documents_category on documents(category);

alter table documents enable row level security;

-- Create document_versions table
create table if not exists document_versions (
  id uuid primary key default gen_random_uuid(),
  document_id uuid references documents(id) on delete cascade not null,
  version_number int not null,
  filename text not null,
  file_size_bytes bigint not null,
  storage_path text not null,
  mime_type text not null,
  uploaded_by uuid references auth.users(id) not null,
  created_at timestamptz default now(),
  unique(document_id, version_number)
);

create index if not exists idx_doc_versions_document on document_versions(document_id);

alter table document_versions enable row level security;

-- Create metadata_schemas table
create table if not exists metadata_schemas (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references tenants(id) not null,
  department_id uuid references departments(id) not null,
  program_id uuid references programs(id) not null,
  category text not null,
  name text not null,
  description text,
  status text not null default 'ACTIVE',
  created_by uuid references auth.users(id) not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(tenant_id, department_id, program_id, category)
);

create index if not exists idx_metadata_schemas_tenant on metadata_schemas(tenant_id);
create index if not exists idx_metadata_schemas_program on metadata_schemas(program_id);

alter table metadata_schemas enable row level security;

-- Create metadata_schema_fields table
create table if not exists metadata_schema_fields (
  id uuid primary key default gen_random_uuid(),
  schema_id uuid references metadata_schemas(id) on delete cascade not null,
  field_key text not null,
  field_name text not null,
  field_type text not null,
  required boolean default false,
  display_order int not null default 0,
  validation_rules jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(schema_id, field_key)
);

create index if not exists idx_schema_fields_schema on metadata_schema_fields(schema_id);

alter table metadata_schema_fields enable row level security;

-- Create document_metadata table
create table if not exists document_metadata (
  id uuid primary key default gen_random_uuid(),
  document_id uuid references documents(id) on delete cascade not null,
  field_key text not null,
  field_value text not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(document_id, field_key)
);

create index if not exists idx_doc_metadata_document on document_metadata(document_id);

alter table document_metadata enable row level security;

-- RLS Policies for folders (users can access folders in programs they have access to)
create policy "Users can view folders in their programs"
  on folders for select
  to authenticated
  using (
    program_id in (
      select program_id from user_role_assignments 
      where user_id = auth.uid() and program_id is not null
    )
  );

create policy "Users can create folders in their programs"
  on folders for insert
  to authenticated
  with check (
    program_id in (
      select program_id from user_role_assignments 
      where user_id = auth.uid() and program_id is not null
    )
  );

create policy "Users can update folders in their programs"
  on folders for update
  to authenticated
  using (
    program_id in (
      select program_id from user_role_assignments 
      where user_id = auth.uid() and program_id is not null
    )
  )
  with check (
    program_id in (
      select program_id from user_role_assignments 
      where user_id = auth.uid() and program_id is not null
    )
  );

-- RLS Policies for documents (strict program siloing)
create policy "Users can view documents in their programs"
  on documents for select
  to authenticated
  using (
    program_id in (
      select program_id from user_role_assignments 
      where user_id = auth.uid() and program_id is not null
    )
  );

create policy "Users can insert documents in their programs"
  on documents for insert
  to authenticated
  with check (
    program_id in (
      select program_id from user_role_assignments 
      where user_id = auth.uid() and program_id is not null
    )
  );

create policy "Users can update documents in their programs"
  on documents for update
  to authenticated
  using (
    program_id in (
      select program_id from user_role_assignments 
      where user_id = auth.uid() and program_id is not null
    )
  )
  with check (
    program_id in (
      select program_id from user_role_assignments 
      where user_id = auth.uid() and program_id is not null
    )
  );

create policy "Users can delete documents in their programs"
  on documents for delete
  to authenticated
  using (
    program_id in (
      select program_id from user_role_assignments 
      where user_id = auth.uid() and program_id is not null
    )
  );

-- RLS Policies for document_versions
create policy "Users can view document versions they have access to"
  on document_versions for select
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

-- RLS Policies for metadata_schemas
create policy "Users can view metadata schemas in their programs"
  on metadata_schemas for select
  to authenticated
  using (
    program_id in (
      select program_id from user_role_assignments 
      where user_id = auth.uid() and program_id is not null
    )
  );

-- RLS Policies for metadata_schema_fields
create policy "Users can view schema fields they have access to"
  on metadata_schema_fields for select
  to authenticated
  using (
    schema_id in (
      select id from metadata_schemas 
      where program_id in (
        select program_id from user_role_assignments 
        where user_id = auth.uid() and program_id is not null
      )
    )
  );

-- RLS Policies for document_metadata
create policy "Users can view document metadata they have access to"
  on document_metadata for select
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

create policy "Users can update document metadata they have access to"
  on document_metadata for update
  to authenticated
  using (
    document_id in (
      select id from documents 
      where program_id in (
        select program_id from user_role_assignments 
        where user_id = auth.uid() and program_id is not null
      )
    )
  )
  with check (
    document_id in (
      select id from documents 
      where program_id in (
        select program_id from user_role_assignments 
        where user_id = auth.uid() and program_id is not null
      )
    )
  );
