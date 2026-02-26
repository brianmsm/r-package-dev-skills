#!/usr/bin/env Rscript

# audit_readme_for_migration.R
#
# Purpose:
#   Audit README.md length and structure, then suggest what content to migrate
#   into pkgdown site home (index.md) and/or articles.
#
# Philosophy:
#   - Keep README as a quick start hub.
#   - Move long tutorials, module guides, FAQs, and roadmap/design notes out of README.
#
# Usage:
#   Rscript scripts/audit_readme_for_migration.R
#   Rscript scripts/audit_readme_for_migration.R path/to/README.md
#   Rscript scripts/audit_readme_for_migration.R --readme=README.md --output=report.md
#
# Exit codes:
#   0: Completed (report printed)
#   1: README not found or unreadable

defaults <- list(
  readme = "README.md",
  output = NA_character_,
  line_threshold_long = 150L,
  line_threshold_very_long = 250L,
  long_section_threshold = 80L,
  top_n = 5L
)

print_usage <- function() {
  cat("Usage:\n")
  cat("  Rscript scripts/audit_readme_for_migration.R\n")
  cat("  Rscript scripts/audit_readme_for_migration.R path/to/README.md\n")
  cat("  Rscript scripts/audit_readme_for_migration.R --readme=README.md --output=report.md\n")
  cat("Options:\n")
  cat("  --readme=PATH\n")
  cat("  --output=PATH\n")
  cat("  --line-threshold-long=INT\n")
  cat("  --line-threshold-very-long=INT\n")
  cat("  --long-section-threshold=INT\n")
  cat("  --top-n=INT\n")
  cat("Compatibility options:\n")
  cat("  --line-threshold=INT            (maps to --line-threshold-very-long)\n")
}

parse_args <- function(args) {
  opts <- defaults
  pos_seen <- FALSE
  long_set <- FALSE
  compat_line_threshold_set <- FALSE

  for (arg in args) {
    if (arg %in% c("-h", "--help")) {
      print_usage()
      quit(status = 0)
    } else if (grepl("^--readme=", arg)) {
      opts$readme <- sub("^--readme=", "", arg)
    } else if (grepl("^--output=", arg)) {
      opts$output <- sub("^--output=", "", arg)
    } else if (grepl("^--line-threshold-long=", arg)) {
      opts$line_threshold_long <- as.integer(sub("^--line-threshold-long=", "", arg))
      long_set <- TRUE
    } else if (grepl("^--line-threshold-very-long=", arg)) {
      opts$line_threshold_very_long <- as.integer(sub("^--line-threshold-very-long=", "", arg))
    } else if (grepl("^--line-threshold=", arg)) {
      opts$line_threshold_very_long <- as.integer(sub("^--line-threshold=", "", arg))
      compat_line_threshold_set <- TRUE
    } else if (grepl("^--long-section-threshold=", arg)) {
      opts$long_section_threshold <- as.integer(sub("^--long-section-threshold=", "", arg))
    } else if (grepl("^--top-n=", arg)) {
      opts$top_n <- as.integer(sub("^--top-n=", "", arg))
    } else if (!startsWith(arg, "--")) {
      if (pos_seen) {
        stop("Multiple positional paths provided. Pass only one README path.", call. = FALSE)
      }
      opts$readme <- arg
      pos_seen <- TRUE
    } else {
      stop(sprintf("Unknown argument: %s", arg), call. = FALSE)
    }
  }

  for (field in c("line_threshold_long", "line_threshold_very_long", "long_section_threshold", "top_n")) {
    value <- opts[[field]]
    if (is.na(value) || value <= 0L) {
      stop(sprintf("Invalid value for %s. Use a positive integer.", field), call. = FALSE)
    }
  }

  if (opts$line_threshold_long > opts$line_threshold_very_long) {
    if (compat_line_threshold_set && !long_set) {
      opts$line_threshold_long <- opts$line_threshold_very_long
    } else {
      stop("line_threshold_long cannot be greater than line_threshold_very_long.", call. = FALSE)
    }
  }

  opts
}

trim_ws <- function(x) gsub("[ \t]+$", "", gsub("^[ \t]+", "", x))

read_lines_safe <- function(path) {
  tryCatch(
    readLines(path, warn = FALSE, encoding = "UTF-8"),
    error = function(e) NULL
  )
}

is_heading <- function(line) {
  grepl("^#{1,6}\\s+\\S", line)
}

