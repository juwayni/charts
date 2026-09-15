import std/[math]
import pixie
import ../types, ../helpers

proc drawDotPlotChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  groups: openArray[DotPlotGroup],
  config: ChartConfig = defaultChartConfig(),
  dotRadius: float32 = 4.5f
) =
  let count = groups.len
  if count == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  var minVal = 0.0f
  var maxVal = 1.0f
  var hasValues = false

  for g in groups:
    for v in g.values:
      if not hasValues:
        minVal = v
        maxVal = v
        hasValues = true
      else:
        if v < minVal: minVal = v
        if v > maxVal: maxVal = v

  var range, niceMin, niceMax, tickSpacing: float64
  calculateNiceScale(minVal.float64, maxVal.float64, config.yAxisMaxTicks, range, tickSpacing, niceMin, niceMax)
  let valRange = max(1.0f, (niceMax - niceMin).float32)

  let leftMargin = config.margin + measureNiceScaleLabelWidth(font, niceMin, tickSpacing, config.yAxisMaxTicks, config.labelTextSize) + 10.0f
  let bottomMargin = config.margin + config.labelTextSize + 10.0f
  let chartW = bounds.w - leftMargin - config.margin
  let chartH = bounds.h - config.margin - bottomMargin

  # Y Grid & Axis - fades in as the backdrop
  let gridAlpha = clamp(config.animationProgress / 0.3f, 0.0f, 1.0f)
  for i in 0 ..< config.yAxisMaxTicks:
    let tickVal = (niceMin + (i.float64 * tickSpacing)).float32
    let y = config.margin + chartH - (((tickVal - niceMin.float32) / valRange) * chartH)
    ctx.beginPath()
    ctx.moveTo(leftMargin, y)
    ctx.lineTo(leftMargin + chartW, y)
    ctx.strokeStyle = config.yAxisLinesColor.withAlpha(config.yAxisLinesColor.a * gridAlpha)
    ctx.lineWidth = 1.0f
    ctx.stroke()
    drawTextAligned(ctx, font, formatNiceNumber(tickVal), vec2(leftMargin - 8.0f, y), config.yAxisTextColor.withAlpha(gridAlpha), RightAlign, MiddleAlign)

  let laneW = chartW / count.float32
  let progress = config.animationProgress

  # Render Displaced Dots - lanes sweep in left-to-right, and within a
  # lane each dot pops in with a small overshoot once its lane has started.
  for gIdx in 0 ..< count:
    let g = groups[gIdx]
    let laneCenterX = leftMargin + (gIdx.float32 * laneW) + (laneW * 0.5f)
    let laneT = staggerProgress(gIdx, count, progress, 0.7f)
    var placedPts: seq[Vec2] = @[]

    for vIdx in 0 ..< g.values.len:
      let v = g.values[vIdx]
      let targetY = config.margin + chartH - (((v - niceMin.float32) / valRange) * chartH)
      var currentX = laneCenterX
      var jitterOffset = 0.0f
      var step = 1.0f

      # Local collision avoidance
      var collides = true
      while collides and jitterOffset < laneW * 0.40f:
        currentX = laneCenterX + jitterOffset
        collides = false
        for p in placedPts:
          if (vec2(currentX, targetY) - p).length < (dotRadius * 2.0f):
            collides = true
            break

        if collides:
          jitterOffset = if jitterOffset <= 0.0f: abs(jitterOffset) + (dotRadius * 1.5f) else: -jitterOffset
          step += 1.0f

      placedPts.add(vec2(currentX, targetY))

      let dotT = easeOutBack(staggerProgress(vIdx, max(1, g.values.len), laneT, 0.6f))
      if dotT <= 0.0f: continue
      let dAlpha = min(1.0f, dotT)

      ctx.fillStyle = g.color.withAlpha(0.70f * dAlpha)
      ctx.beginPath()
      ctx.circle(currentX, targetY, dotRadius * clamp(dotT, 0.0f, 1.15f))
      ctx.fill()
      ctx.strokeStyle = g.color.withAlpha(dAlpha)
      ctx.lineWidth = 1.0f
      ctx.stroke()

    # Category Group Title
    drawTextAligned(ctx, font, g.groupLabel, vec2(laneCenterX, bounds.h - (bottomMargin * 0.5f)), config.labelColor.withAlpha(min(1.0f, laneT * 2.0f)), CenterAlign, MiddleAlign)

  ctx.restore()
