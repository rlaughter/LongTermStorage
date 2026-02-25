<template>
  <MainLayout>
    <div class="user-management">
      <div class="page-header">
        <div>
          <h1>User Management</h1>
          <p class="page-description">Manage users, roles, and program access</p>
        </div>
        <Button
          label="Add User"
          icon="pi pi-plus"
          @click="openAddDialog"
          v-if="canManageUsers"
          class="add-button"
        />
      </div>

      <Card class="users-card">
        <template #content>
          <DataTable
            :value="users"
            :loading="loading"
            paginator
            :rows="10"
            responsive-layout="scroll"
            striped-rows
          >
            <template #empty>
              <div class="empty-state">
                <i class="pi pi-users"></i>
                <p>No users found</p>
                <Button
                  label="Add Your First User"
                  icon="pi pi-plus"
                  @click="openAddDialog"
                  v-if="canManageUsers"
                  outlined
                />
              </div>
            </template>

            <Column field="first_name" header="Name" sortable>
              <template #body="slotProps">
                <div class="user-name">
                  <strong>{{ slotProps.data.first_name }} {{ slotProps.data.last_name }}</strong>
                  <small>{{ slotProps.data.email }}</small>
                </div>
              </template>
            </Column>
            <Column field="status" header="Status" sortable>
              <template #body="slotProps">
                <Tag
                  :value="slotProps.data.status"
                  :severity="getStatusSeverity(slotProps.data.status)"
                />
              </template>
            </Column>
            <Column field="roles" header="Roles">
              <template #body="slotProps">
                <div class="role-tags">
                  <Tag
                    v-for="role in slotProps.data.uniqueRoles"
                    :key="role"
                    :value="role"
                    severity="info"
                    class="role-tag"
                  />
                </div>
              </template>
            </Column>
            <Column field="program_count" header="Programs">
              <template #body="slotProps">
                <div class="program-count">
                  {{ slotProps.data.program_count }} program{{ slotProps.data.program_count !== 1 ? 's' : '' }}
                </div>
              </template>
            </Column>
            <Column field="created_at" header="Created" sortable>
              <template #body="slotProps">
                {{ formatDate(slotProps.data.created_at) }}
              </template>
            </Column>
            <Column header="Actions" v-if="canManageUsers">
              <template #body="slotProps">
                <div class="action-buttons">
                  <Button
                    icon="pi pi-pencil"
                    text
                    rounded
                    @click="openEditDialog(slotProps.data)"
                    v-tooltip="'Edit'"
                  />
                  <Button
                    icon="pi pi-trash"
                    text
                    rounded
                    severity="danger"
                    @click="confirmDelete(slotProps.data)"
                    v-tooltip="'Delete'"
                  />
                </div>
              </template>
            </Column>
          </DataTable>
        </template>
      </Card>

      <Dialog
        v-model:visible="userDialog"
        :header="dialogMode === 'add' ? 'Add New User' : 'Edit User'"
        :modal="true"
        :closable="true"
        class="user-dialog"
      >
        <form @submit.prevent="saveUser" class="user-form">
          <div class="form-section">
            <h3 class="section-title">User Information</h3>

            <div class="form-grid">
              <div class="field">
                <label for="first_name">First Name *</label>
                <InputText
                  id="first_name"
                  v-model="userForm.first_name"
                  :class="{ 'p-invalid': submitted && !userForm.first_name }"
                  required
                  placeholder="Enter first name"
                />
                <small v-if="submitted && !userForm.first_name" class="p-error">
                  First name is required
                </small>
              </div>

              <div class="field">
                <label for="last_name">Last Name *</label>
                <InputText
                  id="last_name"
                  v-model="userForm.last_name"
                  :class="{ 'p-invalid': submitted && !userForm.last_name }"
                  required
                  placeholder="Enter last name"
                />
                <small v-if="submitted && !userForm.last_name" class="p-error">
                  Last name is required
                </small>
              </div>
            </div>

            <div class="field">
              <label for="email">Email Address *</label>
              <InputText
                id="email"
                v-model="userForm.email"
                type="email"
                :class="{ 'p-invalid': submitted && !userForm.email }"
                :disabled="dialogMode === 'edit'"
                required
                placeholder="user@example.com"
              />
              <small v-if="submitted && !userForm.email" class="p-error">
                Email is required
              </small>
              <small v-if="dialogMode === 'edit'" class="field-hint">
                Email cannot be changed after user creation
              </small>
            </div>

            <div class="field" v-if="dialogMode === 'add'">
              <label for="password">Password *</label>
              <Password
                id="password"
                v-model="userForm.password"
                :class="{ 'p-invalid': submitted && !userForm.password }"
                toggle-mask
                :feedback="true"
                required
                placeholder="Enter a secure password"
              />
              <small v-if="submitted && !userForm.password" class="p-error">
                Password is required
              </small>
            </div>

            <div class="field">
              <label for="status">Account Status *</label>
              <Dropdown
                id="status"
                v-model="userForm.status"
                :options="statusOptions"
                placeholder="Select status"
                required
              />
            </div>
          </div>

          <div class="form-section">
            <h3 class="section-title">Role & Access</h3>

            <div class="field">
              <label for="role">Role *</label>
              <Dropdown
                id="role"
                v-model="userForm.role_id"
                :options="availableRoles"
                option-label="name"
                option-value="id"
                placeholder="Select a role"
                :class="{ 'p-invalid': submitted && !userForm.role_id }"
                required
              >
                <template #option="slotProps">
                  <div class="role-option">
                    <strong>{{ slotProps.option.name }}</strong>
                    <small>{{ slotProps.option.description }}</small>
                  </div>
                </template>
              </Dropdown>
              <small v-if="submitted && !userForm.role_id" class="p-error">
                Role is required
              </small>
            </div>

            <div class="field">
              <label for="programs">Program Access *</label>
              <MultiSelect
                id="programs"
                v-model="userForm.program_ids"
                :options="availablePrograms"
                option-label="name"
                option-value="id"
                placeholder="Select programs"
                :class="{ 'p-invalid': submitted && (!userForm.program_ids || userForm.program_ids.length === 0) }"
                display="chip"
                :filter="true"
              />
              <small v-if="submitted && (!userForm.program_ids || userForm.program_ids.length === 0)" class="p-error">
                At least one program is required
              </small>
              <small class="field-hint">
                Select which programs this user can access
              </small>
            </div>
          </div>

          <div class="dialog-actions">
            <Button
              label="Cancel"
              severity="secondary"
              @click="closeDialog"
              type="button"
              outlined
            />
            <Button
              :label="dialogMode === 'add' ? 'Create User' : 'Save Changes'"
              :loading="saving"
              type="submit"
            />
          </div>
        </form>
      </Dialog>

      <ConfirmDialog></ConfirmDialog>
    </div>
  </MainLayout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useToast } from 'primevue/usetoast';
