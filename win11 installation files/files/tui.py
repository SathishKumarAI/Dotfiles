# tui.py — Textual TUI for Dev Manager (v5)
# Features: resizable sidebar · install missing · install by category ·
#           single-click select · two-row action bar · live activity log

import shutil
import re as _re
from datetime import datetime
from textual.app import App, ComposeResult
from textual.widgets import (
    Header, Footer, DataTable, Input, Button, Label,
    Static, TabbedContent, TabPane, Switch,
    ScrollableContainer,
)
from textual.containers import Container, Horizontal, Vertical
from textual.binding import Binding
from textual.reactive import reactive
from textual import work
from textual.screen import ModalScreen
from rich.text import Text

# RichLog support (textual >= 0.32); plain-text fallback for older installs
try:
    from textual.widgets import RichLog
except ImportError:
    from textual.widgets import Log

    class RichLog(Log):                              # type: ignore[no-redef]
        def write(self, msg, **_):                   # type: ignore[override]
            self.write_line(_re.sub(r"\[/?[^\[\]]*\]", "", str(msg)))

from data import (
    APPS, ESSENTIAL, RECOMMENDED, OPTIONAL, SKIP,
    TIER_COLOR, TIER_SYMBOL, TIER_ORDER,
)
from core import (
    get_installed_version, get_latest_version,
    install_app, open_website, version_cmp,
)
from config import ConfigManager

cfg = ConfigManager()

STATUS_STYLE = {
    "missing":  "red",
    "outdated": "yellow",
    "ok":       "green",
    "unknown":  "dim",
}
STATUS_LABEL = {
    "missing":  "✗ Not installed",
    "outdated": "↑ Update available",
    "ok":       "✓ Up to date",
    "unknown":  "? Unknown",
}

# Sidebar width presets (chars).  0 = hidden.
SIDEBAR_WIDTHS = [0, 28, 42, 56, 72]
SIDEBAR_DEFAULT_IDX = 2   # start at 42


# ══════════════════════════════════════════════════════════════
#  ADD CUSTOM APP MODAL
# ══════════════════════════════════════════════════════════════
class AddAppModal(ModalScreen):
    CSS = """
    AddAppModal > Container {
        width: 72; height: auto; padding: 1 2;
        background: $surface; border: tall $primary;
    }
    AddAppModal Label  { margin-bottom: 1; color: $text-muted; }
    AddAppModal Input  { margin-bottom: 1; }
    AddAppModal .row   { height: auto; }
    AddAppModal Button { margin: 0 1; }
    """

    def compose(self) -> ComposeResult:
        with Container():
            yield Label("➕  Add a Custom App")
            yield Input(placeholder="App name  (e.g. My Tool)",                  id="c-name")
            yield Input(placeholder="Category  (e.g. Dev Tools)",                id="c-cat")
            yield Input(placeholder="winget ID  (e.g. Publisher.AppID)",         id="c-winget")
            yield Input(placeholder="Version check  (e.g. mytool --version)",    id="c-cmd")
            yield Input(placeholder="Download page URL",                         id="c-url")
            yield Input(placeholder="Note — why do you need this?",              id="c-note")
            with Horizontal(classes="row"):
                yield Button("💾  Save",   variant="primary", id="save-app")
                yield Button("✕  Cancel",  variant="default", id="cancel-app")

    def on_button_pressed(self, event):
        if event.button.id == "cancel-app":
            self.dismiss(None)
            return
        name   = self.query_one("#c-name",   Input).value.strip()
        cat    = self.query_one("#c-cat",    Input).value.strip() or "Custom"
        winget = self.query_one("#c-winget", Input).value.strip() or None
        cmd    = self.query_one("#c-cmd",    Input).value.strip()
        url    = self.query_one("#c-url",    Input).value.strip() or None
        note   = self.query_one("#c-note",   Input).value.strip()
        if not name:
            return
        app = {
            "name": name, "category": cat, "tier": "optional",
            "winget_id":   winget,
            "check_cmd":   cmd.split() if cmd else None,
            "version_url": None, "web_url": url,
            "approx_mb":   0, "tags": ["custom"], "note": note,
        }
        cfg.add_custom_app(app)
        self.dismiss(app)


# ══════════════════════════════════════════════════════════════
#  PROFILE SWITCHER MODAL
# ══════════════════════════════════════════════════════════════
class ProfileModal(ModalScreen):
    CSS = """
    ProfileModal > Container {
        width: 64; height: auto; padding: 1 2;
        background: $surface; border: tall $primary;
    }
    ProfileModal .profile-row { height: 3; margin-bottom: 1; }
    ProfileModal Button { width: 100%; }
    """

    def compose(self) -> ComposeResult:
        profiles = cfg.list_profiles()
        active   = cfg.active_profile_name
        with Container():
            yield Label("👤  Switch Install Profile")
            for key, p in profiles.items():
                marker  = "●" if key == active else "○"
                variant = "primary" if key == active else "default"
                with Horizontal(classes="profile-row"):
                    yield Button(
                        f"{marker}  {p['name']}  —  {p['description']}",
                        id=f"profile-{key}", variant=variant,
                    )
            yield Button("✕  Close", id="close-profile", variant="default")

    def on_button_pressed(self, event):
        if event.button.id == "close-profile":
            self.dismiss(None)
            return
        if event.button.id.startswith("profile-"):
            key = event.button.id.replace("profile-", "")
            cfg.set_profile(key)
            self.dismiss(key)


