# context.R — execution context for NSSK.R analysis
#
# Resolves and validates the input file and output directory for NSSK.R,
# in both headless (Rscript) and interactive (RStudio) modes.
#
# Sourced by NSSK.R during workspace setup (section 1.1.2).
#
# Exports:
#   input_file_arg        — named list key for the input file path in the get_context() result
#   output_dir_arg        — named list key for the output directory in the get_context() result
#   default_input_file    — default CSV path (relative to project root); edit to change the default
#   default_output_parent — default parent directory for timestamped run output; edit to change
#   get_context()         — resolves and returns the input file and output directory

# Named list keys for the get_context() return value.
input_file_arg <- "input_file"
output_dir_arg <- "output_dir"

# Default input file used in interactive (RStudio) mode.
# Supports ./, ../, ~/, or absolute paths; ./ is relative to the project root (NSSK.R's directory).
default_input_file <- "./May_30_2025_Download.csv"

# Default parent directory for timestamped run output directories.
# Supports ./, ../, ~/, or absolute paths; ./ is relative to the project root.
default_output_parent <- "."

# Normalized at source time against the project root (.script_dir set by NSSK.R before sourcing).
.normalized_default_input_file    <- as.character(fs::path_abs(default_input_file,   start = .script_dir))
.normalized_default_output_parent <- as.character(fs::path_abs(default_output_parent, start = .script_dir))

.print_usage <- function() {
  cat(r"(
NSSK.R - North Shore Streamkeepers Summary Chloride Analysis
Analysis by Clare L. Kilgour <https://github.com/clarekilgour>

Usage: Rscript NSSK.R <input_csv_file> [-o <output_dir>]

Arguments:
  input_csv_file      Path to the CSV file containing water quality data.

Options:
  -o <output_dir>     Optional: directory where output directories and files will be written.
                      If not provided, a timestamped directory will be created in the project root.
  --help, -h          Show this help message and exit.

)")
}

.make_timestamped_dir <- function(parent) {
  file.path(parent, paste0("analysis-", format(Sys.time(), "%Y%m%d-%H%M%S")))
}

# Resolve and validate the input file and output directory.
# Returns a named list with keys input_file_arg and output_dir_arg; both are always non-NULL.
#
# .interactive — injectable for testing; defaults to the actual interactive() state.
# .args        — injectable for testing; defaults to commandArgs(trailingOnly = TRUE).
get_context <- function(.interactive = interactive(), .args = commandArgs(trailingOnly = TRUE)) {

  if (.interactive) {
    # Interactive (RStudio): commandArgs() returns nothing useful; use defaults.
    input_file <- .normalized_default_input_file
    output_dir <- .make_timestamped_dir(.normalized_default_output_parent)

  } else {
    # Headless (Rscript): resolve from command-line arguments.

    if (any(.args %in% c("-h", "--help"))) {
      .print_usage()
      quit(status = 0)
    }

    # Parse -o <output_dir>
    output_dir_flag <- which(.args == "-o")
    if (length(output_dir_flag) > 0) {
      flag_idx <- output_dir_flag[1]
      if (flag_idx >= length(.args)) stop("-o flag requires a directory argument.")
      output_dir <- .args[flag_idx + 1]
      .args <- .args[-c(flag_idx, flag_idx + 1)]
    } else {
      output_dir <- .make_timestamped_dir(.normalized_default_output_parent)
    }

    # Input file is required in headless mode.
    if (length(.args) < 1 || !nzchar(.args[1])) {
      .print_usage()
      quit(status = 1)
    }
    input_file <- .args[1]
  }

  # Validate and normalize (both modes).
  if (!file.exists(input_file)) stop("Input CSV file not found: ", input_file)
  input_file <- as.character(fs::path_abs(input_file))
  output_dir <- as.character(fs::path_abs(output_dir))

  result <- list()
  result[[input_file_arg]] <- input_file
  result[[output_dir_arg]] <- output_dir
  result
}