import { useConfirm } from 'primevue/useconfirm';
import Card from 'primevue/card';
import Button from 'primevue/button';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Tag from 'primevue/tag';
import Dialog from 'primevue/dialog';
import InputText from 'primevue/inputtext';
import Password from 'primevue/password';
import Dropdown from 'primevue/dropdown';
import MultiSelect from 'primevue/multiselect';
import ConfirmDialog from 'primevue/confirmdialog';
import MainLayout from '@/components/MainLayout.vue';
import { useAuthStore } from '@/stores/auth.store';
import { supabase } from '@/lib/supabase';

const toast = useToast();
const confirm = useConfirm();
const authStore = useAuthStore();

const users = ref<any[]>([]);
const loading = ref(false);
const userDialog = ref(false);
const dialogMode = ref<'add' | 'edit'>('add');
const submitted = ref(false);
const saving = ref(false);

const availableRoles = ref<any[]>([]);
const availablePrograms = ref<any[]>([]);

const statusOptions = ['ACTIVE', 'INACTIVE', 'SUSPENDED'];

const userForm = ref({
  id: '',
  user_id: '',
  first_name: '',
  last_name: '',
  email: '',
  password: '',
  status: 'ACTIVE',
  role_id: '',
  program_ids: [] as string[]
});

const canManageUsers = computed(() => {
  return authStore.isTenantAdmin || authStore.isSystemAdmin;
});

onMounted(async () => {
  if (!canManageUsers.value) {
    toast.add({
      severity: 'error',
      summary: 'Access Denied',
      detail: 'You do not have permission to manage users',
      life: 3000
    });
    return;
  }
  await loadUsers();
  await loadRoles();
  await loadPrograms();
});

