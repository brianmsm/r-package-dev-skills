#!/usr/bin/env Rscript

# scaffold_pkgdown_site.R
#
# Purpose:
#   Scaffold a pkgdown website setup into a target R package repo using this
#   skill's templates.
#
# It can:
#   - create _pkgdown.yml from a chosen template (minimal or grouped)
#   - create index.md (site home) from template
#   - optionally create a lean README.md (with backup)
#   - optionally create website-only articles (Quarto) under vignettes/
#   - optionally create a Get started vignette/article (named after package)
#   - optionally append patterns to .Rbuildignore for website-only articles
#   - optionally copy a pkgdown GitHub Actions example workflow
#
# Usage examples:
#   Rscript scripts/scaffold_pkgdown_site.R --target ../myPkg --pkg myPkg --org user --repo myPkg
#
#   Rscript scripts/scaffold_pkgdown_site.R \
#     --target ../myPkg --pkg myPkg --org user --repo myPkg \
#     --config grouped \
#     --create-index \
#     --create-get-started \
#     --create-article workflows-cfa --create-article workflows-irt \
#     --web-only-articles
#
# Compatibility examples (legacy flags):
#   Rscript scripts/scaffold_pkgdown_site.R --package-path=. --template=articles-grouped --create-index=true
#
# Exit codes:
#   0: Completed
#   1: Failed

`%||%` <- function(x, y) if (is.null(x)) y else x

defaults <- list(
  target = ".",
  pkg = NULL,
  org = NULL,
  repo = NULL,
  url = NULL,
  config = "minimal", # minimal | grouped
  create_index = TRUE,
  write_readme = FALSE,
  create_readme_template = FALSE,
  create_get_started = FALSE,
  create_articles = character(),
  web_only_articles = FALSE,
  create_workflow_example = FALSE,
  force = FALSE,
  quiet = FALSE
)

help_text <- function() {
  paste0(
    "\nscaffold_pkgdown_site.R\n",
    "\nPrimary options:\n",
    "  -t, --target PATH            Target package root (default: .)\n",
    "      --pkg NAME               Package name (used to fill templates)\n",
    "      --org NAME               GitHub user/org (used to fill templates)\n",
    "      --repo NAME              GitHub repo name (used to fill templates)\n",
    "      --url URL                Site URL (overrides inferred GitHub Pages URL)\n",
    "      --config minimal|grouped Choose _pkgdown.yml template (default: minimal)\n",
    "      --create-index           Create index.md from template (if missing)\n",
    "      --write-readme           Replace README.md with lean template (backs up and overwrites)\n",
    "      --create-readme-template Create README-lean-template.md (non-destructive)\n",
    "      --create-get-started     Create vignettes/<pkg>.qmd from template\n",
    "      --create-article NAME    Create vignettes/NAME.qmd from article template (repeatable)\n",
    "      --web-only-articles      Append created article paths to .Rbuildignore\n",
    "      --create-workflow-example Copy assets/examples/pkgdown-gha.yaml to workflow\n",
    "  -f, --force                  Overwrite existing files\n",
    "  -q, --quiet                  Reduce output\n",
    "  -h, --help                   Show this help\n",
    "\nLegacy compatibility:\n",
    "      --package-path=PATH\n",
    "      --template=minimal|articles-grouped\n",
    "      --create-index=true|false\n",
    "      --create-readme-template=true|false\n",
    "      --create-get-started=true|false\n",
    "      --create-web-only-article=true|false\n",
    "      --create-workflow-example=true|false\n",
    "\n"
  )
}

as_bool <- function(x, what = "boolean") {
  value <- tolower(trimws(as.character(x)))
  if (value %in% c("true", "1", "yes", "y")) return(TRUE)
  if (value %in% c("false", "0", "no", "n")) return(FALSE)
  stop(sprintf("Invalid %s value: %s", what, x), call. = FALSE)
}

normalize_config <- function(x) {
  value <- tolower(trimws(as.character(x)))
  if (value %in% c("minimal")) return("minimal")
  if (value %in% c("grouped", "articles-grouped")) return("grouped")
  stop(sprintf("Invalid config/template value: %s (use minimal or grouped)", x), call. = FALSE)
}

