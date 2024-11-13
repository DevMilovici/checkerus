<template>
  <div class="min-h-[100vh] flex flex-col items-center justify-center p-4">
    <div class="card flex flex-col justify-center">
        <Form v-slot="$form" :resolver="form.resolver" :initialValues="form.initialValues" @submit="onFormSubmit" class="flex flex-col gap-4 w-full sm:w-56">
          <div class="flex flex-col gap-1">
              <InputText name="email" type="text" placeholder="Email" fluid :disabled="isLoading" />
              <Message v-if="$form.email?.invalid" severity="error" size="small" variant="simple">{{ $form.email.error?.message }}</Message>
          </div>
          <div class="flex flex-col gap-1">
              <InputText name="password" type="password" placeholder="Parola" fluid :disabled="isLoading"/>
              <Message v-if="$form.password?.invalid" severity="error" size="small" variant="simple">{{ $form.password.error?.message }}</Message>
          </div>
          <Button type="submit" severity="primary" label="Login" :disabled="isLoading"/>
          <Toast />
        </Form>
        <div class="flex items-center justify-center mt-2">
          <i class="pi pi-spin pi-spinner" :class="isLoading ? '' : 'invisible'" style="font-size: 2rem"></i>
        </div>
    </div>
  </div>
</template>

<script>
import { zodResolver } from '@primevue/forms/resolvers/zod';
import { z } from 'zod';

import useAuthStore from "@/stores/auth";

export default {
  data() {
    return {
      form: {
        initialValues: {
          email: '',
          password: ''
        },
        resolver: zodResolver(
          z.object({
              password: z.string().min(1, { message: 'Parola este obligatorie.' }),
              email: z.string().min(1, { message: 'Email-ul este obligatoriu.' }).email({ message: 'Adresă de email invalidă.' })
          })
        )
      },
      isLoading: false
    }
  },
  methods: {
    async onFormSubmit({ valid, values }){
      if (valid) {
          console.log(values)
          
          this.isLoading = true;
          this.$toast.add({ severity: 'success', summary: 'Cererea de autentificare a fost trimisă.', life: 3000 });

          let authStore = useAuthStore();
          
          // setTimeout(async () => {
          let loginResponse = await authStore.login(values.email, values.password);

          if(loginResponse.success) {
            this.$toast.add({ severity: 'success', summary: 'Autentificarea a avut loc cu succes. Vă direcționăm către pagina principală în câteva clipe!', life: 3000 });
          } else {
            // TODO: Treat status codes (404, 500, no connection...)
            this.$toast.add({ severity: 'error', summary: 'Credențiale invalide.', life: 3000 });
          }
          this.isLoading = false;
          // }, "2000");
      }
    }
  }
}
</script>