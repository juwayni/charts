import std/[math]
import pixie
import ../types, ../helpers

proc drawKpiCardChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  card: KpiCardData,
  config: ChartConfig = defaultChartConfig()
) =
  ctx.save()
  ctx.translate(bounds.x, bounds.y)

  let progress = config.animationProgress
  # The whole card fades in first, like it's settling onto the dashboard.
  let cardT = easeOutCubic(clamp(progress / 0.35f, 0.0f, 1.0f))
  let cardAlpha = min(1.0f, cardT)

  # 1. Card Container & Border (with a soft drop shadow for depth)
  let cardRect = rect(2.0f, 2.0f, bounds.w - 4.0f, bounds.h - 4.0f)
  let cardPath = newPath()
  cardPath.roundedRect(cardRect, 10.0f, 10.0f)

  if cardAlpha > 0.05f:
    drawSoftShadow(
      ctx,
      proc(p: Path) = p.roundedRect(cardRect, 10.0f, 10.0f),
      offset = vec2(0.0f, 4.0f),
      color = color(0.0f, 0.0f, 0.0f, 0.14f),
      alpha = cardAlpha
    )

  ctx.fillStyle = card.cardBgColor.withAlpha(card.cardBgColor.a * cardAlpha)
  ctx.fillPath(cardPath)
  ctx.strokeStyle = color(0.88f, 0.88f, 0.88f, cardAlpha)
  ctx.lineWidth = 1.0f
  ctx.strokePath(cardPath)

  let pad = 16.0f

  # 2. Card Title & Delta Badge - title fades first, badge pops in
  # slightly after it.
  let titleAlpha = min(1.0f, clamp((progress - 0.2f) / 0.3f, 0.0f, 1.0f))
  font.size = 14.0f
  drawTextAligned(ctx, font, card.title, vec2(pad, pad + 8.0f), color(0.45f, 0.45f, 0.45f, titleAlpha), LeftAlign, MiddleAlign)

  let badgeT = easeOutBack(clamp((progress - 0.35f) / 0.35f, 0.0f, 1.0f))
  if badgeT > 0.0f:
    let badgeColor = if card.isPositiveChange: color(0.18f, 0.80f, 0.44f, 1.0f) else: color(0.91f, 0.30f, 0.24f, 1.0f)
    let badgeBg = badgeColor.withAlpha(0.15f * min(1.0f, badgeT))
    let badgeW = 60.0f
    let badgeH = 22.0f
    let badgeX = bounds.w - pad - badgeW
    let badgeY = pad

    let bPath = newPath()
    bPath.roundedRect(rect(badgeX, badgeY, badgeW, badgeH), 4.0f, 4.0f)
    ctx.fillStyle = badgeBg
    ctx.fillPath(bPath)

    font.size = 12.0f
    drawTextAligned(ctx, font, card.changeLabel, vec2(badgeX + (badgeW * 0.5f), badgeY + (badgeH * 0.5f)), badgeColor.withAlpha(min(1.0f, badgeT)), CenterAlign, MiddleAlign)

  # 3. Large Metric Value - slides up slightly as it fades in
  let valueT = clamp((progress - 0.25f) / 0.35f, 0.0f, 1.0f)
  let valueAlpha = min(1.0f, valueT)
  let valueYOffset = (1.0f - easeOutQuad(valueT)) * 8.0f
  font.size = 32.0f
  drawTextAligned(ctx, font, card.value, vec2(pad, pad + 48.0f + valueYOffset), color(0.12f, 0.12f, 0.12f, valueAlpha), LeftAlign, MiddleAlign)

  # 4. Integrated Area Sparkline - draws left-to-right last, like a live feed
  let vals = card.sparklineValues
  if vals.len >= 2:
    var minV = vals[0]
    var maxV = vals[0]
    for v in vals:
      if v < minV: minV = v
      if v > maxV: maxV = v
    let span = max(0.001f, maxV - minV)

    let sparkX = pad
    let sparkW = bounds.w - (pad * 2.0f)
    let sparkH = 45.0f
    let sparkY = bounds.h - pad - sparkH
    let stepX = sparkW / (vals.len.float32 - 1.0f)

    let sparkT = easeOutQuad(clamp((progress - 0.45f) / 0.55f, 0.0f, 1.0f))
    let revealX = sparkX + (sparkW * sparkT) + 2.0f

    ctx.save()
    var clip = newPath()
    clip.moveTo(0.0f, 0.0f)
    clip.lineTo(revealX, 0.0f)
    clip.lineTo(revealX, bounds.h)
    clip.lineTo(0.0f, bounds.h)
    clip.closePath()
    ctx.clipPath(clip)

    let linePath = newPath()
    let areaPath = newPath()

    for i in 0 ..< (vals.len - 1):
      let x1 = sparkX + (i.float32 * stepX)
      let x2 = sparkX + ((i.float32 + 1.0f) * stepX)
      let y1 = sparkY + sparkH - (((vals[i] - minV) / span) * sparkH)
      let y2 = sparkY + sparkH - (((vals[i + 1] - minV) / span) * sparkH)
      let ctrlOffset = (x2 - x1) * 0.5f

      if i == 0:
        linePath.moveTo(x1, y1)
        areaPath.moveTo(x1, sparkY + sparkH)
        areaPath.lineTo(x1, y1)

      linePath.bezierCurveTo(x1 + ctrlOffset, y1, x2 - ctrlOffset, y2, x2, y2)
      areaPath.bezierCurveTo(x1 + ctrlOffset, y1, x2 - ctrlOffset, y2, x2, y2)

    let lastX = sparkX + sparkW
    areaPath.lineTo(lastX, sparkY + sparkH)
    areaPath.closePath()

    ctx.fillStyle = card.accentColor.withAlpha(0.20f)
    ctx.fillPath(areaPath)
    ctx.strokeStyle = card.accentColor
    ctx.lineWidth = 2.0f
    ctx.strokePath(linePath)
    ctx.restore()

  ctx.restore()
