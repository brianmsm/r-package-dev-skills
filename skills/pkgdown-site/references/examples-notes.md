# Examples and Notes (Patterns, Naming, and Practical Conventions)

This file collects practical patterns for designing and scaling pkgdown documentation.
Treat it as a playbook of conventions, not strict rules.

Use this file when:

- you are deciding article names and grouping conventions
- you want navigation patterns that scale as docs grow
- you need repeatable templates for article structure
- you want examples of docs sets for different package types

## Scope of This File

This reference is intentionally example-driven.
For canonical architecture decisions, use `references/content-architecture.md`.

## Naming Conventions

### Article file naming

Use short, stable, task-oriented names.

Prefer:

- `workflows-import.qmd`
- `workflows-modeling.qmd`
- `workflows-visualization.qmd`
- `concepts-metrics.qmd`
- `faq.qmd`
- `troubleshooting.qmd`

Avoid:

- `my_article_v2_final.qmd`
- `notes-random.qmd`
- `functions.qmd`
- `misc.qmd`

Reason:

- users scan titles quickly; names should communicate purpose

### Prefix conventions (optional)

Prefixes help grouping once you have many guides.

Suggested prefixes:

- `workflows-...` for end-to-end tasks
- `concepts-...` for theory and interpretation
- `dev-...` for contributor-focused docs
- `internal-...` for hidden or non-user-facing docs

Be careful:

- avoid prefixing everything when docs are still small
- keep naming meaningful, not mechanical

## Navigation Patterns

### Minimal navbar (early stage)

- `Home | Reference | Articles | News | GitHub`

Best when:

- package is early-stage
- article count is low
- docs ownership is still forming

### Grouped navbar (growing docs)

- `Get started | Reference | Articles (grouped) | News | GitHub`

Best when:

- you have multiple workflows or audiences
- users ask "where do I start?"
- a flat article list is hard to scan

### Get started placement patterns

Pattern A:

- top-level `Get started`
- other guides under `Articles`

Pattern B:

- all guides under `Articles`
- `Get started` is first menu item

Both are valid. Pick one and stay consistent.

## Article Structure Patterns

### Minimal article structure

Each article should include:

1. Goal
2. Audience
3. Prerequisites
4. Steps with minimal runnable code
5. Pitfalls
6. Links to reference pages

### Workflow article skeleton

Recommended headings:

- Goal
- Inputs
- Step 1: Prepare data
- Step 2: Run the procedure
- Step 3: Inspect outputs
- Step 4: Export/report
- Pitfalls
- Variations (optional)
- See also

### Concepts article skeleton

Recommended headings:

- Why this concept matters
- Core definition
- Practical implication
- Small example
- Common misunderstandings
- Links to workflows and reference

## Grouping Strategies for Articles

### Group by module

Use when your package has clear functional domains.

Example groups:

- data ingestion
- transformation
- modeling
- visualization
- reporting

### Group by audience

Use when user skill levels differ significantly.

Example groups:

- getting started
- core workflows
- advanced
- developer

### Hybrid grouping (common in practice)

A useful default:

- getting started
- workflows
- concepts
- advanced
- FAQ
- developer

## Practical Documentation Sets (Domain-Agnostic)

These are sample sets, not prescriptions.

### A) Data manipulation package

Typical goals: load, transform, validate, export.

Suggested set:

1. Get started
2. Workflows: import/export
3. Workflows: transformation patterns
4. Concepts: data assumptions
5. FAQ
6. Troubleshooting

### B) Modeling/statistics package

Typical goals: specify, fit, diagnose, report.

Suggested set:

1. Get started
2. Workflows: fitting
3. Workflows: diagnostics
4. Concepts: assumptions/metrics
5. FAQ
6. Troubleshooting

### C) Visualization package

Typical goals: build, style, publish.

Suggested set:

1. Get started
2. Workflows: plot types
3. Workflows: themes/styling
4. Concepts: scales/aesthetics
5. FAQ
6. Troubleshooting

### D) Domain-specialized package

Typical goals: ingest domain objects, run operations, export results.

Suggested set:

1. Get started
2. Workflows: core operations
3. Workflows: interoperability
4. Concepts: domain assumptions
5. FAQ
6. Troubleshooting

### E) Developer tooling package

Typical goals: integrate into CI, automate tasks, enforce conventions.

Suggested set:

1. Get started
2. Workflows: CI integration
3. Workflows: configuration patterns
4. Concepts: conventions/constraints
5. FAQ
6. Troubleshooting
7. Developer extension guide

## Style Conventions

### Titles

Prefer outcome-oriented titles:

- "Fit a model and interpret results"
- "Validate inputs and handle missing data"
- "Export outputs to common formats"

Avoid generic titles:

- "Details"
- "Notes"
- "Misc"

### Code chunks

Prefer:

- minimal runnable code
- short chunks
- stable outputs
- consistent options (`message = FALSE`, `warning = FALSE`)

Avoid:

- very large outputs in docs
- brittle setup blocks that fail frequently

## Maintenance Checks

Use these checks periodically:

- users can find a clear starting point
- at least one complete workflow is easy to discover
- article list is curated, not an unstructured dump
- README stays lean
- home page explains package scope and next steps
- core exported functions are documented in Reference

## Internal Cross-References

- architecture rules: `references/content-architecture.md`
- package growth strategy: `references/package-in-growth.md`
- setup and publish flow: `references/pkgdown-flow.md`
- troubleshooting: `references/troubleshooting.md`
- templates: `assets/templates/`
