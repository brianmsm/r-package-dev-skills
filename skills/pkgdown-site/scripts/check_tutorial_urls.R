#!/usr/bin/env Rscript

# check_tutorial_urls.R
#
# Purpose:
#   Validate the `tutorials:` section in `_pkgdown.yml` and probe configured URLs.
#   This is useful when pkgdown tutorials are embedded from externally hosted apps.
#
# Usage:
#   Rscript scripts/check_tutorial_urls.R
#   Rscript scripts/check_tutorial_urls.R _pkgdown.yml
#   Rscript scripts/check_tutorial_urls.R _pkgdown.yml --timeout=20
#
# Exit codes:
#   0: OK (or no tutorials configured)
#   1: FAILED (invalid tutorials config or URL probe failures)

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

as_num <- function(x, arg_name) {
  value <- suppressWarnings(as.numeric(x))
  if (!is.finite(value) || value <= 0) {
    stop(sprintf("Invalid numeric value for %s: %s", arg_name, x), call. = FALSE)
  }
  value
}

is_flag <- function(x) {
  is.character(x) && length(x) == 1 && grepl("^--|^-", x)
}

msg <- function(..., quiet = FALSE) {
  if (!quiet) cat(..., "\n", sep = "")
}

help_text <- function() {
  paste0(
    "\ncheck_tutorial_urls.R\n",
    "\nValidate `_pkgdown.yml` tutorials entries and probe tutorial URLs.\n",
    "\nUsage:\n",
    "  Rscript scripts/check_tutorial_urls.R\n",
    "  Rscript scripts/check_tutorial_urls.R _pkgdown.yml\n",
    "  Rscript scripts/check_tutorial_urls.R _pkgdown.yml --timeout=20\n",
    "\nOptions:\n",
    "  --timeout=SECONDS   Request timeout per tutorial URL (default: 15)\n",
    "  -q, --quiet         Reduce verbosity\n",
    "  -h, --help          Show this help\n\n"
  )
}

parse_args <- function(args) {
  out <- list(
    cfg_path = "_pkgdown.yml",
    timeout = 15,
    quiet = FALSE
  )

  if (length(args) >= 1 && !is_flag(args[1])) {
    out$cfg_path <- args[1]
    args <- args[-1]
  }

  i <- 1
  while (i <= length(args)) {
    a <- args[i]

    if (a %in% c("-q", "--quiet")) {
      out$quiet <- TRUE
      i <- i + 1
      next
    }
    if (a %in% c("-h", "--help")) {
      cat(help_text())
      quit(status = 0)
    }
    if (grepl("^--timeout=", a)) {
      out$timeout <- as_num(sub("^--timeout=", "", a), "--timeout")
      i <- i + 1
      next
    }
    if (a == "--timeout") {
      if (i == length(args)) stop("Missing value for --timeout", call. = FALSE)
      out$timeout <- as_num(args[i + 1], "--timeout")
      i <- i + 2
      next
    }

    stop(sprintf("Unknown argument: %s (use --help)", a), call. = FALSE)
  }

  out
}

as_scalar_text <- function(x) {
  if (is.null(x) || length(x) == 0) return("")
  value <- as.character(x[[1]])
  trimws(value)
}

is_http_url <- function(x) {
  grepl("^https?://", x, ignore.case = TRUE)
}

validate_tutorial_entries <- function(tutorials) {
  problems <- character()
  entries <- list()

  if (!is.list(tutorials)) {
    problems <- c(problems, "`tutorials:` must be a YAML list.")
    return(list(problems = problems, entries = entries))
  }

  if (length(tutorials) == 0) {
    problems <- c(problems, "`tutorials:` is present but empty.")
    return(list(problems = problems, entries = entries))
  }

  for (i in seq_along(tutorials)) {
    item <- tutorials[[i]]
    if (!is.list(item)) {
      problems <- c(problems, sprintf("tutorials[%d] is not a mapping/list entry.", i))
      next
    }

    name <- as_scalar_text(item$name)
    title <- as_scalar_text(item$title)
    url <- as_scalar_text(item$url)
    source <- as_scalar_text(item$source)

    if (!nzchar(name)) {
      problems <- c(problems, sprintf("tutorials[%d] missing required `name`.", i))
    }
    if (!nzchar(title)) {
      problems <- c(problems, sprintf("tutorials[%d] missing required `title`.", i))
    }
    if (!nzchar(url)) {
      problems <- c(problems, sprintf("tutorials[%d] missing required `url`.", i))
    } else if (!is_http_url(url)) {
      problems <- c(problems, sprintf("tutorials[%d] has non-http(s) URL: %s", i, url))
    }
    if (nzchar(source) && !is_http_url(source)) {
      problems <- c(problems, sprintf("tutorials[%d] `source` is not http(s): %s", i, source))
    }

    entries[[length(entries) + 1]] <- list(
      index = i,
      name = name,
      title = title,
      url = url,
      source = source
    )
  }

  list(problems = problems, entries = entries)
}

