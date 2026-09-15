import std/[math]
import pixie
import ../types, ../helpers

proc interpolateColor(c1, c2: Color, t: float32): Color =
  let f = clamp(t, 0.0f, 1.0f)
  color(c1.r + (c2.r - c1.r) * f, c1.g + (c2.g - c1.g) * f, c1.b + (c2.b - c1.b) * f, 1.0f)

proc getHeatmapColor(val, minV, maxV: float32, low, mid, high: Color): Color =
  let norm = if maxV == minV: 0.5f else: clamp((val - minV) / (maxV - minV), 0.0f, 1.0f)
  if norm < 0.5f:
    interpolateColor(low, mid, norm * 2.0f)
  else:
    interpolateColor(mid, high, (norm - 0.5f) * 2.0f)

proc drawHeatmapChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  data: HeatmapData,
  config: ChartConfig = defaultChartConfig()
) =
  let rows = data.rowLabels.len
  let cols = data.colLabels.len
  if rows == 0 or cols == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  font.size = config.labelTextSize
  var maxRowLabelW = 0.0f
  for r in data.rowLabels:
    let w = font.measureTextSize(r).x
    if w > maxRowLabelW: maxRowLabelW = w

  let leftMargin = config.margin + maxRowLabelW + 10.0f
  let topMargin = config.margin + config.labelTextSize + 15.0f
  let rightMargin = config.margin + 40.0f
  let gridW = bounds.w - leftMargin - rightMargin
  let gridH = bounds.h - topMargin - config.margin
  let progress = config.animationProgress

  let cellW = gridW / cols.float32
  let cellH = gridH / rows.float32
  let labelAlpha = clamp(progress / 0.3f, 0.0f, 1.0f)

  # Column Headers (Top)
  for c in 0 ..< cols:
    let x = leftMargin + (c.float32 * cellW) + (cellW * 0.5f)
    drawTextAligned(ctx, font, data.colLabels[c], vec2(x, topMargin - 8.0f), config.labelColor.withAlpha(labelAlpha), CenterAlign, BottomAlign)

  # Row Headers (Left) & Grid Cells - cells sweep in row by row, each
  # popping to full size with a gentle overshoot for a lively feel.
  let totalCells = max(1, rows * cols)
  for r in 0 ..< rows:
    let y = topMargin + (r.float32 * cellH) + (cellH * 0.5f)
    drawTextAligned(ctx, font, data.rowLabels[r], vec2(leftMargin - 8.0f, y), config.labelColor.withAlpha(labelAlpha), RightAlign, MiddleAlign)

    for c in 0 ..< cols:
      let cellIndex = (r * cols) + c
      let itemT = easeOutBack(staggerProgress(cellIndex, totalCells, progress, 0.5f))
      if itemT <= 0.0f:
        continue
      let v = if r < data.values.len and c < data.values[r].len: data.values[r][c] else: data.minVal
      let cellColor = getHeatmapColor(v, data.minVal, data.maxVal, data.colorLow, data.colorMid, data.colorHigh)
      let cx = leftMargin + (c.float32 * cellW)
      let cy = topMargin + (r.float32 * cellH)

      let scale = clamp(itemT, 0.0f, 1.15f)
      let fullW = cellW - 2.0f
      let fullH = cellH - 2.0f
      let w = fullW * scale
      let h = fullH * scale
      let ox = cx + 1.0f + (fullW - w) * 0.5f
      let oy = cy + 1.0f + (fullH - h) * 0.5f

      ctx.fillStyle = cellColor.withAlpha(min(1.0f, itemT))
      ctx.fillRect(ox, oy, w, h)

      # Adaptive Text Contrast: luminance = 0.299R + 0.587G + 0.114B
      let lum = (0.299f * cellColor.r) + (0.587f * cellColor.g) + (0.114f * cellColor.b)
      let textColor = if lum > 0.55f: color(0, 0, 0, min(1.0f, itemT)) else: color(1, 1, 1, min(1.0f, itemT))

      if scale > 0.6f:
        font.size = min(config.labelTextSize, min(cellW, cellH) * 0.40f)
        drawTextAligned(ctx, font, formatNiceNumber(v), vec2(cx + (cellW * 0.5f), cy + (cellH * 0.5f)), textColor, CenterAlign, MiddleAlign)

  ctx.restore()
