<template>
  <div class="main-layout">
    <div class="mobile-header">
      <button class="menu-toggle" @click="toggleMobileMenu">
        <i class="pi pi-bars"></i>
      </button>
      <h1 class="mobile-title">K-12 Records</h1>
      <div class="mobile-user">
        <span v-if="authStore.userProfile">
          {{ authStore.userProfile.first_name?.charAt(0) }}{{ authStore.userProfile.last_name?.charAt(0) }}
        </span>
      </div>
    </div>

    <div class="sidebar" :class="{ 'mobile-open': mobileMenuOpen }">
      <div class="sidebar-header">
        <h2>K-12 Records</h2>
        <button class="close-mobile" @click="mobileMenuOpen = false">
          <i class="pi pi-times"></i>
        </button>
      </div>

      <nav class="nav-menu">
        <div class="nav-section">
          <span class="nav-section-title">Overview</span>
          <router-link to="/" class="nav-item" @click="closeMobileMenu">
            <i class="pi pi-home"></i>
            <span>Dashboard</span>
          </router-link>
        </div>

        <div class="nav-section">
          <span class="nav-section-title">Records Management</span>
          <router-link to="/documents" class="nav-item" @click="closeMobileMenu">
            <i class="pi pi-folder-open"></i>
            <span>All Documents</span>
          </router-link>
          <router-link to="/upload" class="nav-item" @click="closeMobileMenu">
            <i class="pi pi-upload"></i>
            <span>Upload Document</span>
          </router-link>
          <router-link to="/search" class="nav-item" @click="closeMobileMenu">
            <i class="pi pi-search"></i>
            <span>Advanced Search</span>
          </router-link>
        </div>

        <div class="nav-section">
          <span class="nav-section-title">Compliance</span>
          <router-link to="/audit-log" class="nav-item" @click="closeMobileMenu">
            <i class="pi pi-history"></i>
            <span>Audit Log</span>
          </router-link>
        </div>

        <div class="nav-section" v-if="canManageUsers">
          <span class="nav-section-title">Administration</span>
          <router-link to="/users" class="nav-item" @click="closeMobileMenu">
            <i class="pi pi-users"></i>
            <span>User Management</span>
          </router-link>
        </div>
      </nav>

      <div class="sidebar-footer">
        <div class="user-profile">
          <div class="user-avatar">
            <span v-if="authStore.userProfile">
              {{ authStore.userProfile.first_name?.charAt(0) }}{{ authStore.userProfile.last_name?.charAt(0) }}
            </span>
          </div>
          <div class="user-info">
            <div class="user-name" v-if="authStore.userProfile">
              {{ authStore.userProfile.first_name }} {{ authStore.userProfile.last_name }}
            </div>
            <div class="user-role">Administrator</div>
          </div>
        </div>
        <Button
          icon="pi pi-sign-out"
          text
          severity="secondary"
          class="logout-btn"
          @click="handleLogout"
          v-tooltip.right="'Sign Out'"
        />
      </div>
    </div>

    <div class="main-content" @click="closeMobileMenu">
      <div class="top-bar">
        <div class="search-bar">
          <InputText
            v-model="searchQuery"
            placeholder="Search documents by filename, employee ID, student ID..."
            class="search-input"
            @keyup.enter="performSearch"
            :disabled="searching"
          />
          <Button
            label="Search"
            @click="performSearch"
            :loading="searching"
            aria-label="Search"
          />
        </div>
      </div>
      <div class="content-wrapper">
        <slot />
      </div>
    </div>

    <div class="mobile-overlay" :class="{ 'active': mobileMenuOpen }" @click="closeMobileMenu"></div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useAuthStore } from '@/stores/auth.store';
import { useToast } from 'primevue/usetoast';
import Button from 'primevue/button';
import InputText from 'primevue/inputtext';
import { supabase } from '@/lib/supabase';

const route = useRoute();
const router = useRouter();
const authStore = useAuthStore();
const toast = useToast();
const mobileMenuOpen = ref(false);
const searchQuery = ref('');
const searching = ref(false);

const canManageUsers = computed(() => {
  console.log('Checking canManageUsers:', {
    isTenantAdmin: authStore.isTenantAdmin,
    isSystemAdmin: authStore.isSystemAdmin,
    roleAssignments: authStore.roleAssignments,
    userRoles: authStore.userRoles
  });
  return authStore.isTenantAdmin || authStore.isSystemAdmin;
});

function toggleMobileMenu() {
  mobileMenuOpen.value = !mobileMenuOpen.value;
}

function closeMobileMenu() {
  mobileMenuOpen.value = false;
}

async function handleLogout() {
  await authStore.signOut();
  router.push('/login');
}

