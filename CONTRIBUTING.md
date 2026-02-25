# Contributing

Thanks for contributing to this repository.

## Contribution Rules

- Write all documentation, code comments, and skill content in English.
- Keep each skill self-contained in its own folder under `skills/`.
- Use lowercase hyphenated names for skill folders, for example: `r-package-docs`.
- Include a single required file per skill: `SKILL.md`.
- Add extra folders (`references/`, `scripts/`, `assets/`) only when they are needed.
- Keep instructions agent-agnostic and avoid provider-specific assumptions.

## Skill Quality Checklist

- The frontmatter includes `name` and `description`.
- The description clearly states what the skill does and when to use it.
- Steps are actionable and ordered.
- Commands are safe and reproducible.
- Validation or verification steps are included.
- Content avoids unnecessary verbosity.

## Suggested Workflow

1. Copy `skills/_template` to `skills/your-skill-name`.
2. Edit `SKILL.md` and replace all placeholders.
3. Add optional resources only if required.
4. Run basic smoke tests for any scripts you add.
5. Open a pull request with a short summary and examples.