normalize_article_name <- function(x) {
  value <- trimws(as.character(x))
  value <- sub("[.](qmd|rmd|md)$", "", value, ignore.case = TRUE)
  value <- gsub("\\\\", "/", value)
  value <- gsub("/+", "/", value)
  value <- sub("^/+", "", value)
  value <- sub("/+$", "", value)
  value
}

is_valid_pkg_name <- function(x) {
  is.character(x) && length(x) == 1 && grepl("^[A-Za-z][A-Za-z0-9.]*$", x)
}

validate_article_name <- function(x) {
  if (!is.character(x) || length(x) != 1) {
    stopf("Invalid article name (expected a single string).")
  }
  if (!nzchar(x)) {
    stopf("Invalid article name (empty).")
  }
  if (grepl("(^|/)\\.\\.?(/|$)", x)) {
    stopf("Invalid article name: %s (must not contain '.' or '..' path segments).", x)
  }
  if (!grepl("^[A-Za-z0-9][A-Za-z0-9._/-]*$", x)) {
    stopf(
      "Invalid article name: %s (use letters/digits and only '.', '_', '-', '/'; no spaces).",
      x
    )
  }
  invisible(TRUE)
}

assert_within_dir <- function(root_dir, path) {
  root_norm <- normalizePath(root_dir, winslash = "/", mustWork = FALSE)
  path_norm <- normalizePath(path, winslash = "/", mustWork = FALSE)
  prefix <- paste0(sub("/+$", "", root_norm), "/")

  root_cmp <- prefix
  path_cmp <- path_norm
  if (identical(.Platform$OS.type, "windows")) {
    root_cmp <- tolower(root_cmp)
    path_cmp <- tolower(path_cmp)
  }

  if (!startsWith(path_cmp, root_cmp)) {
    stopf("Refusing to write outside target directory: %s", path_norm)
  }
  invisible(TRUE)
}

set_frontmatter_title <- function(lines, title) {
  if (!is.character(lines) || length(lines) == 0) return(lines)
  if (!nzchar(title)) return(lines)

  is_delim <- function(x) identical(trimws(x), "---")
  if (!is_delim(lines[[1]])) return(lines)

  end_idx <- which(vapply(lines[-1], is_delim, logical(1)))
  if (length(end_idx) == 0) return(lines)
  end_idx <- end_idx[[1]] + 1L

  start <- 2L
  end <- end_idx - 1L
  if (end < start) return(lines)

  title_line <- paste0('title: "', title, '"')
  title_idx <- which(grepl("^\\s*title\\s*:", lines[start:end]))
  if (length(title_idx) > 0) {
    lines[start + title_idx[[1]] - 1L] <- title_line
    return(lines)
  }

  append(
    lines[seq_len(start - 1L)],
    c(title_line, lines[start:length(lines)]),
    after = start - 1L
  )
}

apply_option <- function(opts, key, value = NULL, flag_only = FALSE) {
  k <- gsub("-", "_", sub("^--?", "", key))

  if (k == "package_path") k <- "target"
  if (k == "template") k <- "config"
  if (k == "create_web_only_article") k <- "create_web_only_article_legacy"

  set_bool <- function(field, val) {
    opts[[field]] <<- if (flag_only) TRUE else as_bool(val, what = field)
  }

  if (k %in% c("target", "pkg", "org", "repo", "url")) {
    if (is.null(value)) stop(sprintf("Missing value for --%s", k), call. = FALSE)
    opts[[k]] <- value
    return(opts)
  }

  if (k == "config") {
    if (is.null(value)) stop("Missing value for --config", call. = FALSE)
    opts$config <- normalize_config(value)
    return(opts)
  }

  if (k == "create_article") {
    if (is.null(value)) stop("Missing value for --create-article", call. = FALSE)
    nm <- normalize_article_name(value)
    if (nzchar(nm)) opts$create_articles <- c(opts$create_articles, nm)
    return(opts)
  }

  if (k %in% c(
    "create_index", "write_readme", "create_readme_template", "create_get_started",
    "web_only_articles", "create_workflow_example", "force", "quiet"
  )) {
    set_bool(k, value)
    return(opts)
  }

  if (k == "create_web_only_article_legacy") {
    val <- if (flag_only) TRUE else as_bool(value, what = "create_web_only_article")
    if (isTRUE(val)) {
      opts$create_articles <- c(opts$create_articles, "articles/article-web-only")
    }
    return(opts)
  }

  stop(sprintf("Unknown argument: --%s", gsub("_", "-", k)), call. = FALSE)
}

