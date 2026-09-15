import std/[math]
import pixie
import ../types, ../helpers

proc drawTernaryChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  points: openArray[TernaryPoint],
  config: ChartConfig = defaultChartConfig(),
  labelA: string = "Component A",
  labelB: string = "Component B",
  labelC: string = "Component C"
) =
  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  let side = min(bounds.w, bounds.h) - (config.margin * 3.0f)
  let triH = side * (sqrt(3.0f) * 0.5f)
  let center = vec2(bounds.w * 0.5f, bounds.h * 0.52f)
  let progress = config.animationProgress

  let topV = vec2(center.x, center.y - (triH * 0.5f))
  let leftV = vec2(center.x - (side * 0.5f), center.y + (triH * 0.5f))
  let rightV = vec2(center.x + (side * 0.5f), center.y + (triH * 0.5f))

  # 1. Equilateral Triangle Frame - fades/scales in from the centroid,
  # establishing the "stage" before data points arrive.
  let frameT = easeOutQuad(clamp(progress / 0.4f, 0.0f, 1.0f))
  let centroid = vec2((topV.x + leftV.x + rightV.x) / 3.0f, (topV.y + leftV.y + rightV.y) / 3.0f)
  proc scaledPt(p: Vec2): Vec2 = centroid + ((p - centroid) * (0.85f + 0.15f * frameT))

  let sTop = scaledPt(topV)
  let sLeft = scaledPt(leftV)
  let sRight = scaledPt(rightV)

  let triPath = newPath()
  triPath.moveTo(sTop.x, sTop.y)
  triPath.lineTo(sLeft.x, sLeft.y)
  triPath.lineTo(sRight.x, sRight.y)
  triPath.closePath()

  ctx.strokeStyle = config.borderLineColor.withAlpha(config.borderLineColor.a * frameT)
  ctx.lineWidth = 2.0f
  ctx.strokePath(triPath)

  # 2. Grid Lines (20%, 40%, 60%, 80%)
  for k in 1 .. 4:
    let f = k.float32 * 0.20f
    # A-parallel lines
    let p0 = leftV + ((topV - leftV) * f)
    let p1 = rightV + ((topV - rightV) * f)
    ctx.beginPath()
    ctx.moveTo(p0.x, p0.y)
    ctx.lineTo(p1.x, p1.y)
    ctx.strokeStyle = config.yAxisLinesColor.withAlpha(config.yAxisLinesColor.a * frameT)
    ctx.lineWidth = 1.0f
    ctx.stroke()

  # 3. Data Markers - pop in one by one after the triangle has settled
  let n = points.len
  for i in 0 ..< n:
    let pt = points[i]
    let sum = pt.a + pt.b + pt.c
    if sum > 0.0f:
      let itemT = easeOutBack(staggerProgress(i, n, clamp((progress - 0.25f) / 0.75f, 0.0f, 1.0f), 0.6f))
      if itemT <= 0.0f:
        continue
      let a = pt.a / sum
      let b = pt.b / sum
      let c = pt.c / sum

      # Barycentric coordinate mapping
      let px = (a * topV.x) + (b * leftV.x) + (c * rightV.x)
      let py = (a * topV.y) + (b * leftV.y) + (c * rightV.y)
      let r = 5.0f * clamp(itemT, 0.0f, 1.15f)
      let alpha = min(1.0f, itemT)

      ctx.fillStyle = pt.color.withAlpha(alpha)
      ctx.beginPath()
      ctx.circle(px, py, r)
      ctx.fill()
      ctx.strokeStyle = color(1, 1, 1, alpha)
      ctx.lineWidth = 1.5f
      ctx.stroke()

      if pt.label.len > 0:
        font.size = config.labelTextSize * 0.80f
        drawTextAligned(ctx, font, pt.label, vec2(px + 8.0f, py), config.labelColor.withAlpha(alpha), LeftAlign, MiddleAlign)

  # 4. Corner Labels
  font.size = config.labelTextSize
  drawTextAligned(ctx, font, labelA, vec2(topV.x, topV.y - 12.0f), config.labelColor.withAlpha(frameT), CenterAlign, BottomAlign)
  drawTextAligned(ctx, font, labelB, vec2(leftV.x - 8.0f, leftV.y + 8.0f), config.labelColor.withAlpha(frameT), RightAlign, TopAlign)
  drawTextAligned(ctx, font, labelC, vec2(rightV.x + 8.0f, rightV.y + 8.0f), config.labelColor.withAlpha(frameT), LeftAlign, TopAlign)

  ctx.restore()
