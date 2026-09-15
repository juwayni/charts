import std/[math]
import pixie
import ../types, ../helpers

proc drawRidgelineChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  series: openArray[RidgelineSeries],
  config: ChartConfig = defaultChartConfig(),
  overlapFactor: float32 = 2.2f
) =
  let count = series.len
  if count == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  font.size = config.labelTextSize
  var maxNameW = 0.0f
  for s in series:
    let w = font.measureTextSize(s.name).x
    if w > maxNameW: maxNameW = w

  let leftMargin = config.margin + maxNameW + 15.0f
  let chartW = bounds.w - leftMargin - config.margin
  let chartH = bounds.h - (config.margin * 2.0f)
  let rowSpacing = chartH / (count.float32 + 0.5f)
  let progress = config.animationProgress

  # Ridges reveal from back to front (bottom to top) since later rows
  # visually overlap earlier ones - drawing/animating in that natural
  # stacking order reads best.
  for idx in 0 ..< count:
    let s = series[idx]
    let nPoints = s.values.len
    if nPoints < 2: continue

    let baselineY = config.margin + ((idx.float32 + 1.0f) * rowSpacing)
    let stepX = chartW / (nPoints.float32 - 1.0f)
    let rowT = easeOutQuad(staggerProgress(count - 1 - idx, count, progress, 0.6f))
    let rowAlpha = min(1.0f, rowT * 2.0f)

    # Series Title
    drawTextAligned(ctx, font, s.name, vec2(leftMargin - 10.0f, baselineY), config.labelColor.withAlpha(rowAlpha), RightAlign, MiddleAlign)

    var maxV = 0.0f
    for v in s.values:
      if v > maxV: maxV = v
    if maxV <= 0.0f: maxV = 1.0f

    let path = newPath()
    let strokePath = newPath()

    for i in 0 ..< (nPoints - 1):
      let x1 = leftMargin + (i.float32 * stepX)
      let x2 = leftMargin + ((i.float32 + 1.0f) * stepX)
      let h1 = (s.values[i] / maxV) * rowSpacing * overlapFactor * rowT
      let h2 = (s.values[i + 1] / maxV) * rowSpacing * overlapFactor * rowT
      let y1 = baselineY - h1
      let y2 = baselineY - h2
      let ctrlOffset = (x2 - x1) * 0.5f

      if i == 0:
        path.moveTo(x1, baselineY)
        path.lineTo(x1, y1)
        strokePath.moveTo(x1, y1)

      path.bezierCurveTo(x1 + ctrlOffset, y1, x2 - ctrlOffset, y2, x2, y2)
      strokePath.bezierCurveTo(x1 + ctrlOffset, y1, x2 - ctrlOffset, y2, x2, y2)

    let lastX = leftMargin + ((nPoints.float32 - 1.0f) * stepX)
    path.lineTo(lastX, baselineY)
    path.closePath()

    ctx.fillStyle = s.color.withAlpha(0.65f * rowAlpha)
    ctx.fillPath(path)

    ctx.strokeStyle = s.color.withAlpha(rowAlpha)
    ctx.lineWidth = 1.5f
    ctx.strokePath(strokePath)

  ctx.restore()
