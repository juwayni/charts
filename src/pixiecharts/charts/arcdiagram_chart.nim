import std/[math, options]
import pixie
import ../types, ../helpers

proc drawArcDiagramChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  data: ArcDiagramData,
  config: ChartConfig = defaultChartConfig()
) =
  let count = data.nodes.len
  if count < 2:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  let baselineY = bounds.h * 0.70f
  let chartW = bounds.w - (config.margin * 2.0f)
  let stepX = chartW / (count.float32 - 1.0f)
  let progress = config.animationProgress

  # Map node positions
  var nodePositions = newSeq[Vec2](count)
  for i in 0 ..< count:
    nodePositions[i] = vec2(config.margin + (i.float32 * stepX), baselineY)

  # 1. Semicircular Flow Arcs - sweep on left-to-right, matching the
  # reading order of the baseline, so links seem to bloom into place.
  for l in data.links:
    var idxSrc = -1
    var idxDst = -1
    for i in 0 ..< count:
      if data.nodes[i].id == l.sourceId: idxSrc = i
      if data.nodes[i].id == l.targetId: idxDst = i

    if idxSrc >= 0 and idxDst >= 0 and idxSrc != idxDst:
      let pSrc = nodePositions[idxSrc]
      let pDst = nodePositions[idxDst]
      let midX = (pSrc.x + pDst.x) * 0.5f
      let radius = abs(pDst.x - pSrc.x) * 0.5f

      let arcT = easeOutQuad(positionStagger(min(pSrc.x, pDst.x), chartW, progress, 0.5f))
      if arcT <= 0.0f:
        continue

      let sweep = PI * clamp(arcT, 0.0f, 1.0f)
      let arcPath = newPath()
      arcPath.arc(midX, baselineY, radius, PI, PI + sweep, false)

      let linkColor = l.color.get(data.nodes[idxSrc].color).withAlpha(0.55f * min(1.0f, arcT))
      ctx.strokeStyle = linkColor
      ctx.lineWidth = max(1.5f, l.weight)
      ctx.strokePath(arcPath)

  # 2. Nodes & Labels - pop in left to right along the baseline
  font.size = config.labelTextSize * 0.85f
  for i in 0 ..< count:
    let n = data.nodes[i]
    let p = nodePositions[i]
    let nodeT = easeOutBack(staggerProgress(i, count, progress, 0.6f))
    if nodeT <= 0.0f:
      continue
    let a = min(1.0f, nodeT)

    ctx.fillStyle = n.color.withAlpha(a)
    ctx.beginPath()
    ctx.circle(p.x, p.y, 6.5f * clamp(nodeT, 0.0f, 1.15f))
    ctx.fill()
    ctx.strokeStyle = color(1, 1, 1, a)
    ctx.lineWidth = 1.5f
    ctx.stroke()

    # Label rotated along baseline
    drawTextAligned(ctx, font, n.label, vec2(p.x, p.y + 14.0f), config.labelColor.withAlpha(a), CenterAlign, TopAlign)

  ctx.restore()
