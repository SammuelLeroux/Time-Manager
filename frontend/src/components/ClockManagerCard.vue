<template>
  <v-app>
    <v-card class="clock-manager-card glass-card" elevation="2">
      <v-card-title class="headline">Clock Manager</v-card-title>
      <v-card-text>
        <v-row>
          <v-col class="d-flex justify-center" cols="12">
            <v-btn
              v-if="!clockedIn"
              class="ma-2 glass-button clock-in-button"
              @click="clockIn"
            >
              <v-icon left>mdi-login</v-icon>
              Clock In
            </v-btn>
            <v-btn
              v-else
              class="ma-2 glass-button clock-out-button"
              @click="clockOut"
            >
              <v-icon left>mdi-logout</v-icon>
              Clock Out
            </v-btn>
          </v-col>
        </v-row>

        <v-row>
          <v-col class="d-flex justify-center" cols="12">
            <div class="clock-display">{{ currentTime }}</div>
          </v-col>
        </v-row>

        <v-data-table
          class="glass-table elevation-1"
          :headers="headers"
          :items="formattedClockEntries"
          :loading="loading"
        >
          <template #[`item.status`]="{ item }">
            <span
              :class="{
                'status-clocked-in': item.status === 'Clocked In',
                'status-clocked-out': item.status === 'Clocked Out',
              }"
            >
              {{ item.status }}
            </span>
          </template>
        </v-data-table>
      </v-card-text>
    </v-card>
  </v-app>
</template>

<script>
import {
  computed,
  defineComponent,
  inject,
  onMounted,
  onUnmounted,
  ref,
} from "vue";
import axios from "axios";

const API_BASE_URL = 'http://localhost:4000/api';

export default defineComponent({
  name: "ClockManagerCard",

  setup() {
    const userTools = inject("userTools");
    const USER_ID = userTools.user_id;

    const currentTime = ref(new Date().toLocaleTimeString());
    const clockedIn = ref(false);
    const clockEntries = ref([]);
    const loading = ref(false);

    const headers = [
      { text: "Start Time", value: "start_time" },
      { text: "End Time", value: "end_time" },
      { text: "Status", value: "status" },
    ];

    const updateCurrentTime = () => {
      currentTime.value = new Date().toLocaleTimeString();
    };

    const getClockEntries = async () => {
      if (!userTools) return;

      loading.value = true;
      try {
        const response = await axios.get(`${API_BASE_URL}/clocks/${USER_ID}`, {
          headers: {
            Accept: "application/json",
            "Content-Type": "application/json",
            Authorization: `Bearer ${userTools.token}`,
          },
          withCredentials: true,
        });
        clockEntries.value = response.data.data;
        const lastClock = clockEntries.value[clockEntries.value.length - 1];
        clockedIn.value = lastClock && lastClock.status;
      } catch (error) {
        console.error("Error fetching clock entries:", error);
      } finally {
        loading.value = false;
      }
    };

    const clockIn = async () => {
      if (!userTools) return;

      try {
        const response = await axios.post(
          `${API_BASE_URL}/clocks/${USER_ID}`,
          {
            clock: { start_time: new Date(), end_time: null, status: true },
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
          url: `${API_BASE_URL}/clocks/${USER_ID}`,
          method: "POST",
          headers: {
            Accept: "application/json",
            "Content-Type": "application/json",
            Authorization: `Bearer ${userTools.token}`,
          },
          data: {
            clock: { start_time: new Date(), end_time: null, status: true },
          },
          objInfo: {id: response.data.data.id}
        })

        clockedIn.value = true;
        getClockEntries();
      } catch (error) {
        console.error("Error clocking in:", error);
      }
    };

    const clockOut = async () => {
      if (!userTools) return;

      try {
        const lastClock = clockEntries.value[clockEntries.value.length - 1];
        const response = await axios.post(
          `${API_BASE_URL}/clocks/${USER_ID}`,
          {
            clock: {
              start_time: lastClock.start_time,
              end_time: new Date(),
              status: false,
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
          url: `${API_BASE_URL}/clocks/${USER_ID}`,
          method: "POST",
          headers: {
            Accept: "application/json",
            "Content-Type": "application/json",
            Authorization: `Bearer ${userTools.token}`,
          },
          data: {
            clock: {
              start_time: lastClock.start_time,
              end_time: new Date(),
              status: false,
            },
          },
          objInfo: {id: response.data.data.id}
        })

        clockedIn.value = false;
        getClockEntries();
      } catch (error) {
        console.error("Error clocking out:", error);
      }
    };

    const formattedClockEntries = computed(() => {
      return clockEntries.value.map((entry) => ({
        start_time: new Date(entry.start_time).toLocaleString(),
        end_time: entry.end_time
          ? new Date(entry.end_time).toLocaleString()
          : "N/A",
        status: entry.status ? "Clocked In" : "Clocked Out",
      }));
    });

    onMounted(() => {
      getClockEntries();
      const interval = setInterval(updateCurrentTime, 1000);
      onUnmounted(() => clearInterval(interval));
    });

    return {
      currentTime,
      clockedIn,
      clockEntries,
      formattedClockEntries,
      headers,
      loading,
      clockIn,
      clockOut,
    };
  },
});
</script>

<style scoped>
.clock-manager-card {
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

.clock-manager-card:hover {
  box-shadow: 0 6px 15px rgba(0, 0, 0, 0.3);
  border-color: rgba(255, 255, 255, 0.4);
}

.headline {
  color: #1e88e5;
  font-weight: bold;
  font-size: 24px;
  margin-bottom: 20px;
}

.clock-display {
  font-size: 2em;
  color: white;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 8px;
  padding: 10px;
  backdrop-filter: blur(8px);
  border: 1px solid rgba(255, 255, 255, 0.2);
}

.v-data-table {
  border-radius: 12px;
  box-shadow: none;
  border: none;
  color: white;
  margin-top: 20px;
  background: rgba(255, 255, 255, 0.1);
}

.glass-button {
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.2);
  color: white;
  transition: background-color 0.3s;
}

.clock-in-button {
  background: rgba(76, 175, 80, 0.2);
}

.clock-in-button:hover {
  background: rgba(76, 175, 80, 0.4);
}

.clock-out-button {
  background: rgba(244, 67, 54, 0.2);
}

.clock-out-button:hover {
  background: rgba(244, 67, 54, 0.4);
}

.status-clocked-in {
  color: #4caf50;
  font-weight: bold;
}

.status-clocked-out {
  color: #f44336;
  font-weight: bold;
}
</style>