parse_args <- function(args) {
  opts <- defaults
  positional <- character()

  i <- 1L
  while (i <= length(args)) {
    a <- args[[i]]

    if (a %in% c("-h", "--help")) {
      cat(help_text())
      quit(status = 0)
    }

    if (startsWith(a, "--") && grepl("=", a, fixed = TRUE)) {
      parts <- strsplit(sub("^--", "", a), "=", fixed = TRUE)[[1]]
      key <- parts[[1]]
      value <- paste(parts[-1], collapse = "=")
      opts <- apply_option(opts, key = key, value = value, flag_only = FALSE)
      i <- i + 1L
      next
    }

    if (a %in% c("-t", "--target", "--pkg", "--org", "--repo", "--url", "--config", "--create-article")) {
      if (i == length(args)) stop(sprintf("Missing value after %s", a), call. = FALSE)
      key <- if (a == "-t") "target" else sub("^--", "", a)
      opts <- apply_option(opts, key = key, value = args[[i + 1L]], flag_only = FALSE)
      i <- i + 2L
      next
    }

    if (a %in% c(
      "--create-index", "--write-readme", "--create-readme-template", "--create-get-started",
      "--web-only-articles", "--create-workflow-example", "-f", "--force", "-q", "--quiet"
    )) {
      key <- switch(a,
        "-f" = "force",
        "--force" = "force",
        "-q" = "quiet",
        "--quiet" = "quiet",
        sub("^--", "", a)
      )
      opts <- apply_option(opts, key = key, flag_only = TRUE)
      i <- i + 1L
      next
    }

    if (startsWith(a, "--")) {
      stop(sprintf("Unknown argument: %s", a), call. = FALSE)
    }

    positional <- c(positional, a)
    i <- i + 1L
  }

  if (length(positional) > 1L) {
    stop("Only one positional argument is supported (target path).", call. = FALSE)
  }
  if (length(positional) == 1L && identical(opts$target, ".")) {
    opts$target <- positional[[1]]
  }

  opts$create_articles <- unique(opts$create_articles[nzchar(opts$create_articles)])
  opts
}

msg <- function(..., quiet = FALSE) {
  if (!quiet) cat(..., "\n", sep = "")
}

stopf <- function(fmt, ...) stop(sprintf(fmt, ...), call. = FALSE)

timestamp <- function() format(Sys.time(), "%Y%m%d-%H%M%S")

script_path <- function() {
  cmd <- commandArgs(trailingOnly = FALSE)
  file_arg <- cmd[grepl("^--file=", cmd)]
  if (length(file_arg) == 0) return(NA_character_)
  sub("^--file=", "", file_arg[1])
}

skill_root_from_script <- function() {
  sp <- script_path()
  if (is.na(sp)) return(normalizePath(".", winslash = "/", mustWork = FALSE))
  sd <- normalizePath(dirname(sp), winslash = "/", mustWork = FALSE)
  normalizePath(file.path(sd, ".."), winslash = "/", mustWork = FALSE)
}

read_text <- function(path) readLines(path, warn = FALSE, encoding = "UTF-8")

write_text <- function(path, lines) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  writeLines(lines, con = path, useBytes = TRUE)
}

backup_file <- function(path) {
  if (!file.exists(path)) return(invisible(NULL))
  bkp <- paste0(path, ".bak-", timestamp())
  file.copy(path, bkp, overwrite = FALSE)
  bkp
}

infer_site_url <- function(org, repo) {
  if (is.null(org) || is.null(repo)) return(NULL)
  paste0("https://", org, ".github.io/", repo, "/")
}

ensure_trailing_slash <- function(x) {
  if (is.null(x) || !nzchar(x)) return(x)
  if (grepl("/$", x)) x else paste0(x, "/")
}

