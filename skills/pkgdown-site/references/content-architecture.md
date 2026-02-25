# Content Architecture

Use this guide to decide where each documentation type should live.

## Core Rule

Do not let `README.md` become the full manual.

## Content Ownership Matrix

- README:
  - short value proposition
  - installation
  - minimal runnable example
  - link to website and roadmap

- Site home (`pkgdown/index.md` or `index.md`):
  - package overview
  - module map
  - project maturity and status
  - navigation to reference and articles

- Reference:
  - function-level API docs generated from roxygen

- Articles:
  - task workflows
  - conceptual guides
  - migration notes
  - FAQ and troubleshooting guides

- News:
  - release-oriented change communication

## Typical Migration Triggers

Move content out of README when:

- README is hard to scan in under two minutes
- quick start is buried under long tutorials
- roadmap and design notes crowd core usage
- package has multiple modules requiring separate guides

## Recommended Navbar Pattern

Start simple:

- Home
- Reference
- Articles
- News
- GitHub

Then group articles when content grows by audience or workflow area.

## Anti-Patterns

- duplicated content in README and home page
- one giant article that mixes onboarding, theory, and troubleshooting
- hidden docs that are not linked from navbar or article index
- unstable deep technical notes in "Get started"

## Practical Split Example

Keep in README:

- install
- one minimal example
- one paragraph project status

Move to home:

- scope and module overview
- maturity and roadmap summary

Move to articles:

- advanced workflows
- migration guides
- edge-case diagnostics
