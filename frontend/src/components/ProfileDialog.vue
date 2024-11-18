<template>
  <v-dialog v-model="show" max-width="500px" transition="dialog-transition">
    <v-card class="glass-dialog">
      <v-card-title class="headline d-flex align-center">
        <v-icon class="mr-2">mdi-account-edit</v-icon>
        My Profile
      </v-card-title>

      <v-card-text>
        <v-alert
          v-if="error"
          class="glass-alert mb-4"
          dismissible
          type="error"
          @click="error = null"
        >
          {{ error }}
        </v-alert>

        <v-alert
          v-if="success"
          class="glass-alert mb-4"
          dismissible
          type="success"
          @click="success = null"
        >
          {{ success }}
        </v-alert>

        <v-form ref="form" v-model="valid" @submit.prevent="updateProfile">
          <!-- Username -->
          <v-text-field
            v-model="profileData.username"
            class="modern-input"
            :disabled="loading"
            label="Username"
            :loading="loading"
            prepend-icon="mdi-account"
            required
            :rules="usernameRules"
            :readonly="isGoogleUser == 'true'"
          />

          <!-- Email -->
          <v-text-field
            v-model="profileData.email"
            class="modern-input"
            :disabled="loading"
            label="Email"
            :loading="loading"
            prepend-icon="mdi-email"
            required
            :rules="emailRules"
            :readonly="isGoogleUser == 'true'"
          />

          <!-- Role (readonly) -->
          <v-text-field
            v-model="profileData.role"
            class="modern-input"
            :disabled="true"
            label="Role"
            prepend-icon="mdi-shield-account"
            readonly
          />
          
          <!-- Team (readonly) -->
          <v-text-field
            v-model="profileData.team_id"
            class="modern-input"
            :disabled="true"
            label="Team"
            prepend-icon="mdi-account-multiple"
            readonly
          />

          <v-divider class="my-4" />

          <!-- Password change section -->
          <v-checkbox
            v-model="changePassword"
            class="modern-checkbox mb-2"
            color="primary"
            :disabled="loading"
            label="Change password"
            v-if="isGoogleUser == 'false'"
          />

          <v-expand-transition>
            <div v-if="changePassword">
              <!-- Current password -->
              <v-text-field
                v-model="profileData.currentPassword"
                class="modern-input"
                :disabled="loading"
                label="Current password"
                :loading="loading"
                prepend-icon="mdi-lock-outline"
                required
                :rules="currentPasswordRules"
                type="password"
              />

              <!-- New password -->
              <v-text-field
                v-model="profileData.newPassword"
                class="modern-input"
                :disabled="loading"
                label="New password"
                :loading="loading"
                prepend-icon="mdi-lock"
                required
                :rules="passwordRules"
                type="password"
              />

              <!-- Confirm new password -->
              <v-text-field
                v-model="passwordConfirm"
                class="modern-input"
                :disabled="loading"
                label="Confirm new password"
                :loading="loading"
                prepend-icon="mdi-lock-check"
                required
                :rules="[...passwordRules, passwordMatchRule]"
                type="password"
              />
            </div>
          </v-expand-transition>

          <div class="d-flex justify-space-between align-center mt-4">
            <span class="text-caption text-medium-emphasis">
              Last modified: {{ lastUpdated }}
            </span>
            <div>
              <v-btn
                class="mr-2"
                color="error"
                :disabled="loading"
                text
                @click="handleClose"
              >
                Cancel
              </v-btn>
              <v-btn
                class="glass-button"
                color="primary"
                :disabled="!valid || loading"
                :loading="loading"
                @click="updateProfile"
                v-if="isGoogleUser == 'false'"
              >
                <v-icon left>mdi-content-save</v-icon>
                Save
              </v-btn>
            </div>
          </div>
        </v-form>

        <!-- Account deletion section -->
        <v-divider class="my-6" v-if="isGoogleUser == 'false'" />
        <div class="d-flex justify-center">
          <v-btn
            class="glass-button-danger"
            color="error"
            :disabled="loading"
            @click="showDeleteDialog = true"
            v-if="isGoogleUser == 'false'"
          >
            <v-icon left>mdi-account-remove</v-icon>
            Delete my account
          </v-btn>
        </div>
      </v-card-text>
    </v-card>
  </v-dialog>

  <!-- Delete confirmation dialog -->
  <v-dialog v-model="showDeleteDialog" max-width="400px">
    <v-card class="glass-dialog">
      <v-card-title class="headline error--text">
        <v-icon color="error" left>mdi-alert</v-icon>
        Delete Confirmation
      </v-card-title>

      <v-card-text class="mt-4">
        <p class="mb-4">This action is irreversible. To confirm the deletion of your account, please follow these steps:</p>

        <v-alert
          v-if="deleteError"
          class="glass-alert mb-4"
          dismissible
          type="error"
          @click="deleteError = null"
        >
          {{ deleteError }}
        </v-alert>

        <v-form ref="deleteForm" v-model="deleteFormValid" @submit.prevent="confirmDelete">
          <v-text-field
            v-model="deleteConfirmation.password"
            class="modern-input"
            :disabled="loading"
            label="Your current password"
            :loading="loading"
            prepend-icon="mdi-lock"
            required
            :rules="[v => !!v || 'Password is required']"
            type="password"
          />

          <v-text-field
            v-model="deleteConfirmation.confirmText"
            class="modern-input"
            :disabled="loading"
            label="Type 'DELETE' to confirm"
            :loading="loading"
            prepend-icon="mdi-text-box"
            required
            :rules="[v => v === 'DELETE' || 'Please type DELETE to confirm']"
          />
        </v-form>
      </v-card-text>

      <v-card-actions>
        <v-spacer />
        <v-btn
          :disabled="loading"
          text
          @click="cancelDelete"
        >
          Cancel
        </v-btn>
        <v-btn
          class="glass-button-danger"
          color="error"
          :disabled="!deleteFormValid"
          :loading="loading"
          @click="confirmDelete"
        >
          Delete permanently
        </v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script>
  import { defineComponent, inject, onMounted, ref, watch } from 'vue'
  import axios from 'axios'
  import Cookies from 'js-cookie'
  import { jwtDecode } from 'jwt-decode'

  const API_BASE_URL = 'http://localhost:4000/api';

  export default defineComponent({
    name: 'ProfileDialog',

    props: {
      modelValue: {
        type: Boolean,
        default: false,
      },
      isGoogleUser: {
        type: String,
        required: true
      },
    },

    emits: ['update:modelValue'],

    setup (props, { emit }) {

      const userTools = inject("userTools");
      
      // Refs pour le profil
      const show = ref(props.modelValue)
      const valid = ref(true)
      const form = ref(null)
      const loading = ref(false)
      const error = ref(null)
      const success = ref(null)
      const changePassword = ref(false)
      const passwordConfirm = ref('')
      const lastUpdated = ref('Never')

      // Refs pour la suppression
      const showDeleteDialog = ref(false)
      const deleteFormValid = ref(false)
      const deleteForm = ref(null)
      const deleteError = ref(null)
      const deleteConfirmation = ref({
        password: '',
        confirmText: '',
      })

      const profileData = ref({
        username: '',
        email: '',
        role: '',
        team_id: '',
        currentPassword: '',
        newPassword: '',
      })

      // Règles de validation
      const usernameRules = [
        v => !!v || 'Username is required',
        v => v.length >= 3 || 'Username must be at least 3 characters long',
        v => /^[a-zA-Z0-9_-]+$/.test(v) || 'Username can only contain letters, numbers, dashes and underscores',
      ]

      const emailRules = [
        v => !!v || 'Email is required',
        v => /.+@.+\..+/.test(v) || 'Email must be valid',
      ]

      const currentPasswordRules = [
        v => !changePassword.value || !!v || 'Current password is required',
      ]

      const passwordRules = [
        v => !changePassword.value || !!v || 'Password is required',
        v => !changePassword.value || v.length >= 6 || 'Password must be at least 6 characters long',
        v => !changePassword.value || /\d/.test(v) || 'Password must contain at least one number',
      ]

      const passwordMatchRule = v =>
        !changePassword.value ||
        v === profileData.value.newPassword ||
        'Passwords do not match'

      // Fonctions utilitaires
      const checkAuthentication = () => {
        const token = Cookies.get('token')
        if (!token) {
          throw new Error('Not authenticated')
        }
        return { token, decodedToken: jwtDecode(token) }
      }

      const validateUserId = requestedId => {
        const { decodedToken } = checkAuthentication()
        if (decodedToken.user_id !== requestedId) {
          throw new Error('Unauthorized action')
        }
      }

      const handleError = error => {
        console.error('Error:', error)
        const errorMessage = error.response?.data?.error || error.message || 'An error occurred'
        return errorMessage
      }

      const formatDate = date => {
        return new Intl.DateTimeFormat('en-US', {
          dateStyle: 'long',
          timeStyle: 'short',
        }).format(new Date(date))
      }

      // Fonctions de gestion du profil
      const loadUserProfile = async () => {
        loading.value = true
        error.value = null

        try {
          const { token, decodedToken } = checkAuthentication()
          const userId = decodedToken.user_id

          const response = await axios.get(`${API_BASE_URL}/users/${userId}`, {
            headers: {
              Authorization: `Bearer ${token}`,
              Accept: 'application/json',
            },
            withCredentials: true,
          })

          const userData = response.data.data
          profileData.value = {
            username: userData.username,
            email: userData.email,
            role: userData.role || 'employee',
            team_id: userData.team_id || 'No team',
            currentPassword: '',
            newPassword: '',
          }

          if (userData.updated_at) {
            lastUpdated.value = formatDate(userData.updated_at)
          }
        } catch (err) {
          error.value = handleError(err)
        } finally {
          loading.value = false
        }
      }

      const updateProfile = async () => {
        if (!form.value?.validate()) return

        loading.value = true
        error.value = null
        success.value = null

        try {
          const { token, decodedToken } = checkAuthentication()
          const userId = decodedToken.user_id

          const updateData = {
            username: profileData.value.username,
            email: profileData.value.email,
          }

          if (changePassword.value) {
            if (!profileData.value.currentPassword) {
              throw new Error('Current password is required')
            }
            updateData.current_password = profileData.value.currentPassword
            updateData.password = profileData.value.newPassword
          }

          const response = await axios.put(
            `${API_BASE_URL}/users/${userId}`,
            { user: updateData },
            {
              headers: {
                Authorization: `Bearer ${token}`,
                Accept: 'application/json',
                'Content-Type': 'application/json',
              },
              withCredentials: true,
            }
          )

          // gestion offline
          userTools.addOfflineRequest({
            url: `${API_BASE_URL}/users/${userId}`,
            method: "PUT",
            headers: {
              Authorization: `Bearer ${token}`,
              Accept: 'application/json',
              'Content-Type': 'application/json',
            },
            data: { user: updateData },
          })

          if (response.data.error) {
            throw new Error(response.data.error)
          }

          success.value = 'Profile updated successfully'
          lastUpdated.value = formatDate(new Date())

          if (changePassword.value) {
            setTimeout(() => {
              handleClose()
              Cookies.remove('token')
              window.location.reload()
            }, 1500)
          } else {
            changePassword.value = false
            profileData.value.currentPassword = ''
            profileData.value.newPassword = ''
            passwordConfirm.value = ''
          }
        } catch (err) {
          error.value = handleError(err)
        } finally {
          loading.value = false
        }
      }

      // Fonctions de gestion de la suppression
      const resetDeleteForm = () => {
        deleteConfirmation.value = {
          password: '',
          confirmText: '',
        }
        deleteError.value = null
        if (deleteForm.value) {
          deleteForm.value.reset()
        }
      }

      const cancelDelete = () => {
        showDeleteDialog.value = false
        resetDeleteForm()
      }

      const confirmDelete = async () => {
        if (!deleteForm.value?.validate()) return

        loading.value = true
        deleteError.value = null

        try {
          const { token, decodedToken } = checkAuthentication()
          const userId = decodedToken.user_id

          validateUserId(userId)

          if (deleteConfirmation.value.confirmText !== 'DELETE') {
            throw new Error('Please type DELETE to confirm')
          }

          const response = await axios.delete(`${API_BASE_URL}/users/${userId}`, {
            headers: {
              Authorization: `Bearer ${token}`,
              Accept: 'application/json',
              'Content-Type': 'application/json',
            },
            data: {
              current_password: deleteConfirmation.value.password,
            },
            withCredentials: true,
          })

          // gestion offline
          userTools.addOfflineRequest({
            url: `${API_BASE_URL}/users/${userId}`,
            method: "DELETE",
            headers: {
              Authorization: `Bearer ${token}`,
              Accept: 'application/json',
              'Content-Type': 'application/json',
            },
            data: {
              current_password: deleteConfirmation.value.password,
            },
          })

          if (response.data.error) {
            throw new Error(response.data.error)
          }

          showDeleteDialog.value = false
          show.value = false
          Cookies.remove('token')
          window.location.href = '/'
        } catch (err) {
          deleteError.value = handleError(err)
        } finally {
          loading.value = false
        }
      }

      const handleClose = () => {
        show.value = false
        resetForm()
      }

      const resetForm = () => {
        profileData.value = {
          username: '',
          email: '',
          role: '',
          team_id: '',
          currentPassword: '',
          newPassword: '',
        }
        changePassword.value = false
        passwordConfirm.value = ''
        error.value = null
        success.value = null
        if (form.value) {
          form.value.reset()
        }
      }

      // Watchers
      watch(() => props.modelValue, newVal => {
        show.value = newVal
        if (newVal) {
          loadUserProfile()
        }
      })

      watch(show, newVal => {
        emit('update:modelValue', newVal)
        if (!newVal) {
          resetForm()
        }
      })

      // Lifecycle hooks
      onMounted(() => {
        if (show.value) {
          loadUserProfile()
        }
      })

      return {
        // Refs du profil
        show,
        valid,
        form,
        loading,
        error,
        success,
        profileData,
        changePassword,
        passwordConfirm,
        lastUpdated,

        // Refs de suppression
        showDeleteDialog,
        deleteFormValid,
        deleteForm,
        deleteError,
        deleteConfirmation,

        // Règles de validation
        usernameRules,
        emailRules,
        currentPasswordRules,
        passwordRules,
        passwordMatchRule,

        // Méthodes du profil
        updateProfile,
        handleClose,

        // Méthodes de suppression
        cancelDelete,
        confirmDelete,
      }
    },
  })
