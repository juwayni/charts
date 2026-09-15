import std/[math]
import pixie
import ../types, ../helpers

proc drawLikertChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  responses: openArray[LikertResponse],
  config: ChartConfig = defaultChartConfig(),
  palette: array[5, Color] = [
    color(0.85f, 0.24f, 0.20f, 1.0f), # Strongly Disagree
    color(0.94f, 0.60f, 0.56f, 1.0f), # Disagree
    color(0.82f, 0.82f, 0.82f, 1.0f), # Neutral
    color(0.55f, 0.78f, 0.90f, 1.0f), # Agree
    color(0.18f, 0.53f, 0.82f, 1.0f)  # Strongly Agree
  ]
) =
  let count = responses.len
  if count == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  font.size = config.labelTextSize
  var maxQWidth = 0.0f
  for r in responses:
    let w = font.measureTextSize(r.question).x
    if w > maxQWidth: maxQWidth = w

  let leftMargin = config.margin + maxQWidth + 15.0f
  let chartW = bounds.w - leftMargin - config.margin
  let chartH = bounds.h - (config.margin * 2.0f)
  let rowH = chartH / count.float32
  let barH = rowH * 0.50f
  let midX = leftMargin + (chartW * 0.5f)
  let progress = config.animationProgress

  # Central Divergence Axis
  ctx.beginPath()
  ctx.moveTo(midX, config.margin)
  ctx.lineTo(midX, config.margin + chartH)
  ctx.strokeStyle = config.yAxisLinesColor
  ctx.lineWidth = 1.5f
  ctx.stroke()

  for i in 0 ..< count:
    let r = responses[i]
    let y = config.margin + (i.float32 * rowH) + (rowH * 0.5f) - (barH * 0.5f)
    # Rows sweep in top-to-bottom, each growing outward from the central axis.
    let rowT = easeOutQuad(staggerProgress(i, count, progress, 0.65f))
    let rowAlpha = min(1.0f, rowT * 1.5f)

    drawTextAligned(ctx, font, r.question, vec2(leftMargin - 10.0f, y + (barH * 0.5f)), config.labelColor.withAlpha(rowAlpha), RightAlign, MiddleAlign)

    let total = r.counts[0] + r.counts[1] + r.counts[2] + r.counts[3] + r.counts[4]
    if total <= 0.0f: continue

    let scale = ((chartW * 0.45f) / total) * rowT

    # Leftward bars (SD, D, 1/2 N)
    let leftHalfNeutral = r.counts[2] * 0.5f * scale
    let leftD = r.counts[1] * scale
    let leftSD = r.counts[0] * scale

    ctx.fillStyle = palette[2].withAlpha(rowAlpha)
    ctx.fillRect(midX - leftHalfNeutral, y, leftHalfNeutral, barH)
    ctx.fillStyle = palette[1].withAlpha(rowAlpha)
    ctx.fillRect(midX - leftHalfNeutral - leftD, y, leftD, barH)
    ctx.fillStyle = palette[0].withAlpha(rowAlpha)
    ctx.fillRect(midX - leftHalfNeutral - leftD - leftSD, y, leftSD, barH)

    # Rightward bars (1/2 N, A, SA)
    let rightHalfNeutral = r.counts[2] * 0.5f * scale
    let rightA = r.counts[3] * scale
    let rightSA = r.counts[4] * scale

    ctx.fillStyle = palette[2].withAlpha(rowAlpha)
    ctx.fillRect(midX, y, rightHalfNeutral, barH)
    ctx.fillStyle = palette[3].withAlpha(rowAlpha)
    ctx.fillRect(midX + rightHalfNeutral, y, rightA, barH)
    ctx.fillStyle = palette[4].withAlpha(rowAlpha)
    ctx.fillRect(midX + rightHalfNeutral + rightA, y, rightSA, barH)

  ctx.restore()
