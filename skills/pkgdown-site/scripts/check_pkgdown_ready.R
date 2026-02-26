#!/usr/bin/env Rscript

# check_pkgdown_ready.R
#
# Purpose:
#   Quick readiness check for setting up a pkgdown website in an R package repo.
#   This script does not modify files; it reports findings and recommended next steps.
#
# Usage:
#   Rscript scripts/check_pkgdown_ready.R
#   Rscript scripts/check_pkgdown_ready.R /path/to/package/root
#   Rscript scripts/check_pkgdown_ready.R --help
#
# Exit codes:
#   0: Ready enough (may include recommendations)
#   1: Not ready (critical issues found)

require_pkg <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(
      sprintf(
        "Missing dependency '%s'. Install it with: install.packages('%s')",
        pkg, pkg
      ),
      call. = FALSE
    )
  }
}

print_usage <- function() {
  cat("Usage:\n")
  cat("  Rscript scripts/check_pkgdown_ready.R\n")
  cat("  Rscript scripts/check_pkgdown_ready.R /path/to/package/root\n")
}

exists_any <- function(paths) any(file.exists(paths))

fmt_bool <- function(x) if (isTRUE(x)) "YES" else "NO"

is_non_empty_text <- function(x) {
  if (is.null(x) || length(x) == 0) return(FALSE)
  value <- trimws(as.character(x[[1]]))
  if (is.na(value)) return(FALSE)
  if (!nzchar(value, keepNA = TRUE)) return(FALSE)
  if (toupper(value) %in% c("NA", "NULL")) return(FALSE)
  TRUE
}

read_desc_fields <- function(desc_path) {
  require_pkg("desc")
  d <- desc::desc(file = desc_path)
  list(
    package = d$get("Package"),
    version = d$get("Version"),
    title   = d$get("Title"),
    url     = d$get("URL"),
    bugrep  = d$get("BugReports")
  )
}

list_vignette_sources <- function(vignettes_dir) {
  if (!dir.exists(vignettes_dir)) return(character())
  files <- list.files(vignettes_dir, recursive = TRUE, full.names = TRUE)
  exts <- c("rmd", "qmd", "md")
  files[tolower(tools::file_ext(files)) %in% exts]
}

