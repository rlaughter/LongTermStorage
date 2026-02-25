export interface Role {
  id: string;
  name: string;
  description: string;
  permissions: string[];
}

export interface UserRoleAssignment {
  id: string;
  user_id: string;
  role_id: string;
  tenant_id: string;
  department_id: string | null;
  program_id: string | null;
  organization_unit_id: string | null;
  role?: Role;
}

export interface UserProfile {
  id: string;
  user_id: string;
  tenant_id: string;
  first_name: string;
  last_name: string;
  email?: string;
  status: string;
  created_at: string;
  updated_at: string;
}
