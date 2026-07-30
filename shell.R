# shell.R — command-line argument parsing for NSSK.R
#
# Sourced by NSSK.R during workspace setup (section 1.1.2).
#
# Exports:
#   input_file_arg  — named list key for the input file path in the parse_args() result
#   output_dir_arg  — named list key for the output directory in the parse_args() result
#   parse_args()    — parses a character vector of shell arguments; returns a named list

# Named list keys for the parse_args() return value.
# Callers use these constants to look up values rather than relying on literal key strings.
input_file_arg <- "input_file"
output_dir_arg <- "output_dir_arg"

# Print usage to stdout. Internal helper; called by parse_args() only.
.print_usage <- function() {
  cat(r"(
NSSK.R - North Shore Streamkeepers Summary Chloride Analysis
Analysis by Clare L. Kilgour <https://github.com/clarekilgour>

Usage: Rscript NSSK.R <input_csv_file> [-o <output_dir>]

Arguments:
  input_csv_file      Path to the CSV file containing water quality data.

Options:
  -o <output_dir>     Optional: directory where output directories and files will be written.
                      If not provided, a timestamped directory will be created in the current working directory.
  --help, -h          Show this help message and exit.

)")
}

# Parse shell arguments and return a named list with keys input_file_arg and output_dir_arg.
# Both keys are always present and non-NULL in the returned list.
#
# args - character vector of shell arguments, typically commandArgs(trailingOnly = TRUE)
#
# Stops (not an error) on --help / -h: prints usage, then quits (Rscript) or stops (interactive).
# Stops (error) on:
#   - -o flag with no following value
#   - missing input file argument (Rscript only; interactive falls back to a default path)
#   - input file not found on disk
parse_args <- function(args) {

  # In headless mode, confirm --file= is present in the full command-line arguments.
  # Its absence means the script was not invoked via Rscript and .script_dir resolution
  # in NSSK.R will produce an invalid path.
  if (!interactive()) {
    if (length(grep("--file=", commandArgs(trailingOnly = FALSE))) == 0) {
      stop("--file= not found in commandArgs — invoke the script via: Rscript NSSK.R <input_csv_file>")
    }
  }

  # --help / -h: print usage and terminate; not an error condition
  if (any(args %in% c("-h", "--help"))) {
    .print_usage()
    if (!interactive()) quit(status = 0) else stop("see usage above", call. = FALSE)
  }

  # Parse -o <output_dir>
  output_dir_flag <- which(args == "-o")
  output_dir_value <- NULL
  if (length(output_dir_flag) > 0) {
    flag_idx <- output_dir_flag[1]
    if (flag_idx < length(args)) {
      output_dir_value <- args[flag_idx + 1]
      args <- args[-c(flag_idx, flag_idx + 1)]
    } else {
      stop("-o flag requires a directory argument.")
    }
  }

  # Resolve input file.
  # Headless (Rscript): a missing or empty argument is a fatal usage error — print help and exit.
  # Interactive (RStudio): commandArgs() returns nothing useful, so fall back to a default file
  # relative to the project root. Place the input CSV there before sourcing.
  if (length(args) < 1 || !nzchar(args[1])) {
    if (!interactive()) {
      .print_usage()
      quit(status = 1)
    } else {
      input_file_value <- "./May_30_2025_Download.csv"
    }
  } else {
    input_file_value <- args[1]
  }

  if (!file.exists(input_file_value)) {
    stop("Input CSV file not found: ", input_file_value)
  }

  input_file_value <- normalizePath(input_file_value)

  # Resolve output directory.
  # Headless: use the -o argument if supplied, otherwise create a timestamped directory in cwd.
  # Interactive: -o is never set (commandArgs() is empty), so always produces a timestamped
  # directory under the project root (cwd when opened via the .Rproj file).
  if (is.null(output_dir_value)) {
    output_dir_value <- file.path(getwd(), paste0("analysis-", format(Sys.time(), "%Y%m%d-%H%M%S")))
  }

  output_dir_value <- as.character(fs::path_abs(output_dir_value))

  # Return named list; callers access values via the exported key constants.
  # Both values are always non-NULL; NULL in the caller indicates an internal error.
  result <- list()
  result[[input_file_arg]] <- input_file_value
  result[[output_dir_arg]] <- output_dir_value
  result
}
