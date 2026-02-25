# R Package Dev Skills

Reusable, agent-agnostic skills for R package development workflows.

## Scope

This repository contains modular skill definitions that help AI agents work on R packages with consistent quality.
All documentation, code, and written content in this repository are in English.

## Principles

- Keep skills compatible with any AI agent.
- Keep workflows practical, deterministic, and test-oriented.
- Prefer small, focused skills over large monolithic instructions.
- Keep the repository lean: `AGENTS.md` plus skill folders.

## Repository Layout

- `skills/`: Skill definitions.
- `skills/_template/`: Starter template used to create new skills.
- `AGENTS.md`: Repository-wide rules and conventions.

## Quick Start

1. Copy the template folder:
   `cp -r skills/_template skills/my-skill-name`
2. Edit `skills/my-skill-name/SKILL.md`.
3. Replace template placeholders.
4. Keep language clear, imperative, and implementation-focused.
5. Commit changes and open a pull request.

## License

This project is distributed under the MIT License. See `LICENSE`.
