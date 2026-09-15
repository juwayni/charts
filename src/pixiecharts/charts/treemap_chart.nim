import std/[math, algorithm]
import pixie
import ../types, ../helpers

proc drawTreemapPartition(
  ctx: Context,
  font: Font,
  items: openArray[TreemapItem],
  r: Rect,
  totalVal: float32,
  vertical: bool,
  startIndex, totalCount: int,
  progress: float32
) =
  if items.len == 0 or r.w <= 0.0f or r.h <= 0.0f:
    return

  if items.len == 1:
    let it = items[0]
    # Each tile pops in from its own center with a gentle overshoot,
    # staggered by its position in the (size-sorted) item list.
    let itemT = easeOutBack(staggerProgress(startIndex, max(totalCount, 1), progress, 0.6f))
    if itemT <= 0.0f:
      return
    let scale = clamp(itemT, 0.0f, 1.05f)
    let a = min(1.0f, itemT)
    let w = (r.w - 2.0f) * scale
    let h = (r.h - 2.0f) * scale
    let x = r.x + 1.0f + ((r.w - 2.0f - w) * 0.5f)
    let y = r.y + 1.0f + ((r.h - 2.0f - h) * 0.5f)

    ctx.fillStyle = it.color.withAlpha(a)
    ctx.fillRect(x, y, w, h)
    # subtle inner highlight along the top edge for a touch of depth
    ctx.fillStyle = color(1.0f, 1.0f, 1.0f, 0.10f * a)
    ctx.fillRect(x, y, w, min(4.0f, h * 0.15f))

    if r.w > 35.0f and r.h > 20.0f and scale > 0.55f:
      font.size = min(14.0f, min(r.w * 0.25f, r.h * 0.35f))
      drawTextAligned(ctx, font, it.label, vec2(r.x + (r.w * 0.5f), r.y + (r.h * 0.5f)), color(1, 1, 1, a), CenterAlign, MiddleAlign)
    return

  var halfVal = 0.0f
  var splitIdx = 0
  for i in 0 ..< items.len:
    halfVal += items[i].value
    if halfVal >= totalVal * 0.5f or i == items.len - 2:
      splitIdx = i + 1
      break

  let firstSlice = items[0 ..< splitIdx]
  let secondSlice = items[splitIdx ..< items.len]
  let frac = halfVal / totalVal

  if vertical:
    let w1 = r.w * frac
    let r1 = rect(r.x, r.y, w1, r.h)
    let r2 = rect(r.x + w1, r.y, r.w - w1, r.h)
    drawTreemapPartition(ctx, font, firstSlice, r1, halfVal, false, startIndex, totalCount, progress)
    drawTreemapPartition(ctx, font, secondSlice, r2, totalVal - halfVal, false, startIndex + splitIdx, totalCount, progress)
  else:
    let h1 = r.h * frac
    let r1 = rect(r.x, r.y, r.w, h1)
    let r2 = rect(r.x, r.y + h1, r.w, r.h - h1)
    drawTreemapPartition(ctx, font, firstSlice, r1, halfVal, true, startIndex, totalCount, progress)
    drawTreemapPartition(ctx, font, secondSlice, r2, totalVal - halfVal, true, startIndex + splitIdx, totalCount, progress)

proc drawTreemapChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  items: openArray[TreemapItem],
  config: ChartConfig = defaultChartConfig()
) =
  if items.len == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  var sortedItems = @items
  sortedItems.sort(proc(a, b: TreemapItem): int = cmp(b.value, a.value))

  var total = 0.0f
  for it in sortedItems: total += it.value
  if total <= 0.0f:
    ctx.restore()
    return

  let r = rect(config.margin, config.margin, bounds.w - (config.margin * 2.0f), bounds.h - (config.margin * 2.0f))
  drawTreemapPartition(ctx, font, sortedItems, r, total, r.w >= r.h, 0, sortedItems.len, config.animationProgress)
  ctx.restore()
