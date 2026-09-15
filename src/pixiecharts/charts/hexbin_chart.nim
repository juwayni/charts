import std/[math, tables]
import pixie
import ../types, ../helpers

proc interpolateHexColor(c1, c2: Color, t: float32): Color =
  let f = clamp(t, 0.0f, 1.0f)
  color(c1.r + (c2.r - c1.r) * f, c1.g + (c2.g - c1.g) * f, c1.b + (c2.b - c1.b) * f, 0.80f)

proc drawHexbinChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  data: HexbinData,
  config: ChartConfig = defaultChartConfig()
) =
  if data.points.len == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  let r = data.hexRadius
  let dx = sqrt(3.0f) * r
  let dy = 1.5f * r

  # Bin counts into hexagonal grid keys
  var counts = initTable[(int, int), int]()
  var maxCount = 0

  for p in data.points:
    let q = int(round(p.x / dx))
    let row = int(round(p.y / dy))
    let key = (q, row)
    counts[key] = counts.getOrDefault(key, 0) + 1
    if counts[key] > maxCount: maxCount = counts[key]

  if maxCount == 0: maxCount = 1

  # Render Hexagons - bloom outward from the densest cell (or grid center)
  # with a gentle scale-pop, so the pattern seems to "settle" into place.
  var cx0 = 0.0f
  var cy0 = 0.0f
  var n = 0
  for key, c in counts.pairs:
    let (q, row) = key
    cx0 += (q.float32 * dx) + (if (row mod 2 != 0): dx * 0.5f else: 0.0f)
    cy0 += row.float32 * dy
    inc n
  if n > 0:
    cx0 /= n.float32
    cy0 /= n.float32

  var maxDist = 1.0f
  for key in counts.keys:
    let (q, row) = key
    let cx = (q.float32 * dx) + (if (row mod 2 != 0): dx * 0.5f else: 0.0f)
    let cy = row.float32 * dy
    let d = sqrt((cx - cx0) * (cx - cx0) + (cy - cy0) * (cy - cy0))
    if d > maxDist: maxDist = d

  for key, c in counts.pairs:
    let (q, row) = key
    let cx = (q.float32 * dx) + (if (row mod 2 != 0): dx * 0.5f else: 0.0f)
    let cy = row.float32 * dy
    let dist = sqrt((cx - cx0) * (cx - cx0) + (cy - cy0) * (cy - cy0))
    let cellT = easeOutBack(positionStagger(dist, maxDist, config.animationProgress, 0.6f))
    if cellT <= 0.0f:
      continue
    let norm = c.float32 / maxCount.float32
    let cellColor = interpolateHexColor(data.colorLow, data.colorHigh, norm)
    let hexScale = clamp(cellT, 0.0f, 1.1f)

    let hexPath = newPath()
    for i in 0 ..< 6:
      let a = (i.float32 * (PI / 3.0f)) + (PI / 6.0f)
      let vx = cx + (((r - 1.0f) * hexScale) * cos(a))
      let vy = cy + (((r - 1.0f) * hexScale) * sin(a))
      if i == 0: hexPath.moveTo(vx, vy)
      else: hexPath.lineTo(vx, vy)
    hexPath.closePath()

    ctx.fillStyle = cellColor.withAlpha(cellColor.a * min(1.0f, cellT))
    ctx.fillPath(hexPath)

  ctx.restore()
