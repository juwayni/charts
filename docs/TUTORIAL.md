# PixieCharts Step-by-Step Tutorial 🎓

Welcome to the **PixieCharts** step-by-step tutorial! This guide covers everything from basic canvas setup to building customized multi-series charts, animating chart reveals, and exporting frame sequences for GIF and video creation.

---

## Tutorial 1: Rendering Your First Chart

All chart rendering procedures in PixieCharts draw into a Pixie `Context` using a loaded TTF `Font` and bounding `Rect`.

```nim
import pixie
import pixiecharts

# 1. Load a font
let font = readFont("Roboto-Regular.ttf")

# 2. Create an image canvas and context
let img = newImage(800, 600)
let ctx = newContext(img)
let bounds = rect(0, 0, 800, 600)

# 3. Create chart entries
let entries = @[
  newChartEntry(120.0f, "Jan", "$120k", color(0.18f, 0.53f, 0.82f, 1.0f)),
  newChartEntry(180.0f, "Feb", "$180k", color(0.15f, 0.68f, 0.38f, 1.0f)),
  newChartEntry(240.0f, "Mar", "$240k", color(0.95f, 0.77f, 0.06f, 1.0f))
]

# 4. Configure options
var cfg = defaultChartConfig()
cfg.showYAxisText = true
cfg.showYAxisLines = true

# 5. Render bar chart
drawBarChart(ctx, font, bounds, entries, cfg)

# 6. Save image to disk
img.writeFile("my_first_chart.png")
```

---

## Tutorial 2: Multi-Series Stacked Charts

For multi-series data (e.g., comparing products or regions across categories), use `ChartSerie`:

```nim
import pixie
import pixiecharts

let font = readFont("Roboto-Regular.ttf")
let img = newImage(800, 600)
let ctx = newContext(img)
let bounds = rect(0, 0, 800, 600)

let series = @[
  newChartSerie("Product A", @[
    newChartEntry(40.0f, "Q1"), newChartEntry(60.0f, "Q2"), newChartEntry(30.0f, "Q3")
  ], some(color(0.18f, 0.53f, 0.82f, 1.0f))),

  newChartSerie("Product B", @[
    newChartEntry(25.0f, "Q1"), newChartEntry(35.0f, "Q2"), newChartEntry(45.0f, "Q3")
  ], some(color(0.15f, 0.68f, 0.38f, 1.0f)))
]

var cfg = defaultChartConfig()
cfg.legendOption = SeriesLegendOption.Top

drawStackedBarChart(ctx, font, bounds, series, cfg)
img.writeFile("stacked_chart.png")
```

---

## Tutorial 3: Custom Themes & Dark Mode

You can easily style PixieCharts for dark mode by customizing `ChartConfig`:

```nim
import pixie
import pixiecharts

var cfg = defaultChartConfig()
cfg.backgroundColor = color(0.1f, 0.12f, 0.15f, 1.0f) # Dark slate background
cfg.labelColor = color(0.85f, 0.85f, 0.85f, 1.0f)       # Light text
cfg.yAxisTextColor = color(0.70f, 0.70f, 0.70f, 1.0f)
cfg.yAxisLinesColor = color(0.25f, 0.30f, 0.35f, 1.0f)  # Subtle dark gridlines
cfg.showYAxisLines = true
cfg.showYAxisText = true
```

---

## Tutorial 4: Creating Smooth Animation Frame Sequences

PixieCharts charts respond dynamically to `ChartConfig.animationProgress` (0.0 = completely hidden, 1.0 = fully rendered).

Use `renderAnimationFrames` to render 30-60 frames sweeping `animationProgress` with an easing curve:

```nim
import pixie
import pixiecharts

let font = readFont("Roboto-Regular.ttf")
let cfg = defaultChartConfig()

let candles = @[
  newCandleEntry("Mon", 100.0f, 115.0f, 95.0f, 110.0f),
  newCandleEntry("Tue", 110.0f, 112.0f, 102.0f, 105.0f),
  newCandleEntry("Wed", 105.0f, 125.0f, 104.0f, 122.0f)
]

# Render 30 frames using easeOutBack
let frames = renderAnimationFrames(
  width = 800, height = 600, frameCount = 30,
  drawProc = proc(ctx: Context, bounds: Rect, progress: float32) =
    var animCfg = cfg
    animCfg.animationProgress = progress
    ctx.fillStyle = color(1, 1, 1, 1)
    ctx.fillRect(0, 0, bounds.w, bounds.h)
    drawCandlestickChart(ctx, font, bounds, candles, animCfg),
  easing = easeOutBack
)

# Save PNG frames
discard saveAnimationFrames(frames, "frames_dir", "candlestick")
```

Convert the frame sequence into a GIF or MP4 video using `ffmpeg`:

```bash
ffmpeg -framerate 30 -i frames_dir/candlestick_%04d.png -c:v libx264 -pix_fmt yuv420p candlestick.mp4
```

---

## Tutorial 5: Building Executive KPI Dashboards

Combine multiple charts or use specialized dashboard cards like `drawKpiCardChart`:

```nim
import pixie
import pixiecharts

let font = readFont("Roboto-Regular.ttf")
let img = newImage(400, 250)
let ctx = newContext(img)
let bounds = rect(0, 0, 400, 250)

let kpiData = newKpiCardData(
  title = "Quarterly ARR",
  value = "$2,480,000",
  changeLabel = "+24.5% vs last Q",
  sparklineValues = @[12.0f, 15.0f, 14.0f, 18.0f, 22.0f, 28.0f, 34.0f],
  isPositiveChange = true
)

var cfg = defaultChartConfig()
drawKpiCardChart(ctx, font, bounds, kpiData, cfg)

img.writeFile("kpi_card.png")
```
