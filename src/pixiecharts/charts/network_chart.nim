import std/[math, options, tables]
import pixie
import ../types
import ../helpers

proc drawNetworkChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  data: NetworkGraphData,
  config: ChartConfig = defaultChartConfig()
) =
  if data.nodes.len == 0:
    return

  ctx.save()

  # Draw background
  if config.backgroundColor.a > 0.0f:
    ctx.fillStyle = config.backgroundColor
    ctx.fillRect(bounds.x, bounds.y, bounds.w, bounds.h)

  let animProgress = clamp(config.animationProgress, 0.0f, 1.0f)

  # Map nodes by ID for fast lookup
  var nodeMap = initTable[string, NetworkNode]()
  for node in data.nodes:
    nodeMap[node.id] = node

  # Center calculation & scaling if nodes define relative/absolute coordinates
  var minX = data.nodes[0].x
  var maxX = data.nodes[0].x
  var minY = data.nodes[0].y
  var maxY = data.nodes[0].y

  for node in data.nodes:
    if node.x < minX: minX = node.x
    if node.x > maxX: maxX = node.x
    if node.y < minY: minY = node.y
    if node.y > maxY: maxY = node.y

  let margin = config.margin * 2.0f
  let drawW = max(10.0f, bounds.w - margin * 2.0f)
  let drawH = max(10.0f, bounds.h - margin * 2.0f)
  let rangeX = if maxX == minX: 1.0f else: maxX - minX
  let rangeY = if maxY == minY: 1.0f else: maxY - minY

  proc getScreenPos(node: NetworkNode): Vec2 =
    let normX = (node.x - minX) / rangeX
    let normY = (node.y - minY) / rangeY
    let sx = bounds.x + margin + normX * drawW
    let sy = bounds.y + margin + normY * drawH
    vec2(sx, sy)

  # Draw edge links first
  for i, edge in data.edges:
    if nodeMap.hasKey(edge.sourceId) and nodeMap.hasKey(edge.targetId):
      let srcNode = nodeMap[edge.sourceId]
      let dstNode = nodeMap[edge.targetId]

      let srcPos = getScreenPos(srcNode)
      let dstPos = getScreenPos(dstNode)

      let edgeProgress = staggerProgress(i, data.edges.len, animProgress, 0.7f)
      if edgeProgress <= 0.0f: continue

      let currDstPos = vec2(
        lerp(srcPos.x, dstPos.x, easeOut(edgeProgress)),
        lerp(srcPos.y, dstPos.y, easeOut(edgeProgress))
      )

      var path = newPath()
      path.moveTo(srcPos.x, srcPos.y)
      path.lineTo(currDstPos.x, currDstPos.y)

      let edgeColor = edge.color.get(config.borderLineColor).withAlpha(0.6f * animProgress)
      ctx.strokeStyle = edgeColor
      ctx.lineWidth = max(1.0f, edge.weight)
      ctx.stroke(path)

  # Draw graph nodes and labels
  for i, node in data.nodes:
    let nodeProgress = staggerProgress(i, data.nodes.len, animProgress, 0.5f)
    if nodeProgress <= 0.0f: continue

    let pos = getScreenPos(node)
    let radius = node.radius * easeOutBack(nodeProgress)
    let nColor = node.color.withAlpha(node.color.a * animProgress)

    # Soft shadow
    ctx.drawSoftShadow(
      proc(p: Path) = p.circle(pos.x, pos.y, radius),
      offset = vec2(0.0f, 2.0f),
      color = color(0, 0, 0, 0.15f * animProgress)
    )

    # Node circle fill
    var circlePath = newPath()
    circlePath.circle(pos.x, pos.y, radius)
    ctx.fillStyle = nColor
    ctx.fill(circlePath)

    # Node border stroke
    var strokePath = newPath()
    strokePath.circle(pos.x, pos.y, radius)
    ctx.strokeStyle = color(1.0f, 1.0f, 1.0f, 0.8f * animProgress)
    ctx.lineWidth = 2.0f
    ctx.stroke(strokePath)

    # Node text label below circle
    if node.label.len > 0 and nodeProgress > 0.4f:
      drawTextAligned(
        ctx, font, node.label,
        vec2(pos.x, pos.y + radius + 10.0f),
        config.labelColor.withAlpha(animProgress),
        CenterAlign, TopAlign
      )

  ctx.restore()
