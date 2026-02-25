# Package In Growth

Use this module when package scope is expanding and documentation is outgrowing README.

## 1. When To Migrate README Content

Strong migration signals:

- README is usually above 200 to 300 lines and hard to scan
- quick start is mixed with long tutorials
- multiple module examples are stacked in one page
- roadmap and design notes dominate first impressions
- users cannot find install plus minimal example quickly

## 2. Add Site Home Before Vignettes

For evolving packages, introduce site home early:

1. Keep README short and GitHub-first.
2. Add `index.md` (or `pkgdown/index.md`) for website narrative.
3. Place module map, status, and roadmap summary on home.
4. Link clearly to reference and articles.

This gives structure without forcing full vignette stability.

## 3. Use `use_article()` For Fast Iteration

When API still changes, prefer website-only long-form docs:

```r
usethis::use_article("overview")
usethis::use_article("workflow-cfa")
usethis::use_article("faq")
```

Benefits:

- faster iteration
- lower package install footprint
- clearer separation from stable shipped docs

Tradeoff:

- articles are not available offline as installed vignettes

## 4. Suggested Evolution Path

1. Stage 1: README plus Reference
2. Stage 2: basic pkgdown site
3. Stage 3: structured home plus articles
4. Stage 4: strong "Get started" guide
5. Stage 5: formal vignettes when content stabilizes

## 5. Migration Heuristic

For each README section, ask:

1. Is this needed in first 60 seconds?
2. Is it stable enough to keep here?
3. Is it workflow-level guidance better suited for articles?

If answers are "no, no, yes", migrate that section to site home or articles.
