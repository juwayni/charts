import std/[math]
import pixie
import ../types, ../helpers

proc drawParallelCoordsChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  dimensions: openArray[ParallelDimension],
  records: openArray[ParallelRecord],
  config: ChartConfig = defaultChartConfig()
) =
  let numDims = dimensions.len
  if numDims < 2:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  let topMargin = config.margin + config.labelTextSize + 10.0f
  let bottomMargin = config.margin + config.labelTextSize + 10.0f
  let chartW = bounds.w - (config.margin * 2.0f)
  let chartH = bounds.h - topMargin - bottomMargin
  let dimGap = chartW / (numDims.float32 - 1.0f)

  let progress = config.animationProgress

  # 1. Parallel Polylines - each line "draws" across the dimensions left
  # to right (rather than uniformly rising from the baseline), which
  # reads much more like the data is being traced out live.
  for rIdx in 0 ..< records.len:
    let r = records[rIdx]
    let lineT = staggerProgress(rIdx, records.len, progress, 0.85f)
    let path = newPath()
    var pts: seq[Vec2] = @[]
    for d in 0 ..< numDims:
      let dim = dimensions[d]
      let val = if d < r.values.len: r.values[d] else: dim.minVal
      let span = max(0.001f, dim.maxVal - dim.minVal)
      let norm = clamp((val - dim.minVal) / span, 0.0f, 1.0f)

      let x = config.margin + (d.float32 * dimGap)
      let y = topMargin + chartH - (norm * chartH)
      pts.add(vec2(x, y))

    # Reveal the polyline progressively along its own length using lineT
    let revealSegs = clamp(lineT * (numDims.float32 - 1.0f), 0.0f, (numDims - 1).float32)
    let fullSegs = int(floor(revealSegs))
    let segFrac = revealSegs - fullSegs.float32

    if pts.len > 0:
      path.moveTo(pts[0].x, pts[0].y)
      for d in 1 .. fullSegs:
        path.lineTo(pts[d].x, pts[d].y)
      if fullSegs + 1 < pts.len and segFrac > 0.0f:
        let a = pts[fullSegs]
        let b = pts[fullSegs + 1]
        path.lineTo(lerp(a.x, b.x, segFrac), lerp(a.y, b.y, segFrac))

    ctx.strokeStyle = r.color.withAlpha(0.55f * min(1.0f, lineT * 3.0f))
    ctx.lineWidth = 2.0f
    ctx.strokePath(path)

  # 2. Vertical Dimension Axes & Labels - fade in as a quick backdrop
  let axisAlpha = clamp(progress / 0.25f, 0.0f, 1.0f)
  font.size = config.labelTextSize * 0.85f
  for d in 0 ..< numDims:
    let dim = dimensions[d]
    let x = config.margin + (d.float32 * dimGap)

    ctx.beginPath()
    ctx.moveTo(x, topMargin)
    ctx.lineTo(x, topMargin + chartH)
    ctx.strokeStyle = config.yAxisLinesColor.withAlpha(config.yAxisLinesColor.a * axisAlpha)
    ctx.lineWidth = 1.5f
    ctx.stroke()

    # Dimension Title
    drawTextAligned(ctx, font, dim.name, vec2(x, topMargin - 8.0f), config.labelColor.withAlpha(axisAlpha), CenterAlign, BottomAlign)
    # Min & Max Tick Labels
    drawTextAligned(ctx, font, formatNiceNumber(dim.maxVal), vec2(x, topMargin + 6.0f), config.yAxisTextColor.withAlpha(axisAlpha), CenterAlign, TopAlign)
    drawTextAligned(ctx, font, formatNiceNumber(dim.minVal), vec2(x, topMargin + chartH - 6.0f), config.yAxisTextColor.withAlpha(axisAlpha), CenterAlign, BottomAlign)

  ctx.restore()
