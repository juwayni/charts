import std/options
import pixie

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

  ChartEntry* = object
    hasValue*: bool
    value*: float32
    label*: string
    valueLabel*: string
    color*: Color
    otherColor*: Color
    textColor*: Color
    valueLabelColor*: Color

  ChartSerie* = object
    name*: string
    color*: Option[Color]
    otherColor*: Option[Color]
    entries*: seq[ChartEntry]

  ChartConfig* = object
    # Layout & Base Metrics
    margin*: float32
    animationProgress*: float32
    backgroundColor*: Color
    labelColor*: Color
    labelTextSize*: float32
    valueLabelTextSize*: float32
    serieLabelTextSize*: float32
    minValue*: Option[float32]
    maxValue*: Option[float32]

    # Orientations & Placements
    labelOrientation*: Orientation
    valueLabelOrientation*: Orientation
    valueLabelOption*: ValueLabelOption
    legendOption*: SeriesLegendOption

    # Y-Axis Settings
    showYAxisText*: bool
    showYAxisLines*: bool
    yAxisMaxTicks*: int
    yAxisPosition*: YAxisPosition
    yAxisTextColor*: Color
    yAxisLinesColor*: Color

    # Bar Specifics
    barAreaAlpha*: float32
    minBarHeight*: float32
    cornerRadius*: float32

    # Point & Line Specifics
    pointSize*: float32
    pointMode*: PointMode
    pointAreaAlpha*: float32
    lineSize*: float32
    lineMode*: LineMode
    lineAreaAlpha*: float32
    enableYFadeOutGradient*: bool

    # Radial, Donut & Gauge Specifics
    holeRadius*: float32
    labelMode*: LabelMode
    graphPosition*: GraphPosition
    startAngle*: float32
    gaugeAreaAlpha*: float32

    # Radar Specifics
    borderLineColor*: Color
    borderLineSize*: float32

  # Candlestick / OHLC
  CandleEntry* = object
    dateLabel*: string
    open*: float32
    high*: float32
    low*: float32
    close*: float32
    volume*: float32

  # Box & Whisker
  BoxPlotEntry* = object
    label*: string
    minVal*: float32
    q1*: float32
    median*: float32
    q3*: float32
    maxVal*: float32
    outliers*: seq[float32]
    color*: Color

  # 2D Scatter / Bubble
  BubbleEntry* = object
    x*: float32
    y*: float32
    radius*: float32
    label*: string
    color*: Color

  # 2D Heatmap Matrix
  HeatmapData* = object
    rowLabels*: seq[string]
    colLabels*: seq[string]
    values*: seq[seq[float32]]
    minVal*: float32
    maxVal*: float32
    colorLow*: Color
    colorMid*: Color
    colorHigh*: Color

  # Funnel / Pipeline
  FunnelEntry* = object
    label*: string
    value*: float32
    valueLabel*: string
    color*: Color

  # Treemap Node
  TreemapItem* = object
    label*: string
    value*: float32
    color*: Color

  # Waterfall Chart
  WaterfallEntry* = object
    label*: string
    value*: float32
    kind*: WaterfallKind
    color*: Option[Color]

  # Bullet Chart
  BulletRange* = object
    label*: string
    value*: float32
    color*: Color

  BulletEntry* = object
    label*: string
    subtitle*: string
    actual*: float32
    target*: float32
    ranges*: seq[BulletRange]
    actualColor*: Color
    targetColor*: Color

  # Lollipop Chart
  LollipopEntry* = object
    label*: string
    value*: float32
    valueLabel*: string
    color*: Color
    stemColor*: Color

  # Sankey Flow Diagram
  SankeyNode* = object
    id*: string
    label*: string
    color*: Color

  SankeyLink* = object
    sourceId*: string
    targetId*: string
    value*: float32
    color*: Option[Color]

  SankeyData* = object
    stages*: seq[seq[SankeyNode]]
    links*: seq[SankeyLink]

  # Violin Plot
  ViolinEntry* = object
    label*: string
    densityY*: seq[float32]
    densityW*: seq[float32]
    minVal*: float32
    q1*: float32
    median*: float32
    q3*: float32
    maxVal*: float32
    color*: Color

  # Dumbbell / Cleveland Dot Plot
  DumbbellEntry* = object
    label*: string
    valA*: float32
    valB*: float32
    colorA*: Color
    colorB*: Color

  # Radial Activity Rings
  RadialBarRing* = object
    label*: string
    value*: float32
    maxValue*: float32
    color*: Color
    trackColor*: Option[Color]

  # Population Pyramid
  PyramidCohort* = object
    cohortLabel*: string
    leftValue*: float32
    rightValue*: float32

  # Speedometer / Analog Needle Gauge
  GaugeColorZone* = object
    startFraction*: float32
    endFraction*: float32
    color*: Color

  SpeedometerData* = object
    minVal*: float32
    maxVal*: float32
    currentVal*: float32
    unit*: string
    title*: string
    zones*: seq[GaugeColorZone]
    needleColor*: Color

  # Sunburst
  SunburstNode* = object
    name*: string
    value*: float32
    color*: Color
    children*: seq[SunburstNode]

  # Streamgraph
  StreamSeries* = object
    name*: string
    values*: seq[float32]
    color*: Color

  # Gantt
  GanttTask* = object
    label*: string
    startDay*: float32
    endDay*: float32
    progress*: float32
    color*: Color
    isMilestone*: bool

  # Chord
  ChordMatrix* = object
    names*: seq[string]
    matrix*: seq[seq[float32]]
    colors*: seq[Color]

  # Word Cloud
  WordCloudItem* = object
    text*: string
    weight*: float32
    color*: Color

  # Parallel Coordinates
  ParallelDimension* = object
    name*: string
    minVal*: float32
    maxVal*: float32

  ParallelRecord* = object
    name*: string
    values*: seq[float32]
    color*: Color

  # Ridgeline / Joyplot
  RidgelineSeries* = object
    name*: string
    values*: seq[float32]
    color*: Color

  # Circle Packing
  PackedCircleItem* = object
    label*: string
    value*: float32
    color*: Color

  # Marimekko / Mosaic
  MekkoSegment* = object
    name*: string
    value*: float32
    color*: Color

  MekkoColumn* = object
    name*: string
    segments*: seq[MekkoSegment]

  # Ternary Plot
  TernaryPoint* = object
    label*: string
    a*: float32
    b*: float32
    c*: float32
    color*: Color

  # Venn Diagram
  Venn2Data* = object
    labelA*: string
    labelB*: string
    labelAB*: string
    countA*: float32
    countB*: float32
    countAB*: float32
    colorA*: Color
    colorB*: Color

  Venn3Data* = object
    labelA*, labelB*, labelC*: string
    labelAB*, labelBC*, labelCA*, labelABC*: string
    countA*, countB*, countC*: float32
    countAB*, countBC*, countCA*, countABC*: float32
    colorA*, colorB*, colorC*: Color

  # KPI Scorecard Card
  KpiCardData* = object
    title*: string
    value*: string
    changeLabel*: string
    isPositiveChange*: bool
    sparklineValues*: seq[float32]
    cardBgColor*: Color
    accentColor*: Color

  # Multi-Series Radar
  MultiRadarSeries* = object
    name*: string
    values*: seq[float32]
    color*: Color

  MultiRadarData* = object
    axes*: seq[string]
    maxVal*: float32
    series*: seq[MultiRadarSeries]

  # Horizon Graph
  HorizonSeries* = object
    name*: string
    values*: seq[float32]
    positiveColor*: Color
    negativeColor*: Color

  # Arc Diagram
  ArcNode* = object
    id*: string
    label*: string
    color*: Color

  ArcLink* = object
    sourceId*: string
    targetId*: string
    weight*: float32
    color*: Option[Color]

  ArcDiagramData* = object
    nodes*: seq[ArcNode]
    links*: seq[ArcLink]

  # Waffle Matrix
  WaffleCategory* = object
    name*: string
    count*: int
    color*: Color

  # Beeswarm / Dot Plot
  DotPlotGroup* = object
    groupLabel*: string
    values*: seq[float32]
    color*: Color

  # Range Bar
  RangeBarEntry* = object
    label*: string
    minVal*: float32
    maxVal*: float32
    color*: Color

  # Hexbin
  HexPoint* = object
    x*: float32
    y*: float32

  HexbinData* = object
    points*: seq[HexPoint]
    hexRadius*: float32
    colorLow*: Color
    colorHigh*: Color

  # Slopegraph
  SlopeItem* = object
    label*: string
    startVal*: float32
    endVal*: float32
    color*: Option[Color]

  # Pareto Chart
  ParetoEntry* = object
    label*: string
    count*: float32
    color*: Color

  # Calendar Heatmap
  CalendarDay* = object
    dayIndex*: int
    weekIndex*: int
    value*: int

  # Liquid Fill Wave Gauge
  LiquidGaugeData* = object
    percentage*: float32
    waveHeight*: float32
    waveCount*: int
    fillColor*: Color
    borderColor*: Color
    textColor*: Color

  # Error Bar / Confidence Interval
  ErrorBarEntry* = object
    label*: string
    meanVal*: float32
    errorLow*: float32
    errorHigh*: float32
    color*: Color

  # Likert Scale Survey
  LikertResponse* = object
    question*: string
    counts*: array[5, float32]

  # Quadrant 2x2 Matrix
  QuadrantItem* = object
    label*: string
    x*: float32
    y*: float32
    size*: float32
    color*: Color

  QuadrantData* = object
    items*: seq[QuadrantItem]
    minX*, maxX*, minY*, maxY*: float32
    xLabel*, yLabel*: string
    quadLabels*: array[4, string]

  # Milestone Event Timeline
  TimelineEvent* = object
    dateLabel*: string
    title*: string
    color*: Color

  # Wind Rose / Directional Polar Column
  WindRoseSector* = object
    directionLabel*: string
    speedBands*: seq[float32]

  WindRoseData* = object
    sectors*: seq[WindRoseSector]
    bandColors*: seq[Color]
    bandLabels*: seq[string]

  # Dendrogram / Radial Tree
  DendrogramNode* = object
    name*: string
    color*: Color
    children*: seq[DendrogramNode]

  # Semi-Circle Modern Arch Meter
  SemiCircleMeterData* = object
    value*: float32
    maxVal*: float32
    label*: string
    unit*: string
    barColor*: Color
    trackColor*: Color

  # Bump Chart (Rank Over Time)
  BumpSeries* = object
    name*: string
    ranks*: seq[int]
    color*: Color

  BumpChartData* = object
    timeLabels*: seq[string]
    series*: seq[BumpSeries]

  # Compact Sparkline
  SparklineData* = object
    values*: seq[float32]
    lineColor*: Color
    fillColor*: Color
    showMinMax*: bool

  # Network / Node-Link Graph
  NetworkNode* = object
    id*: string
    label*: string
    x*: float32
    y*: float32
    radius*: float32
    color*: Color

  NetworkEdge* = object
    sourceId*: string
    targetId*: string
    weight*: float32
    color*: Option[Color]

  NetworkGraphData* = object
    nodes*: seq[NetworkNode]
    edges*: seq[NetworkEdge]

  # Hierarchical Org Chart
  OrgNode* = object
    name*: string
    title*: string
    color*: Color
    children*: seq[OrgNode]

