# r-package-dev-skills

Agent skills for R package development.

This repository currently contains:

- `pkgdown-site`: design, configure, organize, and maintain pkgdown websites for R packages (GitHub Pages, content architecture, articles/vignettes strategy, CI preflights).

Entry point:
- `skills/pkgdown-site/SKILL.md`

All documentation and code in this repository are in English.

## Install

### Option A: OpenAI Codex (`$skill-installer`)

Codex supports installing skills from a local folder or another repository via the built-in installer.

1. In Codex, run `$skill-installer`.
2. Install from this GitHub directory URL:

```text
https://github.com/brianmsm/r-package-dev-skills/tree/main/skills/pkgdown-site
```

### Option B: Multi-agent install with `npx skills` (Codex + Claude Code + others)

If you want the same skill available across multiple agents, the open-source `skills` CLI can install skills from GitHub repositories.

List skills in this repo:

```bash
npx skills add brianmsm/r-package-dev-skills --list
```

Install only `pkgdown-site` into the current project:

```bash
npx skills add brianmsm/r-package-dev-skills --skill pkgdown-site
```

Install globally:

```bash
npx skills add brianmsm/r-package-dev-skills --skill pkgdown-site -g
```

Install only to a specific agent:

```bash
# Codex only
npx skills add brianmsm/r-package-dev-skills --skill pkgdown-site -a codex

# Claude Code only
npx skills add brianmsm/r-package-dev-skills --skill pkgdown-site -a claude-code
```

You can also install directly from the skill folder URL:

```bash
npx skills add https://github.com/brianmsm/r-package-dev-skills/tree/main/skills/pkgdown-site
```

## Use

Once installed, ask your agent to use the skill by name and follow its entry point.

Example requests:

- "Use the `pkgdown-site` skill to set up pkgdown + GitHub Pages for this package."
- "Use the `pkgdown-site` skill to migrate a long README into `index.md` + web-only articles."

## What's Inside

```text
skills/pkgdown-site/
├── SKILL.md
├── references/   # architecture, flow, troubleshooting, customization, tutorials, etc.
├── assets/       # copy/paste templates + CI workflow example
└── scripts/      # operational scripts (lint, checks, scaffolding, build helpers)
```

## Contributing

PRs are welcome.

- Repo conventions: `AGENTS.md`
- Contributing guidelines: `CONTRIBUTING.md`

## License

MIT. See `LICENSE`.
