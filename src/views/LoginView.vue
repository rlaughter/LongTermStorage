<template>
  <div class="login-container">
    <div class="login-background">
      <div class="gradient-orb orb-1"></div>
      <div class="gradient-orb orb-2"></div>
      <div class="gradient-orb orb-3"></div>
    </div>

    <div class="login-content">
      <div class="login-card">
        <div class="login-header">
          <div class="logo-container">
            <div class="logo-icon">
              <i class="pi pi-book"></i>
            </div>
          </div>
          <h1 class="login-title">Welcome Back</h1>
          <p class="login-subtitle">K-12 Records Management System</p>
        </div>

        <form @submit.prevent="handleLogin" class="login-form">
          <div class="form-field">
            <label for="email" class="field-label">Email Address</label>
            <div class="input-wrapper">
              <i class="pi pi-envelope input-icon"></i>
              <InputText
                id="email"
                v-model="email"
                type="email"
                placeholder="you@school.edu"
                :class="['custom-input', { 'p-invalid': emailError }]"
                required
              />
            </div>
            <Transition name="error">
              <small v-if="emailError" class="field-error">{{ emailError }}</small>
            </Transition>
          </div>

          <div class="form-field">
            <label for="password" class="field-label">Password</label>
            <div class="input-wrapper">
              <i class="pi pi-lock input-icon"></i>
              <Password
                id="password"
                v-model="password"
                placeholder="Enter your password"
                :feedback="false"
                toggle-mask
                :class="['custom-input', { 'p-invalid': passwordError }]"
                :input-class="'password-input'"
                required
              />
            </div>
            <Transition name="error">
              <small v-if="passwordError" class="field-error">{{ passwordError }}</small>
            </Transition>
          </div>

          <Transition name="fade">
            <div v-if="error" class="error-message">
              <i class="pi pi-exclamation-circle"></i>
              <span>{{ error }}</span>
            </div>
          </Transition>

          <Button
            type="submit"
            label="Sign In"
            :loading="loading"
            class="login-button"
            icon-pos="right"
          >
            <template #icon>
              <i class="pi pi-arrow-right"></i>
            </template>
          </Button>

          <div class="login-footer">
            <p class="demo-notice">
              <i class="pi pi-info-circle"></i>
              Demo credentials: demo@school.edu / demo123
            </p>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useToast } from 'primevue/usetoast';
import Card from 'primevue/card';
import InputText from 'primevue/inputtext';
import Password from 'primevue/password';
import Button from 'primevue/button';
import Message from 'primevue/message';
import { useAuthStore } from '@/stores/auth.store';

const router = useRouter();
const route = useRoute();
const toast = useToast();
const authStore = useAuthStore();

const email = ref('');
const password = ref('');
const emailError = ref('');
const passwordError = ref('');
const error = ref('');
const loading = ref(false);

async function handleLogin() {
  emailError.value = '';
  passwordError.value = '';
  error.value = '';

  if (!email.value) {
    emailError.value = 'Email is required';
    return;
  }

  if (!password.value) {
    passwordError.value = 'Password is required';
    return;
  }

  loading.value = true;

  const result = await authStore.signIn(email.value, password.value);

  loading.value = false;

  if (result.success) {
    toast.add({
      severity: 'success',
      summary: 'Welcome!',
      detail: 'You have successfully signed in',
      life: 3000
    });

    const redirectPath = route.query.redirect as string || '/';
    router.push(redirectPath);
  } else {
    error.value = result.error || 'Invalid email or password';
  }
}
</script>

