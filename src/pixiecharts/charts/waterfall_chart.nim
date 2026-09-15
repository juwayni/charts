import std/[math, options]
import pixie
import ../types, ../helpers

proc drawWaterfallChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  entries: openArray[WaterfallEntry],
  config: ChartConfig = defaultChartConfig(),
  gainColor: Color = color(0.15f, 0.68f, 0.38f, 1.0f),
  lossColor: Color = color(0.91f, 0.30f, 0.24f, 1.0f),
  totalColor: Color = color(0.18f, 0.53f, 0.82f, 1.0f)
) =
  if entries.len == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  # First pass: compute the TRUE (final, un-animated) start/end running
  # values for every bar. Interpolating the increment itself (rather than
  # each bar's own start->end span) would leave adjacent bars briefly
  # mismatched mid-animation, since a later bar's baseline would already
  # reflect the fully-summed running total while the current bar was still
  # only partially grown. Precomputing here keeps every frame internally
  # consistent - only the reveal of each bar (not the underlying math) animates.
  var trueStart = newSeq[float32](entries.len)
  var trueEnd = newSeq[float32](entries.len)
  var runningTotal = 0.0f
  var minVal = 0.0f
  var maxVal = 0.0f

  for i in 0 ..< entries.len:
    let e = entries[i]
    case e.kind
    of Normal:
      trueStart[i] = runningTotal
      runningTotal += e.value
      trueEnd[i] = runningTotal
    of Subtotal, Total:
      trueStart[i] = 0.0f
      runningTotal = e.value
      trueEnd[i] = runningTotal
    if runningTotal < minVal: minVal = runningTotal
    if runningTotal > maxVal: maxVal = runningTotal

  var range, niceMin, niceMax, tickSpacing: float64
  calculateNiceScale(minVal.float64, maxVal.float64, config.yAxisMaxTicks, range, tickSpacing, niceMin, niceMax)
  let valRange = max(1.0f, (niceMax - niceMin).float32)

  font.size = config.labelTextSize
  let footerH = config.labelTextSize + (config.margin * 1.5f)
  let headerH = config.margin + config.valueLabelTextSize
  let chartW = bounds.w - (config.margin * 2.0f)
  let chartH = bounds.h - footerH - headerH
  let origin = headerH + chartH - (((0.0f - niceMin.float32) / valRange) * chartH)
  let progress = config.animationProgress

  # Horizontal 0-baseline
  let baselineAlpha = clamp(progress / 0.2f, 0.0f, 1.0f)
  ctx.beginPath()
  ctx.moveTo(config.margin, origin)
  ctx.lineTo(config.margin + chartW, origin)
  ctx.strokeStyle = config.yAxisLinesColor.withAlpha(config.yAxisLinesColor.a * baselineAlpha)
  ctx.lineWidth = 1.0f
  ctx.stroke()

  let nbItems = entries.len.float32
  let slotW = chartW / nbItems
  let barW = max(4.0f, slotW * 0.65f)

  for i in 0 ..< entries.len:
    let e = entries[i]
    let cx = config.margin + (i.float32 * slotW) + (slotW * 0.5f)
    let leftX = cx - (barW * 0.5f)

    # Each bar grows in turn, left to right, from its own true baseline.
    let itemT = easeOutQuad(staggerProgress(i, entries.len, progress, 0.6f))
    let alpha = min(1.0f, itemT * 2.0f)
    let startVal = trueStart[i]
    let endVal = lerp(startVal, trueEnd[i], itemT)

    let yStart = headerH + chartH - (((startVal - niceMin.float32) / valRange) * chartH)
    let yEnd = headerH + chartH - (((endVal - niceMin.float32) / valRange) * chartH)
    let yEndFull = headerH + chartH - (((trueEnd[i] - niceMin.float32) / valRange) * chartH)

    let barTop = min(yStart, yEnd)
    let barH = max(2.0f, abs(yEnd - yStart))

    let segColor = if e.color.isSome:
                     e.color.get
                   elif e.kind != Normal:
                     totalColor
                   elif e.value >= 0.0f:
                     gainColor
                   else:
                     lossColor

    ctx.fillStyle = color(0.0f, 0.0f, 0.0f, 0.14f * alpha)
    ctx.fillRect(leftX + 1.5f, barTop + 2.5f, barW, barH)

    let barPath = newPath()
    let barRad = min(3.0f, min(barW, barH) * 0.5f)
    barPath.roundedRect(rect(leftX, barTop, barW, barH), barRad, barRad)
    ctx.fillStyle = segColor.withAlpha(segColor.a * alpha)
    ctx.fillPath(barPath)

    let sheenH = min(barH * 0.4f, 8.0f)
    if sheenH > 1.5f:
      ctx.fillStyle = color(1.0f, 1.0f, 1.0f, 0.16f * alpha)
      ctx.fillRect(leftX, barTop, barW, sheenH)

    # Connector line to next step - fades in once this bar has landed
    if i < entries.len - 1:
      let nextCx = config.margin + ((i.float32 + 1.0f) * slotW) + (slotW * 0.5f)
      let connT = clamp((itemT - 0.7f) / 0.3f, 0.0f, 1.0f)
      if connT > 0.0f:
        ctx.beginPath()
        ctx.moveTo(cx + (barW * 0.5f), yEndFull)
        ctx.lineTo(nextCx - (barW * 0.5f), yEndFull)
        ctx.strokeStyle = color(0.6f, 0.6f, 0.6f, 0.75f * connT)
        ctx.lineWidth = 1.0f
        ctx.stroke()

    # Category label
    drawTextAligned(ctx, font, e.label, vec2(cx, bounds.h - (footerH * 0.5f)), config.labelColor.withAlpha(alpha), CenterAlign, MiddleAlign)

    # Value label
    let valStr = (if e.value > 0.0f and e.kind == Normal: "+" else: "") & formatNiceNumber(e.value)
    let valY = if yEndFull < yStart: barTop - 6.0f else: barTop + barH + 10.0f
    drawTextAligned(ctx, font, valStr, vec2(cx, valY), segColor.withAlpha(alpha), CenterAlign, MiddleAlign)

  ctx.restore()
