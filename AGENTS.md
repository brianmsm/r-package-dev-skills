# AGENTS

This repository is designed for any AI agent that can read Markdown files and execute shell commands.

## Precedence

- `AGENTS.md` is the repository source of truth for shared rules.
- Each `skills/<skill-name>/SKILL.md` defines task-specific behavior for that skill.
- If there is a conflict, follow `AGENTS.md` unless a maintainer explicitly states otherwise.

## Operating Rules

- Use English for all generated content inside this repository.
- Prefer deterministic and reproducible workflows.
- Keep solutions tool-agnostic unless a dependency is explicitly required.
- Validate outcomes with tests, checks, or concrete verification steps.
- Avoid destructive operations unless explicitly requested.

## Skill Authoring Rules

- Place each skill in `skills/<skill-name>/`.
- Include `SKILL.md` with frontmatter keys `name` and `description`.
- Keep instructions concise and procedural.
- Use optional folders only when needed:
  - `references/` for on-demand documentation
  - `scripts/` for deterministic automation
  - `assets/` for reusable output assets

## Writing Style

- Use imperative instructions.
- Keep examples short and practical.
- Prioritize clarity over framework-specific jargon.
