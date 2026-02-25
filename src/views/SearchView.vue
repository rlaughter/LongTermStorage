<template>
  <MainLayout>
    <Card>
      <template #content>
        <div class="search-bar">
          <InputText
            v-model="searchQuery"
            placeholder="Search by filename, employee ID, student ID..."
            class="search-input"
            @keyup.enter="performSearch"
          />
          <Button
            label="Search"
            @click="performSearch"
            :loading="searching"
          />
        </div>

        <DataTable
          v-if="searchResults.length > 0"
          :value="searchResults"
          :loading="searching"
          class="mt-3"
        >
          <Column field="filename" header="File Name"></Column>
          <Column field="file_type" header="Type">
            <template #body="slotProps">
              <Tag :value="slotProps.data.file_type" />
            </template>
          </Column>
          <Column field="program" header="Program"></Column>
          <Column field="employee_id" header="Employee ID"></Column>
          <Column field="student_id" header="Student ID"></Column>
          <Column header="Actions">
            <template #body="slotProps">
              <Button
                icon="pi pi-eye"
                text
                rounded
                @click="viewDocument(slotProps.data.id)"
              />
            </template>
          </Column>
        </DataTable>

        <div v-else-if="searched" class="empty-state">
          <i class="pi pi-search" style="font-size: 3rem; color: #ccc;"></i>
          <p>No documents found matching your search</p>
        </div>
      </template>
    </Card>
  </MainLayout>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useToast } from 'primevue/usetoast';
import Card from 'primevue/card';
import Button from 'primevue/button';
import InputText from 'primevue/inputtext';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Tag from 'primevue/tag';
import MainLayout from '@/components/MainLayout.vue';
import { useAuthStore } from '@/stores/auth.store';
import { supabase } from '@/lib/supabase';

const router = useRouter();
const toast = useToast();
const authStore = useAuthStore();

const searchQuery = ref('');
const searchResults = ref<any[]>([]);
const searching = ref(false);
const searched = ref(false);

onMounted(() => {
  if (history.state && history.state.results) {
    searchResults.value = history.state.results;
    searchQuery.value = history.state.query || '';
    searched.value = true;
  }
});

async function performSearch() {
  if (!searchQuery.value.trim()) return;

  searching.value = true;
  searched.value = true;

  try {
    const programIds = authStore.userRoles
      .filter(role => role.program_id)
      .map(role => role.program_id);

    if (programIds.length === 0) {
      searching.value = false;
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

    searchResults.value = data.map((doc: any) => ({
      ...doc,
      program: doc.programs?.name || 'Unknown'
    }));
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

function viewDocument(id: string) {
  router.push(`/documents/${id}`);
}
</script>

<style scoped>
.search-bar {
  display: flex;
  gap: 1rem;
  align-items: center;
  margin-bottom: 2rem;
}

.search-input {
  flex: 1;
}

.mt-3 {
  margin-top: 1.5rem;
}

.empty-state {
  text-align: center;
  padding: 3rem;
  margin-top: 2rem;
}

.empty-state p {
  margin-top: 1rem;
  color: #6c757d;
  font-size: 1.1rem;
}
</style>
