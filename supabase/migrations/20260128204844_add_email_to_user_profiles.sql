/*
  # Add email field to user_profiles

  ## Changes
  1. Add email column to user_profiles table
  2. Populate email from auth.users for existing records
  3. Create function to auto-sync email on user creation/update

  ## Purpose
  Store email directly in user_profiles for easier querying in audit logs
  and other features without needing to access auth.users
*/

-- Add email column to user_profiles
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'user_profiles' AND column_name = 'email'
  ) THEN
    ALTER TABLE user_profiles ADD COLUMN email text;
  END IF;
END $$;

-- Populate email from auth.users for existing records
UPDATE user_profiles up
SET email = au.email
FROM auth.users au
WHERE up.user_id = au.id AND up.email IS NULL;

-- Make email NOT NULL after populating
ALTER TABLE user_profiles ALTER COLUMN email SET NOT NULL;

-- Create index on email for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON user_profiles(email);

-- Create or replace function to sync email from auth.users
CREATE OR REPLACE FUNCTION sync_user_profile_email()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND NEW.email != OLD.email) THEN
    UPDATE user_profiles
    SET email = NEW.email
    WHERE user_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to auto-sync email changes from auth.users
DROP TRIGGER IF EXISTS on_auth_user_email_change ON auth.users;
CREATE TRIGGER on_auth_user_email_change
  AFTER INSERT OR UPDATE OF email ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION sync_user_profile_email();
