<template>
  <main class="min-h-[100vh] flex flex-col items-center justify-center p-4">
    <h1 class="text-2xl">
      Tema 1
    </h1>
    <!-- Tabs -->
    <div class="min-w-[600px] max-w-[600px] min-h-[400px] h-[400px] m-x-auto">
      <Tabs value="history" class="w-full h-full" @update:value="onChangeTab">
        <TabList>
          <Tab value="history" :disabled="history.isLoading || isUploading">Istoric</Tab>
          <Tab value="upload" :disabled="history.isLoading || isUploading">Încărcare</Tab>
        </TabList>
        <TabPanels class="h-full border border-gray-600">
          <TabPanel value="history" class="h-full">
            <div class="h-full">
              <ScrollPanel class="w-full h-full">
                <div v-if="history.isLoading" class="h-full w-full flex items-center justify-center text-center">
                  <i class="pi pi-spin pi-spinner text-green-400" style="font-size: 2rem"></i>
                </div>
                <div v-else class="h-full">
                  <div v-if="history.uploads?.length > 0">
                    <DataTable 
                      :value="history.uploads" 
                      selectionMode="single" @rowSelect="onHistoryItemSelect" 
                      class="pb-8"
                    >
                      <Column field="index" header="Nr."></Column>
                      <Column field="date" header="Dată"></Column>
                      <Column field="points" header="Punctaj"></Column>
                  </DataTable>
                  </div>
                  <div v-else class="h-full w-full flex items-center justify-center text-center">
                    Nu există încărcări.
                  </div>
                </div>
              </ScrollPanel>
            </div>
          </TabPanel>
          <TabPanel value="upload" class="h-full">
            <div class="h-full flex flex-col items-center justify-center gap-8 items-center">
              <div>
                <FileUpload ref="fileupload" mode="basic" name="file" :maxFileSize="1000000" customUpload
                  :disabled="isUploading || waitTimeInSeconds > 0" @select="onFileSelected" />
              </div>
              <div>
                <Button label="Încarcă" @click="upload" :disabled="!canUpload || waitTimeInSeconds > 0" severity="secondary" class="shrink" />
              </div>
              <div>
                <p>
                  Puteți încărca un nou fișier în <span :class="waitTimeInSeconds == 0 ? 'text-green-400' : 'text-red-400'">{{ waitTimeInSeconds }}</span> secunde...
                </p>
              </div>
            </div>
          </TabPanel>
        </TabPanels>
      </Tabs>
      <Toast />
    </div>
    <!-- History item info dialog -->
    <Dialog v-model:visible="history.infoDialogVisible" modal header="" class="min-w-[600px] w-full m-10">
      <template #header>
        &nbsp;
      </template>
      <div class="h-full w-full flex items-center justify-center gap-4 mb-4">
          <pre>{{ history.selectedItemInfo }}</pre>
      </div>
      <template #footer>
        <div class="w-full flex justify-center mt-4">
          <Button type="button" label="Închide" severity="danger" @click="history.infoDialogVisible = false"></Button>
        </div>
      </template>
    </Dialog>
  </main>
</template>

<script>
import fetchWrapper from '@/helpers/fetch-wrapper';
import moment from "moment";

const API_URL = `${import.meta.env.VITE_API_URL}`;

