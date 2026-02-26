# Package In Growth

Use this module for packages that are evolving quickly, where README is growing and core APIs still change.

## Goals

1. Keep README short and scannable for GitHub and CRAN-style expectations.
2. Ship a navigable website early, even before formal vignettes.
3. Use website-only documentation to iterate without high maintenance cost.
4. Build a path to mature docs later with minimal rework.

## Constraints And Trade-Offs

- Early-stage packages change quickly, so docs must be cheap to update.
- Formal vignettes increase maintenance because they ship with the package.
- Website-only articles iterate faster and reduce package bloat.
- Website-only articles are not available offline.

## When To Migrate Content Out Of README

Move content when two or more signals are true:

- README is hard to scan due to length, section count, or long examples.
- quick start is buried under advanced material.
- README mixes many intents: quick start, tutorials, roadmap, design notes, and contributor content.
- multiple workflows or modules need dedicated guides.
- users repeatedly ask questions already answered in README.

## Recommended Architecture

Use clear ownership per artifact:

- README: quick start and essential links.
- Site home (`index.md` or `pkgdown/index.md`): package narrative and orientation.
- Reference: function docs from `.Rd`.
- Articles: task-oriented guides and evolving workflows.
- News: release-oriented change log.

## Migration Playbook

### Step 1. Audit README

Classify sections:

1. quick start
2. installation
3. long examples
4. deep dives
5. roadmap or design notes
6. FAQ items
7. contributor material

### Step 2. Decide Target Location

- keep in README: package summary, install, minimal example, key links.
- move to site home: package scope, module map, status, roadmap summary.
- move to articles: tutorials, workflows, FAQ, migration notes, troubleshooting.
- move to separate project files: backlog and experimental design notes.

### Step 3. Add Site Home Before Vignettes

`pkgdown` resolves home in this order:

1. `pkgdown/index.md`
2. `index.md`
3. `README.md`

For growing packages:

1. keep README lean.
2. add `index.md` or `pkgdown/index.md` for a richer landing page.
3. link clearly to reference and articles.

### Step 4. Add Website-Only Articles

Use `usethis::use_article()` for evolving content:

```r
usethis::use_article("overview")
usethis::use_article("workflow-module-a")
usethis::use_article("faq")
usethis::use_article("troubleshooting")
```

Recommended early article set:

1. overview and concepts
2. module-specific workflows
3. FAQ
4. migration notes
5. troubleshooting

### Step 5. Update `_pkgdown.yml`

Start with a simple menu:

- Home
- Reference
- Articles
- News

Group articles by audience or module only when the list grows.

### Step 6. Reduce README

Ensure README stays as an entry point:

- short value statement
- installation
- minimal example
- link to website
- link to first guide
- link to roadmap if available

## How To Choose Articles Versus Vignettes

Prefer articles when:

- API is changing often
- workflows are still being discovered
- fast iteration matters most

Prefer vignettes when:

- workflow is stable across releases
- offline availability matters
- package is approaching release maturity

## Suggested Evolution Path

1. Stage 1: lean README plus Reference
2. Stage 2: pkgdown site with basic home
3. Stage 3: home plus website-only articles
4. Stage 4: stable "Get started" guide
5. Stage 5: promote stable guides to formal vignettes

## Minimal `_pkgdown.yml` For Early Stage

```yaml
url: https://<org-or-user>.github.io/<repo>/

template:
  bootstrap: 5

navbar:
  structure:
    left:
      - intro
      - reference
      - articles
      - news
```

Expand navigation only after content scale justifies it.

## Checklists

### Ready To Shrink README

- README has one minimal runnable example.
- README links to website prominently.
- site home exists (`index.md` or `pkgdown/index.md`).
- at least one article absorbs long tutorial content.
- roadmap or design notes moved out of README.

### Ready To Promote Article To Vignette

- workflow stayed stable across at least one or two releases.
- content no longer needs frequent rewrites.
- team can maintain examples as API evolves.
- offline availability is a real user need.

## Common Pitfalls

1. Treating README as the only docs surface.
2. Creating too many formal vignettes too early.
3. Leaving articles ungrouped and hard to navigate.
4. Mixing developer notes into user-facing onboarding.
5. Forgetting to link the website clearly from README.

## Generic Implementation Plan

Use this sequence for a module-heavy package:

1. trim README to essentials.
2. add site home with module map and status notes.
3. create website-only articles for each major workflow.
4. group articles in navbar.
5. promote only stable guides to vignettes later.
