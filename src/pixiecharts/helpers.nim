import std/[math, options, os, strutils]
import pixie
import types

proc withAlpha*(c: Color, a: float32): Color {.inline.} =
  color(c.r, c.g, c.b, a)

# --- Easing Functions ---
# A small, well-tested easing toolkit. All take t in [0, 1] and return a
# (usually) [0, 1] progress value; some (easeOutBack / easeOutElastic)
# briefly overshoot past 1.0 on purpose to create a lively "pop"/"bounce".

proc easeLinear*(t: float32): float32 =
  clamp(t, 0.0f, 1.0f)

proc easeOut*(t: float32): float32 =
  ## Cubic ease-out (kept for backward-compatibility with existing code).
  let c = clamp(t, 0.0f, 1.0f)
  1.0f - pow(1.0f - c, 3.0f)

proc easeIn*(t: float32): float32 =
  let c = clamp(t, 0.0f, 1.0f)
  c * c * c

proc easeOutCubic*(t: float32): float32 =
  ## Alias of `easeOut` with an explicit name, for readability at call sites.
  easeOut(t)

proc easeInOutCubic*(t: float32): float32 =
  let c = clamp(t, 0.0f, 1.0f)
  if c < 0.5f: 4.0f * c * c * c
  else: 1.0f - pow(-2.0f * c + 2.0f, 3.0f) * 0.5f

proc easeOutQuad*(t: float32): float32 =
  let c = clamp(t, 0.0f, 1.0f)
  1.0f - (1.0f - c) * (1.0f - c)

proc easeOutBack*(t: float32): float32 =
  ## Overshoots slightly past 1.0 before settling - gives bars/points/
  ## dots a lively little "pop" as they land.
  let c = clamp(t, 0.0f, 1.0f)
  const c1 = 1.70158f
  const c3 = c1 + 1.0f
  1.0f + c3 * pow(c - 1.0f, 3.0f) + c1 * pow(c - 1.0f, 2.0f)

proc easeOutElastic*(t: float32): float32 =
  ## Springy overshoot, good for gauges/needles settling into place.
  let c = clamp(t, 0.0f, 1.0f)
  const p = 0.45f
  if c <= 0.0f: return 0.0f
  if c >= 1.0f: return 1.0f
  let s = p / 4.0f
  pow(2.0f, -10.0f * c) * sin((c - s) * (2.0f * PI) / p) + 1.0f

proc easeOutCirc*(t: float32): float32 =
  let c = clamp(t, 0.0f, 1.0f)
  sqrt(1.0f - pow(c - 1.0f, 2.0f))

proc staggerProgress*(index, total: int, progress: float32, overlap: float32 = 0.6f): float32 =
  ## Splits the global `progress` (0..1) timeline into `total` overlapping
  ## per-item windows so items animate in one after another instead of all
  ## at once, while still all finishing exactly at progress = 1.
  ## `overlap` (0..1) controls how much each item's window spans of the
  ## total timeline - smaller values give a snappier, more sequential
  ## wave; larger values make items animate almost together.
  let ov = clamp(overlap, 0.05f, 1.0f)
  if total <= 1:
    return clamp(progress / ov, 0.0f, 1.0f)
  let step = (1.0f - ov) / (total.float32 - 1.0f)
  let startT = index.float32 * step
  result = clamp((progress - startT) / ov, 0.0f, 1.0f)

proc lighten*(c: Color, amount: float32): Color =
  ## amount in [0,1]; positive lightens toward white, negative darkens toward black.
  proc adj(v: float32): float32 =
    if amount >= 0.0f: v + (1.0f - v) * amount
    else: v * (1.0f + amount)
  color(clamp(adj(c.r), 0.0f, 1.0f), clamp(adj(c.g), 0.0f, 1.0f), clamp(adj(c.b), 0.0f, 1.0f), c.a)

proc darken*(c: Color, amount: float32): Color {.inline.} =
  lighten(c, -amount)

# --- Pixie API Compatibility Wrappers ---

proc fillPath*(ctx: Context, path: Path) {.inline.} =
  ctx.fill(path)

proc strokePath*(ctx: Context, path: Path) {.inline.} =
  ctx.stroke(path)

proc fillPath*(ctx: Context, path: Path, paint: Paint) {.inline.} =
  let oldPaint = ctx.fillStyle
  ctx.fillStyle = paint
  ctx.fill(path)
  ctx.fillStyle = oldPaint

