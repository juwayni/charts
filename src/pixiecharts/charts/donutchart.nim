import std/[math]
import pixie
import ../types, ../helpers

proc drawCaptionElementsSide*(
  ctx: Context,
  font: Font,
  entries: openArray[ChartEntry],
  width, height, margin, textSize, animationProgress: float32,
  isLeft: bool,
  drawableArea: var Rect
) =
  if entries.len == 0:
    return

  let totalMargin = 2.0f * margin
  let availableHeight = height - (2.0f * totalMargin)
  let ySpace = if entries.len <= 1: availableHeight else: (availableHeight - textSize) / (entries.len.float32 - 1.0f)

  for i in 0 ..< entries.len:
    let entry = entries[i]
    var y = totalMargin + (i.float32 * ySpace)
    if entries.len <= 1:
      y += (availableHeight - textSize) * 0.5f

    if entry.label.len > 0 or entry.valueLabel.len > 0:
      var captionX = if isLeft: margin else: width - margin - textSize
      let legendColor = entry.color.withAlpha(animationProgress)
      let valueColor = entry.valueLabelColor.withAlpha(animationProgress)
      let lblColor = entry.textColor.withAlpha(animationProgress)

      ctx.fillStyle = legendColor
      ctx.fillRect(captionX, y, textSize, textSize)

      let captionMargin = textSize * 0.60f
      if isLeft:
        captionX += textSize + captionMargin
      else:
        captionX -= captionMargin

      var labelBounds: Rect
      let alignment = if isLeft: LeftAlign else: RightAlign
      drawCaptionLabels(ctx, font, entry.label, lblColor, entry.valueLabel, valueColor, textSize, vec2(captionX, y + (textSize * 0.5f)), alignment, labelBounds)

      if isLeft:
        drawableArea.x = max(drawableArea.x, labelBounds.x + labelBounds.w)
      else:
        drawableArea.w = min(drawableArea.w, labelBounds.x - drawableArea.x)

proc drawDonutChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  entries: openArray[ChartEntry],
  config: ChartConfig = defaultChartConfig()
) =
  if entries.len == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  var drawableArea = rect(0, 0, bounds.w, bounds.h)
  var validEntries: seq[ChartEntry] = @[]
  var sumValue = 0.0f
  for e in entries:
    if e.hasValue:
      validEntries.add(e)
      sumValue += abs(e.value)

  if validEntries.len == 0 or sumValue <= 0.0f:
    ctx.restore()
    return

  case config.labelMode
  of LabelMode.None:
    discard
  of LabelMode.RightOnly:
    drawCaptionElementsSide(ctx, font, validEntries, bounds.w, bounds.h, config.margin, config.labelTextSize, config.animationProgress, false, drawableArea)
  of LabelMode.LeftAndRight:
    var rightEntries: seq[ChartEntry] = @[]
    var leftEntries: seq[ChartEntry] = @[]
    var curr = 0.0f
    var idx = 0
    while idx < validEntries.len and curr < sumValue * 0.5f:
      rightEntries.add(validEntries[idx])
      curr += abs(validEntries[idx].value)
      inc idx
    while idx < validEntries.len:
      leftEntries.add(validEntries[idx])
      inc idx

    drawCaptionElementsSide(ctx, font, rightEntries, bounds.w, bounds.h, config.margin, config.labelTextSize, config.animationProgress, false, drawableArea)
    drawCaptionElementsSide(ctx, font, leftEntries, bounds.w, bounds.h, config.margin, config.labelTextSize, config.animationProgress, true, drawableArea)

  let centerX = if config.graphPosition == GraphPosition.Center:
                  bounds.w * 0.5f
                else:
                  drawableArea.x + (drawableArea.w * 0.5f)
  let centerY = bounds.h * 0.5f
  let radius = (min(drawableArea.w, bounds.h) - (2.0f * config.margin)) * 0.5f

  if radius > 0.0f:
    ctx.save()
    ctx.translate(centerX, centerY)

    # The pie sweeps into view like a clock hand - a growing sector clip
    # mask reveals each wedge at its TRUE final angular width (rather than
    # proportionally shrinking every wedge's width by `progress`, which
    # would repack them into a fan compressed near the start angle instead
    # of a proper clockwise reveal).
    let revealFraction = easeOutQuad(config.animationProgress)
    if revealFraction > 0.001f:
      ctx.save()
      if revealFraction < 0.999f:
        let clipPath = createSectorPath(0.0f, revealFraction, radius + 4.0f, 0.0f)
        ctx.clipPath(clipPath)

      var start = 0.0f
      # A single shadow silhouette behind the whole ring (rather than one
      # shadow per wedge, which would create ugly overlapping seams at
      # every wedge boundary) for a subtle sense of depth.
      let shadowShape = createSectorPath(0.0f, 1.0f, radius, radius * config.holeRadius)
      ctx.save()
      ctx.translate(1.5f, 3.0f)
      ctx.fillStyle = color(0.0f, 0.0f, 0.0f, 0.14f)
      ctx.fillPath(shadowShape)
      ctx.restore()

      for entry in validEntries:
        let sweep = abs(entry.value) / sumValue
        let endSweep = start + sweep
        let path = createSectorPath(start, endSweep, radius, radius * config.holeRadius)
        ctx.fillStyle = entry.color
        ctx.fillPath(path)
        ctx.strokeStyle = config.backgroundColor.withAlpha(1.0f)
        ctx.lineWidth = 2.0f
        ctx.strokePath(path)
        start = endSweep
      ctx.restore()
    ctx.restore()

  ctx.restore()

proc drawPieChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  entries: openArray[ChartEntry],
  config: ChartConfig = defaultChartConfig()
) =
  var pieConfig = config
  pieConfig.holeRadius = 0.0f
  drawDonutChart(ctx, font, bounds, entries, pieConfig)
