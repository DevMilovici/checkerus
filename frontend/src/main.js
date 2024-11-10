import './assets/main.css'
import './assets/style.scss'

import { createApp } from 'vue'
import { createPinia } from 'pinia'

import PrimeVue from 'primevue/config';
import Aura from '@primevue/themes/aura';
import Button from "primevue/button"
import InputText from 'primevue/inputtext';
import { Form } from '@primevue/forms';
import Toast from 'primevue/toast';
import ToastService from 'primevue/toastservice';
import Message from 'primevue/message';

import App from './App.vue'
import router from './router'

const app = createApp(App);
app.component('Button', Button);
app.component('InputText', InputText);
app.component('Form', Form);
app.component('Toast', Toast);
app.component('Message', Message);

app.use(createPinia());
app.use(router);
app.use(ToastService);

app.use(PrimeVue, {
    theme: {
        preset: Aura
    }
});

app.mount('#app');
