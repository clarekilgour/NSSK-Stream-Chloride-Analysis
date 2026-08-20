# theme.R — plot theme configuration for NSSK.R
# Resolves the active font for the current platform and exposes build_theme()
# for constructing a consistent ggplot2 theme across all plots.

# Target font for all platforms. Change here to switch the project font.
target_font <- "Helvetica"

# Linux fallback fonts per target font, in order of visual fidelity to the target.
# At 300 DPI, FreeType hinting is irrelevant — outline quality and spacing accuracy dominate.
# Add an entry here when changing target_font.
# Packages: fonts-texgyre (TeX Gyre Heros), fonts-urw-base35 (Nimbus Sans), fonts-liberation (Liberation Sans)
linux_font_fallbacks <- list(
  "Helvetica" = c("TeX Gyre Heros", "Nimbus Sans", "Liberation Sans"),
  "Arial"     = c("Liberation Sans", "Nimbus Sans")
)

# Resolves .theme_font for the current platform at source time.
# macOS: target_font is used directly; Helvetica is a native system font.
# Windows: target_font is used directly; not all fonts are standard — systemfonts falls back to
#   the system sans if not found.
# Linux: falls through linux_font_fallbacks[[target_font]] in order until a match is found.
# systemfonts is available via ragg without an explicit library() call.
.theme_font <- local({
  sysname <- Sys.info()[["sysname"]]
  if (sysname %in% c("Darwin", "Windows")) {
    message("Using plot font on ", sysname, ": ", target_font)
    target_font
  } else {
    if (!target_font %in% names(linux_font_fallbacks)) {
      stop(paste0("No Linux font fallback list defined for target_font '", target_font, "'. Add an entry to linux_font_fallbacks in theme.R."))
    }
    families <- unique(systemfonts::system_fonts()$family)
    found    <- intersect(linux_font_fallbacks[[target_font]], families)
    if (length(found) > 0) {
      message("Using Linux fallback font for ", target_font, ": ", found[1])
      found[1]
    } else {
      warning("No equivalent font found on Linux for '", target_font, "' — plots will use the system default sans.")
      ""
    }
  }
})

# Returns a theme_bw() with .theme_font set as the default base_family.
# All arguments are passed to theme_bw() — use + theme(...) at the call site
# for ad-hoc theme() element overrides (e.g. legend.position, panel.grid.minor).
build_theme <- function(...) {
  args <- list(...)
  if (!"base_family" %in% names(args)) args$base_family <- .theme_font
  do.call(theme_bw, args)
}
