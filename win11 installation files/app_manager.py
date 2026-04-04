"""
╔══════════════════════════════════════════════════════════╗
║         Developer App Manager — Windows                  ║
║  Installs · Checks Versions · Finds Updates · Opens Web  ║
╚══════════════════════════════════════════════════════════╝

Requirements:
    pip install requests rich

Run:
    python app_manager.py
    python app_manager.py --install      # install all enabled apps
    python app_manager.py --check        # check versions only
    python app_manager.py --update       # check for updates online
    python app_manager.py --app "Docker" # target a single app
"""

import subprocess
import webbrowser
import argparse
import json
import sys
import os
import re
from datetime import datetime

try:
    import requests
    from rich.console import Console
    from rich.table import Table
    from rich.panel import Panel
    from rich.progress import Progress, SpinnerColumn, TextColumn
    from rich.prompt import Confirm
    from rich import box
    from rich.text import Text
except ImportError:
    print("Installing required packages...")
    subprocess.run([sys.executable, "-m", "pip", "install", "requests", "rich"], check=True)
    import requests
    from rich.console import Console
    from rich.table import Table
    from rich.panel import Panel
    from rich.progress import Progress, SpinnerColumn, TextColumn
    from rich.prompt import Confirm
    from rich import box
    from rich.text import Text

console = Console()

