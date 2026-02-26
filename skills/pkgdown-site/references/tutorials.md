# Tutorials in pkgdown (learnr and embedded interactive content)

This reference explains how pkgdown handles tutorials, especially `learnr`.

Key idea:

- `learnr` tutorials require an R execution engine.
- pkgdown does not build or host tutorial apps for you.
- pkgdown can embed already-published tutorials with iframes.

## What pkgdown Means by Tutorials

In pkgdown, tutorials are pages under a `tutorials/` section that embed an external URL in an `<iframe>`.

This is useful when interactive content is hosted elsewhere (for example ShinyApps.io, Posit Connect, or another Shiny host) and you want a stable entry point from your package site.

## When to Use Tutorials

Use tutorials when:

- you have interactive training material that must run on a server
- you want those tutorials discoverable from the package website
- your hosting setup allows iframe embedding

Do not use tutorials when:

- you only have static documentation (use Articles and Reference)
- you cannot host tutorials externally
- your host blocks iframe embedding via frame/CSP policies

## Discovery and Configuration

pkgdown can discover tutorials from:

- `inst/tutorials`
- `vignettes/tutorials`

For most projects, explicit configuration in `_pkgdown.yml` is clearer and more stable.

Example:

```yaml
tutorials:
  - name: 00-setup
    title: Setup
    url: https://example-host.org/tutorial-00-setup/
    source: https://github.com/<org>/<repo>/tree/main/tutorials/00-setup
  - name: 01-data-basics
    title: Data basics
    url: https://example-host.org/tutorial-01-data-basics/
```

Fields:

- `name`: generated file name
- `title`: page title and navbar label
- `url`: published URL embedded by iframe
- `source` (optional): source code link

## Navbar Integration

If you use tutorials, include `tutorials` in navbar structure:

```yaml
navbar:
  structure:
    left:  [intro, reference, articles, tutorials, news]
    right: [search, github]
```

If you do not use tutorials, remove `tutorials` from navbar to avoid empty navigation.

## Build Behavior

`pkgdown::build_site()` runs `build_tutorials()` and generates tutorial pages that embed configured URLs.

Important:

- this does not deploy or run tutorial apps
- it only builds static pages that point to hosted tutorials

## Hosting and Embedding Checks

Before relying on iframe embeds:

1. Ensure tutorial URLs are reachable over HTTPS.
2. Ensure host allows embedding (no restrictive frame/CSP headers).
3. Ensure iframe height is reasonable and responsive enough.

If embedding is blocked, users typically see a blank frame or browser frame-policy errors.

## Optional CI Guard for Tutorial URLs

If you maintain a tutorials section in `_pkgdown.yml`, you can validate entries and URL reachability in CI with:

```bash
Rscript scripts/check_tutorial_urls.R _pkgdown.yml
```

This check is optional and should only be enabled when tutorials are configured.

## Troubleshooting Quick Tips

### Tutorial page is blank

Likely cause:

- host blocks iframe embedding

Check:

- open tutorial URL directly
- check browser console for frame/CSP errors

Fix:

- change hosting policy or host provider
- provide a direct "open tutorial" link as fallback

### Tutorials tab appears but no items show

Likely cause:

- navbar includes `tutorials` but no discovered/configured tutorials

Fix:

- add explicit `tutorials:` entries in `_pkgdown.yml`
- or remove `tutorials` from navbar

## See Also

- `references/pkgdown-flow.md`
- `references/troubleshooting.md`
- `assets/templates/tutorial-embed.md`
- `scripts/check_tutorial_urls.R`
