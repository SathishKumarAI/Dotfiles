# Frontend UI/UX Features — General Reference

A **general, reusable** catalog of frontend UI/UX features, patterns, and best
practices — not tied to any one project. Use it as a checklist when designing or
reviewing any web/app interface. Each item: what it is, when to use, key UX consideration.

- **Generated:** 2026-06-18 (web-sourced — Nielsen Norman Group, web.dev, MDN, WCAG/W3C, Material Design, Apple HIG, Smashing Magazine, Laws of UX, GOV.UK/USWDS, Refactoring UI).
- **Scope:** vendor-neutral; applies to any stack (React/Vue/Svelte/plain HTML).
- Sources are listed per section and consolidated at the bottom.

## Contents
1. [Layout & Navigation](#layout--navigation)
2. [Forms, Input & Data Entry](#forms-input--data-entry)
3. [Feedback & System State](#feedback--system-state)
4. [Visual Design, Theming & Design Systems](#visual-design-theming--design-systems)
5. [Motion & Micro-interactions](#motion--micro-interactions)
6. [Accessibility, Responsiveness & Performance UX](#accessibility-responsiveness--performance-ux)
7. [Common UI Components](#common-ui-components)
8. [Onboarding & Engagement](#onboarding--engagement)
9. [Liquid Glass & Glassmorphism](#liquid-glass--glassmorphism)
10. [Cross-cutting Laws of UX](#cross-cutting-laws-of-ux)
11. [Distinctive Design — Avoiding "AI Slop"](#distinctive-design--avoiding-ai-slop)
12. [Building AI-Friendly Sites](#building-ai-friendly-sites)

---

## Layout & Navigation
How interface space is structured and how users move through it — the skeleton that determines whether everything else is findable. Aim for layouts that adapt to any viewport and navigation that answers "Where am I? Where can I go?" at a glance.

### Responsive Layout Systems
- **Mobile-first** — Design the smallest screen first, then layer complexity upward with `min-width` queries. Forces content prioritization; avoids cramming a desktop layout into a phone. Default for modern responsive work.
- **Flexbox vs. CSS Grid** — Flexbox for one-dimensional flows (toolbars, button rows, nav); Grid for true 2D layouts (page scaffolds, dashboards, bento). Mix: Grid for macro structure, Flexbox inside cells.
- **Intrinsic / self-adjusting layouts** — `repeat(auto-fit, minmax(min, 1fr))` + `flex-wrap` + `clamp()` reflow with fewer hand-written breakpoints. Prefer content-driven flexibility over device-targeting.
- **Container queries** — Style a component by its *container's* size, not the viewport. Essential for reusable components (a card that lays out differently in a sidebar vs. wide column).
- **Content-based breakpoints** — Set breakpoints where the layout *breaks*, not at named device widths. Common start: ~600px, ~900px, ~1200px. Test at the seams.
- **Fluid units & type** — Use relative units (`rem`, `%`, `vw`, `clamp()`) so layouts/type scale smoothly rather than snapping.

### Navigation Patterns
- **Top / horizontal nav** — Standard for websites; primary nav in header, utility nav top-right. Best when primary sections fit one row (~≤7 items).
- **Sidebar nav** — Best for deep hierarchies: docs, dashboards, admin apps. Persistent context + easy drill-down. Default location for primary nav in *apps*.
- **Hamburger menu** — A "necessary evil" on small screens; avoid on desktop. Hides options, lowers discoverability. Text label "Menu" tests better than the icon alone.
- **Tab bar** — 3–5 always-visible top-level destinations (bottom iOS, top Android). Ideal for frequent section-switching. Don't exceed ~5 items.
- **Breadcrumbs** — Show path back up a hierarchy; orient users arriving via deep links/search. A secondary aid, never the sole nav.
- **Mega menu** — Expose a large organized link set in one panel. Keep to ~3–4 columns; group logically; add icons/images for information scent.
- **Sticky / scroll-aware headers** — Keep nav reachable on long pages; scroll-aware variants hide on scroll-down, reveal on scroll-up. Keep slim.
- **Click over hover for submenus** — Hover isn't accessible to touch/keyboard; activate on click, mark submenu items with a caret. Avoid multi-level cascading dropdowns.

### Information Architecture & Orientation
- **"You are here" indicators** — Always show current location (highlight, active state, breadcrumbs). Answers the most basic orientation question.
- **Familiar, specific labels** — Recognizable terms, not jargon/invented names. Front-load key words; left-justify vertical menus for fast scanning.
- **Lateral / local navigation** — In-section nav so users browse related content without bouncing through global hierarchy each time.
- **Prioritize content over chrome** — Don't let UI scaffolding crowd out actual content, especially on mobile.

### Layout Composition Patterns
- **App shell** — Persistent frame (nav/header/footer) loads instantly while content streams into the main region. Improves perceived performance; common in PWAs/SPAs.
- **Bento grid** — Modular grid of varying-sized cells, each one self-contained piece; cell size reflects importance. For feature showcases, dashboards, marketing. Start from content hierarchy.
- **Above-the-fold** — Most attention is on the first viewport; place core value prop, primary CTA, key orientation cues there.

### Scanning & Visual Hierarchy
- **F-pattern** — Users scan text-heavy pages in an F. Largely a *failure state* of weak structure — counter with clear headings, short front-loaded paragraphs, bullets.
- **Z-pattern** — On sparse visual pages (landing/signup), eye travels TL → TR → diagonal → BL → BR. Place logo, primary action, CTA along that path.
- **Whitespace** — Groups related elements, separates unrelated, reduces cognitive load, signals premium/calm. An active design tool, not leftover space.
- **Visual hierarchy** — Rank elements with size, weight, color, contrast, spacing so the most important is seen first.

**Sources:** NN/g (menu-design, mobile-navigation-patterns, mobile-subnavigation, navigation-you-are-here), MDN Responsive Design, css-tricks (fewer media queries), LogRocket (CSS breakpoints), Tailwind/StudioMeyer (bento).

---

## Forms, Input & Data Entry
Forms are where users do the work and conversions are won or lost. Reduce effort, validate kindly, and make every field obvious, accessible, and forgiving.

### Form Layout & Structure
- **Single-column layout** — One field per row preserves top-to-bottom momentum. Multi-column only for short linked fields (City/State/Zip).
- **Top-aligned labels** — Fastest completion, fewest errors; left-aligned suits very long forms. Keep label visually close to its field.
- **Visual grouping & white space** — Cluster related fields (address, payment) with spacing/`<fieldset>`/`<legend>` so the form reads as chunks.
- **Keep it short** — Every field is a cost; drop/derive/defer what you can. Mark the minority (whichever is fewer: optional or required).
- **Logical sequencing & tab order** — Order fields the way users think; Tab moves through them in visual order.
- **Single primary action** — One dominant submit; avoid Reset/Clear (accidental loss); keep Cancel low-prominence.

### Labels, Placeholders & Affordances
- **Real labels, not placeholder-only** — Placeholder-as-label disappears on input, strains memory, raises errors, hurts a11y. Use a persistent visible label; reserve placeholders for format hints.
- **Format & requirement hints up front** — State constraints before submission, not only as errors. Eliminate arbitrary formatting rules (accept spaces in card/phone).
- **Match control to input** — Field width hints expected length; radios for 2–4 exclusive options vs a dropdown; checkboxes for multi-select.

### Input Types, Mobile Keyboards & Autofill
- **Correct HTML input types** — `email`, `tel`, `url`, `number`, `date` trigger the right keyboard + native validation. Pair with `inputmode`.
- **`autocomplete` tokens** — Standardized values (`given-name`, `email`, `street-address`, `cc-number`, `one-time-code`) for fast browser/password-manager fill. Critical for motor/cognitive a11y.
- **Masked inputs** — Format-as-you-type (phone, card, currency) reduces errors; keep forgiving, show the pattern, never block paste; password reveal toggle.

### Validation & Error Messaging
- **Inline validation, timed right** — Validate on blur or after input stabilizes, not every keystroke. "Reward early, flag late."
- **Clear, specific, plain-language errors** — Say what's wrong + how to fix, beside/below the field. Preserve input; never wipe the form.
- **Multiple cues, not color alone** — Color + icon + text so colorblind users perceive state. Don't over-celebrate success.
- **Programmatic association** — `aria-describedby` for messages, `aria-invalid="true"` on errored fields, focus/summary at top on submit (WCAG 3.3.1).

### Multi-Step / Wizard Forms
- **Break long forms into steps** — Chunk complex tasks; progressive disclosure + conditional logic show only what's relevant now.
- **Progress indicator / stepper** — Show current position + total (completed/current/upcoming states). Reduces abandonment.
- **Save & resume** — Persist progress so users can leave and return; essential when info isn't on hand.

### Smart Defaults & Friction Reduction
- **Smart defaults** — Pre-fill the likely value (country by locale, today's date) but keep it easy to change.
- **Passwordless & social login** — Magic links, OTP, passkeys, "Continue with Google/Apple." Cap social at ~3; passwordless shows strongest retention.
- **Defer & derive** — Progressive profiling later; derive what you can (zip → city/state).

### Search UX
- **Autosuggest / autocomplete** — Ranked suggestions as users type; highest value on mobile. Keyboard-navigable; don't auto-submit on highlight.
- **Filters vs. facets** — Filters = broad cuts (date/type/price); facets = granular combinable attributes (size/color/brand). Faceted nav finds results faster.
- **Mobile faceted search** — Slide-in tray so users keep result context; applied-filter chips + result counts; easy clear.
- **Scoped search** — Optional category scoping helps but risks hiding results; default to all-content.

### Pickers (Date / File / Select)
- **Date pickers** — Always allow direct text entry alongside the calendar; fully keyboard-operable with correct ARIA (WCAG 2.1.1).
- **Select / dropdowns** — Prefer native `<select>`; custom needs `role="listbox"`/`option`, arrow-key nav, SR announcements. Radios for few options.
- **File upload** — Labeled control, state accepted types/size up front, show filenames + upload progress, errors in text. Drag-and-drop as enhancement only.

### Form Accessibility (cross-cutting)
- **Programmatic labels for every control** — Real `<label for=…>` (also enlarges click target). WCAG 3.3.2.
- **Keyboard operability & visible focus** — All controls reachable/operable with clear focus; logical tab order.
- **Error recovery support** — Identify in text, describe the fix, not color-only; review/confirm before legal/financial submit (WCAG 3.3.4).

### Destructive-Action Confirmation
- **Confirm only consequential, irreversible actions** — Don't gate routine actions or users habituate and stop reading.
- **Restate consequence + specific button labels** — Label with the verb ("Delete account"), not "Yes/OK"; default focus on the safe option.
- **Escalating friction for high-stakes deletes** — Require typing a confirmation phrase. Prefer undo (soft-delete + toast) where feasible.

**Sources:** NN/g (web-form-design, reduce-cognitive-load, form-design-white-space, errors-forms, ecommerce-search, mobile-faceted-search, scoped-search), Smashing (inline validation, dangerous actions), Baymard, LogRocket, MDN (autocomplete, input), USWDS (step-indicator, date-picker), Authgear, WCAG.com.

---

## Feedback & System State
Feedback tells users the system received their input, what it's doing now, and the result. Good feedback respects human time perception, makes every state visible, and always offers a path forward.

### Response Time & Perceived Performance
- **0.1s — instantaneous limit** — Under ~100ms feels like direct manipulation; just react (hover, press, drag).
- **1s — flow-of-thought limit** — Up to ~1s users stay in flow but notice a pause. No progress UI required.
- **10s — attention limit** — Ceiling for keeping focus; show something is happening; beyond it users mentally switch away.
- **Beyond 10s — percent-done + cancel** — Determinate progress + realistic estimate + cancel/background.
- **Perceived performance** — Felt speed > measured speed. Respond instantly, show layout early, use forward motion.

### Loading States
- **Spinner** — Indeterminate, short (≈1–4s) blocking atomic actions (submit/save/auth). Place on the triggering element. Avoid for long/full-page loads.
- **Skeleton screen** — Greyed placeholder mirroring final layout. Best for content fetches; perceived faster than spinners; reduces layout shift. Final content MUST land in the same position/size.
- **Progress bar** — Determinate when measurable (uploads/multi-step); required >~10s. Never stall or go backwards.
- **Optimistic UI** — Update immediately assuming success, reconcile after. For high-success, low-risk, reversible actions. Roll back + retry on failure; pairs with undo.

### Empty States
- **First-use / onboarding** — A blank screen is a teaching moment: what goes here, the value, a primary CTA.
- **User-cleared** — After emptying a list, confirm success positively, not a sad blank.
- **No-results** — Explain why + offer recovery (clear filters, broaden, check spelling, alternatives).
- **Error-as-empty** — Distinguish "nothing here yet" from "failed to load"; the latter needs retry, not onboarding copy.

### Error States & Recovery
- **Inline / field-level** — Next to the field, plain language, what's wrong + how to fix; preserve input.
- **Summary errors** — Grouped summary at top linking to each field, plus inline markers. Aids scanning + SR.
- **Message quality** — Specific, blame the system not the user, no codes/jargon, always state recovery. Never color-alone.
- **Graceful degradation** — Keep the rest usable when a section fails; offer retry/offline/cached.
- **Recovery over blocking** — Prefer letting users proceed and fix over hard-blocking.

### Notifications: Toasts, Snackbars, Inline
- **Toast / snackbar** — Brief, transient, auto-dismissing, non-critical (saved/sent/copied). Don't use for critical/persistent/bulk errors or essential actions. If it carries Undo, give dwell time.
- **Persistent banner / alert** — For ongoing conditions (offline, degraded, account issue) use a non-dismissing inline banner.
- **Accessible announcements** — Mirror to ARIA live regions: `polite` for most, `assertive`/`role="alert"` only urgent. Region must pre-exist; don't steal focus.
- **Inline status** — State where the user looks: badge counts, sync icons, "saving…/saved", availability.

### Success Confirmation
- **Confirm completion explicitly** — Visible signal (checkmark/state change/message); match prominence to importance.
- **Avoid over-confirming** — Don't interrupt routine reversible actions with modal "Success!" dialogs.

### Status Visibility (Heuristic #1)
- **Keep users informed** — Always show what's happening through timely feedback.
- **Surface backstage events** — State users can't see but care about (inventory, sync, background jobs).
- **Never change state silently** — Mark items unavailable rather than quietly removing them.

### Undo vs. Confirm
- **Prefer undo (forgiveness)** — Let it happen instantly + offer Undo. Best for reversible, frequent actions.
- **Confirm only serious, irreversible** — Overuse causes "cry wolf" dismissal blindness.
- **Label buttons with the action** — "Delete file"/"Keep file"; separate consequential from benign options spatially.

### Disabled vs. Hidden, & Progressive Disclosure
- **Disabled vs. hidden** — Disabled = visible but inert; always explain *why* (silent disabled buttons confuse). Hidden = irrelevant to role/context. Modern alternative: keep enabled, show validation error on click.
- **Progressive disclosure** — Reveal advanced/secondary options only when needed (accordions, steps); `aria-expanded` + `aria-controls`.

**Sources:** NN/g (response-times-3-limits, website-response-times, powers-of-10, visibility-system-status, skeleton vs progress vs spinner, confirmation-dialog, proximity-consequential-options, disabled-buttons, user-control-and-freedom), Material (empty states, errors), Carbon (empty-states), Sara Soueidan + Adrian Roselli + Primer (accessible notifications), LogRocket (skeleton).

---

## Visual Design, Theming & Design Systems
Reusable principles for a coherent visual language — typography, color, spacing, theming, and the token/component infrastructure that keeps it consistent at scale.

### Typography
- **Type scale** — Fixed progression (modular ratio ~1.25/1.333), 5–7 steps, reused; not arbitrary values.
- **Hierarchy** — ≥3 levels (heading/subheading/body); differentiate by size, weight, AND spacing.
- **Line length (measure)** — 45–90 chars/line (~66 ideal); `max-width` in `ch`.
- **Line height** — Body ~1.4–1.6; headings tighter (~1.1–1.25).
- **Fluid type** — `clamp(min, vw, max)` scales smoothly between viewports.
- **Font pairing** — 1–2 families (or one variable font); pair by contrast of style.
- **Body baseline** — 16px minimum for body.

### Color
- **60-30-10 rule** — 60% dominant (surfaces), 30% secondary, 10% accent (CTAs/links/active).
- **Palette structure** — 1–2 primary + 1 accent + neutral ramp (8–10 steps) + 4 semantic, each with a lightness scale.
- **Semantic colors** — red=error, green=success, amber=warning, blue=info; named tokens, not raw hex.
- **Contrast (WCAG)** — AA: 4.5:1 normal text, 3:1 large text + UI/icons.
- **Never color alone** — Pair with text/icon/pattern.

### Spacing & Rhythm
- **8pt grid** — Multiples of 8 (4pt half-step for icons/tight text).
- **Spacing scale** — Fixed scale as tokens (4, 8, 12, 16, 24, 32, 48, 64); `rem`.
- **Layout grids** — Consistent gutters/margins; whitespace is structural.

### Dark Mode & Theming
- **Token-swap theming** — Semantic tokens (`surface`, `text-primary`) point to different primitives per theme. Structure for theming from the start.
- **Don't invert** — Dark greys (not pure black); desaturate accents.
- **Elevation in dark mode** — Higher surfaces lighter (shadows are weak on dark); depth via surface tone.

### Design Tokens
- **Three-tier architecture** — Primitive (`blue-500`) → semantic (`color-action`) → component (`button-bg`). Components reference semantic, never raw.
- **Naming** — Descriptive, consistent prefixes; encode role/intent, not appearance.
- **Single source of truth** — Author once (JSON), transform (Style Dictionary), export to CSS/iOS/Android.

### Component Libraries & Design Systems
- **Headless/primitive (Radix, Base UI)** — Unstyled accessible behavior you style. Max control, custom identity.
- **Copy-in (shadcn/ui)** — Pre-styled on Radix + Tailwind, copied into your repo and owned. No dependency lock-in.
- **Full frameworks (Material UI)** — Opinionated, batteries-included. Fastest to ship; hard to escape the look.
- **Choose by control vs. speed.**

### Iconography, Elevation, Radius, Consistency
- **Iconography** — Consistent grid (24px), uniform stroke weight + radius; pair with labels.
- **Elevation & shadows** — Layered surfaces signal depth (modals/menus float); one consistent light source; restraint (heavy shadows feel dated; avoid neumorphism).
- **Border radius** — Small token set (0/4/8/12/full); nested elements slightly smaller than container.
- **Consistency & branding** — System over one-offs; express brand through the token layer so rebrand = token change.

**Sources:** Refactoring-style guides (design.dev, Figma), ModernCSS (fluid type), Toptal/USWDS (hierarchy/typography), Vision Australia + sixtythirtyten + UXPin (60-30-10), InclusiveColors, DesignSystems.com, Material M3 (tokens), Contentful (token system), Muz.li (dark mode), Atlassian + DesignSystems.surf + LogRocket (elevation/shadows), Ramotion (iconography), BuildPilot/Zenrio (shadcn vs radix).

---

## Motion & Micro-interactions
Motion should be functional first — guiding attention, confirming actions, explaining spatial relationships — decorative second. Every animation needs a purpose; when in doubt, make it faster, subtler, or remove it.

### Micro-interactions (feedback)
- **Trigger-feedback pairs** — Every interactive element gets a small contextual response so the UI feels responsive.
- **Hover states** — Signal interactivity on pointer devices. Never hide essential info/actions behind hover-only (no touch).
- **Press/active feedback** — Immediate confirmation on tap/click within ~100ms.
- **Toggle & state-change** — Animate the transition (switch slide, checkmark draw); pair with color/haptics, never motion alone.
- **Inline validation** — Gentle confirm/flag near the input; reserve attention-grabbing motion for genuine errors.

### Transitions & Easing
- **Standard (ease-in-out)** — Default for elements moving between two on-screen positions. Avoid linear (mechanical).
- **Deceleration (ease-out)** — Elements arriving on screen.
- **Acceleration (ease-in)** — Elements leaving.
- **Emphasized vs. standard curves** — Expressive curves for hero/celebratory moments; standard for routine.

### Meaningful Motion
- **Spatial continuity** — Animate along a path reflecting relationship (card expands into detail view).
- **Shared-element / container transforms** — Morph a shared element across screens to keep context.
- **Hierarchy through motion** — Most important element gets most emphasis; stagger guides the eye in reading order.

### Duration & Curves
- **Match duration to distance & size** — Larger/farther = longer; small = faster. No single global duration.
- **Typical ranges** — Micro ~100–300ms; large/full-screen ~300–375ms+; most under ~500ms.
- **Doherty Threshold** — Keep response under ~400ms to maintain flow.
- **Asymmetric enter/exit** — Exits can be quicker (already processed).

### Loading, Entrance & Scroll
- **Skeleton-to-content** — Soft fade/crossfade, not a hard pop.
- **Entrance animations** — Subtle fade/slide-up on first paint; short stagger, above-the-fold only; don't re-animate on scroll-back.
- **CSS scroll-driven animations** — Native scroll/view-timeline over JS scroll handlers (off main thread, no jank).
- **Parallax (sparingly)** — One or two tasteful layers; a full page feels gimmicky + triggers vestibular discomfort. Gate behind reduced-motion.
- **Scrollytelling** — Tie animation to scroll to narrate; stays accessible if motion disabled; simplify on mobile.

### Page Transitions
- **Soft cuts over hard jumps** — Fade/slide between routes; View Transitions API. Keep short (<~400ms perceived), interruptible.

### Accessibility (prefers-reduced-motion)
- **Honor `prefers-reduced-motion: reduce`** — Detect in CSS + JS; remove/replace non-essential motion (WCAG C39).
- **Remove vs. keep** — Remove decorative parallax/large slides/autoplay; keep essential feedback (often swapped to opacity fade).
- **Why** — Motion triggers dizziness/nausea/migraines for vestibular-disorder users (~35% of adults by 40).

### Gesture & Haptic
- **Gesture responsiveness** — Drag/swipe/pinch track the finger 1:1 with rubber-banding at limits.
- **Haptics (mobile)** — Subtle vibration reinforces toggles/selections/success. Use sparingly; never the sole channel.

### When Motion HURTS UX
- **Overuse / competing motion** — Hierarchy collapses; motion is the exception that signals importance.
- **Distraction & cognitive load** — Flashy/constant animation scatters focus.
- **Slow/blocking** — Long durations that gate interaction frustrate power users.
- **Performance jank** — Animate only `transform`/`opacity`; avoid `top`/`left`/`width`/layout. SVG/Lottie over GIF/video; target 60fps; test mid/low-range devices.

**Sources:** Material M3/M2/M1 motion + Google Design, NN/g (microinteractions), web.dev (prefers-reduced-motion, learn/accessibility/motion), MDN, W3C WCAG22 C39, Chrome/css-tricks/Motion.dev (scroll-driven), Laws of UX (Doherty), Lordicon + LogRocket + dev.to (motion mistakes/performance).

---

## Accessibility, Responsiveness & Performance UX
Interfaces everyone can use, on any device, that load and respond fast. These overlap: accessible, fast, resilient UIs are better UX for all.

### WCAG POUR & AA Targets
- **Perceivable** — Text alternatives, captions, contrast, adaptable layout. Never convey info by color/sound alone.
- **Operable** — All functionality via keyboard, enough time, no seizure flashes, navigable structure.
- **Understandable** — Readable, predictable, input assistance; consistent help placement (WCAG 2.2).
- **Robust** — Valid markup, correct name/role/value; prefer native HTML over custom widgets.
- **Target AA, not AAA** — AA is the legal/practical baseline (ADA, EN 301 549, EAA).

### Keyboard Navigation & Focus
- **Logical tab order** — DOM matches visual; avoid positive `tabindex`. `tabindex="0"` to add, `-1` to programmatically focus.
- **Visible focus indicator** — Never `outline:none` without replacement; 3:1 contrast; use `:focus-visible`.
- **Focus management on route/state change** — Move focus to new view heading/first field; return to trigger on close.
- **Skip links** — "Skip to main content" as first focusable; visible on focus.
- **Roving tabindex / arrow-key nav** — Composite widgets (menus/tabs/grids) get one tab stop + arrow keys (ARIA APG).

### ARIA, Roles & Semantic HTML
- **Semantic HTML first** — `<button>`/`<a>`/`<nav>`/`<main>` give free keyboard/focus/role. No ARIA is better than bad ARIA.
- **Landmark regions** — banner/nav/main/complementary/contentinfo; one `<main>`; label repeated landmarks.
- **Accessible names** — Every control named via `<label>`/`aria-label`/`aria-labelledby`; icon-only buttons need a name.
- **Live regions** — `aria-live` for async updates without moving focus.
- **State & relationships** — `aria-expanded`/`selected`/`current`/`controls`/`describedby`, kept in sync with visuals.
- **Heading hierarchy** — One `<h1>`, no skipped levels.

### Color, Contrast & Text Alternatives
- **Contrast ratios** — Body ≥4.5:1, large ≥3:1, UI/graphics ≥3:1; verify hover/disabled/focus too.
- **Don't rely on color alone** — Status/links/charts/required fields need icon/text/pattern; body links need underline.
- **Alt text** — Describe purpose for informative images; `alt=""` for decorative; charts need longer description nearby.
- **Text resize / reflow** — Works at 200% zoom + reflows to 320px-wide with no horizontal scroll; relative units.

### Touch Targets & Pointer Input
- **Target size** — 44×44 CSS px (AAA/Apple HIG); WCAG 2.2 AA minimum 24×24 + spacing. Small targets cause rage clicks.
- **Spacing & hit area** — Pad clickable area beyond the visible icon; Material 48×48dp comfortable minimum.
- **Dragging alternatives** — Any drag needs a single-pointer non-drag alternative (WCAG 2.5.7).

### Responsive & Adaptive
- **Mobile-first** — Smallest viewport first, enhance upward.
- **Fluid layouts** — Flexbox/Grid, relative units, `clamp()`, container queries.
- **Breakpoints by content** — Where layout breaks; also handle landscape/foldables/very large screens.
- **Responsive vs adaptive** — Prefer responsive (one fluid layout) for maintainability.
- **Viewport meta + safe areas** — `width=device-width, initial-scale=1`; respect `env(safe-area-inset-*)`; don't disable zoom.

### Core Web Vitals as UX
- **LCP ≤ 2.5s** — Largest visible element; priority hints, preload hero, fast CDN, no render-blocking.
- **INP ≤ 200ms** — Interaction to Next Paint (replaced FID 2024); break up long tasks, yield, debounce, defer JS. The metric users *feel*.
- **CLS ≤ 0.1** — Visual stability; explicit `width`/`height`/`aspect-ratio`, reserve space, don't insert above existing content.
- **Measure at 75th percentile** of real-user field data, split mobile/desktop.

### Perceived Performance & Loading
- **Skeletons & optimistic UI** — Mirror final layout; assume-success updates.
- **Lazy loading** — `loading="lazy"` + code-split; never lazy-load the LCP/above-the-fold element.
- **Instant feedback** — Respond within ~100ms; >1s show progress; >10s allow cancel.
- **Prefetch/preconnect** — `preconnect` to critical origins, `prefetch` likely-next on hover/intent.

### Responsive Images & Media
- **`srcset` + `sizes`** — Right size per viewport/DPR; `<picture>` for art direction + AVIF/WebP. Biggest LCP/data win.
- **Dimensions & aspect-ratio** — Declare intrinsic size to reserve space (CLS).
- **Captions & transcripts** — Video captions, audio transcripts (WCAG 1.2).

### PWA & Offline
- **Service workers** — Cache shell/assets for offline + instant repeat loads; clear update strategy.
- **Installability & manifest** — Icons/name/theme/display; meaningful offline fallback, not a browser error.
- **Resilience** — Detect connectivity, queue actions, surface offline state; never silently lose input.

### i18n & RTL
- **Locale-aware formatting** — `Intl` for dates/numbers/currency/plurals; never concatenate translated fragments; allow text expansion.
- **RTL support** — `dir="rtl"` + CSS logical properties (`margin-inline-start`); mirror directional icons.
- **`lang` attribute** — On `<html>` + inline language changes for correct SR pronunciation.

### Reduced Motion & Data
- **`prefers-reduced-motion`** — Disable/soften parallax/autoplay/large transitions.
- **`prefers-reduced-data` / Save-Data** — Lighter images, skip autoplay, reduce prefetch.
- **`prefers-color-scheme`** — Honor OS light/dark; contrast holds in both; pair with `prefers-contrast`.
- **No autoplay / pausable motion** — Anything moving/blinking/auto-updating >5s must be pausable (WCAG 2.2.2); never autoplay audio.

**Sources:** W3C WAI (WCAG 2.2 quickref, new-in-22, principles, ARIA APG), MDN Accessibility, web.dev (vitals, INP, thresholds, learn/accessibility), NN/g (response-times, skeleton-screens), A11y Project checklist, Apple HIG accessibility, Material M3 accessible design, MDN (picture, prefers-reduced-motion).

---

## Common UI Components

### Overlays & Disclosure
- **Modal dialog** — Interrupts for a focused decision/input; reserve for critical/destructive confirmations or blocking input. Pitfall: overuse erodes trust; must trap focus, close on Esc, return focus to trigger.
- **Non-modal dialog / side panel** — Act while keeping context visible; great for editing a record while referencing others. Pitfall: may silently become modal on mobile.
- **Popover** — Small contextual surface anchored to a trigger; dismiss on outside-click/Esc. Pitfall: don't nest or stuff with primary tasks.
- **Tooltip** — Brief non-interactive label for an icon/control; appears on hover AND keyboard focus. Pitfall: never hide essential info/actions inside; don't explain obvious conventions.
- **Drawer** — Edge-sliding panel for nav/contextual detail. Pitfall: low discoverability; don't hide primary desktop nav.
- **Bottom sheet** — Mobile surface rising from the bottom within thumb reach; peek vs expanded. Pitfall: don't cover context; obvious dismiss affordance.
- **Accordion** — Stacked expandable sections to reduce page length. Pitfall: users rarely re-collapse; don't hide always-needed content (hurts scan/SEO).

### Navigation & Structure
- **Tabs** — Switch peer views of one context, one panel visible; arrow-key nav (ARIA tablist). Pitfall: not for sequential steps or unrelated destinations.
- **Stepper / wizard** — Ordered steps with progress (Goal-Gradient effect). Pitfall: don't bury validation to the end; allow back-nav.
- **Command palette (⌘K)** — Keyboard fuzzy search over actions/nav for power users; Cmd/Ctrl+K. Pitfall: not a substitute for discoverable UI; needs a visible affordance.
- **Dropdown / select** — One option from a constrained list. Pitfall: short lists → radios/segmented (Hick's Law); keyboard-operable ARIA combobox/listbox.
- **Date picker** — Constrains to valid dates. Pitfall: always allow keyboard typing; respect locale; disable invalid ranges.

### Content Display
- **Card** — Groups related content + actions into a scannable tappable unit; good for heterogeneous collections. Pitfall: card overload + inconsistent heights/actions; make the target clear.
- **List** — Efficient vertical homogeneous items; cheaper to scan than cards for text. Pitfall: hover-only actions break on touch.
- **Data table** — Dense comparison with sort/filter/paginate. Pitfall: edit in side panels not modals; visible active filters; freeze headers; right-align numbers; row Actions menu.
- **Carousel** — Cycles items in limited space. Pitfall: low engagement past slide 1 + a11y traps; pause auto-advance, expose controls, keyboard support.

### Micro-elements
- **Chips / tags** — Compact removable tokens for filters/selections/multi-value input. Pitfall: large + keyboard-deletable remove target; distinguish input vs filter chips.
- **Badge** — Small status/count indicator. Pitfall: pair with text/aria-label; avoid badge inflation.
- **Avatar** — User/entity via image/initials/icon. Pitfall: always provide initials/icon fallback + alt; don't encode identity in color alone.

**Sources:** NN/g (modal-nonmodal-dialog, data-tables), W3C ARIA APG patterns, Laws of UX, Mobbin + UXPatterns + Superhuman (command palette).

---

## Onboarding & Engagement

### First Impression
- **First-run onboarding** — Get users to first value ("aha moment") fast; collect the minimum, route to a quick win. Show value over explaining features; let users start immediately, defer setup.
- **Empty-state-as-onboarding** — Turn a blank screen into guidance: a sample, one clear CTA, one-line benefit. Every empty state should teach the next action.

### Guided Help
- **Product tour / coachmarks** — Overlay callouts on first visit; sparingly, for non-obvious high-value features. Front-loaded "push" tours are skipped — ≤2–3 steps, dismissible, replayable.
- **Progressive onboarding** — Reveal features contextually over sessions (just-in-time), respecting working-memory limits (Miller's Law).
- **Contextual help / hints ("pull")** — Help on demand at point of need (inline tips, "?" popovers). Keep findable later; don't explain standard conventions.
- **Microcopy / UX writing** — Specific, action-oriented labels ("Save changes" not "Submit"); errors say what happened + how to fix; no jargon/blame.

### Sustained Engagement
- **Gamification (progress, streaks, badges)** — Layer game mechanics on *already-valuable* actions. Progress bars exploit Goal-Gradient/Zeigarnik; streaks can breed guilt — start with 1–2 mechanics; product must be valuable even if ignored.
- **Personalization** — Adapt content/defaults/recommendations once you have signal; keep transparent + controllable; sensible defaults for first-run.
- **Settings / preferences** — Ship good defaults so most never open settings; group logically, search when large, separate frequent toggles from rare config.

**Sources:** NN/g (onboarding-tutorials), W3C ARIA APG, Laws of UX, StriveCloud + IxDF + UX Magazine (gamification).

---

## Liquid Glass & Glassmorphism

A translucent, blurred-backdrop UI aesthetic: panels that let the content behind them show through a frosted (and, in Apple's 2025 "Liquid Glass," optically refracted) layer. The core tension is constant — it looks premium and conveys depth, but legibility, accessibility, and GPU performance all fight against it, so every glass surface is a trade-off that must be engineered, not just styled.

### What it is & when it fits
- **Glassmorphism** — static Gaussian blur + semi-transparent fill + thin border, hierarchy via stacking/shadows. Cheap (CSS `backdrop-filter`), consistent regardless of background. Fits SaaS dashboards, fintech, auth/overlay panels where calm and clarity matter.
- **Apple Liquid Glass (WWDC 2025, iOS 26 / macOS Tahoe)** — adds real-time *refraction/lensing* (content behind bends), *specular highlights* that shift on scroll/tilt, reflection mapping, and *adaptive transparency* responding to background brightness. "Hierarchy through depth" — importance signaled by transparency/refraction, not just color/size. On the web it demands SVG displacement filters or WebGL/shaders, not plain CSS.
- **When it hurts** — busy/multicolor backgrounds, dense text, data-heavy tables, low-end devices, vestibular/low-vision audiences. Use glass for chrome (nav bars, sheets, toolbars, modals), not primary reading surfaces.

### CSS implementation essentials
- **`backdrop-filter: blur() saturate()`** — the foundation. Element background MUST be partially transparent or the effect is invisible. Typical: `backdrop-filter: blur(12px) saturate(160%); background: rgba(255,255,255,0.12)`. Saturate boosts bleed-through "vibrancy."
- **Blur radius** — sweet spot ~8–20px for cards; more for busier backgrounds. Keep ≤10px on mobile to avoid dropped frames.
- **Inner highlight / border** — hairline rim sells the glass edge: `border: 1px solid rgba(255,255,255,0.18)` + inset `box-shadow: inset 0 1px 0 rgba(255,255,255,0.4)`; soft outer `box-shadow` for elevation.
- **Rounded shapes** — generous `border-radius` (continuous-corner feel) is part of the language.
- **Noise** — faint tiled noise (PNG or SVG `feTurbulence`) over the fill kills banding; keep ~3–6% opacity.
- **Layering** — content (top) > specular highlight > tint/fill > blurred backdrop; `isolation: isolate` to contain blending.
- **Liquid refraction (advanced)** — SVG `<filter>` with `feTurbulence` + `feDisplacementMap` via `backdrop-filter: url(#filter)` warps the backdrop. Caveat: practically Chromium-only today (Safari/Firefox don't support SVG filters on `backdrop-filter`). Progressive enhancement only.
- **Specular highlight** — rim-light whose intensity varies with surface angle; on web usually faked with a gradient border or moving sheen.

### Legibility & contrast
- **WCAG target** — body 4.5:1, large/bold + UI components 3:1. Hard problem: effective background = whatever shows through, so contrast changes pixel-by-pixel — most naive glass UIs fail AA.
- **Scrim / tint film** — never put text on a ~10% fill. Add a semi-opaque film (~0.2–0.3 alpha) behind text. Past ~0.25–0.3 the glass look fades — balance.
- **Test both extremes** — verify contrast against the *lightest and darkest* content that can ever appear behind the panel, not one mockup background.
- **Adaptive/dynamic text color** — flip text light/dark (or strengthen scrim) by backdrop luminance; Apple's material auto-opaques in bright contexts. `text-shadow` is a last-resort crutch, not a scrim substitute.
- **Vibrancy** — let bleed-through color tint text/icons for cohesion, but only after the contrast floor is met.

### Accessibility (fallbacks mandatory)
- **`prefers-reduced-transparency`** — drop translucency: solid (or near-solid) background, remove/cut blur. Mirrors OS "Reduce Transparency."
- **`prefers-reduced-motion`** — gate all specular/sheen/morph animation; render glass static.
- **`prefers-contrast: more`** — raise fill opacity toward solid, strengthen borders + text contrast.
- **`forced-colors: active`** (Windows High Contrast) — system colors override backgrounds; use system color keywords for borders/text; layout must read with no blur.
- **Apple's triad** — Reduce Transparency → opaque material; Increase Contrast → borders/darken; Reduce Motion → stop light-reactive highlights. Mirror on web.
- **Test** — VoiceOver/NVDA/TalkBack, zoom, dark mode, blur as a sensory trigger.

### Performance
- **Most expensive compositing effect** — browser snapshots pixels behind the element into a texture, runs the blur kernel, recomposites; cost scales with blurred **area × radius**.
- **Stacked layers multiply cost** — 8 layers at growing radii can hit ~200ms/frame over 1080p on mid GPUs. Keep simultaneous glass layers to **2–3 max**.
- **INP / jank** — heavy backdrop work during interaction pushes INP past 200ms. `backdrop-filter` on `position: fixed` causes severe iOS scroll jank (repaints every frame) — avoid.
- **Hints** — `will-change: backdrop-filter` before an animated transition; `transform: translateZ(0)` to promote a layer. Don't leave `will-change` on permanently.
- **Mobile** — cap blur ~10px; full-screen blur is worst case. Prefer one big blurred surface over many small panels.
- **Avoid in** — long scrolling lists, video/animated backgrounds, low-end/battery-sensitive contexts.

### Fallbacks & progressive enhancement
- **Feature-detect** — `@supports (backdrop-filter: blur(1px)) or (-webkit-backdrop-filter: blur(1px))`; test the *simplest* value, not a fancy one.
- **Solid fallback first** — author a readable solid/translucent default, then enhance with blur inside `@supports`. UI must be fully usable with zero blur support.
- **Safari prefix** — Safari < 17 needs `-webkit-backdrop-filter`; ship both. ~97%+ support overall, but prefix + SVG-filter gaps are real.

### Depth & design tokens
- **Material levels as tokens** — fixed elevation tiers (L0 opaque base, L1 subtle glass, L2 modal glass), each pairing **blur radius + fill opacity + border + shadow**. Don't free-hand per component.
- **Consistent layering rules** — higher elevation = stronger blur/opacity/shadow; never stack same-level glass on glass. Tokenize `--glass-blur`, `--glass-fill`, `--glass-border` for themeable light/dark/high-contrast variants.

### Motion
- **Light-reactive highlights** — specular sheen shifting on scroll/pointer/tilt; tasteful in moderation, expensive + distracting in excess.
- **"Liquid"/morphing transitions** — panels fluidly grow/merge on open (Apple's signature); approximate with transform/clip-path, full refraction needs SVG/WebGL.
- **Always gate behind `prefers-reduced-motion`** — vestibular users directly harmed by reactive/morphing glass; provide a static equivalent.

### Pitfalls / anti-patterns
- **Overuse** — glass on everything destroys the depth hierarchy it creates; reserve for chrome/overlays.
- **Low contrast** — text on thin translucent fill over busy imagery (the #1 failure); fix with a scrim.
- **Busy backgrounds** under text-heavy glass — raises blur cost AND wrecks legibility.
- **Perf death by a thousand panels** — many simultaneous `backdrop-filter` elements (lists/grids/cards) tank frame rate + INP.
- **`position: fixed` + backdrop-filter on iOS** — scroll jank.
- **No fallback** — assuming blur support; unreadable panels on unsupported/Reduce-Transparency setups.
- **Animating motion without a reduced-motion escape hatch.**

**Sources:** Apple HIG Materials; MDN (backdrop-filter, blur/saturate filter functions, prefers-reduced-transparency, prefers-contrast, forced-colors); Chromium GPU-compositing + Chrome DevTools perf; caniuse (css-backdrop-filter); CSS-Tricks almanac; Axess Lab (glassmorphism a11y); DesignMonks (liquid-glass vs glassmorphism); kube.io + LogRocket (liquid-glass CSS/SVG); EverydayUX.

*Note: Apple HIG Materials page is JS-rendered (not fetchable); Apple-specific behavior (Reduce Transparency/Motion/Contrast, vibrancy, hierarchy-through-depth) corroborated via WWDC-2025 coverage + design analyses rather than quoted directly. SVG-refraction approach is currently Chromium-only — flagged as progressive enhancement.*

---

## Cross-cutting Laws of UX
Apply these across every section above:
- **Jakob's Law** — Match platform/web conventions so it "just works."
- **Hick's Law** — Minimize visible choices to speed decisions.
- **Fitts's Law** — Bigger + closer targets are faster to hit; size primary actions generously.
- **Doherty Threshold** — Keep response under ~400ms or show progress.
- **Miller's Law** — Respect working-memory limits (~7±2); chunk.
- **Goal-Gradient / Zeigarnik** — Motivation rises near completion; show progress.
- **Peak-End Rule** — Design strong peaks and endings into flows.
- **Aesthetic-Usability Effect** — Polished UIs are perceived as more usable (don't let it mask real issues).

*Reference: https://lawsofux.com/*

---

## Distinctive Design — Avoiding "AI Slop"
*Added from the `frontend-design` skill.* The sections above keep a UI usable, accessible, and fast — necessary, but not enough. They describe the floor, not the ceiling. This section is the ceiling: how to make an interface **memorable and intentional** instead of generic. Default AI-generated UI ("AI slop") is technically correct and instantly forgettable; distinctive design is what separates a shipped product from a template.

### Commit to a bold aesthetic direction (before coding)
- **Pick an extreme, then execute precisely** — Choose one clear tone (brutally minimal, maximalist, retro-futuristic, organic, luxury/refined, playful/toy, editorial/magazine, brutalist/raw, art-deco/geometric, industrial). Both bold maximalism and refined minimalism work — the win is *intentionality*, not intensity.
- **Answer 4 questions first** — Purpose (what problem, who uses it), Tone (the extreme above), Constraints (framework/perf/a11y), Differentiation (the one thing someone will remember).
- **Match code complexity to the vision** — Maximalist → elaborate animation/effects; minimalist → restraint, precise spacing/type. Elegance = executing the vision well, not adding more.

### Typography with character
- **Avoid generic fonts** — No Arial, Inter, Roboto, system-default, or the overused "safe" picks. Pick distinctive, characterful faces that elevate the aesthetic.
- **Pair display + body** — One distinctive display font for impact, one refined body font for reading. The pairing carries most of the personality.
- **Don't converge** — Never default to the same trendy face every time (e.g. Space Grotesk). Vary across projects.

### Color & theme with conviction
- **Dominant + sharp accent beats timid/even palettes** — Commit to a cohesive scheme; let one color dominate and accents punch. Drive it all through CSS variables.
- **Vary light/dark + aesthetic per project** — Don't reach for the same combo each time. Especially avoid the cliché purple-gradient-on-white "AI look."

### Spatial composition that surprises
- **Break the grid** — Asymmetry, overlap, diagonal flow, grid-breaking elements. Either generous negative space OR controlled density — chosen deliberately.
- **Unexpected layouts** — Avoid the predictable hero→3-cards→footer template unless subverted with intent.

### Motion as a high-impact moment
- **One orchestrated page-load > scattered micro-interactions** — A single well-staggered entrance (sequenced `animation-delay`) delivers more delight than many random hovers.
- **Surprise on scroll/hover** — Scroll-triggered reveals and hover states that do something unexpected. (Still gate behind `prefers-reduced-motion` — see §5/§9.)
- **CSS-first for HTML; Motion library for React** when available.

### Backgrounds & atmosphere (not flat fills)
- **Create depth, not solid color** — Gradient meshes, noise/grain textures, geometric patterns, layered transparencies, dramatic shadows, decorative borders, custom cursors. Match the texture to the aesthetic.

### The "AI slop" blocklist (what NOT to do)
- Overused fonts (Inter/Roboto/Arial/system); cliché purple-on-white gradients; predictable layouts + cookie-cutter component patterns; evenly-distributed timid palettes; solid flat backgrounds with no atmosphere; context-free design that could belong to any product. **If it looks like the default template, redesign it.**

*Relationship to the rest of this doc: §1–§9 are the constraints distinctiveness must respect (a bold design that fails contrast or jank is still a failure). Apply this section to choose the vision; apply the others to keep it honest.*

**Source:** `frontend-design` skill (Claude Code official plugin) — frontend aesthetics guidelines.

---

## Building AI-Friendly Sites
*Added per request: make the doc support building a modern site that AI agents/LLMs/assistants can read, understand, cite, and act on.* AI agents, LLM assistants, and AI crawlers are now a first-class audience alongside humans. They consume your **raw server response**, not the rendered browser page — so machine-legibility (clean HTML, structured data, discoverable actions, crawler permissions) decides whether your content can be read, cited, and acted on. Most of this overlaps with the accessibility/semantic hygiene already in §6.

### llms.txt — the proposed discovery standard
- **`/llms.txt`** — Markdown file at site root mapping your most important content ("sitemap for reasoning models"). Order: single H1 (only required element), a `>` blockquote summary, optional prose, then H2 sections of annotated links `- [Title](url): note`. Put less-critical links under a final `## Optional` H2 so tools can drop them under tight context budgets.
- **`/llms-full.txt`** — One file concatenating full docs as Markdown for direct paste-in; gets ~3–4× the traffic of `llms.txt` (Mintlify data). Automate generation to avoid drift.
- **Differs from** — `robots.txt` *restricts* access; `sitemap.xml` lists every indexable HTML URL; `llms.txt` is a *human/tool-initiated, on-demand curation*.
- **Reality check** — Major crawlers (GPTBot, ClaudeBot, PerplexityBot) don't request `llms.txt` unprompted yet (~95% of hits in one study were Googlebot). Real value today is human-mediated ("paste this URL") + agent/IDE tooling. Cheap to ship; not a magic visibility lever.

### Machine-readable structure (accessibility == agent legibility)
- **Semantic HTML5** — `<header>/<nav>/<main>/<article>/<section>/<aside>/<footer>` over div-soup; doubles as ARIA landmarks + a parseable outline for free.
- **ARIA landmarks** — Add `role`/`aria-label` only where HTML lacks an element; disambiguate repeated landmarks (two `<nav>`s) with `aria-label`. Aim for all content inside a landmark.
- **Clean heading hierarchy** — One `<h1>`, no skipped levels. Headings are the primary chunking signal for both screen readers and LLMs.
- **Meaningful link text** — "Read the pricing guide", not "click here." It's the anchor an agent uses to decide where to go.
- **Stable IDs/anchors** — Durable heading `id`s enable deep-link citations (`/docs#rate-limits`) that survive crawls.

### Structured data (reliable entity extraction)
- **JSON-LD (Schema.org)** — `<script type="application/ld+json">`; high-value types `Article`/`Organization`/`FAQPage`/`HowTo`/`Product`/`BreadcrumbList`. **Caveat:** table-stakes for Google rich results, but controlled tests found ChatGPT/Claude/Perplexity/Gemini largely *ignore* JSON-LD — not a guaranteed LLM-citation win.
- **Open Graph / metadata** — `og:title/description/url/image` + `article:published_time`/`modified_time`. AI crawlers read `og:description` + dates when deciding to cite; stale `modified_time` correlates with citation drop-off.
- **Canonical + meta** — `<link rel="canonical">`, accurate `<title>`/`<meta name="description">`, correct `lang`.
- **Feeds & APIs** — RSS/Atom/JSON Feed for freshness; publish an **OpenAPI** spec for any API so agents discover endpoints instead of scraping.

### Content for LLM extraction
- **Server-side rendering is critical** — Crawlers read raw HTML, not JS-hydrated DOM. Important content must be in the server response (SSR/SSG/prerender); pure client-side SPA content is often invisible.
- **Ship Markdown variants** — Serve clean `.md` per URL (`/page.md`); Cloudflare measured ~16k HTML tokens → ~3k Markdown (~80% less) for the same content.
- **Advertise the Markdown** — `<link rel="alternate" type="text/markdown" href="/page.md">` + HTTP `Link:` header; support `Accept: text/markdown` content negotiation with `Vary: Accept` (already used by Claude Code, Cursor).
- **Chunkable, self-contained** — Descriptive headings + a leading topic sentence per section so passages quote without context. Enriching *visible* text wins big (a study: quotations +43%, statistics +33%, citing authorities +115% citation rate).
- **Don't trap content** — Keep facts out of images-only/charts (add alt + text equivalent), JS-only widgets, and canvas; provide transcripts for audio/video.

### Agent actionability
- **Predictable, stable URLs** — Logical RESTful human-readable paths; avoid opaque session IDs and hash-routing-only nav.
- **APIs over scraping** — Documented API (OpenAPI) for actions agents need; far more reliable than DOM scraping.
- **MCP (Model Context Protocol)** — Anthropic's open standard (Nov 2024; OpenAI adopted Mar 2025) exposing **Tools, Resources, Prompts** to agents. 2025-03/2025-06 specs add **Streamable HTTP** for hosting a *remote* MCP server so agents call your site's capabilities directly. Best path for "let agents *do* things here."
- **Discoverable forms/actions** — Real `<form>`, `<label>`-associated inputs, proper `name`/`type`/`autocomplete`, clear submit buttons so agents fill/submit reliably.
- **Clear auth boundaries** — Public content public + crawlable; gate write/sensitive actions behind documented auth (OAuth/API keys), not ambiguous walls.

### AI crawler controls (robots.txt)
- **Bot taxonomy** — *Training* crawlers (`GPTBot`, `ClaudeBot`, `Google-Extended`, `CCBot`) feed model training; *search/retrieval* agents (`OAI-SearchBot`, `ChatGPT-User`, `Claude-SearchBot`, `Claude-User`, `PerplexityBot`) fetch live to answer/cite.
- **Core trade-off** — Blocking *training* bots keeps content out of weights with **no** Google ranking impact (Google-Extended isn't a Search signal). Blocking *search/retrieval* bots removes you from AI answers + citations. Decide per-bot, not all-or-nothing.
- **Syntax** — Per-user-agent `Allow`/`Disallow`. "Welcome mat" = `Allow: /` for search/retrieval set; selectively `Disallow: /` the training set for visibility without training.
- **Footgun** — A blanket `User-agent: * / Disallow: /` or aggressive WAF rule silently delists you from AI search. Audit deliberately.

### Generative-UI / freshness considerations
- **Freshness signals** — Recently-updated content cited ~4.3× more; ~85% of AI-Overview citations are <2 years old. Keep `dateModified` + `article:modified_time` honest.
- **Quotable units** — Inverted pyramid (answer first, then support); short paragraphs, definitional sentences, comparison tables, FAQ blocks.
- **Cite sources** — Pages that cite authoritative sources are themselves cited more.
- **Performance** — Fast SSR/TTFB lets crawlers fetch more pages within budget; slow JS-heavy pages get partially or never indexed.
- **GEO ≠ SEO** — <10% of LLM-cited sources rank in Google's top 10 for the same query; optimize for citation/extraction, not just rank.

### Pitfalls (checklist)
- Content rendered only by client-side JS; infinite scroll with no linkable paginated URLs; paywalls/auth hiding substance; vague labels/icon-only buttons/unlabeled inputs; no structured data/canonical/wrong `lang`; facts locked in images/charts/video with no text; accidentally blocking *all* bots; relying on things nothing reads (`ai.txt`, `<meta name="llms">`, HTML comments, UA-sniffing — also cloaking risk); treating `llms.txt`/JSON-LD as guaranteed citation levers (ship cheap, but invest most in **SSR + rich visible text**).

**Sources:** llmstxt.org; Evil Martians (LLM visibility, "what doesn't work"); Google Search Central (structured data, Google-Extended); modelcontextprotocol.io (2025-06 spec); MDN/W3C ARIA landmarks; ogp.me; Anthropic/Cloudflare bot docs; Anagram, ahrefs, Semrush, ALM Corp, Frase (GEO).

---

## Consolidated Sources
Primary authorities used across this document:
- **Nielsen Norman Group** — nngroup.com (heuristics, forms, navigation, response times, data tables, onboarding)
- **W3C WAI / WCAG 2.2 / ARIA APG** — w3.org/WAI
- **web.dev** (Google) — Core Web Vitals, performance, accessibility, motion
- **MDN Web Docs** — developer.mozilla.org (HTML/CSS/ARIA reference)
- **Material Design** (M2/M3) — material.io / m3.material.io
- **Apple Human Interface Guidelines** — developer.apple.com/design
- **Smashing Magazine**, **LogRocket**, **Baymard Institute** — applied UX articles
- **Laws of UX** — lawsofux.com
- **GOV.UK / USWDS design systems**, **Refactoring UI**, **The A11y Project**
