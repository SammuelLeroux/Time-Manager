<template>
  <v-app>
    <!-- Arrière-plan 3D -->
    <div class="spline-background">
      <spline-viewer
        url="https://prod.spline.design/UkQa3LUUlu0u-Hmm/scene.splinecode"
      />
    </div>

    <!-- Barre de navigation supérieure -->
    <v-app-bar app class="nav-bar">
      <v-app-bar-title class="text-h6">Dashboard</v-app-bar-title>
      <v-spacer />
      <v-btn v-if="token" icon @click="drawer = !drawer">
        <v-icon>mdi-menu</v-icon>
      </v-btn>
      <v-btn icon @click="showNewsletterPopup = true">
        <v-icon>mdi-bell</v-icon>
      </v-btn>
      <!-- Nouveau bouton pour le profil -->
      <v-btn v-if="token" icon @click="showProfileDialog = true">
        <v-icon>mdi-account</v-icon>
      </v-btn>
      <v-btn v-if="!token" icon @click="showLoginPopup = true">
        <v-icon>mdi-account-circle</v-icon>
      </v-btn>
      <v-btn v-else icon @click="logout">
        <v-icon>mdi-logout</v-icon>
      </v-btn>
    </v-app-bar>

    <!-- Barre latérale -->
    <v-navigation-drawer v-model="drawer" app class="side-bar">
      <v-list dense>
        <v-list-item
          v-for="card in accessibleCards"
          :key="card.route"
          @click="navigateTo(card.route)"
        >
          <v-list-item-title>{{ card.title }}</v-list-item-title>
        </v-list-item>
      </v-list>
    </v-navigation-drawer>

    <!-- Conteneur principal -->
    <v-main>
      <v-container fluid>
        <UserCard v-if="selectedCard === 'user'" />
        <WorkingTimeCard v-if="selectedCard === 'working-time'" />
        <WorkingTimesCard v-if="selectedCard === 'working-times'" />
        <ClockManagerCard v-if="selectedCard === 'clock-manager'" />
        <ChartManagerCard v-if="selectedCard === 'chart-manager'" />
        <TeamChartManagerCard v-if="selectedCard === 'team-chart-manager'" />
        <TeamCard v-if="selectedCard === 'team'" />
      </v-container>
    </v-main>

    <!-- Login Popup -->
    <LoginPopup :show="showLoginPopup" @close="handleLoginPopupClose" />

    <!-- Newsletter Popup -->
    <NewsletterPopup
      :role="userTools.role"
      :show="showNewsletterPopup"
      @close="handleNewsletterPopupClose"
    />

    <!-- Profile Dialog -->
    <ProfileDialog v-model="showProfileDialog" :isGoogleUser="userTools.isGoogleUser"/>
  </v-app>
</template>

<script lang="ts" setup>
import { computed, provide, ref } from "vue";
import Cookies from "js-cookie";
import { jwtDecode } from "jwt-decode";

import UserCard from "@/components/UserCard.vue";
import WorkingTimeCard from "@/components/WorkingTimeCard.vue";
import WorkingTimesCard from "@/components/WorkingTimesCard.vue";
import ClockManagerCard from "@/components/ClockManagerCard.vue";
import ChartManagerCard from "@/components/ChartManagerCard.vue";
import TeamChartManagerCard from "@/components/TeamChartManagerCard.vue";
import TeamCard from "@/components/TeamCard.vue";
import LoginPopup from "@/components/LoginPopup.vue";
import NewsletterPopup from "@/components/NewsletterPopup.vue";
import UsersTools from "@/utils/UserTools";
import { DecodedToken } from "@utils/types";
import ProfileDialog from "@/components/ProfileDialog.vue";

import "https://unpkg.com/@splinetool/viewer@1.9.32/build/spline-viewer.js";

const userTools = new UsersTools();
provide("userTools", userTools);

