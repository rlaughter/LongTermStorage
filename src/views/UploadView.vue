<template>
  <MainLayout>
    <Card>
      <template #content>
        <form @submit.prevent="handleUpload">
          <div class="form-grid">
            <div class="field">
              <label for="program">Program *</label>
              <Dropdown
                id="program"
                v-model="selectedProgram"
                :options="userPrograms"
                option-label="name"
                option-value="id"
                placeholder="Select a program"
                :class="{ 'p-invalid': submitted && !selectedProgram }"
              />
              <small v-if="submitted && !selectedProgram" class="p-error">Program is required</small>
            </div>

            <div class="field">
              <label for="file">File *</label>
              <FileUpload
                id="file"
                mode="basic"
                :custom-upload="true"
                @select="onFileSelect"
                :auto="false"
                choose-label="Choose File"
              />
              <small v-if="submitted && !selectedFile" class="p-error">File is required</small>
            </div>

            <div class="field">
              <label for="employee-id">Employee ID</label>
              <InputText id="employee-id" v-model="formData.employee_id" />
            </div>

            <div class="field">
              <label for="student-id">Student ID</label>
              <InputText id="student-id" v-model="formData.student_id" />
            </div>

            <div class="field">
              <label for="school-year">School Year</label>
              <InputText id="school-year" v-model="formData.school_year" placeholder="2023-2024" />
            </div>

            <div class="field">
              <label for="campus">Campus</label>
              <InputText id="campus" v-model="formData.campus" />
            </div>

            <div class="field">
              <label for="category">Category</label>
              <InputText id="category" v-model="formData.category" />
            </div>

            <div class="field full-width">
              <Button
                type="submit"
                label="Upload Document"
                icon="pi pi-upload"
                :loading="uploading"
                class="w-full"
              />
            </div>
          </div>
        </form>
      </template>
    </Card>
  </MainLayout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useToast } from 'primevue/usetoast';
import Card from 'primevue/card';
import Button from 'primevue/button';
import InputText from 'primevue/inputtext';
import Dropdown from 'primevue/dropdown';
import FileUpload from 'primevue/fileupload';
import MainLayout from '@/components/MainLayout.vue';
import { useAuthStore } from '@/stores/auth.store';
import { supabase } from '@/lib/supabase';
import { auditService } from '@/services/audit.service';

const router = useRouter();
const toast = useToast();
const authStore = useAuthStore();

const selectedProgram = ref('');
const selectedFile = ref<File | null>(null);
const uploading = ref(false);
const submitted = ref(false);

const formData = ref({
  employee_id: '',
  student_id: '',
  school_year: '',
  campus: '',
  category: ''
});

const userPrograms = ref<any[]>([]);

const programDetails = computed(() => {
  const programId = selectedProgram.value;
  return userPrograms.value.find(p => p.id === programId);
});

onMounted(async () => {
  await loadPrograms();
});

async function loadPrograms() {
  const programIds = authStore.accessibleProgramIds;

  if (programIds.length === 0) {
    toast.add({
      severity: 'warn',
      summary: 'No Access',
      detail: 'You do not have access to any programs. Please contact your administrator.',
      life: 5000
    });
    return;
  }

  const { data, error } = await supabase
    .from('programs')
    .select(`
      id,
      name,
      code,
      department_id,
      tenant_id,
      organization_unit_id
    `)
    .in('id', programIds);

  if (error) {
    console.error('Error loading programs:', error);
    toast.add({
      severity: 'error',
      summary: 'Error',
      detail: 'Failed to load programs',
      life: 3000
    });
    return;
  }

  userPrograms.value = data;
}

function onFileSelect(event: any) {
  selectedFile.value = event.files[0];
}

async function handleUpload() {
  submitted.value = true;

  if (!selectedProgram.value || !selectedFile.value) {
    return;
  }

  uploading.value = true;

  try {
    const file = selectedFile.value;
    const program = programDetails.value;

    const fileExtension = file.name.split('.').pop();
    const timestamp = Date.now();
    const storagePath = `${authStore.tenantId}/${selectedProgram.value}/${timestamp}.${fileExtension}`;

    const { error: uploadError } = await supabase.storage
      .from('documents')
      .upload(storagePath, file);

    if (uploadError) {
      throw uploadError;
    }

    const { data: insertedDoc, error: insertError } = await supabase
      .from('documents')
      .insert({
        tenant_id: authStore.tenantId,
        organization_unit_id: program.organization_unit_id,
        department_id: program.department_id,
        program_id: selectedProgram.value,
        filename: file.name,
        original_filename: file.name,
        file_type: fileExtension || 'unknown',
        file_size_bytes: file.size,
        storage_path: storagePath,
        mime_type: file.type,
        status: 'ACTIVE',
        employee_id: formData.value.employee_id || null,
        student_id: formData.value.student_id || null,
        school_year: formData.value.school_year || null,
        campus: formData.value.campus || null,
        category: formData.value.category || null,
        uploaded_by: authStore.user?.id
      })
      .select()
      .single();

    if (insertError) {
      throw insertError;
    }

    await auditService.createAuditEvent({
      event_type: 'CREATE',
      entity_type: 'DOCUMENT',
      entity_id: insertedDoc.id,
      document_id: insertedDoc.id,
      action: 'Document uploaded',
      details: {
        filename: file.name,
        file_size: file.size,
        program_id: selectedProgram.value,
        program_name: program.name
      }
    });

    toast.add({
      severity: 'success',
      summary: 'Success',
      detail: 'Document uploaded successfully',
      life: 3000
    });

    router.push('/documents');
  } catch (error: any) {
    console.error('Error uploading document:', error);
    toast.add({
      severity: 'error',
      summary: 'Error',
      detail: error.message || 'Failed to upload document',
      life: 3000
    });
  } finally {
    uploading.value = false;
  }
}
</script>

<style scoped>
.form-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 1.5rem;
}

.field {
  display: flex;
  flex-direction: column;
}

.field.full-width {
  grid-column: 1 / -1;
}

.field label {
  margin-bottom: 0.5rem;
  font-weight: 600;
  color: #495057;
}

.w-full {
  width: 100%;
}
</style>
