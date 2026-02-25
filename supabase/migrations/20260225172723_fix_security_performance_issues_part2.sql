/*
  # Fix Security and Performance Issues - Part 2: Optimized RLS Policies

  ## RLS Policy Optimization
  
  ### 1. Use (select auth.uid()) Pattern
  All policies now use `(select auth.uid())` instead of `auth.uid()` to prevent 
  re-evaluation on each row, providing better query performance at scale.

  ### 2. Consolidated Policies
  Replaces duplicate policies with single, clear policies for each operation.

  ### 3. Secure audit_events Insert
  Restricts audit event insertion to only allow users to log their own actions.
*/

-- ============================================================================
-- User Profiles: Combined view/update policy
-- ============================================================================

CREATE POLICY "Users can manage own profile"
  ON user_profiles FOR ALL
  TO authenticated
  USING (user_id = (select auth.uid()))
  WITH CHECK (user_id = (select auth.uid()));

-- ============================================================================
-- User Role Assignments: Users view their own
-- ============================================================================

CREATE POLICY "Users can view own role assignments"
  ON user_role_assignments FOR SELECT
  TO authenticated
  USING (user_id = (select auth.uid()));

-- ============================================================================
-- Audit Events: Secure insert and view policies
-- ============================================================================

CREATE POLICY "Users can view accessible audit events"
  ON audit_events FOR SELECT
  TO authenticated
  USING (
    document_id IS NULL 
    OR document_id IN (
      SELECT id FROM documents 
      WHERE program_id IN (
        SELECT program_id FROM user_role_assignments 
        WHERE user_id = (select auth.uid()) AND program_id IS NOT NULL
      )
    )
  );

CREATE POLICY "Users can log own audit events"
  ON audit_events FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (select auth.uid()));

-- ============================================================================
-- Optimize Existing Policies with (select auth.uid())
-- ============================================================================

-- Recreate tenants policy with optimization
DROP POLICY IF EXISTS "Users can view their own tenant" ON tenants;
CREATE POLICY "Users can view their own tenant"
  ON tenants FOR SELECT
  TO authenticated
  USING (
    id IN (
      SELECT tenant_id FROM user_profiles 
      WHERE user_id = (select auth.uid())
    )
  );

-- Recreate organization_units policy with optimization
DROP POLICY IF EXISTS "Users can view organization units in their tenant" ON organization_units;
CREATE POLICY "Users can view organization units in their tenant"
  ON organization_units FOR SELECT
  TO authenticated
  USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles 
      WHERE user_id = (select auth.uid())
    )
  );

-- Recreate folders policies with optimization
DROP POLICY IF EXISTS "Users can view folders in their tenant" ON folders;
CREATE POLICY "Users can view folders in their tenant"
  ON folders FOR SELECT
  TO authenticated
  USING (
    program_id IN (
      SELECT program_id FROM user_role_assignments 
      WHERE user_id = (select auth.uid()) AND program_id IS NOT NULL
    )
  );

DROP POLICY IF EXISTS "Users can create folders in their tenant" ON folders;
CREATE POLICY "Users can create folders in their tenant"
  ON folders FOR INSERT
  TO authenticated
  WITH CHECK (
    program_id IN (
      SELECT program_id FROM user_role_assignments 
      WHERE user_id = (select auth.uid()) AND program_id IS NOT NULL
    )
  );

DROP POLICY IF EXISTS "Users can update folders in their tenant" ON folders;
CREATE POLICY "Users can update folders in their tenant"
  ON folders FOR UPDATE
  TO authenticated
  USING (
    program_id IN (
      SELECT program_id FROM user_role_assignments 
      WHERE user_id = (select auth.uid()) AND program_id IS NOT NULL
    )
  )
  WITH CHECK (
    program_id IN (
      SELECT program_id FROM user_role_assignments 
      WHERE user_id = (select auth.uid()) AND program_id IS NOT NULL
    )
  );

-- Recreate documents policies with optimization
DROP POLICY IF EXISTS "Users can view documents in accessible programs" ON documents;
CREATE POLICY "Users can view documents in accessible programs"
  ON documents FOR SELECT
  TO authenticated
  USING (
    program_id IN (
      SELECT program_id FROM user_role_assignments 
      WHERE user_id = (select auth.uid()) AND program_id IS NOT NULL
    )
  );

DROP POLICY IF EXISTS "Users can create documents in accessible programs" ON documents;
CREATE POLICY "Users can create documents in accessible programs"
  ON documents FOR INSERT
  TO authenticated
  WITH CHECK (
    program_id IN (
      SELECT program_id FROM user_role_assignments 
      WHERE user_id = (select auth.uid()) AND program_id IS NOT NULL
    )
  );

DROP POLICY IF EXISTS "Users can update documents in accessible programs" ON documents;
CREATE POLICY "Users can update documents in accessible programs"
  ON documents FOR UPDATE
  TO authenticated
  USING (
    program_id IN (
      SELECT program_id FROM user_role_assignments 
      WHERE user_id = (select auth.uid()) AND program_id IS NOT NULL
    )
  )
  WITH CHECK (
    program_id IN (
      SELECT program_id FROM user_role_assignments 
      WHERE user_id = (select auth.uid()) AND program_id IS NOT NULL
    )
  );

