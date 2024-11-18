<template>
  <v-app>
    <v-card class="user-management-card glass-card" elevation="2">
      <v-card-title class="headline">User Management</v-card-title>
      <v-card-text>
        <v-row>
          <v-col cols="12" md="4" sm="6">
            <v-text-field
              v-model="search"
              class="dark-input"
              clearable
              label="Search users"
              prepend-icon="mdi-magnify"
            />
          </v-col>
          <v-col class="d-flex justify-end" cols="12" md="4" sm="6">
            <v-btn class="glass-button" @click="openCreateUserDialog">
              <v-icon left>mdi-account-plus</v-icon>
              Create User
            </v-btn>
          </v-col>
        </v-row>
        <v-data-table
          class="glass-table"
          :headers="headers"
          :items="users"
          :loading="loading"
          :search="search"
        >
          <template #[`item.actions`]="{ item }">
            <v-icon
              class="mr-2 edit-icon"
              small
              @click="openUpdateUserDialog(item)"
            >
              mdi-pencil
            </v-icon>
            <v-icon class="delete-icon" small @click="confirmDeleteUser(item)">
              mdi-delete
            </v-icon>
          </template>
        </v-data-table>
      </v-card-text>
      <v-dialog v-model="createDialog" max-width="500px">
        <v-card class="glass-dialog">
          <v-card-title>Create New User</v-card-title>
          <v-card-text>
            <v-form ref="createForm" v-model="valid">
              <v-text-field
                v-model="editedItem.username"
                class="dark-input"
                :error-messages="usernameErrors"
                label="Username"
                required
                :rules="usernameRules"
              />
              <v-text-field
                v-model="editedItem.email"
                class="dark-input"
                :error-messages="emailErrors"
                label="Email"
                required
                :rules="emailRules"
              />
              <v-text-field
                v-model="editedItem.password"
                class="dark-input"
                :error-messages="passwordErrors"
                label="Password"
                required
                :rules="passwordRules"
                type="password"
              />
              <v-select
                v-model="editedItem.role"
                class="dark-input"
                :error-messages="roleErrors"
                :items="roles"
                label="Role"
                required
                :rules="roleRules"
              />
            </v-form>
          </v-card-text>
          <v-card-actions>
            <v-spacer />
            <v-btn color="transparent" text @click="closeCreateDialog">
              Cancel
            </v-btn>
            <v-btn class="glass-button" @click="createUser"> Save </v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>
      <v-dialog v-model="updateDialog" max-width="500px">
        <v-card class="glass-dialog">
          <v-card-title>Edit User</v-card-title>
          <v-card-text>
            <v-form ref="updateForm" v-model="valid">
              <v-text-field
                v-model="editedItem.username"
                class="dark-input"
                :error-messages="usernameErrors"
                label="Username"
                required
                :rules="usernameRules"
              />
              <v-text-field
                v-model="editedItem.email"
                class="dark-input"
                :error-messages="emailErrors"
                label="Email"
                required
                :rules="emailRules"
              />
              <v-select
                v-model="editedItem.role"
                class="dark-input"
                :error-messages="roleErrors"
                :items="roles"
                label="Role"
                required
                :rules="roleRules"
              />
            </v-form>
          </v-card-text>
          <v-card-actions>
            <v-spacer />
            <v-btn color="transparent" text @click="closeUpdateDialog">
              Cancel
            </v-btn>
            <v-btn class="glass-button" @click="updateUser"> Update </v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>
      <v-dialog v-model="deleteDialog" max-width="400px">
        <v-card class="glass-dialog">
          <v-card-title class="headline">Delete User</v-card-title>
          <v-card-text>
            Are you sure you want to delete this user?
          </v-card-text>
          <v-card-actions>
            <v-spacer />
            <v-btn color="transparent" text @click="closeDeleteDialog">
              Cancel
            </v-btn>
            <v-btn
              class="glass-button"
              color="red darken-1"
              text
              @click="deleteUser"
            >
              Delete
            </v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>
    </v-card>
  </v-app>
</template>

<script>
import { defineComponent, inject, reactive, ref } from "vue";
import axios from "axios";

const API_BASE_URL = 'http://localhost:4000/api';

