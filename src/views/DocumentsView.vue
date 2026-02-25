<template>
  <MainLayout>
    <Card>
      <template #content>
        <DataTable
          :value="documents"
          :loading="loading"
          paginator
          :rows="10"
          :total-records="totalRecords"
          lazy
          @page="onPage"
          responsive-layout="scroll"
        >
          <template #empty>
            <div class="empty-state">
              <i class="pi pi-inbox" style="font-size: 3rem; color: #ccc;"></i>
              <p>No documents found</p>
            </div>
          </template>

          <Column field="filename" header="File Name" sortable></Column>
          <Column field="file_type" header="Type" sortable>
            <template #body="slotProps">
              <Tag :value="slotProps.data.file_type" />
            </template>
          </Column>
          <Column field="program" header="Program"></Column>
          <Column field="employee_id" header="Employee ID"></Column>
          <Column field="student_id" header="Student ID"></Column>
          <Column field="school_year" header="School Year"></Column>
          <Column field="uploaded_at" header="Uploaded" sortable>
            <template #body="slotProps">
              {{ formatDate(slotProps.data.uploaded_at) }}
            </template>
          </Column>
          <Column header="Actions">
            <template #body="slotProps">
              <div class="action-buttons">
                <Button
                  icon="pi pi-eye"
                  text
                  rounded
                  @click="viewDocument(slotProps.data.id)"
                  v-tooltip="'View'"
                />
                <Button
                  icon="pi pi-download"
                  text
                  rounded
                  @click="downloadDocument(slotProps.data)"
                  v-tooltip="'Download'"
                />
              </div>
            </template>
          </Column>
        </DataTable>
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
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Tag from 'primevue/tag';
import MainLayout from '@/components/MainLayout.vue';
import { useAuthStore } from '@/stores/auth.store';
import { supabase } from '@/lib/supabase';

const router = useRouter();
const toast = useToast();
const authStore = useAuthStore();

const documents = ref<any[]>([]);
const loading = ref(false);
const totalRecords = ref(0);

onMounted(async () => {
  await loadDocuments();
});

async function loadDocuments(page = 0, rows = 10) {
  loading.value = true;

  try {
    const programIds = authStore.accessibleProgramIds;

    if (programIds.length === 0) {
      documents.value = [];
      totalRecords.value = 0;
      toast.add({
        severity: 'info',
        summary: 'No Access',
        detail: 'You do not have access to any programs. Please contact your administrator.',
        life: 5000
      });
      loading.value = false;
      return;
    }

    const from = page * rows;
    const to = from + rows - 1;

    const { data, error, count } = await supabase
      .from('documents')
      .select(`
        id,
        filename,
        file_type,
        employee_id,
        student_id,
        school_year,
        uploaded_at,
        programs (
          name
        )
      `, { count: 'exact' })
      .in('program_id', programIds)
      .order('uploaded_at', { ascending: false })
      .range(from, to);

    if (error) {
      throw error;
    }

    documents.value = data.map((doc: any) => ({
      ...doc,
      program: doc.programs?.name || 'Unknown'
    }));

    totalRecords.value = count || 0;
  } catch (error: any) {
    console.error('Error loading documents:', error);
    toast.add({
      severity: 'error',
      summary: 'Error',
      detail: 'Failed to load documents',
      life: 3000
    });
  } finally {
    loading.value = false;
  }
}

function onPage(event: any) {
  loadDocuments(event.page, event.rows);
}

function viewDocument(id: string) {
  router.push(`/documents/${id}`);
}

async function downloadDocument(document: any) {
  try {
    const { data, error } = await supabase.storage
      .from('documents')
      .download(document.storage_path);

    if (error) {
      throw error;
    }

    const url = window.URL.createObjectURL(data);
    const link = window.document.createElement('a');
    link.href = url;
    link.download = document.filename;
    link.click();
    window.URL.revokeObjectURL(url);

    toast.add({
      severity: 'success',
      summary: 'Success',
      detail: 'Document downloaded successfully',
      life: 3000
    });
  } catch (error: any) {
    console.error('Error downloading document:', error);
    toast.add({
      severity: 'error',
      summary: 'Error',
      detail: 'Failed to download document',
      life: 3000
    });
  }
}

function formatDate(dateString: string) {
  const date = new Date(dateString);
  return date.toLocaleDateString();
}
</script>

<style scoped>
.empty-state {
  text-align: center;
  padding: 3rem;
}

.empty-state p {
  margin-top: 1rem;
  color: #6c757d;
  font-size: 1.1rem;
}

.action-buttons {
  display: flex;
  gap: 0.5rem;
}
</style>
