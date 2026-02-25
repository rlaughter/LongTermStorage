import { createClient } from 'npm:@supabase/supabase-js@2.57.4';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Info, Apikey',
};

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

    const url = new URL(req.url);
    const tenant_id = url.searchParams.get('tenant_id');

    if (!tenant_id) {
      throw new Error('Missing tenant_id parameter');
    }

    const { data: profiles, error: profilesError } = await supabaseAdmin
      .from('user_profiles')
      .select(`
        *,
        user_role_assignments (
          id,
          role_id,
          program_id,
          role:roles (
            name
          ),
          program:programs (
            name
          )
        )
      `)
      .eq('tenant_id', tenant_id)
      .order('created_at', { ascending: false });

    if (profilesError) throw profilesError;

    const userIds = profiles.map(p => p.user_id);

    const emailMap = new Map();

    for (const userId of userIds) {
      const { data: authUser } = await supabaseAdmin.auth.admin.getUserById(userId);
      if (authUser && authUser.user) {
        emailMap.set(userId, authUser.user.email);
      }
    }

    const users = profiles.map((profile: any) => ({
      ...profile,
      email: emailMap.get(profile.user_id) || 'N/A',
    }));

    return new Response(
      JSON.stringify({ users }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
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
