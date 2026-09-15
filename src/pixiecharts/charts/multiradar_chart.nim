import std/[math]
import pixie
import ../types, ../helpers

proc drawMultiRadarChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  data: MultiRadarData,
  config: ChartConfig = defaultChartConfig()
) =
  let totalAxes = data.axes.len
  if totalAxes < 3:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  let center = vec2(bounds.w * 0.5f, bounds.h * 0.52f)
  let maxR = (min(bounds.w, bounds.h) - (config.margin * 3.0f)) * 0.5f
  let angleStep = (2.0f * PI) / totalAxes.float32
  let startAngle = -PI * 0.5f
  let progress = config.animationProgress

  # 1. Concentric Polygonal Web Grid - fades in first as the backdrop
  let gridAlpha = clamp(progress / 0.3f, 0.0f, 1.0f)
  let levels = 4
  for l in 1 .. levels:
    let r = maxR * (l.float32 / levels.float32)
    let webPath = newPath()
    for i in 0 ..< totalAxes:
      let a = startAngle + (i.float32 * angleStep)
      let p = vec2(center.x + (r * cos(a)), center.y + (r * sin(a)))
      if i == 0: webPath.moveTo(p.x, p.y)
      else: webPath.lineTo(p.x, p.y)
    webPath.closePath()
    ctx.strokeStyle = config.yAxisLinesColor.withAlpha(config.yAxisLinesColor.a * gridAlpha)
    ctx.lineWidth = 1.0f
    ctx.strokePath(webPath)

  # 2. Radial Axis Spokes & Labels
  font.size = config.labelTextSize * 0.85f
  for i in 0 ..< totalAxes:
    let a = startAngle + (i.float32 * angleStep)
    let p = vec2(center.x + (maxR * cos(a)), center.y + (maxR * sin(a)))

    ctx.beginPath()
    ctx.moveTo(center.x, center.y)
    ctx.lineTo(p.x, p.y)
    ctx.strokeStyle = config.yAxisLinesColor.withAlpha(config.yAxisLinesColor.a * gridAlpha)
    ctx.lineWidth = 1.0f
    ctx.stroke()

    let lp = vec2(center.x + ((maxR + 14.0f) * cos(a)), center.y + ((maxR + 14.0f) * sin(a)))
    let align = if cos(a) > 0.1f: LeftAlign elif cos(a) < -0.1f: RightAlign else: CenterAlign
    drawTextAligned(ctx, font, data.axes[i], lp, config.labelColor.withAlpha(gridAlpha), align, MiddleAlign)

  # 3. Series Polygons - each series expands outward from the center in
  # turn, staggered so they don't all bloom simultaneously.
  let seriesCount = data.series.len
  for sIdx in 0 ..< seriesCount:
    let s = data.series[sIdx]
    let seriesT = easeOutBack(staggerProgress(sIdx, seriesCount, clamp((progress - 0.2f) / 0.8f, 0.0f, 1.0f), 0.65f))
    if seriesT <= 0.0f: continue
    let polyPath = newPath()
    for i in 0 ..< totalAxes:
      let val = if i < s.values.len: s.values[i] else: 0.0f
      let r = maxR * clamp(val / max(0.001f, data.maxVal), 0.0f, 1.0f) * clamp(seriesT, 0.0f, 1.1f)
      let a = startAngle + (i.float32 * angleStep)
      let p = vec2(center.x + (r * cos(a)), center.y + (r * sin(a)))

      if i == 0: polyPath.moveTo(p.x, p.y)
      else: polyPath.lineTo(p.x, p.y)

    polyPath.closePath()
    let alpha = min(1.0f, seriesT)
    ctx.fillStyle = s.color.withAlpha(0.35f * alpha)
    ctx.fillPath(polyPath)
    ctx.strokeStyle = s.color.withAlpha(alpha)
    ctx.lineWidth = 2.0f
    ctx.strokePath(polyPath)

  # 4. Legend at Top - fades in last
  let legendAlpha = clamp((progress - 0.7f) / 0.3f, 0.0f, 1.0f)
  let legendX = config.margin
  var currX = legendX
  for s in data.series:
    ctx.fillStyle = s.color.withAlpha(legendAlpha)
    let swatch = newPath()
    swatch.roundedRect(rect(currX, config.margin, 12.0f, 12.0f), 3.0f, 3.0f)
    ctx.fillPath(swatch)
    font.size = 12.0f
    drawTextAligned(ctx, font, s.name, vec2(currX + 16.0f, config.margin + 6.0f), config.labelColor.withAlpha(legendAlpha), LeftAlign, MiddleAlign)
    currX += font.measureTextSize(s.name).x + 32.0f

  ctx.restore()
