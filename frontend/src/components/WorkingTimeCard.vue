<template>
  <v-app>
    <v-card class="working-times-card glass-card" elevation="2">
      <v-card-title class="headline">User Working Times</v-card-title>
      <v-card-text>
        <v-row>
          <v-col cols="12" md="4" sm="6">
            <v-text-field
              v-model="search"
              class="dark-input modern-input"
              clearable
              label="Search users"
              prepend-icon="mdi-magnify"
            />
          </v-col>
          <v-col cols="12" md="4" sm="6">
            <v-btn class="glass-button" @click="openCreateWorkingTimeDialog">
              <v-icon left>mdi-clock-plus</v-icon>
              Add Working Time
            </v-btn>
          </v-col>
        </v-row>

        <v-data-table
          class="glass-table elevation-1"
          :headers="headers"
          :items="workingTimes"
          :loading="loading"
          :search="search"
        >
          <template #[`item.actions`]="{ item }">
            <v-icon
              class="mr-2"
              small
              @click="openUpdateWorkingTimeDialog(item)"
            >
              mdi-pencil
            </v-icon>
            <v-icon small @click="confirmDeleteWorkingTime(item)">
              mdi-delete
            </v-icon>
          </template>
        </v-data-table>
      </v-card-text>

      <!-- Create Working Time Dialog -->
      <v-dialog v-model="createDialog" max-width="500px">
        <v-card>
          <v-card-title class="headline">Add Working Time</v-card-title>
          <v-card-text>
            <v-form ref="createForm" v-model="valid">
              <v-select
                v-model="editedItem.user"
                class="dark-input modern-input"
                item-title="username"
                item-value="id"
                :items="users"
                label="User"
                required
                :rules="[(v) => !!v || 'User is required']"
              />
              <v-row>
                <v-col cols="6">
                  <v-text-field
                    v-model="editedItem.startDate"
                    class="dark-input modern-input"
                    label="Start Date"
                    :min="today"
                    required
                    :rules="[
                      (v) => !!v || 'Start date is required',
                      validateStartDate,
                    ]"
                    type="date"
                  />
                </v-col>
                <v-col cols="6">
                  <v-text-field
                    v-model="editedItem.startTime"
                    class="dark-input modern-input"
                    label="Start Time"
                    required
                    :rules="[(v) => !!v || 'Start time is required']"
                    type="time"
                  />
                </v-col>
              </v-row>
              <v-row>
                <v-col cols="6">
                  <v-text-field
                    v-model="editedItem.endDate"
                    class="dark-input modern-input"
                    label="End Date"
                    :min="editedItem.startDate || today"
                    required
                    :rules="[
                      (v) => !!v || 'End date is required',
                      validateEndDate,
                    ]"
                    type="date"
                  />
                </v-col>
                <v-col cols="6">
                  <v-text-field
                    v-model="editedItem.endTime"
                    class="dark-input modern-input"
                    label="End Time"
                    required
                    :rules="[
                      (v) => !!v || 'End time is required',
                      validateEndTime,
                    ]"
                    type="time"
                  />
                </v-col>
              </v-row>
            </v-form>
            <v-alert v-if="errorMessage" dense type="error">
              {{ errorMessage }}
            </v-alert>
          </v-card-text>
          <v-card-actions>
            <v-spacer />
            <v-btn
              class="glass-button"
              color="blue darken-1"
              text
              @click="closeCreateDialog"
            >
              Cancel
            </v-btn>
            <v-btn
              class="glass-button"
              color="blue darken-1"
              text
              @click="createWorkingTime"
            >
              Save
            </v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>

      <!-- Update Working Time Dialog -->
      <v-dialog v-model="updateDialog" max-width="500px">
        <v-card>
          <v-card-title class="headline">Edit Working Time</v-card-title>
          <v-card-text>
            <v-form ref="updateForm" v-model="valid">
              <!--
              <v-select
                v-model="editedItem.user"
                class="dark-input modern-input"
                item-title="username"
                item-value="id"
                :items="users"
                label="User"
                required
                :rules="[(v) => !!v || 'User is required']"
              />
            -->
              <v-row>
                <v-col cols="6">
                  <v-text-field
                    v-model="editedItem.startDate"
                    class="dark-input modern-input"
                    label="Start Date"
                    :min="today"
                    required
                    :rules="[
                      (v) => !!v || 'Start date is required',
                      validateStartDate,
                    ]"
                    type="date"
                  />
                </v-col>
                <v-col cols="6">
                  <v-text-field
                    v-model="editedItem.startTime"
                    class="dark-input modern-input"
                    label="Start Time"
                    required
                    :rules="[(v) => !!v || 'Start time is required']"
                    type="time"
                  />
                </v-col>
              </v-row>
              <v-row>
                <v-col cols="6">
                  <v-text-field
                    v-model="editedItem.endDate"
                    class="dark-input modern-input"
                    label="End Date"
                    :min="editedItem.startDate || today"
                    required
                    :rules="[
                      (v) => !!v || 'End date is required',
                      validateEndDate,
                    ]"
                    type="date"
                  />
                </v-col>
                <v-col cols="6">
                  <v-text-field
                    v-model="editedItem.endTime"
                    class="dark-input modern-input"
                    label="End Time"
                    required
                    :rules="[
                      (v) => !!v || 'End time is required',
                      validateEndTime,
                    ]"
                    type="time"
                  />
                </v-col>
              </v-row>
            </v-form>
            <v-alert v-if="errorMessage" dense type="error">
              {{ errorMessage }}
            </v-alert>
          </v-card-text>
          <v-card-actions>
            <v-spacer />
            <v-btn
              class="glass-button"
              color="blue darken-1"
              text
              @click="closeUpdateDialog"
            >
              Cancel
            </v-btn>
            <v-btn
              class="glass-button"
              color="blue darken-1"
              text
              @click="updateWorkingTime"
            >
              Update
            </v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>

      <!-- Delete Confirmation Dialog -->
      <v-dialog v-model="deleteDialog" max-width="400px">
        <v-card>
          <v-card-title class="headline">Delete Working Time</v-card-title>
          <v-card-text>
            Are you sure you want to delete this working time?
          </v-card-text>
          <v-card-actions>
            <v-spacer />
            <v-btn
              class="glass-button"
              color="blue darken-1"
              text
              @click="closeDeleteDialog"
            >
              Cancel
            </v-btn>
            <v-btn
              class="glass-button"
              color="red darken-1"
              text
              @click="deleteWorkingTime"
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
import { computed, defineComponent, inject, onMounted, ref } from "vue";
import axios from "axios";
import { format, isAfter, isBefore, isEqual, parseISO } from "date-fns";

