# Project Instructions (Claude Code)

This repository is a library of reusable, agent-agnostic skills for R package development.

@AGENTS.md

## How To Work In This Repo

- Keep all generated content in English.
- When asked to use a skill, start at `skills/<skill-name>/SKILL.md` and follow its workflow.
- When asked to create or update a skill, use `skills/_template` and keep each skill self-contained under `skills/<skill-name>/`.
- Prefer deterministic scripts under `skills/<skill-name>/scripts/` when available.
- Reuse templates under `skills/<skill-name>/assets/` instead of re-creating boilerplate.
- Validate outcomes (script checks, local builds, or other concrete verification) before declaring success.