proc strokePath*(ctx: Context, path: Path, paint: Paint, strokeWidth: float32 = 1.0f) {.inline.} =
  let oldPaint = ctx.strokeStyle
  let oldWidth = ctx.lineWidth
  ctx.strokeStyle = paint
  ctx.lineWidth = strokeWidth
  ctx.stroke(path)
  ctx.strokeStyle = oldPaint
  ctx.lineWidth = oldWidth

proc clipPath*(ctx: Context, path: Path) {.inline.} =
  ctx.clip(path)

proc roundedRect*(p: Path, rect: Rect, rx, ry: float32) {.inline.} =
  p.roundedRect(rect.x, rect.y, rect.w, rect.h, rx, ry, rx, ry)

proc roundedRect*(p: Path, rect: Rect, r: float32) {.inline.} =
  p.roundedRect(rect.x, rect.y, rect.w, rect.h, r, r, r, r)

proc roundedRect*(ctx: Context, rect: Rect, r: float32) {.inline.} =
  var p = newPath()
  p.roundedRect(rect.x, rect.y, rect.w, rect.h, r, r, r, r)
  ctx.fill(p)

proc roundedRect*(ctx: Context, rect: Rect, rx, ry: float32) {.inline.} =
  var p = newPath()
  p.roundedRect(rect.x, rect.y, rect.w, rect.h, rx, ry, rx, ry)
  ctx.fill(p)

proc positionStagger*(pos, total, progress: float32, overlap: float32 = 0.5f): float32 =
  ## Like `staggerProgress`, but keyed by a continuous position (e.g. an
  ## x-coordinate, or a normalized 0..1 reading-order value) instead of a
  ## discrete index. Useful for left-to-right "wipe" reveals across trees,
  ## timelines, and other spatially laid-out charts.
  let ov = clamp(overlap, 0.05f, 1.0f)
  let frac = clamp(pos / max(total, 0.0001f), 0.0f, 1.0f)
  let startT = frac * (1.0f - ov)
  result = clamp((progress - startT) / ov, 0.0f, 1.0f)

proc lerp*(a, b: float32, t: float32): float32 {.inline.} =
  a + (b - a) * t

proc mixColor*(a, b: Color, t: float32): Color =
  let tt = clamp(t, 0.0f, 1.0f)
  color(
    a.r + (b.r - a.r) * tt,
    a.g + (b.g - a.g) * tt,
    a.b + (b.b - a.b) * tt,
    a.a + (b.a - a.a) * tt
  )

const NicePalette*: array[10, Color] = [
  color(0.20f, 0.47f, 0.93f, 1.0f), # blue
  color(0.94f, 0.33f, 0.33f, 1.0f), # coral red
  color(0.16f, 0.71f, 0.51f, 1.0f), # emerald
  color(0.96f, 0.70f, 0.20f, 1.0f), # amber
  color(0.58f, 0.40f, 0.93f, 1.0f), # violet
  color(0.20f, 0.74f, 0.85f, 1.0f), # cyan
  color(0.95f, 0.47f, 0.68f, 1.0f), # pink
  color(0.55f, 0.65f, 0.24f, 1.0f), # olive
  color(0.98f, 0.55f, 0.28f, 1.0f), # orange
  color(0.35f, 0.42f, 0.55f, 1.0f), # slate
]

proc paletteColor*(i: int): Color {.inline.} =
  NicePalette[((i mod NicePalette.len) + NicePalette.len) mod NicePalette.len]

proc drawSoftShadow*(
  ctx: Context,
  shapePath: proc(p: Path),
  offset: Vec2 = vec2(0.0f, 3.0f),
  color: Color = color(0.0f, 0.0f, 0.0f, 0.16f),
  layers: int = 6,
  spread: float32 = 4.0f,
  alpha: float32 = 1.0f
) =
  ## Cheap, dependency-free "soft shadow" made from several translucent
  ## copies of a shape nudged around a small ring, to fake a blurred drop
  ## shadow without needing a real blur filter. `shapePath` builds the
  ## base shape (in local/untranslated coordinates) into the given Path.
  if layers <= 0 or alpha <= 0.0f:
    return
  ctx.save()
  ctx.translate(offset.x, offset.y)
  let baseAlpha = (color.a * alpha) / layers.float32
  for i in 0 ..< layers:
    let ang = (i.float32 / layers.float32) * 2.0f * PI
    let dx = cos(ang) * spread
    let dy = sin(ang) * spread
    ctx.save()
    ctx.translate(dx, dy)
    var p = newPath()
    shapePath(p)
    ctx.fillStyle = color.withAlpha(baseAlpha)
    ctx.fillPath(p)
    ctx.restore()
  # one solid-ish core copy so the shadow has a defined center
  var core = newPath()
  shapePath(core)
  ctx.fillStyle = color.withAlpha(color.a * alpha * 0.5f)
  ctx.fillPath(core)
  ctx.restore()

