import std/[math]
import pixie
import ../types, ../helpers

proc drawWindRoseChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  data: WindRoseData,
  config: ChartConfig = defaultChartConfig()
) =
  let totalSectors = data.sectors.len
  if totalSectors == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  var maxTotal = 0.0f
  for s in data.sectors:
    var sum = 0.0f
    for b in s.speedBands: sum += b
    if sum > maxTotal: maxTotal = sum

  if maxTotal <= 0.0f: maxTotal = 1.0f

  let center = vec2(bounds.w * 0.5f, bounds.h * 0.5f)
  let maxR = (min(bounds.w, bounds.h) - (config.margin * 2.5f)) * 0.5f
  let angleStep = (2.0f * PI) / totalSectors.float32
  let progress = config.animationProgress

  # Concentric Grid Rings - fade in as the backdrop
  let ringAlpha = clamp(progress / 0.3f, 0.0f, 1.0f)
  for r in 1 .. 4:
    let rad = maxR * (r.float32 / 4.0f)
    ctx.beginPath()
    ctx.circle(center.x, center.y, rad)
    ctx.strokeStyle = config.yAxisLinesColor.withAlpha(config.yAxisLinesColor.a * ringAlpha)
    ctx.lineWidth = 1.0f
    ctx.stroke()

  # Stacked Sector Wedges - each compass sector grows outward one after
  # another, like the rose is spinning up.
  for i in 0 ..< totalSectors:
    let s = data.sectors[i]
    let a0 = (i.float32 * angleStep) - (PI * 0.5f) - (angleStep * 0.40f)
    let a1 = a0 + (angleStep * 0.80f)
    let sectorT = easeOutQuad(staggerProgress(i, totalSectors, progress, 0.7f))
    let alpha = min(1.0f, sectorT * 2.0f)

    var currentR = 0.0f
    for bIdx in 0 ..< s.speedBands.len:
      let bandVal = s.speedBands[bIdx]
      let nextR = currentR + ((bandVal / maxTotal) * maxR * sectorT)

      let path = newPath()
      path.moveTo(center.x + (currentR * cos(a0)), center.y + (currentR * sin(a0)))
      path.arc(center.x, center.y, nextR, a0, a1, false)
      path.lineTo(center.x + (currentR * cos(a1)), center.y + (currentR * sin(a1)))
      if currentR > 0.0f:
        path.arc(center.x, center.y, currentR, a1, a0, true)
      path.closePath()

      ctx.fillStyle = data.bandColors[bIdx mod data.bandColors.len].withAlpha(alpha)
      ctx.fillPath(path)
      currentR = nextR

    # Bearing Label
    let midA = (a0 + a1) * 0.5f
    let lx = center.x + ((maxR + 12.0f) * cos(midA))
    let ly = center.y + ((maxR + 12.0f) * sin(midA))
    font.size = config.labelTextSize * 0.80f
    drawTextAligned(ctx, font, s.directionLabel, vec2(lx, ly), config.labelColor.withAlpha(alpha), CenterAlign, MiddleAlign)

  ctx.restore()
