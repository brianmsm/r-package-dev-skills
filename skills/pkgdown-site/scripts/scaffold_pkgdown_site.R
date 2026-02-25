#!/usr/bin/env Rscript

defaults <- list(
  package_path = ".",
  template = "minimal",
  force = FALSE,
  create_index = TRUE,
  create_readme_template = TRUE,
  create_get_started = FALSE,
  create_web_only_article = FALSE,
  create_workflow_example = FALSE
)

as_bool <- function(x) {
  value <- tolower(trimws(x))
  if (value %in% c("true", "1", "yes", "y")) return(TRUE)
  if (value %in% c("false", "0", "no", "n")) return(FALSE)
  stop(sprintf("Invalid boolean value: %s", x), call. = FALSE)
}

print_usage <- function() {
  cat("Usage:\n")
  cat("  Rscript scaffold_pkgdown_site.R [options]\n\n")
  cat("Options:\n")
  cat("  --package-path=PATH\n")
  cat("  --template=minimal|articles-grouped\n")
  cat("  --force=true|false\n")
  cat("  --create-index=true|false\n")
  cat("  --create-readme-template=true|false\n")
  cat("  --create-get-started=true|false\n")
  cat("  --create-web-only-article=true|false\n")
  cat("  --create-workflow-example=true|false\n")
  cat("  --help\n")
}

parse_args <- function(args) {
  opts <- defaults
  for (arg in args) {
    if (arg == "--help") {
      print_usage()
      quit(status = 0L)
    }
    if (!startsWith(arg, "--") || !grepl("=", arg, fixed = TRUE)) {
      stop(sprintf("Invalid argument format: %s", arg), call. = FALSE)
    }
    parts <- strsplit(sub("^--", "", arg), "=", fixed = TRUE)[[1]]
    key <- gsub("-", "_", parts[[1]])
    value <- parts[[2]]

    if (key == "package_path") {
      opts$package_path <- value
    } else if (key == "template") {
      opts$template <- value
    } else if (key == "force") {
      opts$force <- as_bool(value)
    } else if (key == "create_index") {
      opts$create_index <- as_bool(value)
    } else if (key == "create_readme_template") {
      opts$create_readme_template <- as_bool(value)
    } else if (key == "create_get_started") {
      opts$create_get_started <- as_bool(value)
    } else if (key == "create_web_only_article") {
      opts$create_web_only_article <- as_bool(value)
    } else if (key == "create_workflow_example") {
      opts$create_workflow_example <- as_bool(value)
    } else {
      stop(sprintf("Unknown option: --%s", gsub("_", "-", key)), call. = FALSE)
    }
  }
  opts
}

get_script_dir <- function() {
  script_flag <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  if (length(script_flag) == 0L) {
    return(getwd())
  }
  script_path <- sub("^--file=", "", script_flag[[1]])
  dirname(normalizePath(script_path, winslash = "/", mustWork = FALSE))
}

read_package_name <- function(package_path) {
  desc_path <- file.path(package_path, "DESCRIPTION")
  if (!file.exists(desc_path)) return("REPO")
  desc <- tryCatch(read.dcf(desc_path), error = function(e) NULL)
  if (is.null(desc)) return("REPO")
  if (!"Package" %in% colnames(desc)) return("REPO")
  as.character(desc[1, "Package"])
}

render_template <- function(source_file, target_file, replacements, force = FALSE) {
  if (!file.exists(source_file)) {
    stop(sprintf("Template not found: %s", source_file), call. = FALSE)
  }

  if (file.exists(target_file) && !force) {
    cat(sprintf("[SKIP] %s already exists\n", target_file))
    return(FALSE)
  }

  content <- readLines(source_file, warn = FALSE)
  for (token in names(replacements)) {
    content <- gsub(token, replacements[[token]], content, fixed = TRUE)
  }

  dir.create(dirname(target_file), recursive = TRUE, showWarnings = FALSE)
  writeLines(content, con = target_file)
  cat(sprintf("[CREATE] %s\n", target_file))
  TRUE
}

opts <- parse_args(commandArgs(trailingOnly = TRUE))

if (!opts$template %in% c("minimal", "articles-grouped")) {
  stop("template must be 'minimal' or 'articles-grouped'.", call. = FALSE)
}

package_path <- normalizePath(opts$package_path, winslash = "/", mustWork = FALSE)
if (!dir.exists(package_path)) {
  stop(sprintf("Package path does not exist: %s", package_path), call. = FALSE)
}

script_dir <- get_script_dir()
template_dir <- file.path(script_dir, "..", "assets", "templates")
example_dir <- file.path(script_dir, "..", "assets", "examples")

template_file <- if (opts$template == "minimal") {
  "_pkgdown-minimal.yml"
} else {
  "_pkgdown-articles-grouped.yml"
}

package_name <- read_package_name(package_path)
replacements <- c("REPO" = package_name)

cat("pkgdown scaffold\n")
cat(sprintf("Package path: %s\n", package_path))
cat(sprintf("Template mode: %s\n\n", opts$template))

created <- character()

if (render_template(
  source_file = file.path(template_dir, template_file),
  target_file = file.path(package_path, "_pkgdown.yml"),
  replacements = replacements,
  force = opts$force
)) {
  created <- c(created, "_pkgdown.yml")
}

if (opts$create_index && render_template(
  source_file = file.path(template_dir, "index.md"),
  target_file = file.path(package_path, "pkgdown", "index.md"),
  replacements = replacements,
  force = opts$force
)) {
  created <- c(created, "pkgdown/index.md")
}

if (opts$create_readme_template && render_template(
  source_file = file.path(template_dir, "README-lean-template.md"),
  target_file = file.path(package_path, "README-lean-template.md"),
  replacements = replacements,
  force = opts$force
)) {
  created <- c(created, "README-lean-template.md")
}

if (opts$create_get_started && render_template(
  source_file = file.path(template_dir, "get-started.qmd"),
  target_file = file.path(package_path, "vignettes", "get-started.qmd"),
  replacements = replacements,
  force = opts$force
)) {
  created <- c(created, "vignettes/get-started.qmd")
}

if (opts$create_web_only_article && render_template(
  source_file = file.path(template_dir, "article-web-only.qmd"),
  target_file = file.path(package_path, "vignettes", "articles", "article-web-only.qmd"),
  replacements = replacements,
  force = opts$force
)) {
  created <- c(created, "vignettes/articles/article-web-only.qmd")
}

if (opts$create_workflow_example && render_template(
  source_file = file.path(example_dir, "pkgdown-gha.yaml"),
  target_file = file.path(package_path, ".github", "workflows", "pkgdown.yaml"),
  replacements = replacements,
  force = opts$force
)) {
  created <- c(created, ".github/workflows/pkgdown.yaml")
}

cat("\nSummary\n")
if (length(created) == 0L) {
  cat("- No files created.\n")
} else {
  for (item in created) {
    cat(sprintf("- Created: %s\n", item))
  }
}

cat("\nNext steps\n")
cat("1. Review _pkgdown.yml and replace placeholder ORG in URL and GitHub links.\n")
cat("2. Build locally with pkgdown::build_site().\n")
cat("3. If needed, run usethis::use_pkgdown_github_pages() to wire CI deployment.\n")
