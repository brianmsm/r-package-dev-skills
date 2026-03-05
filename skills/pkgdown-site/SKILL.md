---
name: pkgdown-site
description: "End-to-end pkgdown workflow for R packages: setup, publishing, content architecture, articles/vignettes, README migration, troubleshooting, and maintenance scripts."
---

# Skill: pkgdown-site

## Purpose

Use this skill to build or improve `pkgdown` websites in a way that matches package maturity.

This skill focuses on:

- initial setup and deployment
- practical content architecture
- `_pkgdown.yml` structure and navigation
- troubleshooting failed or empty deploys
- progressive documentation for packages in active development

## When To Use This Skill

Activate this skill when the user asks for any of the following:

- "Set up pkgdown for my package"
- "Publish docs with GitHub Pages"
- "My README is too large"
- "I need a better docs structure"
- "I want articles, get started, and reference navigation"
- "My pkgdown deploy is broken or empty"

Also activate it when repository clues include:

- `_pkgdown.yml`
- `.github/workflows/pkgdown.yaml`
- explicit requests to improve package documentation architecture

## When Not To Use This Skill

Do not use this skill when:

- the task is only function-level roxygen documentation
- the user wants a non-package website platform
- the issue is CI/testing unrelated to pkgdown
- the user only asks for prose rewriting without structural changes

## Working Principles

1. Treat README as a quick entry point, not a full manual.
2. Separate content by purpose: README, home, reference, articles, news.
3. Use progressive documentation for packages that are still changing.
4. Prefer standard `usethis` setup and deployment paths.
5. Validate locally before discussing CI or GitHub Pages failures.

## Recommended Default (If Unspecified)

If the user does not specify a publishing preference, default to:

- Deploy via a `gh-pages` branch from CI (keeps built output out of the default branch).
- Use the workflow template: `assets/examples/pkgdown-gha.yaml`.

Use alternatives only when explicitly requested or when constraints require them:

- Publish from `/docs` on the default branch (branch source in Pages): `assets/examples/pkgdown-gha-docs-branch.yaml`.
- Publish via GitHub Pages "Source: GitHub Actions" (artifact deploy): `assets/examples/pkgdown-gha-pages-artifact.yaml`.

If the user does not specify an article/vignette source format, default to `--format auto` in `scripts/scaffold_pkgdown_site.R`:

- If the target repo shows any `.Rmd` usage (for example `vignettes/*.Rmd`, `README.Rmd`, `index.Rmd`, or any other `.Rmd`), prefer `.Rmd`.
- Otherwise, default to `.qmd` (Quarto).

Do not auto-convert between formats as part of the default workflow.

### Additional Tie-breakers (Defaults When Unspecified)

- Home location: Default to `index.md` at repository root for the pkgdown home. Use `pkgdown/index.md` only if the user explicitly wants a "website-only" home page and prefers not to place `index.md` at repo root.
- README strategy: Default to keep `README.md` as a lean quick-start hub for GitHub and move long-form docs to the pkgdown home (`index.md`/`pkgdown/index.md`) and articles. Do not rewrite or shorten the README unless it is already long and hard to scan, or the user explicitly requests a lean README migration.
- CI strictness: For exploratory/local checks and PRs, run `scripts/validate_pkgdown_config.R` without `--strict`. For deploy/push/release gating, enable `--strict`. Note: `--strict` promotes only warnings flagged as strict (it does not turn every warning into an error).
- Pages source: Default to branch-based Pages publishing to `gh-pages`. If the user explicitly wants to avoid a `gh-pages` branch and also avoid committing rendered output to the default branch, prefer Pages Source: GitHub Actions (artifact deploy).
- Theme customization: Default to no theme changes unless the user asks. If the user asks "make it nicer" without specifics, start with a Bootswatch theme (low-friction) and keep Bootstrap 5.
- Workflow example copying: use `--create-workflow-example` to copy an example workflow into `.github/workflows/pkgdown.yaml`. Default is `gh-pages`; select a different template with `--workflow-template gh-pages|docs-branch|pages-artifact`.

## Inputs To Collect (Minimum)

Before making changes, collect:

- Target repository path (package root).
- Publishing pattern:
  - deploy built site output to `gh-pages` (recommended default for pkgdown), or
  - publish from default branch `/docs`.
- Workflow templates (choose one): `assets/examples/pkgdown-gha.yaml` (deploy to `gh-pages`), `assets/examples/pkgdown-gha-docs-branch.yaml` (publish from `/docs` on the default branch), `assets/examples/pkgdown-gha-pages-artifact.yaml` (Pages "Source: GitHub Actions").
- Whether the project uses Quarto (`.qmd`) for articles/vignettes.
- README strategy: keep as-is vs make it lean (and where long-form docs should live).

## Helper Scripts (Deterministic)

Prefer these scripts for repeatable checks, scaffolding, and troubleshooting:

