# Features & Changes — My Applications

Consolidated feature list and notable changes per app I built, gathered from each
repo's docs (README, FEATURE guides, ADR/DECISIONS, CHANGELOG/WORKLOG, architecture).

- **Generated:** 2026-06-18
- **Scope:** my own apps under `~/coding/` (cloned course/learning repos excluded — see bottom).
- **Source:** docs only (not source code). Update by re-running the doc-gathering pass.

---

## bujo
**What it is:** Private, local-first bullet-journal + health tracker web app — everything in the browser, no accounts/server/tracking.
**Stack:** Vite · React 19 · TypeScript · Tailwind v4 (Catppuccin) · shadcn/ui + Radix · Recharts · Vitest · PWA · localStorage.

**Features:**
- Rapid-logging bullet method (tasks/events/notes + signifiers); daily log with mood/stress/sleep, gratitude, on-this-day resurface.
- Monthly calendar (event dots, location, goals, month photo); habit dot-grid (30/90-day consistency, weekly goals, drag-reorder, archive).
- Fitness (cardio + 14-day calorie trend), Nutrition (macro diary + food DB), Gym (strength training, exercise library w/ wger, muscle map, PRs, body-weight + progress photos), Pull-ups program tracker.
- Challenges (75 Hard/Soft, 90-day, custom; strict/lenient); Focus/Developer coding-session tracker; opt-in Cycle (basal temp) + Streak/NoFap journals.
- Stats (activity heatmap, radar, sleep↔mood scatter, year-in-pixels), Insights (correlations, year-in-review, full-text search, tag manager).
- Future log, Collections (contacts/birthdays), recurring tasks, .ics import, Plan/Migration.
- Optional passcode + AES-GCM encryption (PBKDF2); export JSON/MD/CSV/PDF; cloud sync (Google Drive, GitHub gist, Vercel Blob E2E-encrypted, optional Supabase).
- PWA offline/installable; themes (Mocha/Latte/Neon) + accent picker; global units (kg/lb, km/mi, °F/°C); command palette (⌘K), undo/redo, voice dictation.

**Key changes / decisions:**
- Unified Fitness hub (Cardio + Strength tabs), Gym→Strength mode, Pull-ups dedicated view (D-38).
- shadcn/ui re-themed to Catppuccin (D-18); ~113 KB gzip, charts lazy-loaded (~100 KB).
- Composable app shell (`AppShell`/`Sidebar`/`TopBar`/`Page`), sticky top bar for undo/zoom/theme (D-19).
- Gendered wellbeing opt-in only, never prompted (D-07); contact enrichment consent-based, official GitHub API only, web-scraping rejected (D-31).
- Goals = read-only roll-up, no separate store (D-32); motion OS-controlled via `prefers-reduced-motion` (D-33).
- Passcode encryption at-rest; wrong passcode throws but never wipes; no recovery if lost (D-30).
- Cloud sync Vercel Blob E2E (passphrase) (D-40); optional Supabase guest→email linking, off by default, additive to local-first (D-41).
- 200+ Vitest tests; pure logic in `src/lib/` separated from views. v2: Goals view, tracker visualizations, advanced filters, Friends collection (June 2026).

---

## Pickleball-Vision-LLM
**What it is:** AI coaching system combining computer vision + LLMs to analyze pickleball matches and deliver real-time strategic feedback.
**Stack:** Python 3.12 (mise) · FastAPI + uvicorn · YOLOv8 (ultralytics) · MediaPipe · LangChain · sentence-transformers · PyTorch (CUDA) · OpenCV · Docker.

**Features:**
- Ball detection/tracking (YOLOv8, ~4.28 FPS CPU); player pose estimation (MediaPipe); court detection + spatial mapping.
- Frame quality assessment (brightness/contrast/blur) + optical-flow motion detection; preprocessing (resolution standardize, contrast, denoise).
- Real-time video pipeline; game-state interpretation + strategy analysis via LLM; natural-language coaching tips.
- FastAPI web UI with streaming + visualization dashboard; user profiles; REST endpoints (ball detection, metrics, health).
- YouTube-sourced data-collection pipeline for pickleball training datasets; DVC dataset versioning.
- Testing framework with config profiles (default/high-quality/high-motion/balanced); batch processing + caching; Black/Flake8/MyPy + pre-commit.

