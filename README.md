# R Package Dev Skills

Reusable, agent-agnostic skills for R package development workflows.

## Scope

This repository contains modular skill definitions that help AI agents work on R packages with consistent quality.
All documentation, code, and written content in this repository are in English.

## Principles

- Keep skills compatible with any AI agent.
- Keep workflows practical, deterministic, and test-oriented.
- Prefer small, focused skills over large monolithic instructions.
- Keep the repository lean: `AGENTS.md` plus skill folders (and optional agent-specific entry points like `CLAUDE.md`).

## Repository Layout

- `skills/`: Skill definitions.
- `skills/_template/`: Starter template used to create new skills.
- `AGENTS.md`: Repository-wide rules and conventions.
- `CLAUDE.md`: Optional Claude Code project instructions (imports `AGENTS.md`).

## Using This Repo With Coding Agents

This repo is designed for coding agents that can read Markdown files and run shell/R commands.

### OpenAI Codex (codex-cli)

- Codex automatically loads `AGENTS.md`/`agents.md` files found in the current directory and parent directories.
  This repo uses `AGENTS.md` as the source of truth for shared rules.
- To use a skill, start at `skills/<skill-name>/SKILL.md` and follow its workflow.
  Use `references/` only as needed, prefer `scripts/` for deterministic checks/scaffolding,
  and reuse `assets/` templates instead of rewriting from scratch.

### Anthropic Claude Code

- Claude Code loads `CLAUDE.md` files recursively from the current working directory up to the repo root.
  This repo includes a `CLAUDE.md` that imports `AGENTS.md` so shared rules stay centralized.
- To use a skill, open `skills/<skill-name>/SKILL.md` and follow its routing and execution protocol.

### Other Agents

- Read `AGENTS.md` first, then open the relevant `skills/<skill-name>/SKILL.md`.

### References (Agent Behavior)

- OpenAI Codex: AGENTS instructions loading behavior is documented in the OpenAI Cookbook (Codex Prompting Guide):
  https://cookbook.openai.com/examples/gpt-5/gpt-5-1-codex-max_prompting_guide
- Claude Code: CLAUDE.md project memory and file import behavior is documented in Anthropic's Claude Code docs:
  https://docs.anthropic.com/en/docs/claude-code/memory

## Vendoring Skills Into Another Repository

If you want to use a skill while an agent is working inside a different repository (for example an R package repo),
vendor the relevant skill folder into that repo:

```bash
mkdir -p skills
cp -r /path/to/r-package-dev-skills/skills/<skill-name> skills/<skill-name>
```

Then point your agent to the entry point:

- `skills/<skill-name>/SKILL.md`

Tip: If you vendor scripts into your repo and wire them into CI (for example pkgdown preflight checks),
keep the workflow steps conditional on file existence so partial adoption stays safe.

## Available Skills

- `pkgdown-site`: Design, configure, organize, and troubleshoot pkgdown websites for R packages.
  Entry point: `skills/pkgdown-site/SKILL.md`

## Create A New Skill

1. Copy the template folder:
   `cp -r skills/_template skills/my-skill-name`
2. Edit `skills/my-skill-name/SKILL.md`.
3. Replace template placeholders.
4. Keep language clear, imperative, and implementation-focused.
5. Commit changes and open a pull request.

## License

This project is distributed under the MIT License. See `LICENSE`.
