import std/[math, algorithm]
import pixie
import ../types, ../helpers

proc boxesIntersect(a, b: Rect): bool =
  not (a.x + a.w < b.x or b.x + b.w < a.x or a.y + a.h < b.y or b.y + b.h < a.y)

proc drawWordCloudChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  items: openArray[WordCloudItem],
  config: ChartConfig = defaultChartConfig()
) =
  if items.len == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  var sortedWords = @items
  sortedWords.sort(proc(a, b: WordCloudItem): int = cmp(b.weight, a.weight))

  let minW = sortedWords[^1].weight
  let maxW = sortedWords[0].weight
  let weightRange = max(1.0f, maxW - minW)

  let center = vec2(bounds.w * 0.5f, bounds.h * 0.5f)
  var placedBoxes: seq[Rect] = @[]
  let n = sortedWords.len

  for wIdx in 0 ..< n:
    let w = sortedWords[wIdx]
    let norm = (w.weight - minW) / weightRange
    let fullFontSize = 12.0f + (norm * 32.0f)
    font.size = fullFontSize
    let textSize = font.measureTextSize(w.text)

    var placed = false
    var theta = 0.0f

    # Words pop in largest/most important first, one after another, with
    # a satisfying little overshoot as each one lands in its spiral slot.
    let wordT = easeOutBack(staggerProgress(wIdx, n, config.animationProgress, 0.55f))

    # Archimedean Spiral Placement using full scale layout
    while theta < 120.0f and not placed:
      let r = 2.5f * theta
      let candidateX = center.x + (r * cos(theta)) - (textSize.x * 0.5f)
      let candidateY = center.y + (r * sin(theta)) - (textSize.y * 0.5f)
      let candidateRect = rect(candidateX, candidateY, textSize.x + 4.0f, textSize.y + 4.0f)

      var collides = false
      for b in placedBoxes:
        if boxesIntersect(candidateRect, b):
          collides = true
          break

      if not collides and candidateRect.x >= 5.0f and candidateRect.y >= 5.0f and
         candidateRect.x + candidateRect.w <= bounds.w - 5.0f and candidateRect.y + candidateRect.h <= bounds.h - 5.0f:
        placedBoxes.add(candidateRect)
        if wordT > 0.0f:
          font.size = max(1.0f, fullFontSize * clamp(wordT, 0.0f, 1.1f))
          drawTextAligned(ctx, font, w.text, vec2(candidateX + (textSize.x * 0.5f), candidateY + (textSize.y * 0.5f)), w.color.withAlpha(w.color.a * min(1.0f, wordT)), CenterAlign, MiddleAlign)
        placed = true

      theta += 0.35f

  ctx.restore()
