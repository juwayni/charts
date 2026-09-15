import std/[math]
import pixie
import ../types, ../helpers

proc drawStreamgraphChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  series: openArray[StreamSeries],
  config: ChartConfig = defaultChartConfig()
) =
  let numSeries = series.len
  if numSeries == 0:
    return
  let nPoints = series[0].values.len
  if nPoints < 2:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  # Compute totals per column
  var colSums = newSeq[float32](nPoints)
  var maxColSum = 0.0f
  for i in 0 ..< nPoints:
    var sum = 0.0f
    for s in series:
      if i < s.values.len: sum += max(0.0f, s.values[i])
    colSums[i] = sum
    if sum > maxColSum: maxColSum = sum

  if maxColSum <= 0.0f: maxColSum = 1.0f

  let chartW = bounds.w - (config.margin * 2.0f)
  let chartH = bounds.h - (config.margin * 2.0f)
  let centerY = config.margin + (chartH * 0.5f)
  let stepX = chartW / (nPoints.float32 - 1.0f)
  let progress = config.animationProgress

  # Symmetric baseline (Lee Byron's Streamgraph baseline)
  var currentY0 = newSeq[float32](nPoints)
  for i in 0 ..< nPoints:
    currentY0[i] = centerY - (((colSums[i] * 0.5f) / maxColSum) * chartH * 0.85f * progress)

  # Draw layers from bottom to top - each layer settles in shortly after
  # the one below it, like the stream is filling up layer by layer while
  # still keeping every layer's edges continuous (no gaps/overlaps),
  # since each layer's baseline is always inherited exactly from the one
  # beneath it regardless of its own reveal amount.
  let numSeriesTotal = series.len
  for sIdx in 0 ..< numSeriesTotal:
    let s = series[sIdx]
    let layerT = easeOutQuad(staggerProgress(sIdx, numSeriesTotal, progress, 0.7f))
    var nextY0 = newSeq[float32](nPoints)
    for i in 0 ..< nPoints:
      let v = if i < s.values.len: max(0.0f, s.values[i]) else: 0.0f
      let layerH = ((v / maxColSum) * chartH * 0.85f) * layerT
      nextY0[i] = currentY0[i] + layerH

    let path = newPath()
    # Top profile forwards with cubic Bézier smoothing
    for i in 0 ..< (nPoints - 1):
      let x1 = config.margin + (i.float32 * stepX)
      let x2 = config.margin + ((i.float32 + 1.0f) * stepX)
      let y1 = nextY0[i]
      let y2 = nextY0[i + 1]
      let ctrlOffset = (x2 - x1) * 0.5f

      if i == 0: path.moveTo(x1, y1)
      path.bezierCurveTo(x1 + ctrlOffset, y1, x2 - ctrlOffset, y2, x2, y2)

    # Bottom profile backwards
    for i in countdown(nPoints - 1, 1):
      let x1 = config.margin + (i.float32 * stepX)
      let x2 = config.margin + ((i.float32 - 1.0f) * stepX)
      let y1 = currentY0[i]
      let y2 = currentY0[i - 1]
      let ctrlOffset = (x1 - x2) * 0.5f
      path.bezierCurveTo(x1 - ctrlOffset, y1, x2 + ctrlOffset, y2, x2, y2)

    path.closePath()
    ctx.fillStyle = s.color.withAlpha(0.85f * min(1.0f, layerT * 2.0f))
    ctx.fillPath(path)

    currentY0 = nextY0

  ctx.restore()
