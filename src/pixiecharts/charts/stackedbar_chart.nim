import std/[math, options]
import pixie
import ../types, ../helpers

proc drawStackedBarChart*(
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

  let firstSerie = seriesList[0]
  let nbItems = firstSerie.entries.len
  if nbItems == 0:
    ctx.restore()
    return

  var maxPositive = 0.0f
  var maxNegative = 0.0f

  for i in 0 ..< nbItems:
    var posSum = 0.0f
    var negSum = 0.0f
    for s in seriesList:
      if i < s.entries.len and s.entries[i].hasValue:
        let v = s.entries[i].value
        if v >= 0.0f: posSum += v
        else: negSum += abs(v)
    if posSum > maxPositive: maxPositive = posSum
    if negSum > maxNegative: maxNegative = negSum

  var range, niceMin, niceMax, tickSpacing: float64
  calculateNiceScale(-maxNegative.float64, maxPositive.float64, config.yAxisMaxTicks, range, tickSpacing, niceMin, niceMax)
  let valRange = max(1.0f, (niceMax - niceMin).float32)

  let width = bounds.w
  let height = bounds.h
  font.size = config.labelTextSize

  var labelSizes: seq[Vec2] = @[]
  for e in firstSerie.entries:
    labelSizes.add(font.measureTextSize(e.label))

  let footerHeight = calculateFooterHeaderHeight(config.margin, config.labelTextSize, labelSizes, config.labelOrientation)
  let headerHeight = config.margin
  let itemSize = calculateItemSize(nbItems, width, height, footerHeight + headerHeight, config.margin)
  let origin = calculateYOrigin(itemSize.y, headerHeight, niceMax.float32, niceMin.float32, valRange)

  # Draw X-Axis Labels
  for i in 0 ..< nbItems:
    let itemX = config.margin + (itemSize.x * 0.5f) + (i.float32 * (itemSize.x + config.margin))
    let label = firstSerie.entries[i].label
    let rot = if config.labelOrientation == Orientation.Vertical: -PI * 0.5f else: 0.0f
    let align = if config.labelOrientation == Orientation.Vertical: RightAlign else: CenterAlign
    drawTextAligned(ctx, font, label, vec2(itemX, height - footerHeight + config.margin), config.labelColor, align, MiddleAlign, rot)

  # Stack & Render Segments - each column sweeps upward/downward from the
  # baseline in turn, one column after another.
  let progress = config.animationProgress
  for i in 0 ..< nbItems:
    let itemX = config.margin + (i.float32 * (itemSize.x + config.margin))
    var currentPosOrigin = origin
    var currentNegOrigin = origin
    let colT = easeOutQuad(staggerProgress(i, nbItems, progress, 0.65f))
    let colAlpha = min(1.0f, colT * 2.0f)

    for sIdx in 0 ..< seriesList.len:
      let serie = seriesList[sIdx]
      if i >= serie.entries.len: continue
      let entry = serie.entries[i]
      if not entry.hasValue or entry.value == 0.0f: continue

      let segHeight = (abs(entry.value) / valRange) * itemSize.y * colT
      let segColor = serie.color.get(entry.color)
      ctx.fillStyle = segColor.withAlpha(segColor.a * colAlpha)

      if entry.value > 0.0f:
        let y = currentPosOrigin - segHeight
        ctx.fillRect(itemX, y, itemSize.x, segHeight)
        currentPosOrigin = y
      else:
        let y = currentNegOrigin
        ctx.fillRect(itemX, y, itemSize.x, segHeight)
        currentNegOrigin = y + segHeight

      # Mid-segment Value Tag
      if segHeight > config.valueLabelTextSize and entry.valueLabel.len > 0:
        font.size = config.valueLabelTextSize * 0.85f
        let midY = if entry.value > 0.0f: currentPosOrigin + (segHeight * 0.5f) else: currentNegOrigin - (segHeight * 0.5f)
        drawTextAligned(ctx, font, entry.valueLabel, vec2(itemX + (itemSize.x * 0.5f), midY), color(1, 1, 1, colAlpha), CenterAlign, MiddleAlign)

  ctx.restore()