heading_level <- function(line) {
  if (!is_heading(line)) return(NA_integer_)
  n <- regmatches(line, regexpr("^#+", line))
  nchar(n)
}

heading_text <- function(line) {
  trim_ws(sub("^#{1,6}\\s+", "", line))
}

is_code_fence <- function(line) {
  grepl("^(`{3,}|~{3,})", trim_ws(line))
}

is_list_item <- function(line) {
  grepl("^\\s*([-*+]|\\d+\\.)\\s+\\S", line)
}

is_link_line <- function(line) {
  grepl("\\[[^\\]]+\\]\\([^\\)]+\\)", line) || grepl("https?://\\S+", line)
}

code_context <- function(lines) {
  in_code <- logical(length(lines))
  open <- FALSE
  marker <- ""

  for (i in seq_along(lines)) {
    x <- trim_ws(lines[[i]])

    if (grepl("^(`{3,}|~{3,})", x)) {
      current_marker <- substr(x, 1, 1)
      if (!open) {
        open <- TRUE
        marker <- current_marker
      } else if (current_marker == marker) {
        open <- FALSE
        marker <- ""
      }
      in_code[[i]] <- open
      next
    }

    in_code[[i]] <- open
  }

  in_code
}

heading_indices <- function(lines) {
  in_code <- code_context(lines)
  which(!in_code & vapply(lines, is_heading, logical(1)))
}

summarize_section <- function(lines, start_idx, end_idx) {
  chunk <- lines[start_idx:end_idx]
  n_lines <- length(chunk)
  n_code_fences <- sum(vapply(chunk, is_code_fence, logical(1)))
  n_list_items <- sum(vapply(chunk, is_list_item, logical(1)))
  n_links <- sum(vapply(chunk, is_link_line, logical(1)))
  n_chars <- sum(nchar(chunk), na.rm = TRUE)

  list(
    n_lines = n_lines,
    n_chars = n_chars,
    n_code_fences = n_code_fences,
    n_list_items = n_list_items,
    n_links = n_links
  )
}

classify_section <- function(title, stats) {
  t <- tolower(title)

  if (grepl("install|installation|getting started|quick start|usage", t)) return("quickstart")
  if (grepl("faq|frequently asked|troubleshoot|troubleshooting", t)) return("faq_troubleshooting")
  if (grepl("roadmap|plan|milestone|todo|to-do|future", t)) return("roadmap")
  if (grepl("contribut|developer|internals|architecture", t)) return("developer_notes")
  if (grepl("example|examples|tutorial|walkthrough|guide|workflow", t)) return("tutorial_workflow")
  if (grepl("reference|functions|api", t)) return("reference_like")

  if (stats$n_code_fences >= 2 || stats$n_lines >= 80) return("tutorial_workflow")

  "general"
}

recommend_target <- function(class) {
  switch(
    class,
    quickstart = "KEEP in README (tighten to minimal example, link to site)",
    tutorial_workflow = "MOVE to Articles (web-first); keep only 1 minimal example in README",
    faq_troubleshooting = "MOVE to an FAQ / Troubleshooting Article; keep a link in README",
    roadmap = "MOVE to ROADMAP.md or a clearly labeled Roadmap page; keep link in README",
    developer_notes = "MOVE to CONTRIBUTING.md or Developer docs; keep README user-facing",
    reference_like = "MOVE to Reference (function docs) or an Article index; avoid listing every function in README",
    general = "CONSIDER moving to Site Home (index.md) if it adds narrative value; otherwise keep brief"
  )
}

print_header <- function(title) {
  line <- paste(rep("=", 72), collapse = "")
  c(line, title, line)
}

