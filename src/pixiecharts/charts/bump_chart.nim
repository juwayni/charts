import std/[math, options]
import pixie
import ../types
import ../helpers

proc drawBumpChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  data: BumpChartData,
  config: ChartConfig = defaultChartConfig()
) =
  if data.series.len == 0 or data.timeLabels.len == 0:
    return

  ctx.save()

  # Draw background
  if config.backgroundColor.a > 0.0f:
    ctx.fillStyle = config.backgroundColor
    ctx.fillRect(bounds.x, bounds.y, bounds.w, bounds.h)

  let margin = config.margin
  let headerHeight = margin * 2.0f
  let footerHeight = margin * 2.5f
  let leftMargin = margin * 4.0f
  let rightMargin = margin * 4.0f

  let plotX = bounds.x + leftMargin
  let plotY = bounds.y + headerHeight
  let plotW = max(10.0f, bounds.w - leftMargin - rightMargin)
  let plotH = max(10.0f, bounds.h - headerHeight - footerHeight)

  # Determine max rank (default to number of series)
  var maxRank = data.series.len
  for s in data.series:
    for r in s.ranks:
      if r > maxRank: maxRank = r
  if maxRank < 1: maxRank = 1

  let numSteps = data.timeLabels.len
  let stepX = if numSteps <= 1: plotW else: plotW / (numSteps.float32 - 1.0f)

  # Draw vertical time grid lines and labels
  for i, timeLabel in data.timeLabels:
    let x = plotX + i.float32 * stepX

    # Vertical grid line
    var p = newPath()
    p.moveTo(x, plotY)
    p.lineTo(x, plotY + plotH)
    ctx.strokeStyle = config.borderLineColor.withAlpha(config.borderLineColor.a * config.animationProgress)
    ctx.lineWidth = 1.0f
    ctx.stroke(p)

    # Time label
    drawTextAligned(ctx, font, timeLabel, vec2(x, plotY + plotH + 12.0f), config.labelColor.withAlpha(config.animationProgress), CenterAlign, TopAlign)

  # Draw rank Y-axis numbers on left and right
  for r in 1 .. maxRank:
    let normY = (r.float32 - 0.5f) / maxRank.float32
    let y = plotY + normY * plotH
    drawTextAligned(ctx, font, "#" & $r, vec2(plotX - 10.0f, y), config.labelColor.withAlpha(config.animationProgress), RightAlign, MiddleAlign)
    drawTextAligned(ctx, font, "#" & $r, vec2(plotX + plotW + 10.0f, y), config.labelColor.withAlpha(config.animationProgress), LeftAlign, MiddleAlign)

  # Draw smooth bezier curves and markers for each series
  for sIdx, serie in data.series:
    if serie.ranks.len == 0: continue
    let serieAlpha = config.animationProgress
    let sColor = serie.color.withAlpha(serie.color.a * serieAlpha)

    # Calculate points for this series
    var points: seq[Vec2] = @[]
    for i in 0 ..< numSteps:
      let r = if i < serie.ranks.len: serie.ranks[i] else: maxRank
      let x = plotX + i.float32 * stepX
      let normY = (r.float32 - 0.5f) / maxRank.float32
      let y = plotY + normY * plotH
      points.add(vec2(x, y))

    if points.len > 0:
      # Draw smooth curve
      var path = newPath()
      path.moveTo(points[0].x, points[0].y)

      for i in 0 ..< points.len - 1:
        let p0 = points[i]
        let p1 = points[i + 1]
        let midX = (p0.x + p1.x) * 0.5f

        # Animate progress horizontally across steps
        let stepProgress = positionStagger(i.float32, (points.len - 1).float32, config.animationProgress)
        let currP1 = vec2(lerp(p0.x, p1.x, stepProgress), lerp(p0.y, p1.y, stepProgress))
        let currMidX = (p0.x + currP1.x) * 0.5f

        path.bezierCurveTo(currMidX, p0.y, currMidX, currP1.y, currP1.x, currP1.y)

      ctx.strokeStyle = sColor
      ctx.lineWidth = 4.0f
      ctx.stroke(path)

      # Draw node markers and rank labels inside circles
      for i, pt in points:
        let nodeProgress = staggerProgress(i, points.len, config.animationProgress)
        if nodeProgress <= 0.0f: continue

        let nodeRadius = 14.0f * easeOutBack(nodeProgress)

        # Drop shadow & circle background
        var circlePath = newPath()
        circlePath.circle(pt.x, pt.y, nodeRadius)
        ctx.fillStyle = sColor
        ctx.fill(circlePath)

        var borderPath = newPath()
        borderPath.circle(pt.x, pt.y, nodeRadius)
        ctx.strokeStyle = color(1.0f, 1.0f, 1.0f, 0.9f * serieAlpha)
        ctx.lineWidth = 2.0f
        ctx.stroke(borderPath)

        # Rank number inside node
        if i < serie.ranks.len and nodeProgress > 0.5f:
          let r = serie.ranks[i]
          let fontSaved = font.size
          font.size = 12.0f
          drawTextAligned(ctx, font, $r, pt, color(1.0f, 1.0f, 1.0f, serieAlpha), CenterAlign, MiddleAlign)
          font.size = fontSaved

      # Series label at start and end
      if serie.name.len > 0:
        let firstPt = points[0]
        let lastPt = points[points.len - 1]
        drawTextAligned(ctx, font, serie.name, vec2(firstPt.x - 30.0f, firstPt.y), sColor, RightAlign, MiddleAlign)
        drawTextAligned(ctx, font, serie.name, vec2(lastPt.x + 30.0f, lastPt.y), sColor, LeftAlign, MiddleAlign)

  ctx.restore()