**Key changes / decisions:**
- Phase-1 ball detection with frame-quality + motion gating to build clean training data.
- Modular layout (vision/llm/fusion/core/integration/web); multi-modal fusion layer syncs vision + LLM in real time.
- Docker + production compose; CI/CD with pre-commit + GitHub workflow; Grafana monitoring dashboards.

---

## Dotfiles
**What it is:** chezmoi-managed Rocky Linux / GNOME 49 Wayland workstation config — dotfiles + setup scripts + docs, themed Catppuccin Mocha.
**Stack:** chezmoi · mise · bash/zsh · starship · zellij · WezTerm (Lua) · neovim · GNOME extensions · shell setup scripts.

**Features:**
- chezmoi-tracked configs (bashrc, zshrc, wezterm.lua, etc.) with `apply --force` + `personalize.sh` workflow.
- WezTerm power-user layer: Catppuccin gradient, tab-title/status events, `Ctrl+a` leader (splits/zoom/pane-picker/workspaces), resize key-table, window snap/maximize/center, fuzzy switcher, GitHub hyperlink rule; launches maximized.
- niri-like tiling on GNOME via PaperWM + AATWS (advanced-alt-tab); hover-reveal taskbar (Dash to Panel intellihide).
- Setup scripts: GNOME installers wired into `setup.sh` with sudo/user phase split; idle CLI tools (atuin/direnv/delta); install-wezterm, validate-install, verify-keyboard, remove-unwanted-apps.
- Performance scripts: `speedup-boot.sh` (docker socket-activation, plocate timer off), `optimize-responsiveness.sh` (tracker3 taming + extension toggles for the spinning-HDD machine).
- Docs: WORKLOG.md (dated entries via `/document` skill), terminal/wezterm.mdx keybind tables, KEYBOARD-SHORTCUTS.md.

**Key changes / decisions:**
- Additive-only config policy — extend tables / occupy unused prefixes, never delete or rebind existing settings.
- Maximize (not fullscreen) on WezTerm startup to keep tab bar + window controls.
- Bugs validated not guessed (`wezterm ls-fonts`, `show-keys`, `shellcheck`); migration seeds from canonical config, not stale copy.
- Diagnosed slowness as I/O-bound on a 7200rpm HDD (not CPU/space); real fix = SSD.

---

## Job-Automations (Dice Outreach)
**What it is:** Automated email-marketing + job-search outreach platform integrating Gmail, LinkedIn, Dice.com, and EspoCRM — runs locally, no Docker.
**Stack:** Python 3.11 · Streamlit (UI) · FastAPI (backend) · PostgreSQL · SQLAlchemy · Gmail OAuth 2.0 · Conda.

**Features:**
- **Ingest:** Gmail v3 OAuth pipeline w/ regex/HTML/OCR/vCard contact extraction; Python JobSearch; LinkedIn job imports; Dice scraper; universal CSV/Excel importer.
- **Operations:** LinkedIn signatures manager; email draft queue; rate-limited batch outreach tracker; templates w/ variable substitution; follow-up scheduler w/ Google Calendar sync; exports.
- **Review:** LinkedIn profile lookups; bulk email copier; audit/activity journal w/ filters; rules & blocklist engine; volume/recruiter analytics; Excel viewer.
- **CRM:** Recruiter dashboard (metric tiles, filterable table, status/source charts, profile search).
- **Core:** single-source-of-truth contact extractor (regex + HTML SAX + OCR + vCard) with confidence scoring (email 35% / phone 25% / name 15% / company 15%).

