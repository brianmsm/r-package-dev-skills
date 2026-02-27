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
#   Rscript scripts/validate_pkgdown_config.R path/to/_pkgdown.yml --strict
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
  cat("  Rscript scripts/validate_pkgdown_config.R --strict\n")
}

parse_cli_args <- function(args) {
  cfg_path <- "_pkgdown.yml"
  cfg_set <- FALSE
  template_mode <- FALSE
  strict_mode <- FALSE

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

    if (arg == "--strict") {
      strict_mode <- TRUE
      next
    }

    if (grepl("^--strict=", arg)) {
      strict_mode <- as_bool(sub("^--strict=", "", arg))
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

  list(cfg_path = cfg_path, template_mode = template_mode, strict_mode = strict_mode)
}

as_chr <- function(x) {
  if (is.null(x)) return(character())
  if (is.character(x)) return(x)
  if (is.list(x)) return(unlist(x, use.names = FALSE))
  character()
}

is_yaml_mapping <- function(x) {
  is.list(x) && !is.null(names(x)) && length(x) > 0
}

as_warning_list <- function(x) {
  if (is.null(x)) return(list())
  if (is.list(x)) return(x)
  if (is.character(x)) {
    # Backward-compatible conversion: treat plain strings as non-strict warnings.
    return(lapply(x, function(msg) list(code = "legacy", message = msg, strict = FALSE)))
  }
  stop("Internal error: warnings must be a list.", call. = FALSE)
}

strict_warning_codes <- c(
  "url_missing",
  "url_not_http",
  "url_multiple",
  "home_missing",
  "template_not_mapping",
  "navbar_not_mapping",
  "navbar_structure_not_mapping",
  "navbar_components_not_mapping",
  "articles_not_sections",
  "vignettes_missing_explicit",
  "vignettes_missing_selectors",
  "articles_explicit_missing_files",
  "vignettes_empty_selectors",
  "articles_selectors_no_match"
)

is_strict_warning_code <- function(code) {
  is.character(code) && length(code) == 1 && code %in% strict_warning_codes
}

new_warning <- function(code, message) {
  list(
    code = as.character(code),
    message = as.character(message),
    strict = is_strict_warning_code(code)
  )
}

add_warning <- function(warnings, code, message) {
  warnings <- as_warning_list(warnings)
  warnings[[length(warnings) + 1L]] <- new_warning(code = code, message = message)
  warnings
}

warning_messages <- function(warnings) {
  warnings <- as_warning_list(warnings)
  vapply(warnings, function(w) as.character(w$message), character(1))
}

as_scalar_text <- function(x) {
  vals <- as_chr(x)
  vals <- vals[!is.na(vals)]
  if (length(vals) == 0) return("")
  trimws(as.character(vals[[1]]))
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
    full.names = FALSE
  )
  files <- files[grepl("\\.(Rmd|qmd|md)$", files, ignore.case = TRUE)]
  if (length(files) == 0) return(character())

  rel <- gsub("\\\\", "/", files)
  rel <- sub("^\\./", "", rel)
  stems <- sub("\\.[^.]+$", "", rel)
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
    warnings <- add_warning(
      warnings,
      "home_missing",
      "No pkgdown home source found (pkgdown/index.md, index.md, or README.md). The site home may be empty or default."
    )
  }

  list(warnings = warnings, errors = errors)
}

validate_url <- function(cfg, warnings, errors) {
  url <- cfg$url
  url_vals <- as_chr(url)
  url_vals <- url_vals[!is.na(url_vals)]

  if (length(url_vals) == 0 || !nzchar(trimws(url_vals[[1]]))) {
    warnings <- add_warning(
      warnings,
      "url_missing",
      "No `url:` found in _pkgdown.yml. Internal links may be less reliable, and the site URL will not be explicit."
    )
    return(list(warnings = warnings, errors = errors))
  }

  url_scalar <- trimws(as.character(url_vals[[1]]))
  if (!is_http_url(url_scalar)) {
    warnings <- add_warning(
      warnings,
      "url_not_http",
      sprintf("`url` does not look like an http(s) URL: %s", url_scalar)
    )
  }

  if (length(url_vals) > 1) {
    warnings <- add_warning(
      warnings,
      "url_multiple",
      "`url` has multiple values; expected a single scalar string."
    )
  }

  list(warnings = warnings, errors = errors)
}

