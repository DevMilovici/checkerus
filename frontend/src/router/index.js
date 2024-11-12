import { createRouter, createWebHistory } from 'vue-router'
import useAuthStore from "@/stores/auth";

import HomeView from '../views/HomeView.vue'
import LoginView from '@/views/LoginView.vue'

import { useToast } from 'primevue/usetoast';

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: HomeView,
    },
    {
      path: '/login',
      name: 'login',
      component: LoginView,
    },
    {
      path: '/about',
      name: 'about',
      // route level code-splitting
      // this generates a separate chunk (About.[hash].js) for this route
      // which is lazy-loaded when the route is visited.
      component: () => import('../views/AboutView.vue'),
    },
  ],
});

router.beforeEach(async (to) => {
  // Redirect to login page if logged in and trying to access a restricted page
  const publicPages = ["/login", "/about"];
  const authRequired = !publicPages.includes(to.path);
  const authStore = useAuthStore();
  // console.log(authRequired)

  // If the user is authenticated and tries to access the login page,
  //    then redirect her to the main page "/".
  if(to.path?.includes("/login") 
    && authStore?.user != null 
    && authStore?.isAuthenticated) {
    console.log("User is already authenticated Redirect to home")
    return "/";
  }

  if(authRequired && !authStore.user) {
    authStore.returnUrl = to.fullPath;
    return "/login";
  }

  if(authRequired && authStore.user) {
    // Check the jwt expiration
    // TODO: Remove this return after the jwt is implemented accordingly
    return;
    console.log("Check the jwt expiration")
    try {
      let base64Url = authStore.user.jwt.split(".")[1];
      let base64 = base64Url.replace(/-/g, "+").replace(/_/g, "/");
      let jsonPayload = decodeURIComponent(
        window
          .atob(base64)
          .split("")
          .map(function (c) {
            return "%" + ("00" + c.charCodeAt(0).toString(16)).slice(-2);
          })
          .join("")
      );

      let jwtDecoded = JSON.parse(jsonPayload);
      let current_time = Date.now() / 1000;
      if (jwtDecoded.exp < current_time) {
        // Then logout
        authStore.logout();
        return "/login";
      }
    } catch (error) {
      authStore.logout();
      
      const toast = useToast();
      toast.add({ severity: 'error', summary: 'Credențialele au expirat!', life: 3000 });
      
      return "/login";
    }
  }
});

export default router;
