/*
  # Fix Security and Performance Issues - Part 1: Indexes and Cleanup

  ## Performance Improvements
  
  ### 1. Add Missing Foreign Key Indexes
  Adds indexes for all foreign key columns that were missing covering indexes to improve join performance.

  ### 2. Enable RLS on roles table
  Critical security fix - the roles table has policies but RLS wasn't enabled.

  ### 3. Drop Duplicate/Conflicting RLS Policies
  Removes duplicate permissive policies to simplify security model and improve performance.
*/

-- ============================================================================
-- PART 1: Add Missing Foreign Key Indexes
-- ============================================================================

-- document_versions indexes
CREATE INDEX IF NOT EXISTS idx_document_versions_uploaded_by ON document_versions(uploaded_by);

-- documents indexes
CREATE INDEX IF NOT EXISTS idx_documents_department_id ON documents(department_id);
CREATE INDEX IF NOT EXISTS idx_documents_organization_unit_id ON documents(organization_unit_id);
CREATE INDEX IF NOT EXISTS idx_documents_uploaded_by ON documents(uploaded_by);

-- folders indexes
CREATE INDEX IF NOT EXISTS idx_folders_created_by ON folders(created_by);
CREATE INDEX IF NOT EXISTS idx_folders_department_id ON folders(department_id);
CREATE INDEX IF NOT EXISTS idx_folders_organization_unit_id ON folders(organization_unit_id);

-- legal_holds indexes
CREATE INDEX IF NOT EXISTS idx_legal_holds_placed_by ON legal_holds(placed_by);
CREATE INDEX IF NOT EXISTS idx_legal_holds_released_by ON legal_holds(released_by);

-- metadata_schemas indexes
CREATE INDEX IF NOT EXISTS idx_metadata_schemas_created_by ON metadata_schemas(created_by);
CREATE INDEX IF NOT EXISTS idx_metadata_schemas_department_id ON metadata_schemas(department_id);

-- retention_rules indexes
CREATE INDEX IF NOT EXISTS idx_retention_rules_created_by ON retention_rules(created_by);
CREATE INDEX IF NOT EXISTS idx_retention_rules_department_id ON retention_rules(department_id);

-- user_role_assignments indexes
CREATE INDEX IF NOT EXISTS idx_user_role_assignments_department_id ON user_role_assignments(department_id);
CREATE INDEX IF NOT EXISTS idx_user_role_assignments_organization_unit_id ON user_role_assignments(organization_unit_id);
CREATE INDEX IF NOT EXISTS idx_user_role_assignments_program_id ON user_role_assignments(program_id);
CREATE INDEX IF NOT EXISTS idx_user_role_assignments_role_id ON user_role_assignments(role_id);

-- ============================================================================
-- PART 2: Enable RLS on roles table (CRITICAL SECURITY FIX)
-- ============================================================================

ALTER TABLE roles ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- PART 3: Drop Duplicate/Conflicting RLS Policies
-- ============================================================================

-- tenants: Remove duplicate "Users can view their tenant"
DROP POLICY IF EXISTS "Users can view their tenant" ON tenants;

-- user_profiles: Keep admin policies, remove basic user policies (will recreate optimized)
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;

-- user_role_assignments: Keep admin policy, remove user policy (will recreate)
DROP POLICY IF EXISTS "Users can view own role assignments" ON user_role_assignments;

-- organization_units: Remove duplicate
DROP POLICY IF EXISTS "Users can view org units in their tenant" ON organization_units;

-- folders: Remove older "in their programs" policies, keep tenant ones
DROP POLICY IF EXISTS "Users can view folders in their programs" ON folders;
DROP POLICY IF EXISTS "Users can create folders in their programs" ON folders;
DROP POLICY IF EXISTS "Users can update folders in their programs" ON folders;

-- documents: Remove older "in their programs" policies
DROP POLICY IF EXISTS "Users can view documents in their programs" ON documents;
DROP POLICY IF EXISTS "Users can insert documents in their programs" ON documents;
DROP POLICY IF EXISTS "Users can update documents in their programs" ON documents;

-- document_versions: Remove duplicate
DROP POLICY IF EXISTS "Users can view document versions they have access to" ON document_versions;

-- metadata_schemas: Remove duplicate
DROP POLICY IF EXISTS "Users can view metadata schemas in their programs" ON metadata_schemas;

-- metadata_schema_fields: Remove duplicate
DROP POLICY IF EXISTS "Users can view schema fields they have access to" ON metadata_schema_fields;

-- document_metadata: Remove duplicates
DROP POLICY IF EXISTS "Users can view document metadata they have access to" ON document_metadata;
DROP POLICY IF EXISTS "Users can update document metadata they have access to" ON document_metadata;

-- retention_rules: Remove old policies (will keep tenant-scoped ones)
DROP POLICY IF EXISTS "Users can view retention rules in their programs" ON retention_rules;
DROP POLICY IF EXISTS "Department heads can manage retention rules" ON retention_rules;
DROP POLICY IF EXISTS "Department heads can update retention rules" ON retention_rules;

-- legal_holds: Remove old policies
DROP POLICY IF EXISTS "Users can view legal holds on documents they can access" ON legal_holds;
DROP POLICY IF EXISTS "Admins can place legal holds" ON legal_holds;
DROP POLICY IF EXISTS "Admins can release legal holds" ON legal_holds;

-- audit_events: Remove duplicate and overly permissive policy
DROP POLICY IF EXISTS "Users can view audit events for documents they can access" ON audit_events;
DROP POLICY IF EXISTS "System can insert audit events" ON audit_events;