const drawer = ref(false);
const selectedCard = ref("users");
const showLoginPopup = ref(false);
const showNewsletterPopup = ref(false);
const showProfileDialog = ref(false);

const token = Cookies.get("token");
if (token) {
  userTools.token = token;
  try {
    const decoded: DecodedToken = jwtDecode<DecodedToken>(token);
    userTools.decodedToken = decoded;
    userTools.role = userTools.decodedToken?.role || null;
    userTools.user_id = userTools.decodedToken?.user_id || null;
    userTools.team_id = userTools.decodedToken?.team_id || null;
    userTools.isGoogleUser = userTools.decodedToken?.is_google_user.toString();
  } catch (error) {
    console.error("Error decoding token:", error);
  }
}

const cards = [
  { route: "user", title: "User Management", roles: ["admin", "general_manager"] },
  {
    route: "working-time",
    title: "Working Time",
    roles: ["manager", "general_manager", "admin"],
  },
  {
    route: "working-times",
    title: "Working Times",
    roles: ["employee", "manager", "general_manager", "admin"],
  },
  {
    route: "clock-manager",
    title: "Clock Manager",
    roles: ["employee", "manager", "general_manager", "admin"],
  },
  {
    route: "chart-manager",
    title: "Chart Manager",
    roles: ["employee", "manager", "general_manager", "admin"],
  },
  {
    route: "team-chart-manager",
    title: "Team Chart Manager",
    roles: ["manager", "general_manager", "admin"],
  },
  {
    route: "team",
    title: "Team Management",
    roles: ["general_manager", "admin"],
  },
];

const accessibleCards = computed(() => {
  if (userTools.role) {
    return cards.filter((card) => card.roles.includes(userTools.role));
  } else {
    return [];
  }
});

function navigateTo(route) {
  selectedCard.value = route;
}

function handleLoginPopupClose() {
  showLoginPopup.value = false;
}

function handleNewsletterPopupClose() {
  showNewsletterPopup.value = false;
}

function logout() {
  Cookies.remove("token");
  window.location.reload();
}
</script>

<style scoped>
/* Style général pour un thème sombre et épuré */
body {
  background-color: #000000;
  color: #ffffff;
}

.spline-background {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  overflow: hidden;
}

.spline-background spline-viewer {
  width: 100%;
  height: 100%;
}

/* Barre de navigation avec effet de verre dépoli */
.nav-bar {
  background-color: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(10px);
  box-shadow: none;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  color: #ffffff;
}

/* Style des icônes pour qu'elles soient plus modernes */
.v-btn {
  color: rgba(255, 255, 255, 0.8);
  transition: all 0.3s ease;
}

.v-btn:hover {
  color: #ffffff;
  transform: translateY(-2px);
}

/* Barre latérale épurée avec fond transparent */
.side-bar {
  background-color: rgba(0, 0, 0, 0.7);
  backdrop-filter: blur(10px);
  color: #ffffff;
  border-right: 1px solid rgba(255, 255, 255, 0.1);
}

/* Cartes avec un style épuré et un fond léger */
.bento-card {
  background-color: rgba(255, 255, 255, 0.05);
  backdrop-filter: blur(5px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  color: #ffffff;
  transition:
    background-color 0.3s ease,
    transform 0.3s ease;
}

.bento-card:hover {
  background-color: rgba(255, 255, 255, 0.1);
  transform: translateY(-5px);
}

.text-h6 {
  font-weight: 600;
  color: #ffffff;
}

/* Animation pour l'arrière-plan des boutons */
.v-btn > .v-icon {
  transition: transform 0.3s ease;
}

.v-btn:hover > .v-icon {
  transform: scale(1.1);
}

/* Nouveaux styles pour les boutons de la navbar */
.v-app-bar .v-btn {
  margin-left: 8px;
}

.v-app-bar .v-btn:hover {
  background-color: rgba(255, 255, 255, 0.1);
}
</style>
