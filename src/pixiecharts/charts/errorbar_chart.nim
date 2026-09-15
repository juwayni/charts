import std/[math]
import pixie
import ../types, ../helpers

proc drawErrorBarChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  entries: openArray[ErrorBarEntry],
  config: ChartConfig = defaultChartConfig(),
  capWidth: float32 = 12.0f
) =
  let count = entries.len
  if count == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  var minVal = entries[0].meanVal - entries[0].errorLow
  var maxVal = entries[0].meanVal + entries[0].errorHigh
  for e in entries:
    if (e.meanVal - e.errorLow) < minVal: minVal = e.meanVal - e.errorLow
    if (e.meanVal + e.errorHigh) > maxVal: maxVal = e.meanVal + e.errorHigh

  var range, niceMin, niceMax, tickSpacing: float64
  calculateNiceScale(minVal.float64, maxVal.float64, config.yAxisMaxTicks, range, tickSpacing, niceMin, niceMax)
  let valRange = max(1.0f, (niceMax - niceMin).float32)

  let leftMargin = config.margin + measureNiceScaleLabelWidth(font, niceMin, tickSpacing, config.yAxisMaxTicks, config.labelTextSize) + 10.0f
  let bottomMargin = config.margin + config.labelTextSize + 15.0f
  let chartW = bounds.w - leftMargin - config.margin
  let chartH = bounds.h - config.margin - bottomMargin
  let slotW = chartW / count.float32

  # Y Grid Lines & Axis
  for i in 0 ..< config.yAxisMaxTicks:
    let tickVal = (niceMin + (i.float64 * tickSpacing)).float32
    let y = config.margin + chartH - (((tickVal - niceMin.float32) / valRange) * chartH)
    ctx.beginPath()
    ctx.moveTo(leftMargin, y)
    ctx.lineTo(leftMargin + chartW, y)
    ctx.strokeStyle = config.yAxisLinesColor
    ctx.lineWidth = 1.0f
    ctx.stroke()
    drawTextAligned(ctx, font, formatNiceNumber(tickVal), vec2(leftMargin - 8.0f, y), config.yAxisTextColor, RightAlign, MiddleAlign)

  for i in 0 ..< count:
    let e = entries[i]
    let cx = leftMargin + (i.float32 * slotW) + (slotW * 0.5f)
    let meanY = config.margin + chartH - (((e.meanVal - niceMin.float32) / valRange) * chartH)

    # Each error bar sweeps in one after another; the whiskers extend
    # outward from the mean, then the mean node pops on top last.
    let itemT = easeOutQuad(staggerProgress(i, count, config.animationProgress, 0.6f))
    let nodeT = easeOutBack(clamp((itemT - 0.5f) / 0.5f, 0.0f, 1.0f))
    let alpha = min(1.0f, itemT * 2.0f)

    let lowY = config.margin + chartH - ((((e.meanVal - e.errorLow * itemT) - niceMin.float32) / valRange) * chartH)
    let highY = config.margin + chartH - ((((e.meanVal + e.errorHigh * itemT) - niceMin.float32) / valRange) * chartH)

    # Whisker Shaft
    ctx.beginPath()
    ctx.moveTo(cx, lowY)
    ctx.lineTo(cx, highY)
    ctx.strokeStyle = color(0.2f, 0.2f, 0.2f, alpha)
    ctx.lineWidth = 2.0f
    ctx.stroke()

    # Upper and Lower Caps
    ctx.beginPath()
    ctx.moveTo(cx - (capWidth * 0.5f), highY)
    ctx.lineTo(cx + (capWidth * 0.5f), highY)
    ctx.moveTo(cx - (capWidth * 0.5f), lowY)
    ctx.lineTo(cx + (capWidth * 0.5f), lowY)
    ctx.strokeStyle = color(0.2f, 0.2f, 0.2f, alpha)
    ctx.stroke()

    # Mean Value Node - pops in once the whiskers have mostly extended
    if nodeT > 0.0f:
      ctx.fillStyle = e.color.withAlpha(min(1.0f, nodeT))
      ctx.beginPath()
      ctx.circle(cx, meanY, 5.0f * clamp(nodeT, 0.0f, 1.15f))
      ctx.fill()
      ctx.strokeStyle = color(1, 1, 1, min(1.0f, nodeT))
      ctx.lineWidth = 1.5f
      ctx.stroke()

    # Category Label
    font.size = config.labelTextSize
    drawTextAligned(ctx, font, e.label, vec2(cx, bounds.h - (bottomMargin * 0.5f)), config.labelColor.withAlpha(alpha), CenterAlign, MiddleAlign)

  ctx.restore()
