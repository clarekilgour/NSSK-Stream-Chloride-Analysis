# render.R — rendering helpers for NSSK.R
#
# Sourced by NSSK.R during workspace setup (section 1.1.1).
# Depends on packages loaded by NSSK.R: ragg, grid, gt.

# Render a gt table object to a PNG file.
# Renders via ragg and grid, avoiding the webshot2/browser dependency of gt::gtsave().
#
# gt_obj   - a gt table object to render
# filename - full output path for the PNG file; parent directory is created if absent
# width    - output image width in pixels (default 2000)
# height   - output image height in pixels (default 1200)
# res      - output resolution in pixels per inch (default 200)
#
# Errors (stop) — examples:
#   - parent directory of filename does not exist and could not be created
#   - ragg could not open a PNG device for filename (e.g. bad path, no write permission)
#   - grid failed to render the gt table (e.g. malformed gt object)
#
# Messages (immediate stderr output):
#   - device close failed on exit
save_gt_png <- function(gt_obj, filename, width = 2000, height = 1200, res = 200) {

  # --- device setup ---

  # Ensure the output directory exists; stop with a clear message if it cannot be created
  if (!dir.create(dirname(filename), recursive = TRUE, showWarnings = FALSE) &&
      !dir.exists(dirname(filename))) {
    stop("save_gt_png: could not create directory: ", dirname(filename))
  }

  # Open a ragg PNG device targeting filename; stop if the file cannot be opened
  tryCatch(
    ragg::agg_png(filename, width = width, height = height, res = res),
    error = function(e) stop("save_gt_png: could not open PNG device for '", filename, "': ", conditionMessage(e))
  )

  # Guarantee the device is closed on function exit whether returning normally or on error.
  # Closing the device flushes rendered content to disk. Wrapped in tryCatch so a flush
  # failure (e.g. disk full) surfaces as a warning rather than masking the original error.
  on.exit(
    tryCatch(
      dev.off(),
      error = function(e) message("save_gt_png: device close failed for '", filename, "': ", conditionMessage(e))
    ),
    add = TRUE
  )

  # --- render ---

  # Convert the gt table to a grid grob and render it to the open device; stop on failure
  tryCatch({
    grid::grid.newpage()
    grid::grid.draw(gt::as_gtable(gt_obj))
  }, error = function(e) stop("save_gt_png: render failed for '", filename, "': ", conditionMessage(e)))
}
