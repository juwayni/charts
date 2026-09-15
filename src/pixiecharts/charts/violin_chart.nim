import std/[math]
import pixie
import ../types, ../helpers

proc drawViolinChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  violins: openArray[ViolinEntry],
  config: ChartConfig = defaultChartConfig()
) =
  if violins.len == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  var minVal = violins[0].minVal
  var maxVal = violins[0].maxVal
  for v in violins:
    if v.minVal < minVal: minVal = v.minVal
    if v.maxVal > maxVal: maxVal = v.maxVal

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

  # Y Grid Lines & Axis - this chart previously had no numeric reference
  # at all for reading violin values off the page; it now shares the same
  # boxplot-style axis, fading in first as the backdrop.
  let gridAlpha = clamp(progress / 0.3f, 0.0f, 1.0f)
  for i in 0 ..< config.yAxisMaxTicks:
    let tickVal = (niceMin + (i.float64 * tickSpacing)).float32
    let y = config.margin + chartH - (((tickVal - niceMin.float32) / valRange) * chartH)
    ctx.beginPath()
    ctx.moveTo(leftMargin, y)
    ctx.lineTo(leftMargin + chartW, y)
    ctx.strokeStyle = config.yAxisLinesColor.withAlpha(config.yAxisLinesColor.a * gridAlpha)
    ctx.lineWidth = 1.0f
    ctx.stroke()
    drawTextAligned(ctx, font, formatNiceNumber(tickVal), vec2(leftMargin - 8.0f, y), config.yAxisTextColor.withAlpha(gridAlpha), RightAlign, MiddleAlign)

  let count = violins.len.float32
  let slotW = chartW / count
  let maxViolinW = slotW * 0.40f

  proc valueToY(dataVal: float32): float32 =
    config.margin + chartH - (((dataVal - niceMin.float32) / valRange) * chartH)

  for i in 0 ..< violins.len:
    let v = violins[i]
    let cx = leftMargin + (i.float32 * slotW) + (slotW * 0.5f)
    let nPoints = v.densityY.len
    let localSpan = max(0.0001f, v.maxVal - v.minVal)

    # Each violin inflates outward from its centerline, staggered so
    # they don't all bloom at once.
    let itemT = easeOutBack(staggerProgress(i, violins.len, progress, 0.6f))
    let widthT = clamp(itemT, 0.0f, 1.1f)
    let alpha = min(1.0f, itemT)

    if nPoints >= 2 and itemT > 0.0f:
      let path = newPath()

      # `densityY` is a 0..1 fraction of this violin's own [minVal, maxVal]
      # span (not the shared chart axis), so it must be mapped into actual
      # data units and then through the SAME niceMin/valRange transform as
      # the quantile markers below - otherwise the silhouette wouldn't line
      # up with its own median/quartile line, and violins with different
      # ranges wouldn't be visually comparable on the shared axis.

      # Right silhouette
      for k in 0 ..< nPoints:
        let dataVal = v.minVal + (v.densityY[k] * localSpan)
        let y = valueToY(dataVal)
        let x = cx + (v.densityW[k] * maxViolinW * widthT)
        if k == 0: path.moveTo(x, y)
        else: path.lineTo(x, y)

      # Left silhouette backwards
      for k in countdown(nPoints - 1, 0):
        let dataVal = v.minVal + (v.densityY[k] * localSpan)
        let y = valueToY(dataVal)
        let x = cx - (v.densityW[k] * maxViolinW * widthT)
        path.lineTo(x, y)

      path.closePath()
      ctx.fillStyle = v.color.withAlpha(0.60f * alpha)
      ctx.fillPath(path)
      ctx.strokeStyle = v.color.withAlpha(alpha)
      ctx.lineWidth = 1.5f
      ctx.strokePath(path)

    # Central Quantile Marker Line (Q1 to Q3) - appears once the silhouette
    # has mostly finished inflating
    let markerT = clamp((itemT - 0.6f) / 0.4f, 0.0f, 1.0f)
    if markerT > 0.0f:
      let q1Y = valueToY(v.q1)
      let q3Y = valueToY(v.q3)
      let medY = valueToY(v.median)

      ctx.beginPath()
      ctx.moveTo(cx, q1Y)
      ctx.lineTo(cx, q3Y)
      ctx.strokeStyle = color(0, 0, 0, 0.85f * markerT)
      ctx.lineWidth = 5.0f
      ctx.stroke()

      # White Median Point
      ctx.fillStyle = color(1, 1, 1, markerT)
      ctx.beginPath()
      ctx.circle(cx, medY, 3.5f)
      ctx.fill()

    # Category label
    font.size = config.labelTextSize
    drawTextAligned(ctx, font, v.label, vec2(cx, bounds.h - (bottomMargin * 0.5f)), config.labelColor.withAlpha(alpha), CenterAlign, MiddleAlign)

  ctx.restore()
