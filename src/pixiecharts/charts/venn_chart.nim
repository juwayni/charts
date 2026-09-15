import std/[math]
import pixie
import ../types, ../helpers

proc drawVenn2Chart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  data: Venn2Data,
  config: ChartConfig = defaultChartConfig()
) =
  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  let center = vec2(bounds.w * 0.5f, bounds.h * 0.5f)
  let radius = min(bounds.w, bounds.h) * 0.28f
  let offset = radius * 0.55f
  let progress = config.animationProgress

  let cA = vec2(center.x - offset, center.y)
  let cB = vec2(center.x + offset, center.y)

  # The two circles drift together from further apart, converging into
  # their final overlapping position, with a gentle overshoot as they settle.
  let convergeT = easeOutBack(clamp(progress / 0.6f, 0.0f, 1.0f))
  let spreadFactor = 1.0f + ((1.0f - clamp(convergeT, 0.0f, 1.0f)) * 0.6f)
  let animCA = vec2(center.x - (offset * spreadFactor), center.y)
  let animCB = vec2(center.x + (offset * spreadFactor), center.y)
  let circAlpha = min(1.0f, clamp(progress / 0.4f, 0.0f, 1.0f))

  # Circle A
  ctx.fillStyle = data.colorA.withAlpha(0.40f * circAlpha)
  ctx.beginPath()
  ctx.circle(animCA.x, animCA.y, radius)
  ctx.fill()
  ctx.strokeStyle = data.colorA.withAlpha(circAlpha)
  ctx.lineWidth = 2.0f
  ctx.stroke()

  # Circle B
  ctx.fillStyle = data.colorB.withAlpha(0.40f * circAlpha)
  ctx.beginPath()
  ctx.circle(animCB.x, animCB.y, radius)
  ctx.fill()
  ctx.strokeStyle = data.colorB.withAlpha(circAlpha)
  ctx.lineWidth = 2.0f
  ctx.stroke()

  # Region Labels - fade in once the circles have (mostly) converged
  let labelAlpha = clamp((progress - 0.5f) / 0.5f, 0.0f, 1.0f)
  font.size = config.labelTextSize
  drawTextAligned(ctx, font, data.labelA & "\n(" & $data.countA & ")", vec2(cA.x - (radius * 0.45f), cA.y), data.colorA.withAlpha(labelAlpha), CenterAlign, MiddleAlign)
  drawTextAligned(ctx, font, data.labelB & "\n(" & $data.countB & ")", vec2(cB.x + (radius * 0.45f), cB.y), data.colorB.withAlpha(labelAlpha), CenterAlign, MiddleAlign)
  drawTextAligned(ctx, font, data.labelAB & "\n(" & $data.countAB & ")", center, config.labelColor.withAlpha(labelAlpha), CenterAlign, MiddleAlign)

  ctx.restore()

proc drawVenn3Chart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  data: Venn3Data,
  config: ChartConfig = defaultChartConfig()
) =
  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  let center = vec2(bounds.w * 0.5f, bounds.h * 0.52f)
  let radius = min(bounds.w, bounds.h) * 0.25f
  let offset = radius * 0.55f
  let progress = config.animationProgress

  let cA = vec2(center.x, center.y - offset)
  let cB = vec2(center.x - (offset * cos(PI / 6.0f)), center.y + (offset * sin(PI / 6.0f)))
  let cC = vec2(center.x + (offset * cos(PI / 6.0f)), center.y + (offset * sin(PI / 6.0f)))

  # The three circles converge from further out into their final
  # overlapping arrangement, popping gently into place.
  let convergeT = easeOutBack(clamp(progress / 0.6f, 0.0f, 1.0f))
  let spreadFactor = 1.0f + ((1.0f - clamp(convergeT, 0.0f, 1.0f)) * 0.7f)
  proc spread(p: Vec2): Vec2 = center + ((p - center) * spreadFactor)
  let circAlpha = min(1.0f, clamp(progress / 0.4f, 0.0f, 1.0f))

  # Draw 3 Translucent Circles
  let circles = [(spread(cA), data.colorA), (spread(cB), data.colorB), (spread(cC), data.colorC)]
  for (c, col) in circles:
    ctx.fillStyle = col.withAlpha(0.35f * circAlpha)
    ctx.beginPath()
    ctx.circle(c.x, c.y, radius)
    ctx.fill()
    ctx.strokeStyle = col.withAlpha(circAlpha)
    ctx.lineWidth = 2.0f
    ctx.stroke()

  # Labels fade in once the circles have (mostly) converged
  let labelAlpha = clamp((progress - 0.5f) / 0.5f, 0.0f, 1.0f)
  font.size = config.labelTextSize * 0.85f
  drawTextAligned(ctx, font, data.labelA & "\n" & $data.countA, vec2(cA.x, cA.y - (radius * 0.45f)), data.colorA.withAlpha(labelAlpha), CenterAlign, MiddleAlign)
  drawTextAligned(ctx, font, data.labelB & "\n" & $data.countB, vec2(cB.x - (radius * 0.45f), cB.y + (radius * 0.3f)), data.colorB.withAlpha(labelAlpha), CenterAlign, MiddleAlign)
  drawTextAligned(ctx, font, data.labelC & "\n" & $data.countC, vec2(cC.x + (radius * 0.45f), cC.y + (radius * 0.3f)), data.colorC.withAlpha(labelAlpha), CenterAlign, MiddleAlign)
  drawTextAligned(ctx, font, $data.countABC, center, config.labelColor.withAlpha(labelAlpha), CenterAlign, MiddleAlign)

  ctx.restore()
