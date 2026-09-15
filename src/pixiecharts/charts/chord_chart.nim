import std/[math]
import pixie
import ../types, ../helpers

proc drawChordChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  data: ChordMatrix,
  config: ChartConfig = defaultChartConfig()
) =
  let n = data.names.len
  if n == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  # Compute row sums
  var rowSums = newSeq[float32](n)
  var totalSum = 0.0f
  for i in 0 ..< n:
    var sum = 0.0f
    for j in 0 ..< n:
      sum += data.matrix[i][j]
    rowSums[i] = sum
    totalSum += sum

  if totalSum <= 0.0f:
    ctx.restore()
    return

  let center = vec2(bounds.w * 0.5f, bounds.h * 0.5f)
  let outerR = (min(bounds.w, bounds.h) - (config.margin * 2.5f)) * 0.5f
  let innerR = outerR - 16.0f
  let gapAngle = 0.05f
  let availableAngle = (2.0f * PI) - (n.float32 * gapAngle)

  # Compute angular boundaries for each entity
  var arcStarts = newSeq[float32](n)
  var arcEnds = newSeq[float32](n)
  var currAngle = -PI * 0.5f

  for i in 0 ..< n:
    let span = (rowSums[i] / totalSum) * availableAngle
    arcStarts[i] = currAngle
    arcEnds[i] = currAngle + span
    currAngle += span + gapAngle

  # 1. Outer Node Arcs & Labels - sweep on first, establishing the ring
  # before ribbons start flowing between them.
  let progress = config.animationProgress
  for i in 0 ..< n:
    let arcT = easeOutQuad(staggerProgress(i, n, progress, 0.5f))
    if arcT <= 0.0f: continue
    let animEnd = arcStarts[i] + ((arcEnds[i] - arcStarts[i]) * clamp(arcT, 0.0f, 1.0f))
    let path = newPath()
    path.arc(center.x, center.y, outerR, arcStarts[i], animEnd, false)
    ctx.strokeStyle = data.colors[i].withAlpha(min(1.0f, arcT))
    ctx.lineWidth = 14.0f
    ctx.strokePath(path)

    let midA = (arcStarts[i] + arcEnds[i]) * 0.5f
    let labelR = outerR + 14.0f
    let lx = center.x + (labelR * cos(midA))
    let ly = center.y + (labelR * sin(midA))
    let align = if cos(midA) > 0.1f: LeftAlign elif cos(midA) < -0.1f: RightAlign else: CenterAlign
    font.size = config.labelTextSize * 0.85f
    drawTextAligned(ctx, font, data.names[i], vec2(lx, ly), config.labelColor.withAlpha(min(1.0f, arcT)), align, MiddleAlign)

  # 2. Flow Ribbons - flow in once the rings have (mostly) finished
  for i in 0 ..< n:
    for j in i ..< n:
      let v = data.matrix[i][j]
      if v > 0.0f:
        let ribbonT = easeOutQuad(clamp((progress - 0.35f) / 0.65f, 0.0f, 1.0f))
        if ribbonT <= 0.0f: continue
        let a1 = (arcStarts[i] + arcEnds[i]) * 0.5f
        let a2 = (arcStarts[j] + arcEnds[j]) * 0.5f

        let p1 = vec2(center.x + (innerR * cos(a1)), center.y + (innerR * sin(a1)))
        let p2 = vec2(center.x + (innerR * cos(a2)), center.y + (innerR * sin(a2)))

        let ribbon = newPath()
        ribbon.moveTo(p1.x, p1.y)
        ribbon.bezierCurveTo(center.x, center.y, center.x, center.y, p2.x, p2.y)

        ctx.strokeStyle = data.colors[i].withAlpha(0.45f * ribbonT)
        ctx.lineWidth = max(1.5f, (v / totalSum) * 40.0f)
        ctx.strokePath(ribbon)

  ctx.restore()
