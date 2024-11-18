<template>
  <v-dialog
    v-model="dialog"
    max-width="800px"
    @click:outside="handleOutsideClick"
  >
    <v-card class="elevation-3 rounded-lg">
      <v-card-title class="headline text-center"> Newsletter </v-card-title>
      <v-card-text>
        <v-form ref="form" v-model="valid">
          <!-- Tag Selection Field -->
          <v-select
            v-model="selectedTag"
            color="primary"
            :items="tags"
            label="Select Release Tag"
            prepend-icon="mdi-tag"
            required
            variant="outlined"
          />

          <!-- Markdown Content Display -->
          <div class="markdown-content" v-html="markdownContent" />
        </v-form>
      </v-card-text>

      <v-card-actions class="d-flex justify-center">
        <v-btn v-if="role === 'admin'" class="glass-button" @click="openAddTag">
          <v-icon left>mdi-tag-plus</v-icon>
          Add tag
          <input
            ref="fileInput"
            accept=".md"
            style="display: none"
            type="file"
            @change="handleFileUpload"
          />
        </v-btn>
        <v-btn color="error" text @click="cancel"> Close </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script>
import { defineComponent, inject, onMounted, ref, watch } from "vue";
import { marked } from "marked";
import axios from "axios";

export default defineComponent({
  name: "NewsletterPopup",
  props: {
    show: {
      type: Boolean,
      required: true,
    },
    role: {
      type: String,
    },
  },
  emits: ["close"],
  setup(props, { emit }) {
    const userTools = inject("userTools");

    const dialog = ref(props.show);
    const valid = ref(false);
    const selectedTag = ref("");
    const tags = ref([]);
    const markdownContent = ref("");
    const fileInput = ref(null);
    const API_BASE_URL = 'http://localhost:4000/api';
    const selectedFile = ref(null);
    const errorMessage = ref("");
    const releases = ref({});

    const openAddTag = () => {
      if (fileInput.value) {
        fileInput.value.click(); // Ouvre la boîte de dialogue de fichiers
      }
    };

    const handleFileUpload = (e) => {
      const file = e.target.files[0];

      if (!file) {
        errorMessage.value = "No file selected.";
        return;
      }

      if (file && file.name.endsWith(".md")) {
        selectedFile.value = file;
        errorMessage.value = "";
        uploadFile();
      } else {
        errorMessage.value = "Please select a valid .md file.";
        selectedFile.value = null;
      }
    };

    const uploadFile = async () => {
      if (!selectedFile.value) {
        errorMessage.value = "No file selected";
        return;
      }

      if (!userTools) return;

      const formData = new FormData();
      formData.append("file", selectedFile.value);

      try {
        const response = await axios.post(`${API_BASE_URL}/newsletter`, formData, {
          headers: {
            Accept: "application/json",
            Authorization: `Bearer ${userTools.token}`,
          },
        });

        // gestion offline
        userTools.addOfflineRequest({
          url: `${API_BASE_URL}/newsletter`,
          method: "POST",
          headers: {
            Accept: "application/json",
            Authorization: `Bearer ${userTools.token}`,
          },
          data: formData,
          objInfo: {id: response.data.data.id}
        })

        loadReleases();
      } catch (error) {
        console.error("Error uploading file: " + error);
        errorMessage.value = "An error occurred while uploading the file.";
      }
    };

    const loadReleases = async () => {
      try {
        const response = await axios.get(`${API_BASE_URL}/newsletter`, {
          headers: {
            Accept: "application/json",
            "Content-Type": "application/json",
          },
        });
        releases.value = response.data.files;

        tags.value = Object.keys(releases.value).map((fileName) => {
          return fileName.replace(".md", "");
        });
      } catch (error) {
        console.error("Error fetching releases:", error);
        errorMessage.value = "Failed to load releases.";
      }
    };

    watch(
      () => props.show,
      (newVal) => {
        dialog.value = newVal;
      },
    );

    onMounted(async () => {
      loadReleases();
    });

    const fetchMarkdownContent = () => {
      if (!selectedTag.value) return;

      const fileKey = `${selectedTag.value}.md`;

      if (releases.value[fileKey]) {
        try {
          const content = releases.value[fileKey];

          if (content) {
            if (content.trim()) {
              markdownContent.value = marked(content); // Convert markdown to HTML
            } else {
              markdownContent.value =
                "<p>No content available for this tag.</p>";
            }
          } else {
            throw new Error("Invalid module format");
          }
        } catch (error) {
          markdownContent.value = "<p>Error loading markdown content.</p>";
        }
      } else {
        markdownContent.value = "<p>No content found for this tag.</p>";
      }
    };

    watch(selectedTag, fetchMarkdownContent);

    const cancel = () => {
      dialog.value = false;
      emit("close");

      selectedTag.value = null;
      markdownContent.value = null;
    };

    const handleOutsideClick = () => {
      dialog.value = false;
      emit("close");
    };

    return {
      dialog,
      valid,
      selectedTag,
      tags,
      markdownContent,
      fileInput,
      selectedFile,
      errorMessage,
      releases,
      fetchMarkdownContent,
      cancel,
      handleOutsideClick,
      openAddTag,
      handleFileUpload,
      uploadFile,
      loadReleases,
    };
  },
});
</script>

<style scoped>
.headline {
  font-size: 24px;
  font-weight: 500;
  color: #1976d2;
}
.v-card-title {
  padding: 20px;
}
.v-card {
  border-radius: 12px;
}
.v-btn {
  border-radius: 8px;
}
.v-text-field,
.v-select {
  margin-bottom: 16px;
}
.markdown-content {
  padding: 16px;
  background-color: transparent;
  border-radius: 8px;
  max-height: 400px;
  overflow-y: auto;
}
</style>
