import std/[math]
import pixie
import ../types, ../helpers

proc drawMarimekkoChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  columns: openArray[MekkoColumn],
  config: ChartConfig = defaultChartConfig()
) =
  let count = columns.len
  if count == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  var colSums = newSeq[float32](count)
  var grandTotal = 0.0f

  for i in 0 ..< count:
    var sum = 0.0f
    for seg in columns[i].segments:
      sum += seg.value
    colSums[i] = sum
    grandTotal += sum

  if grandTotal <= 0.0f: grandTotal = 1.0f

  font.size = config.labelTextSize
  let footerH = config.labelTextSize + (config.margin * 1.5f)
  let chartW = bounds.w - (config.margin * 2.0f)
  let chartH = bounds.h - footerH - config.margin

  var currentX = config.margin

  for i in 0 ..< count:
    let col = columns[i]
    let colW = (colSums[i] / grandTotal) * chartW
    let sum = if colSums[i] > 0.0f: colSums[i] else: 1.0f

    # Columns sweep in left to right; within each column, segments stack
    # upward from the baseline shortly after the column itself starts.
    let colT = staggerProgress(i, count, config.animationProgress, 0.7f)
    let stackT = easeOutQuad(colT)

    var currentY = config.margin + chartH
    for seg in col.segments:
      let segH = (seg.value / sum) * chartH * stackT
      let y = currentY - segH
      let segAlpha = min(1.0f, colT * 2.0f)

      ctx.fillStyle = seg.color.withAlpha(segAlpha)
      ctx.fillRect(currentX + 1.0f, y, colW - 2.0f, segH)
      ctx.strokeStyle = color(1, 1, 1, segAlpha)
      ctx.lineWidth = 1.0f
      ctx.strokeRect(rect(currentX + 1.0f, y, colW - 2.0f, segH))

      if colW > 35.0f and segH > 15.0f:
        font.size = min(11.0f, segH * 0.35f)
        drawTextAligned(ctx, font, seg.name, vec2(currentX + (colW * 0.5f), y + (segH * 0.5f)), color(1, 1, 1, segAlpha), CenterAlign, MiddleAlign)

      currentY = y

    # Column Category Label
    font.size = config.labelTextSize
    drawTextAligned(ctx, font, col.name, vec2(currentX + (colW * 0.5f), bounds.h - (footerH * 0.5f)), config.labelColor.withAlpha(min(1.0f, colT * 2.0f)), CenterAlign, MiddleAlign)
    currentX += colW

  ctx.restore()
