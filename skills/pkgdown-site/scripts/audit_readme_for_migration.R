#!/usr/bin/env Rscript

defaults <- list(
  readme = "README.md",
  output = NA_character_,
  line_threshold = 260L,
  long_section_threshold = 70L
)

parse_args <- function(args) {
  opts <- defaults
  for (arg in args) {
    if (grepl("^--readme=", arg)) {
      opts$readme <- sub("^--readme=", "", arg)
    } else if (grepl("^--output=", arg)) {
      opts$output <- sub("^--output=", "", arg)
    } else if (grepl("^--line-threshold=", arg)) {
      opts$line_threshold <- as.integer(sub("^--line-threshold=", "", arg))
    } else if (grepl("^--long-section-threshold=", arg)) {
      opts$long_section_threshold <- as.integer(sub("^--long-section-threshold=", "", arg))
    } else if (arg == "--help") {
      cat("Usage:\n")
      cat("  Rscript audit_readme_for_migration.R [--readme=README.md] [--output=report.md]\n")
      cat("      [--line-threshold=260] [--long-section-threshold=70]\n")
      quit(status = 0L)
    } else if (!startsWith(arg, "--")) {
      opts$readme <- arg
    }
  }
  opts
}

section_lengths <- function(lines) {
  heading_idx <- grep("^#{1,6}\\s+", lines)
  if (length(heading_idx) == 0L) {
    return(data.frame(
      heading = character(),
      start = integer(),
      end = integer(),
      length = integer(),
      stringsAsFactors = FALSE
    ))
  }

  heading_text <- sub("^#{1,6}\\s+", "", lines[heading_idx])
  end_idx <- c(heading_idx[-1] - 1L, length(lines))
  data.frame(
    heading = heading_text,
    start = heading_idx,
    end = end_idx,
    length = pmax(end_idx - heading_idx + 1L, 0L),
    stringsAsFactors = FALSE
  )
}

count_code_blocks <- function(lines) {
  fence_idx <- grep("^```", lines)
  if (length(fence_idx) < 2L) {
    return(integer())
  }
  lengths <- integer()
  for (i in seq(1L, length(fence_idx) - 1L, by = 2L)) {
    lengths <- c(lengths, max(fence_idx[i + 1L] - fence_idx[i] - 1L, 0L))
  }
  lengths
}

opts <- parse_args(commandArgs(trailingOnly = TRUE))
readme_path <- normalizePath(opts$readme, winslash = "/", mustWork = FALSE)

if (!file.exists(readme_path)) {
  cat(sprintf("ERROR: README file not found at %s\n", readme_path))
  quit(status = 1L)
}

lines <- readLines(readme_path, warn = FALSE)
line_count <- length(lines)
headings <- grep("^#{1,6}\\s+", lines, value = TRUE)
heading_count <- length(headings)
sections <- section_lengths(lines)
code_block_lengths <- count_code_blocks(lines)

long_sections <- if (nrow(sections) > 0L) {
  sections[sections$length >= opts$long_section_threshold, , drop = FALSE]
} else {
  sections
}

long_code_blocks <- code_block_lengths[code_block_lengths >= 20L]

report <- character()
append_line <- function(x = "") {
  report <<- c(report, x)
}

append_line("# README migration audit")
append_line("")
append_line(sprintf("- file: `%s`", readme_path))
append_line(sprintf("- total lines: %d", line_count))
append_line(sprintf("- headings: %d", heading_count))
append_line(sprintf("- code blocks: %d", length(code_block_lengths)))
append_line(sprintf("- long code blocks (>=20 lines): %d", length(long_code_blocks)))
append_line("")

append_line("## Heuristic assessment")
if (line_count > opts$line_threshold) {
  append_line(sprintf("- README is above %d lines: migration is recommended.", opts$line_threshold))
} else {
  append_line(sprintf("- README is below %d lines: full migration may not be required.", opts$line_threshold))
}

if (heading_count >= 10L) {
  append_line("- README has many sections: consider moving workflows to articles.")
}

if (nrow(long_sections) > 0L) {
  append_line("- Long sections detected: these are strong migration candidates.")
} else {
  append_line("- No very long sections detected.")
}
append_line("")

append_line("## Long sections")
if (nrow(long_sections) == 0L) {
  append_line("- none")
} else {
  for (i in seq_len(nrow(long_sections))) {
    append_line(sprintf("- `%s` (%d lines)", long_sections$heading[i], long_sections$length[i]))
  }
}
append_line("")

append_line("## Suggested moves")
append_line("- Keep in README: package summary, install, one minimal example, website link.")
append_line("- Move to site home (`index.md`): module map, maturity status, roadmap summary.")
append_line("- Move to articles: advanced workflows, FAQ, troubleshooting, migration notes.")

if (nrow(sections) > 0L) {
  lower_headings <- tolower(sections$heading)
  candidates_articles <- unique(sections$heading[grepl(
    "workflow|tutorial|advanced|faq|troubleshooting|migration|case study",
    lower_headings
  )])
  candidates_home <- unique(sections$heading[grepl(
    "overview|roadmap|status|architecture|design|module",
    lower_headings
  )])

  if (length(candidates_home) > 0L) {
    append_line("")
    append_line("### Candidate sections for `index.md`")
    for (h in candidates_home) {
      append_line(sprintf("- %s", h))
    }
  }

  if (length(candidates_articles) > 0L) {
    append_line("")
    append_line("### Candidate sections for articles")
    for (h in candidates_articles) {
      append_line(sprintf("- %s", h))
    }
  }
}

append_line("")
append_line("## Recommended next step")
append_line("Create or update `pkgdown/index.md`, keep README lean, and split long workflows into articles.")

cat(paste(report, collapse = "\n"))
cat("\n")

if (!is.na(opts$output) && nzchar(opts$output)) {
  output_path <- normalizePath(opts$output, winslash = "/", mustWork = FALSE)
  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  writeLines(report, con = output_path)
  cat(sprintf("\nReport written to %s\n", output_path))
}
