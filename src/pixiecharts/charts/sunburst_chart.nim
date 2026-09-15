import std/[math]
import pixie
import ../types, ../helpers

proc computeSunburstTotals(node: var SunburstNode): float32 =
  if node.children.len == 0:
    return node.value
  var sum = 0.0f
  for i in 0 ..< node.children.len:
    sum += computeSunburstTotals(node.children[i])
  node.value = sum
  return sum

proc getMaxDepth(node: SunburstNode, current: int = 1): int =
  result = current
  for c in node.children:
    let d = getMaxDepth(c, current + 1)
    if d > result: result = d

proc renderSunburstSlice(
  ctx: Context,
  font: Font,
  node: SunburstNode,
  center: Vec2,
  startAngle, endAngle, rInner, rOuter: float32,
  alpha: float32,
  config: ChartConfig
) =
  if endAngle - startAngle <= 0.002f or alpha <= 0.0f:
    return

  # Rings pop outward slightly from their inner edge, giving each depth
  # level a small "bloom" as it appears rather than snapping to full size.
  let animOuter = lerp(rInner, rOuter, clamp(alpha, 0.0f, 1.15f))

  let path = newPath()
  path.moveTo(center.x + (rInner * cos(startAngle)), center.y + (rInner * sin(startAngle)))
  path.arc(center.x, center.y, animOuter, startAngle, endAngle, false)
  path.lineTo(center.x + (rInner * cos(endAngle)), center.y + (rInner * sin(endAngle)))
  path.arc(center.x, center.y, rInner, endAngle, startAngle, true)
  path.closePath()

  ctx.fillStyle = node.color.withAlpha(min(1.0f, alpha))
  ctx.fillPath(path)
  ctx.strokeStyle = color(1, 1, 1, min(1.0f, alpha))
  ctx.lineWidth = 1.5f
  ctx.strokePath(path)

  # Label if angular width permits
  let arcW = (endAngle - startAngle) * rInner
  if arcW > 25.0f and alpha > 0.7f:
    let midAngle = (startAngle + endAngle) * 0.5f
    let midR = (rInner + rOuter) * 0.5f
    let lx = center.x + (midR * cos(midAngle))
    let ly = center.y + (midR * sin(midAngle))
    font.size = min(12.0f, (rOuter - rInner) * 0.35f)
    drawTextAligned(ctx, font, node.name, vec2(lx, ly), color(1, 1, 1, min(1.0f, alpha)), CenterAlign, MiddleAlign)

proc drawSunburstBranch(
  ctx: Context,
  font: Font,
  node: SunburstNode,
  center: Vec2,
  startAngle, endAngle, rInner, ringW: float32,
  depth, maxDepth: int,
  progress: float32,
  config: ChartConfig
) =
  # Each successive ring (depth level) starts its own reveal a bit after
  # the ring inside it, so the sunburst blooms outward from the center.
  let ringT = easeOutQuad(staggerProgress(depth, max(maxDepth, 1), progress, 0.7f))
  let rOuter = rInner + ringW
  renderSunburstSlice(ctx, font, node, center, startAngle, endAngle, rInner, rOuter, ringT, config)

  if node.children.len > 0 and node.value > 0.0f:
    var currA = startAngle
    let totalSpan = endAngle - startAngle
    for c in node.children:
      let cSpan = (c.value / node.value) * totalSpan
      drawSunburstBranch(ctx, font, c, center, currA, currA + cSpan, rOuter, ringW, depth + 1, maxDepth, progress, config)
      currA += cSpan

proc drawSunburstChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  rootNode: SunburstNode,
  config: ChartConfig = defaultChartConfig()
) =
  var root = rootNode
  let totalVal = computeSunburstTotals(root)
  if totalVal <= 0.0f:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  let center = vec2(bounds.w * 0.5f, bounds.h * 0.5f)
  let maxR = (min(bounds.w, bounds.h) - (config.margin * 2.0f)) * 0.5f
  let depth = getMaxDepth(root)
  let ringW = maxR / depth.float32

  let progress = config.animationProgress
  # The center disc leads the animation; outer rings sweep in angularly
  # and bloom outward ring by ring right after it.
  let centerT = easeOutBack(staggerProgress(0, depth + 1, progress, 0.6f))

  var currA = -PI * 0.5f
  for c in root.children:
    let span = (c.value / totalVal) * (2.0f * PI)
    drawSunburstBranch(ctx, font, c, center, currA, currA + span, ringW, ringW, 1, depth, progress, config)
    currA += span

  # Center Root Disc
  if centerT > 0.0f:
    ctx.fillStyle = root.color.withAlpha(min(1.0f, centerT))
    ctx.beginPath()
    ctx.circle(center.x, center.y, ringW * clamp(centerT, 0.0f, 1.15f))
    ctx.fill()
    font.size = ringW * 0.30f
    drawTextAligned(ctx, font, root.name, center, color(1, 1, 1, min(1.0f, centerT)), CenterAlign, MiddleAlign)

  ctx.restore()
