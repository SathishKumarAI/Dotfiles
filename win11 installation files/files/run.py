#!/usr/bin/env python3
"""
╔══════════════════════════════════════════════════════════════════╗
║       Dev & AI Engineer App Manager  v4                         ║
║   Visual TUI · Profiles · Custom Apps · Live Log · Disk Audit   ║
╚══════════════════════════════════════════════════════════════════╝

Quick start (just double-click or run in terminal):
    python run.py

First time?  Install dependencies first:
    pip install requests rich textual

How to use the visual interface (TUI):
  • Arrow keys / click  → move around the app list
  • Space               → select / deselect an app
  • A                   → select ALL apps in current view
  • I                   → install selected apps
  • C                   → check which apps are already installed
  • U                   → check for updates online
  • O                   → open the download page for the focused app
  • P                   → switch install profile
  • Q                   → quit

Command-line (advanced) options:
    python run.py --cli       → plain terminal, no visual UI
    python run.py --check     → check installed versions
    python run.py --install   → install essential + recommended apps
    python run.py --update    → fetch latest versions from the internet
    python run.py --list      → list all apps with tiers
    python run.py --audit     → show disk usage estimate
    python run.py --ai        → AI/ML tools only
    python run.py --app NAME  → target a specific app by name
    python run.py --tier essential|recommended|optional
"""

import sys, subprocess, shutil, argparse, re

# ── Dependency check ──────────────────────────────────────────
def ensure_deps():
    missing = []
    for pkg in ["requests", "rich", "textual"]:
        try: __import__(pkg)
        except ImportError: missing.append(pkg)
    if missing:
        print(f"Installing: {', '.join(missing)}")
        subprocess.run([sys.executable, "-m", "pip", "install", *missing], check=True)

ensure_deps()

from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.text import Text
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.prompt import Confirm
from rich import box

from data import APPS, ESSENTIAL, RECOMMENDED, OPTIONAL, SKIP, TIER_COLOR, TIER_SYMBOL, TIER_ORDER
from core import get_installed_version, get_latest_version, install_app, open_website, filter_apps, version_cmp
from config import ConfigManager

console = Console()
cfg     = ConfigManager()


# ── CLI helpers ───────────────────────────────────────────────

def get_all_apps():
    return APPS + cfg.load_custom_apps()

def print_banner():
    apps = get_all_apps()
    disk = shutil.disk_usage("/")
    free = disk.free / (1024**3)
    console.print(Panel(
        f"[bold cyan]⬡  Dev & AI Engineer App Manager  v4[/]\n\n"
        f"  [green]{TIER_SYMBOL[ESSENTIAL]} Essential[/]    {sum(1 for a in apps if a['tier']==ESSENTIAL):>3} apps   "
        f"[dim](must-have tools)[/]\n"
        f"  [cyan]{TIER_SYMBOL[RECOMMENDED]} Recommended[/] {sum(1 for a in apps if a['tier']==RECOMMENDED):>3} apps   "
        f"[dim](strongly suggested)[/]\n"
        f"  [yellow]{TIER_SYMBOL[OPTIONAL]} Optional[/]     {sum(1 for a in apps if a['tier']==OPTIONAL):>3} apps   "
        f"[dim](install if you need them)[/]\n"
        f"  [red]{TIER_SYMBOL[SKIP]} Skip[/]         {sum(1 for a in apps if a['tier']==SKIP):>3} apps   "
        f"[dim](not recommended)[/]\n\n"
        f"  Total: [bold]{len(apps)}[/] apps  │  "
        f"Profile: [bold]{cfg.active_profile['name']}[/]  │  "
        f"Free disk: [bold]{free:.1f} GB[/]\n\n"
        f"  [dim]Tip: run without flags for the full visual UI → python run.py[/]",
        border_style="cyan", padding=(0, 2)
    ))

