#!/usr/bin/env Rscript

# validate_pkgdown_config.R
#
# Purpose:
#   Lightweight validation for pkgdown configuration and common repo structure.
#   It aims to catch common mistakes early (invalid YAML, missing url, navbar
#   shape, missing home sources, missing referenced articles).
#
# Usage:
#   Rscript scripts/validate_pkgdown_config.R
#   Rscript scripts/validate_pkgdown_config.R path/to/_pkgdown.yml
#   Rscript scripts/validate_pkgdown_config.R path/to/_pkgdown.yml --template-mode
#
# Exit codes:
#   0: OK (no errors; warnings may exist)
#   1: Errors found

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

as_bool <- function(x) {
  value <- tolower(trimws(x))
  if (value %in% c("true", "1", "yes", "y")) return(TRUE)
  if (value %in% c("false", "0", "no", "n")) return(FALSE)
  stop(sprintf("Invalid boolean value for --template-mode: %s", x), call. = FALSE)
}

print_usage <- function() {
  cat("Usage:\n")
  cat("  Rscript scripts/validate_pkgdown_config.R\n")
  cat("  Rscript scripts/validate_pkgdown_config.R path/to/_pkgdown.yml\n")
  cat("  Rscript scripts/validate_pkgdown_config.R path/to/_pkgdown.yml --template-mode\n")
  cat("  Rscript scripts/validate_pkgdown_config.R --template-mode=true\n")
}

parse_cli_args <- function(args) {
  cfg_path <- "_pkgdown.yml"
  cfg_set <- FALSE
  template_mode <- FALSE

  for (arg in args) {
    if (arg %in% c("-h", "--help")) {
      print_usage()
      quit(status = 0)
    }

    if (arg == "--template-mode") {
      template_mode <- TRUE
      next
    }

    if (grepl("^--template-mode=", arg)) {
      template_mode <- as_bool(sub("^--template-mode=", "", arg))
      next
    }

    if (startsWith(arg, "--")) {
      stop(sprintf("Unknown argument: %s", arg), call. = FALSE)
    }

    if (cfg_set) {
      stop("Multiple config paths provided. Pass only one path.", call. = FALSE)
    }
    cfg_path <- arg
    cfg_set <- TRUE
  }

  list(cfg_path = cfg_path, template_mode = template_mode)
}

as_chr <- function(x) {
  if (is.null(x)) return(character())
  if (is.character(x)) return(x)
  if (is.list(x)) return(unlist(x, use.names = FALSE))
  character()
}

is_selector_expr <- function(x) {
  if (!is.character(x) || length(x) != 1) return(FALSE)
  grepl("\\(", x) || grepl("\\)", x)
}

is_http_url <- function(x) {
  is.character(x) && length(x) == 1 && grepl("^https?://", x)
}

collect_vignette_stems <- function(vignettes_dir) {
  if (!dir.exists(vignettes_dir)) return(character())

  files <- list.files(
    vignettes_dir,
    recursive = TRUE,
    full.names = TRUE
  )
  files <- files[grepl("\\.(Rmd|qmd|md)$", files, ignore.case = TRUE)]
  if (length(files) == 0) return(character())

  root <- normalizePath(vignettes_dir, winslash = "/", mustWork = TRUE)
  files_norm <- normalizePath(files, winslash = "/", mustWork = TRUE)

  rel <- sub(paste0("^", gsub("([.|()\\^{}+$*?]|\\[|\\]|\\\\)", "\\\\\\1", root), "/?"), "", files_norm)
  rel <- sub("^[/\\\\]", "", rel)
  stems <- sub("\\.[^.]+$", "", rel)
  stems <- gsub("\\\\", "/", stems)
  unique(stems)
}

validate_yaml <- function(cfg_path) {
  require_pkg("yaml")
  tryCatch(
    yaml::read_yaml(cfg_path),
    error = function(e) {
      list(.error = paste("YAML parse error:", conditionMessage(e)))
    }
  )
}

