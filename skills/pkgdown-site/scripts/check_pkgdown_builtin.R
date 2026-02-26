#!/usr/bin/env Rscript

# check_pkgdown_builtin.R
#
# Purpose:
#   Run pkgdown's built-in diagnostics (`check_pkgdown()` and `pkgdown_sitrep()`).
#   This provides validation based on pkgdown's own internal rules.
#
# Usage:
#   Rscript scripts/check_pkgdown_builtin.R
#   Rscript scripts/check_pkgdown_builtin.R /path/to/package/root
#   Rscript scripts/check_pkgdown_builtin.R --sitrep-only
#   Rscript scripts/check_pkgdown_builtin.R --check-only
#
# Exit codes:
#   0: OK
#   1: FAILED

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
    "\ncheck_pkgdown_builtin.R\n",
    "\nRun pkgdown's built-in diagnostics (check_pkgdown and pkgdown_sitrep).\n",
    "\nUsage:\n",
    "  Rscript scripts/check_pkgdown_builtin.R\n",
    "  Rscript scripts/check_pkgdown_builtin.R /path/to/package/root\n",
    "  Rscript scripts/check_pkgdown_builtin.R --sitrep-only\n",
    "  Rscript scripts/check_pkgdown_builtin.R --check-only\n",
    "\nOptions:\n",
    "  --sitrep-only   Only run pkgdown_sitrep()\n",
    "  --check-only    Only run check_pkgdown()\n",
    "  -q, --quiet     Reduce verbosity\n",
    "  -h, --help      Show this help\n\n"
  )
}

parse_args <- function(args) {
  out <- list(
    root = ".",
    sitrep_only = FALSE,
    check_only = FALSE,
    quiet = FALSE
  )

  if (length(args) >= 1 && !is_flag(args[1])) {
    out$root <- args[1]
    args <- args[-1]
  }

  i <- 1
  while (i <= length(args)) {
    a <- args[i]

    if (a == "--sitrep-only") {
      out$sitrep_only <- TRUE
      i <- i + 1
      next
    }
    if (a == "--check-only") {
      out$check_only <- TRUE
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

  if (isTRUE(out$sitrep_only) && isTRUE(out$check_only)) {
    stop("Choose only one: --sitrep-only OR --check-only", call. = FALSE)
  }

  out
}

call_pkgdown <- function(fun, root) {
  ns <- asNamespace("pkgdown")
  if (!exists(fun, envir = ns, inherits = FALSE)) {
    stop(
      sprintf(
        "pkgdown::%s() is not available in this pkgdown version (%s). Update pkgdown.",
        fun,
        as.character(utils::packageVersion("pkgdown"))
      ),
      call. = FALSE
    )
  }

  fn <- get(fun, envir = ns, inherits = FALSE)
  fn_args <- names(formals(fn))

  # Prefer explicit pkg argument when available; otherwise call in target wd.
  if ("pkg" %in% fn_args) {
    fn(pkg = root)
  } else {
    old <- getwd()
    on.exit(setwd(old), add = TRUE)
    setwd(root)
    fn()
  }
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

  msg("\n== pkgdown built-in diagnostics ==", quiet = opts$quiet)
  msg("Root: ", root, quiet = opts$quiet)
  msg("", quiet = opts$quiet)

  failed <- FALSE

  if (!isTRUE(opts$check_only)) {
    msg("-> Running pkgdown::pkgdown_sitrep() ...\n", quiet = opts$quiet)
    tryCatch(
      {
        call_pkgdown("pkgdown_sitrep", root)
      },
      error = function(e) {
        failed <<- TRUE
        cat("\nERROR in pkgdown_sitrep(): ", conditionMessage(e), "\n", sep = "")
      }
    )
    msg("", quiet = opts$quiet)
  }

  if (!isTRUE(opts$sitrep_only)) {
    msg("-> Running pkgdown::check_pkgdown() ...\n", quiet = opts$quiet)
    tryCatch(
      {
        call_pkgdown("check_pkgdown", root)
      },
      error = function(e) {
        failed <<- TRUE
        cat("\nERROR in check_pkgdown(): ", conditionMessage(e), "\n", sep = "")
      }
    )
    msg("", quiet = opts$quiet)
  }

  if (failed) {
    cat("Result: FAILED\n")
    quit(status = 1)
  }

  cat("Result: OK\n")
  quit(status = 0)
}

if (identical(environment(), globalenv())) {
  main()
}
