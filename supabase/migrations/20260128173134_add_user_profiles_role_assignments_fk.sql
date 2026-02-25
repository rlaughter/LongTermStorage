/*
  # Add Foreign Key Between user_profiles and user_role_assignments

  1. Changes
    - Add foreign key constraint from user_role_assignments.user_id to user_profiles.user_id
    - This enables PostgREST to automatically join these tables in queries

  2. Notes
    - Both tables reference auth.users via user_id
    - This FK enables relationship queries in the API
*/

-- Add foreign key constraint if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'user_role_assignments_user_id_fkey_profiles' 
    AND table_name = 'user_role_assignments'
  ) THEN
    ALTER TABLE user_role_assignments
    ADD CONSTRAINT user_role_assignments_user_id_fkey_profiles
    FOREIGN KEY (user_id) REFERENCES user_profiles(user_id) ON DELETE CASCADE;
  END IF;
END $$;
