# Tests for context.R
#
# Run from the project root:
#   Rscript tests/test-context.R

library(testthat)
library(fs)

# context.R expects .script_dir to be set before it is sourced.
.script_dir <- as.character(fs::path_abs("."))
source("context.R")

# Temporary CSV file used as a stand-in for a valid input file.
.tmp_csv <- tempfile(fileext = ".csv")
writeLines("col1,col2\n1,2", .tmp_csv)
on.exit(unlink(.tmp_csv), add = TRUE)

# ---------------------------------------------------------------------------
# Result structure
# ---------------------------------------------------------------------------

test_that("result contains both key constants", {
  ctx <- get_context(.interactive = FALSE, .args = .tmp_csv)
  expect_true(input_file_arg %in% names(ctx))
  expect_true(output_dir_arg %in% names(ctx))
})

test_that("both result values are non-NULL", {
  ctx <- get_context(.interactive = FALSE, .args = .tmp_csv)
  expect_false(is.null(ctx[[input_file_arg]]))
  expect_false(is.null(ctx[[output_dir_arg]]))
})

# ---------------------------------------------------------------------------
# Headless path
# ---------------------------------------------------------------------------

test_that("headless: input file is resolved to absolute path", {
  ctx <- get_context(.interactive = FALSE, .args = .tmp_csv)
  expect_true(fs::is_absolute_path(ctx[[input_file_arg]]))
  expect_equal(ctx[[input_file_arg]], as.character(fs::path_abs(.tmp_csv)))
})

test_that("headless: default output dir is timestamped under output parent", {
  ctx <- get_context(.interactive = FALSE, .args = .tmp_csv)
  expect_true(fs::is_absolute_path(ctx[[output_dir_arg]]))
  expect_match(basename(ctx[[output_dir_arg]]), "^analysis-\\d{8}-\\d{6}$")
  expect_equal(dirname(ctx[[output_dir_arg]]), .normalized_default_output_parent)
})

test_that("headless: -o sets explicit output dir", {
  tmp_dir <- as.character(fs::path_abs(tempdir()))
  ctx <- get_context(.interactive = FALSE, .args = c(.tmp_csv, "-o", tmp_dir))
  expect_equal(ctx[[output_dir_arg]], tmp_dir)
})

test_that("headless: -o before input file works", {
  tmp_dir <- as.character(fs::path_abs(tempdir()))
  ctx <- get_context(.interactive = FALSE, .args = c("-o", tmp_dir, .tmp_csv))
  expect_equal(ctx[[input_file_arg]], as.character(fs::path_abs(.tmp_csv)))
  expect_equal(ctx[[output_dir_arg]], tmp_dir)
})

test_that("headless: -o output dir is resolved to absolute path", {
  ctx <- get_context(.interactive = FALSE, .args = c(.tmp_csv, "-o", "."))
  expect_true(fs::is_absolute_path(ctx[[output_dir_arg]]))
})

test_that("headless: -o with no following value errors", {
  expect_error(
    get_context(.interactive = FALSE, .args = c(.tmp_csv, "-o")),
    "-o flag requires a directory argument\\."
  )
})

test_that("headless: -o as only arg errors (no input file)", {
  # After stripping -o and its value, args is empty — exits via quit().
  # We can't intercept quit() in unit tests; exercise the -o-only error instead.
  expect_error(
    get_context(.interactive = FALSE, .args = c("-o")),
    "-o flag requires a directory argument\\."
  )
})

test_that("headless: non-existent input file errors", {
  expect_error(
    get_context(.interactive = FALSE, .args = "/nonexistent/path/file.csv"),
    "Input CSV file not found: /nonexistent/path/file.csv"
  )
})

test_that("headless: relative input file path resolves to absolute", {
  # Write a temp file relative to cwd.
  rel_path <- "test-input-temp.csv"
  writeLines("a,b\n1,2", rel_path)
  on.exit(unlink(rel_path), add = TRUE)
  ctx <- get_context(.interactive = FALSE, .args = rel_path)
  expect_true(fs::is_absolute_path(ctx[[input_file_arg]]))
  expect_equal(ctx[[input_file_arg]], as.character(fs::path_abs(rel_path)))
})

# ---------------------------------------------------------------------------
# Interactive path
# ---------------------------------------------------------------------------

test_that("interactive: uses .normalized_default_input_file when it exists", {
  old <- .normalized_default_input_file
  .normalized_default_input_file <<- .tmp_csv
  on.exit(.normalized_default_input_file <<- old, add = TRUE)

  ctx <- get_context(.interactive = TRUE, .args = character(0))
  expect_equal(ctx[[input_file_arg]], as.character(fs::path_abs(.tmp_csv)))
})

test_that("interactive: output dir is timestamped under output parent", {
  old <- .normalized_default_input_file
  .normalized_default_input_file <<- .tmp_csv
  on.exit(.normalized_default_input_file <<- old, add = TRUE)

  ctx <- get_context(.interactive = TRUE, .args = character(0))
  expect_match(basename(ctx[[output_dir_arg]]), "^analysis-\\d{8}-\\d{6}$")
  expect_equal(dirname(ctx[[output_dir_arg]]), .normalized_default_output_parent)
})

test_that("interactive: output dir is absolute path", {
  old <- .normalized_default_input_file
  .normalized_default_input_file <<- .tmp_csv
  on.exit(.normalized_default_input_file <<- old, add = TRUE)

  ctx <- get_context(.interactive = TRUE, .args = character(0))
  expect_true(fs::is_absolute_path(ctx[[output_dir_arg]]))
})

test_that("interactive: non-existent default input file errors", {
  old <- .normalized_default_input_file
  .normalized_default_input_file <<- "/nonexistent/path/file.csv"
  on.exit(.normalized_default_input_file <<- old, add = TRUE)

  expect_error(
    get_context(.interactive = TRUE, .args = character(0)),
    "Input CSV file not found:"
  )
})

test_that("interactive: ignores .args (uses defaults regardless)", {
  old <- .normalized_default_input_file
  .normalized_default_input_file <<- .tmp_csv
  on.exit(.normalized_default_input_file <<- old, add = TRUE)

  # Even if args contain a different file, interactive path ignores them.
  ctx_no_args   <- get_context(.interactive = TRUE, .args = character(0))
  ctx_with_args <- get_context(.interactive = TRUE, .args = c("/some/other/file.csv"))
  expect_equal(ctx_no_args[[input_file_arg]], ctx_with_args[[input_file_arg]])
})

# ---------------------------------------------------------------------------
# Normalization
# ---------------------------------------------------------------------------

test_that("output_dir_arg constant value is 'output_dir' (not redundant var name)", {
  expect_equal(output_dir_arg, "output_dir")
})

test_that("input_file_arg constant value is 'input_file'", {
  expect_equal(input_file_arg, "input_file")
})

cat("All tests passed.\n")