# ─────────────────────────────────────────────────────────────
#  APP DEFINITIONS
#  Each app has:
#    winget_id   → used to install/check via winget
#    check_cmd   → command to get installed version
#    version_url → API or page to fetch latest version
#    web_url     → homepage to open in browser
#    enabled     → include in auto-install
# ─────────────────────────────────────────────────────────────
APPS = [
    # ── Dev Tools ──
    {
        "name":        "VS Code",
        "category":    "Dev Tools",
        "winget_id":   "Microsoft.VisualStudioCode",
        "check_cmd":   ["code", "--version"],
        "version_url": "https://api.github.com/repos/microsoft/vscode/releases/latest",
        "web_url":     "https://code.visualstudio.com/",
        "enabled":     True,
    },
    {
        "name":        "Git",
        "category":    "Dev Tools",
        "winget_id":   "Git.Git",
        "check_cmd":   ["git", "--version"],
        "version_url": "https://api.github.com/repos/git-for-windows/git/releases/latest",
        "web_url":     "https://git-scm.com/",
        "enabled":     True,
    },
    {
        "name":        "GitHub CLI",
        "category":    "Dev Tools",
        "winget_id":   "GitHub.cli",
        "check_cmd":   ["gh", "--version"],
        "version_url": "https://api.github.com/repos/cli/cli/releases/latest",
        "web_url":     "https://cli.github.com/",
        "enabled":     True,
    },
    {
        "name":        "Postman",
        "category":    "Dev Tools",
        "winget_id":   "Postman.Postman",
        "check_cmd":   None,
        "version_url": None,
        "web_url":     "https://www.postman.com/downloads/",
        "enabled":     True,
    },
    {
        "name":        "DBeaver",
        "category":    "Dev Tools",
        "winget_id":   "dbeaver.dbeaver",
        "check_cmd":   None,
        "version_url": "https://api.github.com/repos/dbeaver/dbeaver/releases/latest",
        "web_url":     "https://dbeaver.io/download/",
        "enabled":     True,
    },

    # ── Containers / DevOps ──
    {
        "name":        "Docker Desktop",
        "category":    "DevOps",
        "winget_id":   "Docker.DockerDesktop",
        "check_cmd":   ["docker", "--version"],
        "version_url": "https://api.github.com/repos/docker/docker-ce/releases/latest",
        "web_url":     "https://docs.docker.com/desktop/release-notes/",
        "enabled":     True,
    },
    {
        "name":        "Kubernetes CLI",
        "category":    "DevOps",
        "winget_id":   "Kubernetes.kubectl",
        "check_cmd":   ["kubectl", "version", "--client", "--short"],
        "version_url": "https://api.github.com/repos/kubernetes/kubernetes/releases/latest",
        "web_url":     "https://kubernetes.io/releases/",
        "enabled":     True,
    },
    {
        "name":        "Helm",
        "category":    "DevOps",
        "winget_id":   "Helm.Helm",
        "check_cmd":   ["helm", "version", "--short"],
        "version_url": "https://api.github.com/repos/helm/helm/releases/latest",
        "web_url":     "https://helm.sh/",
        "enabled":     False,
    },
    {
        "name":        "Minikube",
        "category":    "DevOps",
        "winget_id":   "Kubernetes.minikube",
        "check_cmd":   ["minikube", "version"],
        "version_url": "https://api.github.com/repos/kubernetes/minikube/releases/latest",
        "web_url":     "https://minikube.sigs.k8s.io/docs/",
        "enabled":     False,
    },
    {
        "name":        "AWS CLI",
        "category":    "DevOps",
        "winget_id":   "Amazon.AWSCLI",
        "check_cmd":   ["aws", "--version"],
        "version_url": "https://api.github.com/repos/aws/aws-cli/tags",
        "web_url":     "https://aws.amazon.com/cli/",
        "enabled":     False,
    },
    {
        "name":        "Azure CLI",
        "category":    "DevOps",
        "winget_id":   "Microsoft.AzureCLI",
        "check_cmd":   ["az", "--version"],
        "version_url": "https://api.github.com/repos/Azure/azure-cli/releases/latest",
        "web_url":     "https://learn.microsoft.com/en-us/cli/azure/",
        "enabled":     False,
    },

    # ── Databases ──
    {
        "name":        "PostgreSQL",
        "category":    "Database",
        "winget_id":   "PostgreSQL.PostgreSQL.17",
        "check_cmd":   ["psql", "--version"],
        "version_url": None,
        "web_url":     "https://www.postgresql.org/download/windows/",
        "enabled":     False,
    },
    {
        "name":        "MongoDB",
        "category":    "Database",
        "winget_id":   "MongoDB.Server",
        "check_cmd":   ["mongod", "--version"],
        "version_url": None,
        "web_url":     "https://www.mongodb.com/try/download/community",
        "enabled":     False,
    },
    {
        "name":        "MongoDB Compass",
        "category":    "Database",
        "winget_id":   "MongoDB.Compass.Full",
        "check_cmd":   None,
        "version_url": "https://api.github.com/repos/mongodb-js/compass/releases/latest",
        "web_url":     "https://www.mongodb.com/products/tools/compass",
        "enabled":     True,
    },

    # ── Runtime / Languages ──
    {
        "name":        "Node.js",
        "category":    "Runtime",
        "winget_id":   "OpenJS.NodeJS.LTS",
        "check_cmd":   ["node", "--version"],
        "version_url": "https://nodejs.org/dist/index.json",
        "web_url":     "https://nodejs.org/en/download/",
        "enabled":     True,
    },
    {
        "name":        "Python",
        "category":    "Runtime",
        "winget_id":   "Python.Python.3.12",
        "check_cmd":   ["python", "--version"],
        "version_url": "https://api.github.com/repos/python/cpython/releases/latest",
        "web_url":     "https://www.python.org/downloads/",
        "enabled":     False,
    },

    # ── Terminal / CLI ──
    {
        "name":        "Windows Terminal",
        "category":    "Terminal",
        "winget_id":   "Microsoft.WindowsTerminal",
        "check_cmd":   None,
        "version_url": "https://api.github.com/repos/microsoft/terminal/releases/latest",
        "web_url":     "https://github.com/microsoft/terminal/releases",
        "enabled":     True,
    },
    {
        "name":        "Starship Prompt",
        "category":    "Terminal",
        "winget_id":   "Starship.Starship",
        "check_cmd":   ["starship", "--version"],
        "version_url": "https://api.github.com/repos/starship/starship/releases/latest",
        "web_url":     "https://starship.rs/",
        "enabled":     True,
    },
    {
        "name":        "fzf",
        "category":    "Terminal",
        "winget_id":   "junegunn.fzf",
        "check_cmd":   ["fzf", "--version"],
        "version_url": "https://api.github.com/repos/junegunn/fzf/releases/latest",
        "web_url":     "https://github.com/junegunn/fzf",
        "enabled":     True,
    },
    {
        "name":        "lazygit",
        "category":    "Terminal",
        "winget_id":   "JesseDuffield.lazygit",
        "check_cmd":   ["lazygit", "--version"],
        "version_url": "https://api.github.com/repos/jesseduffield/lazygit/releases/latest",
        "web_url":     "https://github.com/jesseduffield/lazygit",
        "enabled":     True,
    },
    {
        "name":        "ripgrep",
        "category":    "Terminal",
        "winget_id":   "BurntSushi.ripgrep.MSVC",
        "check_cmd":   ["rg", "--version"],
        "version_url": "https://api.github.com/repos/BurntSushi/ripgrep/releases/latest",
        "web_url":     "https://github.com/BurntSushi/ripgrep",
        "enabled":     True,
    },
    {
        "name":        "zoxide",
        "category":    "Terminal",
        "winget_id":   "ajeetdsouza.zoxide",
        "check_cmd":   ["zoxide", "--version"],
        "version_url": "https://api.github.com/repos/ajeetdsouza/zoxide/releases/latest",
        "web_url":     "https://github.com/ajeetdsouza/zoxide",
        "enabled":     True,
    },

    # ── AI / LLM ──
    {
        "name":        "Claude Code",
        "category":    "AI",
        "winget_id":   None,
        "check_cmd":   ["claude", "--version"],
        "version_url": "https://api.github.com/repos/anthropics/claude-code/releases/latest",
        "web_url":     "https://claude.ai/code",
        "install_cmd": ["npm", "install", "-g", "@anthropic-ai/claude-code"],
        "enabled":     True,
    },
    {
        "name":        "LM Studio",
        "category":    "AI",
        "winget_id":   "LMStudio.LMStudio",
        "check_cmd":   None,
        "version_url": None,
        "web_url":     "https://lmstudio.ai/",
        "enabled":     False,
    },

    # ── Productivity ──
    {
        "name":        "Obsidian",
        "category":    "Productivity",
        "winget_id":   "Obsidian.Obsidian",
        "check_cmd":   None,
        "version_url": "https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest",
        "web_url":     "https://obsidian.md/download",
        "enabled":     True,
    },
    {
        "name":        "PowerToys",
        "category":    "Productivity",
        "winget_id":   "Microsoft.PowerToys",
        "check_cmd":   None,
        "version_url": "https://api.github.com/repos/microsoft/PowerToys/releases/latest",
        "web_url":     "https://github.com/microsoft/PowerToys/releases",
        "enabled":     True,
    },
    {
        "name":        "Everything",
        "category":    "Productivity",
        "winget_id":   "voidtools.Everything",
        "check_cmd":   None,
        "version_url": None,
        "web_url":     "https://www.voidtools.com/downloads/",
        "enabled":     True,
    },

    # ── Media / Comms ──
    {
        "name":        "OBS Studio",
        "category":    "Media",
        "winget_id":   "OBSProject.OBSStudio",
        "check_cmd":   None,
        "version_url": "https://api.github.com/repos/obsproject/obs-studio/releases/latest",
        "web_url":     "https://obsproject.com/download",
        "enabled":     False,
    },
    {
        "name":        "Zoom",
        "category":    "Communication",
        "winget_id":   "Zoom.Zoom",
        "check_cmd":   None,
        "version_url": None,
        "web_url":     "https://zoom.us/download",
        "enabled":     False,
    },
    {
        "name":        "Discord",
        "category":    "Communication",
        "winget_id":   "Discord.Discord",
        "check_cmd":   None,
        "version_url": None,
        "web_url":     "https://discord.com/download",
        "enabled":     False,
    },
]


