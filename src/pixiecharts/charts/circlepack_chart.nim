import std/[math, algorithm]
import pixie
import ../types, ../helpers

proc drawCirclePackingChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  items: openArray[PackedCircleItem],
  config: ChartConfig = defaultChartConfig()
) =
  let count = items.len
  if count == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  var sortedItems = @items
  sortedItems.sort(proc(a, b: PackedCircleItem): int = cmp(b.value, a.value))

  var totalVal = 0.0f
  for it in sortedItems: totalVal += it.value
  if totalVal <= 0.0f: totalVal = 1.0f

  let center = vec2(bounds.w * 0.5f, bounds.h * 0.5f)
  let maxArea = (bounds.w - config.margin * 2.0f) * (bounds.h - config.margin * 2.0f) * 0.35f
  let progress = config.animationProgress

  # NOTE: final radii are computed WITHOUT the animation progress factor,
  # so the packing/relaxation layout below is stable and identical across
  # every frame. `progress` is applied only afterwards, purely as a visual
  # scale on the already-settled circles - otherwise the whole layout would
  # visibly reflow as it animated, since smaller mid-animation radii would
  # pack differently than the final ones.
  var radii: seq[float32] = @[]
  for it in sortedItems:
    let r = sqrt((it.value / totalVal) * maxArea / PI)
    radii.add(max(6.0f, r))

  # Tangent spiral relaxation (operates on final radii only)
  var centers: seq[Vec2] = @[]
  centers.add(center)

  for i in 1 ..< count:
    let r_i = radii[i]
    var theta = 0.0f
    var placed = false
    while theta < 80.0f and not placed:
      let dist = (radii[0] + r_i) + (theta * 3.0f)
      let cand = vec2(center.x + (dist * cos(theta)), center.y + (dist * sin(theta)))

      var overlaps = false
      for j in 0 ..< i:
        let d = (cand - centers[j]).length
        if d < (r_i + radii[j]):
          overlaps = true
          break

      if not overlaps:
        centers.add(cand)
        placed = true
      theta += 0.25f

    if not placed:
      centers.add(vec2(center.x + 100.0f, center.y))

  # Circles pop in one after another (largest first, matching the sort
  # order), each with a soft overshoot as it "bubbles" into place.
  for i in 0 ..< count:
    let it = sortedItems[i]
    let c = centers[i]
    let itemT = easeOutBack(staggerProgress(i, count, progress, 0.6f))
    if itemT <= 0.0f:
      continue
    let r = radii[i] * clamp(itemT, 0.0f, 1.1f)
    let alpha = min(1.0f, itemT)

    ctx.fillStyle = it.color.withAlpha(0.70f * alpha)
    ctx.beginPath()
    ctx.circle(c.x, c.y, r)
    ctx.fill()

    ctx.strokeStyle = it.color.withAlpha(alpha)
    ctx.lineWidth = 1.5f
    ctx.stroke()

    if r > 16.0f:
      font.size = min(12.0f, r * 0.35f)
      drawTextAligned(ctx, font, it.label, c, color(1, 1, 1, alpha), CenterAlign, MiddleAlign)

  ctx.restore()
