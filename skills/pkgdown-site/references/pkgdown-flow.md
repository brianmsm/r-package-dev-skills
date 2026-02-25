# pkgdown Flow

This file defines a practical baseline flow for setting up, previewing, and publishing a `pkgdown` site.

## 1. Baseline Setup

1. Confirm package root has `DESCRIPTION`.
2. Run:

```r
usethis::use_pkgdown_github_pages()
```

This usually creates or updates:

- `_pkgdown.yml`
- `.github/workflows/pkgdown.yaml`
- required URL wiring in package metadata

3. Commit and push setup files to the default branch.

## 2. Local Build And Preview

Use local builds before debugging CI.

```r
pkgdown::build_site()
```

Useful partial builds:

```r
pkgdown::build_home()
pkgdown::build_reference()
pkgdown::build_articles()
```

Preview locally:

```r
pkgdown::preview_site()
```

## 3. CI Build And Deploy

Typical CI flow:

1. checkout repository
2. install dependencies
3. build site
4. publish to `gh-pages`

In most setups, rendered HTML is deployed from CI and stored on `gh-pages`.

## 4. Local Build Versus CI Build

Local build:

- uses your current workspace
- may include unstaged changes
- may rely on local packages that CI does not have

CI build:

- starts from clean checkout
- only uses committed files
- fails if dependencies are missing or configuration is invalid

## 5. Deploy Verification Points

When deploy fails, verify in this order:

1. workflow file exists and is on default branch
2. `_pkgdown.yml` parses cleanly
3. GitHub Action has write permission to contents
4. Pages source and branch settings are correct
5. generated site files exist in `gh-pages`

## 6. Fast Failure Triage

- `404`: branch or Pages source mismatch, or no successful deploy
- empty site: build produced little output or wrong deploy path
- broken navbar: invalid YAML or missing referenced pages
- missing article: file exists but not indexed or build failed
