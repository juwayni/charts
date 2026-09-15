import std/[math]
import pixie
import ../types, ../helpers

proc drawCandlestickChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  candles: openArray[CandleEntry],
  config: ChartConfig = defaultChartConfig(),
  bullColor: Color = color(0.15f, 0.68f, 0.38f, 1.0f),
  bearColor: Color = color(0.91f, 0.30f, 0.24f, 1.0f),
  smaPeriod: int = 5
) =
  if candles.len == 0:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  var minPrice = candles[0].low
  var maxPrice = candles[0].high
  var maxVol = 0.0f
  for c in candles:
    if c.low < minPrice: minPrice = c.low
    if c.high > maxPrice: maxPrice = c.high
    if c.volume > maxVol: maxVol = c.volume

  let padding = (maxPrice - minPrice) * 0.05f
  minPrice -= padding
  maxPrice += padding
  let priceRange = max(0.001f, maxPrice - minPrice)

  let rightAxisW = 60.0f
  let footerH = config.labelTextSize + (config.margin * 1.5f)
  let chartW = bounds.w - config.margin - rightAxisW
  let hasVolume = maxVol > 0.0f
  let volumeH = if hasVolume: (bounds.h - footerH) * 0.20f else: 0.0f
  let candleChartH = bounds.h - footerH - volumeH - config.margin
  let progress = config.animationProgress

  let count = candles.len.float32
  let slotW = chartW / count
  let candleW = max(2.0f, slotW * 0.70f)

  # Render Price Grid Lines & Scale (fades in as the stage)
  let gridAlpha = clamp(progress / 0.3f, 0.0f, 1.0f)
  let ticks = 5
  for i in 0 ..< ticks:
    let frac = i.float32 / (ticks.float32 - 1.0f)
    let p = minPrice + (frac * priceRange)
    let y = config.margin + ((1.0f - frac) * candleChartH)

    ctx.beginPath()
    ctx.moveTo(config.margin, y)
    ctx.lineTo(config.margin + chartW, y)
    ctx.strokeStyle = config.yAxisLinesColor.withAlpha(config.yAxisLinesColor.a * gridAlpha)
    ctx.lineWidth = 1.0f
    ctx.stroke()

    let priceStr = formatNiceNumber(p, 2)
    drawTextAligned(ctx, font, priceStr, vec2(config.margin + chartW + 5.0f, y),
      config.yAxisTextColor.withAlpha(gridAlpha), LeftAlign, MiddleAlign)

  # Render Candles & Wicks - a left-to-right "ticker" reveal: candles pop in
  # one after another as `progress` sweeps across the timeline, each with a
  # tiny vertical grow-from-open animation.
  for i in 0 ..< candles.len:
    let c = candles[i]
    let itemT = easeOutBack(staggerProgress(i, candles.len, progress, 0.55f))
    if itemT <= 0.0f:
      continue
    let centerX = config.margin + (i.float32 * slotW) + (slotW * 0.5f)
    let isBull = c.close >= c.open
    let cColor = if isBull: bullColor else: bearColor

    let highY = config.margin + ((1.0f - ((c.high - minPrice) / priceRange)) * candleChartH)
    let lowY = config.margin + ((1.0f - ((c.low - minPrice) / priceRange)) * candleChartH)
    let openY = config.margin + ((1.0f - ((c.open - minPrice) / priceRange)) * candleChartH)
    let closeY = config.margin + ((1.0f - ((c.close - minPrice) / priceRange)) * candleChartH)

    # Wick and body both grow outward from the open price line
    let animHighY = lerp(openY, highY, clamp(itemT, 0.0f, 1.0f))
    let animLowY = lerp(openY, lowY, clamp(itemT, 0.0f, 1.0f))
    let animCloseY = lerp(openY, closeY, clamp(itemT, 0.0f, 1.0f))

    # High-Low Wick
    ctx.beginPath()
    ctx.moveTo(centerX, animHighY)
    ctx.lineTo(centerX, animLowY)
    ctx.strokeStyle = cColor.withAlpha(min(1.0f, itemT))
    ctx.lineWidth = 1.5f
    ctx.stroke()

    # Candle Body
    let bodyTop = min(openY, animCloseY)
    let bodyH = max(1.5f, abs(animCloseY - openY))
    ctx.fillStyle = cColor.withAlpha(min(1.0f, itemT))
    ctx.fillRect(centerX - (candleW * 0.5f), bodyTop, candleW, bodyH)

    # Volume Bar
    if hasVolume and c.volume > 0.0f:
      let vH = (c.volume / maxVol) * volumeH * 0.85f * clamp(itemT, 0.0f, 1.0f)
      let vY = (bounds.h - footerH) - vH
      ctx.fillStyle = cColor.withAlpha(0.40f * min(1.0f, itemT))
      ctx.fillRect(centerX - (candleW * 0.5f), vY, candleW, vH)

    # X-Axis Date
    if i mod max(1, (candles.len div 6)) == 0:
      drawTextAligned(ctx, font, c.dateLabel, vec2(centerX, bounds.h - (footerH * 0.5f)),
        config.labelColor.withAlpha(min(1.0f, itemT)), CenterAlign, MiddleAlign)

  # Simple Moving Average (SMA) Overlay - drawn as a reveal that traces
  # across the chart along with the candle "ticker" sweep.
  if smaPeriod > 1 and candles.len >= smaPeriod:
    let smaPath = newPath()
    var hasFirst = false
    var lastPt = vec2(0, 0)
    for i in (smaPeriod - 1) ..< candles.len:
      let itemT = staggerProgress(i, candles.len, progress, 0.55f)
      if itemT <= 0.0f:
        continue
      var sum = 0.0f
      for j in (i - smaPeriod + 1) .. i:
        sum += candles[j].close
      let avg = sum / smaPeriod.float32
      let x = config.margin + (i.float32 * slotW) + (slotW * 0.5f)
      let y = config.margin + ((1.0f - ((avg - minPrice) / priceRange)) * candleChartH)
      if not hasFirst:
        smaPath.moveTo(x, y)
        hasFirst = true
      else:
        smaPath.lineTo(x, y)
      lastPt = vec2(x, y)

    if hasFirst:
      ctx.strokeStyle = color(0.95f, 0.77f, 0.06f, min(1.0f, progress * 1.5f))
      ctx.lineWidth = 2.0f
      ctx.strokePath(smaPath)
      # small glowing head dot to sell the "drawing" motion
      if progress < 0.98f:
        ctx.fillStyle = color(0.95f, 0.77f, 0.06f, 0.9f)
        ctx.beginPath()
        ctx.circle(lastPt.x, lastPt.y, 3.0f)
        ctx.fill()

  ctx.restore()