# ─────────────────────────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────────────────────────

def run_cmd(cmd: list[str]) -> str | None:
    """Run a command and return stdout, or None on failure."""
    try:
        result = subprocess.run(
            cmd, capture_output=True, text=True, timeout=10
        )
        return result.stdout.strip() or result.stderr.strip()
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return None


def extract_version(text: str) -> str | None:
    """Extract a semver-like version from a string."""
    if not text:
        return None
    match = re.search(r"\d+\.\d+[\.\d]*", text)
    return match.group(0) if match else None


def get_installed_version(app: dict) -> str:
    """Get the installed version of an app."""
    cmd = app.get("check_cmd")
    if not cmd:
        # Try via winget
        winget_id = app.get("winget_id")
        if winget_id:
            out = run_cmd(["winget", "list", "--id", winget_id, "--exact"])
            if out:
                v = extract_version(out)
                return v or "Installed"
        return "Unknown"
    out = run_cmd(cmd)
    if out:
        v = extract_version(out)
        return v or "Installed"
    return "Not installed"


def get_latest_version(app: dict) -> str:
    """Fetch the latest version from the internet."""
    url = app.get("version_url")
    if not url:
        return "—"
    try:
        headers = {"User-Agent": "dev-app-manager/1.0"}
        resp = requests.get(url, headers=headers, timeout=8)
        if resp.status_code != 200:
            return "—"
        data = resp.json()

        # GitHub releases API
        if "tag_name" in data:
            tag = data["tag_name"]
            v = extract_version(tag)
            return v or tag

        # GitHub tags (list)
        if isinstance(data, list) and data and "name" in data[0]:
            v = extract_version(data[0]["name"])
            return v or data[0]["name"]

        # Node.js dist index
        if isinstance(data, list) and data and "version" in data[0]:
            for entry in data:
                if entry.get("lts"):
                    v = extract_version(entry["version"])
                    return v or entry["version"]

    except Exception:
        pass
    return "—"