export default defineComponent({
  name: "UserCard",
  setup() {
    const userTools = inject("userTools");

    const search = ref("");
    const loading = ref(false);
    const users = ref([]);
    const createDialog = ref(false);
    const updateDialog = ref(false);
    const deleteDialog = ref(false);
    const editedIndex = ref(-1);
    const editedItem = ref({
      id: null,
      username: "",
      email: "",
      password: "",
      role: "",
    });
    const defaultItem = {
      id: null,
      username: "",
      email: "",
      password: "",
      role: "",
    };
    const roles = ["employee", "manager", "general_manager"];
    const valid = ref(true);
    const createForm = ref(null);
    const updateForm = ref(null);

    const headers = [
      { text: "Username", value: "username" },
      { text: "Email", value: "email" },
      { text: "Role", value: "role" },
      { text: "Actions", value: "actions", sortable: false },
    ];

    const usernameRules = [(v) => !!v || "Username is required"];

    const emailRules = [
      (v) => !!v || "Email is required",
      (v) => /.+@.+\..+/.test(v) || "Email must be valid",
    ];

    const passwordRules = [
      (v) => !!v || "Password is required",
      (v) => v.length >= 6 || "Password must be at least 6 characters",
    ];

    const roleRules = [
      (v) => !!v || "Role is required",
      (v) =>
        ["employee", "manager", "general_manager"].includes(v) ||
        "Please select a valid role",
    ];

    const errors = reactive({
      username: [],
      email: [],
      password: [],
      role: [],
    });

    const validateField = (value, rules) => {
      for (const rule of rules) {
        const result = rule(value);
        if (typeof result === "string") {
          return result;
        }
      }
      return true;
    };

    const validateForm = () => {
      errors.username = validateField(editedItem.value.username, usernameRules);
      errors.email = validateField(editedItem.value.email, emailRules);
      if (editedItem.value.password) {
        errors.password = validateField(editedItem.value.password, passwordRules);
      } else {
        errors.password = true;
      }
      errors.role = validateField(editedItem.value.role, roleRules);
      return Object.values(errors).every((field) => field === true);
    };

    const getUsers = async () => {
      loading.value = true;
      try {
        const response = await axios.get(`${API_BASE_URL}/users`, {
          headers: {
            Accept: "application/json",
            "Content-Type": "application/json",
            Authorization: `Bearer ${userTools.token}`,
          },
          withCredentials: true,
        });
        users.value = response.data.data;
      } catch (error) {
        console.error("Error fetching users:", error);
      } finally {
        loading.value = false;
      }
    };

    const openCreateUserDialog = () => {
      editedItem.value = { ...defaultItem };
      createDialog.value = true;
    };

    const closeCreateDialog = () => {
      createDialog.value = false;
      resetForm(createForm);
    };

    const createUser = async () => {
      if (validateForm()) {
        try {
          const response = await axios.post(
            `${API_BASE_URL}/users`,
            { user: editedItem.value },
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
            data: { user: editedItem.value },
            objInfo: {id: response.data.data.id}
          })

          users.value.push(response.data.data);
          closeCreateDialog();
          getUsers();
        } catch (error) {
          console.error("Error creating user:", error);
        }
      }
    };

    const openUpdateUserDialog = (item) => {
      editedIndex.value = users.value.indexOf(item);
      editedItem.value = { ...item };
      delete editedItem.value.password;
      updateDialog.value = true;
    };

    const closeUpdateDialog = () => {
      updateDialog.value = false;
      resetForm(updateForm);
    };

    const updateUser = async () => {
      if (validateForm()) {
        try {
          const response = await axios.put(
            `${API_BASE_URL}/users/${editedItem.value.id}`,
            { user: editedItem.value },
            {
              headers: {
                Accept: "application/json",
                "Content-Type": "application/json",
                Authorization: `Bearer ${userTools.token}`,
              },
              withCredentials: true,
            },
          );

          // gestion offline
          userTools.addOfflineRequest({
            url: `${API_BASE_URL}/users/${editedItem.value.id}`,
            method: "PUT",
            headers: {
              Accept: "application/json",
              "Content-Type": "application/json",
              Authorization: `Bearer ${userTools.token}`,
            },
            data: { user: editedItem.value }
          })

          Object.assign(users.value[editedIndex.value], response.data.data);
          closeUpdateDialog();
          getUsers();
        } catch (error) {
          console.error("Error updating user:", error);
        }
      }
    };

    const confirmDeleteUser = (item) => {
      editedIndex.value = users.value.indexOf(item);
      editedItem.value = { ...item };
      deleteDialog.value = true;
    };

    const closeDeleteDialog = () => {
      deleteDialog.value = false;
      editedItem.value = { ...defaultItem };
      editedIndex.value = -1;
    };

    const deleteUser = async () => {
      try {
        await axios.delete(`${API_BASE_URL}/users/${editedItem.value.id}`, {
          headers: {
            Accept: "application/json",
            "Content-Type": "application/json",
            Authorization: `Bearer ${userTools.token}`,
          },
          withCredentials: true,
        });

        // gestion offline
        userTools.addOfflineRequest({
          url: `${API_BASE_URL}/users/${editedItem.value.id}`,
          method: "DELETE",
          headers: {
            Accept: "application/json",
            "Content-Type": "application/json",
            Authorization: `Bearer ${userTools.token}`,
          },
        })

        users.value.splice(editedIndex.value, 1);
        closeDeleteDialog();
        getUsers();
      } catch (error) {
        console.error("Error deleting user:", error);
      }
    };

    const resetForm = (formRef) => {
      editedItem.value = { ...defaultItem };
      editedIndex.value = -1;
      if (formRef.value) {
        formRef.value.reset();
      }
      Object.keys(errors).forEach((key) => {
        errors[key] = [];
      });
    };

    getUsers();

    return {
      search,
      loading,
      users,
      headers,
      createDialog,
      updateDialog,
      deleteDialog,
      editedItem,
      roles,
      valid,
      createForm,
      updateForm,
      usernameRules,
      emailRules,
      passwordRules,
      roleRules,
      usernameErrors: () => errors.username,
      emailErrors: () => errors.email,
      passwordErrors: () => errors.password,
      roleErrors: () => errors.role,
      openCreateUserDialog,
      closeCreateDialog,
      createUser,
      openUpdateUserDialog,
      closeUpdateDialog,
      updateUser,
      confirmDeleteUser,
      closeDeleteDialog,
      deleteUser,
    };
  },
});
</script>