# --- Constructors ---

proc newChartEntry*(
  value: float32,
  label: string = "",
  valueLabel: string = "",
  color: Color = color(0, 0, 0, 1),
  textColor: Color = color(0.5, 0.5, 0.5, 1),
  valueLabelColor: Color = color(0, 0, 0, 1),
  otherColor: Color = color(0, 0, 0, 0)
): ChartEntry =
  ChartEntry(
    hasValue: true,
    value: value,
    label: label,
    valueLabel: valueLabel,
    color: color,
    textColor: textColor,
    valueLabelColor: valueLabelColor,
    otherColor: otherColor
  )

proc newNullEntry*(
  label: string = "",
  textColor: Color = color(0.5, 0.5, 0.5, 1)
): ChartEntry =
  ChartEntry(
    hasValue: false,
    value: 0.0f,
    label: label,
    valueLabel: "",
    color: color(0, 0, 0, 0),
    textColor: textColor,
    valueLabelColor: color(0, 0, 0, 0),
    otherColor: color(0, 0, 0, 0)
  )

proc newChartSerie*(
  name: string,
  entries: seq[ChartEntry],
  color: Option[Color] = none(Color)
): ChartSerie =
  ChartSerie(
    name: name,
    entries: entries,
    color: color,
    otherColor: none(Color)
  )

