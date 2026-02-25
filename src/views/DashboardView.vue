<template>
  <MainLayout>
    <div class="dashboard-content">
      <div class="stats-grid">
        <Card>
          <template #title>Total Documents</template>
          <template #content>
            <div class="stat-value">{{ stats.totalDocuments }}</div>
          </template>
        </Card>

        <Card>
          <template #title>This Month</template>
          <template #content>
            <div class="stat-value">{{ stats.thisMonth }}</div>
          </template>
        </Card>

        <Card>
          <template #title>Active Programs</template>
          <template #content>
            <div class="stat-value">{{ stats.activePrograms }}</div>
          </template>
        </Card>

        <Card>
          <template #title>Pending Reviews</template>
          <template #content>
            <div class="stat-value">{{ stats.pendingReviews }}</div>
          </template>
        </Card>
      </div>

      <div class="quick-actions">
        <h2>Quick Actions</h2>
        <div class="action-buttons">
          <Button
            label="Upload Document"
            icon="pi pi-upload"
            @click="router.push('/upload')"
          />
          <Button
            label="Search Documents"
            icon="pi pi-search"
            severity="secondary"
            @click="router.push('/search')"
          />
          <Button
            label="View All Documents"
            icon="pi pi-folder-open"
            severity="info"
            @click="router.push('/documents')"
          />
        </div>
      </div>

      <div class="recent-documents">
        <h2>Recent Documents</h2>
        <DataTable
          :value="recentDocuments"
          :loading="loading"
          paginator
          :rows="5"
          responsive-layout="scroll"
        >
          <Column field="filename" header="File Name" sortable></Column>
          <Column field="file_type" header="Type" sortable></Column>
          <Column field="program" header="Program"></Column>
          <Column field="uploaded_at" header="Uploaded" sortable>
            <template #body="slotProps">
              {{ formatDate(slotProps.data.uploaded_at) }}
            </template>
          </Column>
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
      </div>
    </div>
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
import MainLayout from '@/components/MainLayout.vue';
import { useAuthStore } from '@/stores/auth.store';
import { supabase } from '@/lib/supabase';

const router = useRouter();
const toast = useToast();
const authStore = useAuthStore();

const stats = ref({
  totalDocuments: 0,
  thisMonth: 0,
  activePrograms: 0,
  pendingReviews: 0
});

const recentDocuments = ref<any[]>([]);
const loading = ref(false);

onMounted(async () => {
  await loadDashboardData();
});

async function loadDashboardData() {
  loading.value = true;

  try {
    const programIds = authStore.accessibleProgramIds;

    if (programIds.length === 0) {
      stats.value = {
        totalDocuments: 0,
        thisMonth: 0,
        activePrograms: 0,
        pendingReviews: 0
      };
      recentDocuments.value = [];
      loading.value = false;
      toast.add({
        severity: 'info',
        summary: 'No Access',
        detail: 'You do not have access to any programs. Please contact your administrator.',
        life: 5000
      });
      return;
    }

    const { data: documents, error: documentsError } = await supabase
      .from('documents')
      .select(`
        id,
        filename,
        file_type,
        uploaded_at,
        programs (
          name
        )
      `)
      .in('program_id', programIds)
      .order('uploaded_at', { ascending: false })
      .limit(5);

    if (documentsError) {
      throw documentsError;
    }

    recentDocuments.value = documents.map((doc: any) => ({
      ...doc,
      program: doc.programs?.name || 'Unknown'
    }));

    const { count } = await supabase
      .from('documents')
      .select('*', { count: 'exact', head: true })
      .in('program_id', programIds);

    stats.value.totalDocuments = count || 0;

    const startOfMonth = new Date();
    startOfMonth.setDate(1);
    startOfMonth.setHours(0, 0, 0, 0);

    const { count: monthCount } = await supabase
      .from('documents')
      .select('*', { count: 'exact', head: true })
      .in('program_id', programIds)
      .gte('uploaded_at', startOfMonth.toISOString());

    stats.value.thisMonth = monthCount || 0;
    stats.value.activePrograms = programIds.length;
    stats.value.pendingReviews = 0;
  } catch (error: any) {
    console.error('Error loading dashboard data:', error);
    toast.add({
      severity: 'error',
      summary: 'Error',
      detail: 'Failed to load dashboard data',
      life: 3000
    });
  } finally {
    loading.value = false;
  }
}

function viewDocument(id: string) {
  router.push(`/documents/${id}`);
}

function formatDate(dateString: string) {
  const date = new Date(dateString);
  return date.toLocaleDateString() + ' ' + date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
}
</script>

<style scoped>
.dashboard-content {
  max-width: 1200px;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.stat-value {
  font-size: 2.5rem;
  font-weight: 700;
  color: #667eea;
}

.quick-actions {
  margin-bottom: 2rem;
}

.quick-actions h2 {
  font-size: 1.5rem;
  margin-bottom: 1rem;
  color: #333;
}

.action-buttons {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
}

.recent-documents h2 {
  font-size: 1.5rem;
  margin-bottom: 1rem;
  color: #333;
}
</style>