# --- Animation Frame Export ---
# The core animation model for every chart in this library is driven by
# `ChartConfig.animationProgress` (0.0 = fully hidden/start state, 1.0 =
# fully drawn/final state). These helpers let you render a whole sequence
# of frames sweeping that value from 0 to 1 with an easing curve, which
# you can then encode into a GIF/MP4/WebM with a tool such as ffmpeg, e.g.:
#
#   ffmpeg -framerate 30 -i frame_%04d.png -vf "fps=30" chart.gif
#
proc renderAnimationFrames*(
  width, height: int,
  frameCount: int,
  drawProc: proc(ctx: Context, bounds: Rect, progress: float32),
  easing: proc(t: float32): float32 = easeOut
): seq[Image] =
  result = newSeq[Image](max(frameCount, 1))
  let n = max(frameCount, 1)
  for i in 0 ..< n:
    let t = if n <= 1: 1.0f else: i.float32 / (n.float32 - 1.0f)
    let eased = clamp(easing(t), 0.0f, 1.15f) # allow slight overshoot for bounce easings
    let img = newImage(width, height)
    let ctx = newContext(img)
    drawProc(ctx, rect(0, 0, width.float32, height.float32), eased)
    result[i] = img

proc saveAnimationFrames*(frames: seq[Image], directory: string, baseName: string = "frame"): seq[string] =
  ## Writes each frame as `<directory>/<baseName>_0000.png`, `_0001.png`, ...
  ## Returns the list of file paths written, in order.
  createDir(directory)
  result = @[]
  for i, img in frames:
    let path = directory / (baseName & "_" & align($i, 4, '0') & ".png")
    img.writeFile(path)
    result.add(path)

proc measureTextSize*(font: Font, text: string): Vec2 =
  if text.len == 0:
    return vec2(0, 0)
  result = font.layoutBounds(text)

proc formatNiceNumber*(v: float32, decimals: int = 1): string =
  ## Formats an axis/value number cleanly: whole numbers print without a
  ## trailing ".0" (e.g. "5" instead of "5.0"), while fractional values
  ## keep `decimals` places (e.g. "5.3"). Used everywhere a raw
  ## `$(round(v * 10.0f) / 10.0f)` used to leave ugly ".0" suffixes on
  ## every tick label.
  let scale = pow(10.0f, decimals.float32)
  let rounded = round(v * scale) / scale
  if abs(rounded - round(rounded)) < (0.5f / scale):
    result = $(int(round(rounded)))
  else:
    result = formatFloat(rounded.float64, ffDecimal, decimals)

proc measureNiceScaleLabelWidth*(
  font: Font, niceMin, tickSpacing: float64, ticks: int, textSize: float32, decimals: int = 1
): float32 =
  ## Measures the widest formatted tick label a `calculateNiceScale` axis
  ## will actually produce, so callers can size a left/right margin to fit
  ## the real numbers instead of guessing a fixed pixel gutter (which
  ## clips long labels like "1234.5" and wastes space for short ones).
  let savedSize = font.size
  font.size = textSize
  result = 0.0f
  for i in 0 ..< ticks:
    let v = (niceMin + (i.float64 * tickSpacing)).float32
    let w = font.measureTextSize(formatNiceNumber(v, decimals)).x
    if w > result: result = w
  font.size = savedSize

