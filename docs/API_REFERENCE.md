# PixieCharts API Reference 📖

Complete type definitions, configuration options, helper procedures, and drawing signatures for all **63 chart modules** in `pixiecharts`.

---

## 1. Core Types & Configurations (`pixiecharts/types`)

### Enums

```nim
type
  Orientation* = enum
    Default
    Horizontal
    Vertical

  ValueLabelOption* = enum
    TopOfChart
    TopOfElement
    OverElement
    None

  SeriesLegendOption* = enum
    Top
    Bottom
    None

  YAxisPosition* = enum
    Left
    Right

  LineMode* = enum
    None
    Spline
    Straight

  PointMode* = enum
    None
    Circle
    Square

  LabelMode* = enum
    None
    LeftAndRight
    RightOnly

  GraphPosition* = enum
    AutoFill
    Center

  StepMode* = enum
    StepAfter
    StepBefore
    StepMiddle

  WaterfallKind* = enum
    Normal
    Subtotal
    Total
```

---

### `ChartConfig`

```nim
type
  ChartConfig* = object
    margin*: float32                # Margin space around plot area
    animationProgress*: float32     # Progress fraction (0.0 to 1.0)
    backgroundColor*: Color         # Background fill color
    labelColor*: Color              # Axis text label color
    labelTextSize*: float32         # Font size for labels
    valueLabelTextSize*: float32    # Font size for value labels
    serieLabelTextSize*: float32    # Font size for series legend text
    minValue*: Option[float32]      # Explicit y-axis min value override
    maxValue*: Option[float32]      # Explicit y-axis max value override

    labelOrientation*: Orientation
    valueLabelOrientation*: Orientation
    valueLabelOption*: ValueLabelOption
    legendOption*: SeriesLegendOption

    showYAxisText*: bool            # Render y-axis tick text labels
    showYAxisLines*: bool           # Render horizontal y-axis gridlines
    yAxisMaxTicks*: int             # Maximum number of y-axis tick marks
    yAxisPosition*: YAxisPosition   # Left or Right positioning
    yAxisTextColor*: Color
    yAxisLinesColor*: Color

    barAreaAlpha*: float32          # Opacity for bar background region
    minBarHeight*: float32          # Minimum height threshold for bars
    cornerRadius*: float32          # Corner rounding radius for bar rectangles

    pointSize*: float32             # Scatter dot size
    pointMode*: PointMode           # Circle or Square marker
    pointAreaAlpha*: float32
    lineSize*: float32              # Line stroke thickness
    lineMode*: LineMode             # Spline or Straight line mode
    lineAreaAlpha*: float32
    enableYFadeOutGradient*: bool

    holeRadius*: float32            # Donut chart hollow center fraction
    labelMode*: LabelMode
    graphPosition*: GraphPosition
    startAngle*: float32            # Gauge or donut starting angle
    gaugeAreaAlpha*: float32

    borderLineColor*: Color         # Radar or grid border line color
    borderLineSize*: float32
```

`defaultChartConfig()` returns standard configuration defaults.

---

## 2. Helper Utilities & Animation Exporter (`pixiecharts/helpers`)

### Easing Functions
* `easeLinear(t: float32): float32`
* `easeIn(t: float32): float32`
* `easeOut(t: float32): float32`
* `easeOutCubic(t: float32): float32`
* `easeInOutCubic(t: float32): float32`
* `easeOutQuad(t: float32): float32`
* `easeOutBack(t: float32): float32` (Overshoots for spring bounce)
* `easeOutElastic(t: float32): float32` (Springy oscillation)
* `easeOutCirc(t: float32): float32`

### Color & Stagger Utilities
* `lighten(c: Color, amount: float32): Color`
* `darken(c: Color, amount: float32): Color`
* `mixColor(a, b: Color, t: float32): Color`
* `staggerProgress(index, total: int, progress: float32, overlap: float32 = 0.6f): float32`
* `positionStagger(pos, total, progress: float32, overlap: float32 = 0.5f): float32`
* `drawSoftShadow(ctx: Context, shapePath: proc(p: Path), offset: Vec2, color: Color, layers: int = 6)`

### Animation Frame Exporter
```nim
proc renderAnimationFrames*(
  width, height: int,
  frameCount: int,
  drawProc: proc(ctx: Context, bounds: Rect, progress: float32) {.closure.},
  easing: proc(t: float32): float32 {.closure.} = easeOut
): seq[Image]

proc saveAnimationFrames*(
  frames: seq[Image],
  directory: string,
  baseName: string = "frame"
): seq[string]
```

---

## 3. Chart Drawing Procedures (All 63 Charts)