async function performSearch() {
  if (!searchQuery.value.trim()) {
    toast.add({
      severity: 'warn',
      summary: 'Search Required',
      detail: 'Please enter a search term',
      life: 3000
    });
    return;
  }

  searching.value = true;

  try {
    const programIds = authStore.accessibleProgramIds;

    if (programIds.length === 0) {
      searching.value = false;
      toast.add({
        severity: 'warn',
        summary: 'No Access',
        detail: 'You do not have access to any programs',
        life: 3000
      });
      return;
    }

    const query = searchQuery.value.toLowerCase();

    const { data, error } = await supabase
      .from('documents')
      .select(`
        id,
        filename,
        file_type,
        employee_id,
        student_id,
        school_year,
        programs (
          name
        )
      `)
      .in('program_id', programIds)
      .or(`filename.ilike.%${query}%,employee_id.ilike.%${query}%,student_id.ilike.%${query}%`);

    if (error) {
      throw error;
    }

    router.push({
      name: 'search',
      state: {
        results: data.map((doc: any) => ({
          ...doc,
          program: doc.programs?.name || 'Unknown'
        })),
        query: searchQuery.value
      }
    });

    searchQuery.value = '';
  } catch (error: any) {
    console.error('Error searching documents:', error);
    toast.add({
      severity: 'error',
      summary: 'Error',
      detail: 'Failed to search documents',
      life: 3000
    });
  } finally {
    searching.value = false;
  }
}

watch(() => route.path, () => {
  closeMobileMenu();
});
</script>

<style scoped>
.main-layout {
  display: flex;
  height: 100vh;
  overflow: hidden;
}

.mobile-header {
  display: none;
}

.sidebar {
  width: 280px;
  background: linear-gradient(180deg, #1e293b 0%, #0f172a 100%);
  color: white;
  display: flex;
  flex-direction: column;
  border-right: 1px solid rgba(255, 255, 255, 0.1);
  transition: transform 0.3s ease;
}

.sidebar-header {
  padding: 2rem 1.5rem;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.sidebar-header h2 {
  font-size: 1.5rem;
  font-weight: 700;
  margin: 0;
  color: white;
}

.close-mobile {
  display: none;
}

.nav-menu {
  flex: 1;
  padding: 1.5rem 0;
  overflow-y: auto;
}

.nav-section {
  margin-bottom: 2rem;
}

.nav-section-title {
  display: block;
  padding: 0.5rem 1.5rem;
  font-size: 0.75rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: rgba(255, 255, 255, 0.5);
  margin-bottom: 0.5rem;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.875rem 1.5rem;
  color: rgba(255, 255, 255, 0.8);
  text-decoration: none;
  transition: all 0.2s ease;
  font-size: 0.9375rem;
  border-left: 3px solid transparent;
  min-height: 44px;
}

.nav-item:hover {
  background: rgba(255, 255, 255, 0.05);
  color: white;
}

.nav-item.router-link-active {
  background: rgba(59, 130, 246, 0.15);
  color: white;
  border-left-color: #3b82f6;
}

.nav-item i {
  font-size: 1.125rem;
  width: 20px;
  text-align: center;
}

.sidebar-footer {
  padding: 1.5rem;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.user-profile {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex: 1;
}

.user-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  font-size: 0.875rem;
}

.user-info {
  flex: 1;
  min-width: 0;
}

.user-name {
  font-weight: 500;
  font-size: 0.875rem;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.user-role {
  font-size: 0.75rem;
  color: rgba(255, 255, 255, 0.6);
}

.logout-btn {
  color: rgba(255, 255, 255, 0.8) !important;
  min-width: 44px;
  min-height: 44px;
}

.logout-btn:hover {
  color: white !important;
  background: rgba(255, 255, 255, 0.1) !important;
}

.main-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  background: #f8fafc;
}

.top-bar {
  padding: 1rem 2rem;
  background: white;
  border-bottom: 1px solid #e2e8f0;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1rem;
}

.search-bar {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  width: 100%;
  max-width: 700px;
}

.search-input {
  flex: 1;
}

.content-wrapper {
  flex: 1;
  overflow-y: auto;
  padding: 2rem;
}

.mobile-overlay {
  display: none;
}

@media (max-width: 768px) {
  .mobile-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 1rem;
    background: white;
    border-bottom: 1px solid #e2e8f0;
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    z-index: 100;
    height: 60px;
  }

  .menu-toggle {
    background: none;
    border: none;
    font-size: 1.5rem;
    color: #1e293b;
    cursor: pointer;
    padding: 0.5rem;
    min-width: 44px;
    min-height: 44px;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .mobile-title {
    font-size: 1.125rem;
    font-weight: 600;
    color: #1e293b;
    margin: 0;
  }

  .mobile-user {
    width: 36px;
    height: 36px;
    border-radius: 50%;
    background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: 600;
    font-size: 0.75rem;
    color: white;
  }

  .main-layout {
    flex-direction: column;
  }

  .sidebar {
    position: fixed;
    top: 0;
    left: 0;
    bottom: 0;
    width: 280px;
    transform: translateX(-100%);
    z-index: 1001;
  }

  .sidebar.mobile-open {
    transform: translateX(0);
  }

  .sidebar-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .close-mobile {
    display: flex;
    align-items: center;
    justify-content: center;
    background: none;
    border: none;
    color: white;
    font-size: 1.25rem;
    cursor: pointer;
    padding: 0.5rem;
    min-width: 44px;
    min-height: 44px;
  }

  .main-content {
    margin-top: 60px;
  }

  .content-wrapper {
    padding: 1rem;
  }

  .top-bar {
    padding: 0.75rem 1rem;
  }

  .search-bar {
    max-width: 100%;
  }

  .mobile-overlay {
    display: block;
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.5);
    z-index: 1000;
    opacity: 0;
    pointer-events: none;
    transition: opacity 0.3s ease;
  }

  .mobile-overlay.active {
    opacity: 1;
    pointer-events: all;
  }
}
</style>
