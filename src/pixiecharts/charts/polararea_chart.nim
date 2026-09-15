import std/[math]
import pixie
import ../types, ../helpers

proc drawPolarAreaChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  entries: openArray[ChartEntry],
  config: ChartConfig = defaultChartConfig()
) =
  let total = entries.len
  if total == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  var maxVal = 0.0f
  for e in entries:
    if e.hasValue and abs(e.value) > maxVal:
      maxVal = abs(e.value)

  if maxVal <= 0.0f: maxVal = 1.0f

  let center = vec2(bounds.w * 0.5f, bounds.h * 0.5f)
  let maxRadius = (min(bounds.w, bounds.h) - (config.margin * 2.5f)) * 0.5f
  let angleStep = (2.0f * PI) / total.float32
  let progress = config.animationProgress

  # Concentric Reference Rings - fade in as the backdrop
  let ringAlpha = clamp(progress / 0.3f, 0.0f, 1.0f)
  let rings = 4
  for r in 1 .. rings:
    let rad = maxRadius * (r.float32 / rings.float32)
    ctx.beginPath()
    ctx.circle(center.x, center.y, rad)
    ctx.strokeStyle = config.yAxisLinesColor.withAlpha(config.yAxisLinesColor.a * ringAlpha)
    ctx.lineWidth = 1.0f
    ctx.stroke()

  # Draw Variable-Radius Wedges - each wedge grows out from the center
  # one after another, popping slightly past its final radius before
  # settling, like a compass needle finding its reading.
  for i in 0 ..< total:
    let entry = entries[i]
    if not entry.hasValue: continue

    let itemT = easeOutBack(staggerProgress(i, total, progress, 0.6f))
    if itemT <= 0.0f: continue

    let a0 = (i.float32 * angleStep) - (PI * 0.5f)
    let a1 = a0 + angleStep
    let r = maxRadius * (abs(entry.value) / maxVal) * clamp(itemT, 0.0f, 1.15f)
    let alpha = min(1.0f, itemT)

    let path = newPath()
    path.moveTo(center.x, center.y)
    path.arc(center.x, center.y, r, a0, a1, false)
    path.closePath()

    ctx.fillStyle = entry.color.withAlpha(0.65f * alpha)
    ctx.fillPath(path)

    ctx.strokeStyle = entry.color.withAlpha(alpha)
    ctx.lineWidth = 1.5f
    ctx.strokePath(path)

    # Perimeter Label
    let midA = (a0 + a1) * 0.5f
    let labelR = maxRadius + 12.0f
    let lx = center.x + (labelR * cos(midA))
    let ly = center.y + (labelR * sin(midA))
    let align = if cos(midA) > 0.1f: LeftAlign elif cos(midA) < -0.1f: RightAlign else: CenterAlign
    drawTextAligned(ctx, font, entry.label, vec2(lx, ly), config.labelColor.withAlpha(alpha), align, MiddleAlign)

  ctx.restore()
