#!/usr/bin/env Rscript

# clean_and_build.R
#
# Purpose:
#   Clean and rebuild a pkgdown site to remove stale/orphaned files after
#   renaming or moving articles, references, and routes.
#
# What it does:
#   1) pkgdown::clean_site()
#   2) pkgdown::build_site() or pkgdown::build_site_github_pages()
#
# Usage:
#   Rscript scripts/clean_and_build.R
#   Rscript scripts/clean_and_build.R /path/to/package/root
#   Rscript scripts/clean_and_build.R /path/to/package/root --preview
#   Rscript scripts/clean_and_build.R /path/to/package/root --github-pages
#
# Exit codes:
#   0: Success
#   1: Failed

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

is_flag <- function(x) {
  is.character(x) && length(x) == 1 && grepl("^--|^-", x)
}

msg <- function(..., quiet = FALSE) {
  if (!quiet) cat(..., "\n", sep = "")
}

help_text <- function() {
  paste0(
    "\nclean_and_build.R\n",
    "\nClean and rebuild a pkgdown website.\n",
    "\nUsage:\n",
    "  Rscript scripts/clean_and_build.R\n",
    "  Rscript scripts/clean_and_build.R /path/to/package/root\n",
    "  Rscript scripts/clean_and_build.R /path/to/package/root --preview\n",
    "  Rscript scripts/clean_and_build.R /path/to/package/root --github-pages\n",
    "\nOptions:\n",
    "  --preview        Preview the site after building\n",
    "  --github-pages   Build using build_site_github_pages() (CI-like output)\n",
    "  -q, --quiet      Reduce verbosity\n",
    "  -h, --help       Show this help\n\n"
  )
}

parse_args <- function(args) {
  out <- list(
    root = ".",
    preview = FALSE,
    github_pages = FALSE,
    quiet = FALSE
  )

  if (length(args) >= 1 && !is_flag(args[1])) {
    out$root <- args[1]
    args <- args[-1]
  }

  i <- 1
  while (i <= length(args)) {
    a <- args[i]

    if (a == "--preview") {
      out$preview <- TRUE
      i <- i + 1
      next
    }
    if (a == "--github-pages") {
      out$github_pages <- TRUE
      i <- i + 1
      next
    }
    if (a %in% c("-q", "--quiet")) {
      out$quiet <- TRUE
      i <- i + 1
      next
    }
    if (a %in% c("-h", "--help")) {
      cat(help_text())
      quit(status = 0)
    }

    stop(sprintf("Unknown argument: %s (use --help)", a), call. = FALSE)
  }

  out
}

main <- function() {
  opts <- parse_args(commandArgs(trailingOnly = TRUE))
  require_pkg("pkgdown")

  root <- normalizePath(opts$root, winslash = "/", mustWork = FALSE)
  if (!dir.exists(root)) {
    stop(sprintf("Directory not found: %s", root), call. = FALSE)
  }
  if (!file.exists(file.path(root, "DESCRIPTION"))) {
    stop("DESCRIPTION not found in target directory. Run from an R package root.", call. = FALSE)
  }

  mode <- if (isTRUE(opts$github_pages)) {
    "build_site_github_pages()"
  } else {
    "build_site()"
  }

  msg("\n== pkgdown clean + build ==", quiet = opts$quiet)
  msg("Root: ", root, quiet = opts$quiet)
  msg("Mode: ", mode, quiet = opts$quiet)
  msg("", quiet = opts$quiet)

  ok <- TRUE

  msg("-> Cleaning site (pkgdown::clean_site()) ...", quiet = opts$quiet)
  tryCatch(
    {
      pkgdown::clean_site(pkg = root, quiet = TRUE, force = TRUE)
    },
    error = function(e) {
      ok <<- FALSE
      cat("ERROR: clean_site() failed: ", conditionMessage(e), "\n", sep = "")
    }
  )
  if (!ok) quit(status = 1)

  msg("\n-> Building site ...", quiet = opts$quiet)
  tryCatch(
    {
      if (isTRUE(opts$github_pages)) {
        pkgdown::build_site_github_pages(
          pkg = root,
          new_process = FALSE,
          install = FALSE
        )
      } else {
        pkgdown::build_site(pkg = root)
      }
    },
    error = function(e) {
      ok <<- FALSE
      cat("ERROR: build failed: ", conditionMessage(e), "\n", sep = "")
    }
  )
  if (!ok) quit(status = 1)

  if (isTRUE(opts$preview)) {
    msg("\n-> Previewing site (pkgdown::preview_site()) ...", quiet = opts$quiet)
    tryCatch(
      {
        pkgdown::preview_site(pkg = root)
      },
      error = function(e) {
        cat("WARNING: preview_site() failed: ", conditionMessage(e), "\n", sep = "")
      }
    )
  }

  cat("\nResult: OK\n")
  quit(status = 0)
}

if (identical(environment(), globalenv())) {
  main()
}
