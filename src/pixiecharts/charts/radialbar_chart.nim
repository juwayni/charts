import std/[math, options]
import pixie
import ../types, ../helpers

proc drawRadialBarChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  rings: openArray[RadialBarRing],
  config: ChartConfig = defaultChartConfig()
) =
  let count = rings.len
  if count == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  let center = vec2(bounds.w * 0.5f, bounds.h * 0.5f)
  let maxRadius = (min(bounds.w, bounds.h) - (config.margin * 2.0f)) * 0.5f
  let ringThickness = maxRadius / (count.float32 + 1.5f)
  let startAngle = -PI * 0.5f

  ctx.lineCap = RoundCap

  for i in 0 ..< count:
    let r = rings[i]
    let radius = maxRadius - (i.float32 * ringThickness)

    # 360° Background Track
    let trackColor = r.trackColor.get(r.color.withAlpha(0.20f))
    ctx.beginPath()
    ctx.circle(center.x, center.y, radius)
    ctx.strokeStyle = trackColor
    ctx.lineWidth = ringThickness * 0.75f
    ctx.stroke()

    # Foreground Progress Arc - rings sweep on one after another (outer
    # ring first, like activity rings filling in turn) with an eased sweep.
    let ringT = easeOutCubic(staggerProgress(i, count, config.animationProgress, 0.7f))
    let progressRatio = clamp(r.value / max(0.001f, r.maxValue), 0.0f, 1.0f)
    let sweepAngle = progressRatio * (2.0f * PI) * ringT

    if sweepAngle > 0.01f:
      ctx.beginPath()
      ctx.arc(center.x + 1.0f, center.y + 2.0f, radius, startAngle, startAngle + sweepAngle, false)
      ctx.strokeStyle = color(0.0f, 0.0f, 0.0f, 0.14f)
      ctx.lineWidth = ringThickness * 0.75f
      ctx.stroke()

      ctx.beginPath()
      ctx.arc(center.x, center.y, radius, startAngle, startAngle + sweepAngle, false)
      ctx.strokeStyle = r.color
      ctx.lineWidth = ringThickness * 0.75f
      ctx.stroke()
      # glowing tip cap
      let tipAngle = startAngle + sweepAngle
      ctx.fillStyle = r.color
      ctx.beginPath()
      ctx.circle(center.x + (radius * cos(tipAngle)), center.y + (radius * sin(tipAngle)), ringThickness * 0.375f)
      ctx.fill()

  ctx.restore()
