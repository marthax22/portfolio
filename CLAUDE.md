# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A personal portfolio site for Martha Charalampidou, built as one static file: `index.html`. It has inline CSS and JS and no build step, package manager, linter or tests. The only external dependency is Google Fonts (Inter, JetBrains Mono).

## Running / deploying

- Preview: open `index.html` in a browser, or serve the folder with any static server (e.g. `npx serve .`).
- Deploy: Cloudflare Pages via Wrangler, project `portfolio-martha-charalampidou` (from `.wrangler/cache/pages.json`):
  `npx wrangler pages deploy . --project-name portfolio-martha-charalampidou`
  `.wrangler/` is local Wrangler state, so don't commit it.

## Architecture (inside index.html)

- **Bilingual (Greek default, English toggle).** Greek is the source language and lives directly in the HTML markup. Translatable elements carry `data-i18n="key"`, or `data-i18n-aria="key"` for `aria-label`s. At startup the script copies the Greek `innerHTML` of those elements into the `EL` dictionary. English strings sit in the hand-written `EN` object in the `<script>`. `setLang()` swaps `innerHTML` for every keyed element and updates `document.title` and the meta description (`meta.title` / `meta.desc` keys).
  - **When you add or edit visible text:** write the Greek in the HTML with a `data-i18n` key, and add the same key to `EN`. Values are injected as HTML, so inline markup like `<strong>` or `<br>` must appear in both versions.
  - Language choice is saved in `localStorage("lang")`. `?lang=en` forces English.
- **Theme.** `data-theme="light"|"dark"` goes on `<html>`. Colors are CSS custom properties on `:root`, overridden in `:root[data-theme="light"]`. The choice is saved in `localStorage("theme")`, and the system preference is the fallback.
- **Scroll effects.** An IntersectionObserver adds `.visible` to `.reveal` elements and animates skill bars to their `data-w` percentage. A second observer highlights the active nav link per `section[id]`.
- **Contact form.** There's no backend. On submit the form builds a `mailto:` link to `CONTACT_EMAIL` and opens the user's mail client.
- **Sections** are numbered in their titles (`01.` About, `02.` Skills, `03.` Projects, `04.` Contact). Project cards use keys `p1`…`pN` (`.title`, `.desc`).

Code comments are written in Greek.
