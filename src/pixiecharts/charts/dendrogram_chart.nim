import std/[math]
import pixie
import ../types, ../helpers

proc countLeaves(node: DendrogramNode): int =
  if node.children.len == 0: return 1
  for c in node.children: result += countLeaves(c)

proc drawDendrogramBranch(
  ctx: Context,
  font: Font,
  node: DendrogramNode,
  x, y0, y1, levelW, totalW, progress: float32,
  config: ChartConfig
) =
  let midY = (y0 + y1) * 0.5f
  let nextX = x + levelW
  # Reveal sweeps left-to-right, following the tree's growth direction.
  let nodeT = easeOutBack(positionStagger(x, totalW, progress, 0.45f))

  if node.children.len == 0:
    if nodeT <= 0.0f:
      return
    ctx.fillStyle = node.color.withAlpha(min(1.0f, nodeT))
    ctx.beginPath()
    ctx.circle(x, midY, 4.0f * clamp(nodeT, 0.0f, 1.15f))
    ctx.fill()
    font.size = 11.0f
    drawTextAligned(ctx, font, node.name, vec2(x + 8.0f, midY), config.labelColor.withAlpha(min(1.0f, nodeT)), LeftAlign, MiddleAlign)
    return

  if nodeT <= 0.0f:
    return

  ctx.fillStyle = node.color.withAlpha(min(1.0f, nodeT))
  ctx.beginPath()
  ctx.circle(x, midY, 3.0f * clamp(nodeT, 0.0f, 1.15f))
  ctx.fill()

  let totalLeaves = countLeaves(node).float32
  var currY = y0

  for c in node.children:
    let cLeaves = countLeaves(c).float32
    let cSpan = (cLeaves / totalLeaves) * (y1 - y0)
    let childMidY = currY + (cSpan * 0.5f)
    # The connector's own reveal is keyed off where it lands (nextX), so
    # it "grows into" the child node rather than popping fully drawn.
    let connT = easeOutQuad(positionStagger(nextX, totalW, progress, 0.45f))
    if connT > 0.0f:
      let animChildMidY = lerp(midY, childMidY, connT)
      let p = newPath()
      p.moveTo(x, midY)
      p.bezierCurveTo(x + (levelW * 0.5f), midY, nextX - (levelW * 0.5f), animChildMidY, nextX, animChildMidY)
      ctx.strokeStyle = color(0.62f, 0.65f, 0.70f, min(1.0f, connT))
      ctx.lineWidth = 1.5f
      ctx.strokePath(p)

      drawDendrogramBranch(ctx, font, c, nextX, currY, currY + cSpan, levelW, totalW, progress, config)
    currY += cSpan

proc drawDendrogramChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  root: DendrogramNode,
  config: ChartConfig = defaultChartConfig()
) =
  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  let startX = config.margin + 20.0f
  let startY = config.margin + 10.0f
  let chartH = bounds.h - (config.margin * 2.0f)
  let levelW = 90.0f
  let totalW = max(1.0f, bounds.w - startX - config.margin)

  drawDendrogramBranch(ctx, font, root, startX, startY, startY + chartH, levelW, totalW, config.animationProgress, config)
  ctx.restore()
