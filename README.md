# PixieCharts 📊✨

A feature-rich, high-performance, **Pixie-based** Nim visualization library for rendering **63+ static and animated charts**, diagrams, gauges, graphs, and statistical plots.

Built directly on top of [Pixie](https://github.com/treeform/pixie), **PixieCharts** provides pixel-perfect resolution-independent vector rendering, smooth custom easing animations, automatic nice-scale calculations, soft shadow effects, and sequence frame exports for video or GIF generation.

---

## 🚀 Key Features

* **63+ Chart Types**: From classic bar, line, and pie charts to complex Sankey diagrams, Chord matrices, Sunbursts, Ridgelines, Violin plots, Bump charts, and Org charts.
* **Driven by Easing Animations**: Every chart supports smooth, customizable animation sweeping via `animationProgress` (0.0 to 1.0) with built-in easings (`easeOutBack`, `easeOutElastic`, `easeInOutCubic`, etc.).
* **Animation Frame Exporter**: Built-in `renderAnimationFrames` and `saveAnimationFrames` helpers to render frame sequences into PNGs ready for `ffmpeg` conversion to MP4 or GIF.
* **Auto Nice-Scale Axis Formatting**: Intelligent tick calculation and label sizing without fixed padding hacks.
* **Zero C Dynamic Dependencies**: Powered entirely by Pixie and pure Nim packages (`chroma`, `vmath`, `bumpy`).

---

## 📦 Installation

Add `pixiecharts` to your `.nimble` file or install via Nimble:

```bash
nimble install pixiecharts
```

*Prerequisite dependencies (automatically resolved by Nimble):*
* `pixie >= 5.0.0`
* `chroma >= 1.0.0`

---

## 🏁 Quickstart

Creating a chart with `pixiecharts` requires just a few lines of Nim code:

```nim
import pixie
import pixiecharts

proc generateBarChart() =
  # 1. Prepare font and canvas
  let font = readFont("Roboto-Regular.ttf")
  let img = newImage(800, 600)
  let ctx = newContext(img)
  let bounds = rect(0, 0, 800, 600)

  # 2. Define data entries
  let entries = @[
    newChartEntry(142.0f, "Q1", "142k", color(0.18f, 0.53f, 0.82f, 1.0f)),
    newChartEntry(210.0f, "Q2", "210k", color(0.15f, 0.68f, 0.38f, 1.0f)),
    newChartEntry(88.0f,  "Q3", "88k",  color(0.95f, 0.77f, 0.06f, 1.0f)),
    newChartEntry(315.0f, "Q4", "315k", color(0.91f, 0.30f, 0.24f, 1.0f))
  ]

  # 3. Configure chart options
  var cfg = defaultChartConfig()
  cfg.margin = 25.0f
  cfg.showYAxisText = true
  cfg.showYAxisLines = true

  # 4. Draw chart
  drawBarChart(ctx, font, bounds, entries, cfg)

  # 5. Save output image
  img.writeFile("barchart.png")

when isMainModule:
  generateBarChart()
```

---

## 🎬 Generating Animated Sequences (GIF / MP4)

PixieCharts makes rendering animated frame sequences trivial:

```nim
import pixie
import pixiecharts

let font = readFont("Roboto-Regular.ttf")
let cfg = defaultChartConfig()

let entries = @[
  newChartEntry(100.0f, "Jan"),
  newChartEntry(250.0f, "Feb"),
  newChartEntry(180.0f, "Mar")
]

# Render 45 animation frames with an easeOutBack spring bounce
let frames = renderAnimationFrames(
  width = 800, height = 600, frameCount = 45,
  drawProc = proc(ctx: Context, bounds: Rect, progress: float32) =
    var animCfg = cfg
    animCfg.animationProgress = progress
    ctx.fillStyle = color(1, 1, 1, 1)
    ctx.fillRect(0, 0, bounds.w, bounds.h)
    drawBarChart(ctx, font, bounds, entries, animCfg),
  easing = easeOutBack
)

# Save frames as frame_0000.png, frame_0001.png, ...
discard saveAnimationFrames(frames, "output_gallery", "frame")
```

Convert the frame sequence into a smooth MP4 or GIF using `ffmpeg`:

```bash
ffmpeg -framerate 30 -i output_gallery/frame_%04d.png -vf "fps=30" chart_animation.gif
```

---

## 📊 Comprehensive Chart Catalog (63 Charts)

### 1. Bar & Column Charts
* **Bar Chart** (`drawBarChart`): Vertical bar chart with depth shading, rounded corners, drop shadows, and value labels.
* **Horizontal Bar Chart** (`drawHorizontalBarChart`): Left-to-right horizontal bar chart.
* **Stacked Bar Chart** (`drawStackedBarChart`): Multi-series stacked vertical bars.
* **Range Bar Chart** (`drawRangeBarChart`): Floating horizontal range bars defined by min/max values.
* **Waterfall Chart** (`drawWaterfallChart`): Financial bridge chart supporting normal, subtotal, and total bars.
* **Pareto Chart** (`drawParetoChart`): Dual-axis bar chart sorted by frequency with cumulative percentage line.
* **Population Pyramid** (`drawPyramidChart`): Back-to-back demographic population chart.

### 2. Line, Point & Trend Charts
* **Line Chart** (`drawLineChart`): Smooth spline or straight line chart with soft fill gradients and data dots.
* **Point / Scatter Chart** (`drawPointChart`): Point scatter plot with configurable shape markers.
* **Step Line Chart** (`drawStepLineChart`): Discrete step line chart (`StepBefore`, `StepMiddle`, `StepAfter`).
* **Sparkline Chart** (`drawSparklineChart`): Micro-trend line graph with area fill and min/max/latest point indicators.
* **Slopegraph** (`drawSlopeChart`): Comparison plot connecting start and end rank values.
* **Bump Chart** (`drawBumpChart`): Smooth bezier rank tracker over discrete time steps.

### 3. Radial, Circular & Gauges
* **Donut Chart** (`drawDonutChart`): Hollow arc chart with slice labels.
* **Pie Chart** (`drawPieChart`): Classic circular proportion pie chart.
* **Radial Gauge** (`drawRadialGaugeChart`): Full circular gauge meter.
* **Half Radial Gauge** (`drawHalfRadialGaugeChart`): 180-degree arch gauge.
* **Radial Bar Chart** (`drawRadialBarChart`): Concentric activity ring meter.
* **Speedometer Chart** (`drawSpeedometerChart`): Analog gauge with color zones, tick marks, and needle indicator.
* **Semicircle Meter** (`drawSemiCircleMeter`): Modern semi-circular arch status meter.
* **Liquid Fill Gauge** (`drawLiquidGauge`): Animated liquid wave percentage gauge inside a circular ring.

### 4. Radar & Polar Charts
* **Radar Chart** (`drawRadarChart`): Polygonal spider radar chart.
* **Multi Radar Chart** (`drawMultiRadarChart`): Multi-series radar chart overlay.
* **Polar Area Chart** (`drawPolarAreaChart`): Coxcomb polar area diagram with variable radius sectors.
* **Wind Rose Chart** (`drawWindRoseChart`): Directional wind rose polar stacked column diagram.

### 5. Distribution & Statistical Charts
* **BoxPlot Chart** (`drawBoxPlotChart`): Tukey box and whisker plot with median, Q1/Q3, min/max, and outlier dots.
* **Violin Plot** (`drawViolinChart`): Kernel density distribution plot with embedded boxplot metrics.
* **Dot Plot / Beeswarm** (`drawDotPlotChart`): Grouped Cleveland dot plot.
* **Bubble Chart** (`drawBubbleChart`): 3D data scatter plot mapping X, Y, and Bubble Radius.
* **Error Bar Chart** (`drawErrorBarChart`): Mean values with confidence interval upper/lower error bounds.
* **Ridgeline / Joyplot** (`drawRidgelineChart`): Overlapping density distribution profiles over time or categories.

### 6. Hierarchical, Flow & Network Diagrams
* **Sankey Flow Diagram** (`drawSankeyChart`): Multi-stage weighted flow network with bezier ribbons.
* **Chord Diagram** (`drawChordChart`): Circular matrix relationship chart with translucent chord ribbons.
* **Sunburst Chart** (`drawSunburstChart`): Multi-level radial tree partition diagram.
* **Treemap Chart** (`drawTreemapChart`): Rectangular squarified area partition tree.
* **Circle Packing Chart** (`drawCirclePackingChart`): Nested circle packaging layout.
* **Dendrogram Chart** (`drawDendrogramChart`): Tree hierarchy layout with branch nodes.
* **Arc Diagram Chart** (`drawArcDiagramChart`): Linear node layout with arc connections.
* **Conversion Funnel** (`drawFunnelChart`): Funnel conversion chart.
* **Network Graph** (`drawNetworkChart`): Node-link diagram with weighted edge links and node cards.
* **Org Chart** (`drawOrgChart`): Hierarchical tree organizational structure with cards and orthogonal connectors.

### 7. Matrix, Heatmap & Area Charts
* **Heatmap Chart** (`drawHeatmapChart`): 2D color gradient intensity matrix with cell labels.
* **Calendar Heatmap** (`drawCalendarHeatmap`): GitHub-style 52-week calendar grid heatmap.
* **Hexbin Chart** (`drawHexbinChart`): 2D spatial point density hexbin plot.
* **Stacked Area Chart** (`drawStackedAreaChart`): Multi-series stacked area chart.
* **Streamgraph** (`drawStreamgraphChart`): Organic baseline-centered stream flow area chart.
* **Horizon Graph** (`drawHorizonChart`): Compact band-folded positive/negative trend graph.
* **Marimekko / Mosaic** (`drawMarimekkoChart`): Variable-width column stacked segment chart.

### 8. Specialized & Dashboard Cards
* **Gantt Chart** (`drawGanttChart`): Project schedule timeline with progress fill and milestone markers.
* **Bullet Graph** (`drawBulletChart`): Metric comparison against target line and qualitative range bands.
* **Dumbbell Plot** (`drawDumbbellChart`): Connected dot plot comparing two values per category.
* **Ternary Plot** (`drawTernaryChart`): Triangular coordinate system plot for three normalized variables.
* **Venn 2-Set Diagram** (`drawVenn2Chart`): Two-circle overlapping set intersection chart.
* **Venn 3-Set Diagram** (`drawVenn3Chart`): Three-circle overlapping set intersection chart.
* **KPI Scorecard Card** (`drawKpiCardChart`): Executive metric card with big figure, change badge, and sparkline trend.
* **Waffle Matrix Chart** (`drawWaffleChart`): 10x10 categorical percentage grid matrix.
* **Likert Scale Survey** (`drawLikertChart`): Diverging survey sentiment response bar chart.
* **Quadrant 2x2 Matrix** (`drawQuadrantChart`): 2x2 decision matrix bubble plot.
* **Milestone Timeline** (`drawTimelineEvent`): Chronological milestone event timeline.
* **Word Cloud** (`drawWordCloudChart`): Text frequency tag cloud layout.
* **Parallel Coordinates** (`drawParallelCoordsChart`): Multi-dimensional parallel axis record plot.

---

## 🛠️ Configuration (`ChartConfig`)

All charts accept an optional `ChartConfig` object to customize styling:

```nim
type
  ChartConfig* = object
    margin*: float32                # Margin padding around chart edges
    animationProgress*: float32     # Current animation progress (0.0 .. 1.0)
    backgroundColor*: Color         # Background fill color
    labelColor*: Color              # Axis and label text color
    labelTextSize*: float32         # Font size for category labels
    valueLabelTextSize*: float32    # Font size for numeric value labels
    showYAxisText*: bool            # Toggle Y-axis tick text
    showYAxisLines*: bool           # Toggle horizontal Y-axis grid lines
    yAxisMaxTicks*: int             # Maximum number of Y-axis ticks
    yAxisPosition*: YAxisPosition   # Left or Right Y-axis position
    barAreaAlpha*: float32          # Opacity for bar fills
    cornerRadius*: float32          # Corner radius for bars and boxes
    lineSize*: float32              # Line stroke thickness
    pointSize*: float32             # Marker dot diameter
    # ... and more
```

Use `defaultChartConfig()` to get standard defaults.

---

## 📚 Detailed Documentation

* **[API Reference](docs/API_REFERENCE.md)**: Full signatures, type definitions, and constructor functions.
* **[Tutorial Guide](docs/TUTORIAL.md)**: Comprehensive step-by-step tutorial covering customized styling, multi-series data, and video exports.

---

## 📄 License

MIT License. Free for open-source and commercial use.