read_desc_value <- function(desc_path, field) {
  if (!file.exists(desc_path)) return(NULL)
  dcf <- tryCatch(read.dcf(desc_path), error = function(e) NULL)
  if (is.null(dcf) || !field %in% colnames(dcf)) return(NULL)
  value <- trimws(as.character(dcf[1, field]))
  if (!nzchar(value) || toupper(value) %in% c("NA", "NULL")) return(NULL)
  value
}

build_replacements <- function(opts, root) {
  desc_path <- file.path(root, "DESCRIPTION")

  pkg <- opts$pkg %||% read_desc_value(desc_path, "Package")
  repo <- opts$repo %||% pkg
  site_url <- ensure_trailing_slash(opts$url %||% infer_site_url(opts$org, repo))
  license <- read_desc_value(desc_path, "License")

  issues_url <- if (!is.null(opts$org) && !is.null(repo)) {
    paste0("https://github.com/", opts$org, "/", repo, "/issues")
  } else {
    "{issues_url}"
  }

  website <- if (!is.null(site_url)) site_url else "{pkgdown_url}"
  articles_index <- if (!is.null(site_url)) paste0(site_url, "articles/") else "{articles_index_link}"
  reference <- if (!is.null(site_url)) paste0(site_url, "reference/") else "{reference_link}"
  news <- if (!is.null(site_url)) paste0(site_url, "news/") else "{news_link}"

  get_started <- if (!is.null(site_url) && !is.null(pkg)) {
    paste0(site_url, "articles/", pkg, ".html")
  } else {
    "{get_started_link}"
  }

  roadmap <- if (!is.null(opts$org) && !is.null(repo)) {
    paste0("https://github.com/", opts$org, "/", repo, "/blob/main/ROADMAP.md")
  } else {
    "{roadmap_link}"
  }

  list(
    pkg = pkg,
    org = opts$org,
    repo = repo,
    site_url = site_url,
    issues_url = issues_url,
    website = website,
    articles_index = articles_index,
    reference = reference,
    news = news,
    get_started = get_started,
    roadmap = roadmap,
    license = license
  )
}

apply_replacements <- function(lines, rep) {
  out <- lines

  # Angle-bracket placeholders used in YAML templates
  if (!is.null(rep$org)) out <- gsub("<user-or-org>", rep$org, out, fixed = TRUE)
  if (!is.null(rep$repo)) out <- gsub("<repo>", rep$repo, out, fixed = TRUE)

  # Legacy placeholders used in older templates
  if (!is.null(rep$org) && !is.null(rep$repo)) out <- gsub("ORG/REPO", paste0(rep$org, "/", rep$repo), out, fixed = TRUE)
  if (!is.null(rep$pkg)) out <- gsub("REPO", rep$pkg, out, fixed = TRUE)

  # Curly placeholders used in newer templates
  token_map <- c(
    "{pkg}" = rep$pkg %||% "{pkg}",
    "{org}" = rep$org %||% "{org}",
    "{repo}" = rep$repo %||% "{repo}",
    "{pkgdown_url}" = rep$website,
    "{issues_url}" = rep$issues_url,
    "{roadmap_link}" = rep$roadmap,
    "{news_link}" = rep$news,
    "{get_started_link}" = rep$get_started,
    "{articles_index_link}" = rep$articles_index,
    "{reference_link}" = rep$reference,
    "{license}" = rep$license %||% "{license}"
  )

  for (k in names(token_map)) {
    out <- gsub(k, token_map[[k]], out, fixed = TRUE)
  }

  out
}

force_set_url <- function(lines, site_url) {
  if (is.null(site_url)) return(lines)
  sub("^url:\\s+.*$", paste0("url: ", site_url), lines)
}

safe_write <- function(path, lines, force = FALSE, quiet = FALSE) {
  if (file.exists(path) && !force) {
    msg("Skip (exists): ", path, quiet = quiet)
    return(FALSE)
  }
  write_text(path, lines)
  msg("Wrote: ", path, quiet = quiet)
  TRUE
}