proc fillBarWithDepth*(
  ctx: Context,
  r: Rect,
  col: Color,
  cornerRadius: float32 = 0.0f,
  alpha: float32 = 1.0f,
  shadowAlpha: float32 = 0.16f,
  highlightAlpha: float32 = 0.16f
) =
  ## Fills a bar-like rectangle with a soft drop shadow underneath and a
  ## subtle lighter "sheen" band across the top - turns a flat, single-tone
  ## rectangle into something with a touch of dimensionality, without
  ## needing a real gradient/blur API. Used across the bar-family charts
  ## (bar, horizontal bar, waterfall, pareto, pyramid, gantt, range bar)
  ## for a consistent, more polished look.
  if r.w <= 0.0f or r.h <= 0.0f or alpha <= 0.0f:
    return

  proc mkPath(rr: Rect): Path =
    result = newPath()
    if cornerRadius > 0.0f:
      result.roundedRect(rr, min(cornerRadius, min(rr.w, rr.h) * 0.5f), min(cornerRadius, min(rr.w, rr.h) * 0.5f))
    else:
      result.moveTo(rr.x, rr.y)
      result.lineTo(rr.x + rr.w, rr.y)
      result.lineTo(rr.x + rr.w, rr.y + rr.h)
      result.lineTo(rr.x, rr.y + rr.h)
      result.closePath()

  if shadowAlpha > 0.0f:
    let shadowRect = rect(r.x + 1.5f, r.y + 2.5f, r.w, r.h)
    ctx.fillStyle = color(0.0f, 0.0f, 0.0f, shadowAlpha * alpha)
    ctx.fillPath(mkPath(shadowRect))

  ctx.fillStyle = col.withAlpha(col.a * alpha)
  ctx.fillPath(mkPath(r))

  if highlightAlpha > 0.0f:
    let sheenH = min(r.h * 0.45f, 10.0f)
    if sheenH > 1.0f:
      ctx.save()
      ctx.clipPath(mkPath(r))
      ctx.fillStyle = color(1.0f, 1.0f, 1.0f, highlightAlpha * alpha)
      ctx.fillRect(r.x, r.y, r.w, sheenH)
      ctx.restore()

proc niceNum*(range: float64, round: bool): float64 =
  if range <= 0.0:
    return 1.0
  let exponent = floor(log10(range))
  let fraction = range / pow(10.0, exponent)
  var niceFraction: float64
  if round:
    if fraction < 1.5: niceFraction = 1.0
    elif fraction < 3.0: niceFraction = 2.0
    elif fraction < 7.0: niceFraction = 5.0
    else: niceFraction = 10.0
  else:
    if fraction <= 1.0: niceFraction = 1.0
    elif fraction <= 2.0: niceFraction = 2.0
    elif fraction <= 5.0: niceFraction = 5.0
    else: niceFraction = 10.0
  result = niceFraction * pow(10.0, exponent)

proc calculateNiceScale*(
  minVal, maxVal: float64,
  maxTicks: int,
  range, tickSpacing, niceMin, niceMax: var float64
) =
  range = niceNum(maxVal - minVal, false)
  tickSpacing = niceNum(range / (maxTicks - 1).float64, true)
  niceMin = floor(minVal / tickSpacing) * tickSpacing
  niceMax = ceil(maxVal / tickSpacing) * tickSpacing


proc calculateFooterHeaderHeight*(
  margin, textSize: float32,
  textSizes: openArray[Vec2],
  orientation: Orientation
): float32 =
  result = margin
  var hasNonEmpty = false
  var maxWidth: float32 = 0.0f
  for s in textSizes:
    if s.x > 0.0f or s.y > 0.0f:
      hasNonEmpty = true
      if s.x > maxWidth:
        maxWidth = s.x
  if hasNonEmpty:
    if orientation == Orientation.Vertical:
      if maxWidth > 0.0f:
        result += maxWidth + margin
    else:
      result += textSize + margin

proc calculateMinMax*(
  series: openArray[ChartSerie],
  cfgMin, cfgMax: Option[float32],
  outMin, outMax: var float32
) =
  var values: seq[float32] = @[]
  for s in series:
    for e in s.entries:
      if e.hasValue:
        values.add(e.value)

  if values.len == 0:
    outMin = cfgMin.get(0.0f)
    outMax = cfgMax.get(0.0f)
    return

  var calculatedMin = min(0.0f, values[0])
  var calculatedMax = max(0.0f, values[0])
  for v in values:
    if v < calculatedMin: calculatedMin = v
    if v > calculatedMax: calculatedMax = v

  outMin = if cfgMin.isSome: min(cfgMin.get, calculatedMin) else: calculatedMin
  outMax = if cfgMax.isSome: max(cfgMax.get, calculatedMax) else: calculatedMax

