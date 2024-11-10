<script setup>
import { ref } from 'vue';
import { zodResolver } from '@primevue/forms/resolvers/zod';
import { useToast } from "primevue/usetoast";
import { z } from 'zod';
import router from '@/router';

const isLoading = ref(false);

const toast = useToast();
const initialValues = ref({
  email: '',
  password: '',
});

const resolver = ref(zodResolver(
    z.object({
        password: z.string().min(1, { message: 'Parola este obligatorie.' }),
        email: z.string().min(1, { message: 'Email-ul este obligatoriu.' }).email({ message: 'Adresă de email invalidă.' })
    })
));

const onFormSubmit = ({ valid, values }) => {
    if (valid) {
        isLoading.value = true;
        toast.add({ severity: 'success', summary: 'Cererea de autentificare a fost trimisă.', life: 3000 });
        console.log(values)
        // TODO: Remove this fake loading
        let loginResponse = { 
          success: true, 
          user: {
            jwt: "asdasdadadsasd",
            email: values.email,
          }
        };
        setTimeout(() => {
          if(loginResponse.success) {
            toast.add({ severity: 'success', summary: 'Autentificarea a avut loc cu succes. Vă direcționăm către pagina principală în câteva clipe!', life: 3000 });
            router.push("/about")
          } else {
            toast.add({ severity: 'error', summary: 'Credențiale invalide.', life: 3000 });
          }
          isLoading.value = false;
        }, "3000");
    }
};
</script>

<template>
  <div class="min-h-[100vh] flex flex-col items-center justify-center p-4">
    <div class="card flex flex-col justify-center">
        <Form v-slot="$form" :resolver="resolver" :initialValues="initialValues" @submit="onFormSubmit" class="flex flex-col gap-4 w-full sm:w-56">
          <div class="flex flex-col gap-1">
              <InputText name="email" type="text" placeholder="Email" fluid :disabled="isLoading" />
              <Message v-if="$form.email?.invalid" severity="error" size="small" variant="simple">{{ $form.email.error?.message }}</Message>
          </div>
          <div class="flex flex-col gap-1">
              <InputText name="password" type="password" placeholder="Parola" fluid :disabled="isLoading"/>
              <Message v-if="$form.password?.invalid" severity="error" size="small" variant="simple">{{ $form.password.error?.message }}</Message>
          </div>
          <Button type="submit" severity="primary" label="Submit" :disabled="isLoading"/>
          <Toast />
        </Form>
        <div class="flex items-center justify-center mt-2">
          <i class="pi pi-spin pi-spinner" :class="isLoading ? '' : 'invisible'" style="font-size: 2rem"></i>
        </div>
    </div>
  </div>
</template>