append_rbuildignore <- function(root, paths_to_ignore, quiet = FALSE) {
  if (length(paths_to_ignore) == 0L) return(FALSE)

  rb <- file.path(root, ".Rbuildignore")
  existing <- if (file.exists(rb)) read_text(rb) else character()

  root_norm <- normalizePath(root, winslash = "/", mustWork = FALSE)
  paths_norm <- normalizePath(paths_to_ignore, winslash = "/", mustWork = FALSE)
  root_prefix <- paste0(sub("/+$", "", root_norm), "/")

  root_cmp <- root_prefix
  paths_cmp <- paths_norm
  if (identical(.Platform$OS.type, "windows")) {
    root_cmp <- tolower(root_cmp)
    paths_cmp <- tolower(paths_cmp)
  }

  rels <- ifelse(
    startsWith(paths_cmp, root_cmp),
    substr(paths_norm, nchar(root_prefix) + 1L, nchar(paths_norm)),
    paths_norm
  )
  rels <- gsub("([.|()\\^{}+$*?]|\\[|\\]|\\\\)", "\\\\\\1", rels)
  patterns <- paste0("^", rels, "$")

  to_add <- setdiff(patterns, existing)
  if (length(to_add) == 0L) {
    msg("No .Rbuildignore changes needed.", quiet = quiet)
    return(FALSE)
  }

  write_text(rb, c(existing, to_add))
  msg("Updated: ", rb, quiet = quiet)
  TRUE
}