</script>

<style scoped>
.dialog-transition-enter-active,
.dialog-transition-leave-active {
  transition: opacity 0.3s ease;
}

.dialog-transition-enter-from,
.dialog-transition-leave-to {
  opacity: 0;
}

.glass-dialog {
  background: rgba(0, 0, 0, 0.7);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  color: white;
}

.glass-alert {
  background: rgba(0, 0, 0, 0.3) !important;
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.modern-input {
  margin-bottom: 16px;
}

.modern-input :deep(.v-input__control) {
  background-color: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 8px;
  transition: all 0.3s ease;
}

.modern-input :deep(.v-input__control:hover) {
  border-color: rgba(255, 255, 255, 0.2);
}

.modern-input :deep(.v-input__control:focus-within) {
  border-color: rgba(30, 136, 229, 0.8);
  box-shadow: 0 0 10px rgba(30, 136, 229, 0.4);
}

.modern-checkbox :deep(.v-input__control) {
  background: transparent !important;
  border: none !important;
}

.glass-button {
  background: rgba(30, 136, 229, 0.2) !important;
  backdrop-filter: blur(10px);
  border: 1px solid rgba(30, 136, 229, 0.3);
  color: white !important;
  transition: all 0.3s ease !important;
}

.glass-button:hover {
  background: rgba(30, 136, 229, 0.3) !important;
  border-color: rgba(30, 136, 229, 0.5);
  transform: translateY(-2px);
}

.glass-button-danger {
  background: rgba(244, 67, 54, 0.2) !important;
  backdrop-filter: blur(10px);
  border: 1px solid rgba(244, 67, 54, 0.3);
  color: white !important;
  transition: all 0.3s ease !important;
}

.glass-button-danger:hover {
  background: rgba(244, 67, 54, 0.3) !important;
  border-color: rgba(244, 67, 54, 0.5);
  transform: translateY(-2px);
}

.headline {
  color: rgba(255, 255, 255, 0.9);
  font-size: 1.5rem;
  font-weight: 500;
}

.text-medium-emphasis {
  color: rgba(255, 255, 255, 0.7);
}

.v-expand-transition-enter-active,
.v-expand-transition-leave-active {
  transition: all 0.3s ease-in-out;
}

.v-expand-transition-enter-from,
.v-expand-transition-leave-to {
  opacity: 0;
  transform: translateY(-20px);
}
</style>