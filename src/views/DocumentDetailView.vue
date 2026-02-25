<template>
  <MainLayout>
    <div class="document-detail-page">
      <Card v-if="document">
        <template #title>{{ document.filename }}</template>
        <template #content>
          <div class="details-grid">
            <div class="detail-item">
              <label>File Type:</label>
              <span>{{ document.file_type }}</span>
            </div>
            <div class="detail-item">
              <label>Size:</label>
              <span>{{ formatFileSize(document.file_size_bytes) }}</span>
            </div>
            <div class="detail-item">
              <label>Program:</label>
              <span>{{ document.program }}</span>
            </div>
            <div class="detail-item">
              <label>Employee ID:</label>
              <span>{{ document.employee_id || 'N/A' }}</span>
            </div>
            <div class="detail-item">
              <label>Student ID:</label>
              <span>{{ document.student_id || 'N/A' }}</span>
            </div>
            <div class="detail-item">
              <label>School Year:</label>
              <span>{{ document.school_year || 'N/A' }}</span>
            </div>
            <div class="detail-item">
              <label>Uploaded:</label>
              <span>{{ formatDate(document.uploaded_at) }}</span>
            </div>
          </div>

          <div class="actions">
            <Button
              label="Download"
              icon="pi pi-download"
              @click="downloadDocument"
            />
          </div>
        </template>
      </Card>

      <Card class="audit-log-card">
        <template #title>
          <div class="audit-header">
            <i class="pi pi-history"></i>
            <span>Document Audit Log</span>
          </div>
        </template>
        <template #content>
          <DataTable
            :value="auditEvents"
            :loading="loadingAudit"
            :rows="10"
            paginator
            class="audit-table"
            stripedRows
          >
            <template #empty>
              <div class="empty-state">
                <i class="pi pi-history"></i>
                <p>No audit events for this document</p>
              </div>
            </template>

            <Column header="Time" style="width: 180px">
              <template #body="{ data }">
                <div class="timestamp">
                  {{ formatDateTime(data.created_at) }}
                </div>
              </template>
            </Column>

            <Column header="Event" style="width: 150px">
              <template #body="{ data }">
                <Tag
                  :severity="auditService.getEventTypeColor(data.event_type)"
                  :icon="`pi ${auditService.getEventTypeIcon(data.event_type)}`"
                >
                  {{ data.event_type }}
                </Tag>
              </template>
            </Column>

            <Column field="action" header="Action" style="min-width: 200px"></Column>

            <Column header="User" style="min-width: 200px">
              <template #body="{ data }">
                <div class="user-info">
                  <i class="pi pi-user"></i>
                  {{ data.user_email }}
                </div>
              </template>
            </Column>

            <Column header="Details" style="width: 100px">
              <template #body="{ data }">
                <Button
                  v-if="data.details"
                  icon="pi pi-info-circle"
                  text
                  rounded
                  @click="showDetails(data)"
                  v-tooltip.top="'View Details'"
                />
              </template>
            </Column>
          </DataTable>
        </template>
      </Card>
    </div>

    <Dialog
      v-model:visible="detailsVisible"
      modal
      :header="`Event Details - ${selectedEvent?.action}`"
      :style="{ width: '600px' }"
    >
      <div v-if="selectedEvent" class="event-details">
        <div class="detail-row">
          <strong>Event Type:</strong>
          <Tag
            :severity="auditService.getEventTypeColor(selectedEvent.event_type)"
            :icon="`pi ${auditService.getEventTypeIcon(selectedEvent.event_type)}`"
          >
            {{ selectedEvent.event_type }}
          </Tag>
        </div>
        <div class="detail-row">
          <strong>Time:</strong>
          <span>{{ formatDateTime(selectedEvent.created_at) }}</span>
        </div>
        <div class="detail-row">
          <strong>User:</strong>
          <span>{{ selectedEvent.user_email }}</span>
        </div>
        <div v-if="selectedEvent.ip_address" class="detail-row">
          <strong>IP Address:</strong>
          <span>{{ selectedEvent.ip_address }}</span>
        </div>
        <div v-if="selectedEvent.details" class="detail-row details-json">
          <strong>Additional Details:</strong>
          <pre>{{ JSON.stringify(selectedEvent.details, null, 2) }}</pre>
        </div>
      </div>
    </Dialog>
  </MainLayout>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useToast } from 'primevue/usetoast';
import Card from 'primevue/card';
import Button from 'primevue/button';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Tag from 'primevue/tag';
import Dialog from 'primevue/dialog';
import MainLayout from '@/components/MainLayout.vue';
import { useAuthStore } from '@/stores/auth.store';
import { supabase } from '@/lib/supabase';
import { auditService, type AuditEvent } from '@/services/audit.service';

