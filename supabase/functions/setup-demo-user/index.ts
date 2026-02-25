import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    });
  }

  try {
    // Create Supabase Admin client
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      }
    );

    // Create the demo user
    const { data: userData, error: userError } = await supabaseAdmin.auth.admin.createUser({
      email: "demo@k12records.local",
      password: "DemoPass123!",
      email_confirm: true,
      user_metadata: {
        first_name: "Demo",
        last_name: "Admin",
      },
    });

    if (userError) {
      throw userError;
    }

    const userId = userData.user.id;

    // Create user profile
    const { error: profileError } = await supabaseAdmin
      .from("user_profiles")
      .insert({
        user_id: userId,
        tenant_id: "00000000-0000-0000-0000-000000000001",
        first_name: "Demo",
        last_name: "Admin",
        status: "ACTIVE",
      });

    if (profileError) {
      throw profileError;
    }

    // Get SYSTEM_ADMIN role ID
    const { data: roleData, error: roleError } = await supabaseAdmin
      .from("roles")
      .select("id")
      .eq("name", "SYSTEM_ADMIN")
      .single();

    if (roleError) {
      throw roleError;
    }

    // Get all programs for the demo tenant
    const { data: programs, error: programsError } = await supabaseAdmin
      .from("programs")
      .select("id")
      .eq("tenant_id", "00000000-0000-0000-0000-000000000001");

    if (programsError) {
      throw programsError;
    }

    // Assign SYSTEM_ADMIN role with access to all programs
    const roleAssignments = programs.map((program: any) => ({
      user_id: userId,
      role_id: roleData.id,
      tenant_id: "00000000-0000-0000-0000-000000000001",
      program_id: program.id,
    }));

    const { error: assignmentError } = await supabaseAdmin
      .from("user_role_assignments")
      .insert(roleAssignments);

    if (assignmentError) {
      throw assignmentError;
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Demo user created successfully",
        email: "demo@k12records.local",
        password: "DemoPass123!",
      }),
      {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      {
        status: 400,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      }
    );
  }
});