main <- function() {
  opts <- parse_args(commandArgs(trailingOnly = TRUE))
  root <- normalizePath(opts$target, winslash = "/", mustWork = FALSE)

  if (!dir.exists(root)) stopf("Target directory does not exist: %s", root)

  desc <- file.path(root, "DESCRIPTION")
  if (!file.exists(desc)) {
    msg("Warning: DESCRIPTION not found at target root. Proceeding anyway.", quiet = opts$quiet)
  }

  rep <- build_replacements(opts, root)

  if (opts$create_get_started && (is.null(rep$pkg) || !nzchar(rep$pkg))) {
    stopf("--create-get-started requires --pkg or a Package field in DESCRIPTION.")
  }
  if (opts$create_get_started && !is_valid_pkg_name(rep$pkg)) {
    stopf(
      "Invalid package name for --create-get-started: %s (must be a valid R package name).",
      rep$pkg
    )
  }

  skill_root <- skill_root_from_script()
  templates_dir <- file.path(skill_root, "assets", "templates")
  examples_dir <- file.path(skill_root, "assets", "examples")

  if (!dir.exists(templates_dir)) stopf("Templates directory not found: %s", templates_dir)

  cfg_template <- switch(
    opts$config,
    minimal = file.path(templates_dir, "_pkgdown-minimal.yml"),
    grouped = file.path(templates_dir, "_pkgdown-articles-grouped.yml"),
    stopf("Unsupported config: %s", opts$config)
  )
  if (!file.exists(cfg_template)) stopf("Config template not found: %s", cfg_template)

  msg("\n== Scaffold pkgdown site ==", quiet = opts$quiet)
  msg("Target: ", root, quiet = opts$quiet)
  msg("Config: ", opts$config, quiet = opts$quiet)
  if (!is.null(rep$site_url)) msg("URL:    ", rep$site_url, quiet = opts$quiet)
  msg("", quiet = opts$quiet)

  created <- character()
  created_articles <- character()

  # 1) _pkgdown.yml
  cfg_out <- file.path(root, "_pkgdown.yml")
  cfg_lines <- read_text(cfg_template)
  cfg_lines <- apply_replacements(cfg_lines, rep)
  cfg_lines <- force_set_url(cfg_lines, rep$site_url)
  if (safe_write(cfg_out, cfg_lines, force = opts$force, quiet = opts$quiet)) {
    created <- c(created, cfg_out)
  }

  # 2) index.md
  if (isTRUE(opts$create_index)) {
    idx_template <- file.path(templates_dir, "index.md")
    if (!file.exists(idx_template)) stopf("index.md template not found: %s", idx_template)

    idx_out <- file.path(root, "index.md")
    idx_lines <- apply_replacements(read_text(idx_template), rep)
    if (safe_write(idx_out, idx_lines, force = opts$force, quiet = opts$quiet)) {
      created <- c(created, idx_out)
    }
  }

  # 3) README handling
  if (isTRUE(opts$create_readme_template)) {
    rd_template <- file.path(templates_dir, "README-lean-template.md")
    if (!file.exists(rd_template)) stopf("README template not found: %s", rd_template)

    rd_out <- file.path(root, "README-lean-template.md")
    rd_lines <- apply_replacements(read_text(rd_template), rep)
    if (safe_write(rd_out, rd_lines, force = opts$force, quiet = opts$quiet)) {
      created <- c(created, rd_out)
    }
  }

  if (isTRUE(opts$write_readme)) {
    rd_template <- file.path(templates_dir, "README-lean-template.md")
    if (!file.exists(rd_template)) stopf("README template not found: %s", rd_template)

    rd_out <- file.path(root, "README.md")
    if (file.exists(rd_out)) {
      bkp <- backup_file(rd_out)
      msg("Backed up existing README to: ", bkp, quiet = opts$quiet)
    }

    rd_lines <- apply_replacements(read_text(rd_template), rep)
    if (safe_write(rd_out, rd_lines, force = TRUE, quiet = opts$quiet)) {
      created <- c(created, rd_out)
    }
  }

  vignettes_dir <- file.path(root, "vignettes")

  # 4) get-started
  if (isTRUE(opts$create_get_started)) {
    gs_template <- file.path(templates_dir, "get-started.qmd")
    if (!file.exists(gs_template)) stopf("Get started template not found: %s", gs_template)

    gs_out <- file.path(vignettes_dir, paste0(rep$pkg, ".qmd"))
    gs_lines <- apply_replacements(read_text(gs_template), rep)

    dir.create(vignettes_dir, showWarnings = FALSE, recursive = TRUE)
    assert_within_dir(root, gs_out)
    if (safe_write(gs_out, gs_lines, force = opts$force, quiet = opts$quiet)) {
      created <- c(created, gs_out)
      created_articles <- c(created_articles, gs_out)
    }
  }

  # 5) additional articles
  if (length(opts$create_articles) > 0L) {
    art_template <- file.path(templates_dir, "article-web-only.qmd")
    if (!file.exists(art_template)) stopf("Article template not found: %s", art_template)

    dir.create(vignettes_dir, showWarnings = FALSE, recursive = TRUE)

    for (nm in opts$create_articles) {
      article_name <- normalize_article_name(nm)
      if (!nzchar(article_name)) next
      validate_article_name(article_name)

      out <- file.path(vignettes_dir, paste0(article_name, ".qmd"))
      assert_within_dir(vignettes_dir, out)
      art_lines <- apply_replacements(read_text(art_template), rep)
      art_lines <- set_frontmatter_title(art_lines, article_name)

      if (safe_write(out, art_lines, force = opts$force, quiet = opts$quiet)) {
        created <- c(created, out)
        created_articles <- c(created_articles, out)
      }
    }
  }

  # 6) optional workflow example
  if (isTRUE(opts$create_workflow_example)) {
    gha_template <- file.path(examples_dir, "pkgdown-gha.yaml")
    if (!file.exists(gha_template)) stopf("Workflow example not found: %s", gha_template)

    gha_out <- file.path(root, ".github", "workflows", "pkgdown.yaml")
    gha_lines <- apply_replacements(read_text(gha_template), rep)
    if (safe_write(gha_out, gha_lines, force = opts$force, quiet = opts$quiet)) {
      created <- c(created, gha_out)
    }
  }

  # 7) optional .Rbuildignore updates
  if (isTRUE(opts$web_only_articles) && length(created_articles) > 0L) {
    append_rbuildignore(root, created_articles, quiet = opts$quiet)
  }

  msg("\n== Summary ==", quiet = opts$quiet)
  if (length(created) == 0L) {
    msg("No files created (all targets already existed and --force was not set).", quiet = opts$quiet)
  } else {
    for (p in created) msg("- ", p, quiet = opts$quiet)
  }

  msg("\nNext steps:", quiet = opts$quiet)
  msg("  1) Review _pkgdown.yml and set final site metadata.", quiet = opts$quiet)
  msg("  2) Run pkgdown::build_site() locally to preview.", quiet = opts$quiet)
  msg("  3) Consider usethis::use_pkgdown_github_pages() for Pages deploy wiring.", quiet = opts$quiet)

  quit(status = 0)
}

main()