proc defaultChartConfig*(): ChartConfig =
  ChartConfig(
    margin: 20.0f,
    animationProgress: 1.0f,
    backgroundColor: color(1, 1, 1, 1),
    labelColor: color(0.5, 0.5, 0.5, 1),
    labelTextSize: 16.0f,
    valueLabelTextSize: 16.0f,
    serieLabelTextSize: 16.0f,
    minValue: none(float32),
    maxValue: none(float32),
    labelOrientation: Orientation.Vertical,
    valueLabelOrientation: Orientation.Vertical,
    valueLabelOption: ValueLabelOption.TopOfChart,
    legendOption: SeriesLegendOption.None,
    showYAxisText: false,
    showYAxisLines: false,
    yAxisMaxTicks: 5,
    yAxisPosition: YAxisPosition.Right,
    yAxisTextColor: color(0, 0, 0, 1),
    yAxisLinesColor: color(0, 0, 0, 0.3137f),
    barAreaAlpha: 32.0f / 255.0f,
    minBarHeight: 4.0f,
    cornerRadius: 0.0f,
    pointSize: 14.0f,
    pointMode: PointMode.Circle,
    pointAreaAlpha: 100.0f / 255.0f,
    lineSize: 3.0f,
    lineMode: LineMode.Spline,
    lineAreaAlpha: 32.0f / 255.0f,
    enableYFadeOutGradient: false,
    holeRadius: 0.5f,
    labelMode: LabelMode.LeftAndRight,
    graphPosition: GraphPosition.AutoFill,
    startAngle: -90.0f,
    gaugeAreaAlpha: 52.0f / 255.0f,
    borderLineColor: color(0.83f, 0.83f, 0.83f, 0.43f),
    borderLineSize: 2.0f
  )

