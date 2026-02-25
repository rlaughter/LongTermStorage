<template>
  <MainLayout>
    <div class="audit-log-page">
      <div class="header">
        <h1>Audit Log</h1>
        <p class="subtitle">View all system activity and changes</p>
      </div>

      <Card>
        <template #content>
          <DataTable
            :value="auditEvents"
            :loading="loading"
            paginator
            :rows="50"
            :totalRecords="auditEvents.length"
            class="audit-table"
            :rowClass="rowClass"
            stripedRows
          >
            <template #empty>
              <div class="empty-state">
                <i class="pi pi-history"></i>
                <p>No audit events found</p>
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

            <Column header="Entity" style="min-width: 150px">
              <template #body="{ data }">
                <div class="entity-info">
                  <span class="entity-type">{{ data.entity_type }}</span>
                  <span v-if="data.document_filename" class="entity-name">
                    {{ data.document_filename }}
                  </span>
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
        <div class="detail-row">
          <strong>Entity Type:</strong>
          <span>{{ selectedEvent.entity_type }}</span>
        </div>
        <div v-if="selectedEvent.document_filename" class="detail-row">
          <strong>Document:</strong>
          <span>{{ selectedEvent.document_filename }}</span>
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
import { useToast } from 'primevue/usetoast';
import Card from 'primevue/card';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import Tag from 'primevue/tag';
import Button from 'primevue/button';
import Dialog from 'primevue/dialog';
import MainLayout from '@/components/MainLayout.vue';
import { auditService, type AuditEvent } from '@/services/audit.service';

const toast = useToast();
const auditEvents = ref<AuditEvent[]>([]);
const loading = ref(false);
const detailsVisible = ref(false);
const selectedEvent = ref<AuditEvent | null>(null);

onMounted(async () => {
  await loadAuditEvents();
});

async function loadAuditEvents() {
  loading.value = true;
  try {
    auditEvents.value = await auditService.getAuditLogs({ limit: 100 });
  } catch (error: any) {
    console.error('Error loading audit events:', error);
    toast.add({
      severity: 'error',
      summary: 'Error',
      detail: 'Failed to load audit events',
      life: 3000
    });
  } finally {
    loading.value = false;
  }
}

function showDetails(event: AuditEvent) {
  selectedEvent.value = event;
  detailsVisible.value = true;
}

function formatDateTime(dateString: string) {
  const date = new Date(dateString);
  return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
}

function rowClass(data: AuditEvent) {
  if (data.event_type === 'DELETE') return 'delete-row';
  if (data.event_type === 'CREATE') return 'create-row';
  return '';
}
</script>

<style scoped>
.audit-log-page {
  max-width: 1400px;
  margin: 0 auto;
}

.header {
  margin-bottom: 2rem;
}

.header h1 {
  font-size: 2rem;
  font-weight: 700;
  color: #1a202c;
  margin: 0 0 0.5rem 0;
}

.subtitle {
  color: #6c757d;
  font-size: 1rem;
  margin: 0;
}

.empty-state {
  text-align: center;
  padding: 3rem 1rem;
  color: #6c757d;
}

.empty-state i {
  font-size: 3rem;
  margin-bottom: 1rem;
  display: block;
  opacity: 0.5;
}

.empty-state p {
  font-size: 1.1rem;
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

.entity-info {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.entity-type {
  font-weight: 600;
  font-size: 0.875rem;
  color: #495057;
}

.entity-name {
  font-size: 0.875rem;
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

:deep(.delete-row) {
  background-color: #fff5f5 !important;
}

:deep(.create-row) {
  background-color: #f0fdf4 !important;
}

:deep(.audit-table .p-datatable-tbody > tr:hover) {
  background-color: #e9ecef !important;
}
</style>