**Key changes / decisions:**
- Streamlit over React (Python-first, zero build) (ADR-001); single-page v3 dashboard w/ session-state routing (ADR-002); FastAPI split out for OAuth callback + async (ADR-007).
- v3 redesign (2026-05): segmented-control tabs (Home/Ingest/Ops/Review/CRM), keyboard shortcuts, compact layout.
- Consolidation (2026-05): archived dead `gmail2/`, docs 117→24, `utcnow()`→tz-aware across 34 files, unified DB session util across 10 tabs.
- Reusable `PipelineRunner` for multi-stage pipelines (ADR-008); 4 named themes via single injected CSS template (ADR-010).

---

## Nexus-Job-Automations
**What it is:** Email-marketing + job-search automation platform for recruiter outreach, Gmail integration, and multi-source job tracking with DB-backed workflows. (Successor/sibling to Job-Automations.)
**Stack:** Python 3.11+ · Streamlit · PostgreSQL/SQLite · SQLAlchemy · FastAPI · Playwright · Gmail API · Google Sheets API · Typer (CLI).

**Features:**
- Gmail ingestion + signature parsing + recruiter extraction; multi-source scraping (Dice, LinkedIn, Python boards).
- Recruiter CRM (contacts, status, enrichment); outreach campaigns w/ rate limiting + scheduling; templates w/ categorization + usage tracking.
- Import center (CSV/Excel upload, validation, dedup, blocklist); rules & blocklist across all workflows.
- Unified Streamlit dashboard (v1/v2/v3, 14+ tabs); analytics (daily trends, recruiter distribution); follow-up scheduler w/ Calendar sync.
- Export/import (CSV/Excel/JSONL); journaling/audit trails; automated test suite w/ file-watch, dashboard, Docker.

**Key changes / decisions:**
- Phase 1–10 delivery; DB schema tuned for 10M+ rows (WAL, 64MB cache, mmap I/O, indexing).
- Canonicalization: consolidated Gmail v3 + storage layer + UI versions into single sources of truth; clear layering (UI→Services→Integrations→Storage→Domain) with deprecation shims.
- Added 6 models (Recruiter, EmailRecord, ImporterLog, Template, Blocklist, FollowUp); Pydantic settings; all tests mocked (no real keys).

---

## pickleball-shuffle (Paddol)
**What it is:** Mobile-first, local-first web app combining 1,729 pickleball twist cards with a real-time scorekeeper.
**Stack:** Next.js 16 · React 19 · TypeScript · Tailwind v4 · Lucide · PWA · Vercel.

**Features:**
- 1,729 twist cards across 10 categories → 5 deck modes (Family→Chaos); rarity badges, intensity, dual text styles (concise + commentator voice).
- Custom deck builder (save personal cards); full scorekeeper (side-out scoring, win-by-2, serving indicator, undo, persisted pause).
- Match tracking (single / best-of-3 / best-of-5 + celebration); resume last game; match history; export/import backup (all local).
- PWA installable + offline; dark/light themes; haptics & sound; accessibility (focus rings, dialog semantics, 44px targets, SR labels, motion respect).

**Key changes / decisions:**
- Deck grown 200 → exactly 1,729 (Ramanujan taxicab) via deterministic generator.
- Reload-surviving pause; configurable match length; commentator-voice toggle; per-card rarity/metadata.
- Accessibility audit fixes (contrast, dialog semantics, reduced-motion); custom fonts; rebranded shuffle→card-games; CI gates (lint + tsc + build).

---

## Dice_automation (Dice Auto Helper V2)
**What it is:** Chrome/Brave MV3 extension automating job applications on Dice.com — form steps, recruiter capture, tab management.
**Stack:** Chrome Manifest V3 · JavaScript · File System Access API · message passing.

**Features:**
- Easy Apply automation (detect/click, navigate multi-step forms); recruiter capture (name/email/phone → CSV); tab nav (auto-close done, open next).
- Leave-confirmation auto-dismiss; terminal-state detection (skip unavailable/applied); blocklist/allowlist (company/recruiter/keyword).
- Safety limits (auto-pause after N w/ continue); configurable auto-run timer; floating draggable dashboard; storage fallbacks (sync→local→background).

