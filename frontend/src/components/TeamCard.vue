<template>
  <v-app>
    <v-card class="team-management-card glass-card" elevation="2">
      <v-card-title class="headline">Team Management</v-card-title>
      <v-card-text>
        <v-row>
          <v-col cols="12" md="4" sm="6">
            <v-select
              v-model="search"
              class="dark-input"
              clearable
              :items="teams"
              item-title="team"
              item-value="value"
              label="Select Team"
              :loading="loading"
              required
            />
          </v-col>
          <v-col class="d-flex justify-end" cols="12" md="4" sm="6">
            <v-btn class="glass-button" @click="openCreateTeamMemberDialog">
              <v-icon left>mdi-account-plus</v-icon>
              Add Team Member
            </v-btn>
          </v-col>
        </v-row>
        <v-data-table
          class="glass-table"
          :headers="headers"
          :items="teamMembers"
          :loading="loading"
        >
          <template #[`item.actions`]="{ item }">
            <v-icon class="delete-icon" small @click="confirmDeleteTeamMember(item)">
              mdi-delete
            </v-icon>
          </template>
        </v-data-table>
      </v-card-text>
      <v-dialog v-model="createDialog" max-width="500px">
        <v-card class="glass-dialog">
          <v-card-title>Add New Team Member</v-card-title>
          <v-card-text>
            <v-form ref="createForm" v-model="valid">
              <v-select
                v-model="selectedUser"
                class="dark-input"
                clearable
                :items="users"
                item-title="username"
                item-value="id"
                label="Select User"
                required
              />
              <v-text-field
                v-model="teamId"
                class="dark-input"
                label="Team ID"
                required
              />
            </v-form>
          </v-card-text>
          <v-card-actions>
            <v-spacer />
            <v-btn color="transparent" text @click="closeCreateDialog">
              Cancel
            </v-btn>
            <v-btn class="glass-button" @click="createTeamMember"> Save </v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>
      <v-dialog v-model="deleteDialog" max-width="400px">
        <v-card class="glass-dialog">
          <v-card-title class="headline">Delete Team Member</v-card-title>
          <v-card-text>
            Are you sure you want to delete this team member?
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
              @click="deleteTeamMember"
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
  import { defineComponent, inject, reactive, ref, watch } from "vue";
  import axios from "axios";
  import Cookies from "js-cookie";
  import { jwtDecode } from "jwt-decode";

  const API_BASE_URL = 'http://localhost:4000/api';

  export default defineComponent({
    name: "TeamCard",
    setup() {
      const userTools = inject("userTools");

      const search = ref("");
      const loading = ref(false);
      const teamMembers = ref([]);
      const createDialog = ref(false);
      const deleteDialog = ref(false);
      const editedIndex = ref(-1);
      const selectedUser = ref(null);
      const teamId = ref("");
      const users = ref([]);
      const valid = ref(true);
      const createForm = ref(null);
      const teams = ref([]);

      const headers = [
        { text: "Username", value: "username" },
        { text: "Email", value: "email" },
        { text: "Role", value: "role" },
        { text: "Actions", value: "actions", sortable: false },
      ];

      const errors = reactive({
        username: [],
        email: [],
        password: [],
        role: [],
      });

      const getTeamMembers = async () => {

        if (search.value == null) return [];

        loading.value = true;
        try {
          const teamId = search.value;

          const response = await axios.get(`${API_BASE_URL}/teams/${teamId}/users`, {
            headers: {
              Accept: "application/json",
              "Content-Type": "application",
              Authorization: `Bearer ${userTools.token}`,
            },
            withCredentials: true,
          });
          teamMembers.value = response.data.data;
        } catch (error) {
          console.error("Error fetching team members:", error);
        } finally {
          loading.value = false;
        }
      };

      watch(search, async (newTeamId) => {
        await getTeamMembers();
      });

      const getTeams = async () => {
        try {
          const response = await axios.get(`${API_BASE_URL}/teams`, {
            headers: {
              Accept: "application/json",
              "Content-Type": "application/json",
              Authorization: `Bearer ${userTools.token}`,
            },
            withCredentials: true,
          });
          teams.value = response.data.data.map(teams => String(teams.id));
        } catch (error) {
          console.error("Error fetching teams:", error);
        }
      }

      const getUsers = async () => {
        try {
          const response = await axios.get(`${API_BASE_URL}/users`, {
            headers: {
              Accept: "application/json",
              "Content-Type": "application/json",
              Authorization: `Bearer ${userTools.token}`,
            },
            withCredentials: true,
          });
          users.value = response.data.data.map((user) => ({
            id: user.id,
            username: user.username,
          }));
        } catch (error) {
          console.error("Error fetching users:", error);
        }
      };

      const openCreateTeamMemberDialog = () => {
        selectedUser.value = null;
        teamId.value = "";
        createDialog.value = true;
        getUsers();
      };

      const closeCreateDialog = () => {
        createDialog.value = false;
        resetForm(createForm);
      };

      const createTeamMember = async () => {
        if (selectedUser.value && teamId.value) {
          try {
            await axios.put(
              `${API_BASE_URL}/users/${selectedUser.value}`,
              { user: { team_id: teamId.value } },
              {
                headers: {
                  Accept: "application/json",
                  "Content-Type": "application/json",
                  Authorization: `Bearer ${userTools.token}`,
                },
                withCredentials: true,
              },
            );
            closeCreateDialog();
            getTeamMembers();
          } catch (error) {
            console.error("Error updating team member:", error);
          }
        }
      };

      const confirmDeleteTeamMember = (item) => {
        editedIndex.value = teamMembers.value.indexOf(item);
        deleteDialog.value = true;
      };

      const closeDeleteDialog = () => {
        deleteDialog.value = false;
        editedIndex.value = -1;
      };

      const deleteTeamMember = async () => {
        try {
          await axios.delete(`${API_BASE_URL}/users/${teamMembers.value[editedIndex.value].id}`, {
            headers: {
              Accept: "application/json",
              "Content-Type": "application/json",
              Authorization: `Bearer ${userTools.token}`,
            },
            withCredentials: true,
          });

          teamMembers.value.splice(editedIndex.value, 1);
          closeDeleteDialog();
          getTeamMembers();
        } catch (error) {
          console.error("Error deleting team member:", error);
        }
      };

      const resetForm = (formRef) => {
        selectedUser.value = null;
        teamId.value = "";
        editedIndex.value = -1;
        if (formRef.value) {
          formRef.value.reset();
        }
        Object.keys(errors).forEach((key) => {
          errors[key] = [];
        });
      };

      onMounted(() => {
        if (userTools.isAdmin() || userTools.isGeneralManager()) {
          getTeams()
        }
      })

      return {
        search,
        loading,
        teamMembers,
        teams,
        search,
        headers,
        createDialog,
        deleteDialog,
        selectedUser,
        teamId,
        users,
        valid,
        createForm,
        openCreateTeamMemberDialog,
        closeCreateDialog,
        createTeamMember,
        confirmDeleteTeamMember,
        closeDeleteDialog,
        deleteTeamMember,
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

.team-management-card {
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

.team-management-card:hover {
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
