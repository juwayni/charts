import std/[math]
import pixie
import ../types, ../helpers

proc drawTimelineChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  events: openArray[TimelineEvent],
  config: ChartConfig = defaultChartConfig()
) =
  let count = events.len
  if count == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  let midY = bounds.h * 0.5f
  let chartW = bounds.w - (config.margin * 2.0f)
  let stepX = chartW / (count.float32 + 0.5f)
  let progress = config.animationProgress

  # Central Spine grows left-to-right, like the timeline is being drawn live.
  let spineT = easeOutQuad(clamp(progress / 0.5f, 0.0f, 1.0f))
  ctx.beginPath()
  ctx.moveTo(config.margin, midY)
  ctx.lineTo(config.margin + (chartW * spineT), midY)
  ctx.strokeStyle = color(0.75f, 0.75f, 0.75f, 1.0f)
  ctx.lineWidth = 3.0f
  ctx.stroke()

  for i in 0 ..< count:
    let ev = events[i]
    let itemT = easeOutBack(staggerProgress(i, count, progress, 0.6f))
    if itemT <= 0.0f:
      continue
    let a = min(1.0f, itemT)
    let cx = config.margin + ((i.float32 + 0.75f) * stepX)
    let isAbove = i mod 2 == 0
    let cardY = if isAbove: midY - 65.0f else: midY + 30.0f

    # Connector stem grows outward from the spine toward the card
    let fullStemY1 = midY
    let fullStemY2 = if isAbove: cardY + 35.0f else: cardY
    let animStemY2 = lerp(fullStemY1, fullStemY2, clamp(itemT, 0.0f, 1.0f))
    ctx.beginPath()
    ctx.moveTo(cx, fullStemY1)
    ctx.lineTo(cx, animStemY2)
    ctx.strokeStyle = ev.color.withAlpha(a)
    ctx.lineWidth = 1.5f
    ctx.stroke()

    # Anchor Node on Spine - pops in with a little overshoot
    ctx.fillStyle = ev.color.withAlpha(a)
    ctx.beginPath()
    ctx.circle(cx, midY, 6.0f * clamp(itemT, 0.0f, 1.15f))
    ctx.fill()
    ctx.strokeStyle = color(1, 1, 1, a)
    ctx.lineWidth = 2.0f
    ctx.stroke()

    # Event Card Box - only draw once the stem has (mostly) reached it
    let cardT = clamp((itemT - 0.5f) / 0.5f, 0.0f, 1.0f)
    if cardT > 0.0f:
      let p = newPath()
      p.roundedRect(rect(cx - 45.0f, cardY, 90.0f, 32.0f), 4.0f, 4.0f)
      ctx.fillStyle = ev.color.withAlpha(0.15f * cardT)
      ctx.fillPath(p)
      ctx.strokeStyle = ev.color.withAlpha(cardT)
      ctx.lineWidth = 1.0f
      ctx.strokePath(p)

      font.size = 10.0f
      drawTextAligned(ctx, font, ev.dateLabel, vec2(cx, cardY + 8.0f), ev.color.withAlpha(cardT), CenterAlign, MiddleAlign)
      font.size = 11.0f
      drawTextAligned(ctx, font, ev.title, vec2(cx, cardY + 22.0f), config.labelColor.withAlpha(cardT), CenterAlign, MiddleAlign)

  ctx.restore()
