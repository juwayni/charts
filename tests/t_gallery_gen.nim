import std/os
import std/options
import pixie
import pixiecharts

proc renderAndSave(name: string, drawProc: proc(ctx: Context, font: Font, bounds: Rect)) =
  let font = readFont("Roboto-Regular.ttf")
  let img = newImage(800, 600)
  let ctx = newContext(img)
  let bounds = rect(0, 0, 800, 600)
  drawProc(ctx, font, bounds)
  createDir("output")
  createDir("output_gallery")
  img.writeFile("output/chart_" & name & ".png")
  img.writeFile("output_gallery/chart_" & name & ".png")
  echo "Generated: output/chart_" & name & ".png and output_gallery/chart_" & name & ".png"

proc main() =
  let cfg = defaultChartConfig()

  let entries = @[
    newChartEntry(142.0f, "Q1", "142k", color(0.18f, 0.53f, 0.82f, 1.0f)),
    newChartEntry(210.0f, "Q2", "210k", color(0.15f, 0.68f, 0.38f, 1.0f)),
    newChartEntry(88.0f,  "Q3", "88k",  color(0.95f, 0.77f, 0.06f, 1.0f)),
    newChartEntry(315.0f, "Q4", "315k", color(0.91f, 0.30f, 0.24f, 1.0f))
  ]

  let series = @[
    newChartSerie("Product A", @[newChartEntry(40.0f, "Q1"), newChartEntry(60.0f, "Q2"), newChartEntry(30.0f, "Q3")], some(color(0.18f, 0.53f, 0.82f, 1.0f))),
    newChartSerie("Product B", @[newChartEntry(25.0f, "Q1"), newChartEntry(35.0f, "Q2"), newChartEntry(45.0f, "Q3")], some(color(0.15f, 0.68f, 0.38f, 1.0f)))
  ]

  # 1. Bar Chart
  renderAndSave("barchart", proc(ctx: Context, font: Font, b: Rect) =
    drawBarChart(ctx, font, b, entries, cfg)
  )

  # 2. Point Chart
  renderAndSave("pointchart", proc(ctx: Context, font: Font, b: Rect) =
    drawPointChart(ctx, font, b, entries, cfg)
  )

  # 3. Line Chart
  renderAndSave("linechart", proc(ctx: Context, font: Font, b: Rect) =
    drawLineChart(ctx, font, b, entries, cfg)
  )

  # 4. Horizontal Bar Chart
  renderAndSave("hbar_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawHorizontalBarChart(ctx, font, b, entries, cfg)
  )

  # 5. Stacked Bar Chart
  renderAndSave("stackedbar_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawStackedBarChart(ctx, font, b, series, cfg)
  )

  # 6. Stacked Area Chart
  renderAndSave("stackedarea_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawStackedAreaChart(ctx, font, b, series, cfg)
  )

  # 7. Step Line Chart
  renderAndSave("stepline_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawStepLineChart(ctx, font, b, entries, config = cfg)
  )

  # 8. Lollipop Chart
  let lollipops = @[
    newLollipopEntry("A", 80.0f),
    newLollipopEntry("B", 120.0f),
    newLollipopEntry("C", 45.0f)
  ]
  renderAndSave("lollipop_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawLollipopChart(ctx, font, b, lollipops, cfg)
  )

  # 9. Range Bar Chart
  let rangeBars = @[
    newRangeBarEntry("P1", 20.0f, 80.0f),
    newRangeBarEntry("P2", 40.0f, 100.0f)
  ]
  renderAndSave("rangebar_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawRangeBarChart(ctx, font, b, rangeBars, cfg)
  )

  # 10. Donut Chart
  renderAndSave("donutchart", proc(ctx: Context, font: Font, b: Rect) =
    drawDonutChart(ctx, font, b, entries, cfg)
  )

  # 11. Pie Chart
  renderAndSave("piechart", proc(ctx: Context, font: Font, b: Rect) =
    drawPieChart(ctx, font, b, entries, cfg)
  )

  # 12. Radial Gauge
  renderAndSave("radial_gauge", proc(ctx: Context, font: Font, b: Rect) =
    drawRadialGaugeChart(ctx, font, b, entries, cfg)
  )

  # 13. Half Radial Gauge
  renderAndSave("half_radial_gauge", proc(ctx: Context, font: Font, b: Rect) =
    drawHalfRadialGaugeChart(ctx, font, b, entries, cfg)
  )

  # 14. Radar Chart
  renderAndSave("radarchart", proc(ctx: Context, font: Font, b: Rect) =
    drawRadarChart(ctx, font, b, entries, cfg)
  )

  # 15. Multi Radar Chart
  let multiRadar = MultiRadarData(
    axes: @["Speed", "Power", "Durability", "Agility", "Safety"],
    maxVal: 100.0f,
    series: @[
      MultiRadarSeries(name: "Model A", values: @[80.0f, 90.0f, 70.0f, 85.0f, 95.0f], color: color(0.18f, 0.53f, 0.82f, 0.7f)),
      MultiRadarSeries(name: "Model B", values: @[65.0f, 75.0f, 85.0f, 90.0f, 80.0f], color: color(0.91f, 0.30f, 0.24f, 0.7f))
    ]
  )
  renderAndSave("multiradar_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawMultiRadarChart(ctx, font, b, multiRadar, cfg)
  )

  # 16. Polar Area Chart
  renderAndSave("polararea_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawPolarAreaChart(ctx, font, b, entries, cfg)
  )

  # 17. Wind Rose Chart
  let windRose = WindRoseData(
    sectors: @[
      WindRoseSector(directionLabel: "N", speedBands: @[10.0f, 20.0f, 15.0f]),
      WindRoseSector(directionLabel: "NE", speedBands: @[15.0f, 10.0f, 5.0f]),
      WindRoseSector(directionLabel: "E", speedBands: @[5.0f, 25.0f, 20.0f]),
      WindRoseSector(directionLabel: "SE", speedBands: @[12.0f, 18.0f, 10.0f]),
      WindRoseSector(directionLabel: "S", speedBands: @[8.0f, 12.0f, 15.0f]),
      WindRoseSector(directionLabel: "SW", speedBands: @[20.0f, 15.0f, 10.0f]),
      WindRoseSector(directionLabel: "W", speedBands: @[18.0f, 22.0f, 8.0f]),
      WindRoseSector(directionLabel: "NW", speedBands: @[14.0f, 16.0f, 12.0f])
    ],
    bandColors: @[color(0.18f, 0.53f, 0.82f, 1.0f), color(0.15f, 0.68f, 0.38f, 1.0f), color(0.91f, 0.30f, 0.24f, 1.0f)],
    bandLabels: @["0-10 mph", "10-20 mph", "20+ mph"]
  )
  renderAndSave("windrose_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawWindRoseChart(ctx, font, b, windRose, cfg)
  )

  # 18. Radial Bar Chart
  let radialRings = @[
    newRadialBarRing("Move", 450.0f, 600.0f, color(0.91f, 0.30f, 0.24f, 1.0f)),
    newRadialBarRing("Exercise", 35.0f, 30.0f, color(0.15f, 0.68f, 0.38f, 1.0f)),
    newRadialBarRing("Stand", 10.0f, 12.0f, color(0.18f, 0.53f, 0.82f, 1.0f))
  ]
  renderAndSave("radialbar_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawRadialBarChart(ctx, font, b, radialRings, cfg)
  )

  # 19. Speedometer Chart
  let speedometer = SpeedometerData(
    minVal: 0.0f, maxVal: 240.0f, currentVal: 120.0f,
    unit: "km/h", title: "Speed",
    zones: @[
      GaugeColorZone(startFraction: 0.0f, endFraction: 0.5f, color: color(0.15f, 0.68f, 0.38f, 1.0f)),
      GaugeColorZone(startFraction: 0.5f, endFraction: 0.8f, color: color(0.95f, 0.77f, 0.06f, 1.0f)),
      GaugeColorZone(startFraction: 0.8f, endFraction: 1.0f, color: color(0.91f, 0.30f, 0.24f, 1.0f))
    ],
    needleColor: color(0.1f, 0.1f, 0.1f, 1.0f)
  )
  renderAndSave("speedometer_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawSpeedometerChart(ctx, font, b, speedometer, cfg)
  )

  # 20. Semicircle Meter
  let semiMeter = SemiCircleMeterData(
    value: 78.0f, maxVal: 100.0f, label: "Performance", unit: "%",
    barColor: color(0.15f, 0.68f, 0.38f, 1.0f), trackColor: color(0.85f, 0.85f, 0.85f, 1.0f)
  )
  renderAndSave("semicircle_meter", proc(ctx: Context, font: Font, b: Rect) =
    drawSemiCircleMeter(ctx, font, b, semiMeter, cfg)
  )

  # 21. Liquid Fill Gauge
  let liquidGauge = LiquidGaugeData(
    percentage: 0.65f, waveHeight: 12.0f, waveCount: 2,
    fillColor: color(0.18f, 0.53f, 0.82f, 1.0f),
    borderColor: color(0.15f, 0.45f, 0.70f, 1.0f),
    textColor: color(0.1f, 0.1f, 0.1f, 1.0f)
  )
  renderAndSave("liquid_gauge", proc(ctx: Context, font: Font, b: Rect) =
    drawLiquidGauge(ctx, font, b, liquidGauge, cfg)
  )

  # 22. Candlestick Chart
  let candles = @[
    newCandleEntry("Mon", 100.0f, 115.0f, 95.0f, 110.0f, 1200.0f),
    newCandleEntry("Tue", 110.0f, 112.0f, 102.0f, 105.0f, 1500.0f),
    newCandleEntry("Wed", 105.0f, 125.0f, 104.0f, 122.0f, 2100.0f),
    newCandleEntry("Thu", 122.0f, 128.0f, 118.0f, 120.0f, 1800.0f),
    newCandleEntry("Fri", 120.0f, 135.0f, 119.0f, 132.0f, 2500.0f)
  ]
  renderAndSave("candlestick_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawCandlestickChart(ctx, font, b, candles, cfg)
  )

  # 23. BoxPlot Chart
  let boxPlots = @[
    newBoxPlotEntry("Group 1", 10.0f, 25.0f, 40.0f, 60.0f, 85.0f, @[2.0f, 95.0f]),
    newBoxPlotEntry("Group 2", 20.0f, 35.0f, 50.0f, 70.0f, 90.0f, @[98.0f])
  ]
  renderAndSave("boxplot_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawBoxPlotChart(ctx, font, b, boxPlots, cfg)
  )

  # 24. Violin Plot
  let violins = @[
    ViolinEntry(label: "Control", densityY: @[0.0f, 0.25f, 0.5f, 0.75f, 1.0f], densityW: @[0.1f, 0.6f, 0.9f, 0.5f, 0.1f], minVal: 10.0f, q1: 30.0f, median: 50.0f, q3: 70.0f, maxVal: 90.0f, color: color(0.18f, 0.53f, 0.82f, 0.7f)),
    ViolinEntry(label: "Treatment", densityY: @[0.0f, 0.25f, 0.5f, 0.75f, 1.0f], densityW: @[0.05f, 0.4f, 0.95f, 0.6f, 0.1f], minVal: 15.0f, q1: 40.0f, median: 65.0f, q3: 80.0f, maxVal: 95.0f, color: color(0.15f, 0.68f, 0.38f, 0.7f))
  ]
  renderAndSave("violin_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawViolinChart(ctx, font, b, violins, cfg)
  )

  # 25. Dot Plot Chart
  let dotGroups = @[
    DotPlotGroup(groupLabel: "North", values: @[12.0f, 15.0f, 15.5f, 18.0f, 22.0f, 22.5f], color: color(0.18f, 0.53f, 0.82f, 1.0f)),
    DotPlotGroup(groupLabel: "South", values: @[8.0f, 10.0f, 14.0f, 14.2f, 19.0f, 25.0f], color: color(0.91f, 0.30f, 0.24f, 1.0f))
  ]
  renderAndSave("dotplot_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawDotPlotChart(ctx, font, b, dotGroups, cfg)
  )

  # 26. Bubble Chart
  let bubbles = @[
    newBubbleEntry(20.0f, 30.0f, 18.0f, "Alpha"),
    newBubbleEntry(50.0f, 70.0f, 28.0f, "Beta"),
    newBubbleEntry(80.0f, 40.0f, 12.0f, "Gamma")
  ]
  renderAndSave("bubble_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawBubbleChart(ctx, font, b, bubbles, cfg)
  )

  # 27. Pareto Chart
  let paretoEntries = @[
    newParetoEntry("Syntax Error", 145.0f),
    newParetoEntry("Type Mismatch", 85.0f),
    newParetoEntry("Null Pointer", 35.0f),
    newParetoEntry("Index Defect", 18.0f),
    newParetoEntry("Memory Leak", 8.0f)
  ]
  renderAndSave("pareto_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawParetoChart(ctx, font, b, paretoEntries, cfg)
  )

  # 28. Error Bar Chart
  let errorBars = @[
    newErrorBarEntry("Sample A", 50.0f, 42.0f, 58.0f),
    newErrorBarEntry("Sample B", 75.0f, 68.0f, 82.0f),
    newErrorBarEntry("Sample C", 30.0f, 25.0f, 35.0f)
  ]
  renderAndSave("errorbar_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawErrorBarChart(ctx, font, b, errorBars, cfg)
  )

  # 29. Ridgeline Chart
  let ridgeSeries = @[
    RidgelineSeries(name: "Jan", values: @[1.0f, 4.0f, 10.0f, 5.0f, 2.0f], color: color(0.18f, 0.53f, 0.82f, 0.7f)),
    RidgelineSeries(name: "Feb", values: @[2.0f, 6.0f, 15.0f, 8.0f, 3.0f], color: color(0.15f, 0.68f, 0.38f, 0.7f)),
    RidgelineSeries(name: "Mar", values: @[1.0f, 8.0f, 12.0f, 10.0f, 4.0f], color: color(0.95f, 0.77f, 0.06f, 0.7f))
  ]
  renderAndSave("ridgeline_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawRidgelineChart(ctx, font, b, ridgeSeries, cfg)
  )

  # 30. Hexbin Chart
  var hexPoints: seq[HexPoint] = @[]
  for i in 0 ..< 200:
    let x = (i mod 20).float32 * 30.0f + ((i mod 5).float32 * 8.0f)
    let y = (i div 20).float32 * 30.0f + ((i mod 7).float32 * 6.0f)
    hexPoints.add(HexPoint(x: x, y: y))
  let hexData = HexbinData(
    points: hexPoints, hexRadius: 18.0f,
    colorLow: color(0.85f, 0.92f, 1.0f, 1.0f), colorHigh: color(0.10f, 0.30f, 0.75f, 1.0f)
  )
  renderAndSave("hexbin_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawHexbinChart(ctx, font, b, hexData, cfg)
  )

  # 31. Heatmap Chart
  let heatmapData = HeatmapData(
    rowLabels: @["Mon", "Tue", "Wed", "Thu", "Fri"],
    colLabels: @["Morning", "Afternoon", "Evening", "Night"],
    values: @[
      @[12.0f, 45.0f, 78.0f, 22.0f],
      @[18.0f, 52.0f, 85.0f, 30.0f],
      @[25.0f, 60.0f, 92.0f, 15.0f],
      @[30.0f, 58.0f, 88.0f, 40.0f],
      @[10.0f, 35.0f, 65.0f, 18.0f]
    ],
    minVal: 0.0f, maxVal: 100.0f,
    colorLow: color(0.9f, 0.95f, 1.0f, 1.0f),
    colorMid: color(0.4f, 0.6f, 0.9f, 1.0f),
    colorHigh: color(0.1f, 0.2f, 0.7f, 1.0f)
  )
  renderAndSave("heatmap_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawHeatmapChart(ctx, font, b, heatmapData, cfg)
  )

  # 32. Sunburst Chart
  let sunburstData = newSunburstNode("Total", 0.0f, color(0.2f, 0.2f, 0.2f, 1.0f), @[
    newSunburstNode("Europe", 0.0f, color(0.18f, 0.53f, 0.82f, 1.0f), @[
      newSunburstNode("UK", 40.0f, color(0.24f, 0.60f, 0.90f, 1.0f)),
      newSunburstNode("Germany", 60.0f, color(0.15f, 0.45f, 0.70f, 1.0f))
    ]),
    newSunburstNode("Americas", 0.0f, color(0.15f, 0.68f, 0.38f, 1.0f), @[
      newSunburstNode("USA", 120.0f, color(0.18f, 0.80f, 0.44f, 1.0f)),
      newSunburstNode("Canada", 30.0f, color(0.11f, 0.55f, 0.30f, 1.0f))
    ])
  ])
  renderAndSave("sunburst_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawSunburstChart(ctx, font, b, sunburstData, cfg)
  )

  # 33. Sankey Flow Diagram
  let sankeyData = SankeyData(
    stages: @[
      @[SankeyNode(id: "src1", label: "Organic", color: color(0.18f, 0.53f, 0.82f, 1.0f)), SankeyNode(id: "src2", label: "Paid", color: color(0.15f, 0.68f, 0.38f, 1.0f))],
      @[SankeyNode(id: "mid1", label: "Landing", color: color(0.95f, 0.77f, 0.06f, 1.0f)), SankeyNode(id: "mid2", label: "Direct", color: color(0.61f, 0.35f, 0.71f, 1.0f))],
      @[SankeyNode(id: "dst1", label: "Converted", color: color(0.15f, 0.68f, 0.38f, 1.0f)), SankeyNode(id: "dst2", label: "Bounced", color: color(0.91f, 0.30f, 0.24f, 1.0f))]
    ],
    links: @[
      SankeyLink(sourceId: "src1", targetId: "mid1", value: 60.0f),
      SankeyLink(sourceId: "src2", targetId: "mid1", value: 40.0f),
      SankeyLink(sourceId: "src1", targetId: "mid2", value: 20.0f),
      SankeyLink(sourceId: "mid1", targetId: "dst1", value: 70.0f),
      SankeyLink(sourceId: "mid1", targetId: "dst2", value: 30.0f),
      SankeyLink(sourceId: "mid2", targetId: "dst1", value: 15.0f)
    ]
  )
  renderAndSave("sankey_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawSankeyChart(ctx, font, b, sankeyData, cfg)
  )

  # 34. Chord Diagram
  let chordData = ChordMatrix(
    names: @["Group A", "Group B", "Group C"],
    matrix: @[
      @[0.0f, 25.0f, 40.0f],
      @[15.0f, 0.0f, 30.0f],
      @[35.0f, 20.0f, 0.0f]
    ],
    colors: @[color(0.18f, 0.53f, 0.82f, 1.0f), color(0.15f, 0.68f, 0.38f, 1.0f), color(0.95f, 0.77f, 0.06f, 1.0f)]
  )
  renderAndSave("chord_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawChordChart(ctx, font, b, chordData, cfg)
  )

  # 35. Treemap Chart
  let treemapItems = @[
    newTreemapItem("Electronics", 450.0f, color(0.18f, 0.53f, 0.82f, 1.0f)),
    newTreemapItem("Apparel", 300.0f, color(0.15f, 0.68f, 0.38f, 1.0f)),
    newTreemapItem("Home & Garden", 180.0f, color(0.95f, 0.77f, 0.06f, 1.0f)),
    newTreemapItem("Books", 90.0f, color(0.91f, 0.30f, 0.24f, 1.0f)),
    newTreemapItem("Toys", 60.0f, color(0.61f, 0.35f, 0.71f, 1.0f))
  ]
  renderAndSave("treemap_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawTreemapChart(ctx, font, b, treemapItems, cfg)
  )

  # 36. Circle Packing Chart
  let circleItems = @[
    PackedCircleItem(label: "Sales", value: 120.0f, color: color(0.18f, 0.53f, 0.82f, 1.0f)),
    PackedCircleItem(label: "Marketing", value: 80.0f, color: color(0.15f, 0.68f, 0.38f, 1.0f)),
    PackedCircleItem(label: "R&D", value: 95.0f, color: color(0.95f, 0.77f, 0.06f, 1.0f)),
    PackedCircleItem(label: "HR", value: 40.0f, color: color(0.91f, 0.30f, 0.24f, 1.0f)),
    PackedCircleItem(label: "Support", value: 65.0f, color: color(0.61f, 0.35f, 0.71f, 1.0f))
  ]
  renderAndSave("circlepack_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawCirclePackingChart(ctx, font, b, circleItems, cfg)
  )

  # 37. Dendrogram Chart
  let dendrogram = newDendrogramNode("Life", color(0.2f, 0.2f, 0.2f, 1.0f), @[
    newDendrogramNode("Animals", color(0.18f, 0.53f, 0.82f, 1.0f), @[
      newDendrogramNode("Mammals", color(0.24f, 0.60f, 0.90f, 1.0f)),
      newDendrogramNode("Reptiles", color(0.15f, 0.45f, 0.70f, 1.0f))
    ]),
    newDendrogramNode("Plants", color(0.15f, 0.68f, 0.38f, 1.0f), @[
      newDendrogramNode("Trees", color(0.18f, 0.80f, 0.44f, 1.0f)),
      newDendrogramNode("Flowers", color(0.11f, 0.55f, 0.30f, 1.0f))
    ])
  ])
  renderAndSave("dendrogram_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawDendrogramChart(ctx, font, b, dendrogram, cfg)
  )

  # 38. Arc Diagram Chart
  let arcDiagram = ArcDiagramData(
    nodes: @[
      ArcNode(id: "n1", label: "Node 1", color: color(0.18f, 0.53f, 0.82f, 1.0f)),
      ArcNode(id: "n2", label: "Node 2", color: color(0.15f, 0.68f, 0.38f, 1.0f)),
      ArcNode(id: "n3", label: "Node 3", color: color(0.95f, 0.77f, 0.06f, 1.0f)),
      ArcNode(id: "n4", label: "Node 4", color: color(0.91f, 0.30f, 0.24f, 1.0f))
    ],
    links: @[
      ArcLink(sourceId: "n1", targetId: "n3", weight: 3.0f, color: none(Color)),
      ArcLink(sourceId: "n2", targetId: "n4", weight: 2.0f, color: none(Color)),
      ArcLink(sourceId: "n1", targetId: "n4", weight: 4.0f, color: none(Color))
    ]
  )
  renderAndSave("arcdiagram_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawArcDiagramChart(ctx, font, b, arcDiagram, cfg)
  )

  # 39. Conversion Funnel Chart
  let funnelEntries = @[
    newFunnelEntry("Impressions", 10000.0f, "100k"),
    newFunnelEntry("Clicks", 4200.0f, "42k"),
    newFunnelEntry("Signups", 1800.0f, "18k"),
    newFunnelEntry("Purchases", 650.0f, "6.5k")
  ]
  renderAndSave("funnel_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawFunnelChart(ctx, font, b, funnelEntries, cfg)
  )

  # 40. Waterfall Chart
  let waterfall = @[
    newWaterfallEntry("Revenue", 120.0f, Normal),
    newWaterfallEntry("COGS", -45.0f, Normal),
    newWaterfallEntry("Gross", 75.0f, Subtotal),
    newWaterfallEntry("Opex", -30.0f, Normal),
    newWaterfallEntry("Tax", -12.0f, Normal),
    newWaterfallEntry("Net Profit", 33.0f, Total)
  ]
  renderAndSave("waterfall_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawWaterfallChart(ctx, font, b, waterfall, cfg)
  )

  # 41. Gantt Chart
  let ganttTasks = @[
    newGanttTask("Requirements", 0.0f, 5.0f, 1.0f),
    newGanttTask("Architecture Design", 4.0f, 10.0f, 0.8f),
    newGanttTask("Implementation", 9.0f, 20.0f, 0.4f),
    newGanttTask("Testing & QA", 18.0f, 25.0f, 0.0f)
  ]
  renderAndSave("gantt_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawGanttChart(ctx, font, b, ganttTasks, cfg)
  )

  # 42. Bullet Graph
  let bullet = newBulletEntry(
    "Revenue", "kUSD", 275.0f, 250.0f,
    @[
      BulletRange(label: "Bad", value: 150.0f, color: color(0.85f, 0.85f, 0.85f, 1.0f)),
      BulletRange(label: "Satisfactory", value: 225.0f, color: color(0.70f, 0.70f, 0.70f, 1.0f)),
      BulletRange(label: "Good", value: 300.0f, color: color(0.55f, 0.55f, 0.55f, 1.0f))
    ]
  )
  renderAndSave("bullet_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawBulletChart(ctx, font, b, [bullet], cfg)
  )

  # 43. Dumbbell Plot
  let dumbbells = @[
    newDumbbellEntry("Product A", 45.0f, 85.0f),
    newDumbbellEntry("Product B", 60.0f, 92.0f),
    newDumbbellEntry("Product C", 30.0f, 70.0f)
  ]
  renderAndSave("dumbbell_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawDumbbellChart(ctx, font, b, dumbbells, cfg)
  )

  # 44. Streamgraph
  let streams = @[
    StreamSeries(name: "Rock", values: @[12.0f, 25.0f, 45.0f, 32.0f, 18.0f], color: color(0.18f, 0.53f, 0.82f, 1.0f)),
    StreamSeries(name: "Pop", values: @[20.0f, 35.0f, 28.0f, 40.0f, 50.0f], color: color(0.15f, 0.68f, 0.38f, 1.0f)),
    StreamSeries(name: "Jazz", values: @[15.0f, 18.0f, 22.0f, 15.0f, 10.0f], color: color(0.95f, 0.77f, 0.06f, 1.0f))
  ]
  renderAndSave("streamgraph_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawStreamgraphChart(ctx, font, b, streams, cfg)
  )

  # 45. Marimekko Chart
  let mekkoCols = @[
    MekkoColumn(name: "Segment 1", segments: @[
      MekkoSegment(name: "A", value: 40.0f, color: color(0.18f, 0.53f, 0.82f, 1.0f)),
      MekkoSegment(name: "B", value: 60.0f, color: color(0.15f, 0.68f, 0.38f, 1.0f))
    ]),
    MekkoColumn(name: "Segment 2", segments: @[
      MekkoSegment(name: "A", value: 25.0f, color: color(0.18f, 0.53f, 0.82f, 1.0f)),
      MekkoSegment(name: "B", value: 75.0f, color: color(0.15f, 0.68f, 0.38f, 1.0f))
    ])
  ]
  renderAndSave("marimekko_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawMarimekkoChart(ctx, font, b, mekkoCols, cfg)
  )

  # 46. Ternary Plot
  let ternaryPts = @[
    newTernaryPoint("Sample 1", 50.0f, 30.0f, 20.0f),
    newTernaryPoint("Sample 2", 20.0f, 60.0f, 20.0f),
    newTernaryPoint("Sample 3", 15.0f, 25.0f, 60.0f)
  ]
  renderAndSave("ternary_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawTernaryChart(ctx, font, b, ternaryPts, cfg)
  )

  # 47. Slopegraph
  let slopeItems = @[
    newSlopeItem("Alpha", 45.0f, 82.0f),
    newSlopeItem("Beta", 65.0f, 50.0f),
    newSlopeItem("Gamma", 30.0f, 75.0f)
  ]
  renderAndSave("slope_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawSlopeChart(ctx, font, b, slopeItems, cfg)
  )

  # 48. Venn 2-Set Diagram
  let venn2 = newVenn2Data("Team A", "Team B", "Overlap", 120.0f, 85.0f, 35.0f)
  renderAndSave("venn2_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawVenn2Chart(ctx, font, b, venn2, cfg)
  )

  # 49. Venn 3-Set Diagram
  let venn3 = Venn3Data(
    labelA: "Design", labelB: "Dev", labelC: "Product",
    labelAB: "UI/UX", labelBC: "Tech Spec", labelCA: "Strategy", labelABC: "Full Stack",
    countA: 100.0f, countB: 120.0f, countC: 80.0f,
    countAB: 30.0f, countBC: 25.0f, countCA: 20.0f, countABC: 12.0f,
    colorA: color(0.18f, 0.53f, 0.82f, 0.5f),
    colorB: color(0.15f, 0.68f, 0.38f, 0.5f),
    colorC: color(0.95f, 0.77f, 0.06f, 0.5f)
  )
  renderAndSave("venn3_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawVenn3Chart(ctx, font, b, venn3, cfg)
  )

  # 50. KPI Scorecard Card
  let kpiData = newKpiCardData("Quarterly ARR", "$2,480,000", "+24.5%", @[12.0f, 15.0f, 14.0f, 18.0f, 22.0f, 28.0f, 34.0f])
  renderAndSave("kpi_card_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawKpiCardChart(ctx, font, b, kpiData, cfg)
  )

  # 51. Waffle Matrix Chart
  let waffleCats = @[
    WaffleCategory(name: "Done", count: 68, color: color(0.15f, 0.68f, 0.38f, 1.0f)),
    WaffleCategory(name: "In Progress", count: 22, color: color(0.18f, 0.53f, 0.82f, 1.0f)),
    WaffleCategory(name: "To Do", count: 10, color: color(0.85f, 0.85f, 0.85f, 1.0f))
  ]
  renderAndSave("waffle_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawWaffleChart(ctx, font, b, waffleCats, cfg)
  )

  # 52. Likert Scale Survey
  let likertResponses = @[
    LikertResponse(question: "The documentation is clear", counts: [2.0f, 8.0f, 15.0f, 45.0f, 30.0f]),
    LikertResponse(question: "The API is easy to use", counts: [1.0f, 5.0f, 10.0f, 50.0f, 34.0f]),
    LikertResponse(question: "Performance meets expectations", counts: [3.0f, 7.0f, 20.0f, 40.0f, 30.0f])
  ]
  renderAndSave("likert_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawLikertChart(ctx, font, b, likertResponses, cfg)
  )

  # 53. Quadrant 2x2 Matrix
  let quadData = QuadrantData(
    items: @[
      newQuadrantItem("Proj A", 80.0f, 85.0f, 10.0f, color(0.15f, 0.68f, 0.38f, 1.0f)),
      newQuadrantItem("Proj B", 30.0f, 70.0f, 8.0f, color(0.18f, 0.53f, 0.82f, 1.0f)),
      newQuadrantItem("Proj C", 20.0f, 25.0f, 12.0f, color(0.91f, 0.30f, 0.24f, 1.0f)),
      newQuadrantItem("Proj D", 75.0f, 35.0f, 9.0f, color(0.95f, 0.77f, 0.06f, 1.0f))
    ],
    minX: 0.0f, maxX: 100.0f, minY: 0.0f, maxY: 100.0f,
    xLabel: "Feasibility", yLabel: "Impact",
    quadLabels: ["Quick Wins", "Strategic", "Reconsider", "Fillers"]
  )
  renderAndSave("quadrant_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawQuadrantChart(ctx, font, b, quadData, cfg)
  )

  # 54. Milestone Event Timeline
  let timelineEvents = @[
    newTimelineEvent("Jan 2024", "Project Kickoff"),
    newTimelineEvent("Mar 2024", "Alpha Prototype"),
    newTimelineEvent("Jun 2024", "Beta Testing"),
    newTimelineEvent("Sep 2024", "v1.0 GA Release")
  ]
  renderAndSave("timeline_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawTimelineChart(ctx, font, b, timelineEvents, cfg)
  )

  # 55. Calendar Heatmap
  var calDays: seq[CalendarDay] = @[]
  for w in 0 ..< 52:
    for d in 0 ..< 7:
      calDays.add(CalendarDay(dayIndex: d, weekIndex: w, value: (w * 7 + d) mod 5))
  renderAndSave("calendar_heatmap", proc(ctx: Context, font: Font, b: Rect) =
    drawCalendarHeatmap(ctx, font, b, calDays, cfg)
  )

  # 56. Horizon Graph
  let horizonSeries = @[
    HorizonSeries(name: "CPU Utilization", values: @[15.0f, 35.0f, 75.0f, 90.0f, 45.0f, -10.0f, 20.0f], positiveColor: color(0.18f, 0.53f, 0.82f, 1.0f), negativeColor: color(0.91f, 0.30f, 0.24f, 1.0f))
  ]
  renderAndSave("horizon_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawHorizonChart(ctx, font, b, horizonSeries, cfg)
  )

  # 57. Word Cloud
  let wordCloudItems = @[
    WordCloudItem(text: "Nim", weight: 100.0f, color: color(0.95f, 0.77f, 0.06f, 1.0f)),
    WordCloudItem(text: "Pixie", weight: 85.0f, color: color(0.18f, 0.53f, 0.82f, 1.0f)),
    WordCloudItem(text: "Graphics", weight: 70.0f, color: color(0.15f, 0.68f, 0.38f, 1.0f)),
    WordCloudItem(text: "Charts", weight: 65.0f, color: color(0.91f, 0.30f, 0.24f, 1.0f)),
    WordCloudItem(text: "Vector", weight: 50.0f, color: color(0.61f, 0.35f, 0.71f, 1.0f)),
    WordCloudItem(text: "Performance", weight: 45.0f, color: color(0.20f, 0.70f, 0.80f, 1.0f))
  ]
  renderAndSave("wordcloud_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawWordCloudChart(ctx, font, b, wordCloudItems, cfg)
  )

  # 58. Parallel Coordinates
  let parallelRecords = @[
    ParallelRecord(name: "Car 1", values: @[200.0f, 25.0f, 15.0f], color: color(0.18f, 0.53f, 0.82f, 0.8f)),
    ParallelRecord(name: "Car 2", values: @[150.0f, 35.0f, 22.0f], color: color(0.15f, 0.68f, 0.38f, 0.8f)),
    ParallelRecord(name: "Car 3", values: @[280.0f, 18.0f, 12.0f], color: color(0.91f, 0.30f, 0.24f, 0.8f))
  ]
  let parallelDims = @[
    ParallelDimension(name: "Horsepower", minVal: 100.0f, maxVal: 300.0f),
    ParallelDimension(name: "MPG", minVal: 10.0f, maxVal: 40.0f),
    ParallelDimension(name: "Acceleration", minVal: 10.0f, maxVal: 25.0f)
  ]
  renderAndSave("parallelcoords_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawParallelCoordsChart(ctx, font, b, parallelDims, parallelRecords, cfg)
  )

  # 59. Population Pyramid
  let pyramidCohorts = @[
    newPyramidCohort("0-19", 120.0f, 115.0f),
    newPyramidCohort("20-39", 180.0f, 175.0f),
    newPyramidCohort("40-59", 150.0f, 152.0f),
    newPyramidCohort("60-79", 90.0f, 98.0f),
    newPyramidCohort("80+", 30.0f, 42.0f)
  ]
  renderAndSave("pyramid_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawPyramidChart(ctx, font, b, pyramidCohorts, cfg)
  )

  # 60. Bump Chart
  let bumpData = BumpChartData(
    timeLabels: @["2021", "2022", "2023", "2024"],
    series: @[
      newBumpSeries("Team Alpha", @[1, 2, 1, 1], color(0.18f, 0.53f, 0.82f, 1.0f)),
      newBumpSeries("Team Beta", @[2, 1, 3, 2], color(0.15f, 0.68f, 0.38f, 1.0f)),
      newBumpSeries("Team Gamma", @[3, 3, 2, 3], color(0.91f, 0.30f, 0.24f, 1.0f))
    ]
  )
  renderAndSave("bump_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawBumpChart(ctx, font, b, bumpData, cfg)
  )

  # 61. Sparkline Chart
  let sparkData = newSparklineData(
    @[10.0f, 15.0f, 8.0f, 22.0f, 18.0f, 28.0f, 35.0f, 32.0f, 42.0f, 40.0f],
    color(0.18f, 0.53f, 0.82f, 1.0f),
    color(0.18f, 0.53f, 0.82f, 0.25f)
  )
  renderAndSave("sparkline_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawSparklineChart(ctx, font, b, sparkData, cfg)
  )

  # 62. Network Chart
  let netData = NetworkGraphData(
    nodes: @[
      newNetworkNode("n1", "Server", 100.0f, 100.0f, 22.0f, color(0.18f, 0.53f, 0.82f, 1.0f)),
      newNetworkNode("n2", "Client A", 300.0f, 50.0f, 18.0f, color(0.15f, 0.68f, 0.38f, 1.0f)),
      newNetworkNode("n3", "Client B", 300.0f, 180.0f, 18.0f, color(0.95f, 0.77f, 0.06f, 1.0f)),
      newNetworkNode("n4", "Database", 500.0f, 100.0f, 25.0f, color(0.91f, 0.30f, 0.24f, 1.0f))
    ],
    edges: @[
      newNetworkEdge("n1", "n2", 2.0f),
      newNetworkEdge("n1", "n3", 2.0f),
      newNetworkEdge("n2", "n4", 3.0f),
      newNetworkEdge("n3", "n4", 3.0f)
    ]
  )
  renderAndSave("network_chart", proc(ctx: Context, font: Font, b: Rect) =
    drawNetworkChart(ctx, font, b, netData, cfg)
  )

  # 63. Org Chart
  let orgData = newOrgNode("Alice Smith", "CEO", color(0.18f, 0.53f, 0.82f, 1.0f), @[
    newOrgNode("Bob Jones", "VP Engineering", color(0.15f, 0.68f, 0.38f, 1.0f), @[
      newOrgNode("Charlie", "Lead Dev", color(0.61f, 0.35f, 0.71f, 1.0f)),
      newOrgNode("Diana", "QA Lead", color(0.61f, 0.35f, 0.71f, 1.0f))
    ]),
    newOrgNode("Eve Brown", "VP Marketing", color(0.95f, 0.77f, 0.06f, 1.0f), @[
      newOrgNode("Frank", "SEO Lead", color(0.91f, 0.30f, 0.24f, 1.0f))
    ])
  ])
  renderAndSave("orgchart", proc(ctx: Context, font: Font, b: Rect) =
    drawOrgChart(ctx, font, b, orgData, cfg)
  )

  echo "All gallery charts generated successfully!"

  # Bonus: demonstrate animation-frame export helpers by
  # rendering a short animated sequence of the bar chart sweeping in.
  let font = readFont("Roboto-Regular.ttf")
  let frames = renderAnimationFrames(
    800, 600, 45,
    proc(ctx: Context, bounds: Rect, progress: float32) =
      var animCfg = cfg
      animCfg.animationProgress = progress
      ctx.fillStyle = color(1, 1, 1, 1)
      ctx.fillRect(0, 0, bounds.w, bounds.h)
      drawBarChart(ctx, font, bounds, entries, animCfg),
    easeOutBack
  )
  createDir("output")
  createDir("output_gallery")
  discard saveAnimationFrames(frames, "output", "anim_barchart")
  discard saveAnimationFrames(frames, "output_gallery", "anim_barchart")
  echo "Generated ", frames.len, " animation frames in output/ and output_gallery/"

when isMainModule:
  main()