proc newCandleEntry*(
  dateLabel: string,
  open, high, low, close: float32,
  volume: float32 = 0.0f
): CandleEntry =
  CandleEntry(
    dateLabel: dateLabel,
    open: open,
    high: high,
    low: low,
    close: close,
    volume: volume
  )

proc newBoxPlotEntry*(
  label: string,
  minVal, q1, median, q3, maxVal: float32,
  outliers: seq[float32] = @[],
  color: Color = color(0.18f, 0.53f, 0.82f, 1.0f)
): BoxPlotEntry =
  BoxPlotEntry(
    label: label,
    minVal: minVal,
    q1: q1,
    median: median,
    q3: q3,
    maxVal: maxVal,
    outliers: outliers,
    color: color
  )

proc newBubbleEntry*(
  x, y, radius: float32,
  label: string = "",
  color: Color = color(0.18f, 0.53f, 0.82f, 0.75f)
): BubbleEntry =
  BubbleEntry(x: x, y: y, radius: radius, label: label, color: color)

proc newFunnelEntry*(
  label: string,
  value: float32,
  valueLabel: string = "",
  color: Color = color(0.18f, 0.53f, 0.82f, 1.0f)
): FunnelEntry =
  FunnelEntry(label: label, value: value, valueLabel: valueLabel, color: color)

