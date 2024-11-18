<template>
  <v-card class="team-chart-manager-card" elevation="2">
    <v-card-title class="headline">Team Chart Manager</v-card-title>
    <v-card-text>
      <v-row>
        <v-col cols="12" md="4" sm="6">
          <v-select
            v-model="selectedTeam"
            clearable
            :disabled="loading"
            item-title="team_name"
            item-value="team_id"
            :items="teams"
            label="Select Team"
            :loading="loading"
            @update:model-value="handleTeamChange"
          />
        </v-col>
        <v-col cols="12" md="4" sm="6">
          <v-select
            v-model="periodType"
            :disabled="loading"
            item-title="text"
            item-value="value"
            :items="periodTypes"
            label="Period Type"
            @update:model-value="resetDates"
          />
        </v-col>
        <v-col cols="12" md="4" sm="6">
          <v-menu
            v-model="dateMenu"
            :close-on-content-click="false"
            transition="scale-transition"
          >
            <template #activator="{ props }">
              <v-text-field
                v-model="formattedSelectedPeriod"
                :label="periodType === 'day' ? 'Select Date' : 'Select Week'"
                :prepend-icon="periodType === 'day' ? 'mdi-calendar' : 'mdi-calendar-week'"
                readonly
                v-bind="props"
              />
            </template>
            <v-date-picker
              v-model="selectedDate"
              :first-day-of-week="1"
              :show-week="periodType === 'week'"
              :type="periodType === 'week' ? 'week' : 'date'"
              @update:model-value="updateSelectedPeriod"
            />
          </v-menu>
        </v-col>
      </v-row>
      <v-row>
        <v-col cols="12">
          <v-btn color="primary" :disabled="!canGenerateChart" :loading="loading" @click="generateCharts">
            Generate Charts
          </v-btn>
        </v-col>
      </v-row>
      <v-row>
        <v-col cols="12">
          <div class="chart-container">
            <canvas ref="chartRef1" />
          </div>
        </v-col>
        <v-col cols="12">
          <div class="chart-container">
            <canvas ref="chartRef2" />
          </div>
        </v-col>
      </v-row>
    </v-card-text>
  </v-card>
</template>

<script setup lang="ts">
import { computed, inject, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import axios from 'axios'
import { Chart, ChartConfiguration, ChartData, ChartOptions } from 'chart.js/auto'
import { BarElement, CategoryScale, Legend, LinearScale, Title, Tooltip } from 'chart.js'
import { 
  addDays, 
  endOfDay, 
  endOfWeek, 
  format, 
  parseISO, 
  startOfDay, 
  startOfWeek,
  isSameDay,
  isSameWeek,
  isWithinInterval
} from 'date-fns'

Chart.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend)

const API_BASE_URL = 'http://localhost:4000/api';
const userTools = inject("userTools")

type TeamData = {
  team_id: number
  team_name: string
}

type TeamMemberData = {
  userId: number
  username: string
  clockEntries: any[]
  workingTimeEntries: any[]
}

type TimeSlotData = {
  x: string
  y: number[]
  start: number
  end: number
}

const selectedTeam = ref<number | null>(null)
const teams = ref<TeamData[]>([])
const teamUsers = ref<Array<{ id: number; username: string }>>([])
const periodType = ref('week')
const periodTypes = ref([
  { text: 'Day', value: 'day' },
  { text: 'Week', value: 'week' },
])
const loading = ref(false)
const chartRef1 = ref<HTMLCanvasElement | null>(null)
const chartRef2 = ref<HTMLCanvasElement | null>(null)
let chart1: Chart | null = null
let chart2: Chart | null = null

const selectedDate = ref(new Date())
const dateMenu = ref(false)
const canGenerateChart = computed(() => {
  return selectedTeam.value !== null && selectedDate.value !== null
})

const formattedSelectedPeriod = computed(() => {
  if (periodType.value === 'day') {
    return format(selectedDate.value, 'MMMM d, yyyy')
  } else {
    const start = startOfWeek(selectedDate.value, { weekStartsOn: 1 })
    const end = endOfWeek(selectedDate.value, { weekStartsOn: 1 })
    return `${format(start, 'MMM d')} - ${format(end, 'MMM d, yyyy')}`
  }
})

const formatToLocalTime = (dateString: string): string => {
  const date = parseISO(dateString)
  return format(date, 'yyyy-MM-dd HH:mm:ss')
}

