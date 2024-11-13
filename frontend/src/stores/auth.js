import router from '@/router';
import { defineStore } from 'pinia'

import fetchWrapper from "@/helpers/fetch-wrapper";
const API_URL = `${import.meta.env.VITE_API_URL}`;

export default defineStore('auth', {
  state: () => ({
    user: JSON.parse(localStorage.getItem("user")),
    returnUrl: null
  }),
  getters: {
    isAuthenticated() {
      if(this.user) {
        return true;
      }
      try {
        const authTokenDecoded = VueJwtDecode.decode(this.user.auth_token);

        if (authTokenDecoded.exp < Date.now() / 1000) return false;

        return true;
      } catch (error) {
        return false;
      }
    }
  },
  actions: {
    async login(email, password) {
      // Send request to backend
      let loginResponse = await fetchWrapper.post(
        `${API_URL}/login`, 
        {
          email: email,
          password: password
        }
      );

      if(!loginResponse?.success) {
        return loginResponse ?? { success: false };
      }
        
      this.user = {
        auth_token: loginResponse.token
      };

      localStorage.setItem("user", JSON.stringify(this.user));

      router.push(this.returnUrl || "/");

      return loginResponse;
    },
    logout() {
      this.user = null;
      localStorage.removeItem("user");
      router.push("/login");
    }
  }
})