proc newTreemapItem*(
  label: string,
  value: float32,
  color: Color
): TreemapItem =
  TreemapItem(label: label, value: value, color: color)

proc newWaterfallEntry*(
  label: string,
  value: float32,
  kind: WaterfallKind = Normal,
  color: Option[Color] = none(Color)
): WaterfallEntry =
  WaterfallEntry(label: label, value: value, kind: kind, color: color)

proc newBulletEntry*(
  label, subtitle: string,
  actual, target: float32,
  ranges: seq[BulletRange],
  actualColor: Color = color(0.12f, 0.12f, 0.12f, 1.0f),
  targetColor: Color = color(0.91f, 0.30f, 0.24f, 1.0f)
): BulletEntry =
  BulletEntry(
    label: label,
    subtitle: subtitle,
    actual: actual,
    target: target,
    ranges: ranges,
    actualColor: actualColor,
    targetColor: targetColor
  )

proc newLollipopEntry*(
  label: string,
  value: float32,
  valueLabel: string = "",
  color: Color = color(0.18f, 0.53f, 0.82f, 1.0f),
  stemColor: Color = color(0.70f, 0.70f, 0.70f, 1.0f)
): LollipopEntry =
  LollipopEntry(
    label: label,
    value: value,
    valueLabel: valueLabel,
    color: color,
    stemColor: stemColor
  )

proc newDumbbellEntry*(
  label: string,
  valA, valB: float32,
  colorA: Color = color(0.18f, 0.53f, 0.82f, 1.0f),
  colorB: Color = color(0.91f, 0.30f, 0.24f, 1.0f)
): DumbbellEntry =
  DumbbellEntry(label: label, valA: valA, valB: valB, colorA: colorA, colorB: colorB)

proc newRadialBarRing*(
  label: string,
  value, maxValue: float32,
  color: Color,
  trackColor: Option[Color] = none(Color)
): RadialBarRing =
  RadialBarRing(
    label: label,
    value: value,
    maxValue: maxValue,
    color: color,
    trackColor: trackColor
  )

proc newPyramidCohort*(
  label: string,
  leftVal, rightVal: float32
): PyramidCohort =
  PyramidCohort(cohortLabel: label, leftValue: leftVal, rightValue: rightVal)

proc newSunburstNode*(
  name: string,
  value: float32 = 0.0f,
  color: Color = color(0, 0, 0, 1),
  children: seq[SunburstNode] = @[]
): SunburstNode =
  SunburstNode(name: name, value: value, color: color, children: children)

proc newGanttTask*(
  label: string,
  startDay, endDay: float32,
  progress: float32 = 1.0f,
  color: Color = color(0.18f, 0.53f, 0.82f, 1.0f),
  isMilestone: bool = false
): GanttTask =
  GanttTask(
    label: label,
    startDay: startDay,
    endDay: endDay,
    progress: progress,
    color: color,
    isMilestone: isMilestone
  )

proc newTernaryPoint*(
  label: string,
  a, b, c: float32,
  color: Color = color(0.18f, 0.53f, 0.82f, 1.0f)
): TernaryPoint =
  TernaryPoint(label: label, a: a, b: b, c: c, color: color)

proc newVenn2Data*(
  labelA, labelB, labelAB: string,
  countA, countB, countAB: float32,
  colorA: Color = color(0.18f, 0.53f, 0.82f, 1.0f),
  colorB: Color = color(0.91f, 0.30f, 0.24f, 1.0f)
): Venn2Data =
  Venn2Data(
    labelA: labelA, labelB: labelB, labelAB: labelAB,
    countA: countA, countB: countB, countAB: countAB,
    colorA: colorA, colorB: colorB
  )

