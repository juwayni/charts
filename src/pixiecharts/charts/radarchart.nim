import std/[math]
import pixie
import ../types, ../helpers

proc getRadarPoint(value, absMin, valRange: float32, center: Vec2, angle, radius: float32): Vec2 =
  let amount = abs(value - absMin) / valRange
  let r = radius * amount
  # In Microcharts Skia matrix rotation: (0, r) rotated by angle
  result.x = center.x - (r * sin(angle))
  result.y = center.y + (r * cos(angle))

proc drawRadarChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  entries: openArray[ChartEntry],
  config: ChartConfig = defaultChartConfig()
) =
  let total = entries.len
  if total == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  var maxCaptionH = 0.0f
  font.size = config.labelTextSize
  for e in entries:
    let h1 = if e.label.len > 0: config.labelTextSize else: 0.0f
    let h2 = if e.valueLabel.len > 0: config.labelTextSize else: 0.0f
    let spacing = if e.label.len > 0 and e.valueLabel.len > 0: config.labelTextSize * 0.60f else: 0.0f
    let totalH = h1 + h2 + spacing
    if totalH > maxCaptionH:
      maxCaptionH = totalH

  let center = vec2(bounds.w * 0.5f, bounds.h * 0.5f)
  let radius = ((min(bounds.w, bounds.h) - (2.0f * config.margin)) * 0.5f) - maxCaptionH
  if radius <= 0.0f:
    ctx.restore()
    return

  var absMin = abs(entries[0].value)
  var absMax = abs(entries[0].value)
  for e in entries:
    if e.hasValue:
      let av = abs(e.value)
      if av < absMin: absMin = av
      if av > absMax: absMax = av

  let valRange = if absMax == absMin: 1.0f else: absMax - absMin
  let rangeAngle = (2.0f * PI) / total.float32
  let startAngle = PI
  let progress = config.animationProgress

  # Outer Boundary Web - fades in first as the backdrop
  let webAlpha = clamp(progress / 0.3f, 0.0f, 1.0f)
  ctx.beginPath()
  ctx.circle(center.x, center.y, radius)
  ctx.strokeStyle = config.borderLineColor.withAlpha(config.borderLineColor.a * webAlpha)
  ctx.lineWidth = config.borderLineSize
  ctx.stroke()

  # Radial Spokes, Polygon Rings, and Values - each axis blooms outward
  # from the center in turn, with its point popping into place last.
  for i in 0 ..< total:
    let angle = startAngle + (rangeAngle * i.float32)
    let entry = entries[i]
    let axisT = easeOutQuad(staggerProgress(i, total, progress, 0.65f))
    let axisAlpha = min(1.0f, axisT * 2.0f)

    var nextIdx = (i + 1) mod total
    while not entries[nextIdx].hasValue:
      nextIdx = (nextIdx + 1) mod total
    let nextAngle = startAngle + (rangeAngle * nextIdx.float32)
    let nextEntry = entries[nextIdx]
    let nextAxisT = easeOutQuad(staggerProgress(nextIdx, total, progress, 0.65f))

    if entry.hasValue:
      let pt = getRadarPoint(entry.value * axisT, absMin, valRange, center, angle, radius)
      let nextPt = getRadarPoint(nextEntry.value * nextAxisT, absMin, valRange, center, nextAngle, radius)
      let borderPt = getRadarPoint(absMax, absMin, valRange, center, angle, radius)

      # 1. Spoke Line
      ctx.beginPath()
      ctx.moveTo(center.x, center.y)
      ctx.lineTo(borderPt.x, borderPt.y)
      ctx.strokeStyle = config.borderLineColor.withAlpha(config.borderLineColor.a * webAlpha)
      ctx.lineWidth = config.borderLineSize
      ctx.stroke()

      # 2. Concentric Indicator Ring
      let amount = abs((entry.value * clamp(axisT, 0.0f, 1.0f)) - absMin) / valRange
      ctx.beginPath()
      ctx.circle(center.x, center.y, radius * amount)
      ctx.strokeStyle = entry.color.withAlpha(entry.color.a * 0.75f * axisAlpha)
      ctx.lineWidth = config.borderLineSize
      ctx.stroke()

      # 3. Web Connection Lines
      ctx.beginPath()
      ctx.moveTo(center.x, center.y)
      ctx.lineTo(pt.x, pt.y)
      ctx.strokeStyle = entry.color.withAlpha(entry.color.a * 0.75f * axisAlpha)
      ctx.lineWidth = config.lineSize
      ctx.stroke()

      ctx.beginPath()
      ctx.moveTo(pt.x, pt.y)
      ctx.lineTo(nextPt.x, nextPt.y)
      ctx.strokeStyle = entry.color.withAlpha(axisAlpha)
      ctx.lineWidth = config.lineSize
      ctx.stroke()

      # 4. Point Node - pops in with a soft overshoot once its axis has
      # mostly finished growing
      let nodeT = easeOutBack(clamp((axisT - 0.5f) / 0.5f, 0.0f, 1.0f))
      if nodeT > 0.0f:
        if config.pointMode == PointMode.Circle:
          ctx.fillStyle = entry.color.withAlpha(min(1.0f, nodeT))
          ctx.beginPath()
          ctx.circle(pt.x, pt.y, config.pointSize * 0.5f * clamp(nodeT, 0.0f, 1.15f))
          ctx.fill()
        elif config.pointMode == PointMode.Square:
          let s = config.pointSize * clamp(nodeT, 0.0f, 1.15f)
          ctx.fillStyle = entry.color.withAlpha(min(1.0f, nodeT))
          ctx.fillRect(pt.x - (s * 0.5f), pt.y - (s * 0.5f), s, s)

    # 5. Label Position
    let labelR = radius + config.labelTextSize + (config.pointSize * 0.5f)
    let labelPt = vec2(center.x - (labelR * sin(angle)), center.y + (labelR * cos(angle)))
    var align = LeftAlign
    let eps = 0.01f

    if abs(angle - (startAngle + PI)) < eps or abs(angle - PI) < eps:
      align = CenterAlign
    elif angle > startAngle + PI:
      align = RightAlign

    var labelBounds: Rect
    drawCaptionLabels(ctx, font, entry.label, entry.textColor, entry.valueLabel, entry.color.withAlpha(axisAlpha), config.labelTextSize, labelPt, align, labelBounds)

  ctx.restore()
