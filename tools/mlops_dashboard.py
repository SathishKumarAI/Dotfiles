#!/usr/bin/env python3
"""mlops_dashboard.py - local control plane for the Windows -> ML/DevOps pipeline.

Think AWX/Semaphore, scoped to one machine: a web UI that shows state, runs
pipeline stages on click, streams their output, and records what each run
actually installed.

Reads setup/state/pipeline-state.json (written by setup/pipeline-windows-ml.ps1)
and layers live read-only probes on top. Stdlib only - the same dependency-free
rule setup/md2html.py follows.

  This tool NEVER installs, updates, or modifies GPU drivers. It only reads
  nvidia-smi for display.

SECURITY - read before using --allow-run
    Without --allow-run the server is strictly read-only: run endpoints return
    403 and the buttons render disabled. That is the default.

    --allow-run lets a web page start installers on your machine, so it is
    guarded three ways:
      1. the listener binds 127.0.0.1 only,
      2. every POST must carry the per-start token embedded in the page,
      3. the Origin/Referer header must match this server.
    Together these stop another site open in your browser from POSTing to
    localhost and installing software. Do not expose this port to a network.

Usage:
    python tools/mlops_dashboard.py                    # read-only, :8765
    python tools/mlops_dashboard.py --allow-run        # enable the run buttons
    python tools/mlops_dashboard.py --port 9000
    python tools/mlops_dashboard.py --once out.html    # static snapshot

Endpoints:
    GET  /              the panel
    GET  /api/state     pipeline state + live probes
    GET  /api/runs      run history (what each run installed)
    GET  /api/log       ?id=<run>&offset=<n>  incremental log
    POST /api/run       {"stage": "..."}      start a stage   (needs --allow-run)
"""
from __future__ import annotations

import argparse
import json
import os
import re
import secrets
import shutil
import subprocess
import sys
import threading
import webbrowser
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse, parse_qs

REPO = Path(__file__).resolve().parent.parent
STATE_DIR = REPO / "setup" / "state"
STATE_FILE = STATE_DIR / "pipeline-state.json"
LOG_DIR = STATE_DIR / "logs"
HISTORY_FILE = STATE_DIR / "history.json"
PIPELINE = REPO / "setup" / "pipeline-windows-ml.ps1"

STAGE_ORDER = ["preflight", "base", "apps", "ml", "wsl", "verify"]
STAGE_META = {
    "preflight": ("Preflight", "Probe machine, GPU and disk. Changes nothing.", "safe"),
    "base": ("Base toolset", "winget core apps plus the scoop CLI cluster.", "installs"),
    "apps": ("Applications", "Restored app set from the machine inventory.", "installs"),
    "ml": ("ML runtime", "Python, uv, venv, CUDA-matched PyTorch.", "installs"),
    "wsl": ("WSL2", "Ubuntu with GPU passthrough. Needs admin.", "admin"),
    "verify": ("Verify", "Tool inventory plus a live torch/CUDA probe.", "safe"),
}
CATEGORY_LABEL = {
    "core": "Core", "python": "Python", "runtime": "Runtimes", "cli": "Modern CLI",
    "shell": "Shell & terminal", "editor": "Editor & git", "devops": "DevOps", "ai": "AI",
    "docs": "Docs & OCR",
}
PROFILE_PATH = Path.home() / "Documents" / "PowerShell" / "Microsoft.PowerShell_profile.ps1"
PROFILE_SAMPLE = REPO / "assets" / "powershell-profile.ps1"

ALLOW_RUN = False
RUN_TOKEN = secrets.token_urlsafe(24)
SERVER_ORIGINS = set()
_RUNS = {}
_RUNS_LOCK = threading.Lock()
STORE_STUB_SUSPECTS = {"python", "python3"}
_MISE = None


# --------------------------------------------------------------------------
# Read-only probes
# --------------------------------------------------------------------------
def refresh_path():
    """Re-read PATH from the registry.

    A long-lived shell holds the PATH snapshot it launched with, so tools
    installed afterwards look missing. Windows-only; a no-op elsewhere.
    """
    if sys.platform != "win32":
        return
    try:
        import winreg
    except ImportError:
        return
    parts = []
    for root, key in (
        (winreg.HKEY_LOCAL_MACHINE,
         r"SYSTEM\CurrentControlSet\Control\Session Manager\Environment"),
        (winreg.HKEY_CURRENT_USER, "Environment"),
    ):
        try:
            with winreg.OpenKey(root, key) as k:
                val, _ = winreg.QueryValueEx(k, "Path")
                parts.append(os.path.expandvars(val))
        except OSError:
            pass
    if parts:
        os.environ["PATH"] = os.pathsep.join(parts)


def _run(cmd):
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        return out.stdout.strip() if out.returncode == 0 else ""
    except Exception:
        return ""


def probe_gpu():
    """Read nvidia-smi. Nothing here alters the driver."""
    if not shutil.which("nvidia-smi"):
        return {"present": False, "note": "nvidia-smi not found"}
    fields = ("name,driver_version,memory.total,memory.used,compute_cap,"
              "temperature.gpu,utilization.gpu,power.draw,power.limit")
    raw = _run(["nvidia-smi", "--query-gpu=" + fields, "--format=csv,noheader,nounits"])
    if not raw:
        return {"present": False, "note": "nvidia-smi returned nothing"}
    p = [x.strip() for x in raw.splitlines()[0].split(",")]

    def num(i, cast=float, default=0):
        try:
            return cast(p[i])
        except (ValueError, IndexError):
            return default

    cc = num(4)
    if cc >= 12.0:
        channel, arch = "cu128", "Blackwell (sm_120)"
    elif cc >= 8.9:
        channel, arch = "cu128", "Ada / Hopper"
    elif cc >= 8.0:
        channel, arch = "cu126", "Ampere"
    elif cc >= 7.0:
        channel, arch = "cu126", "Volta / Turing"
    else:
        channel, arch = "cpu", "pre-Volta"
    return {
        "present": True, "name": p[0], "driver": p[1],
        "vramTotalMB": num(2, int), "vramUsedMB": num(3, int),
        "computeCap": cc, "architecture": arch, "torchChannel": channel,
        "tempC": num(5, int), "utilPct": num(6, int),
        "powerW": num(7), "powerLimitW": num(8),
    }


TOOLS = [
    ("winget", "core"), ("scoop", "core"), ("git", "core"), ("gh", "core"),
    ("python", "python"), ("uv", "python"), ("conda", "python"),
    ("node", "runtime"), ("mise", "runtime"), ("go", "runtime"),
    ("rg", "cli"), ("fd", "cli"), ("bat", "cli"), ("eza", "cli"),
    ("fzf", "cli"), ("zoxide", "cli"), ("delta", "cli"), ("jq", "cli"),
    ("starship", "shell"), ("zellij", "shell"), ("chezmoi", "shell"), ("wezterm", "shell"),
    ("nvim", "editor"), ("code", "editor"), ("lazygit", "editor"),
    ("docker", "devops"), ("minikube", "devops"), ("psql", "devops"), ("wsl", "devops"),
    ("claude", "ai"),
    # Docs group. Neither installer touches PATH, so both were installed and
    # unresolvable until update-user-path.ps1 learned to find them. GNU.Wget2
    # ships as wget2.exe - there is no `wget` on a Windows box.
    ("pandoc", "docs"), ("tesseract", "docs"), ("wget2", "docs"),
]