**Key changes / decisions:**
- Consolidated multiple versions into single MV3 codebase; separated "Open All Easy Apply" (tabs) from per-job clicking.
- Login modal wait/resume (polls ≤2 min); DOM-selector + URL-fallback detection (no element hallucination); diagnostics logging; idempotent requests (no dup closes/nav).

---

## resume-automation
**What it is:** LaTeX-based system building ATS-friendly resume PDFs/DOCX from modular sources with keyword-coverage tooling.
**Stack:** LaTeX (pdf/lua/xelatex) · Python 3.8+ · Pandoc · Flask (optional) · TeX Live.

**Features:**
- Modular structure (header/summary/skills/experience-per-role/projects/education); OS-independent `build.py` w/ engine auto-detect + container fallback.
- ATS keyword helper (`ats_helper.py`) checks JD coverage without editing; Claude `/tailor-resume` for truthful job-specific tailoring.
- Multiple role overlays (data-analyst, genai-engineer…) sharing one codebase; Resume Studio web GUI (browse roles, build, preview, ATS check); CI builds PDF on push.

**Key changes / decisions:**
- Recovered from host crash (zero-byte binaries); made source engine-agnostic; unified five per-OS build scripts into one `build.py`; added `repair-toolchain.sh`.
- Humanized resume voice (varied openings, fewer buzzwords, real metrics only); reframed summary around GenAI/RAG + Neo4j KG differentiator.
- Truthful JD tailoring (never fabricates; gaps surfaced; per-job branches); added reusable `~/coding/docs/templates/`.

---

## RAG
**What it is:** Production-oriented Retrieval-Augmented Generation pipeline with multi-modal document processing, vector search, and LLM integration.
**Stack:** Python (LangChain, LangGraph) · FastAPI · Pinecone · AWS (S3, DynamoDB, Bedrock) · MLflow · Kubernetes/Helm · GitHub Actions.

**Features:**
- Multi-format loading (PDF/HTML/DOCX/CSV/JSON/images); chunking strategies (fixed-window, markdown-aware, page-based, recursive).
- Embeddings (OpenAI + local); abstract vector-store interface (in-memory/FAISS/Chroma/Pinecone); hybrid retrieval (vector + keyword) + re-ranking.
- LLM-agnostic inference (OpenAI + Bedrock); evaluation framework (exact match, F1, hit rate, recall@k); MLflow tracking + registry.
- AWS infra (S3 raw, DynamoDB metadata); structured JSON logging; pytest suite (>80% target).

**Key changes / decisions:**
- Refactored monolith → modular three-layer architecture (utilities / RAG core / storage); abstract vector store for backend swapping.
- Production structured logging w/ tracing; docs-first (architecture diagrams, gaps analysis); 4 notebooks (explore/demo/embedding/eval).

---

## insta_reels_scrap
**What it is:** Pipeline to download Instagram reels and extract content as structured data, then render PDFs + a searchable docs site with local semantic search.
**Stack:** Python 3.12 · Streamlit · Claude Code CLI (vision) · faster-whisper · easyocr · fastembed · weasyprint · mkdocs-material.

**Features:**
- Multi-source ingest (public URLs via yt-dlp, private via browser cookies, profiles, hashtags, saved); genre-aware structured extraction w/ frame+timestamp provenance.
- Transcript generation, on-screen OCR, vision field extraction; Catppuccin PDF rendering + linked mkdocs site.
- Local semantic search over summaries/fields/transcripts/facts; bounded-parallel batch (3 workers, thread-safe model loading); CLI + Streamlit UI.

**Key changes / decisions:**
- Claude Code CLI (subscription) as default vision backend, Anthropic API fallback; local-first (Whisper/easyocr/fastembed on-device); static ffmpeg via pip (no sudo).
- Structured + frame-provenance over prose to resist hallucination; public-default w/ cookie-only login opt-in; ~7 min / 20 clips at 3 workers vs ~20 min sequential.

---

## lona_access_ai (loan-division-tracker)
**What it is:** Browser React app managing one bank loan divided among multiple borrowers — tracks EMI repayments under variable interest-rate timelines with full numerical transparency.
**Stack:** React 19 · TypeScript · Vite · Tailwind v4 · Zustand · decimal.js · Recharts · jsPDF + SheetJS · pdf.js · Vitest.

