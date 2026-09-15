import std/[math, options]
import pixie
import ../types, ../helpers

proc drawLineChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  seriesList: openArray[ChartSerie],
  config: ChartConfig = defaultChartConfig()
) =
  if seriesList.len == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  var series = @seriesList
  var minVal, maxVal: float32
  calculateMinMax(series, config.minValue, config.maxValue, minVal, maxVal)

  var width = bounds.w
  let height = bounds.h
  let fixedRange = config.minValue.isSome or config.maxValue.isSome
  var yAxisXShift: float32 = 0.0f
  var yAxisIntervalLabels: seq[float32] = @[]

  font.size = config.labelTextSize
  width = calculateYAxis(
    config.showYAxisText, config.showYAxisLines, series,
    config.yAxisMaxTicks, font, config.yAxisPosition,
    width, fixedRange, maxVal, minVal, yAxisXShift, yAxisIntervalLabels
  )

  let valRange = maxVal - minVal
  let firstSerie = series[0]
  var labels = newSeqOfCap[string](firstSerie.entries.len)
  var labelSizes: seq[Vec2] = @[]
  for e in firstSerie.entries:
    labels.add(e.label)
    labelSizes.add(font.measureTextSize(e.label))

  let nbItems = labels.len
  if nbItems == 0:
    ctx.restore()
    return

  let footerHeight = calculateFooterHeaderHeight(config.margin, config.labelTextSize, labelSizes, config.labelOrientation)
  var valueLabelSizes: seq[Vec2] = @[]
  font.size = config.valueLabelTextSize
  for s in series:
    for e in s.entries:
      valueLabelSizes.add(font.measureTextSize(e.valueLabel))

  var headerHeight = config.margin
  if config.valueLabelOption == ValueLabelOption.TopOfChart or config.valueLabelOption == ValueLabelOption.TopOfElement:
    headerHeight = calculateFooterHeaderHeight(config.margin, config.valueLabelTextSize, valueLabelSizes, config.valueLabelOrientation)

  let itemSize = calculateItemSize(nbItems, width, height, footerHeight + headerHeight, config.margin)
  let origin = calculateYOrigin(itemSize.y, headerHeight, maxVal, minVal, valRange)

  font.size = config.labelTextSize
  drawYAxisLinesAndText(
    ctx, font, config.showYAxisText, config.showYAxisLines,
    config.yAxisPosition, config.yAxisTextColor, config.yAxisLinesColor,
    config.margin, maxVal, valRange, width, yAxisXShift, headerHeight,
    itemSize, origin, yAxisIntervalLabels,
    alpha = clamp(config.animationProgress / 0.3f, 0.0f, 1.0f)
  )

  # Render Labels
  font.size = config.labelTextSize
  let labelAlpha = clamp(config.animationProgress / 0.3f, 0.0f, 1.0f)
  for i in 0 ..< nbItems:
    let itemX = config.margin + (itemSize.x * 0.5f) + (i.float32 * (itemSize.x + config.margin)) + yAxisXShift
    let label = labels[i]
    if label.len > 0:
      let pos = vec2(itemX, height - footerHeight + config.margin)
      let rot = if config.labelOrientation == Orientation.Vertical: -PI * 0.5f else: 0.0f
      let align = if config.labelOrientation == Orientation.Vertical: RightAlign else: CenterAlign
      drawTextAligned(ctx, font, label, pos, config.labelColor.withAlpha(labelAlpha), align, MiddleAlign, rot)

  # Collect plotted coordinates for each series
  var seriesPoints: seq[seq[Vec2]] = @[]
  for serie in series:
    var pts: seq[Vec2] = @[]
    for i in 0 ..< nbItems:
      if i >= serie.entries.len or not serie.entries[i].hasValue:
        pts.add(vec2(-10000.0f, -10000.0f))
      else:
        let entry = serie.entries[i]
        let itemX = config.margin + (itemSize.x * 0.5f) + (i.float32 * (itemSize.x + config.margin)) + yAxisXShift
        let progress = config.animationProgress
        let barY = headerHeight + ((1.0f - progress) * (origin - headerHeight) + (((maxVal - entry.value) / valRange) * itemSize.y) * progress)
        pts.add(vec2(itemX, barY))
    seriesPoints.add(pts)

  # 1. Fill Line Areas
  if config.lineAreaAlpha > 0.0f:
    for sIdx in 0 ..< series.len:
      let serie = series[sIdx]
      let pts = seriesPoints[sIdx]
      let sColor = serie.color.get(if serie.entries.len > 0: serie.entries[0].color else: color(0, 0, 0, 1))
      let areaPaint = sColor.withAlpha(config.lineAreaAlpha * config.animationProgress)

      var isFirst = true
      var lastPt = vec2(0, 0)
      let path = newPath()

      for i in 0 ..< pts.len:
        if pts[i].x < -5000.0f:
          continue

        if isFirst:
          path.moveTo(pts[i].x, origin)
          path.lineTo(pts[i].x, pts[i].y)
          isFirst = false
          lastPt = pts[i]
        else:
          if config.lineMode == LineMode.Spline:
            var prevValid = i - 1
            while prevValid >= 0 and pts[prevValid].x < -5000.0f:
              dec prevValid
            if prevValid >= 0:
              let info = calculateCubicInfo(pts, prevValid, i, itemSize.x)
              path.bezierCurveTo(info.control.x, info.control.y, info.nextControl.x, info.nextControl.y, info.nextPoint.x, info.nextPoint.y)
              lastPt = info.nextPoint
          elif config.lineMode == LineMode.Straight:
            path.lineTo(pts[i].x, pts[i].y)
            lastPt = pts[i]

      if not isFirst:
        path.lineTo(lastPt.x, origin)
        path.closePath()
        ctx.fillStyle = areaPaint
        ctx.fillPath(path)

  # 2. Draw Connected Series Stroke
  if config.lineMode != LineMode.None:
    for sIdx in 0 ..< series.len:
      let serie = series[sIdx]
      let pts = seriesPoints[sIdx]
      let sColor = serie.color.get(if serie.entries.len > 0: serie.entries[0].color else: color(0, 0, 0, 1))

      let path = newPath()
      var isFirst = true

      for i in 0 ..< pts.len:
        if pts[i].x < -5000.0f:
          continue

        if isFirst:
          path.moveTo(pts[i].x, pts[i].y)
          isFirst = false
        else:
          if config.lineMode == LineMode.Spline:
            var prevValid = i - 1
            while prevValid >= 0 and pts[prevValid].x < -5000.0f:
              dec prevValid
            if prevValid >= 0:
              let info = calculateCubicInfo(pts, prevValid, i, itemSize.x)
              path.bezierCurveTo(info.control.x, info.control.y, info.nextControl.x, info.nextControl.y, info.nextPoint.x, info.nextPoint.y)
          elif config.lineMode == LineMode.Straight:
            path.lineTo(pts[i].x, pts[i].y)

      if not isFirst:
        ctx.strokeStyle = sColor
        ctx.lineWidth = config.lineSize
        ctx.strokePath(path)

  # 3. Draw Nodes and Value Labels - nodes pop in with a soft overshoot,
  # gently staggered across the series so they don't all land at once.
  font.size = config.valueLabelTextSize
  let progress = config.animationProgress
  for sIdx in 0 ..< series.len:
    let serie = series[sIdx]
    let pts = seriesPoints[sIdx]
    let sColor = serie.color.get(if serie.entries.len > 0: serie.entries[0].color else: color(0, 0, 0, 1))

    for i in 0 ..< pts.len:
      let pt = pts[i]
      if pt.x < -5000.0f:
        continue
      let entry = serie.entries[i]
      let popT = easeOutBack(staggerProgress(i, max(1, pts.len), progress, 0.7f))
      let popScale = clamp(popT, 0.0f, 1.15f)
      let popAlpha = min(1.0f, popT * 2.0f)

      if config.pointMode == PointMode.Circle:
        ctx.fillStyle = sColor.withAlpha(sColor.a * popAlpha)
        ctx.beginPath()
        ctx.circle(pt.x, pt.y, config.pointSize * 0.5f * popScale)
        ctx.fill()
      elif config.pointMode == PointMode.Square:
        let s = config.pointSize * popScale
        ctx.fillStyle = sColor.withAlpha(sColor.a * popAlpha)
        ctx.fillRect(pt.x - (s * 0.5f), pt.y - (s * 0.5f), s, s)

      if entry.valueLabel.len > 0 and config.valueLabelOption != ValueLabelOption.None:
        let valColor = entry.valueLabelColor.withAlpha(popAlpha)
        let rot = if config.valueLabelOrientation == Orientation.Vertical: -PI * 0.5f else: 0.0f
        var labelPos = pt
        var align = CenterAlign

        case config.valueLabelOption
        of ValueLabelOption.TopOfChart:
          if series.len == 1:
            labelPos = vec2(pt.x, headerHeight - config.margin)
            align = if config.valueLabelOrientation == Orientation.Vertical: RightAlign else: CenterAlign
          else:
            labelPos = vec2(pt.x, pt.y - (config.pointSize * 0.5f) - (config.margin * 0.5f))
            align = if config.valueLabelOrientation == Orientation.Vertical: RightAlign else: CenterAlign
        of ValueLabelOption.TopOfElement:
          labelPos = vec2(pt.x, pt.y - (config.pointSize * 0.5f) - (config.margin * 0.5f))
          align = if config.valueLabelOrientation == Orientation.Vertical: RightAlign else: CenterAlign
        of ValueLabelOption.OverElement:
          labelPos = pt
          align = CenterAlign
        of ValueLabelOption.None:
          discard

        drawTextAligned(ctx, font, entry.valueLabel, labelPos, valColor, align, MiddleAlign, rot)

  ctx.restore()

proc drawLineChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  entries: openArray[ChartEntry],
  config: ChartConfig = defaultChartConfig()
) =
  drawLineChart(ctx, font, bounds, [newChartSerie("Default", @entries)], config)