# A tool on PATH is not a tool you can use. On Windows nothing creates a
# PowerShell profile, so zoxide/starship/mise install fine and stay inert -
# `z` simply does not exist. Probe the profile, not just the binaries.
SHELL_INIT = [
    ("zoxide", "zoxide init", "z / zi directory jumping"),
    ("starship", "starship init", "prompt"),
    ("mise", "mise activate", "runtime shims"),
]


def probe_tools():
    global _MISE
    refresh_path()
    _MISE = shutil.which("mise")
    out = []
    for name, cat in TOOLS:
        path = shutil.which(name) or ""
        present = bool(path)
        # Only python/python3 get the zero-byte test. Those Store aliases are
        # dead stubs. winget's launcher is also zero bytes but entirely real,
        # so testing everything this way reports installed tools as missing.
        if present and name in STORE_STUB_SUSPECTS:
            try:
                if Path(path).stat().st_size == 0:
                    present, path = False, ""
            except OSError:
                pass
        # mise-managed runtimes live behind mise shims, not the raw PATH.
        if not present and _MISE:
            shim = _run([_MISE, "which", name])
            if shim and Path(shim).exists():
                present, path = True, shim + "  (mise)"
        out.append({"name": name, "category": cat, "present": present, "path": path})
    return out


def probe_shell():
    """Is the PowerShell profile in place, and is each tool actually wired in?

    Presence on PATH and presence in the shell are different facts. This reads
    the profile text rather than launching pwsh, so it stays a cheap read-only
    probe like the rest of this file.
    """
    text = ""
    present = PROFILE_PATH.exists()
    if present:
        try:
            text = PROFILE_PATH.read_text(encoding="utf-8-sig", errors="replace")
        except OSError:
            present = False
    inits = [{"tool": tool, "marker": marker, "why": why,
              "installed": bool(shutil.which(tool)), "wired": marker in text}
             for tool, marker, why in SHELL_INIT]
    return {"profilePath": str(PROFILE_PATH), "profilePresent": present,
            "samplePath": str(PROFILE_SAMPLE), "sampleAvailable": PROFILE_SAMPLE.exists(),
            "inits": inits}


def probe_disks():
    disks = []
    for letter in "CDEFGH":
        root = letter + ":\\"
        if not Path(root).exists():
            continue
        try:
            u = shutil.disk_usage(root)
        except OSError:
            continue
        disks.append({"name": letter, "usedGB": round(u.used / 1e9),
                      "freeGB": round(u.free / 1e9), "totalGB": round(u.total / 1e9)})
    return disks


def load_state():
    if not STATE_FILE.exists():
        return {}
    try:
        return json.loads(STATE_FILE.read_text(encoding="utf-8-sig"))
    except (json.JSONDecodeError, OSError):
        return {}


