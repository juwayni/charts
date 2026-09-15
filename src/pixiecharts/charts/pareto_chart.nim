import std/[math, algorithm]
import pixie
import ../types, ../helpers

proc drawParetoChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  entries: openArray[ParetoEntry],
  config: ChartConfig = defaultChartConfig()
) =
  let count = entries.len
  if count == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  var sorted = @entries
  sorted.sort(proc(a, b: ParetoEntry): int = cmp(b.count, a.count))

  var totalCount = 0.0f
  for e in sorted: totalCount += e.count
  if totalCount <= 0.0f: totalCount = 1.0f

  var range, niceMin, niceMax, tickSpacing: float64
  calculateNiceScale(0.0, sorted[0].count.float64 * 1.1, config.yAxisMaxTicks, range, tickSpacing, niceMin, niceMax)
  let maxCountScale = niceMax.float32

  font.size = config.labelTextSize * 0.80f
  var leftLabelW = 0.0f
  for i in 0 .. 5:
    let w = font.measureTextSize($(int(maxCountScale * (i.float32 * 0.20f)))).x
    if w > leftLabelW: leftLabelW = w
  let rightLabelW = font.measureTextSize("100%").x

  let leftMargin = config.margin + leftLabelW + 12.0f
  let rightMargin = config.margin + rightLabelW + 12.0f
  let bottomMargin = config.margin + config.labelTextSize + 15.0f
  let chartW = bounds.w - leftMargin - rightMargin
  let chartH = bounds.h - config.margin - bottomMargin
  let originY = config.margin + chartH
  let progress = config.animationProgress

  let slotW = chartW / count.float32
  let barW = max(4.0f, slotW * 0.65f)

  # 1. 80% Cutoff Reference Line & Dual Y-Axis Labels - fade in as backdrop
  let gridAlpha = clamp(progress / 0.3f, 0.0f, 1.0f)
  let y80 = originY - (0.80f * chartH)
  ctx.beginPath()
  ctx.moveTo(leftMargin, y80)
  ctx.lineTo(leftMargin + chartW, y80)
  ctx.strokeStyle = color(0.91f, 0.30f, 0.24f, 0.60f * gridAlpha)
  ctx.lineWidth = 1.5f
  ctx.stroke()

  font.size = config.labelTextSize * 0.80f
  for i in 0 .. 5:
    let frac = i.float32 * 0.20f
    let y = originY - (frac * chartH)
    let countVal = frac * maxCountScale
    drawTextAligned(ctx, font, $(int(countVal)), vec2(leftMargin - 8.0f, y), config.yAxisTextColor.withAlpha(gridAlpha), RightAlign, MiddleAlign)
    drawTextAligned(ctx, font, $(int(frac * 100.0f)) & "%", vec2(leftMargin + chartW + 8.0f, y), color(0.91f, 0.30f, 0.24f, gridAlpha), LeftAlign, MiddleAlign)

  # 2. Frequency Bars - each pops in one after another, left to right
  for i in 0 ..< count:
    let e = sorted[i]
    let x = leftMargin + (i.float32 * slotW) + (slotW * 0.5f) - (barW * 0.5f)
    let itemT = easeOutBack(staggerProgress(i, count, progress, 0.6f))
    let h = (e.count / maxCountScale) * chartH * clamp(itemT, 0.0f, 1.0f)
    let y = originY - h
    let alpha = min(1.0f, itemT)

    if itemT > 0.0f:
      ctx.fillStyle = color(0.0f, 0.0f, 0.0f, 0.14f * alpha)
      ctx.fillRect(x + 1.5f, y + 2.5f, barW, h)

      let barPath = newPath()
      let barRad = min(4.0f, min(barW, h) * 0.5f)
      barPath.roundedRect(rect(x, y, barW, h), barRad, barRad)
      ctx.fillStyle = e.color.withAlpha(e.color.a * alpha)
      ctx.fillPath(barPath)

      let sheenH = min(h * 0.4f, 8.0f)
      if sheenH > 1.5f:
        ctx.fillStyle = color(1.0f, 1.0f, 1.0f, 0.16f * alpha)
        ctx.fillRect(x, y, barW, sheenH)

    # Category Label
    font.size = config.labelTextSize * 0.85f
    drawTextAligned(ctx, font, e.label, vec2(x + (barW * 0.5f), bounds.h - (bottomMargin * 0.5f)), config.labelColor.withAlpha(alpha), CenterAlign, MiddleAlign)

  # 3. Cumulative Percentage Line - draws left-to-right, tracing behind
  # the bars as they settle in.
  let lineT = easeOutQuad(clamp((progress - 0.2f) / 0.8f, 0.0f, 1.0f))
  var runningSum = 0.0f
  let linePath = newPath()
  var lastPt = vec2(0, 0)
  var drawnAny = false
  for i in 0 ..< count:
    runningSum += sorted[i].count
    let cumPct = runningSum / totalCount
    let cx = leftMargin + (i.float32 * slotW) + (slotW * 0.5f)
    let cy = originY - (cumPct * chartH)

    let ptT = positionStagger(i.float32, count.float32, lineT, 0.5f)
    if ptT <= 0.0f: continue

    if not drawnAny:
      linePath.moveTo(cx, cy)
      drawnAny = true
    else:
      linePath.lineTo(cx, cy)
    lastPt = vec2(cx, cy)

  ctx.strokeStyle = color(0.91f, 0.30f, 0.24f, min(1.0f, lineT * 1.5f))
  ctx.lineWidth = 2.5f
  ctx.strokePath(linePath)

  # Percentage Node Markers - pop in alongside the line as it reaches them
  runningSum = 0.0f
  for i in 0 ..< count:
    runningSum += sorted[i].count
    let cumPct = runningSum / totalCount
    let cx = leftMargin + (i.float32 * slotW) + (slotW * 0.5f)
    let cy = originY - (cumPct * chartH)
    let ptT = easeOutBack(positionStagger(i.float32, count.float32, lineT, 0.4f))
    if ptT <= 0.0f: continue
    ctx.fillStyle = color(0.91f, 0.30f, 0.24f, min(1.0f, ptT))
    ctx.beginPath()
    ctx.circle(cx, cy, 3.5f * clamp(ptT, 0.0f, 1.15f))
    ctx.fill()

  ctx.restore()