<style scoped>
.login-container {
  position: relative;
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  overflow: hidden;
  background: linear-gradient(135deg, #0f172a 0%, #1e293b 50%, #334155 100%);
}

.login-background {
  position: absolute;
  inset: 0;
  overflow: hidden;
}

.gradient-orb {
  position: absolute;
  border-radius: 50%;
  filter: blur(80px);
  opacity: 0.3;
  animation: float 20s ease-in-out infinite;
}

.orb-1 {
  width: 500px;
  height: 500px;
  background: linear-gradient(135deg, #3b82f6 0%, #06b6d4 100%);
  top: -10%;
  left: -10%;
  animation-delay: 0s;
}

.orb-2 {
  width: 400px;
  height: 400px;
  background: linear-gradient(135deg, #06b6d4 0%, #10b981 100%);
  bottom: -10%;
  right: -10%;
  animation-delay: -7s;
}

.orb-3 {
  width: 350px;
  height: 350px;
  background: linear-gradient(135deg, #10b981 0%, #3b82f6 100%);
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  animation-delay: -14s;
}

@keyframes float {
  0%, 100% {
    transform: translate(0, 0) scale(1);
  }
  33% {
    transform: translate(30px, -30px) scale(1.1);
  }
  66% {
    transform: translate(-20px, 20px) scale(0.9);
  }
}

.login-content {
  position: relative;
  z-index: 1;
  width: 100%;
  max-width: 480px;
  padding: 1.5rem;
  animation: fadeInUp 0.6s ease-out;
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(30px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.login-card {
  background: rgba(255, 255, 255, 0.98);
  backdrop-filter: blur(20px);
  border-radius: 24px;
  padding: 3rem 2.5rem;
  box-shadow:
    0 20px 60px rgba(0, 0, 0, 0.3),
    0 0 0 1px rgba(255, 255, 255, 0.1);
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.login-card:hover {
  transform: translateY(-4px);
  box-shadow:
    0 24px 70px rgba(0, 0, 0, 0.35),
    0 0 0 1px rgba(255, 255, 255, 0.15);
}

.login-header {
  text-align: center;
  margin-bottom: 2.5rem;
}

.logo-container {
  display: flex;
  justify-content: center;
  margin-bottom: 1.5rem;
}

.logo-icon {
  width: 64px;
  height: 64px;
  background: linear-gradient(135deg, #3b82f6 0%, #06b6d4 100%);
  border-radius: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 8px 24px rgba(59, 130, 246, 0.3);
  animation: pulse 2s ease-in-out infinite;
}

@keyframes pulse {
  0%, 100% {
    transform: scale(1);
    box-shadow: 0 8px 24px rgba(59, 130, 246, 0.3);
  }
  50% {
    transform: scale(1.05);
    box-shadow: 0 12px 32px rgba(59, 130, 246, 0.4);
  }
}

.logo-icon i {
  font-size: 2rem;
  color: white;
}

.login-title {
  font-size: 2rem;
  font-weight: 700;
  color: #0f172a;
  margin: 0 0 0.5rem 0;
  letter-spacing: -0.02em;
}

.login-subtitle {
  font-size: 0.9375rem;
  color: #64748b;
  margin: 0;
  font-weight: 500;
}

.login-form {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.form-field {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.field-label {
  font-size: 0.875rem;
  font-weight: 600;
  color: #334155;
  letter-spacing: 0.01em;
}

.input-wrapper {
  position: relative;
}

.input-icon {
  position: absolute;
  left: 1rem;
  top: 50%;
  transform: translateY(-50%);
  color: #94a3b8;
  font-size: 1.125rem;
  z-index: 1;
  pointer-events: none;
  transition: color 0.2s ease;
}

.input-wrapper:focus-within .input-icon {
  color: #3b82f6;
}

:deep(.custom-input) {
  width: 100%;
  padding: 0.875rem 1rem 0.875rem 3rem;
  border: 2px solid #e2e8f0;
  border-radius: 12px;
  font-size: 0.9375rem;
  transition: all 0.2s ease;
  background: white;
}

:deep(.custom-input:hover) {
  border-color: #cbd5e1;
}

:deep(.custom-input:focus) {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.1);
}

:deep(.custom-input.p-invalid) {
  border-color: #ef4444;
}

:deep(.custom-input.p-invalid:focus) {
  box-shadow: 0 0 0 4px rgba(239, 68, 68, 0.1);
}

:deep(.p-password) {
  width: 100%;
}

:deep(.p-password .p-inputtext) {
  width: 100%;
  padding: 0.875rem 3rem 0.875rem 3rem;
  border: 2px solid #e2e8f0;
  border-radius: 12px;
  font-size: 0.9375rem;
  transition: all 0.2s ease;
}

:deep(.p-password .p-inputtext:hover) {
  border-color: #cbd5e1;
}

:deep(.p-password .p-inputtext:focus) {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.1);
}

:deep(.p-password.p-invalid .p-inputtext) {
  border-color: #ef4444;
}

:deep(.p-password.p-invalid .p-inputtext:focus) {
  box-shadow: 0 0 0 4px rgba(239, 68, 68, 0.1);
}

:deep(.p-password .p-icon) {
  color: #94a3b8;
}

.field-error {
  color: #ef4444;
  font-size: 0.8125rem;
  font-weight: 500;
  display: flex;
  align-items: center;
  gap: 0.25rem;
}

.error-message {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 1rem;
  background: #fef2f2;
  border: 1px solid #fecaca;
  border-radius: 12px;
  color: #dc2626;
  font-size: 0.875rem;
  font-weight: 500;
}

.error-message i {
  font-size: 1.125rem;
}

.login-button {
  width: 100%;
  padding: 0.875rem 1.5rem;
  font-size: 1rem;
  font-weight: 600;
  border-radius: 12px;
  background: linear-gradient(135deg, #3b82f6 0%, #06b6d4 100%);
  border: none;
  color: white;
  transition: all 0.2s ease;
  margin-top: 0.5rem;
}

.login-button:hover:not(:disabled) {
  background: linear-gradient(135deg, #2563eb 0%, #0891b2 100%);
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(59, 130, 246, 0.3);
}

.login-button:active:not(:disabled) {
  transform: translateY(0);
}

:deep(.login-button .p-button-label) {
  flex: 1;
  text-align: center;
}

.login-footer {
  margin-top: 1.5rem;
  padding-top: 1.5rem;
  border-top: 1px solid #e2e8f0;
}

.demo-notice {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  font-size: 0.8125rem;
  color: #64748b;
  margin: 0;
  padding: 0.75rem;
  background: #f8fafc;
  border-radius: 8px;
}

.demo-notice i {
  color: #3b82f6;
}

.error-enter-active, .error-leave-active {
  transition: all 0.2s ease;
}

.error-enter-from, .error-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}

.fade-enter-active, .fade-leave-active {
  transition: all 0.3s ease;
}

.fade-enter-from, .fade-leave-to {
  opacity: 0;
  transform: scale(0.95);
}

@media (max-width: 640px) {
  .login-content {
    padding: 1rem;
  }

  .login-card {
    padding: 2rem 1.5rem;
    border-radius: 20px;
  }

  .login-title {
    font-size: 1.75rem;
  }

  .logo-icon {
    width: 56px;
    height: 56px;
  }

  .logo-icon i {
    font-size: 1.75rem;
  }

  .orb-1, .orb-2, .orb-3 {
    width: 300px;
    height: 300px;
  }
}
</style>
