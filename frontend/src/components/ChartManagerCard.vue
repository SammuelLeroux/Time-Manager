<template>
  <v-card class="chart-manager-card" elevation="2">
    <v-card-title class="headline">Chart Manager</v-card-title>
    <v-card-text>
      <v-row>
        <v-col cols="12" md="4" sm="6">
          <v-select
            v-model="selectedUser"
            clearable
            :disabled="loading"
            item-title="username"
            item-value="id"
            :items="users"
            label="Select User"
            :loading="loading"
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
        <v-col cols="12" md="6">
          <div class="chart-container">
            <canvas ref="chartRef1" />
          </div>
        </v-col>
        <v-col cols="12" md="6">
          <div class="chart-container">
            <canvas ref="chartRef2" />
          </div>
        </v-col>
      </v-row>
    </v-card-text>
  </v-card>
</template>

<script setup lang="ts">
  import { computed, inject, onMounted, ref } from 'vue'
  import axios from 'axios'
  import { Chart, ChartConfiguration, ChartData, ChartOptions } from 'chart.js/auto'
  import { BarElement, CategoryScale, Legend, LinearScale, TimeScale, Title, Tooltip } from 'chart.js'
  import 'chartjs-adapter-date-fns'
  import { addDays, endOfDay, endOfWeek, format, parseISO, startOfDay, startOfWeek } from 'date-fns'

  Chart.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend, TimeScale)

  const API_BASE_URL = 'http://localhost:4000/api';

  const userTools = inject("userTools");

  type TimeSlotData = {
    x: string;
    y: number[];
    start: number;
    end: number;
  }

  const selectedUser = ref<number | null>(null)
  const users = ref<Array<{ id: number; username: string }>>([])
  const periodType = ref('week')
  const periodTypes = ref([
    { text: 'Day', value: 'day' },
    { text: 'Week', value: 'week' },
  ])
  const loading = ref(false)
  const chartRef1 = ref<HTMLCanvasElement | null>(null)
  const chartRef2 = ref<HTMLCanvasElement | null>(null)
  let chart1: Chart<'bar', TimeSlotData[], string> | null = null
  let chart2: Chart | null = null

  const selectedDate = ref(new Date())
  const dateMenu = ref(false)
  const chartOptions = computed<ChartOptions<'bar'>>(() => ({
    responsive: true,
    maintainAspectRatio: false,
    scales: {
      x: {
        type: 'category',
        title: {
          display: true,
          text: 'Days of the Week',
        },
      },
      y: {
        type: 'linear',
        min: 0,
        max: 24,
        ticks: {
          stepSize: 1,
          callback: value => `${value}:00`,
        },
        title: {
          display: true,
          text: 'Hours of the Day',
        },
      },
    },
    plugins: {
      tooltip: {
        callbacks: {
          title: tooltipItems => {
            const item = tooltipItems[0]
            return `${item.label} - ${item.formattedValue}`
          },
          label: context => {
            const datasetLabel = context.dataset.label || ''
            const data = context.raw as TimeSlotData
            return `${datasetLabel}: ${formatHour(data.start)} - ${formatHour(data.end)}`
          },
        },
      },
      legend: {
        display: true,
      },
    },
  }))

  const formattedSelectedPeriod = computed(() => {
    if (periodType.value === 'day') {
      return selectedDate.value.toLocaleDateString()
    } else {
      const start = getWeekStart(selectedDate.value)
      const end = new Date(start)
      end.setDate(end.getDate() + 6)
      return `${start.toLocaleDateString()} - ${end.toLocaleDateString()}`
    }
  })

  const canGenerateChart = computed(() => selectedUser.value && selectedDate.value)

  /*
  const formatToLocalTime = (dateString: string): string => {
    const date = parseISO(dateString)
    return format(date, 'yyyy-MM-dd HH:mm:ss')
  }
  */

  const fetchUsers = async () => {
    loading.value = true
    try {
      const response = await axios.get(`${API_BASE_URL}/users`, {
        headers: {
          Accept: 'application/json',
          'Content-Type': 'application/json',
          Authorization: `Bearer ${userTools.token}`,
        },
        withCredentials: true,
      })
      users.value = response.data.data.map((user: any) => ({
        id: user.id,
        username: user.username,
      }))
    } catch (error) {
      console.error('Error fetching users:', error)
    } finally {
      loading.value = false
    }
  }

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
      users.value = response.data.data.map((user: any) => ({
        id: user.id,
        username: user.username,
      }))
    } catch (error) {
      console.error('Error fetching users:', error)
    } finally {
      loading.value = false
    }
  }

  const generateCharts = async () => {
    if (!canGenerateChart.value) return

    loading.value = true
    try {
      const { startDate, endDate } = getStartAndEndDate()
      const [clockResponse, workingTimeResponse] = await Promise.all([
        axios.get(`${API_BASE_URL}/clocks/${selectedUser.value}`, {
          params: { start_date: startDate, end_date: endDate },
          headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
            Authorization: `Bearer ${userTools.token}`,
          },
          withCredentials: true,
        }),
        axios.get(`${API_BASE_URL}/workingtime/${selectedUser.value}`, {
          headers: {
            Accept: 'application/json',
            'Content-Type': 'application/json',
            Authorization: `Bearer ${userTools.token}`,
          },
          withCredentials: true,
        }),
      ])

      const clockEntries = clockResponse.data.data
      const workingTimeEntries = workingTimeResponse.data.data

      if (periodType.value === 'day') {
        const processedData = processDayData(clockEntries, workingTimeEntries, startDate)
        updateDayChartData(processedData)
      } else {
        const processedData = processWeekData(clockEntries, workingTimeEntries, startDate, endDate)
        updateWeekChartData(processedData)
      }
    } catch (error) {
      console.error('Error fetching data:', error)
    } finally {
      loading.value = false
    }
  }

  const getStartAndEndDate = () => {
    let startDate, endDate
    if (periodType.value === 'day') {
      startDate = startOfDay(selectedDate.value)
      endDate = endOfDay(selectedDate.value)
    } else {
      startDate = startOfWeek(selectedDate.value, { weekStartsOn: 1 })
      endDate = endOfWeek(selectedDate.value, { weekStartsOn: 1 })
    }
    return {
      startDate: formatDateToISOString(startDate),
      endDate: formatDateToISOString(endDate),
    }
  }

  const formatDateToISOString = (date: Date) => {
    return format(date, "yyyy-MM-dd'T'HH:mm:ssxxx")
  }

  const processDayData = (clockEntries: any[], workingTimeEntries: any[], date: string) => {
    const start = parseISO(date)
    const end = addDays(start, 1)
    const processedDataChart1: TimeSlotData[] = []
    const processedDataChart2 = { totalRequested: 0, totalWorked: 0 }

    const addDataToProcessedChart1 = (entries: any[], dataType: 'requested' | 'worked') => {
      entries.forEach(entry => {
        const entryStart = parseISO(entry.start || entry.start_time)
        let entryEnd = parseISO(entry.end || entry.end_time)

        // Gérer les entrées qui chevauchent minuit
        if (entryEnd < entryStart) {
          entryEnd = addDays(entryEnd, 1)
        }

        if ((entryStart < end && entryEnd > start) || (entryStart >= start && entryStart < end)) {
          const clampedStart = Math.max(entryStart.getTime(), start.getTime())
          const clampedEnd = Math.min(entryEnd.getTime(), end.getTime())

          const startHours = (clampedStart - start.getTime()) / (1000 * 60 * 60)
          const endHours = (clampedEnd - start.getTime()) / (1000 * 60 * 60)

          processedDataChart1.push({
            x: dataType,
            y: [startHours, endHours],
            start: startHours,
            end: endHours,
          })
        }
      })
    }

    const addDataToProcessedChart2 = (entries: any[], dataType: 'requested' | 'worked') => {
      entries.forEach(entry => {
        const entryStart = parseISO(entry.start || entry.start_time)
        let entryEnd = parseISO(entry.end || entry.end_time)

        // Gérer les entrées qui chevauchent minuit
        if (entryEnd < entryStart) {
          entryEnd = addDays(entryEnd, 1)
        }

        if ((entryStart < end && entryEnd > start) || (entryStart >= start && entryStart < end)) {
          const clampedStart = Math.max(entryStart.getTime(), start.getTime())
          const clampedEnd = Math.min(entryEnd.getTime(), end.getTime())
          const duration = (clampedEnd - clampedStart) / (1000 * 60 * 60)
          processedDataChart2[dataType === 'requested' ? 'totalRequested' : 'totalWorked'] += duration
        }
      })
    }

    addDataToProcessedChart1(workingTimeEntries, 'requested')
    addDataToProcessedChart1(clockEntries.filter(entry => entry.status === false && entry.end_time !== null), 'worked')

    addDataToProcessedChart2(workingTimeEntries, 'requested')
    addDataToProcessedChart2(clockEntries.filter(entry => entry.status === false && entry.end_time !== null), 'worked')

    return { processedDataChart1, processedDataChart2 }
  }

  const processWeekData = (clockEntries: any[], workingTimeEntries: any[], startDate: string, endDate: string) => {
    const start = parseISO(startDate)
    const end = parseISO(endDate)
    const processedDataChart1: { [key: string]: { requested: TimeSlotData[], worked: TimeSlotData[] } } = {}
    const processedDataChart2: { [key: string]: { totalRequested: number, totalWorked: number } } = {}

    const daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
    daysOfWeek.forEach(day => {
      processedDataChart1[day] = { requested: [], worked: [] }
      processedDataChart2[day] = { totalRequested: 0, totalWorked: 0 }
    })

    const addDataToProcessedChart1 = (entries: any[], dataType: 'requested' | 'worked') => {
      entries.forEach(entry => {
        let entryStart = parseISO(entry.start || entry.start_time)
        let entryEnd = parseISO(entry.end || entry.end_time)

        // Gérer les entrées qui chevauchent minuit
        if (entryEnd < entryStart) {
          entryEnd = addDays(entryEnd, 1)
        }

        // Traiter chaque jour couvert par l'entrée
        let currentDay = startOfDay(entryStart)
        while (currentDay < entryEnd && currentDay < end) {
          const nextDay = addDays(currentDay, 1)
          const dayOfWeek = daysOfWeek[getDayIndex(currentDay)]

          const dayStart = Math.max(entryStart.getTime(), currentDay.getTime())
          const dayEnd = Math.min(entryEnd.getTime(), nextDay.getTime())

          if (dayStart < end.getTime() && dayEnd > start.getTime()) {
            const startHours = (dayStart - currentDay.getTime()) / (1000 * 60 * 60)
            const endHours = (dayEnd - currentDay.getTime()) / (1000 * 60 * 60)

            processedDataChart1[dayOfWeek][dataType].push({
              x: dayOfWeek,
              y: [startHours, endHours],
              start: startHours,
              end: endHours,
            })
          }

          currentDay = nextDay
          entryStart = new Date(nextDay)
        }
      })
    }

    const addDataToProcessedChart2 = (entries: any[], dataType: 'requested' | 'worked') => {
      entries.forEach(entry => {
        let entryStart = parseISO(entry.start || entry.start_time)
        let entryEnd = parseISO(entry.end || entry.end_time)

        // Gérer les entrées qui chevauchent minuit
        if (entryEnd < entryStart) {
          entryEnd = addDays(entryEnd, 1)
        }

        // Traiter chaque jour couvert par l'entrée
        let currentDay = startOfDay(entryStart)
        while (currentDay < entryEnd && currentDay < end) {
          const nextDay = addDays(currentDay, 1)
          const dayOfWeek = daysOfWeek[getDayIndex(currentDay)]

          const dayStart = Math.max(entryStart.getTime(), currentDay.getTime())
          const dayEnd = Math.min(entryEnd.getTime(), nextDay.getTime())

          if (dayStart < end.getTime() && dayEnd > start.getTime()) {
            const duration = (dayEnd - dayStart) / (1000 * 60 * 60)
            processedDataChart2[dayOfWeek][dataType === 'requested' ? 'totalRequested' : 'totalWorked'] += duration
          }

          currentDay = nextDay
          entryStart = new Date(nextDay)
        }
      })
    }

    addDataToProcessedChart1(workingTimeEntries, 'requested')
    addDataToProcessedChart1(clockEntries.filter(entry => entry.status === false && entry.end_time !== null), 'worked')

    addDataToProcessedChart2(workingTimeEntries, 'requested')
    addDataToProcessedChart2(clockEntries.filter(entry => entry.status === false && entry.end_time !== null), 'worked')

    return { processedDataChart1, processedDataChart2 }
  }
  const updateDayChartData = (processedData: {
    processedDataChart1: TimeSlotData[],
    processedDataChart2: { totalRequested: number, totalWorked: number }
  }) => {
    const dayLabel = format(selectedDate.value, 'EEEE, MMM d, yyyy')
    const datasets1 = [
      {
        label: 'Requested Hours',
        data: processedData.processedDataChart1.filter(d => d.x === 'requested'),
        backgroundColor: 'rgba(255, 206, 86, 0.6)',
        borderColor: 'rgb(255, 206, 86)',
        borderWidth: 1,
      },
      {
        label: 'Worked Hours',
        data: processedData.processedDataChart1.filter(d => d.x === 'worked'),
        backgroundColor: 'rgba(75, 192, 192, 0.6)',
        borderColor: 'rgb(75, 192, 192)',
        borderWidth: 1,
      },
    ]

    const datasets2 = [
      {
        label: 'Total Requested Hours',
        data: [{ x: 'Requested', y: processedData.processedDataChart2.totalRequested }],
        backgroundColor: 'rgba(255, 206, 86, 0.6)',
        borderColor: 'rgb(255, 206, 86)',
        borderWidth: 1,
      },
      {
        label: 'Total Worked Hours',
        data: [{ x: 'Worked', y: processedData.processedDataChart2.totalWorked }],
        backgroundColor: 'rgba(75, 192, 192, 0.6)',
        borderColor: 'rgb(75, 192, 192)',
        borderWidth: 1,
      },
    ]
    if (chart1) chart1.destroy()
    if (chart2) chart2.destroy()

    const dayChartOptions: ChartOptions<'bar'> = {
      ...chartOptions.value,
      scales: {
        x: {
          type: 'category',
          title: {
            display: true,
            text: 'Date',
          },
        },
        y: {
          type: 'linear',
          min: 0,
          max: 24,
          ticks: {
            stepSize: 1,
            callback: value => `${value}:00`,
          },
          title: {
            display: true,
            text: 'Hours of the Day',
          },
        },
      },
      plugins: {
        tooltip: {
          callbacks: {
            title: () => dayLabel,
            label: context => {
              const data = context.raw as TimeSlotData
              return `${context.dataset.label}: ${formatHour(data.start)} - ${formatHour(data.end)}`
            },
          },
        },
      },
    }

    chart1 = new Chart<'bar', TimeSlotData[], string>(chartRef1.value!, {
      type: 'bar',
      data: {
        labels: [dayLabel],
        datasets: datasets1,
      } as ChartData<'bar', TimeSlotData[], string>,
      options: {
        ...dayChartOptions,
        plugins: {
          ...dayChartOptions.plugins,
          tooltip: {
            ...dayChartOptions.plugins?.tooltip,
            callbacks: {
              ...dayChartOptions.plugins?.tooltip?.callbacks,
              title: tooltipItems => {
                const item = tooltipItems[0]
                return `${dayLabel} - ${item.dataset.label}`
              },
            },
          },
        },
      } as ChartConfiguration<'bar', TimeSlotData[], string>['options'],
    })

    const chart2Options: ChartOptions<'bar'> = {
      ...chartOptions.value,
      scales: {
        x: {
          type: 'category',
          title: {
            display: true,
            text: 'Type',
          },
        },
        y: {
          beginAtZero: true,
          title: {
            display: true,
            text: 'Total Hours',
          },
        },
      },
      plugins: {
        tooltip: {
          callbacks: {
            label: context => {
              const label = context.dataset.label || ''
              const value = context.parsed.y
              return `${label}: ${formatHoursAndMinutes(value)}`
            },
          },
        },
        legend: {
          display: true,
          labels: {
          },
        },
      },
    }

    chart2 = new Chart(chartRef2.value!, {
      type: 'bar',
      data: {
        labels: ['Requested', 'Worked'],
        datasets: datasets2,
      },
      options: chart2Options,
    } as ChartConfiguration<'bar', { x: string; y: number }[], string>)
  }

  const updateWeekChartData = (processedData: {
    processedDataChart1: { [key: string]: { requested: TimeSlotData[], worked: TimeSlotData[] } },
    processedDataChart2: { [key: string]: { totalRequested: number, totalWorked: number } }
  }) => {
    const labels = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']

    const datasets1 = [
      {
        label: 'Requested Hours',
        data: labels.flatMap(day => processedData.processedDataChart1[day].requested),
        backgroundColor: 'rgba(255, 206, 86, 0.6)',
        borderColor: 'rgb(255, 206, 86)',
        borderWidth: 1,
      },
      {
        label: 'Worked Hours',
        data: labels.flatMap(day => processedData.processedDataChart1[day].worked),
        backgroundColor: 'rgba(75, 192, 192, 0.6)',
        borderColor: 'rgb(75, 192, 192)',
        borderWidth: 1,
      },
    ]

    const datasets2 = [
      {
        label: 'Total Requested Hours',
        data: labels.map(day => processedData.processedDataChart2[day].totalRequested),
        backgroundColor: 'rgba(255, 206, 86, 0.6)',
        borderColor: 'rgb(255, 206, 86)',
        borderWidth: 1,
      },
      {
        label: 'Total Worked Hours',
        data: labels.map(day => processedData.processedDataChart2[day].totalWorked),
        backgroundColor: 'rgba(75, 192, 192, 0.6)',
        borderColor: 'rgb(75, 192, 192)',
        borderWidth: 1,
      },
    ]

    if (chart1) chart1.destroy()
    if (chart2) chart2.destroy()

    chart1 = new Chart<'bar', TimeSlotData[], string>(chartRef1.value!, {
      type: 'bar',
      data: {
        labels,
        datasets: datasets1,
      } as ChartData<'bar', TimeSlotData[], string>,
      options: {
        ...chartOptions.value,
        scales: {
          x: {
            type: 'category',
            title: {
              display: true,
              text: 'Days of the Week',
            },
          },
          y: {
            type: 'linear',
            min: 0,
            max: 24,
            ticks: {
              stepSize: 1,
              callback: value => `${value}:00`,
            },
            title: {
              display: true,
              text: 'Hours of the Day',
            },
          },
        },
      } as ChartConfiguration<'bar', TimeSlotData[], string>['options'],
    })

    chart2 = new Chart(chartRef2.value!, {
      type: 'bar',
      data: {
        labels,
        datasets: datasets2,
      },
      options: {
        ...chartOptions.value,
        scales: {
          x: {
            type: 'category',
            title: {
              display: true,
              text: 'Days of the Week',
            },
          },
          y: {
            beginAtZero: true,
            title: {
              display: true,
              text: 'Hours',
            },
          },
        },
        plugins: {
          ...chartOptions.value.plugins,
          tooltip: {
            callbacks: {
              label: context => {
                const label = context.dataset.label || ''
                const value = context.parsed.y
                return `${label}: ${formatHoursAndMinutes(value)}`
              },
            },
          },
        },
      },
    })
  }

  const formatHour = (hour: number): string => {
    const hours = Math.floor(hour)
    const minutes = Math.round((hour - hours) * 60)
    return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`
  }

  const formatHoursAndMinutes = (hours: number): string => {
    if (isNaN(hours) || hours < 0) {
      return 'N/A'
    }

    const totalMinutes = Math.round(hours * 60)
    const h = Math.floor(totalMinutes / 60)
    const m = totalMinutes % 60

    if (h === 0) {
      return `${m} minute${m !== 1 ? 's' : ''}`
    } else if (m === 0) {
      return `${h}h`
    } else {
      return `${h}h${m.toString().padStart(2, '0')}`
    }
  }

  const updateSelectedPeriod = (date: Date | string) => {
    selectedDate.value = date instanceof Date ? date : new Date(date)
    dateMenu.value = false
  }

  const resetDates = () => {
    selectedDate.value = new Date()
  }

  const getWeekStart = (date: Date) => {
    const day = date.getDay()
    const diff = date.getDate() - day + (day === 0 ? -6 : 1)
    return new Date(date.setDate(diff))
  }

  const getDayIndex = (date: Date): number => {
    return (date.getDay() + 6) % 7
  }

  onMounted(()=> {
    if (userTools.isAdmin() || userTools.isGeneralManager()) { fetchUsers() }
    else if (userTools.isManager()) { fetchTeamUsers() }
    else {
      selectedUser.value = userTools.user_id
      users.value = [selectedUser.value]
    }
  })

</script>

<style scoped>
.chart-manager-card {
  margin: 20px;
  padding: 20px;
}

.headline {
  color: #1976d2;
}

.chart-container {
  height: 400px;
  width: 100%;
  margin-top: 20px;
}

@media (min-width: 960px) {
  .chart-container {
    height: 500px;
  }
}
</style>