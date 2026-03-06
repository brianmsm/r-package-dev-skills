# pkgdown Troubleshooting

This reference is a practical checklist of common pkgdown failures and how to diagnose and fix them. It focuses on issues that typically occur when building or publishing a pkgdown site with GitHub Pages and GitHub Actions.

Use this file when:

- the site is not updating
- you get a 404
- the deploy is empty
- the navbar breaks
- articles do not appear
- CI succeeds locally but fails in GitHub Actions

## Quick Triage: Identify the Failure Class

### 1) Build failure

Symptoms:

- `pkgdown::build_site()` fails locally
- CI build step fails with R errors

Likely causes:

- missing R package dependencies
- invalid YAML
- broken vignette or article build
- missing system libraries

Start with:

- run local build
- validate `_pkgdown.yml`
- check vignette and article sources under `vignettes/`

### 2) Deploy failure

Symptoms:

- build succeeds but site is not published
- `gh-pages` branch not updated
- GitHub Pages shows 404

Likely causes:

- workflow permissions insufficient
- GitHub Pages source misconfigured
- wrong deploy folder (for example `docs` missing)
- deploy step not running (PR builds only)

Start with:

- check Actions run logs
- check Pages settings
- confirm deploy step condition

### 3) Wrong-content failure

Symptoms:

- home page is not what you expect
- navbar not showing your changes
- older content persists

Likely causes:

- pkgdown is using a different home source
- browser or Pages caching
- multiple competing files (`README.md`, `index.md`, `pkgdown/index.md`)
- stale markdown generated from `README.Rmd` or `index.Rmd`

Start with:

- identify which file is used for home
- confirm latest deploy run completed
- if you edit `README.Rmd` or `index.Rmd`, confirm the corresponding `.md` is up to date

## Build Problems

### Symptom: `_pkgdown.yml` YAML parse error

Typical messages:

- mapping values are not allowed here
- did not find expected key
- found character that cannot start any token

Likely causes:

- indentation error
- tabs instead of spaces
- unquoted colon in text
- mixed list and mapping structure

Checks:

- validate YAML with parser (`yaml::yaml.load_file("_pkgdown.yml")`)
- confirm consistent indentation (2 spaces is typical)
- ensure lists use `- item` correctly

Fix:

- correct indentation and list structure
- quote strings with `:` or special characters

### Symptom: Reference pages missing or incomplete

Likely causes:

- functions not documented with roxygen2
- `devtools::document()` not run
- exports not set (`@export` missing)

Checks:

- `.Rd` files exist in `man/`
- `NAMESPACE` includes expected exports

Fix:

- run `devtools::document()`
- ensure exported functions use roxygen `@export`
- rebuild site

### Symptom: Home page is empty or not found

Likely causes:

- no home source exists
- home source exists but is invalid markdown

Checks:

- one of the following exists:
- `pkgdown/index.md`
- `index.md`
- `README.md`

Fix:

- create `index.md` (recommended for growing package)
- rebuild

### Symptom: Home page does not reflect changes when you edit README.Rmd or index.Rmd

Likely causes:

- pkgdown does not knit home-page `.Rmd` sources
- `README.md` / `index.md` is stale relative to the `.Rmd`

Checks:

- do you edit `README.Rmd` but the site uses `README.md`?
- do you edit `index.Rmd` but the site uses `index.md`?
- compare `git diff` and file timestamps for the `.md`

Fix:

- knit/render `README.Rmd` -> `README.md`
- knit/render `index.Rmd` -> `index.md`
- rebuild and redeploy

### Symptom: Images are missing on the home page (README/index)

Likely causes:

- images are not stored inside the package sources
- image paths are not valid in the pkgdown build context

Checks:

- are images referenced with stable relative paths?
- are README images stored in `man/figures/` (recommended)?
- if you generate figures via R Markdown, is `fig.path` set to `man/figures/`?

Fix:

- move images under `man/figures/` and update paths
- set `knitr::opts_chunk$set(fig.path = \"man/figures/\")` for generated figures
- rebuild and redeploy

### Symptom: Articles do not show up

Likely causes:

- no `.Rmd`/`.qmd` sources in `vignettes/`
- `_pkgdown.yml` `articles:` selectors or names do not match file stems
- Quarto not installed (for `.qmd`)
- vignette build fails and output is skipped

Checks:

- list files in `vignettes/`
- compare file stems to `_pkgdown.yml` `articles:` `contents`
- example: `vignettes/workflows-cfa.qmd` -> `workflows-cfa`
- build locally and inspect warnings

Fix:

- add article sources under `vignettes/`
- update `_pkgdown.yml` contents to match stems
- install Quarto or configure CI to install it

### Symptom: Quarto `.qmd` renders locally but fails in CI

Likely causes:

- Quarto not installed in CI
- missing Pandoc
- missing external system dependencies

Checks:

- CI logs include `quarto: command not found`
- workflow includes Pandoc setup and Quarto installation path

Fix:

- install Quarto in CI (or enable `install-quarto` in dependency step)
- ensure `setup-pandoc` is present
- add missing system dependencies if required

### Symptom: Favicon generation fails

Likely causes:

- no detectable package logo (`logo.svg`/`logo.png` or `man/figures/logo.*`)
- no internet access for `build_favicons()`
- existing `pkgdown/favicon` and no overwrite

Checks:

- verify logo file exists in a pkgdown-detected location
- confirm network access is available
- if output exists, rerun with overwrite

Fix:

- add a logo and rerun `pkgdown::build_favicons(overwrite = TRUE)`
- or use `scripts/setup_favicons.R --overwrite`
- add `^pkgdown$` to `.Rbuildignore` to avoid `R CMD check` notes

### Symptom: Site builds but looks unstyled or layout is broken

Likely causes:

- template misconfiguration
- custom CSS references wrong paths
- browser caching

Checks:

- remove custom overrides temporarily
- hard refresh browser
- check generated HTML asset paths

Fix:

- start from minimal `_pkgdown.yml` and reintroduce customization gradually
- ensure custom assets are in correct locations

## Deploy and GitHub Pages Problems

### Symptom: GitHub Pages shows 404

Likely causes:

- Pages source not configured
- site published to different URL than expected
- deploy step not running
- `gh-pages` missing or empty

Checks:

- repository Settings -> Pages source is correct:
- `gh-pages` and `/ (root)` for Pattern A, or
- default branch and `/docs` for Pattern B
- latest Actions run succeeded
- `gh-pages` contains site files

Fix:

- correct Pages source
- trigger deploy by pushing to default branch
- ensure workflow has `contents: write`

### Symptom: `gh-pages` exists but has no website files

Likely causes:

- deploy step did not run
- workflow lacks permission to push
- deploy folder not found (`docs/` not created)

Checks:

- Actions logs show Build step and Deploy step status
- Deploy skipped due to PR condition
- `docs/` exists at end of build step

Fix:

- ensure deploy step runs on pushes to default branch
- ensure job has `permissions: contents: write`
- ensure build outputs to `docs/` (or adjust deploy folder)

### Symptom: Site does not update after push

Likely causes:

- build did not run
- build ran but deploy failed
- cache delay (Pages/browser)
- pushed to branch not watched by workflow

Checks:

- Actions tab has a run for latest push
- compare source commit SHA with latest `gh-pages` commit
- hard refresh or test in private window

Fix:

- ensure workflow triggers on active default branch
- fix deploy failures
- wait briefly, then refresh

### Symptom: Removed or renamed pages still appear

Likely causes:

- stale files remain in rendered site output
- routes changed but old artifacts were never cleaned

Checks:

- confirm file was actually renamed/removed in source
- inspect generated output for old HTML paths

Fix:

- run `pkgdown::clean_site()` then rebuild
- or use `scripts/clean_and_build.R` for a clean rebuild

### Symptom: Custom domain or CNAME issues

Likely causes:

- `CNAME` not present or overwritten
- Pages domain not configured

Checks:

- `gh-pages` includes `CNAME`
- domain configured in Pages settings

Fix:

- configure domain in Pages settings
- ensure workflow preserves or writes `CNAME`

## Wrong Content and Configuration Confusion

### Symptom: Home page content is not expected

Likely causes:

- multiple home candidates exist and a higher-priority one is used
- you edited README while site uses `index.md` or `pkgdown/index.md`

