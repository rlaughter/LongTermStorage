/*
  # Add organization_unit_id to programs table

  ## Overview
  Programs need to be associated with organization units (school districts) 
  in addition to departments. This allows documents to be properly scoped
  to both functional departments and geographical/organizational units.

  ## Changes Made

  ### 1. Schema Changes
  - Add organization_unit_id column to programs table
  - Add foreign key constraint to organization_units
  - Add index for performance

  ### 2. Data Migration
  - Update existing programs to reference the state-level organization unit
  - This is a safe default since all current programs are state-level

  ## Notes
  - Existing programs will be assigned to the State Education Agency org unit
  - New programs will require an organization_unit_id to be specified
*/

-- Add organization_unit_id column to programs table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'programs' AND column_name = 'organization_unit_id'
  ) THEN
    ALTER TABLE programs ADD COLUMN organization_unit_id uuid;
  END IF;
END $$;

-- Add foreign key constraint
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'programs_organization_unit_id_fkey'
  ) THEN
    ALTER TABLE programs 
    ADD CONSTRAINT programs_organization_unit_id_fkey 
    FOREIGN KEY (organization_unit_id) REFERENCES organization_units(id);
  END IF;
END $$;

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_programs_org_unit ON programs(organization_unit_id);

-- Update existing programs to reference the state-level organization unit
UPDATE programs
SET organization_unit_id = '00000000-0000-0000-0001-000000000001'
WHERE organization_unit_id IS NULL
  AND tenant_id = '00000000-0000-0000-0000-000000000001';

-- Make organization_unit_id required for future inserts
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'programs' 
    AND column_name = 'organization_unit_id'
    AND is_nullable = 'YES'
  ) THEN
    ALTER TABLE programs ALTER COLUMN organization_unit_id SET NOT NULL;
  END IF;
END $$;