def is_installed(app: dict) -> bool:
    v = get_installed_version(app)
    return v not in ("Not installed", "Unknown", None)


def install_app(app: dict) -> bool:
    """Install an app via winget or custom install_cmd."""
    custom = app.get("install_cmd")
    if custom:
        console.print(f"  [yellow]Running:[/] {' '.join(custom)}")
        result = subprocess.run(custom, capture_output=False)
        return result.returncode == 0

    winget_id = app.get("winget_id")
    if winget_id:
        console.print(f"  [yellow]Running:[/] winget install {winget_id}")
        result = subprocess.run(
            ["winget", "install", "--id", winget_id, "--exact",
             "--accept-package-agreements", "--accept-source-agreements"],
            capture_output=False
        )
        return result.returncode == 0

    console.print(f"  [red]No install method for {app['name']}[/]")
    return False


def open_website(app: dict):
    url = app.get("web_url")
    if url:
        console.print(f"  [cyan]Opening:[/] {url}")
        webbrowser.open(url)


# ─────────────────────────────────────────────────────────────
#  DISPLAY
# ─────────────────────────────────────────────────────────────

def print_banner():
    console.print(Panel.fit(
        "[bold cyan]🛠  Developer App Manager[/]\n"
        "[dim]Install · Check · Update · Browse[/]",
        border_style="cyan"
    ))


def show_apps_table(results: list[dict]):
    table = Table(
        title="App Status",
        box=box.ROUNDED,
        header_style="bold magenta",
        show_lines=True
    )
    table.add_column("App",          style="bold white",  min_width=18)
    table.add_column("Category",     style="dim cyan",    min_width=14)
    table.add_column("Installed",    style="green",       min_width=12)
    table.add_column("Latest",       style="yellow",      min_width=12)
    table.add_column("Status",       min_width=14)
    table.add_column("Enabled",      min_width=8)

    for r in results:
        installed = r["installed"]
        latest    = r["latest"]
        enabled   = "✅" if r["enabled"] else "⬜"

        # Status logic
        if installed in ("Not installed", "Unknown"):
            status = Text("❌ Missing",  style="red")
        elif latest == "—" or installed == "Unknown":
            status = Text("✅ Installed", style="green")
        else:
            try:
                iv = tuple(int(x) for x in installed.split(".")[:3])
                lv = tuple(int(x) for x in latest.split(".")[:3])
                if iv >= lv:
                    status = Text("✅ Up to date", style="green")
                else:
                    status = Text("⬆ Update avail", style="yellow")
            except Exception:
                status = Text("✅ Installed",  style="green")

        table.add_row(
            r["name"], r["category"],
            installed, latest,
            status, enabled
        )

    console.print(table)


# ─────────────────────────────────────────────────────────────
#  ACTIONS
# ─────────────────────────────────────────────────────────────

def action_check(filter_name: str = None):
    """Check installed versions of all apps."""
    apps = [a for a in APPS if not filter_name or filter_name.lower() in a["name"].lower()]
    results = []

    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        console=console, transient=True
    ) as prog:
        task = prog.add_task("Checking versions...", total=len(apps))
        for app in apps:
            prog.update(task, description=f"Checking [cyan]{app['name']}[/]...")
            results.append({
                "name":      app["name"],
                "category":  app["category"],
                "installed": get_installed_version(app),
                "latest":    "—",
                "enabled":   app["enabled"],
            })
            prog.advance(task)

    show_apps_table(results)
    return results


def action_update_check(filter_name: str = None):
    """Check installed versions AND fetch latest from the web."""
    apps = [a for a in APPS if not filter_name or filter_name.lower() in a["name"].lower()]
    results = []

    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        console=console, transient=True
    ) as prog:
        task = prog.add_task("Fetching updates...", total=len(apps))
        for app in apps:
            prog.update(task, description=f"Checking [cyan]{app['name']}[/]...")
            installed = get_installed_version(app)
            latest    = get_latest_version(app)
            results.append({
                "name":      app["name"],
                "category":  app["category"],
                "installed": installed,
                "latest":    latest,
                "enabled":   app["enabled"],
                "app":       app,
            })
            prog.advance(task)

    show_apps_table(results)

    # Offer to open download pages for outdated apps
    outdated = []
    for r in results:
        if r["installed"] in ("Not installed", "Unknown") or r["latest"] == "—":
            continue
        try:
            iv = tuple(int(x) for x in r["installed"].split(".")[:3])
            lv = tuple(int(x) for x in r["latest"].split(".")[:3])
            if lv > iv:
                outdated.append(r)
        except Exception:
            pass

    if outdated:
        console.print(f"\n[yellow]⬆  {len(outdated)} app(s) have updates available:[/]")
        for r in outdated:
            console.print(f"   • [bold]{r['name']}[/] {r['installed']} → {r['latest']}")

        if Confirm.ask("\n[cyan]Open download pages in browser?[/]"):
            for r in outdated:
                open_website(r["app"])
    else:
        console.print("\n[green]✅ All installed apps are up to date![/]")

    return results


