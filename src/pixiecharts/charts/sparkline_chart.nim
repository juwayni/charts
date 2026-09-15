import std/[math, options]
import pixie
import ../types
import ../helpers

proc drawSparklineChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  data: SparklineData,
  config: ChartConfig = defaultChartConfig()
) =
  if data.values.len == 0:
    return

  ctx.save()

  # Draw background if specified
  if config.backgroundColor.a > 0.0f:
    ctx.fillStyle = config.backgroundColor
    ctx.fillRect(bounds.x, bounds.y, bounds.w, bounds.h)

  let padding = config.margin * 0.5f
  let plotX = bounds.x + padding
  let plotY = bounds.y + padding
  let plotW = max(5.0f, bounds.w - padding * 2.0f)
  let plotH = max(5.0f, bounds.h - padding * 2.0f)

  # Find min and max values
  var minV = data.values[0]
  var maxV = data.values[0]
  var minIdx = 0
  var maxIdx = 0
  for i, v in data.values:
    if v < minV:
      minV = v
      minIdx = i
    if v > maxV:
      maxV = v
      maxIdx = i

  let valRange = if maxV == minV: 1.0f else: maxV - minV
  let count = data.values.len
  let stepX = if count <= 1: plotW else: plotW / (count.float32 - 1.0f)

  # Compute points based on animation progress
  var points: seq[Vec2] = @[]
  let animProgress = clamp(config.animationProgress, 0.0f, 1.0f)

  for i, v in data.values:
    let itemProgress = staggerProgress(i, count, animProgress)
    let normY = (v - minV) / valRange
    let x = plotX + i.float32 * stepX
    let targetY = plotY + plotH - (normY * plotH)
    let startY = plotY + plotH
    let y = lerp(startY, targetY, easeOut(itemProgress))
    points.add(vec2(x, y))

  if points.len > 1:
    # Build area fill path under line
    var areaPath = newPath()
    areaPath.moveTo(points[0].x, plotY + plotH)
    for pt in points:
      areaPath.lineTo(pt.x, pt.y)
    areaPath.lineTo(points[points.len - 1].x, plotY + plotH)
    areaPath.closePath()

    let fillColor = data.fillColor.withAlpha(data.fillColor.a * animProgress)
    ctx.fillStyle = fillColor
    ctx.fill(areaPath)

    # Build trend line path
    var linePath = newPath()
    linePath.moveTo(points[0].x, points[0].y)
    for i in 1 ..< points.len:
      linePath.lineTo(points[i].x, points[i].y)

    let lineColor = data.lineColor.withAlpha(data.lineColor.a * animProgress)
    ctx.strokeStyle = lineColor
    ctx.lineWidth = max(1.5f, config.lineSize)
    ctx.stroke(linePath)

  # Highlight start, end, min, and max points if enabled
  if data.showMinMax and points.len > 0:
    # Last point marker (current value dot)
    let lastPt = points[points.len - 1]
    let endDotProgress = staggerProgress(count - 1, count, animProgress)
    if endDotProgress > 0.0f:
      var dotPath = newPath()
      let r = 3.5f * easeOutBack(endDotProgress)
      dotPath.circle(lastPt.x, lastPt.y, r)
      ctx.fillStyle = data.lineColor.withAlpha(animProgress)
      ctx.fill(dotPath)

    # Min point marker (red dot)
    if minIdx < points.len:
      let minPt = points[minIdx]
      let minDotProgress = staggerProgress(minIdx, count, animProgress)
      if minDotProgress > 0.0f:
        var dotPath = newPath()
        let r = 3.0f * easeOutBack(minDotProgress)
        dotPath.circle(minPt.x, minPt.y, r)
        ctx.fillStyle = color(0.91f, 0.30f, 0.24f, animProgress)
        ctx.fill(dotPath)

    # Max point marker (green dot)
    if maxIdx < points.len:
      let maxPt = points[maxIdx]
      let maxDotProgress = staggerProgress(maxIdx, count, animProgress)
      if maxDotProgress > 0.0f:
        var dotPath = newPath()
        let r = 3.0f * easeOutBack(maxDotProgress)
        dotPath.circle(maxPt.x, maxPt.y, r)
        ctx.fillStyle = color(0.15f, 0.68f, 0.38f, animProgress)
        ctx.fill(dotPath)

  ctx.restore()
