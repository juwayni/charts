# PixieCharts — Animation & Quality Overhaul

**Important:** this sandbox has no Nim compiler and no network access, so none
of this could be compiled or run here. Everything was written by hand,
carefully reusing patterns already proven elsewhere in your own codebase.
**Please run `nimble install pixie` and `nim c -r tests/t_gallery_gen.nim`
before relying on this** — treat this as a thorough, ready-for-review pass,
not a verified-working build.

## The core problem

`ChartConfig.animationProgress` already existed in `types.nim`, but a large
fraction of the 56 chart files never read it, or only used it for one flat
global fade. So the library could render charts, but almost none of them
actually *animated* in any meaningful way.

## What changed

### 1. `helpers.nim` — new shared animation/color toolkit
- Easing functions: `easeOutCubic` (`easeOut`), `easeOutQuad`, `easeOutBack`
  (springy overshoot/"pop"), `easeOutElastic`, `easeOutCirc`, `easeInOutCubic`.
- `staggerProgress(index, total, progress, overlap)` — turns one global
  `animationProgress` value into N overlapping per-item timelines, so items
  animate in one after another instead of all in lockstep, while still all
  finishing exactly at `progress = 1`.
- `positionStagger(pos, total, progress, overlap)` — same idea keyed by a
  continuous position (x-coordinate, reading-order fraction) instead of an
  index; used for left-to-right "wipe" reveals (dendrogram, arc diagram).
- Color helpers: `lighten`, `darken`, `mixColor`, `lerp`, and a curated
  10-color `NicePalette` / `paletteColor(i)`.
- `drawSoftShadow` — a dependency-free approximate drop shadow (used on the
  KPI card).
- `renderAnimationFrames` / `saveAnimationFrames` — sweep any chart's
  `animationProgress` from 0→1 across N frames and write them as a PNG
  sequence, so you can encode a real GIF/MP4 with e.g.
  `ffmpeg -framerate 30 -i frame_%04d.png -vf "fps=30" chart.gif`.
  Demonstrated in `tests/t_gallery_gen.nim`.

### 2. Charts that were completely static (fixed)
`boxplot_chart`, `candlestick_chart`, `calendar_heatmap`, `dendrogram_chart`,
`timeline_chart`, `quadrant_chart`, `heatmap_chart`, `treemap_chart`,
`ternary_chart`, `likert_chart`, `stepline_chart` — all ignored
`animationProgress` entirely. Each now has a real entrance animation
appropriate to its shape (grow, sweep, reveal, pop-in with stagger).

### 3. Real bugs fixed (not just missing animation)
- **`circlepack_chart`**: circle radii were computed *with* the animation
  progress baked in, before the packing/relaxation layout ran — meaning the
  bubbles didn't just grow, the whole layout reflowed and circles visibly
  drifted to different positions across frames. Fixed by packing at final
  radii first, and applying progress only as a visual scale afterward.
- **`waterfall_chart`**: each bar's end value was computed from an animated
  (partial) increment while the *next* bar's start baseline used the true,
  fully-summed running total — so adjacent bars visibly gapped/overlapped
  mid-animation. Fixed by precomputing true running totals first, then
  animating each bar's own reveal against that fixed baseline.
- **`donutchart`**: every wedge's angular width was scaled by `progress`
  directly, so at 50% progress all wedges were proportionally shrunk and
  repacked into a fan near the start angle rather than sweeping around the
  circle. Replaced with a proper clock-style reveal: wedges are drawn at
  their true final angles, and a growing sector clip mask reveals them.
- **`arcdiagram_chart`**: the reveal used a `PI - sweep` angle range with the
  "anticlockwise" flag, which swept through the *bottom* of the circle
  instead of the top during partial animation (only the final frame looked
  right). Fixed the angle math to sweep through the top consistently.
- **`sankey_chart`**: node rectangles were drawn at full size regardless of
  `animationProgress` — only the flow ribbons animated. Nodes now grow in
  stage by stage along with the ribbons.

### 4. Everything else — upgraded from "one flat fade" to real motion
The remaining ~40 files (bar/line/donut/gauge/radar and all the rest) had
some animation but usually just a single uniform fade or scale applied to
every element simultaneously. These now use `staggerProgress`/
`positionStagger` plus the new easing curves for staggered, springy,
per-element entrances — bars/points/nodes that pop in one after another,
lines/areas that reveal left-to-right via clip masks, rings/gauges that
sweep with elastic/back easing, backdrops (grids, axes) that fade in before
the data on top of them.