DROP POLICY IF EXISTS "Users can delete documents in their programs" ON documents;
CREATE POLICY "Users can delete documents in their programs"
  ON documents FOR DELETE
  TO authenticated
  USING (
    program_id IN (
      SELECT program_id FROM user_role_assignments 
      WHERE user_id = (select auth.uid()) AND program_id IS NOT NULL
    )
  );

-- Recreate document_versions policy with optimization
DROP POLICY IF EXISTS "Users can view document versions in accessible programs" ON document_versions;
CREATE POLICY "Users can view document versions in accessible programs"
  ON document_versions FOR SELECT
  TO authenticated
  USING (
    document_id IN (
      SELECT id FROM documents 
      WHERE program_id IN (
        SELECT program_id FROM user_role_assignments 
        WHERE user_id = (select auth.uid()) AND program_id IS NOT NULL
      )
    )
  );

DROP POLICY IF EXISTS "Users can create document versions in accessible programs" ON document_versions;
CREATE POLICY "Users can create document versions in accessible programs"
  ON document_versions FOR INSERT
  TO authenticated
  WITH CHECK (
    document_id IN (
      SELECT id FROM documents 
      WHERE program_id IN (
        SELECT program_id FROM user_role_assignments 
        WHERE user_id = (select auth.uid()) AND program_id IS NOT NULL
      )
    )
  );

-- Recreate metadata_schemas policy with optimization
DROP POLICY IF EXISTS "Users can view metadata schemas in their tenant" ON metadata_schemas;
CREATE POLICY "Users can view metadata schemas in their tenant"
  ON metadata_schemas FOR SELECT
  TO authenticated
  USING (
    program_id IN (
      SELECT program_id FROM user_role_assignments 
      WHERE user_id = (select auth.uid()) AND program_id IS NOT NULL
    )
  );

-- Recreate metadata_schema_fields policy with optimization
DROP POLICY IF EXISTS "Users can view metadata schema fields in their tenant" ON metadata_schema_fields;
CREATE POLICY "Users can view metadata schema fields in their tenant"
  ON metadata_schema_fields FOR SELECT
  TO authenticated
  USING (
    schema_id IN (
      SELECT id FROM metadata_schemas 
      WHERE program_id IN (
        SELECT program_id FROM user_role_assignments 
        WHERE user_id = (select auth.uid()) AND program_id IS NOT NULL
      )
    )
  );

-- Recreate document_metadata policies with optimization
DROP POLICY IF EXISTS "Users can view document metadata in accessible programs" ON document_metadata;
CREATE POLICY "Users can view document metadata in accessible programs"
  ON document_metadata FOR SELECT
  TO authenticated
  USING (
    document_id IN (
      SELECT id FROM documents 
      WHERE program_id IN (
        SELECT program_id FROM user_role_assignments 
        WHERE user_id = (select auth.uid()) AND program_id IS NOT NULL
      )
    )
  );

DROP POLICY IF EXISTS "Users can update document metadata in accessible programs" ON document_metadata;
CREATE POLICY "Users can update document metadata in accessible programs"
  ON document_metadata FOR UPDATE
  TO authenticated
  USING (
    document_id IN (
      SELECT id FROM documents 
      WHERE program_id IN (
        SELECT program_id FROM user_role_assignments 
        WHERE user_id = (select auth.uid()) AND program_id IS NOT NULL
      )
    )
  )
  WITH CHECK (
    document_id IN (
      SELECT id FROM documents 
      WHERE program_id IN (
        SELECT program_id FROM user_role_assignments 
        WHERE user_id = (select auth.uid()) AND program_id IS NOT NULL
      )
    )
  );

DROP POLICY IF EXISTS "Users can create document metadata in accessible programs" ON document_metadata;
CREATE POLICY "Users can create document metadata in accessible programs"
  ON document_metadata FOR INSERT
  TO authenticated
  WITH CHECK (
    document_id IN (
      SELECT id FROM documents 
      WHERE program_id IN (
        SELECT program_id FROM user_role_assignments 
        WHERE user_id = (select auth.uid()) AND program_id IS NOT NULL
      )
    )
  );

-- Recreate retention_rules policies with optimization
DROP POLICY IF EXISTS "Users can view retention rules in their tenant" ON retention_rules;
CREATE POLICY "Users can view retention rules in their tenant"
  ON retention_rules FOR SELECT
  TO authenticated
  USING (
    program_id IN (
      SELECT program_id FROM user_role_assignments 
      WHERE user_id = (select auth.uid()) AND program_id IS NOT NULL
    )
  );

