import std/[math]
import pixie
import ../types, ../helpers

proc drawSemiCircleMeter*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  data: SemiCircleMeterData,
  config: ChartConfig = defaultChartConfig()
) =
  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  let center = vec2(bounds.w * 0.5f, bounds.h * 0.70f)
  let radius = min(bounds.w * 0.45f, bounds.h * 0.55f)
  let strokeW = radius * 0.22f
  let startA = PI
  let sweepA = PI

  ctx.lineCap = RoundCap

  # 1. 180° Background Arch Track
  ctx.beginPath()
  ctx.arc(center.x, center.y, radius, startA, startA + sweepA, false)
  ctx.strokeStyle = data.trackColor
  ctx.lineWidth = strokeW
  ctx.stroke()

  # 2. Foreground Progress Arc - eases with a soft spring settle rather
  # than a linear sweep, like a real needle easing into place.
  let animT = easeOutCubic(config.animationProgress)
  let ratio = clamp(data.value / max(0.001f, data.maxVal), 0.0f, 1.0f)
  let activeSweep = ratio * PI * animT
  if activeSweep > 0.01f:
    ctx.beginPath()
    ctx.arc(center.x, center.y, radius, startA, startA + activeSweep, false)
    ctx.strokeStyle = data.barColor
    ctx.lineWidth = strokeW
    ctx.stroke()
    # small glowing tip at the end of the arc
    let tipAngle = startA + activeSweep
    ctx.fillStyle = data.barColor
    ctx.beginPath()
    ctx.circle(center.x + (radius * cos(tipAngle)), center.y + (radius * sin(tipAngle)), strokeW * 0.4f)
    ctx.fill()

  # 3. Center Digital Readout & Units - counts up alongside the arc
  font.size = radius * 0.40f
  let displayVal = data.value * animT
  let valStr = formatNiceNumber(displayVal) & " " & data.unit
  drawTextAligned(ctx, font, valStr, vec2(center.x, center.y - 10.0f), config.labelColor.withAlpha(clamp(config.animationProgress * 2.0f, 0.0f, 1.0f)), CenterAlign, BottomAlign)

  font.size = radius * 0.22f
  drawTextAligned(ctx, font, data.label, vec2(center.x, center.y + 12.0f), color(0.55f, 0.55f, 0.55f, 1.0f), CenterAlign, TopAlign)

  ctx.restore()
