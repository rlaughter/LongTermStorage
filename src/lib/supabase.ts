import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true
  }
});

export type Database = {
  public: {
    Tables: {
      tenants: {
        Row: {
          id: string;
          name: string;
          code: string;
          status: string;
          created_at: string;
          updated_at: string;
        };
      };
      user_profiles: {
        Row: {
          id: string;
          user_id: string;
          tenant_id: string;
          first_name: string;
          last_name: string;
          status: string;
          last_login_at: string | null;
          created_at: string;
          updated_at: string;
        };
      };
      documents: {
        Row: {
          id: string;
          tenant_id: string;
          organization_unit_id: string;
          department_id: string;
          program_id: string;
          folder_id: string | null;
          filename: string;
          original_filename: string;
          file_type: string;
          file_size_bytes: number;
          storage_path: string;
          mime_type: string;
          status: string;
          extracted_text: string | null;
          employee_id: string | null;
          student_id: string | null;
          school_year: string | null;
          campus: string | null;
          category: string | null;
          document_date: string | null;
          uploaded_by: string;
          uploaded_at: string;
          created_at: string;
          updated_at: string;
        };
      };
      programs: {
        Row: {
          id: string;
          tenant_id: string;
          department_id: string;
          name: string;
          code: string;
          description: string | null;
          status: string;
          created_at: string;
          updated_at: string;
        };
      };
      departments: {
        Row: {
          id: string;
          tenant_id: string;
          name: string;
          code: string;
          status: string;
          created_at: string;
          updated_at: string;
        };
      };
      organization_units: {
        Row: {
          id: string;
          tenant_id: string;
          parent_id: string | null;
          name: string;
          type: string;
          code: string;
          status: string;
          created_at: string;
          updated_at: string;
        };
      };
    };
  };
};
