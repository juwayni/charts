import std/[math]
import pixie
import ../types, ../helpers

proc drawLollipopChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  entries: openArray[LollipopEntry],
  config: ChartConfig = defaultChartConfig(),
  nodeRadius: float32 = 7.0f
) =
  if entries.len == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  var minVal = 0.0f
  var maxVal = entries[0].value
  for e in entries:
    if e.value < minVal: minVal = e.value
    if e.value > maxVal: maxVal = e.value

  var range, niceMin, niceMax, tickSpacing: float64
  calculateNiceScale(minVal.float64, maxVal.float64, config.yAxisMaxTicks, range, tickSpacing, niceMin, niceMax)
  let valRange = max(1.0f, (niceMax - niceMin).float32)

  font.size = config.labelTextSize
  let footerH = config.labelTextSize + (config.margin * 1.5f)
  let headerH = config.margin + nodeRadius + 10.0f
  let chartW = bounds.w - (config.margin * 2.0f)
  let chartH = bounds.h - footerH - headerH
  let origin = headerH + chartH - (((0.0f - niceMin.float32) / valRange) * chartH)

  let nbItems = entries.len.float32
  let slotW = chartW / nbItems

  # 0-Baseline
  ctx.beginPath()
  ctx.moveTo(config.margin, origin)
  ctx.lineTo(config.margin + chartW, origin)
  ctx.strokeStyle = config.yAxisLinesColor
  ctx.lineWidth = 1.0f
  ctx.stroke()

  for i in 0 ..< entries.len:
    let e = entries[i]
    let cx = config.margin + (i.float32 * slotW) + (slotW * 0.5f)
    let targetY = headerH + chartH - (((e.value - niceMin.float32) / valRange) * chartH)
    let itemT = staggerProgress(i, entries.len, config.animationProgress, 0.6f)
    let stemT = easeOutQuad(itemT)
    let currentY = origin + ((targetY - origin) * stemT)
    let popT = easeOutBack(clamp(itemT / 0.6f, 0.0f, 1.0f))
    let alpha = min(1.0f, itemT * 2.0f)

    # Vertical Stem
    ctx.beginPath()
    ctx.moveTo(cx, origin)
    ctx.lineTo(cx, currentY)
    ctx.strokeStyle = e.stemColor.withAlpha(alpha)
    ctx.lineWidth = 2.0f
    ctx.stroke()

    # Head Node - pops in with a gentle overshoot as the stem lands
    let nodeR = nodeRadius * clamp(popT, 0.0f, 1.15f)
    if nodeR > 0.5f:
      ctx.fillStyle = color(0.0f, 0.0f, 0.0f, 0.16f * alpha)
      ctx.beginPath()
      ctx.circle(cx + 1.0f, currentY + 2.0f, nodeR)
      ctx.fill()

    ctx.fillStyle = e.color.withAlpha(alpha)
    ctx.beginPath()
    ctx.circle(cx, currentY, nodeR)
    ctx.fill()
    ctx.strokeStyle = color(1, 1, 1, alpha)
    ctx.lineWidth = 2.0f
    ctx.stroke()

    # Category label
    drawTextAligned(ctx, font, e.label, vec2(cx, bounds.h - (footerH * 0.5f)), config.labelColor.withAlpha(alpha), CenterAlign, MiddleAlign)

    # Value tag
    let valStr = if e.valueLabel.len > 0: e.valueLabel else: formatNiceNumber(e.value)
    let valY = if e.value >= 0.0f: currentY - nodeRadius - 6.0f else: currentY + nodeRadius + 10.0f
    font.size = config.valueLabelTextSize * 0.85f
    drawTextAligned(ctx, font, valStr, vec2(cx, valY), e.color.withAlpha(alpha), CenterAlign, MiddleAlign)
    font.size = config.labelTextSize

  ctx.restore()
