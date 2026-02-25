#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
config_path <- if (length(args) >= 1) args[[1]] else "_pkgdown.yml"
config_path <- normalizePath(config_path, winslash = "/", mustWork = FALSE)

state <- new.env(parent = emptyenv())
state$error <- 0L
state$warn <- 0L

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

emit <- function(level, message) {
  cat(sprintf("[%s] %s\n", level, message))
}

ok <- function(message) emit("OK", message)
warn <- function(message) {
  state$warn <- state$warn + 1L
  emit("WARN", message)
}
error_msg <- function(message) {
  state$error <- state$error + 1L
  emit("ERROR", message)
}

is_non_empty_scalar <- function(x) {
  !is.null(x) && length(x) >= 1 && nzchar(trimws(as.character(x[[1]])))
}

cat("pkgdown config validation\n")
cat(sprintf("Config path: %s\n\n", config_path))

if (!file.exists(config_path)) {
  error_msg("Configuration file does not exist.")
  quit(status = 1L)
}

if (!requireNamespace("yaml", quietly = TRUE)) {
  error_msg("Package 'yaml' is required. Install it with install.packages('yaml').")
  quit(status = 2L)
}

config <- tryCatch(yaml::read_yaml(config_path), error = function(e) e)
if (inherits(config, "error")) {
  error_msg(sprintf("YAML parse error: %s", config$message))
  quit(status = 1L)
}

if (!is.list(config)) {
  error_msg("Parsed configuration is not a list.")
  quit(status = 1L)
}

ok("YAML parsed successfully.")

if (is_non_empty_scalar(config$url)) {
  if (grepl("^https?://", config$url)) {
    ok("url is present and looks valid.")
  } else {
    warn("url is present but does not start with http:// or https://.")
  }
} else {
  warn("url is missing or empty.")
}

if (is.null(config$template)) {
  warn("template section is missing.")
} else if (is.list(config$template)) {
  ok("template section found.")
} else {
  error_msg("template section must be a YAML object.")
}

if (is.null(config$navbar)) {
  warn("navbar section is missing.")
} else if (!is.list(config$navbar)) {
  error_msg("navbar must be a YAML object.")
} else {
  ok("navbar section found.")
  navbar_structure <- config$navbar$structure %||% list()
  left_items <- unlist(navbar_structure$left %||% character(), use.names = FALSE)
  right_items <- unlist(navbar_structure$right %||% character(), use.names = FALSE)
  all_structure_items <- unique(c(left_items, right_items))

  if (length(all_structure_items) == 0L) {
    warn("navbar.structure has no left or right items.")
  } else {
    ok("navbar.structure has entries.")
  }

  components <- names(config$navbar$components %||% list())
  built_in <- c("home", "reference", "articles", "news", "tutorials", "search")
  unknown_items <- setdiff(all_structure_items, c(built_in, components))
  if (length(unknown_items) > 0L) {
    warn(sprintf(
      "Unknown navbar structure items: %s",
      paste(unknown_items, collapse = ", ")
    ))
  }
}

if (!is.null(config$articles)) {
  if (!is.list(config$articles)) {
    error_msg("articles must be a list of article groups.")
  } else {
    ok("articles section found.")
    for (i in seq_along(config$articles)) {
      entry <- config$articles[[i]]
      if (!is.list(entry)) {
        error_msg(sprintf("articles entry %d is not a YAML object.", i))
        next
      }
      has_title <- is_non_empty_scalar(entry$title)
      has_contents <- !is.null(entry$contents)
      if (!has_title) {
        warn(sprintf("articles entry %d has no title.", i))
      }
      if (!has_contents) {
        warn(sprintf("articles entry %d has no contents.", i))
      }
    }
  }
}

cat("\nSummary\n")
cat(sprintf("- Errors: %d\n", state$error))
cat(sprintf("- Warnings: %d\n", state$warn))

if (state$error > 0L) {
  cat("\nResult: INVALID CONFIG\n")
  quit(status = 1L)
}

if (state$warn > 0L) {
  cat("\nResult: VALID WITH WARNINGS\n")
} else {
  cat("\nResult: VALID\n")
}