def cli_list(apps):
    cats = {}
    for a in apps:
        cats.setdefault(a["category"], []).append(a)
    for cat, items in sorted(cats.items()):
        console.print(f"\n[bold white]{cat}[/]")
        for tier in [ESSENTIAL, RECOMMENDED, OPTIONAL, SKIP]:
            for a in sorted([x for x in items if x["tier"] == tier], key=lambda x: x["name"]):
                tc   = TIER_COLOR[a["tier"]]
                note = f"[dim]— {a['note']}[/]" if a.get("note") else ""
                console.print(f"  [{tc}]{TIER_SYMBOL[a['tier']]}[/] {a['name']} [dim]{a.get('approx_mb','?')}MB[/] {note}")

def cli_check(apps):
    results = []
    with Progress(SpinnerColumn(), TextColumn("{task.description}"), console=console, transient=True) as p:
        task = p.add_task("Checking...", total=len(apps))
        for a in apps:
            p.update(task, description=f"[cyan]{a['name']}[/]")
            iv = get_installed_version(a)
            results.append({"app": a, "installed": iv, "latest": "—", "status": "missing" if iv == "Not installed" else "ok"})
            p.advance(task)
    _show_table(results)

def cli_update(apps):
    results = []
    updates = 0
    with Progress(SpinnerColumn(), TextColumn("{task.description}"), console=console, transient=True) as p:
        task = p.add_task("Fetching...", total=len(apps))
        for a in apps:
            p.update(task, description=f"[cyan]{a['name']}[/]")
            iv = get_installed_version(a)
            lv = get_latest_version(a)
            st = version_cmp(iv, lv)
            if st == "outdated": updates += 1
            results.append({"app": a, "installed": iv, "latest": lv, "status": st})
            p.advance(task)
    _show_table(results)
    outdated = [r for r in results if r["status"] == "outdated"]
    if outdated:
        console.print(f"\n[yellow]⬆  {len(outdated)} update(s) available[/]")
        for r in outdated:
            console.print(f"  • [bold]{r['app']['name']}[/]  {r['installed']} → {r['latest']}")
        if Confirm.ask("\n[cyan]Open download pages?[/]"):
            for r in outdated:
                open_website(r["app"])
    else:
        console.print("\n[green]✓ All up to date![/]")

def _show_table(results):
    cats = {}
    for r in results:
        cats.setdefault(r["app"]["category"], []).append(r)
    for cat, items in sorted(cats.items()):
        t = Table(title=f"[white]{cat}[/]", box=box.SIMPLE_HEAVY, min_width=80)
        t.add_column("Tier",    min_width=4)
        t.add_column("App",     min_width=28, style="bold white")
        t.add_column("Installed", min_width=12)
        t.add_column("Latest",  min_width=10)
        t.add_column("Status",  min_width=14)
        for r in sorted(items, key=lambda x: (TIER_ORDER.get(x["app"]["tier"], 9), x["app"]["name"])):
            tc = TIER_COLOR.get(r["app"]["tier"], "white")
            ICONS = {"missing": ("✗", "red"), "outdated": ("↑", "yellow"), "ok": ("✓", "green"), "unknown": ("?", "dim")}
            icon, style = ICONS.get(r["status"], ("?", "dim"))
            t.add_row(
                Text(TIER_SYMBOL.get(r["app"]["tier"],"?"), style=tc),
                r["app"]["name"],
                Text(r["installed"], style=style),
                Text(r["latest"],    style="dim"),
                Text(f"{icon} {r['status']}", style=style),
            )
        console.print(t)

def cli_install(apps, label=""):
    console.print(f"\n[bold]Apps to install: {len(apps)}{(' (' + label + ')') if label else ''}[/]")
    for a in apps:
        tc = TIER_COLOR[a["tier"]]
        console.print(f"  [{tc}]{TIER_SYMBOL[a['tier']]}[/] {a['name']}")
    if cfg.get("confirm_before_install", True):
        if not Confirm.ask("\n[cyan]Proceed?[/]"):
            console.print("[yellow]Cancelled.[/]")
            return
    ok, skip_, fail = [], [], []
    for app in apps:
        console.rule(f"[bold cyan]{app['name']}[/]")
        iv = get_installed_version(app)
        if iv != "Not installed":
            console.print(f"  [green]Already installed:[/] {iv}")
            skip_.append(app["name"])
            continue
        if install_app(app):
            console.print(f"  [green]✓ Installed[/]")
            ok.append(app["name"])
        else:
            console.print(f"  [red]✗ Failed[/]")
            if cfg.get("open_web_on_fail", True):
                open_website(app)
            fail.append(app["name"])
    console.print()
    console.print(Panel(
        f"[green]✓ Installed: {len(ok)}[/]\n[dim]⊘ Skipped: {len(skip_)}[/]\n[red]✗ Failed: {len(fail)}[/]"
        + (f"\n\n[dim]{', '.join(fail)}[/]" if fail else ""),
        title="Summary", border_style="cyan"
    ))