const API_BASE_URL = 'http://localhost:4000/api';

export default defineComponent({
  name: "WorkingTimeCard",

  setup() {
    const userTools = inject("userTools");
    const USER_ID = userTools.user_id;

    const search = ref("");
    const loading = ref(false);
    const workingTimes = ref([]);
    const users = ref([]);
    const createDialog = ref(false);
    const updateDialog = ref(false);
    const deleteDialog = ref(false);
    const editedIndex = ref(-1);
    const editedItem = ref({
      id: null,
      user: "",
      startDate: "",
      startTime: "",
      endDate: "",
      endTime: "",
    });
    const defaultItem = {
      id: null,
      user: "",
      startDate: "",
      startTime: "",
      endDate: "",
      endTime: "",
    };
    const valid = ref(true);
    const createForm = ref(null);
    const updateForm = ref(null);
    const errorMessage = ref("");

    const headers = [
      { text: "User ID", value: "user.id" },
      { text: "Username", value: "user.username" },
      { text: "Start Time", value: "start" },
      { text: "End Time", value: "end" },
      { text: "Actions", value: "actions", sortable: false },
    ];

    const today = computed(() => {
      return new Date().toISOString().split("T")[0];
    });

    const formatToLocalTime = (dateString) => {
      const date = parseISO(dateString);
      return format(date, "yyyy-MM-dd HH:mm:ss");
    };

    const validateStartDate = (v) => {
      if (isBefore(parseISO(v), parseISO(today.value))) {
        return "Start date cannot be in the past";
      }
      return true;
    };

    const validateEndDate = (v) => {
      if (isBefore(parseISO(v), parseISO(editedItem.value.startDate))) {
        return "End date must be after start date";
      }
      return true;
    };

    const validateEndTime = (v) => {
      const startDateTime = new Date(
        `${editedItem.value.startDate}T${editedItem.value.startTime}`,
      );
      const endDateTime = new Date(`${editedItem.value.endDate}T${v}`);

      if (
        isEqual(startDateTime, endDateTime) ||
        isBefore(endDateTime, startDateTime)
      ) {
        return "End time must be after start time";
      }
      return true;
    };

    const checkOverlap = (newStart, newEnd, userId, excludeId = null) => {
      return workingTimes.value.some((wt) => {
        if (excludeId && wt.id === excludeId) return false;
        if (wt.user.id !== userId) return false;
        const existingStart = parseISO(wt.start);
        const existingEnd = parseISO(wt.end);
        return (
          isEqual(newStart, existingStart) ||
          isEqual(newEnd, existingEnd) ||
          (isAfter(newStart, existingStart) &&
            isBefore(newStart, existingEnd)) ||
          (isAfter(newEnd, existingStart) && isBefore(newEnd, existingEnd)) ||
          (isBefore(newStart, existingStart) && isAfter(newEnd, existingEnd))
        );
      });
    };

    const getWorkingTimes = async () => {
      loading.value = true;
      try {
        const response = await axios.get(
          `${API_BASE_URL}/workingtime/${USER_ID}`,
          {
            headers: {
              Accept: "application/json",
              "Content-Type": "application/json",
              Authorization: `Bearer ${userTools.token}`,
            },
            withCredentials: true,
          },
        );
        workingTimes.value = response.data.data.map((item) => ({
          ...item,
          user: users.value.find((user) => user.id === item.user_id) || {},
          start: formatToLocalTime(item.start),
          end: formatToLocalTime(item.end),
        }));
      } catch (error) {
        console.error("Error fetching working times:", error);
        errorMessage.value = "Failed to fetch working times. Please try again.";
      } finally {
        loading.value = false;
      }
    };

    const getAllWorkingTimes = async () => {
      loading.value = true;
      try {
        const response = await axios.get(
          `${API_BASE_URL}/workingtime`,
          {
            headers: {
              Accept: "application/json",
              "Content-Type": "application/json",
              Authorization: `Bearer ${userTools.token}`,
            },
            withCredentials: true,
          },
        );
        workingTimes.value = response.data.data.map((item) => ({
          ...item,
          user: users.value.find((user) => user.id === item.user_id) || {},
          start: formatToLocalTime(item.start),
          end: formatToLocalTime(item.end),
        }));
      } catch (error) {
        console.error("Error fetching working times:", error);
        errorMessage.value = "Failed to fetch working times. Please try again.";
      } finally {
        loading.value = false;
      }
    };

    const getUsers = async () => {
      try {
        const response = await axios.get(`${API_BASE_URL}/users/`, {
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
        errorMessage.value = "Failed to fetch users. Please try again.";
      }
    };

    const getTeamMembers = async () => {
      try {
        const response = await axios.get(`${API_BASE_URL}/teams/${userTools.team_id}/users`, {
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
        errorMessage.value = "Failed to fetch users. Please try again.";
      }
    };

    const getTeamMembersWorkingTime = async () => {
      loading.value = true;
      try {
        // Boucle asynchrone sur chaque utilisateur
        const workingTimePromises = users.value.map(async (user) => {
          const response = await axios.get(`${API_BASE_URL}/workingtime/${user.id}`, {
            headers: {
              Accept: "application/json",
              "Content-Type": "application/json",
              Authorization: `Bearer ${userTools.token}`,
            },
            withCredentials: true,
          });
          
          // Associe les temps de travail de l'utilisateur avec son profil
          return response.data.data.map((item) => ({
            ...item,
            user: { id: user.id, username: user.username },
            start: formatToLocalTime(item.start),
            end: formatToLocalTime(item.end),
          }));
        });

        // Résout toutes les requêtes en parallèle et affecte à `workingTimes.value`
        const results = await Promise.all(workingTimePromises);
        workingTimes.value = results.flat();
      } catch (error) {
        console.error("Error fetching individual working times:", error);
        errorMessage.value = "Failed to fetch individual working times. Please try again.";
      } finally {
        loading.value = false;
      }
    };

    const openCreateWorkingTimeDialog = () => {
      editedItem.value = { ...defaultItem };
      createDialog.value = true;
      errorMessage.value = "";
    };

    const closeCreateDialog = () => {
      createDialog.value = false;
      resetForm(createForm);
      errorMessage.value = "";
    };

    const createWorkingTime = async () => {
      if (valid.value) {
        try {
          const startDate = new Date(
            `${editedItem.value.startDate}T${editedItem.value.startTime}`,
          );
          const endDate = new Date(
            `${editedItem.value.endDate}T${editedItem.value.endTime}`,
          );
          // Assurez-vous que editedItem.value.user contient l'ID de l'utilisateur
          const userId = editedItem.value.user;
          const response = await axios.post(
            `${API_BASE_URL}/workingtime/${userId}`,
            {
              working_time: {
                start: startDate.toISOString(),
                end: endDate.toISOString(),
              },
            },
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
            url: `${API_BASE_URL}/workingtime/${userId}`,
            method: "POST",
            headers: {
              Accept: "application/json",
              "Content-Type": "application/json",
              Authorization: `Bearer ${userTools.token}`,
            },
            data: {
              working_time: {
                start: startDate.toISOString(),
                end: endDate.toISOString(),
              },
            }
          })

          workingTimes.value.push(response.data.data);
          closeCreateDialog();
          
          init()
        } catch (error) {
          handleApiError(error, "creating");
        }
      }
    };

    const openUpdateWorkingTimeDialog = (item) => {
      editedIndex.value = workingTimes.value.indexOf(item);
      const [startDate, startTime] = item.start.split(" ");
      const [endDate, endTime] = item.end.split(" ");
      editedItem.value = { ...item, startDate, startTime, endDate, endTime };
      updateDialog.value = true;
      errorMessage.value = "";
    };

    const closeUpdateDialog = () => {
      updateDialog.value = false;
      resetForm(updateForm);
      errorMessage.value = "";
    };

    const updateWorkingTime = async () => {
      if (valid.value) {
        try {
          const startDate = new Date(
            `${editedItem.value.startDate}T${editedItem.value.startTime}`,
          );
          const endDate = new Date(
            `${editedItem.value.endDate}T${editedItem.value.endTime}`,
          );

          const response = await axios.put(
            `${API_BASE_URL}/workingtime/${editedItem.value.id}`,
            {
              working_time: {
                start: startDate.toISOString(),
                end: endDate.toISOString(),
              },
            },
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
            url: `${API_BASE_URL}/workingtime/${editedItem.value.id}`,
            method: "PUT",
            headers: {
              Accept: "application/json",
              "Content-Type": "application/json",
              Authorization: `Bearer ${userTools.token}`,
            },
            data: {
              working_time: {
                start: startDate.toISOString(),
                end: endDate.toISOString(),
              },
            }
          })

          Object.assign(
            workingTimes.value[editedIndex.value],
            response.data.data,
          );
          closeUpdateDialog();
          
          init()
        } catch (error) {
          handleApiError(error, "updating");
        }
      }
    };

    const confirmDeleteWorkingTime = (item) => {
      editedIndex.value = workingTimes.value.indexOf(item);
      editedItem.value = { ...item };
      deleteDialog.value = true;
    };

    const closeDeleteDialog = () => {
      deleteDialog.value = false;
      editedItem.value = { ...defaultItem };
      editedIndex.value = -1;
    };

    const deleteWorkingTime = async () => {
      try {
        await axios.delete(
          `${API_BASE_URL}/workingtime/${editedItem.value.id}`,
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
          url: `${API_BASE_URL}/workingtime/${editedItem.value.id}`,
          method: "DELETE",
          headers: {
            Accept: "application/json",
            "Content-Type": "application/json",
            Authorization: `Bearer ${userTools.token}`,
          },
          data: {
            current_password: deleteConfirmation.value.password,
          },
        })

        workingTimes.value.splice(editedIndex.value, 1);
        closeDeleteDialog();
        
        init()
      } catch (error) {
        handleApiError(error, "deleting");
      }
    };

    const handleApiError = (error, action) => {
      // console.error(`Error ${action} working time:`, error);
      if (error.response && error.response.data) {
        if (error.response.data.errors) {
          errorMessage.value = Object.values(error.response.data.errors).join(
            ", ",
          );
        } else if (error.response.data.error) {
          errorMessage.value = error.response.data.error;
        } else {
          errorMessage.value = `An error occurred while ${action} the working time.`;
        }
      } else {
        errorMessage.value = `An error occurred while ${action} the working time.`;
      }
    };

    const resetForm = (formRef) => {
      editedItem.value = { ...defaultItem };
      editedIndex.value = -1;
      if (formRef.value) {
        formRef.value.reset();
      }
      errorMessage.value = "";
    };

    const init = () => {
      if (userTools.isAdmin() || userTools.isGeneralManager()) {
        getUsers().then(() => getAllWorkingTimes());
      }
      else if (userTools.isManager()) { getTeamMembers().then(() => getTeamMembersWorkingTime()); }
      else { getWorkingTimes(); }
    }

    onMounted(() => {
      init();
    });

    return {
      search,
      loading,
      workingTimes,
      users,
      headers,
      createDialog,
      updateDialog,
      deleteDialog,
      editedItem,
      valid,
      createForm,
      updateForm,
      errorMessage,
      today,
      validateStartDate,
      validateEndDate,
      validateEndTime,
      openCreateWorkingTimeDialog,
      closeCreateDialog,
      createWorkingTime,
      openUpdateWorkingTimeDialog,
      closeUpdateDialog,
      updateWorkingTime,
      confirmDeleteWorkingTime,
      closeDeleteDialog,
      deleteWorkingTime,
    };
  },
});
</script>

<style scoped>
.working-times-card {
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

.working-times-card:hover {
  box-shadow: 0 6px 15px rgba(0, 0, 0, 0.3);
  border-color: rgba(255, 255, 255, 0.4);
}

.headline {
  color: #1e88e5;
  font-weight: bold;
  font-size: 24px;
  margin-bottom: 20px;
}

.dark-input .v-input__control {
  background-color: rgba(255, 255, 255, 0.05);
  color: #ffffff;
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 8px;
  transition:
    border-color 0.3s,
    box-shadow 0.3s;
}

.dark-input .v-input__control:focus-within {
  border-color: rgba(30, 136, 229, 0.8);
  box-shadow: 0 0 10px rgba(30, 136, 229, 0.4);
}

.v-data-table {
  border-radius: 12px;
  box-shadow: none;
  border: none;
  color: #ffffff;
  margin-top: 20px;
  overflow: hidden;
  background: rgba(255, 255, 255, 0.1);
}

.glass-button {
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.2);
  color: white;
  transition: background-color 0.3s;
}

.glass-button:hover {
  background: rgba(255, 255, 255, 0.2);
}

.time-column-start {
  color: lime;
}

.time-column-end {
  color: red;
}
</style>
