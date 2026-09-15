import std/[math, options]
import pixie
import ../types, ../helpers

proc drawPointChart*(
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
  let barSize = calculateBarSize(itemSize.x, itemSize.y, series.len, config.margin)
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
  for i in 0 ..< nbItems:
    let itemX = config.margin + (itemSize.x * 0.5f) + (i.float32 * (itemSize.x + config.margin)) + yAxisXShift
    let label = labels[i]
    if label.len > 0:
      let pos = vec2(itemX, height - footerHeight + config.margin)
      let rot = if config.labelOrientation == Orientation.Vertical: -PI * 0.5f else: 0.0f
      let align = if config.labelOrientation == Orientation.Vertical: RightAlign else: CenterAlign
      drawTextAligned(ctx, font, label, pos, config.labelColor, align, MiddleAlign, rot)

  # Render Points and Area Bars
  font.size = config.valueLabelTextSize
  for serieIndex in 0 ..< series.len:
    let serie = series[serieIndex]
    let totalBarMarge = serieIndex.float32 * (config.margin * 0.5f)

    for i in 0 ..< nbItems:
      if i >= serie.entries.len:
        break
      let entry = serie.entries[i]
      if not entry.hasValue:
        continue

      let itemX = config.margin + (itemSize.x * 0.5f) + (i.float32 * (itemSize.x + config.margin)) + yAxisXShift
      let barX = itemX + (serieIndex.float32 * barSize.x) + totalBarMarge
      let progress = config.animationProgress
      # Each point staggers in shortly after the previous, with its own
      # gentle overshoot as it "lands" on its final value.
      let popT = easeOutBack(staggerProgress(i, nbItems, progress, 0.6f))
      let barY = headerHeight + ((1.0f - progress) * (origin - headerHeight) + (((maxVal - entry.value) / valRange) * itemSize.y) * progress)
      let centerPt = vec2(barX - (itemSize.x * 0.5f) + (barSize.x * 0.5f), barY)
      let color = serie.color.get(entry.color)
      let pointScale = clamp(popT, 0.0f, 1.15f)
      let pointAlpha = min(1.0f, popT)

      if config.pointAreaAlpha > 0.0f:
        let y = min(origin, barY)
        let areaH = max(2.0f, abs(origin - barY))
        let areaX = centerPt.x - (config.pointSize * 0.5f)
        ctx.fillStyle = color.withAlpha(config.pointAreaAlpha * progress)
        ctx.fillRect(areaX, y, config.pointSize, areaH)

      if config.pointMode == PointMode.Circle:
        ctx.fillStyle = color.withAlpha(pointAlpha)
        ctx.beginPath()
        ctx.circle(centerPt.x, centerPt.y, config.pointSize * 0.5f * pointScale)
        ctx.fill()
      elif config.pointMode == PointMode.Square:
        let s = config.pointSize * pointScale
        ctx.fillStyle = color.withAlpha(pointAlpha)
        ctx.fillRect(centerPt.x - (s * 0.5f), centerPt.y - (s * 0.5f), s, s)

      if entry.valueLabel.len > 0 and config.valueLabelOption != ValueLabelOption.None:
        let valColor = entry.valueLabelColor.withAlpha(progress)
        let rot = if config.valueLabelOrientation == Orientation.Vertical: -PI * 0.5f else: 0.0f
        var labelPos = vec2(centerPt.x, headerHeight - config.margin)
        var align = CenterAlign

        case config.valueLabelOption
        of ValueLabelOption.TopOfChart:
          labelPos = vec2(centerPt.x, headerHeight - config.margin)
          align = if config.valueLabelOrientation == Orientation.Vertical: RightAlign else: CenterAlign
        of ValueLabelOption.TopOfElement:
          labelPos = vec2(centerPt.x, centerPt.y - (config.pointSize * 0.5f) - (config.margin * 0.5f))
          align = if config.valueLabelOrientation == Orientation.Vertical: RightAlign else: CenterAlign
        of ValueLabelOption.OverElement:
          labelPos = centerPt
          align = CenterAlign
        of ValueLabelOption.None:
          discard

        drawTextAligned(ctx, font, entry.valueLabel, labelPos, valColor, align, MiddleAlign, rot)

  ctx.restore()

proc drawPointChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  entries: openArray[ChartEntry],
  config: ChartConfig = defaultChartConfig()
) =
  drawPointChart(ctx, font, bounds, [newChartSerie("Default", @entries)], config)