validate_repo_basics <- function(root_dir, warnings, errors, template_mode = FALSE) {
  if (isTRUE(template_mode)) {
    return(list(warnings = warnings, errors = errors))
  }

  desc_path <- file.path(root_dir, "DESCRIPTION")
  if (!file.exists(desc_path)) {
    errors <- c(errors, "Missing DESCRIPTION at repo root. Are you in an R package directory?")
  }

  home_candidates <- c(
    file.path(root_dir, "pkgdown", "index.md"),
    file.path(root_dir, "index.md"),
    file.path(root_dir, "README.md")
  )
  if (!any(file.exists(home_candidates))) {
    warnings <- c(
      warnings,
      "No pkgdown home source found (pkgdown/index.md, index.md, or README.md). The site home may be empty or default."
    )
  }

  list(warnings = warnings, errors = errors)
}

validate_url <- function(cfg, warnings, errors) {
  url <- cfg$url

  if (is.null(url) || length(url) == 0 || !nzchar(trimws(as.character(url[[1]])))) {
    warnings <- c(
      warnings,
      "No `url:` found in _pkgdown.yml. Internal links may be less reliable, and the site URL will not be explicit."
    )
    return(list(warnings = warnings, errors = errors))
  }

  url_scalar <- as.character(url[[1]])
  if (!is_http_url(url_scalar)) {
    warnings <- c(
      warnings,
      sprintf("`url` does not look like an http(s) URL: %s", url_scalar)
    )
  }

  if (length(url) > 1) {
    warnings <- c(warnings, "`url` has multiple values; expected a single scalar string.")
  }

  list(warnings = warnings, errors = errors)
}

validate_template <- function(cfg, warnings, errors) {
  tmpl <- cfg$template
  if (is.null(tmpl)) return(list(warnings = warnings, errors = errors))

  if (!is.list(tmpl)) {
    warnings <- c(warnings, "`template:` is present but not a mapping/list. Check YAML indentation.")
    return(list(warnings = warnings, errors = errors))
  }

  if (!is.null(tmpl$bootstrap)) {
    bs <- as.character(tmpl$bootstrap[[1]])
    if (nzchar(bs) && bs != "5") {
      warnings <- c(
        warnings,
        sprintf("template.bootstrap is '%s'. Most modern pkgdown sites use bootstrap: 5.", bs)
      )
    }
  }

  list(warnings = warnings, errors = errors)
}

validate_navbar <- function(cfg, warnings, errors) {
  nb <- cfg$navbar
  if (is.null(nb)) return(list(warnings = warnings, errors = errors))

  if (!is.list(nb)) {
    warnings <- c(warnings, "`navbar:` is present but not a mapping/list. Check YAML indentation.")
    return(list(warnings = warnings, errors = errors))
  }

  structure <- nb$structure
  if (is.null(structure)) {
    warnings <- c(warnings, "navbar.structure is missing. pkgdown will use defaults, but customization may not apply.")
    return(list(warnings = warnings, errors = errors))
  }

  if (!is.list(structure)) {
    warnings <- c(warnings, "navbar.structure is not a mapping/list. Check YAML indentation.")
    return(list(warnings = warnings, errors = errors))
  }

  left <- as_chr(structure$left)
  right <- as_chr(structure$right)

  if (length(left) == 0 && length(right) == 0) {
    warnings <- c(warnings, "navbar.structure.left and navbar.structure.right are empty. Did you intend that?")
  }

  known <- c("home", "intro", "reference", "articles", "tutorials", "news", "search", "github")
  all_items <- unique(c(left, right))
  unknown <- setdiff(all_items, known)
  if (length(unknown) > 0) {
    warnings <- c(
      warnings,
      paste0(
        "navbar.structure contains unknown components: ",
        paste(unknown, collapse = ", "),
        ". This may be fine if you define matching navbar.components entries."
      )
    )
  }

  comps <- nb$components
  if (!is.null(comps) && !is.list(comps)) {
    warnings <- c(warnings, "navbar.components is present but not a mapping/list. Check YAML indentation.")
  }

  list(warnings = warnings, errors = errors)
}

