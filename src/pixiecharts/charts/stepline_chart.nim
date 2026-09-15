import std/[math, options]
import pixie
import ../types, ../helpers

proc drawStepLineChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  seriesList: openArray[ChartSerie],
  config: ChartConfig = defaultChartConfig(),
  stepMode: StepMode = StepAfter
) =
  if seriesList.len == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  var minVal, maxVal: float32
  calculateMinMax(seriesList, config.minValue, config.maxValue, minVal, maxVal)

  var range, niceMin, niceMax, tickSpacing: float64
  calculateNiceScale(minVal.float64, maxVal.float64, config.yAxisMaxTicks, range, tickSpacing, niceMin, niceMax)
  let valRange = max(1.0f, (niceMax - niceMin).float32)

  font.size = config.labelTextSize
  let footerH = config.labelTextSize + (config.margin * 1.5f)
  let headerH = config.margin
  let chartW = bounds.w - (config.margin * 2.0f)
  let chartH = bounds.h - footerH - headerH
  let origin = headerH + chartH - (((0.0f - niceMin.float32) / valRange) * chartH)

  let nbItems = seriesList[0].entries.len
  if nbItems < 2:
    ctx.restore()
    return

  let stepX = chartW / (nbItems.float32 - 1.0f)
  let progress = config.animationProgress

  # The whole plot is revealed left-to-right, like the series is being
  # drawn live, via a clip rect that grows with animation progress.
  let revealT = easeOutQuad(progress)
  let revealX = config.margin + (chartW * revealT) + 2.0f

  ctx.save()
  var clip = newPath()
  clip.moveTo(0.0f, 0.0f)
  clip.lineTo(revealX, 0.0f)
  clip.lineTo(revealX, bounds.h)
  clip.lineTo(0.0f, bounds.h)
  clip.closePath()
  ctx.clipPath(clip)

  for s in seriesList:
    let sColor = s.color.get(color(0.18f, 0.53f, 0.82f, 1.0f))
    let path = newPath()
    let areaPath = newPath()
    var isFirst = true

    for i in 0 ..< (nbItems - 1):
      let e1 = s.entries[i]
      let e2 = s.entries[i + 1]
      let x1 = config.margin + (i.float32 * stepX)
      let x2 = config.margin + ((i.float32 + 1.0f) * stepX)
      let y1 = headerH + chartH - (((e1.value - niceMin.float32) / valRange) * chartH)
      let y2 = headerH + chartH - (((e2.value - niceMin.float32) / valRange) * chartH)

      if isFirst:
        path.moveTo(x1, y1)
        areaPath.moveTo(x1, origin)
        areaPath.lineTo(x1, y1)
        isFirst = false

      case stepMode
      of StepAfter:
        path.lineTo(x2, y1)
        path.lineTo(x2, y2)
        areaPath.lineTo(x2, y1)
        areaPath.lineTo(x2, y2)
      of StepBefore:
        path.lineTo(x1, y2)
        path.lineTo(x2, y2)
        areaPath.lineTo(x1, y2)
        areaPath.lineTo(x2, y2)
      of StepMiddle:
        let midX = (x1 + x2) * 0.5f
        path.lineTo(midX, y1)
        path.lineTo(midX, y2)
        path.lineTo(x2, y2)
        areaPath.lineTo(midX, y1)
        areaPath.lineTo(midX, y2)
        areaPath.lineTo(x2, y2)

    let lastX = config.margin + ((nbItems.float32 - 1.0f) * stepX)
    areaPath.lineTo(lastX, origin)
    areaPath.closePath()

    ctx.fillStyle = sColor.withAlpha(0.20f)
    ctx.fillPath(areaPath)

    ctx.strokeStyle = sColor
    ctx.lineWidth = config.lineSize
    ctx.strokePath(path)

  ctx.restore() # end clip

  # A little glowing "pen tip" at the current reveal edge sells the
  # live-drawing motion while progress < 1.
  if progress > 0.02f and progress < 0.995f:
    for s in seriesList:
      let sColor = s.color.get(color(0.18f, 0.53f, 0.82f, 1.0f))
      let posF = clamp((revealX - config.margin) / stepX, 0.0f, (nbItems - 1).float32)
      let idx = clamp(posF.int, 0, nbItems - 1)
      let e = s.entries[idx]
      let y = headerH + chartH - (((e.value - niceMin.float32) / valRange) * chartH)
      ctx.fillStyle = sColor.withAlpha(0.9f)
      ctx.beginPath()
      ctx.circle(revealX - 2.0f, y, 4.0f)
      ctx.fill()

  ctx.restore()

proc drawStepLineChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  entries: openArray[ChartEntry],
  config: ChartConfig = defaultChartConfig(),
  stepMode: StepMode = StepAfter
) =
  drawStepLineChart(ctx, font, bounds, [newChartSerie("Default", @entries)], config, stepMode)