def load_history():
    if not HISTORY_FILE.exists():
        return []
    try:
        return json.loads(HISTORY_FILE.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return []


def save_history(entries):
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    HISTORY_FILE.write_text(json.dumps(entries[-100:], indent=2), encoding="utf-8")


# --------------------------------------------------------------------------
# Run engine
# --------------------------------------------------------------------------
def _tool_names_present():
    return {t["name"] for t in probe_tools() if t["present"]}


def start_run(stage):
    """Launch a pipeline stage, streaming stdout to a per-run log file."""
    if stage != "all" and stage not in STAGE_ORDER:
        raise ValueError("unknown stage: " + str(stage))
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    run_id = datetime.now().strftime("%Y%m%d-%H%M%S") + "-" + stage
    log_path = LOG_DIR / (run_id + ".log")

    cmd = ["powershell", "-ExecutionPolicy", "Bypass", "-File", str(PIPELINE), "-Force"]
    if stage != "all":
        cmd += ["-Stages", stage]
    if stage in ("wsl", "all"):
        cmd += ["-IncludeWsl"] if stage == "wsl" else []

    before = _tool_names_present()
    rec = {
        "id": run_id, "stage": stage,
        "startedAt": datetime.now().isoformat(timespec="seconds"),
        "finishedAt": None, "exitCode": None, "status": "running",
        "log": str(log_path), "added": [], "removed": [],
    }
    with _RUNS_LOCK:
        _RUNS[run_id] = rec

    def worker():
        with open(log_path, "w", encoding="utf-8", errors="replace") as fh:
            fh.write("$ " + " ".join(cmd) + "\n\n")
            fh.flush()
            try:
                proc = subprocess.Popen(
                    cmd, stdout=fh, stderr=subprocess.STDOUT, cwd=str(REPO),
                    creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
                code = proc.wait()
            except Exception as e:
                fh.write("\n[dashboard] failed to launch: " + str(e) + "\n")
                code = -1
        after = _tool_names_present()
        rec["added"] = sorted(after - before)
        rec["removed"] = sorted(before - after)
        rec["exitCode"] = code
        rec["status"] = "ok" if code == 0 else "failed"
        rec["finishedAt"] = datetime.now().isoformat(timespec="seconds")
        rec["toolsAfter"] = len(after)
        hist = load_history()
        hist.append(dict(rec))
        save_history(hist)

    threading.Thread(target=worker, daemon=True).start()
    return rec


# Raw pipeline output is hostile to read: winget repeats a four-line
# "already installed" paragraph per package, PowerShell appends a caret/
# CategoryInfo/FullyQualifiedErrorId block to every error record, and stage
# banners are buried. format_log collapses the noise and tags each surviving
# line so the UI can filter and colour it.
_BOILERPLATE = re.compile(
    r"^\s*\+\s+(CategoryInfo|FullyQualifiedErrorId)"
    r"|^\s*\+\s*~+\s*$"
    r"|^At line:\d+ char:\d+"
    r"|^\s*\+\s+\.{3}"
    r"|^\s*$")
_PKG_START = re.compile(r"^\+ (?:winget install )?([A-Za-z0-9_.\-]+)")
_SCOOP = re.compile(r"^\+ scoop install (.+)$")
_BLOCK_END = re.compile(r"^(\+ |={2,}|#{2,}|\s{0,3}==)")
_STAGE = re.compile(r"^#+\s+STAGE:\s+(\w+)")


def _level(line):
    if line.startswith("$ "):
        return "cmd"
    if _STAGE.match(line):
        return "stage"
    if line.startswith("== ") or line.startswith("=== "):
        return "head"
    if re.search(r"FAIL|Error|Exception|not recognized|does not belong", line):
        return "err"
    if re.search(r"WARN|^\s+!\s|warning", line):
        return "warn"
    if re.search(r"Successfully installed|\+ stage .* ok|OK\s|was installed successfully", line):
        return "ok"
    return "info"


def format_log(text):
    """Collapse repetitive installer noise; tag each line with level + stage."""
    lines = text.splitlines()
    out, dropped, stage = [], 0, ""
    i = 0
    while i < len(lines):
        ln = lines[i].rstrip()
        if _BOILERPLATE.match(ln):
            dropped += 1
            i += 1
            continue

        m = _STAGE.match(ln)
        if m:
            stage = m.group(1)
            out.append({"t": "stage", "s": stage.upper(), "g": stage})
            i += 1
            continue

        # Collapse a package block into a single verdict line.
        pm = _PKG_START.match(ln)
        sm = _SCOOP.match(ln)
        if pm or sm:
            pkg = (sm.group(1) if sm else pm.group(1)).strip()
            j = i + 1
            body = []
            while j < len(lines) and not _BLOCK_END.match(lines[j]):
                body.append(lines[j])
                j += 1
            blob = " ".join(body)
            verdict = None
            if "already installed" in blob or "No available upgrade" in blob:
                verdict, lvl = "already installed", "skip"
            elif "Successfully installed" in blob or "was installed successfully" in blob:
                verdict, lvl = "installed", "ok"
            elif "failed" in blob.lower():
                verdict, lvl = "failed", "err"
            if verdict:
                out.append({"t": lvl, "s": pkg + "  -  " + verdict, "g": stage})
                dropped += len(body)
                i = j
                continue

        out.append({"t": _level(ln), "s": ln, "g": stage})
        i += 1
    return out, dropped


def read_log(run_id, offset):
    safe = re.sub(r"[^A-Za-z0-9_.-]", "", run_id or "")
    path = LOG_DIR / (safe + ".log")
    if not safe or not path.exists():
        return {"offset": 0, "text": "", "done": True, "missing": True}
    data = path.read_text(encoding="utf-8", errors="replace")
    with _RUNS_LOCK:
        rec = _RUNS.get(safe)
    done = not rec or rec["status"] != "running"
    lines, dropped = format_log(data)
    return {"offset": len(data), "text": data[offset:], "lines": lines,
            "collapsed": dropped, "rawBytes": len(data), "done": done,
            "status": rec["status"] if rec else "ok",
            "exitCode": rec["exitCode"] if rec else None,
            "added": rec["added"] if rec else [],
            "removed": rec["removed"] if rec else []}


def build_payload():
    state = load_state()
    by_id = {s.get("id"): s for s in state.get("stages", []) if isinstance(s, dict)}
    stages = []
    for i, sid in enumerate(STAGE_ORDER, start=1):
        s = by_id.get(sid, {})
        label, blurb, kind = STAGE_META[sid]
        stages.append({
            "n": i, "id": sid, "label": label, "blurb": blurb, "kind": kind,
            "status": s.get("status", "pending"),
            "durationSec": s.get("durationSec", 0) or 0,
            "detail": (s.get("detail") or "")[:6000],
            "finishedAt": s.get("finishedAt") or "",
        })
    with _RUNS_LOCK:
        active = [r["id"] for r in _RUNS.values() if r["status"] == "running"]
    return {
        "generated": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "hasState": bool(state), "allowRun": ALLOW_RUN, "activeRuns": active,
        "machine": state.get("machine", {}), "ml": state.get("ml", {}),
        "stages": stages, "gpu": probe_gpu(), "tools": probe_tools(),
        "disks": probe_disks(), "categoryLabels": CATEGORY_LABEL,
        "shell": probe_shell(),
        "history": load_history()[-25:][::-1],
    }


# --------------------------------------------------------------------------
# Page
# --------------------------------------------------------------------------
# Palette "silicon telemetry": copper interconnect on an indigo die.
# Status trio #2ea37f / #b28f10 / #cf4a55 passes all five dataviz validator
# checks on a dark surface. Status is never colour alone - every chip and row
# carries a glyph and a text label.
PAGE = r"""<!doctype html>
<html lang="en" data-theme="dark">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Bring-up console - Windows to ML workstation</title>
<style>
  :root{
    --ink:#0d1017; --surface:#151a24; --raised:#1d2431; --line:#2a3446; --line-2:#374359;
    --text:#e8edf5; --text-2:#98a3b7; --text-3:#5c6980;
    --copper:#c2662b; --copper-lo:#a15426; --copper-hi:#d98a4f; --copper-pale:#e8ab7a;
    --signal:#3d7fd6;
    --good:#2ea37f; --warn:#b28f10; --crit:#cf4a55;
    --good-ink:#7fdcbd; --warn-ink:#e3c25a; --crit-ink:#f0949a;
    --mono:"JetBrainsMono Nerd Font","JetBrains Mono",Consolas,"Cascadia Mono",monospace;
    --sans:"Segoe UI Variable Display","Segoe UI",system-ui,-apple-system,sans-serif;
    --r:10px;
  }
  *{box-sizing:border-box}
  html,body{margin:0;padding:0}
  body{
    background:var(--ink); color:var(--text); font-family:var(--sans);
    font-size:15px; line-height:1.5; -webkit-font-smoothing:antialiased;
    background-image:
      radial-gradient(950px 520px at 88% -10%, rgba(194,102,43,.13), transparent 62%),
      radial-gradient(720px 430px at 3% 0%, rgba(61,127,214,.075), transparent 60%);
    background-attachment:fixed;
  }
  .wrap{max-width:1240px;margin:0 auto;padding:26px 22px 80px}
  .eyebrow{font-family:var(--mono);font-size:10.5px;letter-spacing:.16em;
    text-transform:uppercase;color:var(--text-3)}

  header{display:flex;justify-content:space-between;align-items:flex-end;gap:20px;
    flex-wrap:wrap;padding-bottom:16px;border-bottom:1px solid var(--line)}
  h1{font-size:clamp(24px,3.2vw,35px);line-height:1.05;margin:6px 0 0;
    letter-spacing:-.028em;font-weight:640}
  h1 .dim{color:var(--text-3);font-weight:350}
  .live{display:flex;align-items:center;gap:8px;font-family:var(--mono);
    font-size:11.5px;color:var(--text-2)}
  .dot{width:7px;height:7px;border-radius:50%;background:var(--good);
    animation:pulse 2.4s ease-out infinite}
  @keyframes pulse{0%{box-shadow:0 0 0 0 rgba(46,163,127,.5)}
    70%{box-shadow:0 0 0 8px rgba(46,163,127,0)}100%{box-shadow:0 0 0 0 rgba(46,163,127,0)}}

  nav.tabs{display:flex;gap:2px;margin:18px 0 20px;border-bottom:1px solid var(--line);flex-wrap:wrap}
  .tab{appearance:none;background:none;border:0;border-bottom:2px solid transparent;
    color:var(--text-3);font-family:var(--mono);font-size:12px;letter-spacing:.09em;
    text-transform:uppercase;padding:9px 15px;cursor:pointer;margin-bottom:-1px}
  .tab:hover{color:var(--text-2)}
  .tab[aria-selected="true"]{color:var(--copper-pale);border-bottom-color:var(--copper)}
  .tab .ct{font-size:10.5px;color:var(--text-3);margin-left:6px}
  .view[hidden]{display:none}

  .gate{margin:0 0 22px;padding:24px 24px 20px;border-radius:var(--r);
    background:linear-gradient(160deg,#1a2130 0%,#141922 100%);
    border:1px solid var(--line);position:relative;overflow:hidden}
  .gate::after{content:"";position:absolute;inset:0;pointer-events:none;
    background:repeating-linear-gradient(0deg,rgba(255,255,255,.02) 0 1px,transparent 1px 3px)}
  .gate-grid{display:grid;grid-template-columns:1fr auto 1fr;gap:20px;align-items:center;
    position:relative;z-index:1}
  .gate-cell .k{font-family:var(--mono);font-size:11px;letter-spacing:.13em;
    text-transform:uppercase;color:var(--text-3);margin-bottom:7px}
  .gate-num{font-family:var(--mono);font-size:clamp(34px,5.6vw,54px);line-height:1;
    font-weight:700;letter-spacing:-.03em}
  .gate-num.cap{color:var(--copper-pale)} .gate-num.ch{color:var(--good-ink)}
  .gate-sub{color:var(--text-2);font-size:13px;margin-top:7px}
  .arrow{display:flex;flex-direction:column;align-items:center;gap:5px;color:var(--copper)}
  .arrow .lbl{font-family:var(--mono);font-size:9.5px;letter-spacing:.14em;
    text-transform:uppercase;color:var(--text-3);white-space:nowrap}
  .gate-foot{margin-top:18px;padding-top:14px;border-top:1px solid var(--line);
    display:flex;gap:9px;flex-wrap:wrap;align-items:center;position:relative;z-index:1}

  .chip{display:inline-flex;align-items:center;gap:7px;padding:4px 11px 4px 9px;
    border-radius:999px;font-family:var(--mono);font-size:11.5px;border:1px solid;white-space:nowrap}
  .chip .g{font-weight:700}
  .chip.ok{color:var(--good-ink);border-color:rgba(46,163,127,.42);background:rgba(46,163,127,.11)}
  .chip.warnc{color:var(--warn-ink);border-color:rgba(178,143,16,.42);background:rgba(178,143,16,.11)}
  .chip.bad{color:var(--crit-ink);border-color:rgba(207,74,85,.42);background:rgba(207,74,85,.11)}
  .chip.idle{color:var(--text-3);border-color:var(--line);background:rgba(255,255,255,.02)}

  .cols{display:grid;grid-template-columns:1.3fr 1fr;gap:18px;align-items:start}
  @media(max-width:900px){.cols{grid-template-columns:1fr}.gate-grid{grid-template-columns:1fr;gap:14px}}
  .panel{background:var(--surface);border:1px solid var(--line);border-radius:var(--r);
    padding:18px 19px;margin-bottom:18px}
  .panel h2{font-size:12px;letter-spacing:.13em;text-transform:uppercase;
    font-family:var(--mono);color:var(--text-2);margin:0 0 3px;font-weight:600}
  .panel .note{color:var(--text-3);font-size:12.5px;margin:0 0 14px}

  .stage{display:grid;grid-template-columns:26px 1fr auto;gap:12px;padding:12px 0;
    border-bottom:1px solid rgba(42,52,70,.55);align-items:start}
  .stage:last-child{border-bottom:0}
  .stage .n{font-family:var(--mono);font-size:11px;color:var(--text-3);padding-top:4px}
  .stage .nm{font-weight:560;font-size:14.5px}
  .stage .bl{color:var(--text-3);font-size:12.5px;margin-top:2px}
  .stage .rt{display:flex;flex-direction:column;gap:7px;align-items:flex-end}
  .bar{height:4px;border-radius:2px;background:rgba(255,255,255,.05);width:96px;overflow:hidden}
  .bar i{display:block;height:100%;border-radius:2px;background:var(--copper)}
  .secs{font-family:var(--mono);font-size:11px;color:var(--text-3)}

  .btn{appearance:none;font-family:var(--mono);font-size:11.5px;letter-spacing:.05em;
    padding:6px 13px;border-radius:6px;cursor:pointer;white-space:nowrap;
    border:1px solid var(--copper-lo);background:rgba(194,102,43,.14);color:var(--copper-pale);
    transition:background .15s ease,border-color .15s ease}
  .btn:hover:not(:disabled){background:rgba(194,102,43,.26);border-color:var(--copper)}
  .btn:disabled{opacity:.4;cursor:not-allowed}
  .btn.ghost{border-color:var(--line-2);background:transparent;color:var(--text-2)}
  .btn.ghost:hover:not(:disabled){background:rgba(255,255,255,.04);border-color:var(--text-3)}
  .btn.primary{background:var(--copper-lo);border-color:var(--copper);color:#fff5ee}
  .btn.primary:hover:not(:disabled){background:var(--copper)}

  details.tap{margin-top:7px}
  details.tap>summary{cursor:pointer;font-family:var(--mono);font-size:11px;
    color:var(--text-3);list-style:none;display:inline-flex;align-items:center;gap:6px;
    padding:2px 0;user-select:none}
  details.tap>summary::-webkit-details-marker{display:none}
  details.tap>summary::before{content:"\25B8";display:inline-block;transition:transform .15s ease}
  details.tap[open]>summary::before{transform:rotate(90deg)}
  details.tap>summary:hover{color:var(--text-2)}
  .dump{margin-top:8px;padding:11px 13px;border-radius:7px;background:#0a0d14;
    border:1px solid var(--line);font-family:var(--mono);font-size:11.5px;
    color:var(--text-2);white-space:pre-wrap;word-break:break-word;
    max-height:300px;overflow:auto;line-height:1.55}

  .console{background:#0a0d14;border:1px solid var(--line);border-radius:var(--r);
    font-family:var(--mono);font-size:12px;line-height:1.6;color:#c8d2e2;
    padding:14px 16px;height:min(62vh,620px);overflow:auto;white-space:pre-wrap;word-break:break-word}
  .console .ln-warn{color:var(--warn-ink)}
  .console .ln-err{color:var(--crit-ink)}
  .console .ln-ok{color:var(--good-ink)}
  .console .ln-hd{color:var(--copper-pale);font-weight:600}
  .console .ln-cmd{color:var(--signal)}
  .conbar{display:flex;gap:9px;align-items:center;flex-wrap:wrap;margin-bottom:11px}
  .fbtn{appearance:none;font-family:var(--mono);font-size:11px;letter-spacing:.06em;
    padding:4px 11px;border-radius:999px;cursor:pointer;border:1px solid var(--line-2);
    background:transparent;color:var(--text-3)}
  .fbtn:hover{color:var(--text-2);border-color:var(--text-3)}
  .fbtn.on{color:var(--copper-pale);border-color:var(--copper-lo);background:rgba(194,102,43,.14)}
  #conFind{font-family:var(--mono);font-size:11.5px;background:var(--raised);color:var(--text);
    border:1px solid var(--line-2);border-radius:6px;padding:5px 10px;min-width:150px;flex:1;max-width:280px}
  .conmeta{font-family:var(--mono);font-size:10.5px;color:var(--text-3);white-space:nowrap}
  .lrow{display:flex;gap:11px;padding:1px 0}
  .lrow .gut{flex:0 0 62px;color:#3d4759;text-align:right;user-select:none;font-size:10.5px;
    padding-top:1px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
  .lrow .txt{flex:1;min-width:0;white-space:pre-wrap;word-break:break-word}
  .l-stage{margin:14px 0 4px;padding:5px 11px;border-radius:5px;font-weight:700;letter-spacing:.14em;
    background:rgba(194,102,43,.14);color:var(--copper-pale);border:1px solid rgba(194,102,43,.3);
    display:inline-block;font-size:11px}
  .l-cmd .txt{color:var(--signal)}
  .l-head .txt{color:var(--copper-pale);font-weight:600}
  .l-ok .txt{color:var(--good-ink)}
  .l-warn .txt{color:var(--warn-ink)}
  .l-err .txt{color:var(--crit-ink)}
  .l-skip .txt{color:#55617a}
  .l-info .txt{color:#c8d2e2}
  mark{background:rgba(178,143,16,.35);color:#fff;border-radius:2px}
  .conbar select{font-family:var(--mono);font-size:11.5px;background:var(--raised);
    color:var(--text);border:1px solid var(--line-2);border-radius:6px;padding:5px 9px;max-width:100%}
  label.follow{font-family:var(--mono);font-size:11.5px;color:var(--text-2);
    display:inline-flex;align-items:center;gap:6px;cursor:pointer}

  .meter{margin:12px 0}
  .meter .top{display:flex;justify-content:space-between;font-size:12.5px;margin-bottom:6px}
  .meter .top b{font-family:var(--mono);font-weight:600}
  .track{height:7px;border-radius:4px;background:rgba(255,255,255,.055);overflow:hidden}
  .track i{display:block;height:100%;border-radius:4px;transition:width .5s ease}
  .kv{display:grid;grid-template-columns:auto 1fr;gap:7px 15px;font-size:13.5px;margin:0}
  .kv dt{color:var(--text-3)} .kv dd{margin:0;font-family:var(--mono);font-size:12.5px;word-break:break-word}
  .cat{margin-bottom:14px}
  .cat h3{font-size:10.5px;letter-spacing:.14em;text-transform:uppercase;font-family:var(--mono);
    color:var(--text-3);margin:0 0 8px;font-weight:600}
  .tools{display:flex;flex-wrap:wrap;gap:6px}
  .tool{display:inline-flex;align-items:center;gap:6px;padding:4px 10px;border-radius:6px;
    font-family:var(--mono);font-size:12px;border:1px solid}
  .tool.y{color:#8fe0c4;border-color:rgba(46,163,127,.33);background:rgba(46,163,127,.08)}
  .tool.n{color:var(--text-3);border-color:var(--line);background:rgba(255,255,255,.015)}

  .run{border:1px solid var(--line);border-radius:8px;padding:13px 15px;margin-bottom:11px;
    background:var(--surface)}
  .run .hd{display:flex;justify-content:space-between;gap:12px;align-items:center;flex-wrap:wrap}
  .run .rid{font-family:var(--mono);font-size:12px;color:var(--text-2)}
  .run .meta{font-family:var(--mono);font-size:11px;color:var(--text-3);margin-top:5px}
  .delta{display:flex;flex-wrap:wrap;gap:5px;margin-top:9px}
  .d-add{color:var(--good-ink);border:1px solid rgba(46,163,127,.35);background:rgba(46,163,127,.09);
    padding:2px 8px;border-radius:5px;font-family:var(--mono);font-size:11px}
  .d-rem{color:var(--crit-ink);border:1px solid rgba(207,74,85,.35);background:rgba(207,74,85,.09);
    padding:2px 8px;border-radius:5px;font-family:var(--mono);font-size:11px}

  .banner{border-radius:8px;padding:11px 14px;margin-bottom:16px;font-size:13px;
    border:1px solid rgba(178,143,16,.4);background:rgba(178,143,16,.09);color:var(--warn-ink)}
  footer{margin-top:30px;padding-top:16px;border-top:1px solid var(--line);
    color:var(--text-3);font-size:12.5px;display:flex;justify-content:space-between;gap:16px;flex-wrap:wrap}
  code{font-family:var(--mono);font-size:.92em;color:var(--copper-pale)}
  .empty{color:var(--text-3);font-size:13px;padding:6px 0}
  :focus-visible{outline:2px solid var(--signal);outline-offset:2px;border-radius:4px}
  @media(prefers-reduced-motion:reduce){*{animation:none!important;transition:none!important}}
</style>
</head>
<body>
<div class="wrap">
  <header>
    <div>
      <div class="eyebrow">Workstation bring-up console</div>
      <h1>Windows box <span class="dim">to</span> ML workstation</h1>
    </div>
    <div class="live"><span class="dot" aria-hidden="true"></span><span id="stamp">probing</span></div>
  </header>

  <nav class="tabs" role="tablist">
    <button class="tab" role="tab" aria-selected="true"  data-view="overview">Overview</button>
    <button class="tab" role="tab" aria-selected="false" data-view="pipeline">Pipeline</button>
    <button class="tab" role="tab" aria-selected="false" data-view="console">Console</button>
    <button class="tab" role="tab" aria-selected="false" data-view="tools">Tools<span class="ct" id="tabToolCt"></span></button>
    <button class="tab" role="tab" aria-selected="false" data-view="history">History<span class="ct" id="tabRunCt"></span></button>
  </nav>

  <section class="view" id="v-overview">
    <div class="gate" aria-labelledby="gate-h">
      <div class="eyebrow" id="gate-h">The gate &mdash; wheel channel is chosen here</div>
      <div class="gate-grid">
        <div class="gate-cell">
          <div class="k">Compute capability</div>
          <div class="gate-num cap" id="cap">--</div>
          <div class="gate-sub" id="gpuname">detecting</div>
        </div>
        <div class="arrow" aria-hidden="true">
          <span class="lbl">selects</span>
          <svg width="56" height="15" viewBox="0 0 56 15" fill="none">
            <path d="M0 7.5h46" stroke="currentColor" stroke-width="1.5" stroke-dasharray="4 3"/>
            <path d="M44 2.5 53 7.5l-9 5z" fill="currentColor"/></svg>
          <span class="lbl">pytorch index</span>
        </div>
        <div class="gate-cell">
          <div class="k">Wheel channel</div>
          <div class="gate-num ch" id="chan">--</div>
          <div class="gate-sub" id="arch">&nbsp;</div>
        </div>
      </div>
      <div class="gate-foot" id="gatefoot"></div>
    </div>
    <div class="cols">
      <div><section class="panel"><h2>GPU telemetry</h2>
        <p class="note">Read-only. Nothing here touches the driver.</p>
        <div id="gpu"></div></section></div>
      <div>
        <section class="panel"><h2>ML runtime</h2><div id="ml"></div></section>
        <section class="panel"><h2>Shell integration</h2>
          <p class="note">Installed is not the same as usable. Nothing on Windows creates a
            PowerShell profile, so these tools can sit on <code>PATH</code> and still do
            nothing &mdash; no <code>z</code>, no prompt, no shims.</p>
          <div id="shell"></div></section>
        <section class="panel"><h2>Machine</h2><div id="machine"></div></section>
      </div>
    </div>
  </section>

  <section class="view" id="v-pipeline" hidden>
    <div id="runBanner"></div>
    <section class="panel">
      <h2>Stages</h2>
      <p class="note">Six stages, run in order. Each is idempotent &mdash; re-running skips
        what already succeeded. Open a stage's <em>output</em> tap to read what it recorded.</p>
      <div style="display:flex;gap:8px;flex-wrap:wrap;margin-bottom:15px">
        <button class="btn primary" id="runAll">&#9655; Run full pipeline</button>
        <button class="btn ghost" id="runVerify">&#8635; Re-verify only</button>
      </div>
      <div id="stages"></div>
    </section>
  </section>

  <section class="view" id="v-console" hidden>
    <section class="panel">
      <h2>Console</h2>
      <p class="note">Live stdout from the pipeline. Every run also writes a file under
        <code>setup/state/logs/</code>.</p>
      <div class="conbar">
        <select id="logPick" aria-label="Select run log"></select>
        <span class="chip idle" id="conStatus"><span class="g">&#9675;</span>idle</span>
        <label class="follow"><input type="checkbox" id="follow" checked> follow</label>
      </div>
      <div class="conbar">
        <span class="eyebrow" style="margin-right:2px">show</span>
        <button class="fbtn on" data-f="all">all</button>
        <button class="fbtn" data-f="changes">changes</button>
        <button class="fbtn" data-f="problems">problems</button>
        <button class="fbtn" data-f="raw">raw</button>
        <input id="conFind" type="search" placeholder="filter text…" aria-label="Filter log lines">
        <span class="conmeta" id="conMeta"></span>
      </div>
      <div class="console" id="console" role="log" aria-live="polite">No run selected.</div>
    </section>
  </section>

  <section class="view" id="v-tools" hidden>
    <section class="panel">
      <h2>Tool inventory</h2>
      <p class="note">Live probe. Zero-byte Store aliases report as missing;
        mise-managed runtimes resolve through <code>mise which</code>.</p>
      <div id="tools"></div>
    </section>
  </section>

  <section class="view" id="v-history" hidden>
    <section class="panel">
      <h2>Run history</h2>
      <p class="note">Every run, and which tools it actually added or removed &mdash;
        measured by probing before and after, not by parsing output.</p>
      <div id="history"></div>
    </section>
  </section>

  <footer>
    <span>No GPU driver is installed or modified &mdash; <code>nvidia-smi</code> is read only.</span>
    <span id="src"></span>
  </footer>
</div>

<script>
const BOOT = __BOOTSTRAP__;
const TOKEN = "__TOKEN__";
const esc = s => String(s ?? "").replace(/[&<>"]/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;"}[c]));
const el = id => document.getElementById(id);
let DATA = BOOT, curLog = null, logOffset = 0, logTimer = null;

const ST = {ok:["ok","●","ok"], failed:["bad","✕","failed"],
            running:["warnc","◐","running"], pending:["idle","○","pending"]};
const chip = s => { const a = ST[s]||ST.pending;
  return '<span class="chip '+a[0]+'"><span class="g" aria-hidden="true">'+a[1]+'</span>'+a[2]+'</span>'; };

function meter(label, value, total, unit, colour){
  const pct = total > 0 ? Math.min(100,(value/total)*100) : 0;
  return '<div class="meter"><div class="top"><span>'+esc(label)+'</span>'
    +'<b>'+value+unit+' <span style="color:var(--text-3)">/ '+total+unit+'</span></b></div>'
    +'<div class="track"><i style="width:'+pct.toFixed(1)+'%;background:'+colour+'"></i></div></div>';
}

document.querySelectorAll(".tab").forEach(t => t.addEventListener("click", () => {
  document.querySelectorAll(".tab").forEach(x => x.setAttribute("aria-selected", x===t ? "true":"false"));
  document.querySelectorAll(".view").forEach(v => v.hidden = true);
  el("v-" + t.dataset.view).hidden = false;
}));

function render(d){
  DATA = d;
  el("stamp").textContent = d.generated;
  el("src").textContent = d.allowRun ? "run mode enabled" : "read-only mode";
  el("tabToolCt").textContent = d.tools.filter(t=>t.present).length + "/" + d.tools.length;
  el("tabRunCt").textContent = (d.history||[]).length || "";

  const g = d.gpu||{}, ml = d.ml||{};
  if (g.present){
    el("cap").textContent = Number(g.computeCap).toFixed(1);
    el("chan").textContent = g.torchChannel;
    el("gpuname").textContent = g.name + "  ·  driver " + g.driver;
    el("arch").textContent = g.architecture;
  } else {
    el("cap").textContent="n/a"; el("chan").textContent="cpu";
    el("gpuname").textContent=g.note||"no NVIDIA GPU"; el("arch").textContent="CPU wheels";
  }
  const f=[];
  if (ml.torch) f.push('<span class="chip idle"><span class="g">■</span>torch '+esc(ml.torch)+'</span>');
  if (ml.cudaBuild) f.push('<span class="chip idle"><span class="g">■</span>cuda build '+esc(ml.cudaBuild)+'</span>');
  if (ml.cudaAvailable===true) f.push('<span class="chip ok"><span class="g">●</span>cuda available</span>');
  else if (ml.venvPresent) f.push('<span class="chip bad"><span class="g">✕</span>cuda unavailable</span>');
  if (ml.matmulOk===true) f.push('<span class="chip ok"><span class="g">✓</span>kernels verified on device</span>');
  else if (ml.matmulOk===false) f.push('<span class="chip bad"><span class="g">✕</span>no kernel image for this GPU</span>');
  el("gatefoot").innerHTML = f.join("") || '<span class="empty">Run the ml + verify stages to populate.</span>';

  const maxDur = Math.max(1, ...d.stages.map(s=>s.durationSec||0));
  const running = (d.activeRuns||[]).length>0;
  el("stages").innerHTML = d.stages.map(s=>{
    const w=((s.durationSec||0)/maxDur)*100;
    const kindNote = s.kind==="admin"
      ? ' <span class="chip warnc" style="margin-left:6px"><span class="g">!</span>needs admin</span>'
      : s.kind==="safe"
      ? ' <span class="chip idle" style="margin-left:6px"><span class="g">○</span>read-only</span>' : "";
    return '<div class="stage"><div class="n">'+String(s.n).padStart(2,"0")+'</div><div>'
      +'<div class="nm">'+esc(s.label)+kindNote+'</div>'
      +'<div class="bl">'+esc(s.blurb)+'</div>'
      +(s.detail ? '<details class="tap"><summary>output ('+s.detail.length+' chars)</summary>'
                 +'<div class="dump">'+esc(s.detail)+'</div></details>' : "")
      +'</div><div class="rt">'+chip(s.status)
      +(s.durationSec ? '<div class="bar"><i style="width:'+w.toFixed(1)+'%"></i></div>'
                      +'<div class="secs">'+s.durationSec+'s</div>' : "")
      +'<button class="btn run-stage" data-stage="'+s.id+'"'+((!d.allowRun||running)?" disabled":"")+'>▷ run</button>'
      +'</div></div>';
  }).join("");
  document.querySelectorAll(".run-stage").forEach(b => b.onclick = () => startRun(b.dataset.stage));
  el("runAll").disabled = !d.allowRun || running;
  el("runVerify").disabled = !d.allowRun || running;

  el("runBanner").innerHTML = d.allowRun ? "" :
    '<div class="banner"><strong>Read-only mode.</strong> Run buttons are disabled. '
    +'Restart with <code>python tools/mlops_dashboard.py --allow-run</code> to install from this page. '
    +'That flag lets a web page start installers, so it is off by default.</div>';

  if (g.present){
    let h = meter("VRAM", g.vramUsedMB, g.vramTotalMB, " MB", "var(--copper)")
          + meter("Utilisation", g.utilPct, 100, "%", "var(--signal)");
    if (g.powerLimitW>0) h += meter("Power", Math.round(g.powerW), Math.round(g.powerLimitW), " W", "var(--copper-hi)");
    h += '<dl class="kv"><dt>Temp</dt><dd>'+g.tempC+' &deg;C</dd><dt>Driver</dt><dd>'+esc(g.driver)
       +'</dd><dt>Arch</dt><dd>'+esc(g.architecture)+'</dd></dl>';
    el("gpu").innerHTML = h;
  } else el("gpu").innerHTML = '<div class="empty">'+esc(g.note||"no GPU detected")+'</div>';

  if (ml.venvPresent){
    let h = '<dl class="kv"><dt>Python</dt><dd>'+esc(ml.python||"?")+'</dd>'
      +'<dt>torch</dt><dd>'+esc(ml.torch||"not installed")+'</dd>'
      +'<dt>CUDA build</dt><dd>'+esc(ml.cudaBuild||"-")+'</dd>'
      +'<dt>Device</dt><dd>'+esc(ml.device||"-")+'</dd>'
      +'<dt>Capability</dt><dd>'+esc(ml.capability||"-")+'</dd>'
      +'<dt>venv</dt><dd>'+esc(ml.venvPath||"-")+'</dd></dl>';
    const pk = ml.packages||{}, keys = Object.keys(pk);
    if (keys.length) h += '<div class="tools" style="margin-top:11px">' + keys.map(k =>
      '<span class="tool '+(pk[k]?"y":"n")+'"><span aria-hidden="true">'+(pk[k]?"✓":"·")+'</span>'+esc(k)+'</span>').join("") + '</div>';
    el("ml").innerHTML = h;
  } else el("ml").innerHTML = '<div class="empty">No ML venv recorded. Run <code>ml</code> then <code>verify</code>.</div>';

  const sh = d.shell||{}, inits = sh.inits||[];
  if (sh.profilePresent === undefined) {
    el("shell").innerHTML = '<div class="empty">No shell probe in this payload.</div>';
  } else {
    // Three states, because the middle one is the trap: the binary is there,
    // the profile is not, so the tool silently does nothing.
    let h = '<div class="tools">' + inits.map(i => {
      const cls = (i.installed && i.wired) ? "y" : "n";
      const gl  = (i.installed && i.wired) ? "✓" : (i.installed ? "!" : "·");
      const note = (i.installed && i.wired) ? i.why
                 : (i.installed ? "installed, not wired" : "not installed");
      return '<span class="tool '+cls+'" title="'+esc(note)+'"><span aria-hidden="true">'
        +gl+'</span>'+esc(i.tool)+'</span>';
    }).join("") + '</div>';
    h += '<dl class="kv" style="margin-top:11px"><dt>Profile</dt><dd>'
      + (sh.profilePresent ? esc(sh.profilePath) : "missing") + '</dd></dl>';
    const inert = inits.filter(i => i.installed && !i.wired);
    if (!sh.profilePresent || inert.length) {
      h += '<div class="banner" style="margin-top:11px"><strong>'
        + (sh.profilePresent ? esc(inert.length + " tool(s) installed but not wired.")
                             : "No PowerShell profile.")
        + '</strong> Copy the sample from the repo, then reopen the terminal:'
        + '<br><code>Copy-Item assets\\powershell-profile.ps1 $PROFILE</code></div>';
    }
    el("shell").innerHTML = h;
  }

  const m = d.machine||{}; let mh="";
  if (m.cpu) mh += '<dl class="kv"><dt>OS</dt><dd>'+esc(m.os||"")+'</dd><dt>CPU</dt><dd>'+esc(m.cpu)
    +'</dd><dt>Cores</dt><dd>'+esc(m.cores)+'c / '+esc(m.threads)+'t</dd><dt>RAM</dt><dd>'+esc(m.ramGB)+' GB</dd></dl>';
  (d.disks||[]).forEach(dk => { mh += meter("Disk "+dk.name+":", dk.usedGB, dk.totalGB, " GB", "var(--copper-lo)"); });
  el("machine").innerHTML = mh || '<div class="empty">Run the preflight stage.</div>';

  const byCat={}; (d.tools||[]).forEach(t=>{(byCat[t.category] ||= []).push(t);});
  el("tools").innerHTML = Object.keys(byCat).map(c=>{
    const p = byCat[c].filter(t=>t.present).length;
    return '<div class="cat"><h3>'+esc(d.categoryLabels[c]||c)
      +' <span style="color:var(--text-3);letter-spacing:0">'+p+'/'+byCat[c].length+'</span></h3><div class="tools">'
      + byCat[c].map(t => '<span class="tool '+(t.present?"y":"n")+'" title="'+esc(t.path||"not found")+'">'
      +'<span aria-hidden="true">'+(t.present?"✓":"·")+'</span>'+esc(t.name)+'</span>').join("")
      +'</div></div>';
  }).join("");

  const hist = d.history||[];
  el("history").innerHTML = hist.length ? hist.map(r=>{
    const st = r.status==="ok" ? "ok" : r.status==="running" ? "running" : "failed";
    const delta = (r.added||[]).map(x=>'<span class="d-add">+ '+esc(x)+'</span>').join("")
                + (r.removed||[]).map(x=>'<span class="d-rem">− '+esc(x)+'</span>').join("");
    return '<div class="run"><div class="hd"><span class="rid">'+esc(r.id)+'</span>'+chip(st)+'</div>'
      +'<div class="meta">stage '+esc(r.stage)+' · started '+esc(r.startedAt)
      +(r.finishedAt?' · finished '+esc(r.finishedAt):"")
      +(r.exitCode!=null?' · exit '+r.exitCode:"")+'</div>'
      +(delta ? '<div class="delta">'+delta+'</div>'
              : '<div class="meta" style="margin-top:8px">no tool changes detected</div>')
      +'<details class="tap"><summary>open log</summary><div class="dump" id="h-'+esc(r.id)+'">loading…</div></details>'
      +'</div>';
  }).join("") : '<div class="empty">No runs yet. Start one from the Pipeline tab.</div>';

  document.querySelectorAll("details.tap").forEach(dt=>{
    if (dt.dataset.bound) return; dt.dataset.bound = "1";
    dt.addEventListener("toggle", async ()=>{
      if(!dt.open) return;
      const box = dt.querySelector("[id^='h-']"); if(!box || box.dataset.loaded) return;
      const id = box.id.slice(2);
      const r = await fetch("/api/log?id="+encodeURIComponent(id)+"&offset=0").then(r=>r.json()).catch(()=>null);
      box.textContent = (r && r.text) ? r.text : "(log unavailable)"; box.dataset.loaded = "1";
    });
  });

  const pick = el("logPick"), prev = pick.value;
  pick.innerHTML = hist.map(r=>'<option value="'+esc(r.id)+'">'+esc(r.id)+' · '+esc(r.status)+'</option>').join("")
                || '<option value="">no runs yet</option>';
  if (prev) pick.value = prev;
}

async function startRun(stage){
  if (!DATA.allowRun) return;
  const r = await fetch("/api/run", {
    method:"POST", headers:{"Content-Type":"application/json","X-Token":TOKEN},
    body: JSON.stringify({stage:stage})
  }).then(r=>r.json()).catch(e=>({error:String(e)}));
  if (r.error){ alert("Could not start: " + r.error); return; }
  document.querySelector('.tab[data-view="console"]').click();
  attachLog(r.id);
  tick();
}
el("runAll").onclick    = () => startRun("all");
el("runVerify").onclick = () => startRun("verify");
el("logPick").onchange  = e => attachLog(e.target.value);

let LINES = [], RAWTEXT = "", FILTER = "all", FIND = "";

// all      - every formatted line, noise already collapsed
// changes  - only what actually changed state
// problems - only what needs attention
// raw      - the unprocessed log, nothing collapsed or dropped
const KEEP = {
  all:      () => true,
  changes:  t => t === "ok" || t === "err" || t === "stage",
  problems: t => t === "err" || t === "warn" || t === "stage",
};

function hl(text){
  const e = esc(text);
  if (!FIND) return e;
  const hay = e.toLowerCase(), needle = FIND.toLowerCase();
  let out = "", i = 0;
  for (;;){
    const k = hay.indexOf(needle, i);
    if (k < 0){ out += e.slice(i); break; }
    out += e.slice(i, k) + "<mark>" + e.slice(k, k + needle.length) + "</mark>";
    i = k + needle.length;
  }
  return out;
}

function paintLines(){
  const con = el("console");
  if (FILTER === "raw"){
    con.innerHTML = '<div class="lrow l-info"><span class="txt">' + hl(RAWTEXT || "(empty)") + '</span></div>';
    if (el("follow").checked) con.scrollTop = con.scrollHeight;
    return (RAWTEXT || "").split(String.fromCharCode(10)).length;
  }
  const keep = KEEP[FILTER] || KEEP.all;
  const find = FIND.toLowerCase();
  let shown = 0;
  const html = LINES.filter(l => keep(l.t) && (!find || l.s.toLowerCase().includes(find)))
    .map(l => {
      shown++;
      if (l.t === "stage") return '<div class="l-stage">' + esc(l.s) + '</div>';
      return '<div class="lrow l-' + l.t + '"><span class="gut">' + esc(l.g || "") + '</span>'
           + '<span class="txt">' + hl(l.s) + '</span></div>';
    }).join("");
  con.innerHTML = html || '<div class="empty">Nothing matches this filter.</div>';
  if (el("follow").checked) con.scrollTop = con.scrollHeight;
  return shown;
}

document.querySelectorAll(".fbtn").forEach(b => b.onclick = () => {
  document.querySelectorAll(".fbtn").forEach(x => x.classList.toggle("on", x === b));
  FILTER = b.dataset.f;
  updateMeta(paintLines());
});
el("conFind").oninput = e => { FIND = e.target.value.trim(); updateMeta(paintLines()); };

let META = {collapsed: 0, raw: 0};
function updateMeta(shown){
  el("conMeta").textContent =
    shown + " / " + LINES.length + " lines"
    + (META.collapsed ? "  ·  " + META.collapsed + " noise lines collapsed" : "")
    + (META.raw ? "  ·  " + (META.raw / 1024).toFixed(1) + " KB raw" : "");
}

function attachLog(id){
  if (!id) return;
  curLog = id;
  el("logPick").value = id;
  LINES = [];
  el("console").innerHTML = '<div class="empty">loading…</div>';
  if (logTimer) clearInterval(logTimer);
  const pump = async () => {
    const r = await fetch("/api/log?id=" + encodeURIComponent(curLog) + "&offset=0")
                .then(r => r.json()).catch(() => null);
    if (!r) return;
    LINES = r.lines || [];
    RAWTEXT = r.text || "";
    META = {collapsed: r.collapsed || 0, raw: r.rawBytes || 0};
    updateMeta(paintLines());
    const cs = el("conStatus");
    if (r.done){
      const ok = r.status === "ok";
      cs.className = "chip " + (ok ? "ok" : "bad");
      cs.innerHTML = '<span class="g">' + (ok ? "●" : "✕") + '</span>' + r.status
                   + (r.exitCode != null ? " · exit " + r.exitCode : "");
      clearInterval(logTimer); logTimer = null; tick();
    } else {
      cs.className = "chip warnc"; cs.innerHTML = '<span class="g">◐</span>running';
    }
  };
  pump();
  logTimer = setInterval(pump, 1200);
}

render(BOOT);
async function tick(){
  try{ const r = await fetch("/api/state",{cache:"no-store"}); if(r.ok) render(await r.json()); }
  catch(e){}
}
if (location.protocol.startsWith("http")) setInterval(tick, 5000);
</script>
</body>
</html>
"""


def render_page():
    return (PAGE.replace("__BOOTSTRAP__", json.dumps(build_payload()))
                .replace("__TOKEN__", RUN_TOKEN))


# --------------------------------------------------------------------------
# Server
# --------------------------------------------------------------------------
class Handler(BaseHTTPRequestHandler):
    server_version = "mlops-dashboard"

    def _send(self, body, ctype, code=200):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.end_headers()
        self.wfile.write(body)

    def _json(self, obj, code=200):
        self._send(json.dumps(obj).encode("utf-8"), "application/json; charset=utf-8", code)

    def _same_origin(self):
        """Reject cross-site POSTs so another page in the browser cannot drive
        installers on this machine."""
        for hdr in ("Origin", "Referer"):
            v = self.headers.get(hdr)
            if v:
                return urlparse(v).netloc in SERVER_ORIGINS
        return False

    def do_GET(self):
        u = urlparse(self.path)
        if u.path == "/api/state":
            self._json(build_payload())
        elif u.path == "/api/runs":
            self._json(load_history()[::-1])
        elif u.path == "/api/log":
            q = parse_qs(u.query)
            rid = (q.get("id") or [""])[0]
            try:
                off = int((q.get("offset") or ["0"])[0])
            except ValueError:
                off = 0
            self._json(read_log(rid, off))
        elif u.path in ("/", "/index.html"):
            self._send(render_page().encode("utf-8"), "text/html; charset=utf-8")
        else:
            self.send_error(404)

    def do_POST(self):
        if urlparse(self.path).path != "/api/run":
            self.send_error(404)
            return
        if not ALLOW_RUN:
            self._json({"error": "read-only mode; restart with --allow-run"}, 403)
            return
        if self.headers.get("X-Token") != RUN_TOKEN:
            self._json({"error": "bad or missing token"}, 403)
            return
        if not self._same_origin():
            self._json({"error": "cross-origin request refused"}, 403)
            return
        try:
            n = int(self.headers.get("Content-Length") or 0)
            body = json.loads(self.rfile.read(n) or b"{}")
            rec = start_run(str(body.get("stage", "")))
        except ValueError as e:
            self._json({"error": str(e)}, 400)
            return
        except Exception as e:
            self._json({"error": str(e)}, 500)
            return
        self._json({"id": rec["id"], "stage": rec["stage"]})

    def log_message(self, fmt, *args):
        pass


def main():
    global ALLOW_RUN
    ap = argparse.ArgumentParser(description="Windows -> ML pipeline control panel")
    ap.add_argument("--port", type=int, default=8765)
    ap.add_argument("--host", default="127.0.0.1")
    ap.add_argument("--no-browser", action="store_true")
    ap.add_argument("--allow-run", action="store_true",
                    help="enable the install buttons (see SECURITY in the docstring)")
    ap.add_argument("--once", metavar="FILE", help="write a static HTML snapshot and exit")
    args = ap.parse_args()
    ALLOW_RUN = args.allow_run

    if args.once:
        Path(args.once).write_text(render_page(), encoding="utf-8")
        print("wrote " + args.once)
        return

    for h in {args.host, "127.0.0.1", "localhost"}:
        SERVER_ORIGINS.add(h + ":" + str(args.port))

    url = "http://" + args.host + ":" + str(args.port) + "/"
    srv = ThreadingHTTPServer((args.host, args.port), Handler)
    print("ML/DevOps control panel -> " + url)
    print("state: " + str(STATE_FILE))
    print("logs:  " + str(LOG_DIR))
    print("run mode: ENABLED (install buttons live)" if ALLOW_RUN
          else "run mode: off (read-only). Use --allow-run to enable install buttons.")
    print("ctrl-c to stop")
    if not args.no_browser:
        webbrowser.open(url)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        print("\nstopped")
        srv.server_close()


if __name__ == "__main__":
    main()
