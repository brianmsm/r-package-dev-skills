#!/usr/bin/env Rscript

# setup_favicons.R
#
# Purpose:
#   Generate pkgdown favicons from a package logo using pkgdown::build_favicons().
#   This creates `pkgdown/favicon/` resources consumed during site builds.
#
# Usage:
#   Rscript scripts/setup_favicons.R
#   Rscript scripts/setup_favicons.R /path/to/package
#   Rscript scripts/setup_favicons.R /path/to/package --overwrite
#   Rscript scripts/setup_favicons.R --no-rbuildignore
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
    "\nsetup_favicons.R\n",
    "\nGenerate pkgdown favicons from a package logo.\n",
    "\nUsage:\n",
    "  Rscript scripts/setup_favicons.R\n",
    "  Rscript scripts/setup_favicons.R /path/to/package\n",
    "  Rscript scripts/setup_favicons.R /path/to/package --overwrite\n",
    "\nOptions:\n",
    "  --overwrite        Recreate favicons even if pkgdown/favicon already exists\n",
    "  --no-rbuildignore  Do not update .Rbuildignore\n",
    "  -q, --quiet        Reduce verbosity\n",
    "  -h, --help         Show this help\n\n"
  )
}

parse_args <- function(args) {
  out <- list(
    root = ".",
    overwrite = FALSE,
    update_rbuildignore = TRUE,
    quiet = FALSE
  )

  if (length(args) >= 1 && !is_flag(args[1])) {
    out$root <- args[1]
    args <- args[-1]
  }

  i <- 1
  while (i <= length(args)) {
    a <- args[i]

    if (a == "--overwrite") {
      out$overwrite <- TRUE
      i <- i + 1
      next
    }
    if (a == "--no-rbuildignore") {
      out$update_rbuildignore <- FALSE
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

find_logo_candidates <- function(root) {
  candidates <- c(
    file.path(root, "logo.svg"),
    file.path(root, "logo.png"),
    file.path(root, "man", "figures", "logo.svg"),
    file.path(root, "man", "figures", "logo.png")
  )

  candidates[file.exists(candidates)]
}

append_unique_lines <- function(path, lines) {
  existing <- character()
  if (file.exists(path)) {
    existing <- readLines(path, warn = FALSE, encoding = "UTF-8")
  }
  existing <- existing[!is.na(existing)]

  to_add <- setdiff(lines, existing)
  if (length(to_add) == 0) return(FALSE)

  writeLines(c(existing, to_add), con = path, useBytes = TRUE)
  TRUE
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

  msg("\n== Setup pkgdown favicons ==", quiet = opts$quiet)
  msg("Root: ", root, quiet = opts$quiet)

  logos <- find_logo_candidates(root)
  if (length(logos) == 0) {
    msg("\nNo logo candidate detected.", quiet = opts$quiet)
    msg("Expected one of:", quiet = opts$quiet)
    msg("  - ./logo.svg or ./logo.png", quiet = opts$quiet)
    msg("  - ./man/figures/logo.svg or ./man/figures/logo.png", quiet = opts$quiet)
    msg("\nTip: you can place a logo with usethis::use_logo().", quiet = opts$quiet)
    quit(status = 1)
  }

  msg("Detected logo candidate(s):", quiet = opts$quiet)
  for (p in logos) msg("  - ", p, quiet = opts$quiet)

  fav_dir <- file.path(root, "pkgdown", "favicon")
  if (dir.exists(fav_dir) && !isTRUE(opts$overwrite)) {
    msg("\nExisting favicon directory found: ", fav_dir, quiet = opts$quiet)
    msg("Will call build_favicons() with overwrite = FALSE (may fail if files already exist).", quiet = opts$quiet)
    msg("Use --overwrite to force regeneration.", quiet = opts$quiet)
  }

  msg("\n-> Running pkgdown::build_favicons() ...", quiet = opts$quiet)
  ok <- TRUE

  tryCatch(
    {
      pkgdown::build_favicons(pkg = root, overwrite = isTRUE(opts$overwrite))
    },
    error = function(e) {
      ok <<- FALSE
      cat("\nERROR: build_favicons() failed.\n", sep = "")
      cat("Reason: ", conditionMessage(e), "\n", sep = "")
      cat("\nNotes:\n", sep = "")
      cat("  - This step requires internet access.\n", sep = "")
      cat("  - If `pkgdown/favicon` already exists, retry with --overwrite.\n", sep = "")
    }
  )

  if (!ok) quit(status = 1)

  if (dir.exists(fav_dir)) {
    msg("Favicons generated at: ", fav_dir, quiet = opts$quiet)
  } else {
    msg("Warning: expected directory not found after build: ", fav_dir, quiet = opts$quiet)
  }

  if (isTRUE(opts$update_rbuildignore)) {
    rb_path <- file.path(root, ".Rbuildignore")
    changed <- append_unique_lines(rb_path, "^pkgdown$")
    if (changed) {
      msg("Updated .Rbuildignore (added): ^pkgdown$", quiet = opts$quiet)
    } else {
      msg(".Rbuildignore already contains: ^pkgdown$", quiet = opts$quiet)
    }
  } else {
    msg("Skipped .Rbuildignore update (--no-rbuildignore).", quiet = opts$quiet)
  }

  msg("\nNext steps:", quiet = opts$quiet)
  msg("  1) Rebuild the site to include favicon assets.", quiet = opts$quiet)
  msg("     - Local: pkgdown::build_site()", quiet = opts$quiet)
  msg("     - CI:    pkgdown::build_site_github_pages()", quiet = opts$quiet)
  msg("\nResult: OK", quiet = opts$quiet)
}

if (identical(environment(), globalenv())) {
  main()
}
