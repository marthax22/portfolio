# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A personal portfolio site for Martha Charalampidou, built as one static file: `public/index.html`. It has inline CSS and JS and no build step, linter or tests. The only external front-end dependency is Google Fonts (Inter, JetBrains Mono). A Cloudflare Pages Function provides the chatbot backend.

## Layout

- `public/`: the only folder deployed as static files. `public/index.html` is the whole site.
- `functions/api/chat.js`: Cloudflare Pages Function for the chatbot (`POST /api/chat`). It reads the API key from `env.ANTHROPIC_API_KEY` only.
- Everything else in the root (`.dev.vars`, `CLAUDE.md`, `package*.json`, `node_modules/`, `.wrangler/`) must never be deployed.

## Running / deploying

- Preview (static only): open `public/index.html`, or `npx serve public`.
- Local dev with the chatbot: `npx wrangler pages dev public`. It reads the key from `.dev.vars` (`ANTHROPIC_API_KEY=...`).
- Deploy: Cloudflare Pages via Wrangler, project `portfolio-martha-charalampidou` (from `.wrangler/cache/pages.json`):
  `npx wrangler pages deploy public --project-name portfolio-martha-charalampidou`
- Production key: set it once with `npx wrangler pages secret put ANTHROPIC_API_KEY --project-name portfolio-martha-charalampidou`.
- `.wrangler/` is local Wrangler state, so don't commit it.

## Secrets (important)

- NEVER run `wrangler pages deploy .`. It uploads the project root, and `.dev.vars` would become public at `/.dev.vars`.
- Never put the API key in `public/`, in `index.html`, in client-side JS or in any committed file. `.dev.vars` is git-ignored and local only.
- Never print, log or echo the contents of `.dev.vars` or the key.
- Any new static file (images, CV PDF, etc.) goes in `public/`.

## Architecture (inside public/index.html)

- **Bilingual (Greek default, English toggle).** Greek is the source language and lives directly in the HTML markup. Translatable elements carry `data-i18n="key"`, or `data-i18n-aria="key"` for `aria-label`s. At startup the script copies the Greek `innerHTML` of those elements into the `EL` dictionary. English strings sit in the hand-written `EN` object in the `<script>`. `setLang()` swaps `innerHTML` for every keyed element and updates `document.title` and the meta description (`meta.title` / `meta.desc` keys).
  - **When you add or edit visible text:** write the Greek in the HTML with a `data-i18n` key, and add the same key to `EN`. Values are injected as HTML, so inline markup like `<strong>` or `<br>` must appear in both versions.
  - Language choice is saved in `localStorage("lang")`. `?lang=en` forces English.
- **Theme.** `data-theme="light"|"dark"` goes on `<html>`. Colors are CSS custom properties on `:root`, overridden in `:root[data-theme="light"]`. The choice is saved in `localStorage("theme")`, and the system preference is the fallback.
- **Scroll effects.** An IntersectionObserver adds `.visible` to `.reveal` elements and animates skill bars to their `data-w` percentage. A second observer highlights the active nav link per `section[id]`.
- **Contact form.** There's no backend. On submit the form builds a `mailto:` link to `CONTACT_EMAIL` and opens the user's mail client.
- **Chatbot widget.** A floating button (`#chatFab`) opens `#chatPanel`, which becomes a bottom sheet at 480px and below. `sendChat()` POSTs `{ messages, lang }` to `/api/chat`, sending the last 2 exchanges plus the new question. It checks `data.error` before `data.reply`, because `refusal` comes back with status 200. Replies are inserted with `textContent`, never as HTML. Static strings use `data-i18n` keys `chat.*`. Dynamic strings (`chat.ph`, `chat.typing`, `chat.err.*`, `aria.chatOpen`) are written by hand in both `EL` and `EN`. Under `npx serve` the endpoint doesn't exist, so the widget shows the generic error.
- **Sections** are numbered in their titles (`01.` About, `02.` Skills, `03.` Projects, `04.` Contact). Project cards use keys `p1`…`pN` (`.title`, `.desc`).

Code comments are written in Greek.

## Rules
- Every layout change must responsive and look good on all screen sizes: phones (from 320px), tablets and desktops.
- Do not push or deploy without asking me first.
