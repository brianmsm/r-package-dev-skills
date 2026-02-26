# Customization (Theming, Layout, and Assets) for pkgdown Sites

Use this reference when you need practical customization beyond default pkgdown output.

Focus areas:

- theming with Bootswatch and `bslib`
- layout structure (`navbar`, `footer`, home behavior)
- HTML/CSS/JS injection and asset placement
- reusable style across multiple packages via template packages

## Before You Customize

### Prefer Bootstrap 5

Most modern customization options assume Bootstrap 5.

```yaml
template:
  bootstrap: 5
```

### Keep Accessibility in Scope

Default pkgdown styling is accessibility-oriented. Re-test contrast and readability after changing colors, fonts, or dense custom CSS.

## Theming

The main entry point is `_pkgdown.yml` under `template:`.

### Option 1: Bootswatch Theme

Quickly restyle with a Bootswatch theme:

```yaml
template:
  bootstrap: 5
  bootswatch: materia
```

For some taller nav themes, set `pkgdown-nav-height`:

```yaml
template:
  bootstrap: 5
  bslib:
    bootswatch: lux
    pkgdown-nav-height: 100px
```

To estimate navbar height in browser dev tools:

```js
$(".navbar").outerHeight()
```

### Option 2: `bslib` Variables

Fine-tune with `bslib` variables:

```yaml
template:
  bootstrap: 5
  bslib:
    bg: "#ffffff"
    fg: "#111111"
    primary: "#0b5fff"
```

Common variables:

- `bg`: page background
- `fg`: foreground text
- `primary`: links and primary accents

### Optional Light Switch

Enable color-mode switcher:

```yaml
template:
  light-switch: true
```

This adds a `lightswitch` navbar component when supported by your layout.

## Fonts

### Google Fonts

If using `bslib`, set font-related fields (for example `base_font`, `heading_font`, `code_font`) in `template.bslib`.

### Non-Google Fonts

Two common patterns:

1. Add CSS in `pkgdown/extra.scss` or `pkgdown/extra.css`, then reference the font family in `bslib`.
2. Inject a stylesheet `<link>` in header via `template.includes.in_header`.

Example:

```yaml
template:
  includes:
    # Replace with your actual stylesheet URL:
    in_header: <link rel="stylesheet" href="https://<host>/fonts.css" />
```

## Layout

Layout customization generally uses:

- `structure`: placement
- `components`: content and labels

### Navbar

Typical default structure:

```yaml
navbar:
  structure:
    left:  [intro, reference, articles, tutorials, news]
    right: [search, github, lightswitch]
```

Practical guidance:

- keep top-level navigation minimal
- group depth under Articles/Reference before adding many top-level items
- only keep `tutorials` when tutorials are actually configured

### Footer

Footer follows the same `structure`/`components` model.

```yaml
footer:
  structure:
    left: developed_by
    right: built_with
```

Custom example:

```yaml
footer:
  structure:
    left: pkgdown
    right: [developed_by, legal]
  components:
    legal: Provided without **any warranty**.
```

### Homepage Sidebar and Home Behavior

Home behavior is configured separately from navbar decisions. High-impact home tuning typically happens under `home:` in `_pkgdown.yml`.

### Home Metadata: Title and Description

By default, pkgdown derives page title and description from `DESCRIPTION`. It is often worth overriding these for better search-engine and landing-page clarity:

```yaml
home:
  title: "An R package for <short searchable topic>"
  description: >
    One paragraph describing what the package does and why it exists.
    Keep it plain and user-facing.
```

### Home Links

Curate the home sidebar links so users can find the next steps quickly:

```yaml
home:
  links:
    - text: Roadmap
      href: ROADMAP.html
    - text: Changelog
      href: news/index.html
```

Tip: pkgdown also auto-populates links from `DESCRIPTION` fields like `URL` and `BugReports`.

### Home Sidebar Structure

This is the default sidebar structure:

```yaml
home:
  sidebar:
    structure: [links, license, community, citation, authors, dev]
```

You can remove the sidebar entirely:

```yaml
home:
  sidebar: FALSE
```

Guidance:

- keep the sidebar short
- prefer a few curated links over many sections
- treat sidebar changes as home-page concerns (avoid mixing with navbar decisions)

## Additional HTML and Files

### HTML Injection Points

Use `template.includes`:

```yaml
template:
  includes:
    in_header: <!-- end of head -->
    before_body: <!-- start of body -->
    after_body: <!-- end of body -->
    before_title: <!-- before package title -->
    before_navbar: <!-- before navbar links -->
    after_navbar: <!-- after navbar links -->
```

### Asset Locations

Supported drop-in locations:

- `pkgdown/extra.css` and `pkgdown/extra.js`: copied to site and linked after defaults
- `pkgdown/extra.scss`: merged into SCSS ruleset
- `pkgdown/assets`: copied to website root
- `pkgdown/templates`: advanced template overrides

After changing `extra.scss`, logo, or `template.bslib` values, run:

```r
pkgdown::init_site()
```

Then rebuild as needed.

## Sharing Style Across Packages (Template Packages)

For multi-package consistency, use a template package.

Useful files inside template package:

- `inst/pkgdown/_pkgdown.yml`
- `inst/pkgdown/templates/`
- `inst/pkgdown/assets/`
- `inst/pkgdown/extra.scss`

Use it from package site config:

```yaml
template:
  package: your-template-package
```

To ensure CI can install that template package during website builds, add it to:

```text
Config/Needs/website: yourorg/your-template-package
```

## Recommended Customization Workflow

1. Start with `_pkgdown.yml` only.
2. Apply one visual change at a time.
3. Rebuild home or full site depending on scope.
4. Add assets only in documented folders.
5. Re-run diagnostics if layout breaks (`check_pkgdown_builtin.R` and local build).

## Minimal Recipes

### Recipe A: Bootswatch + Light Switch

```yaml
template:
  bootstrap: 5
  bootswatch: materia
  light-switch: true
```

### Recipe B: Brand Colors with `bslib`

```yaml
template:
  bootstrap: 5
  bslib:
    bg: "#ffffff"
    fg: "#111111"
    primary: "#0b5fff"
```

### Recipe C: Extra CSS/JS

Create:

- `pkgdown/extra.css`
- `pkgdown/extra.js`

Then rebuild locally and verify behavior.

## Internal Cross-References

- setup and deployment flow: `references/pkgdown-flow.md`
- architecture and content ownership: `references/content-architecture.md`
- troubleshooting failures: `references/troubleshooting.md`
- naming and patterns: `references/examples-notes.md`
