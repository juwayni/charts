import std/[math, options]
import pixie
import ../types
import ../helpers

type
  LayoutNode = ref object
    node: OrgNode
    x, y: float32
    width, height: float32
    children: seq[LayoutNode]

proc calculateTreeLayout(node: OrgNode, depth: int, startX: var float32, cardW, cardH, gapX, gapY: float32): LayoutNode =
  let resultNode = LayoutNode(
    node: node,
    width: cardW,
    height: cardH,
    y: depth.float32 * (cardH + gapY),
    children: @[]
  )

  if node.children.len == 0:
    resultNode.x = startX
    startX += cardW + gapX
  else:
    var childNodes: seq[LayoutNode] = @[]
    for child in node.children:
      childNodes.add(calculateTreeLayout(child, depth + 1, startX, cardW, cardH, gapX, gapY))
    resultNode.children = childNodes

    let firstX = childNodes[0].x
    let lastX = childNodes[childNodes.len - 1].x
    resultNode.x = (firstX + lastX) * 0.5f

  return resultNode

proc drawLayoutTree(ctx: Context, font: Font, layout: LayoutNode, originX, originY, animProgress: float32, config: ChartConfig) =
  if layout == nil or animProgress <= 0.0f:
    return

  let cardX = originX + layout.x
  let cardY = originY + layout.y
  let cardW = layout.width
  let cardH = layout.height

  # Draw connector lines to children
  if layout.children.len > 0:
    let midParentX = cardX + cardW * 0.5f
    let bottomParentY = cardY + cardH
    let midY = bottomParentY + (config.margin * 0.75f)

    for child in layout.children:
      let midChildX = originX + child.x + cardW * 0.5f
      let topChildY = originY + child.y

      # Orthogonal branch path
      var p = newPath()
      p.moveTo(midParentX, bottomParentY)
      p.lineTo(midParentX, midY)
      p.lineTo(midChildX, midY)
      p.lineTo(midChildX, topChildY)

      let lineColor = config.borderLineColor.withAlpha(config.borderLineColor.a * animProgress)
      ctx.strokeStyle = lineColor
      ctx.lineWidth = 2.0f
      ctx.stroke(p)

      # Recurse child rendering
      drawLayoutTree(ctx, font, child, originX, originY, animProgress, config)

  # Draw card card box
  let nodeColor = layout.node.color.withAlpha(layout.node.color.a * animProgress)

  # Drop shadow
  ctx.drawSoftShadow(
    proc(p: Path) = p.roundedRect(rect(cardX, cardY, cardW, cardH), 6.0f),
    offset = vec2(0.0f, 3.0f),
    color = color(0, 0, 0, 0.12f * animProgress)
  )

  # Card body
  var cardPath = newPath()
  cardPath.roundedRect(rect(cardX, cardY, cardW, cardH), 6.0f)
  ctx.fillStyle = config.backgroundColor.withAlpha(animProgress)
  ctx.fill(cardPath)

  ctx.strokeStyle = nodeColor
  ctx.lineWidth = 1.5f
  ctx.stroke(cardPath)

  # Top accent band
  var accentPath = newPath()
  accentPath.roundedRect(rect(cardX, cardY, cardW, 6.0f), 6.0f, 6.0f, 0.0f, 0.0f)
  ctx.fillStyle = nodeColor
  ctx.fill(accentPath)

  # Node Name & Title
  if layout.node.name.len > 0:
    let fontSaved = font.size
    font.size = config.labelTextSize
    drawTextAligned(ctx, font, layout.node.name, vec2(cardX + cardW * 0.5f, cardY + 22.0f), config.labelColor.withAlpha(animProgress), CenterAlign, MiddleAlign)

    if layout.node.title.len > 0:
      font.size = config.labelTextSize * 0.75f
      drawTextAligned(ctx, font, layout.node.title, vec2(cardX + cardW * 0.5f, cardY + 40.0f), config.labelColor.withAlpha(0.7f * animProgress), CenterAlign, MiddleAlign)

    font.size = fontSaved

proc drawOrgChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  rootNode: OrgNode,
  config: ChartConfig = defaultChartConfig()
) =
  ctx.save()

  # Draw background
  if config.backgroundColor.a > 0.0f:
    ctx.fillStyle = config.backgroundColor
    ctx.fillRect(bounds.x, bounds.y, bounds.w, bounds.h)

  let margin = config.margin
  let cardW = 140.0f
  let cardH = 55.0f
  let gapX = 20.0f
  let gapY = 35.0f

  var startX = 0.0f
  let layout = calculateTreeLayout(rootNode, 0, startX, cardW, cardH, gapX, gapY)

  let treeWidth = startX - gapX
  var treeHeight = cardH
  proc getTreeHeight(node: LayoutNode): float32 =
    result = node.y + node.height
    for c in node.children:
      let ch = getTreeHeight(c)
      if ch > result: result = ch
  treeHeight = getTreeHeight(layout)

  # Center the layout inside bounds
  let originX = bounds.x + max(margin, (bounds.w - treeWidth) * 0.5f)
  let originY = bounds.y + max(margin, (bounds.h - treeHeight) * 0.5f)

  drawLayoutTree(ctx, font, layout, originX, originY, clamp(config.animationProgress, 0.0f, 1.0f), config)

  ctx.restore()
