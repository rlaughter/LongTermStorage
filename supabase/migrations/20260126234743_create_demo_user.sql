/*
  # Create Demo User
  
  Creates a demo user account for testing and development.
  
  ## User Created
  - Email: demo@k12records.local
  - Password: DemoPass123!
  - Role: SYSTEM_ADMIN with full access
  
  ## Details
  1. Creates user in auth.users with proper structure
  2. Creates identity record for email authentication  
  3. Creates user profile linked to demo tenant
  4. Assigns SYSTEM_ADMIN role
  
  ## Security
  - Email is confirmed by default for demo purposes
  - User has full system admin access
  - Change password after first login in production
*/

DO $$
DECLARE
  v_user_id uuid;
  v_role_id uuid;
BEGIN
  -- Check if user already exists
  SELECT id INTO v_user_id FROM auth.users WHERE email = 'demo@k12records.local';
  
  IF v_user_id IS NULL THEN
    -- Create the demo user with a properly hashed password
    -- Password: DemoPass123!
    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at,
      confirmation_token,
      recovery_token,
      email_change_token_new,
      email_change
    )
    VALUES (
      '00000000-0000-0000-0000-000000000000',
      gen_random_uuid(),
      'authenticated',
      'authenticated',
      'demo@k12records.local',
      crypt('DemoPass123!', gen_salt('bf')),
      now(),
      '{"provider":"email","providers":["email"]}',
      '{"first_name":"Demo","last_name":"Admin"}',
      now(),
      now(),
      '',
      '',
      '',
      ''
    )
    RETURNING id INTO v_user_id;

    -- Create identity record for email authentication
    INSERT INTO auth.identities (
      id,
      user_id,
      identity_data,
      provider,
      provider_id,
      last_sign_in_at,
      created_at,
      updated_at
    )
    VALUES (
      gen_random_uuid(),
      v_user_id,
      jsonb_build_object(
        'sub', v_user_id::text,
        'email', 'demo@k12records.local'
      ),
      'email',
      v_user_id::text,
      now(),
      now(),
      now()
    );

    -- Create user profile
    INSERT INTO user_profiles (
      user_id,
      tenant_id,
      first_name,
      last_name,
      status,
      created_at,
      updated_at
    )
    VALUES (
      v_user_id,
      '00000000-0000-0000-0000-000000000001',
      'Demo',
      'Admin',
      'ACTIVE',
      now(),
      now()
    );

    -- Get SYSTEM_ADMIN role ID
    SELECT id INTO v_role_id FROM roles WHERE name = 'SYSTEM_ADMIN';

    -- Assign SYSTEM_ADMIN role with access to all programs
    INSERT INTO user_role_assignments (user_id, role_id, tenant_id, program_id)
    SELECT 
      v_user_id,
      v_role_id,
      '00000000-0000-0000-0000-000000000001',
      id
    FROM programs
    WHERE tenant_id = '00000000-0000-0000-0000-000000000001';
    
    RAISE NOTICE 'Demo user created successfully with email: demo@k12records.local';
  ELSE
    RAISE NOTICE 'Demo user already exists';
  END IF;
END $$;