### 5. Visual polish
- Consistent alpha fade-ins for previously-static backdrops (grid lines,
  axis labels, legends) so nothing just snaps into existence.
- A soft drop shadow under the KPI card.
- Minor color/consistency touch-ups using the new color helpers.

## Follow-up pass: geometry, text alignment, and number formatting

Beyond animation, a second pass audited the actual layout/geometry math and
text handling across every chart:

### Real bugs fixed
- **`violin_chart`**: the density silhouette plotted `densityY` (a 0..1
  fraction of *that violin's own* min/max span) directly against the chart
  height, completely bypassing the shared axis's `niceMin`/`valRange` scale
  that the quantile marker line used. Result: the silhouette didn't line up
  with its own median/quartile marker, and violins with different ranges
  weren't visually comparable. Fixed to map through the same axis transform
  as everything else. Also added a proper Y-axis grid+labels, which this
  chart was missing entirely.
- **`calculateYAxis`** (shared by bar/line/point charts): measured the
  left-margin width using Nim's raw `$v` float stringification (e.g.
  `"123.45600006"`), while the axis actually draws a differently-rounded
  string — so the margin was sized for text that was never shown. Now both
  measurement and display use the same `formatNiceNumber`.
- **`drawYAxisLinesAndText`** (shared by bar/line/point charts): never faded
  in with the rest of the animation (grid + numbers snapped in at full
  opacity immediately) and had the same raw-float-string cosmetic issue.
  Now takes an `alpha` param and formats numbers cleanly.
- **Font-size state leak** in `barchart`, `linechart`, `pointchart`: each
  sets `font.size = config.valueLabelTextSize` to measure value labels, but
  never reset it back to `config.labelTextSize` before drawing the Y-axis —
  so the Y-axis numbers were silently rendered at the *value label* font
  size instead of the axis label size. Fixed by resetting font size right
  before the axis draws.
- Six charts (`boxplot`, `bubble`, `errorbar`, `dotplot`, `violin`, `pareto`)
  used a **hardcoded `+40px` left margin** for the numeric axis regardless
  of how wide the actual tick labels were — fine for "12" but clips a label
  like "123456.7" and wastes space for "5". Replaced with a new
  `measureNiceScaleLabelWidth` helper that sizes the margin to the real text.

### Polish
- New `formatNiceNumber` helper: whole numbers now print as "5" instead of
  "5.0"; applied everywhere axis/value labels were built with ad-hoc
  `$(round(v * 10.0f) / 10.0f)`-style code (18 call sites across the bar,
  candlestick, box plot, bubble, dot plot, error bar, funnel, heatmap,
  lollipop, parallel coordinates, range bar, semicircle meter, slope, and
  speedometer charts, plus the two shared axis helpers).

- Everything above was written without compiling, so please build first.
- `drawSoftShadow` is currently only used in `kpi_card_chart.nim` — it's a
  general-purpose utility if you want to add depth elsewhere.
- The bonus animation-frame demo at the end of `tests/t_gallery_gen.nim`
  writes `output_gallery/anim_barchart_0000.png` … and can be turned into a
  GIF with the `ffmpeg` command in its comment.

## Follow-up pass: visual polish ("make it beautiful")

Added a reusable depth language and applied it across the highest-traffic
chart types, rather than leaving everything as flat single-tone fills:

- **New `fillBarWithDepth` concept** (soft drop shadow + a subtle lighter
  "sheen" band across the top of each bar) applied by hand to: `barchart`,
  `hbar_chart` (horizontal bars), `waterfall_chart`, `pareto_chart`,
  `pyramid_chart` (both wings), `rangebar_chart`, `gantt_chart`'s progress
  fill, `bullet_chart`'s actual-measure bar, and `lollipop_chart`'s head
  node. All shadows/sheens scale with each item's own animation alpha, so
  they fade in with the rest of the chart rather than snapping in.
- **`donutchart`**: added one soft shadow silhouette behind the whole ring
  (not per-wedge, which would create ugly overlapping seams at every slice
  boundary) plus a thin background-colored stroke between wedges for clean
  separation - a small change that makes a big difference in how "finished"
  a pie/donut looks.
- **`gaugechart`** (both full-circle and half-circle variants) and
  **`radialbar_chart`**: the colored progress arc now has a soft shadow
  copy drawn just behind it, giving the ring a bit of lift off the page
  instead of looking like a flat stroke.
- **Legend swatches** in `waffle_chart` and `multiradar_chart` changed from
  sharp-cornered squares to small rounded squares, matching the rounded
  language used everywhere else (bars, cards, KPI badges).
