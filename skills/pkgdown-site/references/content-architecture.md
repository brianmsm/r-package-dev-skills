# Content Architecture For pkgdown Sites

Use this guide to decide where content should live across README, site home, reference, articles, vignettes, tutorials, and news.

The goal is to keep docs discoverable, maintainable, and aligned with how users navigate package websites.

## Core Principle

Separate content by intent.

Each docs surface has a primary job:

- README: first impression and quick start (GitHub-first)
- site home (`index.md` or `pkgdown/index.md`): richer landing page
- reference: function-level docs from `.Rd`
- articles: task-oriented workflows
- vignettes: stable long-form guides shipped with the package
- tutorials: embedded interactive guides hosted externally (optional)
- news: release-oriented user-facing changes
- contributor docs: developer workflows, not end-user onboarding

## Content Map

Think in layers:

1. entry points: README and site home
2. how-to guidance: articles, vignettes, and optional tutorials
3. API lookup: reference
4. change communication: news
5. developer corner: contributor and internal docs

## Content Ownership Rules

### README

Keep:

- one-paragraph value proposition
- installation
- one minimal runnable example
- short project status
- links to website and key guides

Notes:

- If you maintain `README.Rmd`, keep `README.md` up to date and committed. pkgdown uses
  `README.md` for the website home (when selected) and does not knit `README.Rmd` for you.
- If you include images in `README.md`, store them inside the package (commonly `man/figures/`)
  and use stable relative paths. If you generate figures via R Markdown, set `fig.path` to
  `man/figures/` so images land in the right place.

Avoid:

- long tutorials
- full module walkthroughs
- large FAQ sections
- deep design notes

README is a navigation hub, not the full manual.

### Site Home

Use `index.md` or `pkgdown/index.md` for:

- package scope and story
- module map
- stable versus experimental status notes
- "what next" links to reference and articles

Avoid:

- large code dumps
- complete tutorials
- function-by-function listings

Notes:

- If you maintain `index.Rmd`, keep `index.md` up to date and committed. pkgdown does not knit
  `index.Rmd` for the home page.

### Reference

Reference is the source of truth for:

- function usage
- arguments and return values
- concise examples

Rule of thumb:

- reference answers "what does this function do?"
- articles answer "how do I complete this task?"

For growing APIs, group the reference index with `_pkgdown.yml` `reference:` sections
(`title`, `subtitle`, `contents`) so users can scan by function family.
Use `assets/templates/_pkgdown-reference-grouped.yml` as a starting point.

### Articles

Use articles for:

- end-to-end workflows
- module-specific guides
- conceptual primers tied to tasks
- FAQ, troubleshooting, migration notes

Prefer article structure with:

- goal
- audience
- required inputs
- minimal runnable steps
- pitfalls
- links to reference pages

### Promoted Article Pattern

Sometimes one article deserves more prominence than the rest, for example:

- a primary `Get started` guide
- a first workflow users should see immediately
- a migration or onboarding guide

In those cases, treat the formal article index and the visual navbar as separate concerns:

- keep the promoted article in `articles:` so pkgdown still indexes it
- promote it visually in the navbar only when it improves navigation
- curate the Articles dropdown separately if needed so the same article is not shown twice

Prefer pkgdown's official top-level `Get started` behavior when possible:

- if an article or vignette uses the package-name convention, pkgdown can expose it as the top-level `Get started` entry automatically

If the promoted article does not use that convention:

- add a dedicated navbar component for the promoted article
- keep it listed in `articles:` for indexing
- use `navbar.components.articles.menu` to control the visual dropdown contents when duplication would be confusing

Default rule:

- avoid visual duplication between a promoted top-level article and the Articles dropdown unless the user explicitly wants both

### Vignettes

Use vignettes when content is stable and offline availability matters.

Progression guideline:

- start with articles while APIs evolve
- promote stable articles to vignettes later

### Tutorials

Use tutorials when you need interactive `learnr`-style training hosted outside pkgdown.

Key distinction:

- pkgdown can embed tutorials
- pkgdown does not run/host tutorial apps

Use tutorials sparingly and keep static alternatives (articles/reference) available.

### News

Include user-facing release information:

- added features
- deprecations and breaking changes
- important bug fixes

Avoid internal-only refactor noise.

### Contributor Docs

Keep developer docs separate from user docs:

- `CONTRIBUTING.md` for contribution flow
- optional `docs/dev/` for internal architecture notes

If exposed in pkgdown, label clearly as developer-facing.

## Avoid Duplication

Duplication is the main docs maintenance risk.

Apply a single-source rule per topic:

- install and minimal example -> README
- package/module overview -> site home
- workflow guide -> article
- function behavior -> reference
- release changes -> news

Small duplication can be useful when intentional:

- a minimal example in README and a richer one in site home

Avoid full tutorial duplication across README and articles.

## Scalable Structure By Maturity

### Early Stage

- README quick start
- site home overview
- reference pages
- one get-started article
- one workflow article

### Growing Package

- lean README plus links
- strong module map on home
- grouped articles by audience or module
- regular news updates

### Mature Package

- polished home and curated navigation
- stable get-started
- advanced workflows in articles
- selected stable guides as vignettes
- complete reference coverage

## Recommended Repository Layout

```text
.
├── DESCRIPTION
├── NAMESPACE
├── README.md
├── NEWS.md
├── index.md
├── _pkgdown.yml
├── R/
├── man/
├── vignettes/
└── .github/workflows/pkgdown.yaml
```

If you want a site-only landing page, use `pkgdown/index.md`.

## Choosing README Versus Home

Decision rule:

1. keep README short for GitHub scanning
2. use `index.md` or `pkgdown/index.md` for richer website orientation

This keeps GitHub entry concise and website navigation coherent.

## Navbar Patterns

Start minimal:

- intro
- reference
- articles
- news

Group articles only when scale requires it, usually by workflow or audience.

## Migration Heuristic

When README is too large, migrate in this order:

1. long tutorials -> articles
2. roadmap and design notes -> dedicated roadmap page or labeled article
3. FAQs -> article
4. multiple long examples -> articles, keep one minimal example in README
5. expanded narrative -> site home

Optional tool: run `scripts/audit_readme_for_migration.R` to generate a section-by-section
migration report for the current README.

## Common Pitfalls

1. README becomes the entire manual.
2. articles remain an unstructured flat list.
3. reference duplicates workflow narrative.
4. too many formal vignettes too early.
5. developer notes mixed into user onboarding docs.

## Architecture Sanity Checklist

- [ ] README has install and one minimal example.
- [ ] README links prominently to website.
- [ ] site home exists and is richer than README.
- [ ] reference covers core functions.
- [ ] at least one end-to-end workflow exists in articles.
- [ ] news is maintained for public releases.
- [ ] developer docs are separated and clearly labeled.

## Growth Checklist

- [ ] more than five articles exist or are planned.
- [ ] users ask where to start.
- [ ] main workflows can be grouped by module or audience.
- [ ] navbar grouping strategy is defined.

## Cross-Reference

For active-development packages with oversized README, also use:

- `references/package-in-growth.md`
- `references/tutorials.md` (if interactive learnr content is part of the docs strategy)