const router = useRouter();
const route = useRoute();
const toast = useToast();
const authStore = useAuthStore();

const document = ref<any>(null);
const auditEvents = ref<AuditEvent[]>([]);
const loadingAudit = ref(false);
const detailsVisible = ref(false);
const selectedEvent = ref<AuditEvent | null>(null);

onMounted(async () => {
  await loadDocument();
  await loadAuditEvents();
});

async function loadDocument() {
  const documentId = route.params.id as string;
  const programIds = authStore.accessibleProgramIds;

  if (programIds.length === 0) {
    toast.add({
      severity: 'error',
      summary: 'Access Denied',
      detail: 'You do not have access to any programs',
      life: 3000
    });
    router.push('/documents');
    return;
  }

  const { data, error } = await supabase
    .from('documents')
    .select(`
      *,
      programs (
        name
      )
    `)
    .eq('id', documentId)
    .in('program_id', programIds)
    .maybeSingle();

  if (error) {
    console.error('Error loading document:', error);
    toast.add({
      severity: 'error',
      summary: 'Error',
      detail: 'Failed to load document',
      life: 3000
    });
    return;
  }

  if (!data) {
    toast.add({
      severity: 'error',
      summary: 'Access Denied',
      detail: 'You do not have permission to view this document',
      life: 3000
    });
    router.push('/documents');
    return;
  }

  document.value = {
    ...data,
    program: data.programs?.name || 'Unknown'
  };

  await auditService.createAuditEvent({
    event_type: 'VIEW',
    entity_type: 'DOCUMENT',
    entity_id: data.id,
    document_id: data.id,
    action: `Viewed document: ${data.filename}`,
    details: {
      filename: data.filename,
      program: data.programs?.name
    }
  });
}

async function loadAuditEvents() {
  const documentId = route.params.id as string;
  loadingAudit.value = true;
  try {
    auditEvents.value = await auditService.getAuditLogs({
      documentId,
      limit: 50
    });
  } catch (error: any) {
    console.error('Error loading audit events:', error);
  } finally {
    loadingAudit.value = false;
  }
}

async function downloadDocument() {
  if (!document.value) return;

  try {
    const { data, error } = await supabase.storage
      .from('documents')
      .download(document.value.storage_path);

    if (error) {
      throw error;
    }

    const url = window.URL.createObjectURL(data);
    const link = window.document.createElement('a');
    link.href = url;
    link.download = document.value.filename;
    link.click();
    window.URL.revokeObjectURL(url);

    await auditService.createAuditEvent({
      event_type: 'DOWNLOAD',
      entity_type: 'DOCUMENT',
      entity_id: document.value.id,
      document_id: document.value.id,
      action: `Downloaded document: ${document.value.filename}`,
      details: {
        filename: document.value.filename,
        file_type: document.value.file_type,
        file_size_bytes: document.value.file_size_bytes
      }
    });

    await loadAuditEvents();

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

function showDetails(event: AuditEvent) {
  selectedEvent.value = event;
  detailsVisible.value = true;
}

function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
}

function formatDate(dateString: string) {
  const date = new Date(dateString);
  return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
}

function formatDateTime(dateString: string) {
  const date = new Date(dateString);
  return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
}
</script>

<style scoped>
.document-detail-page {
  max-width: 1400px;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.details-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.detail-item {
  display: flex;
  flex-direction: column;
}

.detail-item label {
  font-weight: 600;
  color: #6c757d;
  margin-bottom: 0.25rem;
  font-size: 0.875rem;
}

.detail-item span {
  color: #333;
  font-size: 1rem;
}

.actions {
  display: flex;
  gap: 1rem;
}

.audit-log-card {
  margin-top: 2rem;
}

.audit-header {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  font-size: 1.25rem;
  font-weight: 600;
}

.audit-header i {
  color: #6c757d;
}

.empty-state {
  text-align: center;
  padding: 2rem 1rem;
  color: #6c757d;
}

.empty-state i {
  font-size: 2.5rem;
  margin-bottom: 1rem;
  display: block;
  opacity: 0.5;
}

.empty-state p {
  font-size: 1rem;
  margin: 0;
}

.timestamp {
  font-size: 0.875rem;
  color: #495057;
  font-family: monospace;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.user-info i {
  color: #6c757d;
}

.event-details {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.detail-row {
  display: flex;
  gap: 1rem;
  align-items: flex-start;
}

.detail-row strong {
  min-width: 150px;
  color: #495057;
}

.details-json {
  flex-direction: column;
  align-items: flex-start;
}

.details-json pre {
  background: #f8f9fa;
  padding: 1rem;
  border-radius: 4px;
  overflow-x: auto;
  width: 100%;
  margin: 0.5rem 0 0 0;
  font-size: 0.875rem;
}
</style>
