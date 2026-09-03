# AI-Friendly + Distinctive Frontend Starter

A copy-me starter that bakes in `docs/features/UI-UX-FEATURES.md` — **§11 (distinctive,
anti-"AI slop" design)** and **§12 (AI-friendly / agent-readable)**. Framework-agnostic
static HTML; trivially portable to any SSR framework.

## Files
| File | Purpose |
|------|---------|
| `index.html` | Semantic, SSR-ready page. Every fact is in the HTML (not JS) so crawlers/agents read it. Includes OG tags + JSON-LD. |
| `styles/tokens.css` | 3-tier design tokens (primitive → semantic → component); glass material tokens; dark mode by token-swap; `prefers-reduced-transparency/-motion/-contrast` fallbacks. |
| `styles/main.css` | Warm editorial aesthetic (NOT purple-on-white), asymmetric hero, one orchestrated staggered load, visible focus, skip link. |
| `llms.txt` | Curated content map for LLMs (H1 → blockquote → H2 link sections → `## Optional`). |
| `robots.txt` | Per-bot AI crawler policy: allow search/retrieval bots (cite us), block training bots. |

## How to use
1. Copy the folder into a new project; rename `example.com` and the copy.
2. Open `index.html` directly in a browser to preview — no build step.
3. Replace the JSON-LD `@type`/fields with your real entity (`Article`, `Product`, `Organization`…).
4. Generate a `.md` variant per page and keep the `<link rel="alternate" type="text/markdown">` honest.
5. Edit `robots.txt` to your stance (the default = visible in AI answers, out of training data).

## Porting to a framework (do this for real sites)
- **SSR is the highest-leverage AI-friendly move** (§12). Use Next.js / Astro / SvelteKit / Remix so content ships in the server response.
  - **Astro** is the closest match to this static-first structure — drop the HTML into a `.astro` page, move tokens/main into `src/styles`.
  - Add a Markdown-content-negotiation route (`Accept: text/markdown` → serve `.md`) — already consumed by Claude Code/Cursor.
- Keep the token file as the single source of truth; wire it to Tailwind `theme` or CSS-in-JS variables.
- Add `sitemap.xml`, `feed.xml`, and per-page `dateModified` (freshness signals, §12).

## Make it yours (don't ship the example aesthetic)
The warm-editorial look is a *demonstration of intentionality*, not a default to reuse.
Per §11: pick your own extreme (brutalist, luxury, playful, industrial…), swap the
Fraunces/Newsreader pairing for a different distinctive duo, choose a dominant color
that isn't the cliché. The structure (semantic + tokens + a11y + AI-friendly) stays;
the skin should change every time.
