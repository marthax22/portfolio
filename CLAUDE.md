# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A personal portfolio site for Martha Charalampidou, built as one static file: `public/index.html`. It has inline CSS and JS and no build step, linter or tests. The only external front-end dependency is Google Fonts (Inter, JetBrains Mono). A Cloudflare Pages Function provides the chatbot backend.

## Layout

- `public/`: the only folder deployed as static files. `public/index.html` is the whole site. It also holds `favicon.ico`, `favicon.svg`, `apple-touch-icon.png` and `og-image.png` (1200×630, social preview).
- `functions/api/chat.js`: Cloudflare Pages Function for the chatbot (`POST /api/chat`). It reads the API key from `env.ANTHROPIC_API_KEY` only.
- `migrations/`: D1 schema for chatbot rate limiting (table `hits`).
- `wrangler.toml`: `name` matches the Pages project (`portfolio-martha-charalampidou`), `pages_build_output_dir = "public"`, and the D1 binding `RATE_DB`.
- `STATUS.md`: project status and open tasks, in Greek. Update it when a task is done or a new one comes up.
- Everything else in the root (`.dev.vars`, `CLAUDE.md`, `STATUS.md`, `package*.json`, `node_modules/`, `.wrangler/`) must never be deployed.

## Running / deploying

- Preview (static only): open `public/index.html`, or `npx serve public`.
- Local dev with the chatbot: `npx wrangler pages dev public`. It reads the key from `.dev.vars` (`ANTHROPIC_API_KEY=...`).
- Deploy: Cloudflare Pages via Wrangler, project `portfolio-martha-charalampidou` (from `.wrangler/cache/pages.json`):
  `npx wrangler pages deploy public --project-name portfolio-martha-charalampidou`
- Production key: set it once with `npx wrangler pages secret put ANTHROPIC_API_KEY --project-name portfolio-martha-charalampidou`.
- `.wrangler/` is local Wrangler state, so don't commit it.

## Chat endpoint (/api/chat)

- Model `claude-haiku-5-5`, SDK timeout 10 s (the browser waits up to 20 s, `CHAT_TIMEOUT_MS`).
- Order of checks: same-origin `Origin` header (403 `forbidden`), `Content-Type` JSON (415), `Content-Length` present (411) and body ≤ `MAX_BODY_BYTES` 8 KB (413 `too_large`), message validation (400 `bad_request`: last `MAX_HISTORY = 6` messages, user ≤ `MAX_USER_CHARS = 500`, assistant cut to 600), then rate limit, then the Anthropic call.
- Error codes the browser knows are in `CHAT_ERRORS` in `index.html`. Any new code returned by `chat.js` needs an entry there plus a `chat.err.*` string in both `EL` and `EN`, otherwise it shows the generic error.

## Rate limiting (/api/chat)

- Limits: `RATE_PER_MINUTE = 10` (sliding 60-second window) and `RATE_PER_DAY = 50` (UTC day) per IP, constants at the top of `chat.js`. Over the limit: status 429, `{ error: "rate_minute" | "rate_day" }` and `Retry-After`. The browser maps them to `chat.err.rateMin` / `chat.err.rateDay`.
- Storage: D1 database `chat-rate`, binding `RATE_DB` in `wrangler.toml`. One row per allowed question in `hits (ip_hash, ts)`. A single conditional `INSERT ... SELECT ... WHERE count < limit` makes the check atomic, so concurrent requests can't exceed the limit. Rows older than 2 days are deleted on ~2% of requests.
- The IP is never stored: `ip_hash = SHA-256(RATE_SALT + "|" + IP)`, with IPv6 reduced to its /64 prefix. `RATE_SALT` is a secret: `.dev.vars` locally, `npx wrangler pages secret put RATE_SALT --project-name portfolio-martha-charalampidou` in production. Never commit or log it.
- The check runs after request validation and before the Anthropic call. If `RATE_DB` or `RATE_SALT` is missing or D1 fails, the function returns 503 `busy` (fail closed).
- Schema changes: add a new file in `migrations/`, then `npx wrangler d1 migrations apply chat-rate --local` (and `--remote` for production, only after asking).
- Local testing without API cost: `CHAT_MOCK=1` in `.dev.vars` returns a fake reply, only on `localhost`/`127.0.0.1`.

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
- **Head meta (icons, Open Graph).** Icons and `og:*` / `twitter:card` tags are in `<head>`. `og:url` and `og:image` are absolute URLs on `https://portfolio-martha-charalampidou.pages.dev/`, so change them if the domain changes. The OG texts are Greek only and are not part of the i18n system (crawlers don't run JS).
- **Sections** are numbered in their titles (`01.` About, `02.` Skills, `03.` Projects, `04.` Contact). Project cards use keys `p1`…`pN` (`.title`, `.desc`).
- **Chatbot knowledge: single source.** Skills and projects are written only in `index.html`. `chat.js` (`loadSiteContent()`) fetches the page through `env.ASSETS`, parses it with `HTMLRewriter` and builds the SKILLS/PROJECTS part of the system prompt. Other facts (bio, contact, rules) stay hand-written in `PROMPT_HEAD`/`PROMPT_TAIL`. The markup below is a contract with the function:
  - `#skills .skill-card` → `h3` (category) and `.chip` (skills)
  - `#projects article.project` → `[data-i18n="pN.title"]`, `[data-i18n="pN.desc"]`, `.project-tags span`, the first `.project-links a[href]`
  - If you change that markup, update the selectors in `chat.js`. The function logs `N projects, M κατηγορίες skills` on each load and returns 500 `server_error` if it finds no skills, no projects, or a project with no title. The result is cached per isolate in production and reloaded on every request on localhost.

Code comments are written in Greek.

## Rules
- Every layout change must responsive and look good on all screen sizes: phones (from 320px), tablets and desktops.
- Do not push or deploy without asking me first.