# ══════════════════════════════════════════════════════════════
#  SETTINGS MODAL
# ══════════════════════════════════════════════════════════════
class SettingsModal(ModalScreen):
    CSS = """
    SettingsModal > Container {
        width: 66; height: auto; padding: 1 2;
        background: $surface; border: tall $primary;
    }
    SettingsModal .pref-row { height: 3; }
    SettingsModal Label  { width: 1fr; }
    SettingsModal Switch { width: 8; }
    SettingsModal Button { margin-top: 1; }
    """

    def compose(self) -> ComposeResult:
        with Container():
            yield Label("⚙  Preferences")
            prefs = [
                ("check_updates_on_start", "Check for updates automatically on startup"),
                ("show_skip_tier",         "Show SKIP-tier apps in the table"),
                ("confirm_before_install", "Ask to confirm before each install"),
                ("open_web_on_fail",       "Open download page if an install fails"),
            ]
            for key, label in prefs:
                with Horizontal(classes="pref-row"):
                    yield Label(label)
                    yield Switch(value=cfg.get(key, False), id=f"pref-{key}")
            yield Label(f"[dim]Config file:  {cfg.get_config_path()}[/]")
            yield Label(f"[dim]Custom apps:  {cfg.get_custom_path()}[/]")
            yield Button("✕  Close", id="close-settings", variant="primary")

    def on_switch_changed(self, event):
        cfg.set(event.switch.id.replace("pref-", ""), event.value)

    def on_button_pressed(self, event):
        if event.button.id == "close-settings":
            self.dismiss(None)


# ══════════════════════════════════════════════════════════════
#  CATEGORY INSTALL MODAL
# ══════════════════════════════════════════════════════════════
class CategoryModal(ModalScreen):
    CSS = """
    CategoryModal > Container {
        width: 70; height: auto; max-height: 85vh; padding: 1 2;
        background: $surface; border: tall $primary;
    }
    CategoryModal Label  { margin-bottom: 1; }
    CategoryModal ScrollableContainer { height: auto; max-height: 50; }
    CategoryModal .cat-row { height: 3; margin-bottom: 1; }
    CategoryModal Button   { width: 100%; }
    CategoryModal #cancel-cat { margin-top: 1; }
    """

    def __init__(self, all_apps: list, results: dict):
        super().__init__()
        self._all_apps = all_apps
        self._results  = results
        # build ordered category list with stats
        cats = {}
        for a in all_apps:
            c = a["category"]
            cats.setdefault(c, {"total": 0, "missing": 0})
            cats[c]["total"] += 1
            if results.get(a["name"], {}).get("status") == "missing":
                cats[c]["missing"] += 1
        self._cats = dict(sorted(cats.items()))

    def compose(self) -> ComposeResult:
        with Container():
            yield Label("🗂  Install by Category — click a category to install its apps")
            with ScrollableContainer():
                for cat, info in self._cats.items():
                    n    = info["total"]
                    miss = info["missing"]
                    hint = f"[dim]({n} apps"
                    hint += f", [red]{miss} missing[/]" if miss else f", all installed"
                    hint += ")[/]"
                    safe = _safe_id(cat)
                    with Horizontal(classes="cat-row"):
                        yield Button(
                            f"  {cat}  {hint}",
                            id=f"cat-{safe}",
                            variant="primary" if miss else "default",
                        )
            yield Button("✕  Cancel", id="cancel-cat", variant="default")

    def on_button_pressed(self, event):
        if event.button.id == "cancel-cat":
            self.dismiss(None)
            return
        if event.button.id.startswith("cat-"):
            safe = event.button.id[4:]
            for cat in self._cats:
                if _safe_id(cat) == safe:
                    self.dismiss(cat)
                    return
            self.dismiss(None)


def _safe_id(name: str) -> str:
    """Convert category name to a CSS-safe ID fragment."""
    return _re.sub(r"[^a-zA-Z0-9]", "_", name).lower()


