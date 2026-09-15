import std/[math]
import pixie
import ../types, ../helpers

proc drawFunnelChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  stages: openArray[FunnelEntry],
  config: ChartConfig = defaultChartConfig()
) =
  let n = stages.len
  if n == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  let maxVal = stages[0].value
  let chartW = bounds.w - (config.margin * 2.0f)
  let chartH = bounds.h - (config.margin * 2.0f)
  let stageH = chartH / n.float32
  let centerX = bounds.w * 0.5f
  let progress = config.animationProgress

  for i in 0 ..< n:
    let stage = stages[i]
    let topVal = stage.value
    let nextVal = if i < n - 1: stages[i + 1].value else: stage.value * 0.65f

    # Stages funnel in top-to-bottom, one after another, each widening
    # outward from the centerline with a soft overshoot.
    let itemT = easeOutBack(staggerProgress(i, n, progress, 0.6f))
    let scale = clamp(itemT, 0.0f, 1.08f)
    let alpha = min(1.0f, itemT)

    let topW = (topVal / maxVal) * chartW * scale
    let botW = (nextVal / maxVal) * chartW * scale
    let y0 = config.margin + (i.float32 * stageH)
    let y1 = y0 + stageH - 3.0f

    if itemT > 0.0f:
      let p = newPath()
      p.moveTo(centerX - (topW * 0.5f), y0)
      p.lineTo(centerX + (topW * 0.5f), y0)
      p.lineTo(centerX + (botW * 0.5f), y1)
      p.lineTo(centerX - (botW * 0.5f), y1)
      p.closePath()

      ctx.fillStyle = stage.color.withAlpha(stage.color.a * alpha)
      ctx.fillPath(p)

    # Stage Labels & Values
    font.size = config.labelTextSize
    let midY = (y0 + y1) * 0.5f
    let labelText = stage.label & ": " & (if stage.valueLabel.len > 0: stage.valueLabel else: $stage.value)
    drawTextAligned(ctx, font, labelText, vec2(centerX, midY), color(1, 1, 1, alpha), CenterAlign, MiddleAlign)

    # Conversion Percentage Tag
    if i > 0:
      let convRate = (stage.value / stages[i - 1].value) * 100.0f
      font.size = config.labelTextSize * 0.75f
      drawTextAligned(ctx, font, formatNiceNumber(convRate) & "%", vec2(centerX + (topW * 0.5f) + 8.0f, y0), config.labelColor.withAlpha(alpha), LeftAlign, MiddleAlign)

  ctx.restore()
