<!--
Tutorial embed snippet (pkgdown / Markdown / Quarto compatible)

Purpose:
- Embed a published learnr tutorial (or other interactive app) in a pkgdown page.

Notes:
- URL must be reachable over HTTPS.
- Host must allow iframe embedding.
- Tune height to your content.
-->

## Embedded tutorial

<iframe
  title="{tutorial_title}"
  src="{tutorial_url}"
  loading="lazy"
  style="width: 100%; height: 850px; border: 0;"
  allow="clipboard-write; fullscreen"
></iframe>

### Troubleshooting

- If this area is blank, the host may block iframe embedding.
- Open the tutorial URL directly in a new tab.
- If it works directly but not embedded, inspect browser console for frame/CSP policy errors.

<!-- Optional wider variant -->
<iframe
  title="{tutorial_title}"
  src="{tutorial_url}"
  loading="lazy"
  style="width: 1px; min-width: 100%; height: 850px; border: 0;"
  allow="clipboard-write; fullscreen"
></iframe>