extract_explicit_article_refs <- function(articles_cfg) {
  if (is.null(articles_cfg)) return(character())
  if (!is.list(articles_cfg)) return(character())

  refs <- character()

  for (section in articles_cfg) {
    if (!is.list(section)) next
    contents <- section$contents
    if (is.null(contents)) next

    vals <- as_chr(contents)
    vals <- vals[!is.na(vals) & nzchar(vals)]

    explicit <- vals[!vapply(vals, is_selector_expr, logical(1))]
    refs <- c(refs, explicit)
  }

  unique(refs)
}

validate_articles <- function(root_dir, cfg, warnings, errors, template_mode = FALSE) {
  articles_cfg <- cfg$articles
  if (is.null(articles_cfg)) return(list(warnings = warnings, errors = errors))

  if (!is.list(articles_cfg)) {
    warnings <- c(warnings, "`articles:` is present but not a list of sections. Check YAML indentation.")
    return(list(warnings = warnings, errors = errors))
  }

  vignettes_dir <- file.path(root_dir, "vignettes")
  stems <- collect_vignette_stems(vignettes_dir)
  explicit_refs <- extract_explicit_article_refs(articles_cfg)

  if (length(explicit_refs) == 0) return(list(warnings = warnings, errors = errors))

  if (!dir.exists(vignettes_dir)) {
    if (isTRUE(template_mode)) {
      return(list(warnings = warnings, errors = errors))
    }
    warnings <- c(
      warnings,
      "vignettes/ directory does not exist, but explicit articles are listed in `_pkgdown.yml`."
    )
    return(list(warnings = warnings, errors = errors))
  }

  missing <- setdiff(explicit_refs, stems)
  if (length(missing) > 0) {
    warnings <- c(
      warnings,
      paste0(
        "Some articles referenced in `_pkgdown.yml` do not match files under `vignettes/`: ",
        paste(missing, collapse = ", "),
        ". If these are generated elsewhere or renamed, update `_pkgdown.yml` or the filenames."
      )
    )
  }

  list(warnings = warnings, errors = errors)
}

main <- function() {
  cli <- parse_cli_args(commandArgs(trailingOnly = TRUE))
  cfg_path <- cli$cfg_path
  template_mode <- cli$template_mode

  cfg_path_abs <- normalizePath(cfg_path, winslash = "/", mustWork = FALSE)
  root_dir <- normalizePath(dirname(cfg_path_abs), winslash = "/", mustWork = FALSE)

  warnings <- character()
  errors <- character()

  if (!file.exists(cfg_path_abs)) {
    stop(sprintf("Config file not found: %s", cfg_path), call. = FALSE)
  }

  cfg <- validate_yaml(cfg_path_abs)
  if (is.list(cfg) && !is.null(cfg$.error)) {
    errors <- c(errors, cfg$.error)
    cfg <- list()
  }

  res <- validate_repo_basics(root_dir, warnings, errors, template_mode = template_mode)
  warnings <- res$warnings
  errors <- res$errors

  res <- validate_url(cfg, warnings, errors)
  warnings <- res$warnings
  errors <- res$errors

  res <- validate_template(cfg, warnings, errors)
  warnings <- res$warnings
  errors <- res$errors

  res <- validate_navbar(cfg, warnings, errors)
  warnings <- res$warnings
  errors <- res$errors

  res <- validate_articles(root_dir, cfg, warnings, errors, template_mode = template_mode)
  warnings <- res$warnings
  errors <- res$errors

  cat("\n== pkgdown config validation ==\n")
  cat("Config:", cfg_path_abs, "\n")
  cat("Root:  ", root_dir, "\n\n")
  cat("Mode:  ", if (template_mode) "template" else "package", "\n\n")

  if (length(errors) > 0) {
    cat("Errors:\n")
    for (e in errors) cat("  - ", e, "\n", sep = "")
    cat("\n")
  }

  if (length(warnings) > 0) {
    cat("Warnings:\n")
    for (w in warnings) cat("  - ", w, "\n", sep = "")
    cat("\n")
  }

  if (length(errors) == 0) {
    cat("Result: OK\n")
    if (length(warnings) == 0) {
      cat("No warnings.\n")
    } else {
      cat("Warnings found. Review suggested.\n")
    }
    quit(status = 0)
  }

  cat("Result: FAILED (errors found)\n")
  quit(status = 1)
}

if (identical(environment(), globalenv())) {
  main()
}
