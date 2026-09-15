import std/[math, options]
import pixie
import ../types, ../helpers

proc drawBarChart*(
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

  let valRange = max(1.0f, maxVal - minVal)
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

  # Render X-Axis labels
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

  # Render Bars and Value Labels - bars grow up from the baseline, each
  # slot staggered a touch after the previous so the chart reads as a
  # lively left-to-right build rather than one flat lockstep motion.
  font.size = config.valueLabelTextSize
  let nbSeries = series.len
  for serieIndex in 0 ..< nbSeries:
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
      let progress = easeOutQuad(staggerProgress(i, nbItems, config.animationProgress, 0.75f))
      let barY = headerHeight + ((1.0f - progress) * (origin - headerHeight) + (((maxVal - entry.value) / valRange) * itemSize.y) * progress)

      var x = barX - (itemSize.x * 0.5f)
      var y = min(origin, barY)
      var h = abs(origin - barY)

      if h > 0.0f and h < config.minBarHeight:
        h = config.minBarHeight
        if barY < origin:
          y = origin - h

      let barColor = serie.color.get(entry.color)
      let areaColor = if entry.otherColor.a > 0.0f:
                        entry.otherColor
                      elif config.barAreaAlpha > 0.0f:
                        barColor.withAlpha(config.barAreaAlpha * progress)
                      else:
                        color(0, 0, 0, 0)

      if areaColor.a > 0.0f:
        let maxPos = if entry.value > 0.0f: headerHeight else: headerHeight + itemSize.y
        let areaH = abs(maxPos - barY) + min(origin - barY, config.cornerRadius)
        let areaY = min(maxPos, barY)
        ctx.fillStyle = areaColor
        ctx.fillRect(x, areaY, barSize.x, areaH)

      # Soft drop shadow underneath the bar for a touch of depth
      if h > 1.0f:
        ctx.fillStyle = color(0.0f, 0.0f, 0.0f, 0.14f * min(1.0f, progress * 2.0f))
        ctx.fillRect(x + 1.5f, y + 2.5f, barSize.x, h)

      ctx.fillStyle = barColor
      if config.cornerRadius > 0.0f:
        let path = newPath()
        path.roundedRect(rect(x, y, barSize.x, h), config.cornerRadius, config.cornerRadius)
        ctx.fillPath(path)
        let coverH = h * 0.5f
        ctx.fillRect(x, y + h - coverH, barSize.x, coverH)
      else:
        ctx.fillRect(x, y, barSize.x, h)

      # Subtle lighter sheen across the top of the bar
      let sheenH = min(h * 0.4f, 8.0f)
      if sheenH > 1.5f:
        ctx.fillStyle = color(1.0f, 1.0f, 1.0f, 0.15f * min(1.0f, progress * 2.0f))
        ctx.fillRect(x, y, barSize.x, sheenH)

      if entry.valueLabel.len > 0 and config.valueLabelOption != ValueLabelOption.None:
        let valColor = entry.valueLabelColor.withAlpha(min(1.0f, progress * 1.5f))
        let rot = if config.valueLabelOrientation == Orientation.Vertical: -PI * 0.5f else: 0.0f
        var labelPos = vec2(x + (barSize.x * 0.5f), headerHeight - config.margin)
        var align = CenterAlign

        case config.valueLabelOption
        of ValueLabelOption.TopOfChart:
          labelPos = vec2(x + (barSize.x * 0.5f), headerHeight - config.margin)
          align = if config.valueLabelOrientation == Orientation.Vertical: RightAlign else: CenterAlign
        of ValueLabelOption.TopOfElement:
          labelPos = vec2(x + (barSize.x * 0.5f), barY - config.margin * 0.5f)
          align = if config.valueLabelOrientation == Orientation.Vertical: RightAlign else: CenterAlign
        of ValueLabelOption.OverElement:
          labelPos = vec2(x + (barSize.x * 0.5f), barY + ((origin - barY) * 0.5f))
          align = CenterAlign
        of ValueLabelOption.None:
          discard

        drawTextAligned(ctx, font, entry.valueLabel, labelPos, valColor, align, MiddleAlign, rot)

  ctx.restore()

proc drawBarChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  entries: openArray[ChartEntry],
  config: ChartConfig = defaultChartConfig()
) =
  drawBarChart(ctx, font, bounds, [newChartSerie("Default", @entries)], config)
