import std/[math]
import pixie
import ../types, ../helpers

proc drawPyramidChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  cohorts: openArray[PyramidCohort],
  config: ChartConfig = defaultChartConfig(),
  leftColor: Color = color(0.18f, 0.53f, 0.82f, 1.0f),
  rightColor: Color = color(0.91f, 0.30f, 0.24f, 1.0f)
) =
  let count = cohorts.len.float32
  if count == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  var maxVal = 0.0f
  for c in cohorts:
    if c.leftValue > maxVal: maxVal = c.leftValue
    if c.rightValue > maxVal: maxVal = c.rightValue
  if maxVal <= 0.0f: maxVal = 1.0f

  let centerColW = 70.0f
  let wingW = (bounds.w - (config.margin * 2.0f) - centerColW) * 0.5f
  let leftWingRight = config.margin + wingW
  let rightWingLeft = leftWingRight + centerColW

  let rowH = (bounds.h - (config.margin * 2.0f)) / count
  let barH = max(2.0f, rowH * 0.70f)
  let progress = config.animationProgress

  font.size = config.labelTextSize

  for i in 0 ..< cohorts.len:
    let c = cohorts[i]
    let y = config.margin + (i.float32 * rowH) + (rowH * 0.5f) - (barH * 0.5f)
    # Rows sweep outward from the center, one after another (bottom-up
    # reads naturally for population pyramids, so we stagger by reversed
    # index).
    let itemT = easeOutQuad(staggerProgress(cohorts.len - 1 - i, cohorts.len, progress, 0.65f))
    let alpha = min(1.0f, itemT * 2.0f)

    # Left-wing Bar (anchored at center, growing leftwards)
    let leftW = (c.leftValue / maxVal) * wingW * itemT
    if leftW > 0.5f:
      ctx.fillStyle = color(0.0f, 0.0f, 0.0f, 0.12f * alpha)
      ctx.fillRect(leftWingRight - leftW + 1.0f, y + 2.0f, leftW, barH)
    ctx.fillStyle = leftColor.withAlpha(alpha)
    ctx.fillRect(leftWingRight - leftW, y, leftW, barH)
    let leftSheenH = min(barH * 0.4f, 6.0f)
    if leftW > 1.0f and leftSheenH > 1.5f:
      ctx.fillStyle = color(1.0f, 1.0f, 1.0f, 0.15f * alpha)
      ctx.fillRect(leftWingRight - leftW, y, leftW, leftSheenH)

    # Right-wing Bar (anchored at center, growing rightwards)
    let rightW = (c.rightValue / maxVal) * wingW * itemT
    if rightW > 0.5f:
      ctx.fillStyle = color(0.0f, 0.0f, 0.0f, 0.12f * alpha)
      ctx.fillRect(rightWingLeft + 1.0f, y + 2.0f, rightW, barH)
    ctx.fillStyle = rightColor.withAlpha(alpha)
    ctx.fillRect(rightWingLeft, y, rightW, barH)
    if rightW > 1.0f and leftSheenH > 1.5f:
      ctx.fillStyle = color(1.0f, 1.0f, 1.0f, 0.15f * alpha)
      ctx.fillRect(rightWingLeft, y, rightW, leftSheenH)

    # Center Cohort Label
    drawTextAligned(ctx, font, c.cohortLabel, vec2(leftWingRight + (centerColW * 0.5f), y + (barH * 0.5f)), config.labelColor.withAlpha(alpha), CenterAlign, MiddleAlign)

  ctx.restore()