proc calculateYAxis*(
  showYAxisText, showYAxisLines: bool,
  series: openArray[ChartSerie],
  yAxisMaxTicks: int,
  font: Font,
  yAxisPosition: YAxisPosition,
  width: float32,
  fixedRange: bool,
  maxValue, minValue: var float32,
  yAxisXShift: var float32,
  yAxisIntervalLabels: var seq[float32]
): float32 =
  yAxisXShift = 0.0f
  yAxisIntervalLabels = @[]
  result = width

  if showYAxisText or showYAxisLines:
    var range, niceMin, niceMax, tickSpacing: float64
    var ticks: int

    if not fixedRange:
      if minValue == maxValue:
        if minValue >= 0.0f:
          maxValue += 100.0f
        else:
          maxValue = 0.0f
      calculateNiceScale(minValue.float64, maxValue.float64, yAxisMaxTicks, range, tickSpacing, niceMin, niceMax)
      ticks = int((niceMax - niceMin) / tickSpacing) + 1
    else:
      niceMin = minValue.float64
      niceMax = maxValue.float64
      range = niceMax - niceMin
      tickSpacing = range / (yAxisMaxTicks - 1).float64
      ticks = yAxisMaxTicks

    for i in 0 ..< ticks:
      yAxisIntervalLabels.add((niceMax - (i.float64 * tickSpacing)).float32)

    var longestLabel = ""
    for v in yAxisIntervalLabels:
      let s = formatNiceNumber(v, 2)
      if s.len > longestLabel.len:
        longestLabel = s

    let longestWidth = font.measureTextSize(longestLabel).x
    result = width - longestWidth - 10.0f
    if yAxisPosition == YAxisPosition.Left:
      yAxisXShift = longestWidth

    maxValue = niceMax.float32
    minValue = niceMin.float32

proc calculateYOrigin*(itemHeight, headerHeight, maxVal, minVal, range: float32): float32 =
  if maxVal <= 0.0f:
    return headerHeight
  if minVal > 0.0f:
    return headerHeight + itemHeight
  return headerHeight + ((maxVal / range) * itemHeight)

proc calculateItemSize*(items: int, width, height, reservedSpace, margin: float32): Vec2 =
  let n = max(items, 1).float32
  let w = (width - ((n + 1.0f) * margin)) / n
  let h = height - margin - reservedSpace
  result = vec2(max(w, 1.0f), max(h, 1.0f))

proc calculateBarSize*(itemWidth, itemHeight: float32, barPerItems: int, margin: float32): Vec2 =
  let count = max(barPerItems, 1).float32
  let w = (itemWidth - ((count - 1.0f) * margin * 0.5f)) / count
  result = vec2(max(w, 1.0f), itemHeight)

proc drawTextAligned*(
  ctx: Context,
  font: Font,
  text: string,
  pos: Vec2,
  color: Color,
  hAlign: HorizontalAlignment = LeftAlign,
  vAlign: VerticalAlignment = MiddleAlign,
  rotationAngle: float32 = 0.0f
) =
  if text.len == 0:
    return

  font.paint = color
  let metrics = font.layoutBounds(text)
  var offset = vec2(0, 0)

  case hAlign
  of LeftAlign: offset.x = 0.0f
  of CenterAlign: offset.x = -metrics.x * 0.5f
  of RightAlign: offset.x = -metrics.x

  case vAlign
  of TopAlign: offset.y = 0.0f
  of MiddleAlign: offset.y = -metrics.y * 0.5f
  of BottomAlign: offset.y = -metrics.y

  let arr = font.typeset(text, bounds = vec2(0, 0), wrap = false)
  let transform = translate(pos) * rotate(rotationAngle) * translate(offset)
  ctx.image.fillText(arr, transform)

proc drawCaptionLabels*(
  ctx: Context,
  font: Font,
  label: string,
  labelColor: Color,
  value: string,
  valueColor: Color,
  textSize: float32,
  point: Vec2,
  alignment: HorizontalAlignment,
  outBounds: var Rect
) =
  let hasLabel = label.len > 0
  let hasValue = value.len > 0
  outBounds = rect(point.x, point.y, 0, 0)
  if not hasLabel and not hasValue:
    return

  font.size = textSize
  let hasOffset = hasLabel and hasValue
  let captionMargin = textSize * 0.60f
  let space = if hasOffset: captionMargin else: 0.0f

  if hasLabel:
    let bounds = font.measureTextSize(label)
    let y = point.y - (bounds.y * 0.5f) - space
    drawTextAligned(ctx, font, label, vec2(point.x, y), labelColor, alignment, MiddleAlign)
    let rx = case alignment
             of LeftAlign: point.x
             of CenterAlign: point.x - bounds.x * 0.5f
             of RightAlign: point.x - bounds.x
    outBounds = rect(rx, y - bounds.y * 0.5f, bounds.x, bounds.y)

  if hasValue:
    let bounds = font.measureTextSize(value)
    let y = point.y - (bounds.y * 0.5f) + space
    drawTextAligned(ctx, font, value, vec2(point.x, y), valueColor, alignment, MiddleAlign)
    let rx = case alignment
             of LeftAlign: point.x
             of CenterAlign: point.x - bounds.x * 0.5f
             of RightAlign: point.x - bounds.x
    let vRect = rect(rx, y - bounds.y * 0.5f, bounds.x, bounds.y)
    if outBounds.w == 0.0f and outBounds.h == 0.0f:
      outBounds = vRect
    else:
      let minX = min(outBounds.x, vRect.x)
      let minY = min(outBounds.y, vRect.y)
      let maxX = max(outBounds.x + outBounds.w, vRect.x + vRect.w)
      let maxY = max(outBounds.y + outBounds.h, vRect.y + vRect.h)
      outBounds = rect(minX, minY, maxX - minX, maxY - minY)

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

