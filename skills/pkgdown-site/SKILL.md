---
name: pkgdown-site
description: Design, configure, organize, and troubleshoot pkgdown websites for R packages, including GitHub Pages deployment, content architecture, articles versus vignettes, and migration from oversized READMEs in packages that are still evolving.
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
- style options and naming patterns: `references/examples-notes.md`

## Package In Growth Module

Prioritize this module when:

- README is large and hard to scan
- core API is still changing
- no stable vignette set exists yet

Recommended approach:

1. Keep README to quick-start essentials.
2. Add `index.md` for website home narrative.
3. Use website-only articles for evolving content.
4. Promote only stable guides to formal vignettes later.

## Execution Protocol

Follow this order when skill is active:

1. Run minimal repository diagnosis.
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
