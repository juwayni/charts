import std/[math]
import pixie
import ../types, ../helpers

proc drawSpeedometerChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  data: SpeedometerData,
  config: ChartConfig = defaultChartConfig()
) =
  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  let center = vec2(bounds.w * 0.5f, bounds.h * 0.58f)
  let radius = (min(bounds.w, bounds.h) - (config.margin * 2.0f)) * 0.46f
  let progress = config.animationProgress

  # 240° arc spanning from 150° (bottom-left) to 390° (bottom-right)
  let startAngle = 150.0f * (PI / 180.0f)
  let totalArc = 240.0f * (PI / 180.0f)
  let ringWidth = radius * 0.16f

  # 1. Background Colored Warning Zones - the dial sweeps on first,
  # like the gauge is booting up before the needle appears.
  let dialSweep = easeOutQuad(clamp(progress / 0.45f, 0.0f, 1.0f)) * totalArc
  for z in data.zones:
    let zoneStart = z.startFraction * totalArc
    if zoneStart >= dialSweep: continue
    let a0 = startAngle + zoneStart
    let a1 = startAngle + min(z.endFraction * totalArc, dialSweep)
    ctx.beginPath()
    ctx.arc(center.x, center.y, radius, a0, a1, false)
    ctx.strokeStyle = z.color
    ctx.lineWidth = ringWidth
    ctx.stroke()

  # 2. Dial Calibration Ticks - fade/pop in alongside the dial sweep
  let tickAlpha = clamp((progress - 0.2f) / 0.3f, 0.0f, 1.0f)
  let ticks = 10
  for i in 0 .. ticks:
    let f = i.float32 / ticks.float32
    let a = startAngle + (f * totalArc)
    let p0 = vec2(center.x + ((radius - ringWidth) * cos(a)), center.y + ((radius - ringWidth) * sin(a)))
    let p1 = vec2(center.x + (radius * cos(a)), center.y + (radius * sin(a)))

    ctx.beginPath()
    ctx.moveTo(p0.x, p0.y)
    ctx.lineTo(p1.x, p1.y)
    ctx.strokeStyle = color(1, 1, 1, 0.85f * tickAlpha)
    ctx.lineWidth = 2.0f
    ctx.stroke()

  # 3. Needle Pointer Indicator - eases in with a light spring settle so
  # it feels like a real mechanical needle finding its reading.
  let valRatio = clamp((data.currentVal - data.minVal) / max(0.001f, data.maxVal - data.minVal), 0.0f, 1.0f)
  let needleT = easeOutElastic(clamp((progress - 0.35f) / 0.65f, 0.0f, 1.0f))
  let needleAngle = startAngle + (valRatio * totalArc * needleT)
  let needleLen = radius - ringWidth - 8.0f
  let needleAlpha = min(1.0f, progress * 2.5f)

  let tip = vec2(center.x + (needleLen * cos(needleAngle)), center.y + (needleLen * sin(needleAngle)))
  let leftBase = vec2(center.x + (7.0f * cos(needleAngle - (PI * 0.5f))), center.y + (7.0f * sin(needleAngle - (PI * 0.5f))))
  let rightBase = vec2(center.x + (7.0f * cos(needleAngle + (PI * 0.5f))), center.y + (7.0f * sin(needleAngle + (PI * 0.5f))))

  let needlePath = newPath()
  needlePath.moveTo(tip.x, tip.y)
  needlePath.lineTo(rightBase.x, rightBase.y)
  needlePath.lineTo(leftBase.x, leftBase.y)
  needlePath.closePath()

  ctx.fillStyle = data.needleColor.withAlpha(needleAlpha)
  ctx.fillPath(needlePath)

  # Central Hub Cap
  ctx.fillStyle = color(0.15f, 0.15f, 0.15f, needleAlpha)
  ctx.beginPath()
  ctx.circle(center.x, center.y, 11.0f)
  ctx.fill()

  # Digital Readout - counts up toward the final value
  font.size = config.labelTextSize * 1.30f
  let displayVal = data.currentVal * clamp(needleT, 0.0f, 1.0f)
  let readout = formatNiceNumber(displayVal) & " " & data.unit
  drawTextAligned(ctx, font, readout, vec2(center.x, center.y + 36.0f), config.labelColor.withAlpha(needleAlpha), CenterAlign, MiddleAlign)

  ctx.restore()
