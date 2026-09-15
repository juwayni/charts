import std/[math, options]
import pixie
import ../types, ../helpers

proc drawStackedAreaChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  seriesList: openArray[ChartSerie],
  config: ChartConfig = defaultChartConfig()
) =
  if seriesList.len == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  let nbItems = seriesList[0].entries.len
  if nbItems < 2:
    ctx.restore()
    return

  var maxCumulative = 0.0f
  for i in 0 ..< nbItems:
    var sum = 0.0f
    for s in seriesList:
      if i < s.entries.len and s.entries[i].hasValue:
        sum += max(0.0f, s.entries[i].value)
    if sum > maxCumulative: maxCumulative = sum

  if maxCumulative <= 0.0f: maxCumulative = 1.0f

  var range, niceMin, niceMax, tickSpacing: float64
  calculateNiceScale(0.0, maxCumulative.float64, config.yAxisMaxTicks, range, tickSpacing, niceMin, niceMax)
  let valRange = niceMax.float32

  font.size = config.labelTextSize
  let footerH = config.labelTextSize + (config.margin * 1.5f)
  let headerH = config.margin
  let chartW = bounds.w - (config.margin * 2.0f)
  let chartH = bounds.h - footerH - headerH
  let origin = headerH + chartH
  let stepX = chartW / (nbItems.float32 - 1.0f)
  let progress = config.animationProgress

  # Precalculate Cumulative Heights (using TRUE, un-animated values so the
  # stack's internal geometry stays consistent across every frame; only
  # the reveal - not the underlying stacking math - animates).
  var baselines: seq[seq[float32]] = @[]
  var currentBaseline = newSeq[float32](nbItems)
  baselines.add(currentBaseline)

  for s in seriesList:
    var nextBaseline = newSeq[float32](nbItems)
    for i in 0 ..< nbItems:
      let v = if i < s.entries.len and s.entries[i].hasValue: max(0.0f, s.entries[i].value) else: 0.0f
      nextBaseline[i] = currentBaseline[i] + v
    baselines.add(nextBaseline)
    currentBaseline = nextBaseline

  # The whole stack reveals left-to-right (like it's being plotted live),
  # while layers still settle in with a slight stagger back-to-front.
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

  # Render Stacked Polygons from Back to Front
  for sIdx in countdown(seriesList.len - 1, 0):
    let serie = seriesList[sIdx]
    let topVals = baselines[sIdx + 1]
    let botVals = baselines[sIdx]
    let sColor = serie.color.get(color(0.2f, 0.4f, 0.8f, 1.0f))
    let layerAlpha = min(1.0f, clamp(progress / 0.3f, 0.0f, 1.0f))

    let path = newPath()
    # Top profile forwards
    for i in 0 ..< nbItems:
      let x = config.margin + (i.float32 * stepX)
      let y = origin - ((topVals[i] / valRange) * chartH)
      if i == 0: path.moveTo(x, y)
      else: path.lineTo(x, y)

    # Bottom profile backwards
    for i in countdown(nbItems - 1, 0):
      let x = config.margin + (i.float32 * stepX)
      let y = origin - ((botVals[i] / valRange) * chartH)
      path.lineTo(x, y)

    path.closePath()
    ctx.fillStyle = sColor.withAlpha(0.75f * layerAlpha)
    ctx.fillPath(path)

    # Top boundary line
    let linePath = newPath()
    for i in 0 ..< nbItems:
      let x = config.margin + (i.float32 * stepX)
      let y = origin - ((topVals[i] / valRange) * chartH)
      if i == 0: linePath.moveTo(x, y)
      else: linePath.lineTo(x, y)

    ctx.strokeStyle = sColor.withAlpha(layerAlpha)
    ctx.lineWidth = config.lineSize
    ctx.strokePath(linePath)

  ctx.restore() # end clip

  # X-Axis Labels
  let labelAlpha = clamp(progress / 0.3f, 0.0f, 1.0f)
  let firstSerie = seriesList[0]
  for i in 0 ..< nbItems:
    let x = config.margin + (i.float32 * stepX)
    let label = firstSerie.entries[i].label
    drawTextAligned(ctx, font, label, vec2(x, bounds.h - (footerH * 0.5f)), config.labelColor.withAlpha(labelAlpha), CenterAlign, MiddleAlign)

  ctx.restore()
