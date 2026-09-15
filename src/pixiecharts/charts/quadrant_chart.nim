import std/[math]
import pixie
import ../types, ../helpers

proc drawQuadrantChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  data: QuadrantData,
  config: ChartConfig = defaultChartConfig()
) =
  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  let chartX = config.margin + 30.0f
  let chartY = config.margin + 20.0f
  let chartW = bounds.w - chartX - config.margin
  let chartH = bounds.h - chartY - config.margin - 25.0f
  let progress = config.animationProgress

  let midX = chartX + (chartW * 0.5f)
  let midY = chartY + (chartH * 0.5f)

  # 1. Subtle Quadrant Tint Fills - fade in first as the "stage"
  let stageT = clamp(progress / 0.35f, 0.0f, 1.0f)
  ctx.fillStyle = color(0.18f, 0.80f, 0.44f, 0.08f * stageT) # Q1: Top-Right
  ctx.fillRect(midX, chartY, chartW * 0.5f, chartH * 0.5f)
  ctx.fillStyle = color(0.18f, 0.53f, 0.82f, 0.08f * stageT) # Q2: Top-Left
  ctx.fillRect(chartX, chartY, chartW * 0.5f, chartH * 0.5f)
  ctx.fillStyle = color(0.91f, 0.30f, 0.24f, 0.08f * stageT) # Q3: Bottom-Left
  ctx.fillRect(chartX, midY, chartW * 0.5f, chartH * 0.5f)
  ctx.fillStyle = color(0.95f, 0.77f, 0.06f, 0.08f * stageT) # Q4: Bottom-Right
  ctx.fillRect(midX, midY, chartW * 0.5f, chartH * 0.5f)

  # 2. Quadrant Watermark Titles
  font.size = 14.0f
  drawTextAligned(ctx, font, data.quadLabels[0], vec2(chartX + chartW - 12.0f, chartY + 14.0f), color(0.4f, 0.4f, 0.4f, 0.5f * stageT), RightAlign, TopAlign)
  drawTextAligned(ctx, font, data.quadLabels[1], vec2(chartX + 12.0f, chartY + 14.0f), color(0.4f, 0.4f, 0.4f, 0.5f * stageT), LeftAlign, TopAlign)
  drawTextAligned(ctx, font, data.quadLabels[2], vec2(chartX + 12.0f, chartY + chartH - 14.0f), color(0.4f, 0.4f, 0.4f, 0.5f * stageT), LeftAlign, BottomAlign)
  drawTextAligned(ctx, font, data.quadLabels[3], vec2(chartX + chartW - 12.0f, chartY + chartH - 14.0f), color(0.4f, 0.4f, 0.4f, 0.5f * stageT), RightAlign, BottomAlign)

  # 3. Crosshairs grow outward from the center as the stage settles in
  let crossT = easeOutQuad(clamp((progress - 0.1f) / 0.3f, 0.0f, 1.0f))
  ctx.beginPath()
  ctx.moveTo(midX, midY - ((midY - chartY) * crossT))
  ctx.lineTo(midX, midY + ((chartY + chartH - midY) * crossT))
  ctx.moveTo(midX - ((midX - chartX) * crossT), midY)
  ctx.lineTo(midX + ((chartX + chartW - midX) * crossT), midY)
  ctx.strokeStyle = config.yAxisLinesColor
  ctx.lineWidth = 1.5f
  ctx.stroke()

  # 4. Data Points & Labels - pop in one by one with a satisfying overshoot
  let spanX = max(0.001f, data.maxX - data.minX)
  let spanY = max(0.001f, data.maxY - data.minY)
  let n = data.items.len

  for i in 0 ..< n:
    let it = data.items[i]
    let itemT = easeOutBack(staggerProgress(i, n, progress, 0.55f))
    if itemT <= 0.0f:
      continue
    let px = chartX + (((it.x - data.minX) / spanX) * chartW)
    let py = chartY + chartH - (((it.y - data.minY) / spanY) * chartH)
    let r = it.size * clamp(itemT, 0.0f, 1.15f)
    let a = min(1.0f, itemT)

    # soft drop shadow for a bit of depth
    ctx.fillStyle = color(0.0f, 0.0f, 0.0f, 0.12f * a)
    ctx.beginPath()
    ctx.circle(px + 1.0f, py + 2.0f, r)
    ctx.fill()

    ctx.fillStyle = it.color.withAlpha(a)
    ctx.beginPath()
    ctx.circle(px, py, r)
    ctx.fill()
    ctx.strokeStyle = color(1, 1, 1, a)
    ctx.lineWidth = 1.5f
    ctx.stroke()

    font.size = 11.0f
    drawTextAligned(ctx, font, it.label, vec2(px, py - it.size - 4.0f), config.labelColor.withAlpha(a), CenterAlign, BottomAlign)

  ctx.restore()