async function loadUsers() {
  loading.value = true;

  try {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) throw new Error('No session');

    const apiUrl = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/get-users?tenant_id=${authStore.tenantId}`;

    const response = await fetch(apiUrl, {
      headers: {
        'Authorization': `Bearer ${session.access_token}`,
        'Content-Type': 'application/json',
      },
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Failed to load users');
    }

    const { users: loadedUsers } = await response.json();

    users.value = loadedUsers.map((user: any) => {
      const uniqueRoles = [...new Set(user.user_role_assignments.map((ra: any) => ra.role.name))];
      const programCount = user.user_role_assignments.length;

      return {
        ...user,
        uniqueRoles,
        program_count: programCount
      };
    });
  } catch (error: any) {
    console.error('Error loading users:', error);
    toast.add({
      severity: 'error',
      summary: 'Error',
      detail: 'Failed to load users',
      life: 3000
    });
  } finally {
    loading.value = false;
  }
}

async function loadRoles() {
  const { data, error } = await supabase
    .from('roles')
    .select('*')
    .order('name');

  if (error) {
    console.error('Error loading roles:', error);
    return;
  }

  availableRoles.value = data;
}

async function loadPrograms() {
  const { data, error } = await supabase
    .from('programs')
    .select('*')
    .eq('tenant_id', authStore.tenantId)
    .order('name');

  if (error) {
    console.error('Error loading programs:', error);
    return;
  }

  availablePrograms.value = data;
}

function openAddDialog() {
  dialogMode.value = 'add';
  userForm.value = {
    id: '',
    user_id: '',
    first_name: '',
    last_name: '',
    email: '',
    password: '',
    status: 'ACTIVE',
    role_id: '',
    program_ids: []
  };
  submitted.value = false;
  userDialog.value = true;
}

function openEditDialog(user: any) {
  dialogMode.value = 'edit';
  const roleAssignments = user.user_role_assignments || [];
  const roleId = roleAssignments.length > 0 ? roleAssignments[0].role_id : '';
  const programIds = roleAssignments.map((ra: any) => ra.program_id).filter(Boolean);

  userForm.value = {
    id: user.id,
    user_id: user.user_id,
    first_name: user.first_name,
    last_name: user.last_name,
    email: user.email || '',
    password: '',
    status: user.status,
    role_id: roleId,
    program_ids: programIds
  };
  submitted.value = false;
  userDialog.value = true;
}

function closeDialog() {
  userDialog.value = false;
  submitted.value = false;
}

async function saveUser() {
  submitted.value = true;

  if (!userForm.value.first_name || !userForm.value.email || !userForm.value.role_id) {
    return;
  }

  if (dialogMode.value === 'add' && !userForm.value.password) {
    return;
  }

  if (!userForm.value.program_ids || userForm.value.program_ids.length === 0) {
    return;
  }

  saving.value = true;

  try {
    if (dialogMode.value === 'add') {
      await createUser();
    } else {
      await updateUser();
    }

    toast.add({
      severity: 'success',
      summary: 'Success',
      detail: `User ${dialogMode.value === 'add' ? 'created' : 'updated'} successfully`,
      life: 3000
    });

    closeDialog();
    await loadUsers();
  } catch (error: any) {
    console.error('Error saving user:', error);
    toast.add({
      severity: 'error',
      summary: 'Error',
      detail: error.message || 'Failed to save user',
      life: 3000
    });
  } finally {
    saving.value = false;
  }
}

async function createUser() {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) throw new Error('No session');

  const apiUrl = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/manage-user`;

  const response = await fetch(apiUrl, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${session.access_token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      email: userForm.value.email,
      password: userForm.value.password,
      first_name: userForm.value.first_name,
      last_name: userForm.value.last_name,
      status: userForm.value.status,
      tenant_id: authStore.tenantId,
      role_id: userForm.value.role_id,
      program_ids: userForm.value.program_ids
    })
  });

  if (!response.ok) {
    const error = await response.json();
    console.error('Backend error:', error);
    throw new Error(error.error || 'Failed to create user');
  }

  const result = await response.json();
  console.log('User created successfully:', result);
}

async function updateUser() {
  const { data: { session } } = await supabase.auth.getSession();
  if (!session) throw new Error('No session');

  const apiUrl = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/manage-user`;

  const response = await fetch(apiUrl, {
    method: 'PUT',
    headers: {
      'Authorization': `Bearer ${session.access_token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      user_id: userForm.value.user_id,
      profile_id: userForm.value.id,
      first_name: userForm.value.first_name,
      last_name: userForm.value.last_name,
      status: userForm.value.status,
      role_id: userForm.value.role_id,
      program_ids: userForm.value.program_ids,
      tenant_id: authStore.tenantId
    })
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.error || 'Failed to update user');
  }
}

