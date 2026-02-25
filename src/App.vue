<template>
  <div id="app">
    <Toast />
    <router-view />
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue';
import Toast from 'primevue/toast';
import { useAuthStore } from './stores/auth.store';

const authStore = useAuthStore();

onMounted(async () => {
  await authStore.initialize();
});
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

html,
body {
  height: 100%;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
}

#app {
  height: 100%;
}
</style>
