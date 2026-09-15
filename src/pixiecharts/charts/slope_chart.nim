import std/[math, options]
import pixie
import ../types, ../helpers

proc drawSlopeChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  items: openArray[SlopeItem],
  config: ChartConfig = defaultChartConfig(),
  startPeriodLabel: string = "2024",
  endPeriodLabel: string = "2026"
) =
  let count = items.len
  if count == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  var minVal = items[0].startVal
  var maxVal = items[0].startVal
  for it in items:
    if it.startVal < minVal: minVal = it.startVal
    if it.endVal < minVal: minVal = it.endVal
    if it.startVal > maxVal: maxVal = it.startVal
    if it.endVal > maxVal: maxVal = it.endVal

  let valRange = max(1.0f, maxVal - minVal)
  let topMargin = config.margin + 30.0f
  let bottomMargin = config.margin + 20.0f
  let chartH = bounds.h - topMargin - bottomMargin
  let leftAxisX = bounds.w * 0.32f
  let rightAxisX = bounds.w * 0.68f
  let progress = config.animationProgress

  # Period Titles
  let headerAlpha = clamp(progress / 0.3f, 0.0f, 1.0f)
  font.size = config.labelTextSize
  drawTextAligned(ctx, font, startPeriodLabel, vec2(leftAxisX, topMargin - 15.0f), config.labelColor.withAlpha(headerAlpha), CenterAlign, BottomAlign)
  drawTextAligned(ctx, font, endPeriodLabel, vec2(rightAxisX, topMargin - 15.0f), config.labelColor.withAlpha(headerAlpha), CenterAlign, BottomAlign)

  # 1. Connecting Slopes - each line draws left-to-right, staggered so
  # they don't all move in perfect lockstep, with endpoints popping in
  # as the line reaches them.
  for i in 0 ..< count:
    let it = items[i]
    let itemT = staggerProgress(i, count, progress, 0.65f)
    let drawT = easeOutQuad(itemT)

    let y0 = topMargin + chartH - (((it.startVal - minVal) / valRange) * chartH)
    let targetY1 = topMargin + chartH - (((it.endVal - minVal) / valRange) * chartH)
    let y1 = y0 + ((targetY1 - y0) * drawT)
    let x1 = leftAxisX + ((rightAxisX - leftAxisX) * drawT)

    let isUp = it.endVal >= it.startVal
    let defaultCol = if isUp: color(0.18f, 0.80f, 0.44f, 1.0f) else: color(0.91f, 0.30f, 0.24f, 1.0f)
    let col = it.color.get(defaultCol)
    let alpha = min(1.0f, itemT * 2.0f)

    ctx.beginPath()
    ctx.moveTo(leftAxisX, y0)
    ctx.lineTo(x1, y1)
    ctx.strokeStyle = col.withAlpha(alpha)
    ctx.lineWidth = 2.0f
    ctx.stroke()

    # Left Endpoint Dot (pops in immediately as the row starts)
    let leftDotT = easeOutBack(clamp(itemT / 0.2f, 0.0f, 1.0f))
    ctx.fillStyle = col.withAlpha(min(1.0f, leftDotT))
    ctx.beginPath()
    ctx.circle(leftAxisX, y0, 4.0f * clamp(leftDotT, 0.0f, 1.15f))
    ctx.fill()

    # Right Endpoint Dot (pops in once the line has arrived)
    let rightDotT = easeOutBack(clamp((itemT - 0.75f) / 0.25f, 0.0f, 1.0f))
    if rightDotT > 0.0f:
      ctx.fillStyle = col.withAlpha(min(1.0f, rightDotT))
      ctx.beginPath()
      ctx.circle(rightAxisX, targetY1, 4.0f * clamp(rightDotT, 0.0f, 1.15f))
      ctx.fill()

    # Direct Annotation Labels
    font.size = config.labelTextSize * 0.80f
    let textLeft = it.label & " " & formatNiceNumber(it.startVal)
    let textRight = formatNiceNumber(it.endVal) & " " & it.label
    drawTextAligned(ctx, font, textLeft, vec2(leftAxisX - 8.0f, y0), config.labelColor.withAlpha(min(1.0f, leftDotT)), RightAlign, MiddleAlign)
    if rightDotT > 0.0f:
      drawTextAligned(ctx, font, textRight, vec2(rightAxisX + 8.0f, targetY1), config.labelColor.withAlpha(min(1.0f, rightDotT)), LeftAlign, MiddleAlign)

  ctx.restore()