export default {
  data() {
    return {
      // History
      history: {
        uploads: [],
        isLoading: false,
        selectedItemInfo: "",
        infoDialogVisible: false,
      },
      // Upload
      fileToUpload: null,
      canUpload: false,
      isUploading: false,
      waitTimeInSeconds: 0,
      decremetingInterval: null
    }
  },
  async mounted() {
    await this.loadHistory();
  },
  methods: {
    async onChangeTab(value) {
      switch (value) {
        case 'history':
          await this.loadHistory();
          break;
        case 'upload':
          await this.retrieveLoadTime();
          break;
      }
    },
    // History
    async loadHistory() {
      this.history.isLoading = true;

      this.history.uploads.length = 0;
      let historyResponse = await fetchWrapper.get(`${API_URL}/history`);

      if (historyResponse.success && historyResponse.uploads) {
        let formattedUploads = historyResponse.uploads.map((uploadItem, index) => {
          return {
            index: index + 1,
            date: moment(uploadItem.Timestamp).format("YYYY/MM/DD HH:mm:ss"),
            points: uploadItem.Points,
            info: uploadItem.Result
          }
        });
        formattedUploads.reverse();
        this.history.uploads.push(...formattedUploads)
      } else {
        this.$toast.add({ severity: 'error', summary: 'Ceva nu a funcționat corect la încărcarea istoricului!', life: 3000 });
      }

      await this.retrieveLoadTime();

      this.history.isLoading = false;
    },
    onHistoryItemSelect(selectedItem) {
      this.history.selectedItemInfo = selectedItem.data.info;
      this.history.infoDialogVisible = true;
    },
    // Upload
    async upload() {
      this.isUploading = true;
      this.canUpload = false;

      this.$toast.add({ severity: 'warn', summary: 'Fișierul a fost trimis către server!', life: 3000 });
      var fileFormData = new FormData();
      fileFormData.append("file", this.fileToUpload);
      let uploadResponse = await fetchWrapper.upload(`${API_URL}/upload`, fileFormData);
      if (uploadResponse?.success) {
        this.$toast.add({ severity: 'success', summary: 'Fișierul a fost încărcat cu succes!', life: 3000 });
      } else {
        this.$toast.add({ severity: 'error', summary: 'Ceva nu a funcționat corect la încărcarea fișierului!', life: 3000 });
      }

      this.canUpload = true;
      this.isUploading = false;

      await this.retrieveLoadTime();
    },
    async onFileSelected(event) {
      if (!event.files || event.files.length <= 0) {
        this.$toast.add({ severity: 'error', summary: 'Ceva nu a funcționat corect! Pare a fi o problemă cu fișierul.', life: 3000 });
        this.fileToUpload = null;
        return;
      }

      this.fileToUpload = event.files[0];
      if (!this.fileToUpload) {
        this.$toast.add({ severity: 'error', summary: 'Ceva nu a funcționat corect! Pare a fi o problemă cu fișierul.', life: 3000 });
        this.fileToUpload = null;
        return;
      }

      const fileType = this.fileToUpload["type"];
      const validFileTypes = ["text/plain", 'application/octet-stream', '', ' '];
      if (!validFileTypes.includes(fileType)) {
        this.$toast.add({ severity: 'error', summary: `Tipul de fișier ('${fileType}') este greșit!`, life: 3000 });
        event.files.length = 0;
        this.fileToUpload = null;
        return;
      }

      this.canUpload = true;
    },
    async retrieveLoadTime() {
      let canLoadResponse = await fetchWrapper.get(`${API_URL}/canLoad`);
      if(canLoadResponse.success) {
        this.refreshLoadTime(canLoadResponse.wait)
      } else {
        this.$toast.add({ severity: 'error', summary: 'Ceva nu a funcționat corect la încărcarea informațiilor despre coada de încărcare!', life: 3000 });
      }
    },
    refreshLoadTime(newWaitTime) {
      // Clear any existing interval
      if (this.decremetingInterval) {
        clearInterval(this.decremetingInterval);
        this.decremetingInterval = null;
      }

      // Update waitTimeInSeconds with the new value
      this.waitTimeInSeconds = newWaitTime;

      // Start the decrementing counter
      this.startDecrementingCounter();
    },
    startDecrementingCounter() {
      // Prevent multiple intervals from running
      if (this.decremetingInterval) return;

      this.decremetingInterval = setInterval(() => {
        if (this.waitTimeInSeconds > 0) {
          this.waitTimeInSeconds -= 1;
        } else {
          // Stop the interval when the counter reaches 0
          clearInterval(this.decremetingInterval);
          this.decremetingInterval = null;
        }
      }, 1000); // Run every 1 second
    },
  }
}
</script>