const formatHour = (hour: number): string => {
  const hours = Math.floor(hour)
  const minutes = Math.round((hour - hours) * 60)
  return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`
}

const formatHoursAndMinutes = (hours: number): string => {
  if (isNaN(hours) || hours < 0) return 'N/A'
  const totalMinutes = Math.round(hours * 60)
  const h = Math.floor(totalMinutes / 60)
  const m = totalMinutes % 60
  if (h === 0) return `${m} minute${m !== 1 ? 's' : ''}`
  if (m === 0) return `${h}h`
  return `${h}h${m.toString().padStart(2, '0')}`
}

const updateSelectedPeriod = (date: Date | string) => {
  selectedDate.value = date instanceof Date ? date : new Date(date)
  dateMenu.value = false
}

const resetDates = () => {
  selectedDate.value = new Date()
}

const fetchTeams = async () => {
  try {
    loading.value = true
    const response = await axios.get(`${API_BASE_URL}/teams`, {
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        Authorization: `Bearer ${userTools.token}`,
      },
      withCredentials: true,
    })
    teams.value = response.data.data.map((team: any) => ({
      team_id: team.id,
      team_name: team.number
    }))
    
    if (userTools.team_id) {
      selectedTeam.value = userTools.team_id
      await handleTeamChange(userTools.team_id)
    }
  } catch (error) {
    console.error('Error fetching teams:', error)
  } finally {
    loading.value = false
  }
}

const fetchMyTeam = async () => {
  try {
    loading.value = true
    const response = await axios.get(`${API_BASE_URL}/teams/${selectedTeam.value}/users`, {
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        Authorization: `Bearer ${userTools.token}`,
      },
      withCredentials: true,
    })
    teams.value.push(selectedTeam.value)
  } catch (error) {
    console.error('Error fetching teams:', error)
  } finally {
    loading.value = false
  }
}

const handleTeamChange = async (teamId: number | null) => {
  if (!teamId) {
    teamUsers.value = []
    return
  }

  try {
    loading.value = true
    const response = await axios.get(`${API_BASE_URL}/teams/${teamId}/users`, {
      headers: {
        Authorization: `Bearer ${userTools.token}`,
      },
    })
    teamUsers.value = response.data.data
  } catch (error) {
    console.error('Error fetching team users:', error)
  } finally {
    loading.value = false
  }
}

const getStartAndEndDate = () => {
  if (periodType.value === 'week') {
    const start = startOfWeek(selectedDate.value, { weekStartsOn: 1 })
    const end = endOfWeek(selectedDate.value, { weekStartsOn: 1 })
    return {
      startDate: format(start, "yyyy-MM-dd'T'HH:mm:ssxxx"),
      endDate: format(end, "yyyy-MM-dd'T'HH:mm:ssxxx")
    }
  }
  return {
    startDate: format(startOfDay(selectedDate.value), "yyyy-MM-dd'T'HH:mm:ssxxx"),
    endDate: format(endOfDay(selectedDate.value), "yyyy-MM-dd'T'HH:mm:ssxxx")
  }
}

const calculateDayTotalHours = (entries: any[], targetDate: Date): number => {
  const targetStart = startOfDay(targetDate)
  const targetEnd = endOfDay(targetDate)
  
  return entries.reduce((total, entry) => {
    let entryStart = parseISO(entry.start || entry.start_time)
    let entryEnd = parseISO(entry.end || entry.end_time)
    
    // Gérer les entrées qui chevauchent minuit
    if (entryEnd < entryStart) {
      entryEnd = addDays(entryEnd, 1)
    }

    // Vérifier si l'entrée chevauche la période cible
    if (entryEnd <= targetStart || entryStart >= targetEnd) {
      return total
    }

    // Ajuster les heures de début et de fin si elles débordent de la journée cible
    const effectiveStart = entryStart < targetStart ? targetStart : entryStart
    const effectiveEnd = entryEnd > targetEnd ? targetEnd : entryEnd

    // Calculer la durée en heures
    const durationInHours = (effectiveEnd.getTime() - effectiveStart.getTime()) / (1000 * 60 * 60)
    return total + durationInHours
  }, 0)
}

const calculateWeekHours = (entries: any[], targetDate: Date, dayOfWeek: string): number => {
  // Trouver le jour spécifique dans la semaine
  const weekStart = startOfWeek(targetDate, { weekStartsOn: 1 })
  const dayIndex = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'].indexOf(dayOfWeek)
  const targetDayDate = addDays(weekStart, dayIndex)
  const targetStart = startOfDay(targetDayDate)
  const targetEnd = endOfDay(targetDayDate)

  return entries.reduce((total, entry) => {
    let entryStart = parseISO(entry.start || entry.start_time)
    let entryEnd = parseISO(entry.end || entry.end_time)

    // Gérer les entrées qui chevauchent minuit
    if (entryEnd < entryStart) {
      entryEnd = addDays(entryEnd, 1)
    }

    // Vérifier si l'entrée chevauche la période cible
    if (entryEnd <= targetStart || entryStart >= targetEnd) {
      return total
    }

    // Ajuster les heures de début et de fin si elles débordent de la journée cible
    const effectiveStart = entryStart < targetStart ? targetStart : entryStart
    const effectiveEnd = entryEnd > targetEnd ? targetEnd : entryEnd

    // Calculer la durée en heures
    const durationInHours = (effectiveEnd.getTime() - effectiveStart.getTime()) / (1000 * 60 * 60)
    return total + durationInHours
  }, 0)
}
const generateCharts = async () => {
  if (!canGenerateChart.value) return

  loading.value = true
  try {
    const { startDate, endDate } = getStartAndEndDate()
    
    const teamData = await Promise.all(
      teamUsers.value.map(async (user) => {
        const [clockResponse, workingTimeResponse] = await Promise.all([
          axios.get(`${API_BASE_URL}/clocks/${user.id}`, {
            params: { start_date: startDate, end_date: endDate },
            headers: {
              Authorization: `Bearer ${userTools.token}`,
            },
          }),
          axios.get(`${API_BASE_URL}/workingtime/${user.id}`, {
            headers: {
              Authorization: `Bearer ${userTools.token}`,
            },
          }),
        ])

        return {
          userId: user.id,
          username: user.username,
          clockEntries: clockResponse.data.data,
          workingTimeEntries: workingTimeResponse.data.data,
        }
      })
    )

    if (periodType.value === 'day') {
      updateDayCharts(teamData)
    } else {
      updateWeekCharts(teamData)
    }
  } catch (error) {
    console.error('Error fetching data:', error)
  } finally {
    loading.value = false
  }
}

const updateDayCharts = (teamData: TeamMemberData[]) => {
  const labels = teamData.map(data => data.username)
  const individualDatasets = [
    {
      label: 'Requested Hours',
      data: teamData.map(data => calculateDayTotalHours(data.workingTimeEntries, selectedDate.value)),
      backgroundColor: 'rgba(255, 206, 86, 0.6)',
      borderColor: 'rgb(255, 206, 86)',
      borderWidth: 1,
    },
    {
      label: 'Worked Hours',
      data: teamData.map(data => calculateDayTotalHours(
        data.clockEntries.filter(entry => entry.status === false),
        selectedDate.value
      )),
      backgroundColor: 'rgba(75, 192, 192, 0.6)',
      borderColor: 'rgb(75, 192, 192)',
      borderWidth: 1,
    },
  ]

  const averageRequested = individualDatasets[0].data.reduce((a, b) => a + b, 0) / teamData.length
  const averageWorked = individualDatasets[1].data.reduce((a, b) => a + b, 0) / teamData.length

  const averageDatasets = [
    {
      label: 'Average Requested Hours',
      data: [averageRequested],
      backgroundColor: 'rgba(255, 206, 86, 0.8)',
      borderColor: 'rgb(255, 206, 86)',
      borderWidth: 1,
    },
    {
      label: 'Average Worked Hours',
      data: [averageWorked],
      backgroundColor: 'rgba(75, 192, 192, 0.8)',
      borderColor: 'rgb(75, 192, 192)',
      borderWidth: 1,
    },
  ]

  updateCharts(
    { labels, datasets: individualDatasets },
    { labels: ['Team Average'], datasets: averageDatasets },
    `Individual Hours - ${format(selectedDate.value, 'MMMM d, yyyy')}`,
    `Team Average Hours - ${format(selectedDate.value, 'MMMM d, yyyy')}`
  )
}

const updateWeekCharts = (teamData: TeamMemberData[]) => {
  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
  const weekStart = startOfWeek(selectedDate.value, { weekStartsOn: 1 })

  const individualDatasets = teamData.flatMap(member => [
    {
      label: `${member.username} - Requested`,
      data: days.map(day => calculateWeekHours(member.workingTimeEntries, weekStart, day)),
      backgroundColor: `rgba(255, 206, 86, ${0.6 - member.userId * 0.1})`,
      borderColor: 'rgb(255, 206, 86)',
      borderWidth: 1,
    },
    {
      label: `${member.username} - Worked`,
      data: days.map(day => calculateWeekHours(
        member.clockEntries.filter(entry => entry.status === false),
        weekStart,
        day
      )),
      backgroundColor: `rgba(75, 192, 192, ${0.6 - member.userId * 0.1})`,
      borderColor: 'rgb(75, 192, 192)',
      borderWidth: 1,
    },
  ])

  const averageDatasets = [
    {
      label: 'Average Requested Hours',
      data: days.map(day => {
        const allRequested = teamData.map(member => 
          calculateWeekHours(member.workingTimeEntries, weekStart, day)
        )
        return allRequested.reduce((a, b) => a + b, 0) / teamData.length
      }),
      backgroundColor: 'rgba(255, 206, 86, 0.8)',
      borderColor: 'rgb(255, 206, 86)',
      borderWidth: 1,
    },
    {
      label: 'Average Worked Hours',
      data: days.map(day => {
        const allWorked = teamData.map(member => 
          calculateWeekHours(
            member.clockEntries.filter(entry => entry.status === false),
            weekStart,
            day
          )
        )
        return allWorked.reduce((a, b) => a + b, 0) / teamData.length
      }),
      backgroundColor: 'rgba(75, 192, 192, 0.8)',
      borderColor: 'rgb(75, 192, 192)',
      borderWidth: 1,
    },
  ]

  updateCharts(
    { labels: days, datasets: individualDatasets },
    { labels: days, datasets: averageDatasets },
    `Individual Weekly Hours - ${formattedSelectedPeriod.value}`,
    `Team Average Weekly Hours - ${formattedSelectedPeriod.value}`
  )
}

const updateCharts = (
  chartData1: ChartData,
  chartData2: ChartData,
  title1: string,
  title2: string
) => {
  const commonOptions: ChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    scales: {
      y: {
        beginAtZero: true,
        title: {
          display: true,
          text: 'Hours',
          color: '#ffffff'
        },
        grid: {
          color: 'rgba(255, 255, 255, 0.1)'
        },
        ticks: {
          color: '#ffffff'
        }
      },
      x: {
        grid: {
          color: 'rgba(255, 255, 255, 0.1)'
        },
        ticks: {
          color: '#ffffff'
        }
      }
    },
    plugins: {
      tooltip: {
        callbacks: {
          label: (context) => {
            return `${context.dataset.label}: ${formatHoursAndMinutes(context.parsed.y)}`
          }
        }
      },
      legend: {
        labels: {
          color: '#ffffff'
        }
      }
    }
  }

  if (chart1) chart1.destroy()
  if (chart2) chart2.destroy()

  chart1 = new Chart(chartRef1.value!, {
    type: 'bar',
    data: chartData1,
    options: {
      ...commonOptions,
      plugins: {
        ...commonOptions.plugins,
        title: {
          display: true,
          text: title1,
          color: '#ffffff'
        }
      }
    },
  })

  chart2 = new Chart(chartRef2.value!, {
    type: 'bar',
    data: chartData2,
    options: {
      ...commonOptions,
      plugins: {
        ...commonOptions.plugins,
        title: {
          display: true,
          text: title2,
          color: '#ffffff'
        }
      }
    },
  })
}

// Watches
watch(() => selectedTeam.value, (newValue) => {
  if (newValue) {
    handleTeamChange(newValue)
  }
})

// Lifecycle hooks
onMounted(() => {
  if (userTools.isAdmin() || userTools.isGeneralManager()) fetchTeams()
  else if (userTools.isManager()){
    selectedTeam.value = userTools.team_id
    fetchMyTeam()
  }
})

onBeforeUnmount(() => {
  if (chart1) {
    chart1.destroy()
    chart1 = null
  }
  if (chart2) {
    chart2.destroy()
    chart2 = null
  }
})
</script>

<style scoped>
.team-chart-manager-card {
  margin: 20px;
  padding: 20px;
  background-color: rgba(255, 255, 255, 0.05);
  backdrop-filter: blur(5px);
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.headline {
  color: #ffffff;
  font-size: 1.5rem;
  font-weight: 500;
  margin-bottom: 1rem;
}

.chart-container {
  height: 400px;
  width: 100%;
  margin-top: 20px;
  background-color: rgba(255, 255, 255, 0.08);
  border-radius: 8px;
  padding: 16px;
}

@media (min-width: 960px) {
  .chart-container {
    height: 500px;
  }
}

:deep(.v-btn) {
  margin: 8px;
}

:deep(.v-text-field) {
  color: #ffffff;
}

:deep(.v-select) {
  color: #ffffff;
}

:deep(.v-select__selection-text) {
  color: #ffffff;
}

:deep(.v-field__input) {
  color: #ffffff !important;
}

:deep(.v-field__outline) {
  --v-field-border-opacity: 0.7;
}

:deep(.v-label) {
  color: rgba(255, 255, 255, 0.7);
}

:deep(.v-picker__title) {
  background-color: rgba(25, 118, 210, 0.9);
}

:deep(.v-date-picker-month) {
  background-color: rgba(255, 255, 255, 0.05);
}

:deep(.v-date-picker-controls .v-btn) {
  color: #ffffff;
}

:deep(.v-date-picker-month__day) {
  color: #ffffff;
}

:deep(.v-date-picker-month__day--selected) {
  background-color: rgba(25, 118, 210, 0.9);
}

:deep(.v-date-picker-controls .v-btn--active) {
  background-color: rgba(25, 118, 210, 0.9);
}
</style>