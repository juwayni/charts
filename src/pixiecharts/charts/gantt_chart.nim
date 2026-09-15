import std/[math]
import pixie
import ../types, ../helpers

proc drawGanttChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  tasks: openArray[GanttTask],
  config: ChartConfig = defaultChartConfig()
) =
  let count = tasks.len
  if count == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  var minDay = tasks[0].startDay
  var maxDay = tasks[0].endDay
  for t in tasks:
    if t.startDay < minDay: minDay = t.startDay
    if t.endDay > maxDay: maxDay = t.endDay

  let totalDays = max(1.0f, maxDay - minDay)

  font.size = config.labelTextSize
  var maxLabelW = 0.0f
  for t in tasks:
    let w = font.measureTextSize(t.label).x
    if w > maxLabelW: maxLabelW = w

  let leftMargin = config.margin + maxLabelW + 15.0f
  let topMargin = config.margin + config.labelTextSize + 15.0f
  let chartW = bounds.w - leftMargin - config.margin
  let chartH = bounds.h - topMargin - config.margin
  let rowH = chartH / count.float32
  let barH = rowH * 0.50f

  # Timeline Day Header & Grid - fades in as the backdrop
  let progress = config.animationProgress
  let gridAlpha = clamp(progress / 0.25f, 0.0f, 1.0f)
  let gridTicks = 6
  for i in 0 ..< gridTicks:
    let frac = i.float32 / (gridTicks.float32 - 1.0f)
    let dayVal = minDay + (frac * totalDays)
    let x = leftMargin + (frac * chartW)

    ctx.beginPath()
    ctx.moveTo(x, topMargin)
    ctx.lineTo(x, topMargin + chartH)
    ctx.strokeStyle = config.yAxisLinesColor.withAlpha(config.yAxisLinesColor.a * gridAlpha)
    ctx.lineWidth = 1.0f
    ctx.stroke()
    drawTextAligned(ctx, font, "Day " & $(int(dayVal)), vec2(x, topMargin - 8.0f), config.yAxisTextColor.withAlpha(gridAlpha), CenterAlign, BottomAlign)

  for i in 0 ..< count:
    let t = tasks[i]
    let y = topMargin + (i.float32 * rowH) + (rowH * 0.5f) - (barH * 0.5f)
    # Rows sweep in top-to-bottom, one after another.
    let itemT = staggerProgress(i, count, progress, 0.6f)
    let growT = easeOutQuad(itemT)
    let alpha = min(1.0f, itemT * 2.0f)

    # Task label
    drawTextAligned(ctx, font, t.label, vec2(leftMargin - 10.0f, y + (barH * 0.5f)), config.labelColor.withAlpha(alpha), RightAlign, MiddleAlign)

    let x0 = leftMargin + (((t.startDay - minDay) / totalDays) * chartW)
    let x1 = leftMargin + (((t.endDay - minDay) / totalDays) * chartW)
    let barW = max(2.0f, (x1 - x0) * growT)

    if t.isMilestone:
      # Diamond glyph - pops in with a gentle overshoot once its row starts
      let popT = easeOutBack(clamp(itemT / 0.5f, 0.0f, 1.0f))
      if popT <= 0.0f: continue
      let midX = x0
      let midY = y + (barH * 0.5f)
      let d = barH * 0.65f * clamp(popT, 0.0f, 1.15f)
      let path = newPath()
      path.moveTo(midX, midY - d)
      path.lineTo(midX + d, midY)
      path.lineTo(midX, midY + d)
      path.lineTo(midX - d, midY)
      path.closePath()
      ctx.fillStyle = t.color.withAlpha(min(1.0f, popT))
      ctx.fillPath(path)
    else:
      # Background track
      ctx.fillStyle = color(0.0f, 0.0f, 0.0f, 0.10f * alpha)
      ctx.fillRect(x0 + 1.0f, y + 2.0f, barW, barH)
      ctx.fillStyle = t.color.withAlpha(0.30f * alpha)
      ctx.fillRect(x0, y, barW, barH)

      # Progress fill
      let progW = barW * clamp(t.progress, 0.0f, 1.0f)
      ctx.fillStyle = t.color.withAlpha(alpha)
      ctx.fillRect(x0, y, progW, barH)

      let sheenH = min(barH * 0.4f, 6.0f)
      if progW > 1.0f and sheenH > 1.5f:
        ctx.fillStyle = color(1.0f, 1.0f, 1.0f, 0.16f * alpha)
        ctx.fillRect(x0, y, progW, sheenH)

      ctx.strokeStyle = t.color.withAlpha(alpha)
      ctx.lineWidth = 1.0f
      ctx.strokeRect(rect(x0, y, barW, barH))

  ctx.restore()
