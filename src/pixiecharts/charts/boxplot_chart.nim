import std/[math]
import pixie
import ../types, ../helpers

proc drawBoxPlotChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  boxPlots: openArray[BoxPlotEntry],
  config: ChartConfig = defaultChartConfig()
) =
  if boxPlots.len == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  var minVal = boxPlots[0].minVal
  var maxVal = boxPlots[0].maxVal
  for b in boxPlots:
    if b.minVal < minVal: minVal = b.minVal
    if b.maxVal > maxVal: maxVal = b.maxVal
    for o in b.outliers:
      if o < minVal: minVal = o
      if o > maxVal: maxVal = o

  var range, niceMin, niceMax, tickSpacing: float64
  calculateNiceScale(minVal.float64, maxVal.float64, config.yAxisMaxTicks, range, tickSpacing, niceMin, niceMax)
  let valRange = max(1.0f, (niceMax - niceMin).float32)

  font.size = config.labelTextSize
  let axisLabelW = measureNiceScaleLabelWidth(font, niceMin, tickSpacing, config.yAxisMaxTicks, config.labelTextSize)
  let leftMargin = config.margin + axisLabelW + 10.0f
  let bottomMargin = config.margin + config.labelTextSize + 10.0f
  let chartW = bounds.w - leftMargin - config.margin
  let chartH = bounds.h - config.margin - bottomMargin
  let progress = config.animationProgress

  # Y Grid Lines & Values (fade in first, they're the "stage")
  let gridAlpha = clamp(progress / 0.35f, 0.0f, 1.0f)
  for i in 0 ..< config.yAxisMaxTicks:
    let tickVal = (niceMin + (i.float64 * tickSpacing)).float32
    let y = config.margin + chartH - (((tickVal - niceMin.float32) / valRange) * chartH)
    ctx.beginPath()
    ctx.moveTo(leftMargin, y)
    ctx.lineTo(leftMargin + chartW, y)
    ctx.strokeStyle = config.yAxisLinesColor.withAlpha(config.yAxisLinesColor.a * gridAlpha)
    ctx.lineWidth = 1.0f
    ctx.stroke()
    drawTextAligned(ctx, font, formatNiceNumber(tickVal), vec2(leftMargin - 8.0f, y),
      config.yAxisTextColor.withAlpha(gridAlpha), RightAlign, MiddleAlign)

  let count = boxPlots.len.float32
  let slotW = chartW / count
  let boxW = slotW * 0.50f

  for i in 0 ..< boxPlots.len:
    let b = boxPlots[i]
    # Each box/whisker animates in with a short delay after the previous one,
    # growing outward from its own median line and popping gently into place.
    let itemT = easeOutBack(staggerProgress(i, boxPlots.len, progress, 0.7f))
    let fadeT = clamp(itemT, 0.0f, 1.0f)
    let cx = leftMargin + (i.float32 * slotW) + (slotW * 0.5f)

    let minY = config.margin + chartH - (((b.minVal - niceMin.float32) / valRange) * chartH)
    let q1Y = config.margin + chartH - (((b.q1 - niceMin.float32) / valRange) * chartH)
    let medY = config.margin + chartH - (((b.median - niceMin.float32) / valRange) * chartH)
    let q3Y = config.margin + chartH - (((b.q3 - niceMin.float32) / valRange) * chartH)
    let maxY = config.margin + chartH - (((b.maxVal - niceMin.float32) / valRange) * chartH)

    # Whiskers and box grow outward from the median line as itemT -> 1
    let animQ1Y = lerp(medY, q1Y, itemT)
    let animQ3Y = lerp(medY, q3Y, itemT)
    let animMinY = lerp(medY, minY, itemT)
    let animMaxY = lerp(medY, maxY, itemT)

    # Lower & Upper Whiskers
    ctx.beginPath()
    ctx.moveTo(cx, animQ1Y)
    ctx.lineTo(cx, animMinY)
    ctx.moveTo(cx - (boxW * 0.25f), animMinY)
    ctx.lineTo(cx + (boxW * 0.25f), animMinY)

    ctx.moveTo(cx, animQ3Y)
    ctx.lineTo(cx, animMaxY)
    ctx.moveTo(cx - (boxW * 0.25f), animMaxY)
    ctx.lineTo(cx + (boxW * 0.25f), animMaxY)
    ctx.strokeStyle = color(0.2f, 0.2f, 0.2f, fadeT)
    ctx.lineWidth = 1.5f
    ctx.stroke()

    # Interquartile Box (with a subtle shadow for depth)
    let rectTop = min(animQ1Y, animQ3Y)
    let rectH = max(0.5f, abs(animQ1Y - animQ3Y))
    let boxRect = rect(cx - (boxW * 0.5f), rectTop, boxW, rectH)

    ctx.fillStyle = color(0.0f, 0.0f, 0.0f, 0.10f * fadeT)
    ctx.fillRect(boxRect.x + 1.5f, boxRect.y + 2.0f, boxRect.w, boxRect.h)

    ctx.fillStyle = b.color.withAlpha(0.68f * fadeT)
    ctx.fillRect(boxRect.x, boxRect.y, boxRect.w, boxRect.h)
    ctx.strokeStyle = b.color.withAlpha(fadeT)
    ctx.lineWidth = 2.0f
    ctx.strokeRect(boxRect)

    # Median Divider
    ctx.beginPath()
    ctx.moveTo(cx - (boxW * 0.5f), medY)
    ctx.lineTo(cx + (boxW * 0.5f), medY)
    ctx.strokeStyle = color(0.85f, 0.16f, 0.16f, fadeT)
    ctx.lineWidth = 2.5f
    ctx.stroke()

    # Outlier Dots - pop in last, after the box has mostly settled
    let outlierT = easeOutBack(staggerProgress(2, 3, itemT, 0.5f))
    for o in b.outliers:
      let oy = config.margin + chartH - (((o - niceMin.float32) / valRange) * chartH)
      ctx.fillStyle = color(0.9f, 0.1f, 0.1f, 0.85f * outlierT)
      ctx.beginPath()
      ctx.circle(cx, oy, 3.5f * max(0.0f, outlierT))
      ctx.fill()

    # Group Label
    drawTextAligned(ctx, font, b.label, vec2(cx, bounds.h - (bottomMargin * 0.5f)),
      config.labelColor.withAlpha(fadeT), CenterAlign, MiddleAlign)

  ctx.restore()