proc drawYAxisLinesAndText*(
  ctx: Context,
  font: Font,
  showYAxisText, showYAxisLines: bool,
  yAxisPosition: YAxisPosition,
  textColor, linesColor: Color,
  margin, maxValue, valRange, width, yAxisXShift, headerHeight: float32,
  itemSize: Vec2,
  origin: float32,
  yAxisIntervalLabels: seq[float32],
  alpha: float32 = 1.0f
) =
  if yAxisIntervalLabels.len == 0 or valRange <= 0.0f:
    return

  for tick in yAxisIntervalLabels:
    let tickY = headerHeight + (((maxValue - tick) / valRange) * itemSize.y)
    if showYAxisLines:
      ctx.beginPath()
      ctx.moveTo(yAxisXShift, tickY)
      ctx.lineTo(yAxisXShift + width, tickY)
      ctx.strokeStyle = linesColor.withAlpha(linesColor.a * alpha)
      ctx.lineWidth = 1.0f
      ctx.stroke()

    if showYAxisText:
      let label = formatNiceNumber(tick, 2)
      let textX = if yAxisPosition == YAxisPosition.Left:
                    yAxisXShift - 5.0f
                  else:
                    yAxisXShift + width + 5.0f
      let align = if yAxisPosition == YAxisPosition.Left: RightAlign else: LeftAlign
      drawTextAligned(ctx, font, label, vec2(textX, tickY), textColor.withAlpha(textColor.a * alpha), align, MiddleAlign)

proc createSectorPath*(
  startFraction, endFraction, outerRadius, innerRadius: float32,
  margin: float32 = 0.0f
): Path =
  result = newPath()
  if startFraction == endFraction:
    return

  let fullCircle = 2.0f * PI
  let upright = PI * 0.5f

  if endFraction - startFraction >= 1.0f:
    result.circle(0, 0, outerRadius)
    if innerRadius > 0.0f:
      result.circle(0, 0, innerRadius)
    return

  let startAngle = (fullCircle * startFraction) - upright
  let endAngle = (fullCircle * endFraction) - upright

  let offsetOuterR = if outerRadius == 0.0f: 0.0f else: (margin / (fullCircle * outerRadius)) * fullCircle
  let offsetInnerR = if innerRadius == 0.0f: 0.0f else: (margin / (fullCircle * innerRadius)) * fullCircle

  let a = vec2(outerRadius * cos(startAngle + offsetOuterR), outerRadius * sin(startAngle + offsetOuterR))
  let c = vec2(innerRadius * cos(endAngle - offsetInnerR), innerRadius * sin(endAngle - offsetInnerR))

  result.moveTo(a.x, a.y)
  result.arc(0, 0, outerRadius, startAngle + offsetOuterR, endAngle - offsetOuterR, false)
  result.lineTo(c.x, c.y)
  if innerRadius > 0.0f:
    result.arc(0, 0, innerRadius, endAngle - offsetInnerR, startAngle + offsetInnerR, true)
  result.closePath()

proc calculateCubicInfo*(
  points: openArray[Vec2],
  i, next: int,
  itemWidth: float32
): tuple[control: Vec2, nextPoint: Vec2, nextControl: Vec2] =
  let p = points[i]
  let np = points[next]
  let controlOffset = vec2(itemWidth * 0.8f, 0.0f)
  result.control = p + controlOffset
  result.nextPoint = np
  result.nextControl = np - controlOffset

proc renderChartImage*(
  width, height: int,
  drawProc: proc(ctx: Context, bounds: Rect)
): Image =
  result = newImage(width, height)
  let ctx = newContext(result)
  drawProc(ctx, rect(0, 0, width.float32, height.float32))

