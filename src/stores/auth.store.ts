import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { supabase } from '@/lib/supabase';
import type { User, Session } from '@supabase/supabase-js';
import type { UserProfile, UserRoleAssignment } from '@/types/auth.types';
import { PermissionsService } from '@/services/permissions.service';

export interface UserRole {
  id: string;
  role_id: string;
  role_name: string;
  program_id?: string;
  department_id?: string;
}

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null);
  const session = ref<Session | null>(null);
  const userProfile = ref<UserProfile | null>(null);
  const userRoles = ref<UserRole[]>([]);
  const roleAssignments = ref<UserRoleAssignment[]>([]);
  const loading = ref(false);
  const error = ref<string | null>(null);

  const isAuthenticated = computed(() => !!session.value);
  const tenantId = computed(() => userProfile.value?.tenant_id || null);
  const accessibleProgramIds = computed(() =>
    PermissionsService.getAccessibleProgramIds(roleAssignments.value)
  );
  const isSystemAdmin = computed(() =>
    PermissionsService.isSystemAdmin(roleAssignments.value)
  );
  const isTenantAdmin = computed(() =>
    PermissionsService.isTenantAdmin(roleAssignments.value)
  );

  async function initialize() {
    loading.value = true;
    try {
      const { data: { session: currentSession } } = await supabase.auth.getSession();

      if (currentSession) {
        session.value = currentSession;
        user.value = currentSession.user;
        await loadUserProfile();
        await loadUserRoles();
      }

      supabase.auth.onAuthStateChange(async (_event, newSession) => {
        session.value = newSession;
        user.value = newSession?.user || null;

        if (newSession) {
          await loadUserProfile();
          await loadUserRoles();
        } else {
          userProfile.value = null;
          userRoles.value = [];
          roleAssignments.value = [];
        }
      });
    } catch (err: any) {
      error.value = err.message;
      console.error('Error initializing auth:', err);
    } finally {
      loading.value = false;
    }
  }

  async function loadUserProfile() {
    if (!user.value) return;

    const { data, error: profileError } = await supabase
      .from('user_profiles')
      .select('*')
      .eq('user_id', user.value.id)
      .maybeSingle();

    if (profileError) {
      console.error('Error loading user profile:', profileError);
      error.value = `Database error querying schema: ${profileError.message}`;
      return;
    }

    userProfile.value = data;
  }

  async function loadUserRoles() {
    if (!user.value) return;

    const { data, error: rolesError } = await supabase
      .from('user_role_assignments')
      .select(`
        id,
        role_id,
        tenant_id,
        program_id,
        department_id,
        organization_unit_id,
        role:roles (
          id,
          name,
          description,
          permissions
        )
      `)
      .eq('user_id', user.value.id);

    if (rolesError) {
      console.error('Error loading user roles:', rolesError);
      return;
    }

    roleAssignments.value = data.map((item: any) => ({
      id: item.id,
      user_id: user.value!.id,
      role_id: item.role_id,
      tenant_id: item.tenant_id,
      department_id: item.department_id,
      program_id: item.program_id,
      organization_unit_id: item.organization_unit_id,
      role: item.role
    }));

    userRoles.value = data.map((item: any) => ({
      id: item.id,
      role_id: item.role_id,
      role_name: item.role?.name || 'Unknown',
      program_id: item.program_id,
      department_id: item.department_id
    }));
  }

  async function signIn(email: string, password: string) {
    loading.value = true;
    error.value = null;

    try {
      const { data, error: signInError } = await supabase.auth.signInWithPassword({
        email,
        password
      });

      if (signInError) throw signInError;

      session.value = data.session;
      user.value = data.user;

      await loadUserProfile();
      await loadUserRoles();

      return { success: true };
    } catch (err: any) {
      error.value = err.message;
      return { success: false, error: err.message };
    } finally {
      loading.value = false;
    }
  }

  async function signUp(email: string, password: string, firstName: string, lastName: string, tenantId: string) {
    loading.value = true;
    error.value = null;

    try {
      const { data, error: signUpError } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            first_name: firstName,
            last_name: lastName,
            tenant_id: tenantId
          }
        }
      });

      if (signUpError) throw signUpError;

      if (data.user) {
        const { error: profileError } = await supabase
          .from('user_profiles')
          .insert({
            user_id: data.user.id,
            tenant_id: tenantId,
            first_name: firstName,
            last_name: lastName,
            status: 'ACTIVE'
          });

        if (profileError) {
          console.error('Error creating user profile:', profileError);
        }
      }

      return { success: true };
    } catch (err: any) {
      error.value = err.message;
      return { success: false, error: err.message };
    } finally {
      loading.value = false;
    }
  }

  async function signOut() {
    loading.value = true;
    try {
      await supabase.auth.signOut();
      user.value = null;
      session.value = null;
      userProfile.value = null;
      userRoles.value = [];
      roleAssignments.value = [];
    } catch (err: any) {
      error.value = err.message;
      console.error('Error signing out:', err);
    } finally {
      loading.value = false;
    }
  }

  function hasRole(roleName: string): boolean {
    return userRoles.value.some(role => role.role_name === roleName);
  }

  function hasAnyRole(roleNames: string[]): boolean {
    return userRoles.value.some(role => roleNames.includes(role.role_name));
  }

  return {
    user,
    session,
    userProfile,
    userRoles,
    roleAssignments,
    loading,
    error,
    isAuthenticated,
    tenantId,
    accessibleProgramIds,
    isSystemAdmin,
    isTenantAdmin,
    initialize,
    signIn,
    signUp,
    signOut,
    hasRole,
    hasAnyRole,
    loadUserProfile,
    loadUserRoles
  };
});
