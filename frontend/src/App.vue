<template>
  <div class="h-[100vh] flex items-center justify-center align-center">
    <!-- Header -->
    <header class="w-[300px] min-w-[300px] h-full flex flex-col justify-center p-2 border-r border-green-200">
      <!-- Logo image -->
      <div class="flex flex-row justify-center items-end gap-1 min-w-[200px] p-1 mb-4 ">
        <img alt="Vue logo" class="block w-[100px]" src="@/assets/ap.png" />
        <h1 class="font-bold text-4xl text-green-400">Checker</h1>
      </div>
      <div class="flex flex-col gap-2 items-center ">
        <!-- Links -->
        <nav class="flex flex-row">
          <RouterLink class="p-2 text-lg" v-if="isAuthenticated" to="/">Acasă</RouterLink>
          <RouterLink class="p-2 text-lg" v-if="!isAuthenticated" to="/login">Autentificare</RouterLink>
          <RouterLink class="p-2 text-lg" to="/about">Despre</RouterLink>
        </nav>
        <!-- Logout button -->
        <div class="flex items-center justify-center w-[50px] h-[50px]">
          <Button v-if="isAuthenticated" icon="pi pi-sign-out" severity="danger" @click="logout()" />
        </div>
      </div>
    </header>
    <!-- Router view -->
    <RouterView class="h-full w-full"/>
  </div>
</template>

<script>
import { RouterLink, RouterView } from 'vue-router'
import useAuthStore from "@/stores/auth";

export default {
  name: "App",
  components: {
    RouterLink, RouterView
  },
  computed: {
    isAuthenticated() {
      return useAuthStore().isAuthenticated;
    }
  },
  methods: {
    logout() {
      console.log("logout");
      useAuthStore().logout();
    }
  }
}

</script>

<style scoped lang="scss">

nav a.router-link-exact-active {
  color: var(--color-text);
}

nav a.router-link-exact-active:hover {
  background-color: transparent;
}

nav a {
  display: inline-block;
  border-left: 1px solid var(--color-border);
}

nav a:first-of-type {
  border: 0;
}

</style>