validate_template <- function(cfg, warnings, errors) {
  tmpl <- cfg$template
  if (is.null(tmpl)) return(list(warnings = warnings, errors = errors))

  if (!is.list(tmpl)) {
    warnings <- add_warning(
      warnings,
      "template_not_mapping",
      "`template:` is present but not a mapping/list. Check YAML indentation."
    )
    return(list(warnings = warnings, errors = errors))
  }

  if (!is.null(tmpl$bootstrap)) {
    bs <- as.character(tmpl$bootstrap[[1]])
    if (nzchar(bs) && bs != "5") {
      warnings <- add_warning(
        warnings,
        "bootstrap_not_5",
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
    warnings <- add_warning(
      warnings,
      "navbar_not_mapping",
      "`navbar:` is present but not a mapping/list. Check YAML indentation."
    )
    return(list(warnings = warnings, errors = errors))
  }

  structure <- nb$structure
  if (is.null(structure)) {
    warnings <- add_warning(
      warnings,
      "navbar_structure_missing",
      "navbar.structure is missing. pkgdown will use defaults, but customization may not apply."
    )
    return(list(warnings = warnings, errors = errors))
  }

  if (!is.list(structure)) {
    warnings <- add_warning(
      warnings,
      "navbar_structure_not_mapping",
      "navbar.structure is not a mapping/list. Check YAML indentation."
    )
    return(list(warnings = warnings, errors = errors))
  }

  left <- as_chr(structure$left)
  right <- as_chr(structure$right)

  if (length(left) == 0 && length(right) == 0) {
    warnings <- add_warning(
      warnings,
      "navbar_structure_empty",
      "navbar.structure.left and navbar.structure.right are empty. Did you intend that?"
    )
  }

  known <- c("home", "intro", "reference", "articles", "tutorials", "news", "search", "github")
  all_items <- unique(c(left, right))
  unknown <- setdiff(all_items, known)
  if (length(unknown) > 0) {
    warnings <- add_warning(
      warnings,
      "navbar_unknown_components",
      paste0(
        "navbar.structure contains unknown components: ",
        paste(unknown, collapse = ", "),
        ". This may be fine if you define matching navbar.components entries."
      )
    )
  }

  comps <- nb$components
  if (!is.null(comps) && !is.list(comps)) {
    warnings <- add_warning(
      warnings,
      "navbar_components_not_mapping",
      "navbar.components is present but not a mapping/list. Check YAML indentation."
    )
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

extract_articles_section_info <- function(articles_cfg) {
  if (is.null(articles_cfg) || !is.list(articles_cfg)) return(list())

  out <- list()
  for (i in seq_along(articles_cfg)) {
    section <- articles_cfg[[i]]
    if (!is.list(section)) next
    contents <- section$contents
    if (is.null(contents)) next

    vals <- as_chr(contents)
    vals <- vals[!is.na(vals) & nzchar(vals)]
    if (length(vals) == 0) next

    selectors <- vals[vapply(vals, is_selector_expr, logical(1))]
    explicit <- vals[!vapply(vals, is_selector_expr, logical(1))]

    label <- as_scalar_text(section$title)
    if (!nzchar(label)) label <- as_scalar_text(section$navbar)
    if (!nzchar(label)) label <- paste0("articles section #", i)

    out[[length(out) + 1]] <- list(
      label = label,
      selectors = selectors,
      explicit = explicit
    )
  }

  out
}

parse_simple_selector <- function(expr) {
  if (!is.character(expr) || length(expr) != 1) return(NULL)

  raw <- trimws(expr)
  if (!nzchar(raw)) return(NULL)

  negative <- FALSE
  if (startsWith(raw, "-")) {
    negative <- TRUE
    raw <- trimws(sub("^-", "", raw))
  }

  m <- regexec("^([A-Za-z_][A-Za-z0-9_]*)\\s*\\((.*)\\)\\s*$", raw)
  parts <- regmatches(raw, m)[[1]]
  if (length(parts) < 3) return(NULL)

  fn <- parts[[2]]
  args <- parts[[3]]

  if (!fn %in% c("starts_with", "ends_with", "matches", "contains")) return(NULL)

  # Simple parser: captures the first quoted string in the selector args.
  # Limitations:
  # - Does not handle escaped quotes inside the string.
  # - Will skip validation for selectors that don't match this pattern.
  q <- regexec("(['\"])(.*?)\\1", args)
  qparts <- regmatches(args, q)[[1]]
  if (length(qparts) < 3) return(NULL)

  parse_bool_flag <- function(arg_str, name) {
    rx <- paste0("\\b", name, "\\s*=\\s*(TRUE|FALSE)\\b")
    m <- regexec(rx, arg_str, ignore.case = TRUE)
    parts <- regmatches(arg_str, m)[[1]]
    if (length(parts) < 2) return(NA)
    identical(toupper(parts[[2]]), "TRUE")
  }

  ignore_case <- parse_bool_flag(args, "ignore\\.case")
  perl <- if (identical(fn, "matches")) parse_bool_flag(args, "perl") else NA

  list(
    negative = negative,
    fn = fn,
    pattern = qparts[[3]],
    ignore_case = ignore_case,
    perl = perl,
    raw = expr
  )
}

simple_selector_matches_any <- function(sel, stems) {
  if (is.null(sel) || isTRUE(sel$negative)) return(FALSE)
  if (!is.character(stems) || length(stems) == 0) return(FALSE)

  pat <- sel$pattern
  if (!nzchar(pat)) return(FALSE)

  # pkgdown `articles:` selectors are tidyselect-like. tidyselect defaults to
  # ignore.case = TRUE for these helpers unless explicitly overridden.
  ignore_case <- if (isTRUE(sel$ignore_case) || identical(sel$ignore_case, FALSE)) {
    sel$ignore_case
  } else {
    TRUE
  }

  stems_cmp <- stems
  pat_cmp <- pat
  if (isTRUE(ignore_case)) {
    stems_cmp <- tolower(stems)
    pat_cmp <- tolower(pat)
  }

  safe_any_grepl <- function(pattern, x, ...) {
    tryCatch(any(grepl(pattern, x, ...)), error = function(e) FALSE)
  }

  switch(
    sel$fn,
    starts_with = any(startsWith(stems_cmp, pat_cmp)),
    ends_with = any(endsWith(stems_cmp, pat_cmp)),
    # Base R ignores ignore.case when fixed = TRUE, so we compare pre-normalized
    # strings instead of relying on grepl(ignore.case=...).
    contains = safe_any_grepl(pat_cmp, stems_cmp, fixed = TRUE),
    matches = {
      perl <- if (isTRUE(sel$perl) || identical(sel$perl, FALSE)) sel$perl else FALSE
      safe_any_grepl(pat, stems, ignore.case = isTRUE(ignore_case), perl = perl)
    },
    FALSE
  )
}

validate_articles <- function(root_dir, cfg, warnings, errors, template_mode = FALSE) {
  articles_cfg <- cfg$articles
  if (is.null(articles_cfg)) return(list(warnings = warnings, errors = errors))

  if (!is.list(articles_cfg)) {
    warnings <- add_warning(
      warnings,
      "articles_not_sections",
      "`articles:` is present but not a list of sections. Check YAML indentation."
    )
    return(list(warnings = warnings, errors = errors))
  }

  vignettes_dir <- file.path(root_dir, "vignettes")
  stems <- collect_vignette_stems(vignettes_dir)
  explicit_refs <- extract_explicit_article_refs(articles_cfg)
  sections <- extract_articles_section_info(articles_cfg)
  has_selectors <- any(vapply(sections, function(x) length(x$selectors) > 0, logical(1)))

  if (!dir.exists(vignettes_dir)) {
    if (isTRUE(template_mode)) {
      return(list(warnings = warnings, errors = errors))
    }
    if (length(explicit_refs) > 0) {
      warnings <- add_warning(
        warnings,
        "vignettes_missing_explicit",
        "vignettes/ directory does not exist, but explicit articles are listed in `_pkgdown.yml`."
      )
    }
    if (has_selectors) {
      warnings <- add_warning(
        warnings,
        "vignettes_missing_selectors",
        "vignettes/ directory does not exist, but `_pkgdown.yml` defines `articles:` selector expressions."
      )
    }
    return(list(warnings = warnings, errors = errors))
  }

  if (length(explicit_refs) > 0) {
    missing <- setdiff(explicit_refs, stems)
    if (length(missing) > 0) {
      warnings <- add_warning(
        warnings,
        "articles_explicit_missing_files",
        paste0(
          "Some articles referenced in `_pkgdown.yml` do not match files under `vignettes/`: ",
          paste(missing, collapse = ", "),
          ". If these are generated elsewhere or renamed, update `_pkgdown.yml` or the filenames."
        )
      )
    }
  }

  if (!isTRUE(template_mode)) {
    if (has_selectors && length(stems) == 0) {
      warnings <- add_warning(
        warnings,
        "vignettes_empty_selectors",
        "No vignette/article sources found under `vignettes/`, but `_pkgdown.yml` defines `articles:` selectors. Articles groups may be empty."
      )
    }

    for (sec in sections) {
      if (length(sec$selectors) == 0) next
      if (length(sec$explicit) > 0) next

      parsed <- lapply(sec$selectors, parse_simple_selector)
      parsed <- parsed[!vapply(parsed, is.null, logical(1))]
      parsed <- parsed[!vapply(parsed, function(x) isTRUE(x$negative), logical(1))]
      if (length(parsed) == 0) next

      if (!any(vapply(parsed, simple_selector_matches_any, logical(1), stems = stems))) {
        warnings <- add_warning(
          warnings,
          "articles_selectors_no_match",
          paste0(
            "No vignette/article matched selector(s) for `articles:` ",
            sec$label,
            ". Check `articles:` contents patterns or filenames under `vignettes/`."
          )
        )
      }
    }
  }

  list(warnings = warnings, errors = errors)
}

## Strict promotion is based on warning codes (see strict_warning_codes).

main <- function() {
  cli <- parse_cli_args(commandArgs(trailingOnly = TRUE))
  cfg_path <- cli$cfg_path
  template_mode <- cli$template_mode
  strict_mode <- cli$strict_mode

  cfg_path_abs <- normalizePath(cfg_path, winslash = "/", mustWork = FALSE)
  root_dir <- normalizePath(dirname(cfg_path_abs), winslash = "/", mustWork = FALSE)

  warnings <- list()
  errors <- character()

  if (!file.exists(cfg_path_abs)) {
    stop(sprintf("Config file not found: %s", cfg_path), call. = FALSE)
  }

  cfg_ok <- TRUE
  cfg <- validate_yaml(cfg_path_abs)
  if (is.list(cfg) && !is.null(cfg$.error)) {
    errors <- c(errors, cfg$.error)
    cfg <- list()
    cfg_ok <- FALSE
  }
  if (isTRUE(cfg_ok) && !is_yaml_mapping(cfg)) {
    errors <- c(
      errors,
      "Invalid _pkgdown.yml root. Expected a YAML mapping (key: value), e.g. `url: https://.../`."
    )
    cfg_ok <- FALSE
    cfg <- list()
  }

  res <- validate_repo_basics(root_dir, warnings, errors, template_mode = template_mode)
  warnings <- res$warnings
  errors <- res$errors

  if (isTRUE(cfg_ok)) {
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
  }

  if (isTRUE(strict_mode) && length(warnings) > 0) {
    strict_idx <- vapply(warnings, function(w) isTRUE(w$strict), logical(1))
    if (any(strict_idx)) {
      errors <- c(errors, paste0("[strict] ", warning_messages(warnings[strict_idx])))
      warnings <- warnings[!strict_idx]
    }
  }

  cat("\n== pkgdown config validation ==\n")
  cat("Config:", cfg_path_abs, "\n")
  cat("Root:  ", root_dir, "\n\n")
  cat("Mode:  ", if (template_mode) "template" else "package", "\n\n")
  cat("Strict:", if (strict_mode) "ON" else "OFF", "\n\n")

  if (length(errors) > 0) {
    cat("Errors:\n")
    for (e in errors) cat("  - ", e, "\n", sep = "")
    cat("\n")
  }

  if (length(warnings) > 0) {
    cat("Warnings:\n")
    for (w in warning_messages(warnings)) cat("  - ", w, "\n", sep = "")
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
