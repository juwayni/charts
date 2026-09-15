import std/[math]
import pixie
import ../types, ../helpers

proc drawCalendarHeatmap*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  days: openArray[CalendarDay],
  config: ChartConfig = defaultChartConfig(),
  colorScale: array[5, Color] = [
    color(0.92f, 0.93f, 0.94f, 1.0f), # 0: None
    color(0.61f, 0.87f, 0.67f, 1.0f), # 1: Low
    color(0.25f, 0.77f, 0.49f, 1.0f), # 2: Med-Low
    color(0.14f, 0.63f, 0.36f, 1.0f), # 3: Med-High
    color(0.08f, 0.43f, 0.24f, 1.0f)  # 4: High
  ]
) =
  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  let cols = 53
  let rows = 7
  let leftMargin = config.margin + 25.0f
  let topMargin = config.margin + 15.0f
  let progress = config.animationProgress

  let availableW = bounds.w - leftMargin - config.margin
  let cellGap = 2.5f
  let cellSize = (availableW - ((cols.float32 - 1.0f) * cellGap)) / cols.float32

  # Day of Week Indicators (Mon, Wed, Fri)
  font.size = 10.0f
  let dayLabels = ["M", "", "W", "", "F", "", ""]
  for r in 0 ..< 7:
    if dayLabels[r].len > 0:
      let y = topMargin + (r.float32 * (cellSize + cellGap)) + (cellSize * 0.5f)
      drawTextAligned(ctx, font, dayLabels[r], vec2(leftMargin - 8.0f, y), config.labelColor, RightAlign, MiddleAlign)

  # Default Blank Cells - these sit on the "grid", they fade in gently as a
  # backdrop before the actual contribution tiles pop on top of them.
  let gridAlpha = clamp(progress / 0.25f, 0.0f, 1.0f)
  for c in 0 ..< cols:
    for r in 0 ..< rows:
      let x = leftMargin + (c.float32 * (cellSize + cellGap))
      let y = topMargin + (r.float32 * (cellSize + cellGap))
      let p = newPath()
      p.roundedRect(rect(x, y, cellSize, cellSize), 2.0f, 2.0f)
      ctx.fillStyle = colorScale[0].withAlpha(colorScale[0].a * gridAlpha)
      ctx.fillPath(p)

  # Active Contribution Tiles - sweep on diagonally (week-by-week, like a
  # calendar filling in over time) with a gentle scale-pop per cell.
  for d in days:
    if d.weekIndex in 0 ..< cols and d.dayIndex in 0 ..< rows:
      let level = clamp(d.value, 0, 4)
      # Order the reveal by week first (so it reads left-to-right through
      # the year), with day-of-week providing a touch of stagger within a week.
      let orderIndex = (d.weekIndex * rows) + d.dayIndex
      let totalCells = cols * rows
      let itemT = easeOutBack(staggerProgress(orderIndex, totalCells, progress, 0.12f))
      if itemT <= 0.0f:
        continue

      let x = leftMargin + (d.weekIndex.float32 * (cellSize + cellGap))
      let y = topMargin + (d.dayIndex.float32 * (cellSize + cellGap))
      let scaledSize = cellSize * clamp(itemT, 0.0f, 1.15f)
      let inset = (cellSize - scaledSize) * 0.5f

      let p = newPath()
      p.roundedRect(rect(x + inset, y + inset, scaledSize, scaledSize), 2.0f, 2.0f)
      ctx.fillStyle = colorScale[level].withAlpha(colorScale[level].a * min(1.0f, itemT))
      ctx.fillPath(p)

  ctx.restore()