function confirmDelete(user: any) {
  confirm.require({
    message: `Are you sure you want to delete ${user.first_name} ${user.last_name}? This action cannot be undone.`,
    header: 'Confirm Delete',
    icon: 'pi pi-exclamation-triangle',
    acceptClass: 'p-button-danger',
    accept: () => deleteUser(user)
  });
}

async function deleteUser(user: any) {
  try {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) throw new Error('No session');

    const apiUrl = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/manage-user?user_id=${user.user_id}&profile_id=${user.id}`;

    const response = await fetch(apiUrl, {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${session.access_token}`,
        'Content-Type': 'application/json',
      }
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Failed to delete user');
    }

    toast.add({
      severity: 'success',
      summary: 'Success',
      detail: 'User deleted successfully',
      life: 3000
    });

    await loadUsers();
  } catch (error: any) {
    console.error('Error deleting user:', error);
    toast.add({
      severity: 'error',
      summary: 'Error',
      detail: 'Failed to delete user',
      life: 3000
    });
  }
}

function getStatusSeverity(status: string) {
  switch (status) {
    case 'ACTIVE':
      return 'success';
    case 'INACTIVE':
      return 'secondary';
    case 'SUSPENDED':
      return 'danger';
    default:
      return 'info';
  }
}

function formatDate(dateString: string) {
  const date = new Date(dateString);
  return date.toLocaleDateString();
}
</script>

<style scoped>
.user-management {
  max-width: 1400px;
  margin: 0 auto;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 2rem;
  gap: 2rem;
}

.page-header h1 {
  font-size: 2rem;
  font-weight: 700;
  color: #1e293b;
  margin: 0 0 0.5rem 0;
}

.page-description {
  color: #64748b;
  font-size: 0.95rem;
  margin: 0;
}

.add-button {
  flex-shrink: 0;
}

.users-card {
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.empty-state {
  text-align: center;
  padding: 4rem 2rem;
}

.empty-state i {
  font-size: 4rem;
  color: #cbd5e1;
  margin-bottom: 1rem;
}

.empty-state p {
  margin-top: 0.5rem;
  margin-bottom: 1.5rem;
  color: #64748b;
  font-size: 1.1rem;
}

.user-name {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.user-name strong {
  color: #1e293b;
  font-weight: 600;
}

.user-name small {
  color: #64748b;
  font-size: 0.875rem;
}

.action-buttons {
  display: flex;
  gap: 0.5rem;
  justify-content: center;
}

.role-tags {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.role-tag {
  font-size: 0.75rem;
}

.program-count {
  color: #64748b;
  font-size: 0.9rem;
}

:deep(.user-dialog) {
  width: 650px;
  max-width: 90vw;
}

:deep(.user-dialog .p-dialog-content) {
  padding: 0;
}

.user-form {
  display: flex;
  flex-direction: column;
  gap: 0;
}

.form-section {
  padding: 1.5rem;
  border-bottom: 1px solid #e2e8f0;
}

.form-section:last-of-type {
  border-bottom: none;
}

.section-title {
  font-size: 1.1rem;
  font-weight: 600;
  color: #1e293b;
  margin: 0 0 1.25rem 0;
}

.form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
  margin-bottom: 1rem;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.field label {
  font-weight: 600;
  color: #334155;
  font-size: 0.875rem;
}

.field-hint {
  color: #64748b;
  font-size: 0.8125rem;
  margin-top: -0.25rem;
}

.role-option {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.role-option strong {
  color: #1e293b;
  font-size: 0.95rem;
}

.role-option small {
  color: #64748b;
  font-size: 0.8125rem;
}

.dialog-actions {
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
  padding: 1.25rem 1.5rem;
  background: #f8fafc;
  border-top: 1px solid #e2e8f0;
}

.p-error {
  color: #dc2626;
  font-size: 0.8125rem;
  margin-top: -0.25rem;
}

:deep(.p-datatable .p-datatable-tbody > tr > td) {
  padding: 1rem;
}

:deep(.p-datatable .p-datatable-thead > tr > th) {
  background: #f8fafc;
  color: #475569;
  font-weight: 600;
  font-size: 0.875rem;
  text-transform: uppercase;
  letter-spacing: 0.025em;
  padding: 0.875rem 1rem;
}
</style>