DROP POLICY IF EXISTS "Admins can insert retention rules in their tenant" ON retention_rules;
CREATE POLICY "Admins can insert retention rules in their tenant"
  ON retention_rules FOR INSERT
  TO authenticated
  WITH CHECK (
    (select auth.uid()) IN (
      SELECT ura.user_id FROM user_role_assignments ura
      JOIN roles r ON ura.role_id = r.id
      WHERE r.name IN ('SYSTEM_ADMIN', 'DEPARTMENT_HEAD')
      AND ura.program_id = program_id
    )
  );

DROP POLICY IF EXISTS "Admins can update retention rules in their tenant" ON retention_rules;
CREATE POLICY "Admins can update retention rules in their tenant"
  ON retention_rules FOR UPDATE
  TO authenticated
  USING (
    (select auth.uid()) IN (
      SELECT ura.user_id FROM user_role_assignments ura
      JOIN roles r ON ura.role_id = r.id
      WHERE r.name IN ('SYSTEM_ADMIN', 'DEPARTMENT_HEAD')
      AND ura.program_id = program_id
    )
  )
  WITH CHECK (
    (select auth.uid()) IN (
      SELECT ura.user_id FROM user_role_assignments ura
      JOIN roles r ON ura.role_id = r.id
      WHERE r.name IN ('SYSTEM_ADMIN', 'DEPARTMENT_HEAD')
      AND ura.program_id = program_id
    )
  );

-- Recreate legal_holds policies with optimization
DROP POLICY IF EXISTS "Users can view legal holds in their tenant" ON legal_holds;
CREATE POLICY "Users can view legal holds in their tenant"
  ON legal_holds FOR SELECT
  TO authenticated
  USING (
    document_id IN (
      SELECT id FROM documents 
      WHERE program_id IN (
        SELECT program_id FROM user_role_assignments 
        WHERE user_id = (select auth.uid()) AND program_id IS NOT NULL
      )
    )
  );

DROP POLICY IF EXISTS "Admins can insert legal holds in their tenant" ON legal_holds;
CREATE POLICY "Admins can insert legal holds in their tenant"
  ON legal_holds FOR INSERT
  TO authenticated
  WITH CHECK (
    (select auth.uid()) IN (
      SELECT ura.user_id FROM user_role_assignments ura
      JOIN roles r ON ura.role_id = r.id
      WHERE r.name IN ('SYSTEM_ADMIN', 'DEPARTMENT_HEAD')
    )
  );

DROP POLICY IF EXISTS "Admins can update legal holds in their tenant" ON legal_holds;
CREATE POLICY "Admins can update legal holds in their tenant"
  ON legal_holds FOR UPDATE
  TO authenticated
  USING (
    (select auth.uid()) IN (
      SELECT ura.user_id FROM user_role_assignments ura
      JOIN roles r ON ura.role_id = r.id
      WHERE r.name IN ('SYSTEM_ADMIN', 'DEPARTMENT_HEAD')
    )
  )
  WITH CHECK (
    (select auth.uid()) IN (
      SELECT ura.user_id FROM user_role_assignments ura
      JOIN roles r ON ura.role_id = r.id
      WHERE r.name IN ('SYSTEM_ADMIN', 'DEPARTMENT_HEAD')
    )
  );

-- Recreate admin policies with optimization
DROP POLICY IF EXISTS "Admins can view profiles in their tenant" ON user_profiles;
CREATE POLICY "Admins can view profiles in their tenant"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles WHERE user_id = (select auth.uid())
    )
    AND (select auth.uid()) IN (
      SELECT ura.user_id FROM user_role_assignments ura
      JOIN roles r ON ura.role_id = r.id
      WHERE r.name IN ('SYSTEM_ADMIN', 'DEPARTMENT_HEAD')
    )
  );

DROP POLICY IF EXISTS "Admins can update profiles in their tenant" ON user_profiles;
CREATE POLICY "Admins can update profiles in their tenant"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles WHERE user_id = (select auth.uid())
    )
    AND (select auth.uid()) IN (
      SELECT ura.user_id FROM user_role_assignments ura
      JOIN roles r ON ura.role_id = r.id
      WHERE r.name IN ('SYSTEM_ADMIN', 'DEPARTMENT_HEAD')
    )
  )
  WITH CHECK (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles WHERE user_id = (select auth.uid())
    )
    AND (select auth.uid()) IN (
      SELECT ura.user_id FROM user_role_assignments ura
      JOIN roles r ON ura.role_id = r.id
      WHERE r.name IN ('SYSTEM_ADMIN', 'DEPARTMENT_HEAD')
    )
  );

DROP POLICY IF EXISTS "Admins can view role assignments in their tenant" ON user_role_assignments;
CREATE POLICY "Admins can view role assignments in their tenant"
  ON user_role_assignments FOR SELECT
  TO authenticated
  USING (
    tenant_id IN (
      SELECT tenant_id FROM user_profiles WHERE user_id = (select auth.uid())
    )
    AND (select auth.uid()) IN (
      SELECT ura.user_id FROM user_role_assignments ura
      JOIN roles r ON ura.role_id = r.id
      WHERE r.name IN ('SYSTEM_ADMIN', 'DEPARTMENT_HEAD')
    )
  );