<style scoped>
.modern-input .v-input__control {
  background-color: rgba(255, 255, 255, 0.05);
  color: #ffffff;
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 8px;
  transition:
    border-color 0.3s,
    box-shadow 0.3s;
}

.modern-input .v-input__control:focus-within {
  border-color: rgba(30, 136, 229, 0.8);
  box-shadow: 0 0 10px rgba(30, 136, 229, 0.4);
}

.modern-input .v-label {
  color: rgba(255, 255, 255, 0.6);
  font-size: 16px;
  font-weight: 300;
  transition:
    color 0.3s,
    transform 0.3s;
}

.modern-input .v-label.v-label--active {
  color: rgba(30, 136, 229, 0.9);
  transform: translateY(-20px) scale(0.8);
}

.modern-input .v-input__control input {
  color: #ffffff;
  font-size: 16px;
}

.modern-input .v-select-list {
  background-color: rgba(0, 0, 0, 0.7);
}

.modern-input .v-select-list .v-list-item {
  color: #ffffff;
}

.modern-input .v-input__icon--append {
  color: rgba(255, 255, 255, 0.7);
}

.modern-input:hover .v-input__control {
  border-color: rgba(255, 255, 255, 0.3);
}

.modern-input .v-input--has-state .v-input__control {
  border-color: #f44336;
}

.user-management-card {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 16px;
  backdrop-filter: blur(10px);
  box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
  border: 1px solid rgba(255, 255, 255, 0.2);
  padding: 20px;
  margin: 20px;
  transition:
    box-shadow 0.3s,
    border-color 0.3s;
}

.user-management-card:hover {
  box-shadow: 0 6px 15px rgba(0, 0, 0, 0.3);
  border-color: rgba(255, 255, 255, 0.4);
}

.headline {
  color: #1e88e5;
  font-weight: bold;
  font-size: 24px;
  margin-bottom: 20px;
}

.glass-table {
  background-color: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(8px);
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.2);
  color: #ffffff;
  overflow: hidden;
}

.v-data-table-header th {
  background-color: rgba(30, 136, 229, 0.1);
  color: rgba(255, 255, 255, 0.9);
  font-weight: 600;
  text-transform: uppercase;
}

.v-data-table tbody tr {
  transition:
    background-color 0.3s ease,
    box-shadow 0.3s ease;
}

.v-data-table tbody tr:hover {
  background-color: rgba(30, 136, 229, 0.15);
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.1);
}

.v-data-table tbody tr:not(:last-child) {
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.edit-icon {
  color: #1e88e5;
  cursor: pointer;
  transition: transform 0.2s ease;
}

.edit-icon:hover {
  transform: scale(1.2);
}

.delete-icon {
  color: #e53935;
  cursor: pointer;
  transition: transform 0.2s ease;
}

.delete-icon:hover {
  transform: scale(1.2);
}

.glass-button {
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.2);
  color: white;
  transition: background-color 0.3s;
}
</style>
