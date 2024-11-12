import router from '@/router';
import { defineStore } from 'pinia'

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
      // TODO: Send request to backend
      const loginResponse = {
        success: true,
        jwt: "asdasdasdas",
        email: "emil.bureaca@mta.ro"
      }
      // TODO: Remove this after sending request to backend
      if(password != "12345")
        loginResponse.success = false;

      if(!loginResponse?.success) {
        return loginResponse ?? { success: false };
      }
        
      this.user = {
        jwt: loginResponse.jwt,
        email: loginResponse.email
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