**Features:**
- Reducing-balance EMI for shared loans w/ per-borrower allocation; variable-rate resets (extend tenure / raise EMI / combination).
- Per-person + consolidated amortization w/ reconciliation; accountant's-worksheet transparency (click any number → formula + inputs + steps).
- Payment tracking, prepayment simulation, negative-amortization guard; CSV/PDF export; PDF ingestion for loan docs; pure unit-tested engine (`src/engine/`).

**Key changes / decisions:**
- Pure-engine pattern (UI never does money math inline); INR ₹ lakh/crore locale; monthly reducing-balance default (daily/365 + flat also supported).
- Negative-amortization guard per RBI floating-rate rules; tenure-extension default reset; local browser storage, no backend; 29 engine unit tests (incl. 3-person reconciliation).

---

## KickStarterFiles
**What it is:** Unattended OS-installer scaffold for Rocky + Arch Linux — turns official install media into hands-off USB installers with a Packer/QEMU test loop.
**Stack:** Kickstart (Rocky) · archinstall (Arch) · mkksiso / mkarchiso · HashiCorp Packer · QEMU/KVM · Docker.

**Features:**
- Zero-touch USB install (plug in → boot → install → reboot); Rocky 9 + Arch support via distro-specific branches; official distro tooling only.
- Packer + QEMU/KVM test loop before real hardware; Docker reproducible build env; double-confirm USB write requiring explicit device.

**Key changes / decisions:**
- Official tools only (no reinvention); multi-branch model (main configs-agnostic, specifics on `distro/*`); aggressive safety (`write-usb.sh` requires `DEV=/dev/sdX` + double confirm).

---

## rocky-dev-setup
**What it is:** Rocky Linux developer-environment setup scripts that provision a bare system into a full workstation (languages, DBs, containers, tools).
**Stack:** Bash · mise · chezmoi · Docker/Podman · systemd · dnf.

**Features:**
- `rocky-dev-setup.sh` (reference) + `rocky-dev-setup-custom.sh` (production, mise + chezmoi); package-manager auto-detect (pacman/dnf/apt).
- Installs Dev Tools, Python, Node, Java 17 + Maven, Go, Docker, PostgreSQL/MySQL/SQLite clients; OS-aware TeX Live w/ CTAN fallback; firewall opens dev ports (3000/5000/8000/8080).
- Docker group for rootless; crash-recovery (`repair-toolchain.sh`); extensible for AI/ML, Flutter/Dart, DevOps; Rocky 9/10; idempotent; `setup.sh` refuses root.

**Key changes / decisions:**
- Unified per-language installs under mise + conda (Miniforge); chezmoi for reproducible dotfiles from GitHub.
- Privilege-split scripts (`install-system-packages.sh` sudo / `setup.sh` no-sudo / `fix-permissions.sh`); dropped NodeSource (mise handles Node); CTAN fallback for fontawesome5/FiraSans.
- DevVault (`~/coding/DevVault/`, Obsidian); Flatpak apps over system packages; Podman over Docker default w/ Podman Desktop GUI.

---

## loan-default-prediction
**What it is:** Flask web app predicting loan-default probability from Lending Club P2P data, with separate models for individual vs joint applicants.
**Stack:** Flask · Python · scikit-learn (ensemble) · pandas · HTML/CSS/JS.

**Features:**
- Default-risk prediction on Lending Club records; separate models per applicant type; web form input → risk prediction; EDA dashboard; REST predict endpoint; model loaded once at startup.

**Key changes / decisions:**
- Ensemble model for accuracy across applicant types; features constrained to loan-origination-time info (grades/subgrades/rate derived from FICO) to prevent data leakage; pickle persistence.

---

## Pediatrics
**What it is:** Flutter medical/healthcare mobile app — doctor appointment booking, patient profiles, auth, payments. (Multi-platform: Android/iOS/Web/desktop.)
**Stack:** Dart/Flutter · Firebase (Auth/Firestore/Storage/Database/Analytics) · Supabase · BLoC/Cubit · GraphQL · Hive.

