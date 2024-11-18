<template>
  <v-app>
    <v-card class="working-times-card glass-card" elevation="2">
      <v-card-title class="headline">User Working Times</v-card-title>
      <v-card-text>
        <v-row>
          <v-col cols="12" md="4" sm="6">
            <v-select
              v-model="selectedUser"
              class="dark-input modern-input"
              clearable
              item-title="username"
              item-value="id"
              :items="users"
              label="Select User"
              prepend-icon="mdi-account"
            />
          </v-col>
          <v-col cols="12" md="4" sm="6">
            <v-btn class="glass-button" @click="resetSelection">
              <v-icon left>mdi-refresh</v-icon>
              Reset
            </v-btn>
          </v-col>
        </v-row>
        <v-data-table
          class="glass-table elevation-1"
          :headers="headers"
          :items="workingTimes"
          :loading="loading"
        >
          <template #[`item.start`]="{ item }">
            <span class="time-column-start">{{ item.start }}</span>
          </template>
          <template #[`item.end`]="{ item }">
            <span class="time-column-end">{{ item.end }}</span>
          </template>
        </v-data-table>
      </v-card-text>
    </v-card>
  </v-app>
</template>

<script>
import { defineComponent, onMounted, ref, watch } from "vue";
import axios from "axios";
import { format, parseISO } from "date-fns";

const API_BASE_URL = 'http://localhost:4000/api';

export default defineComponent({
  name: "WorkingTimesCard",
  setup() {
    const userTools = inject("userTools");
    const USER_ID = userTools.user_id;

    const users = ref([]);
    const selectedUser = ref(null);
    const workingTimes = ref([]);
    const loading = ref(false);

    const headers = [
      { text: "User ID", value: "user.id" },
      { text: "Username", value: "user.username" },
      { text: "Start Time", value: "start" },
      { text: "End Time", value: "end" },
    ];

    const formatToLocalTime = (dateString) => {
      const date = parseISO(dateString);
      return format(date, "yyyy-MM-dd HH:mm:ss");
    };

    const fetchUsers = async () => {
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
      }
    };

    const fetchTeamUsers = async () => {
    loading.value = true
    try {
      const response = await axios.get(`${API_BASE_URL}/teams/${userTools.team_id}/users`, {
        headers: {
          Accept: 'application/json',
          'Content-Type': 'application/json',
          Authorization: `Bearer ${userTools.token}`,
        },
        withCredentials: true,
      })
      users.value = response.data.data.map((user) => ({
        id: user.id,
        username: user.username,
      }))
    } catch (error) {
      console.error('Error fetching users:', error)
    } finally {
      loading.value = false
    }
  }

    const fetchWorkingTimes = async () => {
      if (!selectedUser.value) return;
      loading.value = true;
      try {
        const response = await axios.get(
          `${API_BASE_URL}/workingtime/${selectedUser.value}`,
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
      } finally {
        loading.value = false;
      }
    };

    const resetSelection = () => {
      selectedUser.value = null;
      workingTimes.value = [];
    };

    onMounted(() => {
      if (userTools.isAdmin() || userTools.isGeneralManager()) { fetchUsers() }
      else if (userTools.isManager()) { fetchTeamUsers() }
      else {
        selectedUser.value = USER_ID;
        fetchWorkingTimes();
      }
    });

    watch(selectedUser, fetchWorkingTimes);

    return {
      users,
      selectedUser,
      workingTimes,
      loading,
      headers,
      fetchWorkingTimes,
      resetSelection,
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
  background: rgba(255, 255, 255, 0.1);
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
