const COLOR_PALETTE = ["#2e8f60", "#d7ab36", "#109618", "#0d47a1", "#ff9800"];
const charts = new Map();
const ChartLibrary = window.Chart;
const currencyFormatter = new Intl.NumberFormat("en-IN", {
  style: "currency",
  currency: "INR",
  minimumFractionDigits: 2
});

const parseJSON = (value) => {
  if (!value) return null;
  try {
    return JSON.parse(value);
  } catch (error) {
    console.error("Failed to parse chart data", error);
    return null;
  }
};

const destroyCharts = () => {
  charts.forEach((chart, canvas) => {
    chart.destroy();
    charts.delete(canvas);
  });
};

const renderChart = (canvas, config) => {
  if (!ChartLibrary) return;
  const ctx = canvas.getContext("2d");
  if (!ctx) return;
  if (charts.has(canvas)) {
    charts.get(canvas).destroy();
  }
  const chart = new ChartLibrary(ctx, config);
  charts.set(canvas, chart);
};

const chartTooltipLabel = (context) => {
  const value = Number(context.raw ?? context.parsed ?? 0);
  const label = context.dataset.label ?? context.label ?? "Value";
  return `${label}: ${currencyFormatter.format(value)}`;
};

const renderPieChart = () => {
  const canvas = document.getElementById("gst-pie-chart");
  if (!canvas) return;
  const rawData = parseJSON(canvas.dataset.chartData);
  if (!Array.isArray(rawData) || rawData.length === 0) return;

  const labels = rawData.map((item) => String(item[0] ?? ""));
  const data = rawData.map((item) => Number(item[1] ?? 0));
  const backgroundColor = rawData.map((_, index) => COLOR_PALETTE[index % COLOR_PALETTE.length]);

  renderChart(canvas, {
    type: "pie",
    data: {
      labels,
      datasets: [
        {
          data,
          backgroundColor,
          borderColor: "#ffffff",
          borderWidth: 2
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { position: "bottom" },
        tooltip: {
          callbacks: {
            label: (context) => chartTooltipLabel(context)
          }
        }
      }
    }
  });
};

const renderMonthlyGraph = () => {
  const canvas = document.getElementById("monthly-chart");
  if (!canvas) return;
  const rawData = parseJSON(canvas.dataset.chartData);
  if (!Array.isArray(rawData) || rawData.length === 0) return;

  const labelsSource = rawData.find((series) => Array.isArray(series.data) && series.data.length > 0);
  const labels = labelsSource ? labelsSource.data.map((point) => String(point[0] ?? "")) : [];

  const datasets = rawData.map((series, index) => ({
    label: String(series.name ?? `Series ${index + 1}`),
    data: Array.isArray(series.data)
      ? series.data.map((point) => Number(point[1] ?? 0))
      : [],
    backgroundColor: COLOR_PALETTE[index % COLOR_PALETTE.length],
    borderRadius: 4
  }));

  renderChart(canvas, {
    type: "bar",
    data: {
      labels,
      datasets
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      scales: {
        x: {
          title: { display: true, text: "Month" },
          stacked: false
        },
        y: {
          title: { display: true, text: "Amount (₹)" },
          ticks: {
            callback: (value) => {
              const numValue = Number(value);
              if (Number.isFinite(numValue) && Math.abs(numValue) >= 1000) {
                return `${(numValue / 1000).toFixed(1)}k`;
              }
              return numValue;
            }
          }
        }
      },
      plugins: {
        legend: { position: "top" },
        tooltip: {
          callbacks: {
            label: (context) => chartTooltipLabel(context)
          }
        }
      }
    }
  });
};

const initCharts = () => {
  destroyCharts();
  renderPieChart();
  renderMonthlyGraph();
};

document.addEventListener("turbo:load", initCharts);
document.addEventListener("turbo:before-cache", destroyCharts);