# ══════════════════════════════════════════════════════════════
#  MAIN APP
# ══════════════════════════════════════════════════════════════
class DevManagerApp(App):

    CSS = """
    Screen { background: $background; }

    /* ── Top bar: search + buttons ── */
    #top-bar {
        height: 3;
        background: $surface;
        border-bottom: solid $primary;
        padding: 0 1;
    }
    #search        { width: 1fr; height: 3; margin: 0 1; }
    #profile-btn   { width: 24; height: 3; }
    #settings-btn  { width: 16; height: 3; }
    #add-btn       { width: 18; height: 3; }
    #toggle-log-btn{ width: 14; height: 3; }

    /* ── Body: table area + sidebar ── */
    #body      { height: 1fr; }
    #main-area { width: 1fr; height: 1fr; }
    TabbedContent { height: 1fr; }
    DataTable  { height: 1fr; }

    /* ── Selection bar ── */
    #selection-bar {
        height: 3;
        background: $surface-darken-1;
        border-top: solid $primary-darken-2;
        padding: 0 1;
    }
    #sel-all-btn    { width: 18; height: 3; margin: 0 1 0 0; }
    #sel-none-btn   { width: 20; height: 3; margin: 0 1; }
    #sel-missing-btn{ width: 20; height: 3; margin: 0 1; }
    #sel-count      { width: 1fr; height: 3; padding: 0 1; }

    /* ── Sidebar ── */
    #sidebar {
        height: 1fr;
        background: $surface-darken-1;
        border-left: solid $primary-darken-2;
    }
    #sidebar-titlebar {
        height: 1;
        background: $primary-darken-2;
        padding: 0 1;
    }
    #sidebar-title    { width: 1fr; }
    #sidebar-shrink   { width: 3;  height: 1; min-width: 3; border: none; background: $primary-darken-2; }
    #sidebar-expand   { width: 3;  height: 1; min-width: 3; border: none; background: $primary-darken-2; }
    #sidebar-hide     { width: 3;  height: 1; min-width: 3; border: none; background: $primary-darken-2; }
    #activity-log     { height: 1fr; padding: 0 1; }
    #sidebar-stats    {
        height: 4;
        padding: 0 1;
        border-top: solid $primary-darken-3;
        color: $text-muted;
    }
    #clear-log-btn    {
        height: 1;
        width: 100%;
        background: $surface;
        border-top: solid $primary-darken-3;
        color: $text-muted;
    }

    /* ── Install action bar (row 1) ── */
    #install-bar {
        height: 3;
        background: $surface;
        border-top: solid $primary;
        padding: 0 1;
    }
    #install-bar Button { width: auto; margin: 0 1; height: 3; }

    /* ── Info / check action bar (row 2) ── */
    #action-bar {
        height: 3;
        background: $surface-darken-1;
        border-top: solid $primary-darken-2;
        padding: 0 1;
    }
    #action-bar Button { width: auto; margin: 0 1; height: 3; }

    /* ── Bottom status strip ── */
    #status-bar {
        height: 1;
        background: $primary-darken-3;
        padding: 0 1;
        color: $text-muted;
    }

    /* Button colours */
    .btn-install   { background: $success-darken-1; }
    .btn-missing   { background: $error-darken-1; }
    .btn-category  { background: $accent-darken-1; }
    .btn-profile   { background: $success-darken-2; }
    .btn-check     { background: $primary-darken-1; }
    .btn-update    { background: $warning-darken-1; }
    .btn-web       { background: $secondary-darken-1; }
    .btn-audit     { background: $surface-lighten-1; }
    """

    BINDINGS = [
        Binding("i",       "install_selected",  "Install Sel.",  show=True),
        Binding("m",       "install_missing",   "Install Missing", show=True),
        Binding("c",       "check_versions",    "Check",          show=True),
        Binding("u",       "update_check",      "Updates",        show=True),
        Binding("o",       "open_web",          "Open Website",   show=True),
        Binding("space",   "toggle_select",     "Select",         show=True),
        Binding("a",       "select_all",        "Select All",     show=True),
        Binding("e",       "select_none",       "Clear",          show=False),
        Binding("p",       "switch_profile",    "Profile",        show=True),
        Binding("ctrl+b",  "toggle_sidebar",    "Toggle Log",     show=True),
        Binding("ctrl+left",  "shrink_sidebar", "Shrink Log",     show=False),
        Binding("ctrl+right", "expand_sidebar", "Expand Log",     show=False),
        Binding("plus",    "add_app",           "Add App",        show=False),
        Binding("ctrl+s",  "open_settings",     "Settings",       show=False),
        Binding("q",       "quit",              "Quit",           show=True),
    ]

    selected: reactive = reactive(set)

    def __init__(self):
        super().__init__()
        self._all_apps      = APPS + cfg.load_custom_apps()
        self._results: dict = {}
        self._current_apps: list = []
        self._sidebar_idx   = SIDEBAR_DEFAULT_IDX   # index into SIDEBAR_WIDTHS

    # ────────────────────────────────────────────────────────
    #  LAYOUT
    # ────────────────────────────────────────────────────────

    def compose(self) -> ComposeResult:
        yield Header(show_clock=True)

        # ── Top bar ──
        with Horizontal(id="top-bar"):
            yield Input(placeholder="🔍  Search apps…", id="search")
            yield Button(f"👤 {cfg.active_profile['name']}", id="profile-btn",    variant="default")
            yield Button("⚙  Settings",                      id="settings-btn",  variant="default")
            yield Button("➕  Add App",                       id="add-btn",       variant="success")
            yield Button("📋  Log",                           id="toggle-log-btn",variant="default")

        # ── Body: table area | sidebar ──
        with Horizontal(id="body"):

            # Left: tabs, table, selection bar
            with Vertical(id="main-area"):
                with TabbedContent(id="tabs"):
                    for tab_id, label in self._tab_defs():
                        with TabPane(label, id=f"tab-{tab_id}"):
                            yield DataTable(id=f"table-{tab_id}", cursor_type="row")

                with Horizontal(id="selection-bar"):
                    yield Button("☑  Select All",        id="sel-all-btn",    variant="default")
                    yield Button("☐  Clear Selection",   id="sel-none-btn",   variant="default")
                    yield Button("🔴  Select Missing",   id="sel-missing-btn",variant="default")
                    yield Static(
                        "  [dim]Click a row or press Space to select  ·  A = select all[/]",
                        id="sel-count",
                    )

            # Right: activity sidebar (resizable)
            with Vertical(id="sidebar"):
                with Horizontal(id="sidebar-titlebar"):
                    yield Static("📋  Activity Log", id="sidebar-title")
                    yield Button("◀", id="sidebar-shrink", variant="default")
                    yield Button("▶", id="sidebar-expand", variant="default")
                    yield Button("×", id="sidebar-hide",   variant="default")
                yield RichLog(
                    id="activity-log",
                    highlight=True,
                    markup=True,
                    auto_scroll=True,
                )
                yield Static("", id="sidebar-stats")
                yield Button("⊘  Clear Log", id="clear-log-btn", variant="default")

        # ── Install actions (row 1) ──
        with Horizontal(id="install-bar"):
            yield Button("▶  Install Selected",    id="btn-install",   classes="btn-install")
            yield Button("🔴  Install Missing",    id="btn-missing",   classes="btn-missing")
            yield Button("🗂  Install by Category",id="btn-category",  classes="btn-category")
            yield Button("◉  Install by Profile",  id="btn-tier",      classes="btn-profile")

        # ── Check / info actions (row 2) ──
        with Horizontal(id="action-bar"):
            yield Button("⟳  Check What's Installed", id="btn-check",  classes="btn-check")
            yield Button("⬆  Check for Updates",       id="btn-update", classes="btn-update")
            yield Button("🌐  Open Download Page",     id="btn-web",    classes="btn-web")
            yield Button("📊  Disk Usage Audit",       id="btn-audit",  classes="btn-audit")

        yield Static("", id="status-bar")
        yield Footer()

    @staticmethod
    def _tab_defs() -> list:
        return [
            ("all",         "All Apps"),
            ("essential",   "★ Essential"),
            ("recommended", "◆ Recommended"),
            ("optional",    "◇ Optional"),
            ("ai",          "🤖 AI Tools"),
            ("missing",     "✗ Missing"),
            ("custom",      "📦 Custom"),
        ]

    # ────────────────────────────────────────────────────────
    #  MOUNT
    # ────────────────────────────────────────────────────────

    def on_mount(self):
        self._apply_sidebar_width()
        self._setup_tables()
        self._refresh_active_table()
        self._update_status()
        self._log("[cyan bold]Welcome to Dev App Manager v5![/]")
        self._log("  [dim]Click any row to select it  ·  [bold]A[/] = select all[/]")
        self._log("  [dim]Use the install buttons below or press [bold]I[/][/]")
        self._log("  [dim]Ctrl+← / Ctrl+→  resize this log panel[/]")
        self._log("  [dim]Ctrl+B  toggle log panel on/off[/]")
        self._log("[dim]──────────────────────────────────────[/]")

    # ────────────────────────────────────────────────────────
    #  SIDEBAR RESIZE
    # ────────────────────────────────────────────────────────

    def _apply_sidebar_width(self):
        sidebar = self.query_one("#sidebar")
        w = SIDEBAR_WIDTHS[self._sidebar_idx]
        if w == 0:
            sidebar.display = False
        else:
            sidebar.display = True
            sidebar.styles.width = w

    def action_shrink_sidebar(self):
        if self._sidebar_idx > 0:
            self._sidebar_idx -= 1
        self._apply_sidebar_width()
        w = SIDEBAR_WIDTHS[self._sidebar_idx]
        if w:
            self._log(f"[dim]Log panel width → {w}[/]")

    def action_expand_sidebar(self):
        if self._sidebar_idx < len(SIDEBAR_WIDTHS) - 1:
            self._sidebar_idx += 1
        self._apply_sidebar_width()
        self._log(f"[dim]Log panel width → {SIDEBAR_WIDTHS[self._sidebar_idx]}[/]")

    def action_toggle_sidebar(self):
        if SIDEBAR_WIDTHS[self._sidebar_idx] == 0:
            # Restore to default
            self._sidebar_idx = SIDEBAR_DEFAULT_IDX
        else:
            # Hide
            self._sidebar_idx = 0
        self._apply_sidebar_width()

    # ────────────────────────────────────────────────────────
    #  TABLE SETUP & RENDERING
    # ────────────────────────────────────────────────────────

    def _setup_tables(self):
        cols = [
            ("",          3),
            ("Tier",      5),
            ("App Name",  28),
            ("Category",  20),
            ("Installed", 12),
            ("Latest",    10),
            ("Status",    18),
            ("MB",         6),
        ]
        for tab_id, _ in self._tab_defs():
            try:
                t = self.query_one(f"#table-{tab_id}", DataTable)
                for label, width in cols:
                    t.add_column(label, width=width)
            except Exception:
                pass

    def _get_tab_apps(self, tab_id: str) -> list:
        search    = self.query_one("#search", Input).value.strip().lower()
        show_skip = cfg.get("show_skip_tier", False)
        apps      = self._all_apps

        filters = {
            "all":         lambda a: True,
            "essential":   lambda a: a["tier"] == ESSENTIAL,
            "recommended": lambda a: a["tier"] == RECOMMENDED,
            "optional":    lambda a: a["tier"] == OPTIONAL,
            "ai":          lambda a: "ai" in a.get("tags", []),
            "missing":     lambda a: self._results.get(a["name"], {}).get("status") == "missing",
            "custom":      lambda a: "custom" in a.get("tags", []),
        }
        result = [a for a in apps if filters.get(tab_id, lambda _: True)(a)]
        if not show_skip:
            result = [a for a in result if a["tier"] != SKIP]
        if search:
            result = [
                a for a in result
                if search in a["name"].lower()
                or search in a["category"].lower()
                or search in a.get("note", "").lower()
            ]
        result.sort(key=lambda a: (TIER_ORDER.get(a["tier"], 9), a["name"]))
        return result

    def _active_tab_id(self) -> str:
        try:
            return self.query_one("#tabs", TabbedContent).active.replace("tab-", "")
        except Exception:
            return "all"

    def _refresh_active_table(self, tab_id: str = None):
        tid = tab_id or self._active_tab_id()
        try:
            table = self.query_one(f"#table-{tid}", DataTable)
        except Exception:
            return
        apps = self._get_tab_apps(tid)
        self._current_apps = apps
        table.clear()
        for app in apps:
            r     = self._results.get(app["name"], {})
            inst  = r.get("installed", "—")
            lat   = r.get("latest",    "—")
            st    = r.get("status",    "unknown")
            tc    = TIER_COLOR.get(app["tier"], "white")
            sym   = TIER_SYMBOL.get(app["tier"], "?")
            sel   = "☑" if app["name"] in self.selected else "☐"
            pin   = "📌 " if cfg.is_pinned(app["name"]) else ""
            s_col = STATUS_STYLE.get(st, "dim")
            table.add_row(
                Text(sel,                            style="cyan"),
                Text(sym,                            style=tc),
                Text(f"{pin}{app['name']}"),
                Text(app["category"],                style="dim"),
                Text(inst,                           style=s_col),
                Text(lat,                            style="dim"),
                Text(STATUS_LABEL.get(st, f"? {st}"),style=s_col),
                Text(str(app.get("approx_mb", "?")), style="dim"),
                key=app["name"],
            )
        self._update_sel_count()

    # ────────────────────────────────────────────────────────
    #  STATUS / STATS
    # ────────────────────────────────────────────────────────

    def _update_status(self):
        try:
            disk  = shutil.disk_usage("/")
            free  = disk.free / (1024 ** 3)
            ok    = sum(1 for r in self._results.values() if r.get("status") == "ok")
            miss  = sum(1 for r in self._results.values() if r.get("status") == "missing")
            upd   = sum(1 for r in self._results.values() if r.get("status") == "outdated")
            prof  = cfg.active_profile["name"]
            n_sel = len(self.selected)
            self.query_one("#status-bar", Static).update(
                f"  Profile: {prof}  │  {len(self._all_apps)} apps  │  "
                f"Installed: {ok}  │  Missing: {miss}  │  "
                f"Updates: {upd}  │  Selected: {n_sel}  │  Free: {free:.1f} GB"
            )
            self.query_one("#sidebar-stats", Static).update(
                f"  Installed: [green]{ok}[/]   Missing: [red]{miss}[/]\n"
                f"  Updates:   [yellow]{upd}[/]   Free disk: {free:.1f} GB"
            )
        except Exception:
            pass

    def _update_sel_count(self):
        n = len(self.selected)
        try:
            if n == 0:
                msg = "  [dim]Click a row or press [bold]Space[/] · [bold]A[/] = select all[/]"
            else:
                msg = (
                    f"  [cyan bold]{n} app{'s' if n != 1 else ''} selected[/]"
                    f"  [dim]· [bold]I[/] install  [bold]M[/] install missing  [bold]E[/] clear[/]"
                )
            self.query_one("#sel-count", Static).update(msg)
        except Exception:
            pass

    # ────────────────────────────────────────────────────────
    #  LIVE ACTIVITY LOG
    # ────────────────────────────────────────────────────────

    def _log(self, msg: str):
        """Write a timestamped rich message to the activity sidebar."""
        ts        = datetime.now().strftime("%H:%M:%S")
        formatted = f"[dim]{ts}[/]  {msg}"

        def _write():
            try:
                self.query_one("#activity-log", RichLog).write(formatted)
            except Exception:
                pass

        try:
            self.call_from_thread(_write)
        except Exception:
            _write()

    # ────────────────────────────────────────────────────────
    #  EVENTS
    # ────────────────────────────────────────────────────────

    def on_input_changed(self, event):
        if event.input.id == "search":
            self._refresh_active_table()

    def on_tabbed_content_tab_activated(self, event):
        tid = event.tab.id.replace("tab-", "")
        self._refresh_active_table(tid)

    def on_data_table_row_selected(self, event):
        """Single click or Enter on a row toggles selection."""
        name = str(event.row_key.value) if event.row_key else None
        if not name:
            return
        if name in self.selected:
            self.selected.discard(name)
            self._log(f"[dim]Deselected[/]  {name}")
        else:
            self.selected.add(name)
            self._log(f"[cyan]Selected[/]  {name}")
        self.selected = set(self.selected)
        self._refresh_active_table()
        self._update_status()

    def on_button_pressed(self, event):
        bid = event.button.id
        _map = {
            "btn-install":    self.action_install_selected,
            "btn-missing":    self.action_install_missing,
            "btn-category":   self.action_install_by_category,
            "btn-tier":       self.action_install_tier,
            "btn-check":      self.action_check_versions,
            "btn-update":     self.action_update_check,
            "btn-web":        self.action_open_web,
            "btn-audit":      self.action_disk_audit,
            "profile-btn":    self.action_switch_profile,
            "settings-btn":   self.action_open_settings,
            "add-btn":        self.action_add_app,
            "sel-all-btn":    self.action_select_all,
            "sel-none-btn":   self.action_select_none,
            "sel-missing-btn":self.action_select_missing,
            "toggle-log-btn": self.action_toggle_sidebar,
            "sidebar-shrink": self.action_shrink_sidebar,
            "sidebar-expand": self.action_expand_sidebar,
            "sidebar-hide":   lambda: setattr(self, "_sidebar_idx", 0) or self._apply_sidebar_width(),
            "clear-log-btn":  self._clear_log,
        }
        fn = _map.get(bid)
        if fn:
            fn()

    # ────────────────────────────────────────────────────────
    #  SELECTION ACTIONS
    # ────────────────────────────────────────────────────────

    def action_toggle_select(self):
        tid = self._active_tab_id()
        try:
            table = self.query_one(f"#table-{tid}", DataTable)
            row   = table.cursor_row
            apps  = self._get_tab_apps(tid)
            if 0 <= row < len(apps):
                name = apps[row]["name"]
                if name in self.selected:
                    self.selected.discard(name)
                    self._log(f"[dim]Deselected[/]  {name}")
                else:
                    self.selected.add(name)
                    self._log(f"[cyan]Selected[/]  {name}")
                self.selected = set(self.selected)
                self._refresh_active_table()
                self._update_status()
        except Exception:
            pass

    def action_select_all(self):
        before = len(self.selected)
        for a in self._current_apps:
            self.selected.add(a["name"])
        self.selected = set(self.selected)
        self._refresh_active_table()
        self._update_status()
        added = len(self.selected) - before
        self._log(f"[cyan]Selected all visible apps[/]  ({len(self.selected)} total, +{added} new)")

    def action_select_none(self):
        n = len(self.selected)
        self.selected = set()
        self._refresh_active_table()
        self._update_status()
        self._log(f"[dim]Cleared selection  ({n} apps)[/]")

    def action_select_missing(self):
        """Select all apps that have not been installed yet."""
        before = len(self.selected)
        added  = []
        for a in self._all_apps:
            if self._results.get(a["name"], {}).get("status") == "missing":
                self.selected.add(a["name"])
                added.append(a["name"])
        self.selected = set(self.selected)
        self._refresh_active_table()
        self._update_status()
        if added:
            self._log(f"[red]Selected {len(added)} missing app(s)[/]  — press [bold]I[/] to install")
        else:
            self._log("[yellow]No missing apps found[/]  — run [bold]⟳ Check[/] first")

    # ────────────────────────────────────────────────────────
    #  PROFILE / SETTINGS / ADD APP
    # ────────────────────────────────────────────────────────

    def action_switch_profile(self):
        def on_dismiss(result):
            if result:
                self.query_one("#profile-btn", Button).label = f"👤 {cfg.active_profile['name']}"
                self._refresh_active_table()
                self._update_status()
                self._log(f"[cyan]Profile →[/]  {cfg.active_profile['name']}")
        self.push_screen(ProfileModal(), on_dismiss)

    def action_open_settings(self):
        self.push_screen(SettingsModal())

    def action_add_app(self):
        def on_dismiss(result):
            if result:
                self._all_apps = APPS + cfg.load_custom_apps()
                self._refresh_active_table()
                self._update_status()
                self._log(f"[green]✓ Added custom app:[/]  {result['name']}")
        self.push_screen(AddAppModal(), on_dismiss)

    # ────────────────────────────────────────────────────────
    #  LOG CONTROL
    # ────────────────────────────────────────────────────────

    def _clear_log(self):
        try:
            self.query_one("#activity-log", RichLog).clear()
        except Exception:
            pass

    # ────────────────────────────────────────────────────────
    #  BACKGROUND WORKERS — check / update
    # ────────────────────────────────────────────────────────

    @work(thread=True)
    def action_check_versions(self):
        targets = (
            [a for a in self._all_apps if a["name"] in self.selected]
            if self.selected else self._all_apps
        )
        label = f"selected {len(targets)}" if self.selected else f"all {len(targets)}"
        self._log(f"[cyan]⟳  Checking {label} app(s)…[/]")
        ok_n = miss_n = 0
        for i, app in enumerate(targets):
            self._log(f"  [dim][{i+1}/{len(targets)}][/]  {app['name']}")
            iv = get_installed_version(app)
            st = "missing" if iv == "Not installed" else "ok"
            if st == "ok":
                ok_n += 1
            else:
                miss_n += 1
            self._results[app["name"]] = {
                "installed": iv,
                "latest":    self._results.get(app["name"], {}).get("latest", "—"),
                "status":    st,
            }
            if (i + 1) % 5 == 0:
                self.call_from_thread(self._refresh_active_table)
                self.call_from_thread(self._update_status)
        self.call_from_thread(self._refresh_active_table)
        self.call_from_thread(self._update_status)
        self._log(
            f"[green]✓  Check done[/]  "
            f"Installed: [green]{ok_n}[/]  "
            f"Missing: [red]{miss_n}[/]"
        )

    @work(thread=True)
    def action_update_check(self):
        targets = (
            [a for a in self._all_apps if a["name"] in self.selected]
            if self.selected else self._all_apps
        )
        self._log(f"[yellow]⬆  Fetching latest versions online  ({len(targets)} apps)…[/]")
        updates = 0
        for i, app in enumerate(targets):
            self._log(f"  [dim][{i+1}/{len(targets)}][/]  {app['name']}")
            iv  = get_installed_version(app)
            lv  = get_latest_version(app)
            st  = version_cmp(iv, lv)
            if st == "outdated":
                updates += 1
                self._log(f"  [yellow]↑ Update:[/]  {app['name']}  {iv} → {lv}")
            self._results[app["name"]] = {"installed": iv, "latest": lv, "status": st}
            if (i + 1) % 3 == 0:
                self.call_from_thread(self._refresh_active_table)
                self.call_from_thread(self._update_status)
        self.call_from_thread(self._refresh_active_table)
        self.call_from_thread(self._update_status)
        if updates:
            self._log(f"[yellow]⬆  {updates} update(s) available — see the table[/]")
        else:
            self._log("[green]✓  All apps are up to date![/]")

    # ────────────────────────────────────────────────────────
    #  BACKGROUND WORKERS — install
    # ────────────────────────────────────────────────────────

    @work(thread=True)
    def action_install_selected(self):
        targets = [a for a in self._all_apps if a["name"] in self.selected]
        if not targets:
            self._log("[yellow]⚠  No apps selected[/]  — click a row or press [bold]Space[/]")
            return
        self._run_install(targets, label="selected")

    @work(thread=True)
    def action_install_missing(self):
        targets = [
            a for a in self._all_apps
            if self._results.get(a["name"], {}).get("status") == "missing"
        ]
        if not targets:
            if not self._results:
                self._log("[yellow]⚠  No check has been run yet[/]  — press [bold]C[/] to check first")
            else:
                self._log("[green]✓  No missing apps — everything is installed![/]")
            return
        self._log(f"[red bold]🔴  Installing all missing apps ({len(targets)})…[/]")
        self._run_install(targets, label="missing")

    def action_install_by_category(self):
        """Open category picker, then install the chosen category."""
        def on_dismiss(cat: str | None):
            if cat:
                self._do_install_category(cat)
        self.push_screen(CategoryModal(self._all_apps, self._results), on_dismiss)

    @work(thread=True)
    def _do_install_category(self, cat: str):
        targets = [a for a in self._all_apps if a["category"] == cat]
        if not targets:
            self._log(f"[yellow]No apps found in category:[/]  {cat}")
            return
        self._log(f"[cyan]🗂  Installing category:[/]  {cat}  ({len(targets)} apps)")
        self._run_install(targets, label=f"category:{cat}")

    @work(thread=True)
    def action_install_tier(self):
        profile = cfg.active_profile
        tiers   = profile.get("tiers", [ESSENTIAL, RECOMMENDED])
        tags    = profile.get("tags", [])
        targets = [a for a in self._all_apps if a["tier"] in tiers]
        if tags:
            targets = [a for a in targets if any(t in a.get("tags", []) for t in tags)]
        targets = [a for a in targets if not cfg.is_disabled(a["name"])]
        self._log(f"[cyan]◉  Install profile:[/]  {profile['name']}  ({len(targets)} apps)")
        self._run_install(targets, label=f"profile:{profile['name']}")

    def _run_install(self, targets: list, label: str = ""):
        """Core install loop — runs inside a worker thread."""
        newly, skipped, failed = [], [], []
        total = len(targets)
        self._log(f"[cyan]▶  Starting install[/]  [{label}]  {total} app(s)")

        for i, app in enumerate(targets):
            pct = int(100 * i / total)
            self._log(
                f"  [{i+1}/{total}]  [bold]{app['name']}[/]"
                f"  [dim]({pct}%)[/]"
            )
            iv = get_installed_version(app)
            if iv != "Not installed":
                self._log(f"    [dim]↷  Already installed  ({iv})[/]")
                self._results[app["name"]] = {
                    "installed": iv,
                    "latest":    self._results.get(app["name"], {}).get("latest", "—"),
                    "status":    "ok",
                }
                skipped.append(app["name"])
                continue

            success = install_app(app)
            if success:
                iv2 = get_installed_version(app)
                self._log(f"    [green]✓  Installed[/]  ({iv2 or 'done'})")
                self._results[app["name"]] = {
                    "installed": iv2 or "Installed",
                    "latest":    "—",
                    "status":    "ok",
                }
                newly.append(app["name"])
            else:
                self._log(f"    [red]✗  Failed[/]  — opening download page…")
                self._results[app["name"]] = {
                    "installed": "Not installed",
                    "latest":    "—",
                    "status":    "missing",
                }
                if cfg.get("open_web_on_fail", True):
                    open_website(app)
                failed.append(app["name"])

        self.call_from_thread(self._refresh_active_table)
        self.call_from_thread(self._update_status)
        self._log(
            f"[green]✓  Install finished[/]  "
            f"New: [green]{len(newly)}[/]  "
            f"Skipped: {len(skipped)}  "
            f"Failed: [{'red' if failed else 'green'}]{len(failed)}[/]"
        )
        if failed:
            for name in failed:
                self._log(f"  [red]✗[/]  {name}")

    # ────────────────────────────────────────────────────────
    #  OTHER ACTIONS
    # ────────────────────────────────────────────────────────

    def action_open_web(self):
        tid = self._active_tab_id()
        try:
            table = self.query_one(f"#table-{tid}", DataTable)
            row   = table.cursor_row
            apps  = self._get_tab_apps(tid)
            if 0 <= row < len(apps):
                app = apps[row]
                open_website(app)
                self._log(f"[cyan]🌐  Opened download page:[/]  {app['name']}")
        except Exception:
            pass

    def action_disk_audit(self):
        self._log("[cyan]📊  Disk usage estimate by tier:[/]")
        for tier in [ESSENTIAL, RECOMMENDED, OPTIONAL, SKIP]:
            grp  = [a for a in self._all_apps if a["tier"] == tier]
            mb   = sum(a.get("approx_mb", 0) for a in grp)
            sym  = TIER_SYMBOL.get(tier, "?")
            tc   = TIER_COLOR.get(tier, "white")
            self._log(
                f"  [{tc}]{sym}  {tier.upper():12}[/]"
                f"  {len(grp)} apps   ~{mb/1000:.2f} GB"
            )
        try:
            disk  = shutil.disk_usage("/")
            free  = disk.free  / (1024 ** 3)
            used  = disk.used  / (1024 ** 3)
            total = disk.total / (1024 ** 3)
            self._log(
                f"  [bold]System C:[/]  "
                f"Used {used:.1f} GB  "
                f"[green]Free {free:.1f} GB[/]  "
                f"Total {total:.1f} GB"
            )
        except Exception:
            pass
