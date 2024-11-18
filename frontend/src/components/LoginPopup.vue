<template>
  <v-dialog v-model="dialog" max-width="500px" transition="dialog-transition">
    <v-card class="glass-dialog">
      <v-card-title class="headline d-flex align-center">
        <v-icon class="mr-2">mdi-account-circle</v-icon>
        {{ isRegister ? "Create your Account" : "Sign in to your Account" }}
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

        <v-form ref="form" v-model="valid" @submit.prevent="submitForm">
          <!-- Username Field -->
          <v-text-field
            v-model="username"
            class="modern-input"
            :disabled="loading"
            label="Username"
            :loading="loading"
            prepend-icon="mdi-account"
            required
            :rules="[rules.required]"
          />

          <!-- Email Field (Register only) -->
          <v-text-field
            v-if="isRegister"
            v-model="email"
            class="modern-input"
            :disabled="loading"
            label="Email"
            :loading="loading"
            prepend-icon="mdi-email"
            required
            :rules="[rules.required, rules.email]"
            type="email"
          />

          <!-- Password Field -->
          <v-text-field
            v-model="password"
            class="modern-input"
            :disabled="loading"
            label="Password"
            :loading="loading"
            prepend-icon="mdi-lock"
            required
            :rules="[rules.required]"
            type="password"
          />

          <!-- Confirm Password Field (Register only) -->
          <v-text-field
            v-if="isRegister"
            v-model="confirmPassword"
            class="modern-input"
            :disabled="loading"
            label="Confirm Password"
            :loading="loading"
            prepend-icon="mdi-lock-check"
            required
            :rules="[rules.required, rules.matchPassword]"
            type="password"
          />
        </v-form>
      </v-card-text>

      <v-card-actions class="d-flex justify-center">
        <v-btn
          v-if="!isRegister"
          class="glass-button"
          color="primary"
          @click="signInWithGoogle"
        >
          <v-icon>mdi-google</v-icon>
        </v-btn>
        <v-btn class="glass-button" color="primary" @click="submitForm">
          {{ isRegister ? "Register" : "Login" }}
        </v-btn>
      </v-card-actions>

      <v-card-subtitle class="text-center py-3 d-flex flex-column align-center mb-5">
        <v-btn class="glass-button" color="primary" text @click="toggleForm">
          {{
            isRegister
              ? "Already have an account? Login"
              : "No account? Register"
          }}
        </v-btn>
      </v-card-subtitle>
    </v-card>
  </v-dialog>
</template>

<script>
import { computed, defineComponent, onMounted, ref, watch } from "vue";
import axios from "axios";
import Cookies from "js-cookie";

const API_BASE_URL = 'http://localhost:4000/api';

