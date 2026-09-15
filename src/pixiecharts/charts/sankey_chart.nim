import std/[math, options]
import pixie
import ../types, ../helpers

proc drawSankeyChart*(
  ctx: Context,
  font: Font,
  bounds: Rect,
  data: SankeyData,
  config: ChartConfig = defaultChartConfig()
) =
  let stageCount = data.stages.len
  if stageCount < 2:
    return

  ctx.save()
  ctx.translate(bounds.x, bounds.y)
  ctx.fillStyle = config.backgroundColor
  ctx.fillRect(0, 0, bounds.w, bounds.h)

  let chartW = bounds.w - (config.margin * 2.0f)
  let chartH = bounds.h - (config.margin * 2.0f)
  let nodeW = 16.0f
  let stageGap = (chartW - (stageCount.float32 * nodeW)) / (stageCount.float32 - 1.0f)

  # Compute node throughput totals
  var nodeThroughputs: seq[float32] = @[]
  var totalMaxStageValue = 0.0f

  for sIdx in 0 ..< stageCount:
    var stageSum = 0.0f
    for n in data.stages[sIdx]:
      var nodeSum = 0.0f
      for l in data.links:
        if l.sourceId == n.id or l.targetId == n.id:
          nodeSum += l.value
      nodeThroughputs.add(nodeSum)
      stageSum += nodeSum
    if stageSum > totalMaxStageValue: totalMaxStageValue = stageSum

  if totalMaxStageValue <= 0.0f: totalMaxStageValue = 1.0f

  # Compute and store vertical coordinates per node
  var nodeTops: seq[float32] = @[]
  var nodeHeights: seq[float32] = @[]
  var nodeIndex = 0

  for sIdx in 0 ..< stageCount:
    let stage = data.stages[sIdx]
    let verticalSpacing = 12.0f
    let availableH = chartH - ((stage.len.float32 - 1.0f) * verticalSpacing)

    var currentY = config.margin
    for n in stage:
      let tp = nodeThroughputs[nodeIndex]
      let h = max(4.0f, (tp / totalMaxStageValue) * availableH)
      nodeTops.add(currentY)
      nodeHeights.add(h)
      currentY += h + verticalSpacing
      inc nodeIndex

  let progress = config.animationProgress

  # 1. Render Smooth Flow Ribbons - each link fills in one after another,
  # like liquid flowing stage by stage through the diagram.
  for lIdx in 0 ..< data.links.len:
    let l = data.links[lIdx]
    let linkT = easeOutQuad(staggerProgress(lIdx, data.links.len, progress, 0.55f))
    if linkT <= 0.0f:
      continue
    # Find source and target geometry
    var srcX, srcY, srcH, dstX, dstY, dstH: float32
    var foundSrc = false
    var foundDst = false
    var nIdx = 0

    for sIdx in 0 ..< stageCount:
      let stX = config.margin + (sIdx.float32 * (nodeW + stageGap))
      for n in data.stages[sIdx]:
        if n.id == l.sourceId:
          srcX = stX + nodeW
          srcY = nodeTops[nIdx]
          srcH = nodeHeights[nIdx]
          foundSrc = true
        elif n.id == l.targetId:
          dstX = stX
          dstY = nodeTops[nIdx]
          dstH = nodeHeights[nIdx]
          foundDst = true
        inc nIdx

    if foundSrc and foundDst:
      let linkH = max(2.0f, (l.value / totalMaxStageValue) * chartH * linkT)
      let ribbonPath = newPath()
      let ctrlOffset = (dstX - srcX) * 0.5f

      # Top curve
      ribbonPath.moveTo(srcX, srcY)
      ribbonPath.bezierCurveTo(srcX + ctrlOffset, srcY, dstX - ctrlOffset, dstY, dstX, dstY)
      # Right edge
      ribbonPath.lineTo(dstX, dstY + linkH)
      # Bottom curve backwards
      ribbonPath.bezierCurveTo(dstX - ctrlOffset, dstY + linkH, srcX + ctrlOffset, srcY + linkH, srcX, srcY + linkH)
      ribbonPath.closePath()

      let linkColor = l.color.get(color(0.5f, 0.7f, 0.9f, 0.45f))
      ctx.fillStyle = linkColor.withAlpha(linkColor.a * min(1.0f, linkT * 1.5f))
      ctx.fillPath(ribbonPath)

  # 2. Render Solid Node Rectangles & Labels - each stage's nodes grow
  # upward from their baseline and fade in, staggered stage by stage.
  var nIdx = 0
  font.size = config.labelTextSize * 0.85f
  for sIdx in 0 ..< stageCount:
    let stX = config.margin + (sIdx.float32 * (nodeW + stageGap))
    let stageT = easeOutBack(staggerProgress(sIdx, stageCount, progress, 0.7f))
    for n in data.stages[sIdx]:
      let fullY = nodeTops[nIdx]
      let fullH = nodeHeights[nIdx]
      let h = fullH * clamp(stageT, 0.0f, 1.0f)
      let y = fullY + (fullH - h)
      let a = min(1.0f, stageT)

      ctx.fillStyle = n.color.withAlpha(a)
      ctx.fillRect(stX, y, nodeW, h)

      if a > 0.4f:
        let labelX = if sIdx == 0: stX - 6.0f else: stX + nodeW + 6.0f
        let align = if sIdx == 0: RightAlign else: LeftAlign
        drawTextAligned(ctx, font, n.label, vec2(labelX, fullY + (fullH * 0.5f)), config.labelColor.withAlpha(a), align, MiddleAlign)
      inc nIdx

  ctx.restore()