Checks:

- does `pkgdown/index.md` exist
- does root `index.md` exist
- does `README.md` exist

Fix:

- decide one authoritative home source
- remove or align competing sources
- rebuild and redeploy

### Symptom: Navbar changes are ignored

Likely causes:

- editing wrong branch (for example `gh-pages` instead of default branch)
- YAML invalid and defaults applied
- caching

Checks:

- changes committed on default/source branch
- `_pkgdown.yml` validates
- site rebuild and redeploy completed

Fix:

- edit configuration only in source branch
- redeploy site from CI

### Symptom: Articles index exists but dropdown is not grouped

Likely causes:

- `articles:` groups defined but navbar not configured for grouping
- missing `navbar` fields in article sections
- malformed `articles:` structure

Checks:

- `_pkgdown.yml` `articles:` entries include:
- `title`
- `contents`
- optional `navbar`

Fix:

- add `navbar:` labels per section when you want grouped dropdown labels
- rebuild

## Dark Mode (Light Switch)

### Symptom: The light/dark toggle does not appear

Likely causes:

- `template.light-switch` is not enabled.
- Bootstrap 5 is not in use.

Fix:

- set `template.bootstrap: 5`
- set `template.light-switch: true`
- rebuild the site

### Symptom: Dark mode contrast looks wrong (navbar, links, code)

Likely causes:

- Bootswatch theme clashing with dual-mode toggling.
- missing dual-mode tuning for navbar and links.

Fix:

- start with minimal `bslib` tuning:
- set `navbar-light-bg` and `navbar-dark-bg`
- if needed, add small targeted overrides in `pkgdown/extra.css` (avoid broad resets)

### Symptom: Plots look too dark or visually heavy in dark mode

Likely causes:

- dark-mode CSS was applied too broadly
- pkgdown dark-mode plot visibility transforms were not overridden
- the site theme changed, but plots were also restyled without an explicit plotting-theme strategy

Default fix:

- keep plots neutral/light by default
- limit dark-mode styling to the site UI
- if needed, place plots inside a neutral container/card instead of forcing the plot itself into dark mode
- override plot/widget dark-mode transforms in `pkgdown/extra.css` using targeted selectors only

Do not start with:

- global `img` selectors
- global `svg` selectors
- global `canvas` selectors

## Common CI Dependency Issues

### Missing system dependencies

Symptoms:

- package install failures during CI compile
- errors about missing headers or libraries

Fix pattern:

- install required Ubuntu system packages before `setup-r-dependencies`
- examples: `libcurl4-openssl-dev`, `libssl-dev`, `libxml2-dev`, `libgit2-dev`

Add only what your dependencies require.

## Recommended Diagnostic Artifacts for Issues

When reporting or debugging, include:

- Actions log excerpt (build plus deploy)
- `_pkgdown.yml`
- repository structure for key files
- output of `scripts/validate_pkgdown_config.R`
- output of `scripts/check_pkgdown_ready.R`
- output of `scripts/check_pkgdown_builtin.R`
- output of `scripts/check_tutorial_urls.R` (when tutorials are configured)

## Minimal Get-Back-To-Green Recipe

When setup is unstable, reset to a known-good baseline:

1. use minimal `_pkgdown.yml`
2. ensure home exists (`index.md`)
3. remove complex navbar customization temporarily
4. build locally
5. ensure CI installs `pkgdown` and dependencies
6. deploy to `gh-pages` from `docs/`

Then reintroduce complexity gradually (grouped articles, theme customizations, extra components).

## Internal Cross-References

- setup and publish flow: `references/pkgdown-flow.md`
- content placement rules: `references/content-architecture.md`
- growing package strategy: `references/package-in-growth.md`
- learnr/tutorial embedding: `references/tutorials.md`
- theming/layout/assets customization: `references/customization.md`
- config templates: `assets/templates/`
- preflight scripts: `scripts/validate_pkgdown_config.R`, `scripts/check_pkgdown_ready.R`, `scripts/check_pkgdown_builtin.R`, and optionally `scripts/check_tutorial_urls.R`
- visual identity helper: `scripts/setup_favicons.R`
- rebuild helper for stale/orphan pages: `scripts/clean_and_build.R`
