# Troubleshooting

Use this page for common `pkgdown` failure patterns.

## Home Page Does Not Change

Symptom:

- site home still shows old README content

Likely cause:

- `index.md` not in expected location or not committed

Verify:

- check `pkgdown/index.md` and `index.md`
- rebuild locally and inspect generated home page

Fix:

- add or update home source file
- rebuild and redeploy

## Article Does Not Appear

Symptom:

- article file exists but is missing in site

Likely cause:

- article not indexed in `_pkgdown.yml` or build failed

Verify:

- run local article build
- inspect `_pkgdown.yml` `articles` section

Fix:

- add article to article index or naming pattern
- rebuild and confirm article HTML exists

## Broken Navbar

Symptom:

- menu missing or malformed

Likely cause:

- invalid YAML indentation or broken component references

Verify:

- validate YAML parsing
- compare navbar structure items with components

Fix:

- correct indentation and keys
- remove invalid menu entries

## Deploy Returns 404

Symptom:

- published URL returns 404

Likely cause:

- no successful deploy, wrong Pages source, or wrong URL

Verify:

- inspect latest workflow run
- inspect GitHub Pages configuration
- check `gh-pages` branch exists and has HTML

Fix:

- fix workflow and permissions
- redeploy
- align configured URL with actual repo site URL

## gh-pages Branch Is Empty

Symptom:

- branch exists but no useful site output

Likely cause:

- build step failed before deploy
- deploy path points to wrong directory

Verify:

- inspect workflow logs for build errors
- inspect deploy step input and output

Fix:

- fix build dependencies and config
- rerun workflow after commit

## README And Home Duplicate Content

Symptom:

- home and README are nearly identical and too long

Likely cause:

- no content boundary strategy

Verify:

- compare README and home sections side by side

Fix:

- keep README lean
- move long sections to home and articles

## `_pkgdown.yml` Parse Errors

Symptom:

- build fails before rendering

Likely cause:

- malformed YAML

Verify:

- parse YAML directly before build

Fix:

- correct syntax and indentation
- validate again, then rebuild site
