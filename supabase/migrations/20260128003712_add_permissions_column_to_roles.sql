/*
  # Add permissions column to roles table

  1. Changes
    - Add `permissions` column to `roles` table (text array type)
    - Set default to empty array
*/

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'roles' AND column_name = 'permissions'
  ) THEN
    ALTER TABLE roles ADD COLUMN permissions text[] DEFAULT '{}';
  END IF;
END $$;