### 1. Bar & Column Charts
* `drawBarChart(ctx: Context, font: Font, bounds: Rect, entries: openArray[ChartEntry], config: ChartConfig = defaultChartConfig())`
* `drawHorizontalBarChart(ctx: Context, font: Font, bounds: Rect, entries: openArray[ChartEntry], config: ChartConfig = defaultChartConfig())`
* `drawStackedBarChart(ctx: Context, font: Font, bounds: Rect, series: openArray[ChartSerie], config: ChartConfig = defaultChartConfig())`
* `drawRangeBarChart(ctx: Context, font: Font, bounds: Rect, rangeBars: openArray[RangeBarEntry], config: ChartConfig = defaultChartConfig())`
* `drawWaterfallChart(ctx: Context, font: Font, bounds: Rect, entries: openArray[WaterfallEntry], config: ChartConfig = defaultChartConfig())`
* `drawParetoChart(ctx: Context, font: Font, bounds: Rect, entries: openArray[ParetoEntry], config: ChartConfig = defaultChartConfig())`
* `drawPyramidChart(ctx: Context, font: Font, bounds: Rect, cohorts: openArray[PyramidCohort], config: ChartConfig = defaultChartConfig())`

### 2. Line, Point & Trend Charts
* `drawLineChart(ctx: Context, font: Font, bounds: Rect, entries: openArray[ChartEntry], config: ChartConfig = defaultChartConfig())`
* `drawPointChart(ctx: Context, font: Font, bounds: Rect, entries: openArray[ChartEntry], config: ChartConfig = defaultChartConfig())`
* `drawStepLineChart(ctx: Context, font: Font, bounds: Rect, entries: openArray[ChartEntry], stepMode: StepMode = StepAfter, config: ChartConfig = defaultChartConfig())`
* `drawSparklineChart(ctx: Context, font: Font, bounds: Rect, data: SparklineData, config: ChartConfig = defaultChartConfig())`
* `drawSlopeChart(ctx: Context, font: Font, bounds: Rect, items: openArray[SlopeItem], config: ChartConfig = defaultChartConfig())`
* `drawBumpChart(ctx: Context, font: Font, bounds: Rect, data: BumpChartData, config: ChartConfig = defaultChartConfig())`

### 3. Radial, Donut & Gauges
* `drawDonutChart(ctx: Context, font: Font, bounds: Rect, entries: openArray[ChartEntry], config: ChartConfig = defaultChartConfig())`
* `drawPieChart(ctx: Context, font: Font, bounds: Rect, entries: openArray[ChartEntry], config: ChartConfig = defaultChartConfig())`
* `drawRadialGaugeChart(ctx: Context, font: Font, bounds: Rect, entries: openArray[ChartEntry], config: ChartConfig = defaultChartConfig())`
* `drawHalfRadialGaugeChart(ctx: Context, font: Font, bounds: Rect, entries: openArray[ChartEntry], config: ChartConfig = defaultChartConfig())`
* `drawRadialBarChart(ctx: Context, font: Font, bounds: Rect, rings: openArray[RadialBarRing], config: ChartConfig = defaultChartConfig())`
* `drawSpeedometerChart(ctx: Context, font: Font, bounds: Rect, data: SpeedometerData, config: ChartConfig = defaultChartConfig())`
* `drawSemiCircleMeter(ctx: Context, font: Font, bounds: Rect, data: SemiCircleMeterData, config: ChartConfig = defaultChartConfig())`
* `drawLiquidGauge(ctx: Context, font: Font, bounds: Rect, data: LiquidGaugeData, config: ChartConfig = defaultChartConfig())`

### 4. Radar & Polar
* `drawRadarChart(ctx: Context, font: Font, bounds: Rect, entries: openArray[ChartEntry], config: ChartConfig = defaultChartConfig())`
* `drawMultiRadarChart(ctx: Context, font: Font, bounds: Rect, data: MultiRadarData, config: ChartConfig = defaultChartConfig())`
* `drawPolarAreaChart(ctx: Context, font: Font, bounds: Rect, entries: openArray[ChartEntry], config: ChartConfig = defaultChartConfig())`
* `drawWindRoseChart(ctx: Context, font: Font, bounds: Rect, data: WindRoseData, config: ChartConfig = defaultChartConfig())`

### 5. Statistical & Distribution
* `drawBoxPlotChart(ctx: Context, font: Font, bounds: Rect, entries: openArray[BoxPlotEntry], config: ChartConfig = defaultChartConfig())`
* `drawViolinChart(ctx: Context, font: Font, bounds: Rect, entries: openArray[ViolinEntry], config: ChartConfig = defaultChartConfig())`
* `drawDotPlotChart(ctx: Context, font: Font, bounds: Rect, groups: openArray[DotPlotGroup], config: ChartConfig = defaultChartConfig())`
* `drawBubbleChart(ctx: Context, font: Font, bounds: Rect, bubbles: openArray[BubbleEntry], config: ChartConfig = defaultChartConfig())`
* `drawErrorBarChart(ctx: Context, font: Font, bounds: Rect, entries: openArray[ErrorBarEntry], config: ChartConfig = defaultChartConfig())`
* `drawRidgelineChart(ctx: Context, font: Font, bounds: Rect, series: openArray[RidgelineSeries], config: ChartConfig = defaultChartConfig())`
* `drawCandlestickChart(ctx: Context, font: Font, bounds: Rect, candles: openArray[CandleEntry], config: ChartConfig = defaultChartConfig())`

