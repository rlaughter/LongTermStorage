import { createClient } from 'npm:@supabase/supabase-js@2.57.4';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Info, Apikey',
};

interface CreateUserRequest {
  email: string;
  password: string;
  first_name: string;
  last_name: string;
  status: string;
  tenant_id: string;
  role_id: string;
  program_ids: string[];
}

interface UpdateUserRequest {
  user_id: string;
  profile_id: string;
  first_name: string;
  last_name: string;
  status: string;
  role_id: string;
  program_ids: string[];
  tenant_id: string;
}

interface DeleteUserRequest {
  user_id: string;
  profile_id: string;
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    });
  }

  try {
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
        db: {
          schema: 'public',
        },
      }
    );

    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      throw new Error('Missing authorization header');
    }

    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(token);

    if (authError || !user) {
      throw new Error('Unauthorized');
    }

    const method = req.method;
    const body = method !== 'DELETE' ? await req.json() : null;

    if (method === 'POST') {
      return await createUser(supabaseAdmin, user, body as CreateUserRequest);
    } else if (method === 'PUT') {
      return await updateUser(supabaseAdmin, user, body as UpdateUserRequest);
    } else if (method === 'DELETE') {
      const url = new URL(req.url);
      const user_id = url.searchParams.get('user_id');
      const profile_id = url.searchParams.get('profile_id');

      if (!user_id || !profile_id) {
        throw new Error('Missing user_id or profile_id');
      }

      return await deleteUser(supabaseAdmin, user, { user_id, profile_id });
    } else {
      throw new Error('Method not allowed');
    }
  } catch (error) {
    console.error('Error:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});

async function createUser(supabaseAdmin: any, currentUser: any, data: CreateUserRequest) {
  try {
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email: data.email,
      password: data.password,
      email_confirm: true,
    });

    if (authError) {
      console.error('Auth error:', authError);
      throw new Error(`Failed to create auth user: ${authError.message}`);
    }

    const { error: profileError } = await supabaseAdmin
      .from('user_profiles')
      .insert({
        user_id: authData.user.id,
        tenant_id: data.tenant_id,
        first_name: data.first_name,
        last_name: data.last_name,
        email: data.email,
        status: data.status,
      });

    if (profileError) {
      console.error('Profile error:', profileError);
      await supabaseAdmin.auth.admin.deleteUser(authData.user.id);
      throw new Error(`Failed to create user profile: ${profileError.message}`);
    }

    const roleAssignments = data.program_ids.map(programId => ({
      user_id: authData.user.id,
      role_id: data.role_id,
      tenant_id: data.tenant_id,
      program_id: programId,
      department_id: null,
    }));

    const { error: roleError } = await supabaseAdmin
      .from('user_role_assignments')
      .insert(roleAssignments);

    if (roleError) {
      console.error('Role assignment error:', roleError);
      await supabaseAdmin.from('user_profiles').delete().eq('user_id', authData.user.id);
      await supabaseAdmin.auth.admin.deleteUser(authData.user.id);
      throw new Error(`Failed to assign roles: ${roleError.message}`);
    }

    await supabaseAdmin.from('audit_events').insert({
      tenant_id: data.tenant_id,
      user_id: currentUser.id,
      event_type: 'CREATE',
      entity_type: 'USER',
      entity_id: authData.user.id,
      action: `Created user: ${data.email}`,
      details: {
        email: data.email,
        first_name: data.first_name,
        last_name: data.last_name,
        role_id: data.role_id,
        program_count: data.program_ids.length
      }
    });

    return new Response(
      JSON.stringify({ success: true, user_id: authData.user.id }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  } catch (error) {
    console.error('Create user error:', error);
    throw error;
  }
}

async function updateUser(supabaseAdmin: any, currentUser: any, data: UpdateUserRequest) {
  const { data: profile } = await supabaseAdmin
    .from('user_profiles')
    .select('email')
    .eq('id', data.profile_id)
    .single();

  const { error: profileError } = await supabaseAdmin
    .from('user_profiles')
    .update({
      first_name: data.first_name,
      last_name: data.last_name,
      status: data.status,
    })
    .eq('id', data.profile_id);

  if (profileError) throw profileError;

  const { error: deleteError } = await supabaseAdmin
    .from('user_role_assignments')
    .delete()
    .eq('user_id', data.user_id);

  if (deleteError) throw deleteError;

  const roleAssignments = data.program_ids.map(programId => ({
    user_id: data.user_id,
    role_id: data.role_id,
    tenant_id: data.tenant_id,
    program_id: programId,
    department_id: null,
  }));

  const { error: insertError } = await supabaseAdmin
    .from('user_role_assignments')
    .insert(roleAssignments);

  if (insertError) throw insertError;

  await supabaseAdmin.from('audit_events').insert({
    tenant_id: data.tenant_id,
    user_id: currentUser.id,
    event_type: 'UPDATE',
    entity_type: 'USER',
    entity_id: data.user_id,
    action: `Updated user: ${profile?.email || 'Unknown'}`,
    details: {
      first_name: data.first_name,
      last_name: data.last_name,
      status: data.status,
      role_id: data.role_id,
      program_count: data.program_ids.length
    }
  });

  return new Response(
    JSON.stringify({ success: true }),
    {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}

async function deleteUser(supabaseAdmin: any, currentUser: any, data: DeleteUserRequest) {
  const { data: profile } = await supabaseAdmin
    .from('user_profiles')
    .select('email, tenant_id')
    .eq('id', data.profile_id)
    .single();

  const { error: roleError } = await supabaseAdmin
    .from('user_role_assignments')
    .delete()
    .eq('user_id', data.user_id);

  if (roleError) throw roleError;

  const { error: profileError } = await supabaseAdmin
    .from('user_profiles')
    .delete()
    .eq('id', data.profile_id);

  if (profileError) throw profileError;

  const { error: authError } = await supabaseAdmin.auth.admin.deleteUser(data.user_id);

  if (authError) throw authError;

  if (profile) {
    await supabaseAdmin.from('audit_events').insert({
      tenant_id: profile.tenant_id,
      user_id: currentUser.id,
      event_type: 'DELETE',
      entity_type: 'USER',
      entity_id: data.user_id,
      action: `Deleted user: ${profile.email}`,
      details: {
        email: profile.email
      }
    });
  }

  return new Response(
    JSON.stringify({ success: true }),
    {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}