**Features:**
- Email/password + Google Sign-In (Firebase Auth); doctor search, favorites, appointment scheduling.
- Appointment management (Upcoming/Completed/Cancelled); patient profile + edit; payment processing + review summaries.
- Notifications & messaging; medical records storage; help center/FAQ; account deletion + password reset.
- Local SQLite + Firestore sync; multi-platform builds (Android/iOS/Web/Windows/Linux/macOS).

**Key changes / decisions:**
- Clean architecture (data/domain/presentation per feature); BLoC + Cubit state management.
- Firebase primary backend, Supabase secondary; modular feature structure (appointment/auth/chats/notifications/payment/schedule).
- Active development (40+ merged PRs, branch strategy).

---

## flashcards
**What it is:** Zero-dependency, offline-first spaced-repetition flashcard web app implementing FSRS-5, with CSV import/export and an Anki pipeline.
**Stack:** HTML5 · JavaScript (ES modules) · CSS · Python (genanki, pdftotext).

**Features:**
- FSRS-5 pure-JS scheduler (19-parameter weights); two study modes (Review = due-only scheduled, Continuous = hardest-first).
- 3 sample decks (Spanish/World Capitals/CS) or custom CSV import; full card CRUD; localStorage persistence + JSON export/import.
- Keyboard-driven (Space reveal, 1–4 rating); CSV parsing w/ quoted fields; fully private/local.
- `build_apkg.py` (front/back CSV → Anki .apkg); `pdf_chunk.py` (split large PDFs into LLM-ready chunks for batch card generation).

**Key changes / decisions:**
- Documented PDF→LLM→CSV→Anki workflow in SETUP-LOG.md; dark-mode CSS baked into generated decks (28px type).
- Both web fallback (HTTP server) + Anki pipeline (genanki + venv on Arch).

---

## loan
**What it is:** Flask web app for loan-approval prediction using an ML ensemble (general applicant approve/deny — distinct from `loan-default-prediction`'s Lending Club P2P risk scoring).
**Stack:** Python · Flask · scikit-learn · XGBoost · pandas/NumPy · Gunicorn · Bootstrap/HTML/CSS.

**Features:**
- Landing page; EDA visualization page (training-data insights); loan prediction form (gender, marital status, income, credit history…).
- XGBoost ensemble approve/deny engine; preprocessing pipeline (categorical→numeric); pickled model serving; training/test data bundled; responsive Bootstrap UI.

**Key changes / decisions:**
- Heroku deployment (Procfile, Python 3.9.1, port config removed for cloud); Windows→Unix line-ending migration.
- Multiple pickle model versions iterated (model_eclf → new → new_); pinned deps (scikit-learn 0.22.1, XGBoost 1.1.1).

---

## Excluded (not my apps / not applications)
- **Cloned learning / course material:** smol-course, mlops-zoomcamp, system-design-interview-prep, The-AI-Engineering-Bootcamp-Learning-Materials, building-applications-using-amazon-bedrock-3806107, Certifications_202k, Data_Science_Bootcamp_Projects, Data_Science_Learning_Material, Python_DS, Fin_Study.
- **Third-party / upstream:** career-ops-plugin (andrew-shwetzer), rofi-wayland-build (lbonn/rofi upstream), kg-rag (tomasonjo fork).
- **Docs/notes/templates/empty:** Medical-Research (design docs, no app), Personal-Portfolio (templates/test bundles), Github_Repo_Gen_template (boilerplate), data-engineer-project (empty repo), data_insigits (single EDA notebook), My-Notes, prompts, claude-prompt-and-code, SathishKumar (profile), jobsearch.
- **Verified-skip (re-examined source 2026-06-18):** Project-Med (template/structure generator, no app code), Project_Lee (rough HTML landing mockup by a third party "Lee Mesford"), secret_valut (plaintext credential store, not an app).

*Re-examined 2026-06-18: Pediatrics, flashcards, and loan were promoted to full entries above after reading source.*
