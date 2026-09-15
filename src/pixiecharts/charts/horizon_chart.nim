import std/[math]
import pixie
import ../types, ../helpers

proc drawHorizonChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  seriesList: openArray[HorizonSeries],
  config: ChartConfig = defaultChartConfig(),
  bands: int = 2
) =
  let count = seriesList.len
  if count == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  font.size = config.labelTextSize
  var maxNameW = 0.0f
  for s in seriesList:
    let w = font.measureTextSize(s.name).x
    if w > maxNameW: maxNameW = w

  let leftMargin = config.margin + maxNameW + 12.0f
  let chartW = bounds.w - leftMargin - config.margin
  let chartH = bounds.h - (config.margin * 2.0f)
  let slotH = chartH / count.float32

  for sIdx in 0 ..< count:
    let s = seriesList[sIdx]
    let y0 = config.margin + (sIdx.float32 * slotH)
    let nPoints = s.values.len
    if nPoints < 2: continue

    let stepX = chartW / (nPoints.float32 - 1.0f)
    var maxVal = 0.0f
    for v in s.values:
      if abs(v) > maxVal: maxVal = abs(v)
    if maxVal <= 0.0f: maxVal = 1.0f

    let bandMax = maxVal / bands.float32

    # Each row sweeps in top-to-bottom, staggered, and reveals left to
    # right within its own row via a clip mask - like a live-updating strip.
    let rowT = staggerProgress(sIdx, count, config.animationProgress, 0.7f)
    let revealX = leftMargin + (chartW * easeOutQuad(rowT))
    let rowAlpha = min(1.0f, rowT * 2.0f)

    ctx.save()
    var clip = newPath()
    clip.moveTo(0.0f, y0)
    clip.lineTo(revealX, y0)
    clip.lineTo(revealX, y0 + slotH)
    clip.lineTo(0.0f, y0 + slotH)
    clip.closePath()
    ctx.clipPath(clip)

    # Draw stacked bands
    for b in 1 .. bands:
      let path = newPath()
      var isFirst = true

      for i in 0 ..< nPoints:
        let v = s.values[i]
        let x = leftMargin + (i.float32 * stepX)
        let effectiveVal = clamp(v - ((b.float32 - 1.0f) * bandMax), 0.0f, bandMax)
        let h = (effectiveVal / bandMax) * slotH
        let y = y0 + slotH - h

        if isFirst:
          path.moveTo(x, y0 + slotH)
          isFirst = false
        path.lineTo(x, y)

      path.lineTo(leftMargin + chartW, y0 + slotH)
      path.closePath()

      let alpha = 0.40f + (0.30f * (b.float32 / bands.float32))
      ctx.fillStyle = s.positiveColor.withAlpha(alpha)
      ctx.fillPath(path)

    ctx.restore() # end clip

    # Series Title & Baseline
    drawTextAligned(ctx, font, s.name, vec2(leftMargin - 8.0f, y0 + (slotH * 0.5f)), config.labelColor.withAlpha(rowAlpha), RightAlign, MiddleAlign)
    ctx.beginPath()
    ctx.moveTo(leftMargin, y0 + slotH)
    ctx.lineTo(leftMargin + chartW, y0 + slotH)
    ctx.strokeStyle = config.yAxisLinesColor.withAlpha(config.yAxisLinesColor.a * rowAlpha)
    ctx.lineWidth = 1.0f
    ctx.stroke()

  ctx.restore()