### 6. Flow, Network & Hierarchy
* `drawSankeyChart(ctx: Context, font: Font, bounds: Rect, data: SankeyData, config: ChartConfig = defaultChartConfig())`
* `drawChordChart(ctx: Context, font: Font, bounds: Rect, matrix: ChordMatrix, config: ChartConfig = defaultChartConfig())`
* `drawSunburstChart(ctx: Context, font: Font, bounds: Rect, root: SunburstNode, config: ChartConfig = defaultChartConfig())`
* `drawTreemapChart(ctx: Context, font: Font, bounds: Rect, items: openArray[TreemapItem], config: ChartConfig = defaultChartConfig())`
* `drawCirclePackingChart(ctx: Context, font: Font, bounds: Rect, items: openArray[PackedCircleItem], config: ChartConfig = defaultChartConfig())`
* `drawDendrogramChart(ctx: Context, font: Font, bounds: Rect, root: DendrogramNode, config: ChartConfig = defaultChartConfig())`
* `drawArcDiagramChart(ctx: Context, font: Font, bounds: Rect, data: ArcDiagramData, config: ChartConfig = defaultChartConfig())`
* `drawFunnelChart(ctx: Context, font: Font, bounds: Rect, entries: openArray[FunnelEntry], config: ChartConfig = defaultChartConfig())`
* `drawNetworkChart(ctx: Context, font: Font, bounds: Rect, data: NetworkGraphData, config: ChartConfig = defaultChartConfig())`
* `drawOrgChart(ctx: Context, font: Font, bounds: Rect, rootNode: OrgNode, config: ChartConfig = defaultChartConfig())`

### 7. Matrix, Spatial & Heatmap
* `drawHeatmapChart(ctx: Context, font: Font, bounds: Rect, data: HeatmapData, config: ChartConfig = defaultChartConfig())`
* `drawCalendarHeatmap(ctx: Context, font: Font, bounds: Rect, days: openArray[CalendarDay], config: ChartConfig = defaultChartConfig())`
* `drawHexbinChart(ctx: Context, font: Font, bounds: Rect, data: HexbinData, config: ChartConfig = defaultChartConfig())`
* `drawStackedAreaChart(ctx: Context, font: Font, bounds: Rect, series: openArray[ChartSerie], config: ChartConfig = defaultChartConfig())`
* `drawStreamgraphChart(ctx: Context, font: Font, bounds: Rect, series: openArray[StreamSeries], config: ChartConfig = defaultChartConfig())`
* `drawHorizonChart(ctx: Context, font: Font, bounds: Rect, series: openArray[HorizonSeries], config: ChartConfig = defaultChartConfig())`
* `drawMarimekkoChart(ctx: Context, font: Font, bounds: Rect, columns: openArray[MekkoColumn], config: ChartConfig = defaultChartConfig())`

### 8. Specialized Dashboard & Analytics
* `drawGanttChart(ctx: Context, font: Font, bounds: Rect, tasks: openArray[GanttTask], config: ChartConfig = defaultChartConfig())`
* `drawBulletChart(ctx: Context, font: Font, bounds: Rect, bullets: openArray[BulletEntry], config: ChartConfig = defaultChartConfig())`
* `drawDumbbellChart(ctx: Context, font: Font, bounds: Rect, entries: openArray[DumbbellEntry], config: ChartConfig = defaultChartConfig())`
* `drawTernaryChart(ctx: Context, font: Font, bounds: Rect, points: openArray[TernaryPoint], config: ChartConfig = defaultChartConfig())`
* `drawSlopeChart(ctx: Context, font: Font, bounds: Rect, items: openArray[SlopeItem], config: ChartConfig = defaultChartConfig())`
* `drawVenn2Chart(ctx: Context, font: Font, bounds: Rect, data: Venn2Data, config: ChartConfig = defaultChartConfig())`
* `drawVenn3Chart(ctx: Context, font: Font, bounds: Rect, data: Venn3Data, config: ChartConfig = defaultChartConfig())`
* `drawKpiCardChart(ctx: Context, font: Font, bounds: Rect, data: KpiCardData, config: ChartConfig = defaultChartConfig())`
* `drawWaffleChart(ctx: Context, font: Font, bounds: Rect, categories: openArray[WaffleCategory], config: ChartConfig = defaultChartConfig())`
* `drawLikertChart(ctx: Context, font: Font, bounds: Rect, responses: openArray[LikertResponse], config: ChartConfig = defaultChartConfig())`
* `drawQuadrantChart(ctx: Context, font: Font, bounds: Rect, data: QuadrantData, config: ChartConfig = defaultChartConfig())`
* `drawTimelineChart(ctx: Context, font: Font, bounds: Rect, events: openArray[TimelineEvent], config: ChartConfig = defaultChartConfig())`
* `drawWordCloudChart(ctx: Context, font: Font, bounds: Rect, items: openArray[WordCloudItem], config: ChartConfig = defaultChartConfig())`
* `drawParallelCoordsChart(ctx: Context, font: Font, bounds: Rect, dimensions: openArray[ParallelDimension], records: openArray[ParallelRecord], config: ChartConfig = defaultChartConfig())`