main <- function() {
  args <- commandArgs(trailingOnly = TRUE)

  if (length(args) > 0 && args[[1]] %in% c("-h", "--help")) {
    print_usage()
    quit(status = 0)
  }

  root <- if (length(args) >= 1 && nzchar(args[1])) args[1] else "."
  root <- normalizePath(root, winslash = "/", mustWork = FALSE)

  cat("\n== pkgdown readiness check ==\n")
  cat("Root:", root, "\n\n")

  desc_path <- file.path(root, "DESCRIPTION")
  ns_path   <- file.path(root, "NAMESPACE")
  r_dir     <- file.path(root, "R")

  critical_issues <- character()
  recommendations <- character()

  if (!file.exists(desc_path)) {
    critical_issues <- c(critical_issues, "Missing DESCRIPTION. Run this script from the root of an R package.")
  }
  if (!file.exists(ns_path)) {
    recommendations <- c(recommendations, "NAMESPACE not found. If you use roxygen2, generate it with devtools::document().")
  }
  if (!dir.exists(r_dir)) {
    recommendations <- c(recommendations, "R/ directory not found. Most packages have R/ with exported functions.")
  }

  home_candidates <- c(
    file.path(root, "pkgdown", "index.md"),
    file.path(root, "index.md"),
    file.path(root, "README.md")
  )
  has_home <- exists_any(home_candidates)

  pkgdown_yml <- file.path(root, "_pkgdown.yml")
  has_pkgdown_yml <- file.exists(pkgdown_yml)

  gha_pkgdown <- file.path(root, ".github", "workflows", "pkgdown.yaml")
  gha_pkgdown_yml <- file.path(root, ".github", "workflows", "pkgdown.yml")
  has_workflow <- exists_any(c(gha_pkgdown, gha_pkgdown_yml))

  vignettes_dir <- file.path(root, "vignettes")
  vign_sources  <- list_vignette_sources(vignettes_dir)

  news_candidates <- c(file.path(root, "NEWS.md"), file.path(root, "NEWS"))
  has_news <- exists_any(news_candidates)

  if (file.exists(desc_path)) {
    pkg_info <- tryCatch(read_desc_fields(desc_path), error = function(e) NULL)
    if (!is.null(pkg_info)) {
      cat("Package: ", pkg_info$package, "\n", sep = "")
      cat("Version: ", pkg_info$version, "\n", sep = "")
      if (is_non_empty_text(pkg_info$title)) {
        cat("Title: ", pkg_info$title, "\n", sep = "")
      }
      if (is_non_empty_text(pkg_info$url)) {
        cat("DESCRIPTION URL: ", pkg_info$url, "\n", sep = "")
      } else {
        recommendations <- c(recommendations, "DESCRIPTION has no URL field. Consider adding the pkgdown site URL once published.")
      }
      if (is_non_empty_text(pkg_info$bugrep)) {
        cat("BugReports: ", pkg_info$bugrep, "\n", sep = "")
      } else {
        recommendations <- c(recommendations, "DESCRIPTION has no BugReports field. Consider adding your GitHub issues URL.")
      }
      cat("\n")
    } else {
      recommendations <- c(recommendations, "Could not read DESCRIPTION with 'desc'. Install 'desc' for richer checks.")
    }
  }

  cat("Found:\n")
  cat("  DESCRIPTION:           ", fmt_bool(file.exists(desc_path)), "\n", sep = "")
  cat("  NAMESPACE:             ", fmt_bool(file.exists(ns_path)), "\n", sep = "")
  cat("  R/ directory:          ", fmt_bool(dir.exists(r_dir)), "\n", sep = "")
  cat("  _pkgdown.yml:          ", fmt_bool(has_pkgdown_yml), "\n", sep = "")
  cat("  pkgdown workflow:      ", fmt_bool(has_workflow), "\n", sep = "")
  cat("  Home source (index/README): ", fmt_bool(has_home), "\n", sep = "")
  cat("  vignettes/ exists:     ", fmt_bool(dir.exists(vignettes_dir)), "\n", sep = "")
  cat("  vignette/article files:", length(vign_sources), "\n", sep = "")
  cat("  NEWS:                  ", fmt_bool(has_news), "\n", sep = "")
  cat("\n")

  if (!has_home) {
    recommendations <- c(
      recommendations,
      "No site home source found (pkgdown/index.md, index.md, or README.md). Create index.md to control the pkgdown home page."
    )
  } else if (file.exists(file.path(root, "README.md")) &&
             !file.exists(file.path(root, "index.md")) &&
             !file.exists(file.path(root, "pkgdown", "index.md"))) {
    recommendations <- c(
      recommendations,
      "README.md exists but index.md does not. Consider adding index.md for a richer website landing page while keeping README lean."
    )
  }

  if (!has_pkgdown_yml) {
    recommendations <- c(
      recommendations,
      "No _pkgdown.yml found. Consider running usethis::use_pkgdown() or starting from a minimal _pkgdown.yml template."
    )
  }

  if (!has_workflow) {
    recommendations <- c(
      recommendations,
      "No pkgdown GitHub Actions workflow found. Consider running usethis::use_pkgdown_github_pages() to set up GitHub Pages publishing."
    )
  }

  if (dir.exists(vignettes_dir) && length(vign_sources) == 0) {
    recommendations <- c(
      recommendations,
      "vignettes/ exists but contains no .Rmd/.qmd/.md files. If you want Articles, create website-only articles with usethis::use_article()."
    )
  }

  if (!has_news) {
    recommendations <- c(
      recommendations,
      "No NEWS.md found. Consider adding NEWS.md for release notes (optional but recommended if you publish releases)."
    )
  }

  if (length(critical_issues) > 0) {
    cat("Critical issues:\n")
    for (x in unique(critical_issues)) cat("  - ", x, "\n", sep = "")
    cat("\n")
  }

  if (length(recommendations) > 0) {
    cat("Recommendations:\n")
    for (x in unique(recommendations)) cat("  - ", x, "\n", sep = "")
    cat("\n")
  } else {
    cat("No recommendations. Repo looks ready.\n\n")
  }

  if (length(critical_issues) > 0) {
    cat("Result: NOT READY (critical issues found)\n")
    quit(status = 1)
  }

  cat("Result: READY ENOUGH\n")
  quit(status = 0)
}

if (identical(environment(), globalenv())) {
  main()
}
