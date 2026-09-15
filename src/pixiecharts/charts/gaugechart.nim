import std/[math]
import pixie
import ../types, ../helpers

proc drawRadialGaugeChart*(
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

  var validEntries: seq[ChartEntry] = @[]
  for e in entries:
    if e.hasValue:
      validEntries.add(e)

  if validEntries.len == 0:
    ctx.restore()
    return

  var absMin = abs(validEntries[0].value)
  var absMax = abs(validEntries[0].value)
  for e in validEntries:
    let av = abs(e.value)
    if av < absMin: absMin = av
    if av > absMax: absMax = av

  let valRange = if absMax == absMin: 1.0f else: absMax - absMin
  let radius = (min(bounds.w, bounds.h) - (2.0f * config.margin)) * 0.5f
  let cx = bounds.w * 0.5f
  let cy = bounds.h * 0.5f

  let count = validEntries.len.float32
  let lineWidth = if config.lineSize < 0.0f: radius / ((count + 1.0f) * 2.0f) else: config.lineSize
  let radiusSpace = radius / (count + 1.0f)

  ctx.lineCap = RoundCap
  let startAngleRad = config.startAngle * (PI / 180.0f)
  let ringCount = validEntries.len

  for i in 0 ..< validEntries.len:
    let entry = validEntries[i]
    let entryRadius = (i.float32 + 1.0f) * radiusSpace

    # Background Ring
    ctx.beginPath()
    ctx.circle(cx, cy, entryRadius)
    ctx.strokeStyle = entry.color.withAlpha(config.gaugeAreaAlpha)
    ctx.lineWidth = lineWidth
    ctx.stroke()

    # Active Progress Sweep - rings sweep on one after another (outer
    # ring first) rather than all in perfect lockstep.
    let ringT = easeOutCubic(staggerProgress(i, ringCount, config.animationProgress, 0.7f))
    let sweepAngle = ringT * (2.0f * PI) * ((abs(entry.value) - absMin) / valRange)
    if sweepAngle > 0.001f:
      # Soft shadow copy of the arc, offset slightly, for a hint of depth
      ctx.beginPath()
      ctx.arc(cx + 1.0f, cy + 2.0f, entryRadius, startAngleRad, startAngleRad + sweepAngle, false)
      ctx.strokeStyle = color(0.0f, 0.0f, 0.0f, 0.16f)
      ctx.lineWidth = lineWidth
      ctx.stroke()

      ctx.beginPath()
      ctx.arc(cx, cy, entryRadius, startAngleRad, startAngleRad + sweepAngle, false)
      ctx.strokeStyle = entry.color
      ctx.lineWidth = lineWidth
      ctx.stroke()

  # Draw Legend Elements
  var drawableArea = rect(0, 0, bounds.w, bounds.h)
  let halfCount = validEntries.len div 2
  let rightValues = validEntries[0 ..< halfCount]
  let leftValues = validEntries[halfCount ..< validEntries.len]

  drawCaptionElementsSide(ctx, font, rightValues, bounds.w, bounds.h, config.margin, config.labelTextSize, config.animationProgress, false, drawableArea)
  drawCaptionElementsSide(ctx, font, leftValues, bounds.w, bounds.h, config.margin, config.labelTextSize, config.animationProgress, true, drawableArea)

  ctx.restore()

proc drawHalfRadialGaugeChart*(
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

  var validEntries: seq[ChartEntry] = @[]
  for e in entries:
    if e.hasValue:
      validEntries.add(e)

  if validEntries.len == 0:
    ctx.restore()
    return

  var absMin = abs(validEntries[0].value)
  var absMax = abs(validEntries[0].value)
  for e in validEntries:
    let av = abs(e.value)
    if av < absMin: absMin = av
    if av > absMax: absMax = av

  let valRange = if absMax == absMin: 1.0f else: absMax - absMin
  var radius = (min(bounds.w, bounds.h) - (2.0f * config.margin)) * 0.5f
  if bounds.w * 0.5f < bounds.h:
    radius = (min(bounds.w, bounds.h) - (2.0f * config.margin)) * 0.25f

  let cx = bounds.w * 0.5f
  let cy = (bounds.h * 0.5f) + radius - config.margin
  let count = validEntries.len.float32
  let lineWidth = if config.lineSize < 0.0f: radius / (count + 1.0f) else: config.lineSize
  let radiusSpace = lineWidth

  ctx.lineCap = RoundCap
  let startAngleRad = PI
  let ringCount = validEntries.len

  for i in 0 ..< validEntries.len:
    let entry = validEntries[i]
    var entryRadius = (i.float32 + 1.0f) * radiusSpace
    if validEntries.len == 1:
      entryRadius = radius - (radiusSpace * 0.5f)

    # 180° Top Arch Background
    ctx.beginPath()
    ctx.arc(cx, cy, entryRadius, startAngleRad, startAngleRad + PI, false)
    ctx.strokeStyle = entry.color.withAlpha(config.gaugeAreaAlpha)
    ctx.lineWidth = lineWidth
    ctx.stroke()

    # Active Sweep - rings sweep on one after another
    let ringT = easeOutCubic(staggerProgress(i, ringCount, config.animationProgress, 0.7f))
    let sweepAngle = ringT * PI * ((abs(entry.value) - absMin) / valRange)
    if sweepAngle > 0.001f:
      ctx.beginPath()
      ctx.arc(cx + 1.0f, cy + 2.0f, entryRadius, startAngleRad, startAngleRad + sweepAngle, false)
      ctx.strokeStyle = color(0.0f, 0.0f, 0.0f, 0.16f)
      ctx.lineWidth = lineWidth
      ctx.stroke()

      ctx.beginPath()
      ctx.arc(cx, cy, entryRadius, startAngleRad, startAngleRad + sweepAngle, false)
      ctx.strokeStyle = entry.color
      ctx.lineWidth = lineWidth
      ctx.stroke()

  # Draw Legend Elements
  var drawableArea = rect(0, 0, bounds.w, bounds.h)
  let halfCount = validEntries.len div 2
  let rightValues = validEntries[0 ..< halfCount]
  let leftValues = validEntries[halfCount ..< validEntries.len]

  drawCaptionElementsSide(ctx, font, rightValues, bounds.w, bounds.h, config.margin, config.labelTextSize, config.animationProgress, false, drawableArea)
  drawCaptionElementsSide(ctx, font, leftValues, bounds.w, bounds.h, config.margin, config.labelTextSize, config.animationProgress, true, drawableArea)

  ctx.restore()