export default defineComponent({
  name: "LoginPopup",
  props: {
    show: {
      type: Boolean,
      required: true,
    },
  },
  emits: ["close"],
  setup(props, { emit }) {
    const dialog = ref(props.show);
    const username = ref("");
    const email = ref("");
    const password = ref("");
    const confirmPassword = ref("");
    const valid = ref(false);
    const isRegister = ref(false);
    const form = ref(null);

    const rules = {
      required: (value) => !!value || "This field is required.",
      email: (value) => /.+@.+\..+/.test(value) || "E-mail must be valid.",
      matchPassword: (value) =>
        value === password.value || "Passwords must match.",
    };

    watch(
      () => props.show,
      (newVal) => {
        dialog.value = newVal;
      },
    );

    const usernameErrors = computed(() =>
      !username.value ? ["Username is required."] : [],
    );
    const emailErrors = computed(() =>
      !email.value ? ["Email is required."] : [],
    );
    const passwordErrors = computed(() =>
      !password.value ? ["Password is required."] : [],
    );
    const confirmPasswordErrors = computed(() => {
      if (!isRegister.value) return [];
      if (!confirmPassword.value) return ["Confirm Password is required."];
      if (confirmPassword.value !== password.value)
        return ["Passwords must match."];
      return [];
    });

    const validatePasswords = () => {
      if (isRegister.value) {
        if (password.value !== confirmPassword.value) {
          return false;
        }
      }
      return true;
    };

    const login = async () => {
      const isValid = await form.value?.validate();
      if (isValid) {
        try {
          const response = await axios.post(
            `${API_BASE_URL}/users/sign_in`,
            {
              username: username.value,
              password: password.value,
            },
            {
              headers: {
                Accept: "application/json",
                "Content-Type": "application/json",
              },
              withCredentials: true,
            },
          );
          const token = response.data.token;
          Cookies.set("token", token);
          dialog.value = false;
          emit("close");
          window.location.reload();
        } catch (error) {
          console.error("Error logging in:", error);
        }
      }
    };

    const signInWithGoogle = async () => {
      if (!window.google || !google.accounts) {
        return;
      }

      try {
        const client = google.accounts.oauth2.initTokenClient({
          client_id:
            "260342255640-8inh6ra1q5uj8os233i41atr2jjqnflf.apps.googleusercontent.com",
          scope:
            "https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email",
          callback: async (response) => {
            if (!response.error) {
              const accessToken = response.access_token;
              const userInfo = await fetchUserInfo(accessToken);
              await handleGoogleLogin(
                accessToken,
                userInfo.name,
                userInfo.email,
              );
            }
          },
        });

        client.requestAccessToken();
      } catch (error) {
        console.error("Error creating user:", error);
      }
    };

    async function fetchUserInfo(accessToken) {
      const response = await fetch(
        "https://www.googleapis.com/oauth2/v3/userinfo",
        {
          method: "GET",
          headers: {
            Authorization: `Bearer ${accessToken}`,
          },
        },
      );

      if (!response.ok) {
        throw new Error("Failed to fetch user info");
      }

      return response.json();
    }

    const handleGoogleLogin = async (token, username, email) => {
      try {
        const response = await fetch(`${API_BASE_URL}/auth/google`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ code: token, username, email }),
        });

        const result = await response.json();
        if (result.token) {
          Cookies.set("token", result.token);
          dialog.value = false;
          emit("close");
          window.location.reload();
        }
        return result;
      } catch (error) {
        console.error("Error during token validation with backend:", error);
      }
    };

    const createUser = async () => {
      if (!validatePasswords()) {
        console.error("Passwords do not match");
        return false;
      }

      try {
        const response = await axios.post(
          `${API_BASE_URL}/users`,
          {
            user: {
              username: username.value,
              email: email.value,
              password: password.value,
              role: "employee",
            },
          },
          {
            headers: {
              Accept: "application/json",
              "Content-Type": "application/json",
            },
            withCredentials: true,
          },
        );

        // gestion offline
        userTools.addOfflineRequest({
          url: `${API_BASE_URL}/users`,
          method: "POST",
          headers: {
            Accept: "application/json",
            "Content-Type": "application/json",
          },
          data: {
            user: {
              username: username.value,
              email: email.value,
              password: password.value,
              role: "employee",
            },
          },
          objInfo: {id: response.data.data.id}
        })

        return true;
      } catch (error) {
        console.error("Error creating user:", error);
        return false;
      }
    };

    const register = async () => {
      const isValid = await form.value?.validate();
      if (isValid && validatePasswords()) {
        const userCreated = await createUser();
        if (userCreated) {
          dialog.value = false;
          emit("close");
        }
      }
    };

    const submitForm = async () => {
      if (isRegister.value) {
        await register();
      } else {
        await login();
      }
    };

    const cancel = () => {
      dialog.value = false;
      emit("close");
    };

    const toggleForm = () => {
      isRegister.value = !isRegister.value;
      // Reset fields when toggling
      username.value = "";
      email.value = "";
      password.value = "";
      confirmPassword.value = "";
      if (form.value) {
        form.value.resetValidation();
      }
    };

    const handleOutsideClick = () => {
      dialog.value = false;
      emit("close");
    };

    onMounted(() => {
      const script = document.createElement("script");
      script.src = "https://accounts.google.com/gsi/client";
      script.async = true;
      script.defer = true;
      script.onerror = () => {
        console.error("Failed to load Google Identity Services script");
      };
      document.head.appendChild(script);
    });

    return {
      dialog,
      username,
      email,
      password,
      confirmPassword,
      valid,
      isRegister,
      rules,
      usernameErrors,
      emailErrors,
      passwordErrors,
      confirmPasswordErrors,
      login,
      signInWithGoogle,
      handleGoogleLogin,
      register,
      cancel,
      toggleForm,
      handleOutsideClick,
      submitForm,
      form,
    };
  },
});
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

.headline {
  color: rgba(255, 255, 255, 0.9);
  font-size: 1.5rem;
  font-weight: 500;
}
</style>