probe_url <- function(url, timeout) {
  req <- httr2::request(url)
  req <- httr2::req_timeout(req, timeout)
  req <- httr2::req_user_agent(req, "pkgdown-tutorial-check/1.0")

  resp <- tryCatch(
    httr2::req_perform(req, error_on_status = FALSE),
    error = function(e) e
  )

  if (inherits(resp, "error")) {
    return(list(ok = FALSE, status = NA_integer_, final_url = NA_character_, error = conditionMessage(resp)))
  }

  status <- httr2::resp_status(resp)
  final_url <- tryCatch(as.character(httr2::resp_url(resp)), error = function(e) NA_character_)
  ok <- isTRUE(status >= 200 && status < 400)

  list(ok = ok, status = status, final_url = final_url, error = "")
}

main <- function() {
  require_pkg("yaml")
  require_pkg("httr2")

  opts <- parse_args(commandArgs(trailingOnly = TRUE))
  cfg_path <- normalizePath(opts$cfg_path, winslash = "/", mustWork = FALSE)

  if (!file.exists(cfg_path)) {
    stop(sprintf("Config file not found: %s", opts$cfg_path), call. = FALSE)
  }

  cfg <- tryCatch(
    yaml::read_yaml(cfg_path),
    error = function(e) {
      stop(sprintf("YAML parse error in %s: %s", opts$cfg_path, conditionMessage(e)), call. = FALSE)
    }
  )

  tutorials <- cfg$tutorials
  msg("\n== Tutorial URL check ==", quiet = opts$quiet)
  msg("Config: ", cfg_path, quiet = opts$quiet)
  msg("", quiet = opts$quiet)

  if (is.null(tutorials)) {
    msg("No `tutorials:` section found. Skipping URL checks.", quiet = opts$quiet)
    cat("Result: OK\n")
    quit(status = 0)
  }

  validated <- validate_tutorial_entries(tutorials)
  if (length(validated$problems) > 0) {
    cat("Config errors:\n")
    for (p in validated$problems) cat("  - ", p, "\n", sep = "")
    cat("\nResult: FAILED\n")
    quit(status = 1)
  }

  failed <- character()
  warnings <- character()

  for (entry in validated$entries) {
    result <- probe_url(entry$url, timeout = opts$timeout)
    label <- sprintf("%s (%s)", entry$title, entry$url)

    if (!result$ok) {
      if (nzchar(result$error)) {
        failed <- c(failed, sprintf("%s -> request error: %s", label, result$error))
      } else {
        failed <- c(failed, sprintf("%s -> HTTP %s", label, result$status))
      }
      next
    }

    msg(sprintf("OK: %s -> HTTP %s", label, result$status), quiet = opts$quiet)

    if (!is.na(result$final_url) && nzchar(result$final_url) && !identical(result$final_url, entry$url)) {
      warnings <- c(warnings, sprintf("%s redirects to %s", label, result$final_url))
    }
  }

  if (length(warnings) > 0) {
    cat("\nWarnings:\n")
    for (w in warnings) cat("  - ", w, "\n", sep = "")
  }

  if (length(failed) > 0) {
    cat("\nFailures:\n")
    for (f in failed) cat("  - ", f, "\n", sep = "")
    cat("\nResult: FAILED\n")
    quit(status = 1)
  }

  cat("\nResult: OK\n")
  quit(status = 0)
}

if (identical(environment(), globalenv())) {
  main()
}
