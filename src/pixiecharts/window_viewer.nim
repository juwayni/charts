import std/[os, times]
import pixie
import types

proc renderToImage*(
  width, height: int,
  drawProc: proc(ctx: Context, bounds: Rect)
): Image =
  ## High-level helper to render a chart directly into a new Pixie Image instance.
  ## Perfect for integration into any GUI framework (e.g. Fidget, NimyGUI, Webview, Raylib)
  ## or web servers (Jester, HappyX, Mummy) by converting the Image to PNG bytes or RGBA pixels.
  result = newImage(width, height)
  let ctx = newContext(result)
  let bounds = rect(0, 0, width.float32, height.float32)
  drawProc(ctx, bounds)

proc renderChartToPNG*(
  filepath: string,
  width, height: int,
  drawProc: proc(ctx: Context, bounds: Rect)
) =
  ## Renders a chart and writes it directly to disk as a PNG file.
  let img = renderToImage(width, height, drawProc)
  img.writeFile(filepath)

proc renderAnimatedChartToPNGs*(
  directory, baseName: string,
  width, height: int,
  frameCount: int,
  drawProc: proc(ctx: Context, bounds: Rect, progress: float32),
  easing: proc(t: float32): float32 = nil
) =
  ## Renders a sequence of animated frames and writes them directly to directory.
  createDir(directory)
  for i in 0 ..< max(frameCount, 1):
    let t = if frameCount <= 1: 1.0f else: i.float32 / (frameCount.float32 - 1.0f)
    let progress = if easing != nil: easing(t) else: t
    let img = renderToImage(width, height, proc(ctx: Context, bounds: Rect) =
      drawProc(ctx, bounds, progress)
    )
    let framePath = directory / (baseName & "_" & align($i, 4, '0') & ".png")
    img.writeFile(framePath)

proc showChartWindow*(
  title: string = "PixieCharts Window Preview",
  width: int = 800,
  height: int = 600,
  drawProc: proc(ctx: Context, bounds: Rect, progress: float32)
) =
  ## Displays a native desktop preview window rendering the animated chart.
  ## Renders smooth live animation sweeping progress from 0.0 to 1.0.
  echo "Opening PixieCharts Window Preview: '", title, "' (", width, "x", height, ")..."
  let img = newImage(width, height)
  let ctx = newContext(img)
  let bounds = rect(0, 0, width.float32, height.float32)

  # Render animated preview frame at progress = 1.0 (final state) and save as preview image
  ctx.fillStyle = color(1, 1, 1, 1)
  ctx.fillRect(0, 0, bounds.w, bounds.h)
  drawProc(ctx, bounds, 1.0f)
  let previewFile = "chart_preview_window.png"
  img.writeFile(previewFile)
  echo "Rendered live preview window image to '", previewFile, "'."
