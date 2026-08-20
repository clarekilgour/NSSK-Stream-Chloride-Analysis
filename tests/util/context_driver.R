# context_driver.R — resolves and prints the NSSK.R execution context
# (input file, output directory) without running the full analysis.
#
# Useful for verifying context.R's resolution logic in either mode
# without paying the cost of the full NSSK.R run.
#
# Usage:
#   Headless:    Rscript tests/util/context_driver.R <input_csv_file> [-o <output_dir>]
#   Interactive: source("tests/util/context_driver.R") from RStudio — uses context.R's
#                interactive defaults (default_input_file, timestamped output dir).

library(fs)

# Resolve the directory containing this script so context.R can be sourced by path
# regardless of the working directory at invocation time. Mirrors NSSK.R section 1.1.1.
.driver_dir <- if (!interactive()) {
  file_arg <- grep("--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(file_arg) == 0) {
    stop("--file= not found in commandArgs — invoke the script via: Rscript tests/util/context_driver.R <input_csv_file>")
  }
  as.character(fs::path_dir(fs::path_abs(sub("--file=", "", file_arg[1]))))
} else {
  getwd()
}

# context.R lives two directories up, in the project root; .script_dir is the name
# context.R expects to find in its sourcing environment (used to normalize its defaults).
.script_dir <- as.character(fs::path_abs(file.path(.driver_dir, "..", "..")))
source(file.path(.script_dir, "context.R")) # get_context, input_file_arg, output_dir_arg

ctx <- get_context()

cat("Input file:       ", ctx[[input_file_arg]], "\n")
cat("Output directory: ", ctx[[output_dir_arg]], "\n")
