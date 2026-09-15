import std/[math]
import pixie
import ../types, ../helpers

proc drawDumbbellChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  entries: openArray[DumbbellEntry],
  config: ChartConfig = defaultChartConfig(),
  dotRadius: float32 = 6.0f
) =
  if entries.len == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  var minVal = entries[0].valA
  var maxVal = entries[0].valA
  for e in entries:
    if e.valA < minVal: minVal = e.valA
    if e.valB < minVal: minVal = e.valB
    if e.valA > maxVal: maxVal = e.valA
    if e.valB > maxVal: maxVal = e.valB

  var range, niceMin, niceMax, tickSpacing: float64
  calculateNiceScale(minVal.float64, maxVal.float64, config.yAxisMaxTicks, range, tickSpacing, niceMin, niceMax)
  let valRange = max(1.0f, (niceMax - niceMin).float32)

  font.size = config.labelTextSize
  var maxLabelW = 0.0f
  for e in entries:
    let w = font.measureTextSize(e.label).x
    if w > maxLabelW: maxLabelW = w

  let leftMargin = config.margin + maxLabelW + 15.0f
  let bottomMargin = config.margin + config.labelTextSize + 10.0f
  let chartW = bounds.w - leftMargin - config.margin
  let chartH = bounds.h - config.margin - bottomMargin

  let count = entries.len.float32
  let slotH = chartH / count
  let progress = config.animationProgress

  for i in 0 ..< entries.len:
    let e = entries[i]
    let y = config.margin + (i.float32 * slotH) + (slotH * 0.5f)

    # Rows sweep in top-to-bottom; the shaft slides in from the left
    # first, then each dot pops on with a gentle overshoot.
    let itemT = staggerProgress(i, entries.len, progress, 0.65f)
    let slideT = easeOutQuad(itemT)
    let dotAT = easeOutBack(clamp(itemT / 0.5f, 0.0f, 1.0f))
    let dotBT = easeOutBack(clamp((itemT - 0.3f) / 0.7f, 0.0f, 1.0f))
    let rowAlpha = min(1.0f, itemT * 2.0f)

    let targetXA = leftMargin + (((e.valA - niceMin.float32) / valRange) * chartW)
    let targetXB = leftMargin + (((e.valB - niceMin.float32) / valRange) * chartW)
    let xA = leftMargin + ((targetXA - leftMargin) * slideT)
    let xB = leftMargin + ((targetXB - leftMargin) * slideT)

    # Connecting Shaft
    ctx.beginPath()
    ctx.moveTo(xA, y)
    ctx.lineTo(xB, y)
    ctx.strokeStyle = color(0.7f, 0.7f, 0.7f, rowAlpha)
    ctx.lineWidth = 3.0f
    ctx.stroke()

    # Dot A
    if dotAT > 0.0f:
      ctx.fillStyle = e.colorA.withAlpha(min(1.0f, dotAT))
      ctx.beginPath()
      ctx.circle(xA, y, dotRadius * clamp(dotAT, 0.0f, 1.15f))
      ctx.fill()

    # Dot B
    if dotBT > 0.0f:
      ctx.fillStyle = e.colorB.withAlpha(min(1.0f, dotBT))
      ctx.beginPath()
      ctx.circle(xB, y, dotRadius * clamp(dotBT, 0.0f, 1.15f))
      ctx.fill()

    # Category label
    drawTextAligned(ctx, font, e.label, vec2(leftMargin - 10.0f, y), config.labelColor.withAlpha(rowAlpha), RightAlign, MiddleAlign)

  ctx.restore()
