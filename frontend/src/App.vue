<script setup>
import { RouterLink, RouterView } from 'vue-router'
</script>

<template>
  <header class="border-r">
    <img alt="Vue logo" class="logo" src="@/assets/a.png" width="125" height="125" />
    <img alt="Vue logo" class="logo" src="@/assets/p.png" width="125" height="125" />
    <div class="wrapper flex flex-col gap-2 items-center">
      <h1 class="text-4xl text-green-500">Checker</h1>
      <nav class="flex">
        <RouterLink to="/">Acasă</RouterLink>
        <RouterLink to="/login">Autentificare</RouterLink>
        <RouterLink to="/about">Despre</RouterLink>
      </nav>
    </div>
  </header>

  <RouterView />
</template>

<style scoped lang="scss">

header {
  line-height: 1.5;
  max-height: 100vh;
}

.logo {
  display: block;
  margin: 0 auto 2rem;
}

nav {
  width: 100%;
  font-size: 15px;
  text-align: center;
}

nav a.router-link-exact-active {
  color: var(--color-text);
}

nav a.router-link-exact-active:hover {
  background-color: transparent;
}

nav a {
  display: inline-block;
  padding: 0 1rem;
  border-left: 1px solid var(--color-border);
}

nav a:first-of-type {
  border: 0;
}

@media (min-width: 1024px) {
  header {
    display: flex;
    place-items: center;
    padding-right: calc(var(--section-gap) / 2);
  }

  .logo {
    margin: 0 2rem 0 0;
  }
}
</style>
