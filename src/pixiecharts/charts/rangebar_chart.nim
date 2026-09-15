import std/[math]
import pixie
import ../types, ../helpers

proc drawRangeBarChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  entries: openArray[RangeBarEntry],
  config: ChartConfig = defaultChartConfig()
) =
  let count = entries.len
  if count == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  var minVal = entries[0].minVal
  var maxVal = entries[0].maxVal
  for e in entries:
    if e.minVal < minVal: minVal = e.minVal
    if e.maxVal > maxVal: maxVal = e.maxVal

  var range, niceMin, niceMax, tickSpacing: float64
  calculateNiceScale(minVal.float64, maxVal.float64, config.yAxisMaxTicks, range, tickSpacing, niceMin, niceMax)
  let valRange = max(1.0f, (niceMax - niceMin).float32)

  font.size = config.labelTextSize
  var maxLabelW = 0.0f
  for e in entries:
    let w = font.measureTextSize(e.label).x
    if w > maxLabelW: maxLabelW = w

  let leftMargin = config.margin + maxLabelW + 15.0f
  let bottomMargin = config.margin + config.labelTextSize + 10.0f
  let chartW = bounds.w - leftMargin - config.margin
  let chartH = bounds.h - config.margin - bottomMargin
  let slotH = chartH / count.float32
  let barH = max(4.0f, slotH * 0.50f)
  let progress = config.animationProgress

  # Vertical X-Axis Ticks - fade in first as the stage
  let gridAlpha = clamp(progress / 0.3f, 0.0f, 1.0f)
  for i in 0 ..< config.yAxisMaxTicks:
    let tickVal = (niceMin + (i.float64 * tickSpacing)).float32
    let x = leftMargin + (((tickVal - niceMin.float32) / valRange) * chartW)
    ctx.beginPath()
    ctx.moveTo(x, config.margin)
    ctx.lineTo(x, config.margin + chartH)
    ctx.strokeStyle = config.yAxisLinesColor.withAlpha(config.yAxisLinesColor.a * gridAlpha)
    ctx.lineWidth = 1.0f
    ctx.stroke()
    drawTextAligned(ctx, font, formatNiceNumber(tickVal), vec2(x, config.margin + chartH + 12.0f), config.yAxisTextColor.withAlpha(gridAlpha), CenterAlign, MiddleAlign)

  # Draw Floating Bars - each row sweeps in top-to-bottom, growing
  # outward from its minimum value with a gentle overshoot.
  for i in 0 ..< count:
    let e = entries[i]
    let y = config.margin + (i.float32 * slotH) + (slotH * 0.5f) - (barH * 0.5f)
    let itemT = easeOutBack(staggerProgress(i, count, progress, 0.6f))
    let alpha = min(1.0f, itemT)

    let x0 = leftMargin + (((e.minVal - niceMin.float32) / valRange) * chartW)
    let targetX1 = leftMargin + (((e.maxVal - niceMin.float32) / valRange) * chartW)
    let currentX1 = x0 + ((targetX1 - x0) * clamp(itemT, 0.0f, 1.0f))
    let barW = max(2.0f, currentX1 - x0)

    if itemT > 0.0f:
      ctx.fillStyle = color(0.0f, 0.0f, 0.0f, 0.14f * alpha)
      ctx.fillRect(x0 + 1.5f, y + 2.5f, barW, barH)

      let p = newPath()
      p.roundedRect(rect(x0, y, barW, barH), 3.0f, 3.0f)
      ctx.fillStyle = e.color.withAlpha(alpha)
      ctx.fillPath(p)

      let sheenH = min(barH * 0.4f, 6.0f)
      if sheenH > 1.5f:
        ctx.fillStyle = color(1.0f, 1.0f, 1.0f, 0.16f * alpha)
        ctx.fillRect(x0, y, barW, sheenH)

    # Category and Min/Max Endpoint Values
    drawTextAligned(ctx, font, e.label, vec2(leftMargin - 10.0f, y + (barH * 0.5f)), config.labelColor.withAlpha(alpha), RightAlign, MiddleAlign)
    font.size = config.labelTextSize * 0.80f
    drawTextAligned(ctx, font, formatNiceNumber(e.minVal), vec2(x0 - 5.0f, y + (barH * 0.5f)), config.labelColor.withAlpha(alpha), RightAlign, MiddleAlign)
    if itemT > 0.05f:
      drawTextAligned(ctx, font, formatNiceNumber(e.maxVal), vec2(currentX1 + 5.0f, y + (barH * 0.5f)), config.labelColor.withAlpha(alpha), LeftAlign, MiddleAlign)
    font.size = config.labelTextSize

  ctx.restore()
