# core.py — install, version check, web logic
import subprocess, re, webbrowser
try:
    import requests
except ImportError:
    subprocess.run(["pip", "install", "requests", "--quiet"])
    import requests

def run_cmd(cmd):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        return r.stdout.strip() or r.stderr.strip() or None
    except Exception:
        return None

def extract_version(text):
    if not text: return None
    m = re.search(r"\d+\.\d+[\.\d]*", text)
    return m.group(0) if m else None

def get_installed_version(app):
    cmd = app.get("check_cmd")
    if cmd:
        out = run_cmd(cmd)
        if out:
            return extract_version(out) or "Installed"
    wid = app.get("winget_id")
    if wid:
        out = run_cmd(["winget", "list", "--id", wid, "--exact"])
        if out and "No installed" not in out and len(out) > 40:
            return extract_version(out) or "Installed"
    return "Not installed"

def get_latest_version(app):
    url = app.get("version_url")
    if not url: return "—"
    try:
        resp = requests.get(url, headers={"User-Agent": "dev-manager/3"}, timeout=8)
        if resp.status_code != 200: return "—"
        data = resp.json()
        if "tag_name" in data:
            return extract_version(data["tag_name"]) or data["tag_name"]
        if isinstance(data, list) and data:
            for d in data:
                if d.get("lts"):
                    return extract_version(d.get("version", "")) or "—"
            first = data[0]
            key = next((k for k in ["name", "tag_name", "version"] if k in first), None)
            return extract_version(first.get(key, "")) or "—" if key else "—"
    except Exception:
        pass
    return "—"

def version_cmp(installed, latest):
    """Returns: 'missing' | 'ok' | 'outdated' | 'unknown'"""
    if installed == "Not installed": return "missing"
    if latest == "—": return "ok"
    try:
        iv = tuple(int(x) for x in installed.split(".")[:3])
        lv = tuple(int(x) for x in latest.split(".")[:3])
        return "outdated" if lv > iv else "ok"
    except Exception:
        return "unknown"

def install_app(app):
    cmd = app.get("install_cmd")
    if cmd:
        return subprocess.run(cmd).returncode == 0
    wid = app.get("winget_id")
    if wid:
        return subprocess.run([
            "winget", "install", "--id", wid, "--exact",
            "--accept-package-agreements", "--accept-source-agreements"
        ]).returncode == 0
    return False

def open_website(app):
    url = app.get("web_url")
    if url: webbrowser.open(url)

def add_to_startup(app):
    """Add app to Windows registry startup."""
    import winreg
    path = app.get("winget_id") or app.get("name")
    exe  = app.get("exe_path")
    if not exe: return False
    try:
        key = winreg.OpenKey(
            winreg.HKEY_CURRENT_USER,
            r"Software\Microsoft\Windows\CurrentVersion\Run",
            0, winreg.KEY_SET_VALUE
        )
        winreg.SetValueEx(key, app["name"], 0, winreg.REG_SZ, exe)
        winreg.CloseKey(key)
        return True
    except Exception:
        return False

def get_startup_apps():
    """Read current Windows startup registry entries."""
    try:
        import winreg
        key = winreg.OpenKey(
            winreg.HKEY_CURRENT_USER,
            r"Software\Microsoft\Windows\CurrentVersion\Run"
        )
        items = {}
        i = 0
        while True:
            try:
                name, val, _ = winreg.EnumValue(key, i)
                items[name] = val
                i += 1
            except OSError:
                break
        winreg.CloseKey(key)
        return items
    except Exception:
        return {}

def remove_from_startup(name):
    try:
        import winreg
        key = winreg.OpenKey(
            winreg.HKEY_CURRENT_USER,
            r"Software\Microsoft\Windows\CurrentVersion\Run",
            0, winreg.KEY_SET_VALUE
        )
        winreg.DeleteValue(key, name)
        winreg.CloseKey(key)
        return True
    except Exception:
        return False

def filter_apps(apps, name=None, category=None, tier=None, tag=None):
    r = apps
    if name:     r = [a for a in r if name.lower() in a["name"].lower()]
    if category: r = [a for a in r if category.lower() in a["category"].lower()]
    if tier:     r = [a for a in r if a["tier"] == tier]
    if tag:      r = [a for a in r if tag in a.get("tags", [])]
    return r