def action_install(filter_name: str = None):
    """Install all enabled apps (or a specific one)."""
    apps = [
        a for a in APPS
        if (a["enabled"] or filter_name)
        and (not filter_name or filter_name.lower() in a["name"].lower())
    ]

    console.print(f"\n[bold]Apps to install:[/] {len(apps)}")
    for a in apps:
        console.print(f"  • {a['name']}")

    if not Confirm.ask("\n[cyan]Proceed with installation?[/]"):
        console.print("[yellow]Cancelled.[/]")
        return

    success, failed = [], []
    for app in apps:
        console.rule(f"[bold cyan]{app['name']}[/]")

        # Check if already installed
        installed = get_installed_version(app)
        if installed not in ("Not installed", "Unknown"):
            console.print(f"  [green]Already installed:[/] {installed}")
            success.append(app["name"])
            continue

        ok = install_app(app)
        if ok:
            console.print(f"  [green]✅ Installed successfully[/]")
            success.append(app["name"])
        else:
            console.print(f"  [red]❌ Install failed — opening website...[/]")
            open_website(app)
            failed.append(app["name"])

    # Summary
    console.print()
    console.print(Panel(
        f"[green]✅ Installed:  {len(success)}[/]\n"
        f"[red]❌ Failed:     {len(failed)}[/]\n"
        + (f"\n[dim]Failed:[/] {', '.join(failed)}" if failed else ""),
        title="Installation Summary",
        border_style="cyan"
    ))


def action_open_web(filter_name: str = None):
    """Open download/info pages for apps in the browser."""
    apps = [a for a in APPS if not filter_name or filter_name.lower() in a["name"].lower()]

    console.print("\n[bold]Apps to open in browser:[/]")
    for a in apps:
        console.print(f"  • {a['name']} → [cyan]{a.get('web_url', '—')}[/]")

    if not Confirm.ask("\n[cyan]Open all in browser?[/]"):
        console.print("[yellow]Cancelled.[/]")
        return

    for app in apps:
        open_website(app)


def interactive_menu():
    """Main interactive menu."""
    print_banner()

    while True:
        console.print("\n[bold cyan]What would you like to do?[/]")
        console.print("  [bold]1[/] — Check installed versions")
        console.print("  [bold]2[/] — Check versions + fetch updates online")
        console.print("  [bold]3[/] — Install all enabled apps")
        console.print("  [bold]4[/] — Install a specific app")
        console.print("  [bold]5[/] — Open app websites in browser")
        console.print("  [bold]6[/] — Open a specific app's website")
        console.print("  [bold]q[/] — Quit\n")

        choice = console.input("[bold cyan]Choice: [/]").strip().lower()

        if choice == "1":
            action_check()

        elif choice == "2":
            action_update_check()

        elif choice == "3":
            action_install()

        elif choice == "4":
            name = console.input("[cyan]Enter app name (partial ok): [/]").strip()
            action_install(filter_name=name)

        elif choice == "5":
            action_open_web()

        elif choice == "6":
            name = console.input("[cyan]Enter app name (partial ok): [/]").strip()
            action_open_web(filter_name=name)

        elif choice in ("q", "quit", "exit"):
            console.print("[dim]Goodbye![/]")
            break

        else:
            console.print("[red]Invalid choice, try again.[/]")


# ─────────────────────────────────────────────────────────────
#  ENTRY POINT
# ─────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Developer App Manager")
    parser.add_argument("--check",   action="store_true", help="Check installed versions")
    parser.add_argument("--update",  action="store_true", help="Check versions + fetch updates online")
    parser.add_argument("--install", action="store_true", help="Install all enabled apps")
    parser.add_argument("--open",    action="store_true", help="Open app websites in browser")
    parser.add_argument("--app",     type=str,            help="Target a specific app by name")
    args = parser.parse_args()

    print_banner()

    if args.check:
        action_check(filter_name=args.app)
    elif args.update:
        action_update_check(filter_name=args.app)
    elif args.install:
        action_install(filter_name=args.app)
    elif args.open:
        action_open_web(filter_name=args.app)
    else:
        interactive_menu()


if __name__ == "__main__":
    main()