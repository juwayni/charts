import std/[math, options]
import pixie
import ../types, ../helpers

proc drawHorizontalBarChart*(
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

  var minVal, maxVal: float32
  calculateMinMax(seriesList, config.minValue, config.maxValue, minVal, maxVal)
  if minVal > 0.0f: minVal = 0.0f
  if maxVal == minVal: maxVal += 100.0f

  var range, niceMin, niceMax, tickSpacing: float64
  calculateNiceScale(minVal.float64, maxVal.float64, config.yAxisMaxTicks, range, tickSpacing, niceMin, niceMax)
  let ticks = int((niceMax - niceMin) / tickSpacing) + 1
  let valRange = (niceMax - niceMin).float32

  let firstSerie = seriesList[0]
  let nbItems = firstSerie.entries.len
  if nbItems == 0:
    ctx.restore()
    return

  font.size = config.labelTextSize
  var maxLabelWidth = 0.0f
  for e in firstSerie.entries:
    let w = font.measureTextSize(e.label).x
    if w > maxLabelWidth:
      maxLabelWidth = w

  let leftMargin = config.margin + maxLabelWidth + 10.0f
  let bottomMargin = config.margin + config.labelTextSize + 10.0f
  let chartW = max(1.0f, bounds.w - leftMargin - config.margin)
  let chartH = max(1.0f, bounds.h - config.margin - bottomMargin)

  let originX = leftMargin + (((0.0f - niceMin.float32) / valRange) * chartW)
  let progress = config.animationProgress

  # Vertical Value Grid Lines & X-Axis Ticks - fade in as the backdrop
  let gridAlpha = clamp(progress / 0.3f, 0.0f, 1.0f)
  for i in 0 ..< ticks:
    let tickVal = (niceMin + (i.float64 * tickSpacing)).float32
    let x = leftMargin + (((tickVal - niceMin.float32) / valRange) * chartW)
    if config.showYAxisLines:
      ctx.beginPath()
      ctx.moveTo(x, config.margin)
      ctx.lineTo(x, config.margin + chartH)
      ctx.strokeStyle = config.yAxisLinesColor.withAlpha(config.yAxisLinesColor.a * gridAlpha)
      ctx.lineWidth = 1.0f
      ctx.stroke()

    let tickStr = formatNiceNumber(tickVal, 2)
    drawTextAligned(ctx, font, tickStr, vec2(x, config.margin + chartH + 12.0f), config.yAxisTextColor.withAlpha(gridAlpha), CenterAlign, MiddleAlign)

  let slotH = (chartH - ((nbItems.float32 + 1.0f) * config.margin * 0.5f)) / nbItems.float32
  let nbSeries = seriesList.len.float32
  let barH = (slotH - ((nbSeries - 1.0f) * 2.0f)) / nbSeries

  font.size = config.valueLabelTextSize

  for i in 0 ..< nbItems:
    let slotY = config.margin + (i.float32 * (slotH + config.margin * 0.5f))
    let categoryLabel = firstSerie.entries[i].label
    font.size = config.labelTextSize
    drawTextAligned(ctx, font, categoryLabel, vec2(leftMargin - 10.0f, slotY + (slotH * 0.5f)), config.labelColor, RightAlign, MiddleAlign)

    font.size = config.valueLabelTextSize
    for sIdx in 0 ..< seriesList.len:
      let serie = seriesList[sIdx]
      if i >= serie.entries.len: continue
      let entry = serie.entries[i]
      if not entry.hasValue: continue

      let y = slotY + (sIdx.float32 * (barH + 2.0f))
      # Bars sweep in top-to-bottom (one row after another) rather than
      # all growing in perfect lockstep, which reads as much livelier.
      let progress = easeOutQuad(staggerProgress(i, nbItems, config.animationProgress, 0.65f))
      let targetX = leftMargin + (((entry.value - niceMin.float32) / valRange) * chartW)
      let currentX = originX + ((targetX - originX) * progress)

      let barX = min(originX, currentX)
      let barW = max(config.minBarHeight, abs(currentX - originX))
      let barColor = serie.color.get(entry.color)

      # Bar Area Background Track
      if config.barAreaAlpha > 0.0f:
        ctx.fillStyle = barColor.withAlpha(config.barAreaAlpha * progress)
        ctx.fillRect(leftMargin, y, chartW, barH)

      # Soft drop shadow underneath the bar
      if barW > 1.0f:
        ctx.fillStyle = color(0.0f, 0.0f, 0.0f, 0.14f * min(1.0f, progress * 2.0f))
        ctx.fillRect(barX + 1.5f, y + 2.5f, barW, barH)

      ctx.fillStyle = barColor
      if config.cornerRadius > 0.0f:
        let path = newPath()
        path.roundedRect(rect(barX, y, barW, barH), config.cornerRadius, config.cornerRadius)
        ctx.fillPath(path)
      else:
        ctx.fillRect(barX, y, barW, barH)

      # Subtle lighter sheen along the top of the bar
      let sheenH = min(barH * 0.4f, 6.0f)
      if sheenH > 1.5f:
        ctx.fillStyle = color(1.0f, 1.0f, 1.0f, 0.15f * min(1.0f, progress * 2.0f))
        ctx.fillRect(barX, y, barW, sheenH)

      if entry.valueLabel.len > 0:
        let valColor = entry.valueLabelColor.withAlpha(progress)
        let labelPos = vec2(barX + barW + 5.0f, y + (barH * 0.5f))
        drawTextAligned(ctx, font, entry.valueLabel, labelPos, valColor, LeftAlign, MiddleAlign)

  ctx.restore()

proc drawHorizontalBarChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  entries: openArray[ChartEntry],
  config: ChartConfig = defaultChartConfig()
) =
  drawHorizontalBarChart(ctx, font, bounds, [newChartSerie("Default", @entries)], config)
