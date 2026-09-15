import std/[math]
import pixie
import ../types, ../helpers

proc drawLiquidGauge*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  data: LiquidGaugeData,
  config: ChartConfig = defaultChartConfig()
) =
  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  let center = vec2(bounds.w * 0.5f, bounds.h * 0.5f)
  let radius = (min(bounds.w, bounds.h) - (config.margin * 2.0f)) * 0.5f
  let animT = easeOutCubic(config.animationProgress)
  let pct = clamp(data.percentage * animT, 0.0f, 1.0f)
  let waterLevelY = center.y + radius - (2.0f * radius * pct)

  # 1. Circle Boundary Clip - the ring itself sweeps on first, like a
  # vessel being drawn before it fills with liquid.
  let ringSweep = easeOutQuad(clamp(config.animationProgress / 0.4f, 0.0f, 1.0f)) * 2.0f * PI
  ctx.save()
  let clipCircle = newPath()
  clipCircle.circle(center.x, center.y, radius - 2.0f)
  ctx.clipPath(clipCircle)

  # 2. Sine Wave Fluid Fill - the wave's phase drifts with progress so the
  # surface looks like it's actively sloshing as the level rises, not
  # just a static rendered snapshot.
  let wavePath = newPath()
  let waveCount = max(1, data.waveCount).float32
  let waveH = data.waveHeight * (1.0f - abs(pct - 0.5f) * 1.5f)
  let phase = config.animationProgress * PI * 3.0f
  let steps = 60
  let stepX = (2.0f * radius) / steps.float32

  wavePath.moveTo(center.x - radius, center.y + radius)
  for i in 0 .. steps:
    let x = (center.x - radius) + (i.float32 * stepX)
    let angle = ((i.float32 / steps.float32) * (2.0f * PI * waveCount)) + phase
    let y = waterLevelY + (waveH * sin(angle))
    wavePath.lineTo(x, y)

  wavePath.lineTo(center.x + radius, center.y + radius)
  wavePath.closePath()

  ctx.fillStyle = data.fillColor.withAlpha(0.75f * min(1.0f, config.animationProgress * 3.0f))
  ctx.fillPath(wavePath)
  ctx.restore()

  # 3. Outer Ring - sweeps on before the liquid appears
  if ringSweep > 0.01f:
    ctx.strokeStyle = data.borderColor
    ctx.lineWidth = 4.0f
    ctx.beginPath()
    ctx.arc(center.x, center.y, radius, -PI * 0.5f, (-PI * 0.5f) + ringSweep, false)
    ctx.stroke()

  # 4. Center Percentage Readout - counts up alongside the fill
  font.size = radius * 0.40f
  let text = $(int(pct * 100.0f)) & "%"
  drawTextAligned(ctx, font, text, center, data.textColor.withAlpha(min(1.0f, config.animationProgress * 2.0f)), CenterAlign, MiddleAlign)

  ctx.restore()
