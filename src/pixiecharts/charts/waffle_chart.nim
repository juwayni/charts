import std/[math]
import pixie
import ../types, ../helpers

proc drawWaffleChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  categories: openArray[WaffleCategory],
  config: ChartConfig = defaultChartConfig(),
  gridSize: int = 10
) =
  let totalCells = gridSize * gridSize
  var totalCount = 0
  for c in categories: totalCount += c.count
  if totalCount == 0: return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  let footerH = 40.0f
  let matrixW = min(bounds.w, bounds.h - footerH) - (config.margin * 2.0f)
  let cellGap = 3.5f
  let cellSize = (matrixW - ((gridSize.float32 - 1.0f) * cellGap)) / gridSize.float32
  let startX = (bounds.w - matrixW) * 0.5f
  let startY = config.margin

  # Allocate cell colors
  var cellColors = newSeq[Color](totalCells)
  var cellIdx = 0
  for cat in categories:
    let allocCount = int(round((cat.count.float32 / totalCount.float32) * totalCells.float32))
    for _ in 0 ..< allocCount:
      if cellIdx < totalCells:
        cellColors[cellIdx] = cat.color
        inc cellIdx

  while cellIdx < totalCells:
    cellColors[cellIdx] = categories[^1].color
    inc cellIdx

  # Draw Grid Cells (bottom-up, left-to-right) - cells pop in with a
  # staggered wave sweeping across the grid, plus a gentle overshoot.
  let progress = config.animationProgress
  for idx in 0 ..< totalCells:
    let cellT = easeOutBack(staggerProgress(idx, totalCells, progress, 0.35f))
    if cellT <= 0.0f:
      continue
    let col = idx mod gridSize
    let row = gridSize - 1 - (idx div gridSize)
    let x = startX + (col.float32 * (cellSize + cellGap))
    let y = startY + (row.float32 * (cellSize + cellGap))

    let scale = clamp(cellT, 0.0f, 1.15f)
    let s = cellSize * scale
    let inset = (cellSize - s) * 0.5f

    let p = newPath()
    p.roundedRect(rect(x + inset, y + inset, s, s), 2.5f, 2.5f)
    ctx.fillStyle = cellColors[idx].withAlpha(cellColors[idx].a * min(1.0f, cellT))
    ctx.fillPath(p)

  # Legend at Bottom - fades in once the grid is mostly filled
  let legendAlpha = clamp((progress - 0.6f) / 0.4f, 0.0f, 1.0f)
  font.size = 12.0f
  var legX = startX
  let legY = bounds.h - (footerH * 0.5f)
  for cat in categories:
    ctx.fillStyle = cat.color.withAlpha(cat.color.a * legendAlpha)
    let swatch = newPath()
    swatch.roundedRect(rect(legX, legY - 6.0f, 10.0f, 10.0f), 2.5f, 2.5f)
    ctx.fillPath(swatch)
    let text = cat.name & " (" & $(cat.count) & ")"
    drawTextAligned(ctx, font, text, vec2(legX + 14.0f, legY), config.labelColor.withAlpha(legendAlpha), LeftAlign, MiddleAlign)
    legX += font.measureTextSize(text).x + 24.0f

  ctx.restore()
