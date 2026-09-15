import std/[math]
import pixie
import ../types, ../helpers

proc drawBubbleChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  bubbles: openArray[BubbleEntry],
  config: ChartConfig = defaultChartConfig()
) =
  if bubbles.len == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  var minX = bubbles[0].x
  var maxX = bubbles[0].x
  var minY = bubbles[0].y
  var maxY = bubbles[0].y
  for b in bubbles:
    if b.x < minX: minX = b.x
    if b.x > maxX: maxX = b.x
    if b.y < minY: minY = b.y
    if b.y > maxY: maxY = b.y

  if minX == maxX: maxX += 10.0f
  if minY == maxY: maxY += 10.0f

  var rangeX, niceMinX, niceMaxX, tickSpacingX: float64
  var rangeY, niceMinY, niceMaxY, tickSpacingY: float64
  calculateNiceScale(minX.float64, maxX.float64, 5, rangeX, tickSpacingX, niceMinX, niceMaxX)
  calculateNiceScale(minY.float64, maxY.float64, 5, rangeY, tickSpacingY, niceMinY, niceMaxY)

  let spanX = (niceMaxX - niceMinX).float32
  let spanY = (niceMaxY - niceMinY).float32

  font.size = config.labelTextSize
  let axisLabelW = measureNiceScaleLabelWidth(font, niceMinY, tickSpacingY, 5, config.labelTextSize)
  let leftMargin = config.margin + axisLabelW + 10.0f
  let bottomMargin = config.margin + config.labelTextSize + 10.0f
  let chartW = bounds.w - leftMargin - config.margin
  let chartH = bounds.h - config.margin - bottomMargin

  # Y Grid & Axis - fades in as the backdrop
  let progress = config.animationProgress
  let gridAlpha = clamp(progress / 0.3f, 0.0f, 1.0f)
  for i in 0 ..< 5:
    let v = (niceMinY + (i.float64 * tickSpacingY)).float32
    let y = config.margin + chartH - (((v - niceMinY.float32) / spanY) * chartH)
    ctx.beginPath()
    ctx.moveTo(leftMargin, y)
    ctx.lineTo(leftMargin + chartW, y)
    ctx.strokeStyle = config.yAxisLinesColor.withAlpha(config.yAxisLinesColor.a * gridAlpha)
    ctx.lineWidth = 1.0f
    ctx.stroke()
    drawTextAligned(ctx, font, formatNiceNumber(v), vec2(leftMargin - 8.0f, y), config.yAxisTextColor.withAlpha(gridAlpha), RightAlign, MiddleAlign)

  # X Grid & Axis
  for i in 0 ..< 5:
    let v = (niceMinX + (i.float64 * tickSpacingX)).float32
    let x = leftMargin + (((v - niceMinX.float32) / spanX) * chartW)
    ctx.beginPath()
    ctx.moveTo(x, config.margin)
    ctx.lineTo(x, config.margin + chartH)
    ctx.strokeStyle = config.yAxisLinesColor.withAlpha(config.yAxisLinesColor.a * gridAlpha)
    ctx.lineWidth = 1.0f
    ctx.stroke()
    drawTextAligned(ctx, font, formatNiceNumber(v), vec2(x, config.margin + chartH + 12.0f), config.yAxisTextColor.withAlpha(gridAlpha), CenterAlign, MiddleAlign)

  # Draw Bubbles - each pops in with a soft overshoot, staggered so they
  # don't all inflate in perfect unison.
  let n = bubbles.len
  for i in 0 ..< n:
    let b = bubbles[i]
    let itemT = easeOutBack(staggerProgress(i, n, progress, 0.55f))
    if itemT <= 0.0f: continue
    let cx = leftMargin + (((b.x - niceMinX.float32) / spanX) * chartW)
    let cy = config.margin + chartH - (((b.y - niceMinY.float32) / spanY) * chartH)
    let r = max(2.0f, b.radius * clamp(itemT, 0.0f, 1.12f))
    let alpha = min(1.0f, itemT)

    ctx.fillStyle = b.color.withAlpha(0.60f * alpha)
    ctx.beginPath()
    ctx.circle(cx, cy, r)
    ctx.fill()

    ctx.strokeStyle = b.color.withAlpha(alpha)
    ctx.lineWidth = 1.5f
    ctx.stroke()

    if b.label.len > 0:
      font.size = config.labelTextSize * 0.80f
      drawTextAligned(ctx, font, b.label, vec2(cx, cy), color(1, 1, 1, alpha), CenterAlign, MiddleAlign)

  ctx.restore()
