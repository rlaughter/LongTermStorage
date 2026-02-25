/*
  # Fix User Profiles RLS Infinite Recursion

  1. Changes
    - Create a helper function to check if a user is a system admin without triggering RLS
    - Drop and recreate user_profiles RLS policies using the helper function
    - This prevents infinite recursion when policies check user_profiles

  2. Security
    - Uses SECURITY DEFINER function to bypass RLS during role checks
    - Maintains same security model but avoids circular references
*/

-- Create a helper function to check if user is system admin (bypasses RLS)
CREATE OR REPLACE FUNCTION is_system_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM user_role_assignments ura
    JOIN roles r ON r.id = ura.role_id
    WHERE ura.user_id = auth.uid()
    AND r.name = 'SYSTEM_ADMIN'
  );
END;
$$;

-- Get the tenant_id for the current user (bypasses RLS)
CREATE OR REPLACE FUNCTION get_user_tenant_id()
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  tenant uuid;
BEGIN
  SELECT up.tenant_id INTO tenant
  FROM user_profiles up
  WHERE up.user_id = auth.uid()
  LIMIT 1;
  
  RETURN tenant;
END;
$$;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view profiles in their tenant" ON user_profiles;
DROP POLICY IF EXISTS "Admins can insert profiles in their tenant" ON user_profiles;
DROP POLICY IF EXISTS "Admins can update profiles in their tenant" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;

-- Recreate policies without recursion
CREATE POLICY "Users can view own profile"
  ON user_profiles
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Admins can view profiles in their tenant"
  ON user_profiles
  FOR SELECT
  TO authenticated
  USING (
    is_system_admin() AND tenant_id = get_user_tenant_id()
  );

CREATE POLICY "Admins can insert profiles in their tenant"
  ON user_profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    is_system_admin() AND tenant_id = get_user_tenant_id()
  );

CREATE POLICY "Users can update own profile"
  ON user_profiles
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admins can update profiles in their tenant"
  ON user_profiles
  FOR UPDATE
  TO authenticated
  USING (
    is_system_admin() AND tenant_id = get_user_tenant_id()
  )
  WITH CHECK (
    is_system_admin() AND tenant_id = get_user_tenant_id()
  );