def cli_audit(apps):
    console.print("\n[bold cyan]Disk Audit by Tier[/]\n")
    for tier in [ESSENTIAL, RECOMMENDED, OPTIONAL, SKIP]:
        grp  = [a for a in apps if a["tier"] == tier]
        mb   = sum(a.get("approx_mb", 0) for a in grp)
        tc   = TIER_COLOR[tier]
        console.print(f"[bold {tc}]{TIER_SYMBOL[tier]} {tier.upper():12}[/]  {len(grp):>3} apps   ~{mb/1000:.2f} GB")
        for a in sorted(grp, key=lambda x: x["name"]):
            console.print(f"  [dim]{a['name']:35} {a.get('approx_mb','?'):>6} MB  {a.get('note','')}[/]")
    try:
        disk = shutil.disk_usage("/")
        console.print(Panel(
            f"Total: {disk.total/(1024**3):.1f} GB  │  "
            f"Used: {disk.used/(1024**3):.1f} GB  │  "
            f"[green]Free: {disk.free/(1024**3):.1f} GB[/]",
            title="System Disk", border_style="cyan"
        ))
    except Exception:
        pass


# ── Entry point ───────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Dev & AI App Manager v4")
    parser.add_argument("--cli",      action="store_true",  help="Force CLI mode (no TUI)")
    parser.add_argument("--list",     action="store_true")
    parser.add_argument("--check",    action="store_true")
    parser.add_argument("--update",   action="store_true")
    parser.add_argument("--install",  action="store_true")
    parser.add_argument("--audit",    action="store_true")
    parser.add_argument("--all",      action="store_true",  help="All tiers with --install")
    parser.add_argument("--tier",     choices=["essential","recommended","optional","skip"])
    parser.add_argument("--app",      type=str)
    parser.add_argument("--category", type=str)
    parser.add_argument("--tag",      type=str)
    parser.add_argument("--ai",       action="store_true")
    args = parser.parse_args()

    all_apps = get_all_apps()
    apps = filter_apps(
        all_apps,
        name=args.app,
        category=args.category,
        tier=args.tier,
        tag="ai" if args.ai else args.tag,
    )

    # TUI mode (default when no CLI flags given)
    cli_flags = any([args.list, args.check, args.update, args.install, args.audit, args.cli])
    if not cli_flags:
        try:
            from tui import DevManagerApp
            DevManagerApp().run()
            return
        except ImportError:
            console.print(
                "[yellow]⚠  The visual interface requires the 'textual' package.\n"
                "   Run this to install it, then try again:\n\n"
                "     [bold]pip install textual[/]\n[/]"
            )

    # CLI mode
    print_banner()
    if   args.list:   cli_list(apps)
    elif args.check:  cli_check(apps)
    elif args.update: cli_update(apps)
    elif args.audit:  cli_audit(apps)
    elif args.install:
        profile = cfg.active_profile
        if args.all:
            cli_install(apps, "all")
        elif args.tier:
            cli_install(filter_apps(apps, tier=args.tier), args.tier)
        else:
            tiers   = profile.get("tiers", [ESSENTIAL, RECOMMENDED])
            targets = [a for a in apps if a["tier"] in tiers and not cfg.is_disabled(a["name"])]
            cli_install(targets, profile["name"])
    else:
        # Default CLI: show list
        cli_list(apps)

if __name__ == "__main__":
    main()