build_report <- function(readme_path, lines, opts) {
  report <- character()
  add <- function(...) {
    report <<- c(report, ...)
  }

  n_total_lines <- length(lines)
  n_total_chars <- sum(nchar(lines), na.rm = TRUE)

  h_idx <- heading_indices(lines)
  if (length(h_idx) == 0) {
    add(print_header("README Audit Report"))
    add("No headings found. Consider adding headings to improve scannability.")
    add(sprintf("Lines: %d  Chars: %d", n_total_lines, n_total_chars))
    return(report)
  }

  sections <- list()
  for (i in seq_along(h_idx)) {
    start <- h_idx[[i]]
    end <- if (i < length(h_idx)) h_idx[[i + 1]] - 1L else n_total_lines
    title <- heading_text(lines[[start]])
    lvl <- heading_level(lines[[start]])
    stats <- summarize_section(lines, start, end)
    class <- classify_section(title, stats)
    target <- recommend_target(class)

    sections[[length(sections) + 1L]] <- list(
      start = start,
      end = end,
      level = lvl,
      title = title,
      class = class,
      target = target,
      stats = stats
    )
  }

  add(print_header("README Audit Report"))
  add(sprintf("File:  %s", readme_path))
  add(sprintf("Lines: %d", n_total_lines))
  add(sprintf("Chars: %d", n_total_chars))
  add("")

  if (n_total_lines >= opts$line_threshold_very_long) {
    add(sprintf("Signal: README is very long (>=%d lines). Strongly consider migrating content to index.md and Articles.", opts$line_threshold_very_long))
  } else if (n_total_lines >= opts$line_threshold_long) {
    add(sprintf("Signal: README is long (>=%d lines). Consider migrating long tutorials and module guides.", opts$line_threshold_long))
  } else {
    add("Signal: README length is moderate. Migration may still help if sections are tutorial-heavy.")
  }
  add("")

  add(print_header("Section-by-section analysis"))
  for (s in sections) {
    indent <- paste(rep("  ", max(0L, s$level - 1L)), collapse = "")
    add(sprintf("%s- %s", indent, s$title))
    add(sprintf(
      "%s  Lines: %d | Code fences: %d | Lists: %d | Links: %d",
      indent, s$stats$n_lines, s$stats$n_code_fences, s$stats$n_list_items, s$stats$n_links
    ))
    add(sprintf("%s  Class: %s", indent, s$class))
    add(sprintf("%s  Suggestion: %s", indent, s$target))
    add("")
  }

  ord <- order(vapply(sections, function(x) x$stats$n_lines, numeric(1)), decreasing = TRUE)
  top_n <- min(opts$top_n, length(sections))
  top <- sections[ord][seq_len(top_n)]

  add(print_header("Top candidates to migrate (largest sections)"))
  for (s in top) {
    add(sprintf("- %s (%d lines) -> %s", s$title, s$stats$n_lines, s$target))
  }
  add("")

  long_sections <- sections[vapply(sections, function(x) x$stats$n_lines >= opts$long_section_threshold, logical(1))]
  if (length(long_sections) > 0) {
    add(print_header("Sections above long-section threshold"))
    add(sprintf("Threshold: >= %d lines", opts$long_section_threshold))
    for (s in long_sections) {
      add(sprintf("- %s (%d lines)", s$title, s$stats$n_lines))
    }
    add("")
  }

  add(print_header("Recommended lean README structure (suggested outline)"))
  add("- Title + badges")
  add("- One-paragraph description")
  add("- Installation")
  add("- One minimal example")
  add("- Where to start (links): Get started, Articles, Reference, News")
  add("- Scope/status (brief)")
  add("- Support (issues link)")
  add("")

  add(print_header("Suggested action plan"))
  add("1) Create or enrich index.md (site home) to absorb narrative + module map.")
  add("2) Convert long tutorials into Articles (web-first), keep 1 minimal example in README.")
  add("3) Move Roadmap content into ROADMAP.md (or a dedicated site page) and link from README.")
  add("4) Create FAQ and Troubleshooting as Articles.")
  add("5) Group Articles in _pkgdown.yml by module or audience.")
  add("")
  add("Done.")

  report
}

main <- function() {
  opts <- parse_args(commandArgs(trailingOnly = TRUE))
  readme_path <- normalizePath(opts$readme, winslash = "/", mustWork = FALSE)

  if (!file.exists(readme_path)) {
    cat(sprintf("README not found: %s\n", readme_path))
    quit(status = 1)
  }

  lines <- read_lines_safe(readme_path)
  if (is.null(lines)) {
    cat(sprintf("Could not read README: %s\n", readme_path))
    quit(status = 1)
  }

  report <- build_report(readme_path, lines, opts)
  cat(paste(report, collapse = "\n"), "\n", sep = "")

  if (!is.na(opts$output) && nzchar(opts$output)) {
    output_path <- normalizePath(opts$output, winslash = "/", mustWork = FALSE)
    dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
    writeLines(report, con = output_path)
    cat(sprintf("\nReport written to %s\n", output_path))
  }

  quit(status = 0)
}

if (identical(environment(), globalenv())) {
  main()
}