- `scripts/check_pkgdown_ready.R`: quick "is this repo ready?" report (non-destructive).
- `scripts/validate_pkgdown_config.R`: validate `_pkgdown.yml` structure and common repo pitfalls.
- `scripts/scaffold_pkgdown_site.R`: create `_pkgdown.yml`, `index.md`, and optional articles from templates (safe by default).
- `scripts/clean_and_build.R`: rebuild helper to avoid stale artifacts after renames/removals.
- `scripts/check_pkgdown_builtin.R`: run pkgdown-native diagnostics (`check_pkgdown()`, `pkgdown_sitrep()`).
- `scripts/check_tutorial_urls.R`: validate tutorial URLs when `tutorials:` is configured.
- `scripts/setup_favicons.R`: favicon helper (may require internet access).

Example usage (recommended: run from the target package root, where `DESCRIPTION` exists):

- `Rscript scripts/check_pkgdown_ready.R .`
- `Rscript scripts/validate_pkgdown_config.R _pkgdown.yml --strict`
- `Rscript scripts/scaffold_pkgdown_site.R --target . --pkg <pkg> --org <org> --repo <repo>`

Example usage (run skill scripts directly, passing explicit paths):

- `Rscript <path-to-skill>/scripts/check_pkgdown_ready.R /path/to/package/root`
- `Rscript <path-to-skill>/scripts/validate_pkgdown_config.R /path/to/package/_pkgdown.yml --strict`
- `Rscript <path-to-skill>/scripts/scaffold_pkgdown_site.R --target /path/to/package/root --pkg <pkg> --org <org> --repo <repo>`

The skill directory is the folder that contains this SKILL.md file.

Example (this repository): `<path-to-skill>` is `skills/pkgdown-site`.

## Template Placeholders

Templates use `{snake_case}` placeholders (for example `{domain}`, `{modules_list}`, `{primary_capability}`).
After scaffolding, the scaffolder reports any unresolved placeholders so they can be replaced before publishing.

## Standard Workflow

### 1. Initial Setup

1. Confirm package basics: `DESCRIPTION`, `NAMESPACE`, and installable dependencies.
2. Set up site scaffolding:
   - `usethis::use_pkgdown()`, or
   - `usethis::use_pkgdown_github_pages()` (recommended default).
3. Confirm `_pkgdown.yml` and workflow files are committed to the default branch.
4. Run a local build.
5. Confirm published site settings in GitHub Pages.

### 2. Existing Package With Docs Debt

1. Audit `README.md` and long markdown files.
2. Decide what stays in README versus site home versus articles.
3. Add `index.md` when README is oversized.
4. Add articles and tune navbar structure.
5. Rebuild locally and verify links.

### 3. Ongoing Maintenance

1. Keep navbar and article naming consistent.
2. Remove duplicate content across README and home.
3. Resolve deploy failures quickly with focused diagnostics.
4. Recheck architecture as package scope grows.

## Quick Decision Tree

### Case: Huge README, no vignettes

- Set up pkgdown now.
- Keep README lean for GitHub.
- Move structure and roadmap to `index.md`.
- Start with website-only articles using `use_article()`.
- Postpone formal vignettes until API stabilizes.

### Case: Need "Get started"

- Create one guided "happy path" document first.
- Keep it short and stable.
- Move advanced paths to separate articles.

### Case: Confusion around `gh-pages`

- Explain that `gh-pages` stores rendered site output.
- Verify workflow, Pages settings, and branch permissions.

### Case: Navbar and structure customization

- Edit `_pkgdown.yml`.
- Validate YAML before build.
- Rebuild and inspect navigation output.

## File Routing Inside This Skill

Open only what is needed:

- setup and deployment: `references/pkgdown-flow.md`
- content split and doc ownership: `references/content-architecture.md`
- active-development strategy: `references/package-in-growth.md`
- deploy and build failures: `references/troubleshooting.md`
- learnr/tutorial embedding strategy: `references/tutorials.md`
- theming/layout/assets customization: `references/customization.md`
- patterns, naming, and scalable doc sets: `references/examples-notes.md`

## Package In Growth Module

If the package is actively evolving and the README is oversized, follow the playbook in
`references/package-in-growth.md` (lean README -> index.md -> web-only articles -> stable vignettes).

## Execution Protocol

Follow this order when skill is active:

1. Run minimal repository diagnosis against the target package root (prefer `scripts/check_pkgdown_ready.R`).
2. Classify package state.
3. Select work path: setup, reorg, troubleshooting, or maintenance.
4. Read only relevant reference files.
5. Provide a short plan before edits.
6. Implement requested changes.
7. Verify build, links, and content boundaries.

## Expected Outputs

Produce one or more of:

- repository diagnosis
- concrete implementation plan
- direct file edits
- troubleshooting findings with verified fixes
- copy-ready templates
- clear final checklist

Avoid vague outputs that are disconnected from repository state.

## Final Checklist

- [ ] README and site home have distinct roles.
- [ ] Content architecture fits package maturity.
- [ ] Article versus vignette choice is explicit.
- [ ] `_pkgdown.yml` is valid and readable.
- [ ] Deploy path is clear and testable.
- [ ] Output is actionable, not only conceptual.
