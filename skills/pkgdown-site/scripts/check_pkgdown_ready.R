#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
package_path <- if (length(args) >= 1) args[[1]] else "."
package_path <- normalizePath(package_path, winslash = "/", mustWork = FALSE)

state <- new.env(parent = emptyenv())
state$fail <- 0L
state$warn <- 0L

emit <- function(level, message) {
  cat(sprintf("[%s] %s\n", level, message))
}

ok <- function(message) emit("OK", message)
info <- function(message) emit("INFO", message)
warn <- function(message) {
  state$warn <- state$warn + 1L
  emit("WARN", message)
}
fail <- function(message) {
  state$fail <- state$fail + 1L
  emit("FAIL", message)
}

cat("pkgdown readiness check\n")
cat(sprintf("Package path: %s\n\n", package_path))

if (!dir.exists(package_path)) {
  fail("Target directory does not exist.")
  quit(status = 1L)
}

desc_path <- file.path(package_path, "DESCRIPTION")
namespace_path <- file.path(package_path, "NAMESPACE")
readme_path <- file.path(package_path, "README.md")
pkgdown_path <- file.path(package_path, "_pkgdown.yml")
workflow_yaml <- file.path(package_path, ".github", "workflows", "pkgdown.yaml")
workflow_yml <- file.path(package_path, ".github", "workflows", "pkgdown.yml")
vignettes_path <- file.path(package_path, "vignettes")

if (file.exists(desc_path)) {
  ok("DESCRIPTION found.")
  desc <- tryCatch(read.dcf(desc_path), error = function(e) e)
  if (inherits(desc, "error")) {
    fail(sprintf("DESCRIPTION could not be parsed: %s", desc$message))
  } else {
    required_fields <- c("Package", "Version", "Title")
    present_fields <- colnames(desc)
    missing_fields <- setdiff(required_fields, present_fields)
    if (length(missing_fields) > 0) {
      fail(sprintf(
        "DESCRIPTION missing required fields: %s",
        paste(missing_fields, collapse = ", ")
      ))
    } else {
      ok("DESCRIPTION has required fields: Package, Version, Title.")
    }
  }
} else {
  fail("DESCRIPTION not found.")
}

if (file.exists(namespace_path)) {
  ok("NAMESPACE found.")
} else {
  warn("NAMESPACE not found. This may be generated later by roxygen2.")
}

if (file.exists(readme_path)) {
  ok("README.md found.")
} else {
  warn("README.md not found.")
}

if (file.exists(pkgdown_path)) {
  ok("_pkgdown.yml found.")
} else {
  warn("_pkgdown.yml not found.")
}

if (file.exists(workflow_yaml) || file.exists(workflow_yml)) {
  ok("pkgdown GitHub Actions workflow found.")
} else {
  warn("pkgdown workflow not found in .github/workflows/.")
}

if (dir.exists(vignettes_path)) {
  ok("vignettes/ directory found.")
} else {
  info("vignettes/ directory not found. This is optional.")
}

check_package <- function(pkg, required = FALSE) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    ok(sprintf("R package '%s' is installed.", pkg))
  } else if (required) {
    fail(sprintf("R package '%s' is required but not installed.", pkg))
  } else {
    warn(sprintf("R package '%s' is not installed.", pkg))
  }
}

check_package("pkgdown", required = TRUE)
check_package("usethis", required = FALSE)
check_package("yaml", required = FALSE)

cat("\nSummary\n")
cat(sprintf("- Failures: %d\n", state$fail))
cat(sprintf("- Warnings: %d\n", state$warn))

if (state$fail > 0L) {
  cat("\nResult: NOT READY\n")
  quit(status = 1L)
}

if (state$warn > 0L) {
  cat("\nResult: READY WITH WARNINGS\n")
} else {
  cat("\nResult: READY\n")
}