proc newKpiCardData*(
  title, value, changeLabel: string,
  sparklineValues: seq[float32],
  isPositiveChange: bool = true,
  accentColor: Color = color(0.15f, 0.68f, 0.38f, 1.0f),
  cardBgColor: Color = color(1, 1, 1, 1)
): KpiCardData =
  KpiCardData(
    title: title, value: value, changeLabel: changeLabel,
    isPositiveChange: isPositiveChange, sparklineValues: sparklineValues,
    cardBgColor: cardBgColor, accentColor: accentColor
  )

proc newRangeBarEntry*(
  label: string,
  minVal, maxVal: float32,
  color: Color = color(0.18f, 0.53f, 0.82f, 1.0f)
): RangeBarEntry =
  RangeBarEntry(label: label, minVal: minVal, maxVal: maxVal, color: color)

proc newSlopeItem*(
  label: string,
  startVal, endVal: float32,
  color: Option[Color] = none(Color)
): SlopeItem =
  SlopeItem(label: label, startVal: startVal, endVal: endVal, color: color)

proc newParetoEntry*(
  label: string,
  count: float32,
  color: Color = color(0.18f, 0.53f, 0.82f, 1.0f)
): ParetoEntry =
  ParetoEntry(label: label, count: count, color: color)

proc newErrorBarEntry*(
  label: string,
  meanVal, errorLow, errorHigh: float32,
  color: Color = color(0.18f, 0.53f, 0.82f, 1.0f)
): ErrorBarEntry =
  ErrorBarEntry(label: label, meanVal: meanVal, errorLow: errorLow, errorHigh: errorHigh, color: color)

proc newQuadrantItem*(
  label: string,
  x, y: float32,
  size: float32 = 8.0f,
  color: Color = color(0.18f, 0.53f, 0.82f, 1.0f)
): QuadrantItem =
  QuadrantItem(label: label, x: x, y: y, size: size, color: color)

proc newTimelineEvent*(
  dateLabel, title: string,
  color: Color = color(0.18f, 0.53f, 0.82f, 1.0f)
): TimelineEvent =
  TimelineEvent(dateLabel: dateLabel, title: title, color: color)

proc newDendrogramNode*(
  name: string,
  color: Color = color(0.18f, 0.53f, 0.82f, 1.0f),
  children: seq[DendrogramNode] = @[]
): DendrogramNode =
  DendrogramNode(name: name, color: color, children: children)

proc newBumpSeries*(
  name: string,
  ranks: seq[int],
  color: Color = color(0.18f, 0.53f, 0.82f, 1.0f)
): BumpSeries =
  BumpSeries(name: name, ranks: ranks, color: color)

proc newSparklineData*(
  values: seq[float32],
  lineColor: Color = color(0.18f, 0.53f, 0.82f, 1.0f),
  fillColor: Color = color(0.18f, 0.53f, 0.82f, 0.2f),
  showMinMax: bool = true
): SparklineData =
  SparklineData(values: values, lineColor: lineColor, fillColor: fillColor, showMinMax: showMinMax)

proc newNetworkNode*(
  id, label: string,
  x, y: float32,
  radius: float32 = 18.0f,
  color: Color = color(0.18f, 0.53f, 0.82f, 1.0f)
): NetworkNode =
  NetworkNode(id: id, label: label, x: x, y: y, radius: radius, color: color)

proc newNetworkEdge*(
  sourceId, targetId: string,
  weight: float32 = 2.0f,
  color: Option[Color] = none(Color)
): NetworkEdge =
  NetworkEdge(sourceId: sourceId, targetId: targetId, weight: weight, color: color)

proc newOrgNode*(
  name, title: string,
  color: Color = color(0.18f, 0.53f, 0.82f, 1.0f),
  children: seq[OrgNode] = @[]
): OrgNode =
  OrgNode(name: name, title: title, color: color, children: children)
