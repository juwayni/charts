import std/[math]
import pixie
import ../types, ../helpers

proc drawBulletChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  entries: openArray[BulletEntry],
  config: ChartConfig = defaultChartConfig()
) =
  if entries.len == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  font.size = config.labelTextSize
  var maxTitleW = 0.0f
  for e in entries:
    let w = font.measureTextSize(e.label).x
    if w > maxTitleW: maxTitleW = w

  let leftMargin = config.margin + maxTitleW + 15.0f
  let chartW = bounds.w - leftMargin - config.margin
  let count = entries.len.float32
  let rowH = (bounds.h - (config.margin * 2.0f)) / count
  let progress = config.animationProgress

  for i in 0 ..< entries.len:
    let e = entries[i]
    let yRow = config.margin + (i.float32 * rowH)
    let midY = yRow + (rowH * 0.5f)
    let barH = rowH * 0.45f
    let barTop = midY - (barH * 0.5f)

    # Rows sweep in top-to-bottom, one after another.
    let rowT = staggerProgress(i, entries.len, progress, 0.7f)
    let bandT = easeOutQuad(clamp(rowT / 0.4f, 0.0f, 1.0f))
    let barT = easeOutQuad(clamp((rowT - 0.15f) / 0.55f, 0.0f, 1.0f))
    let markerT = easeOutBack(clamp((rowT - 0.5f) / 0.5f, 0.0f, 1.0f))
    let rowAlpha = min(1.0f, rowT * 2.0f)

    # Title & Subtitle on the left
    font.size = config.labelTextSize
    drawTextAligned(ctx, font, e.label, vec2(leftMargin - 10.0f, midY - 6.0f), config.labelColor.withAlpha(rowAlpha), RightAlign, MiddleAlign)
    if e.subtitle.len > 0:
      font.size = config.labelTextSize * 0.75f
      drawTextAligned(ctx, font, e.subtitle, vec2(leftMargin - 10.0f, midY + 8.0f), color(0.6f, 0.6f, 0.6f, rowAlpha), RightAlign, MiddleAlign)

    # Max range scale
    var maxRange = e.actual
    if e.target > maxRange: maxRange = e.target
    for r in e.ranges:
      if r.value > maxRange: maxRange = r.value
    if maxRange <= 0.0f: maxRange = 1.0f

    # 1. Background Qualitative Bands - fade/grow in first, establishing
    # the "ruler" before the actual measure bar draws over it.
    for r in e.ranges:
      let w = (r.value / maxRange) * chartW * bandT
      ctx.fillStyle = r.color.withAlpha(r.color.a * min(1.0f, bandT * 2.0f))
      ctx.fillRect(leftMargin, barTop - 4.0f, w, barH + 8.0f)

    # 2. Central Actual Measure Bar
    let actualW = (e.actual / maxRange) * chartW * barT
    if barT > 0.0f:
      ctx.fillStyle = color(0.0f, 0.0f, 0.0f, 0.16f * min(1.0f, barT * 2.0f))
      ctx.fillRect(leftMargin + 1.0f, barTop + 2.0f, actualW, barH)
      ctx.fillStyle = e.actualColor.withAlpha(min(1.0f, barT * 2.0f))
      ctx.fillRect(leftMargin, barTop, actualW, barH)
      let sheenH = min(barH * 0.4f, 5.0f)
      if actualW > 1.0f and sheenH > 1.0f:
        ctx.fillStyle = color(1.0f, 1.0f, 1.0f, 0.18f * min(1.0f, barT * 2.0f))
        ctx.fillRect(leftMargin, barTop, actualW, sheenH)

    # 3. Comparative Target Marker Line - pops in last, once the actual
    # measure has (mostly) finished drawing.
    if markerT > 0.0f:
      let targetX = leftMargin + ((e.target / maxRange) * chartW)
      let targetH = (barH + 16.0f) * clamp(markerT, 0.0f, 1.15f)
      ctx.beginPath()
      ctx.moveTo(targetX, midY - (targetH * 0.5f))
      ctx.lineTo(targetX, midY + (targetH * 0.5f))
      ctx.strokeStyle = e.targetColor.withAlpha(min(1.0f, markerT))
      ctx.lineWidth = 3.5f
      ctx.stroke()

  ctx.restore()
