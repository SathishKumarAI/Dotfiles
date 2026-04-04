# config.py — profiles, custom apps, preferences
import json, os
from pathlib import Path

CONFIG_DIR  = Path.home() / ".dev-manager"
CONFIG_FILE = CONFIG_DIR / "config.json"
CUSTOM_FILE = CONFIG_DIR / "custom_apps.json"

DEFAULT_CONFIG = {
    "active_profile": "default",
    "profiles": {
        "default":  {"name": "Default",   "description": "All machines",   "tiers": ["essential", "recommended"]},
        "machine1": {"name": "Machine 1",  "description": "Home laptop",    "tiers": ["essential", "recommended"], "tags": ["machine1"]},
        "machine2": {"name": "Machine 2",  "description": "Work desktop",   "tiers": ["essential", "recommended"], "tags": ["machine2"]},
        "minimal":  {"name": "Minimal",    "description": "Just essentials","tiers": ["essential"]},
        "full":     {"name": "Full Stack", "description": "Everything",     "tiers": ["essential", "recommended", "optional"]},
        "ai":       {"name": "AI Engineer","description": "AI/ML focused",  "tiers": ["essential", "recommended"], "tags": ["ai"]},
    },
    "preferences": {
        "check_updates_on_start": False,
        "show_skip_tier":         False,
        "confirm_before_install": True,
        "open_web_on_fail":       True,
        "theme":                  "dark",
    },
    "disabled_apps": [],
    "pinned_apps":   [],
}

CUSTOM_APPS_TEMPLATE = [
    {
        "_comment":    "Add your own apps below. Copy this template.",
        "name":        "My Custom App",
        "category":    "Custom",
        "tier":        "optional",
        "winget_id":   "Publisher.AppName",
        "check_cmd":   ["myapp", "--version"],
        "version_url": None,
        "web_url":     "https://example.com/download",
        "approx_mb":   100,
        "tags":        ["custom"],
        "note":        "Why I need this app",
    }
]

class ConfigManager:
    def __init__(self):
        CONFIG_DIR.mkdir(exist_ok=True)
        self._data = self._load()

    def _load(self):
        if CONFIG_FILE.exists():
            try:
                with open(CONFIG_FILE) as f:
                    saved = json.load(f)
                # Merge with defaults to pick up new keys
                merged = {**DEFAULT_CONFIG, **saved}
                merged["profiles"]    = {**DEFAULT_CONFIG["profiles"],    **saved.get("profiles", {})}
                merged["preferences"] = {**DEFAULT_CONFIG["preferences"], **saved.get("preferences", {})}
                return merged
            except Exception:
                pass
        return dict(DEFAULT_CONFIG)

    def save(self):
        with open(CONFIG_FILE, "w") as f:
            json.dump(self._data, f, indent=2)

    # ── Profiles ──────────────────────────────────────────

    @property
    def active_profile_name(self):
        return self._data["active_profile"]

    @property
    def active_profile(self):
        return self._data["profiles"].get(self.active_profile_name, DEFAULT_CONFIG["profiles"]["default"])

    def set_profile(self, name):
        if name in self._data["profiles"]:
            self._data["active_profile"] = name
            self.save()
            return True
        return False

    def add_profile(self, key, name, description, tiers, tags=None):
        self._data["profiles"][key] = {
            "name": name, "description": description,
            "tiers": tiers, "tags": tags or []
        }
        self.save()

    def delete_profile(self, key):
        if key in self._data["profiles"] and key not in ("default",):
            del self._data["profiles"][key]
            if self._data["active_profile"] == key:
                self._data["active_profile"] = "default"
            self.save()
            return True
        return False

    def list_profiles(self):
        return self._data["profiles"]

    # ── Custom apps ───────────────────────────────────────

    def load_custom_apps(self):
        if not CUSTOM_FILE.exists():
            with open(CUSTOM_FILE, "w") as f:
                json.dump(CUSTOM_APPS_TEMPLATE, f, indent=2)
            return []
        try:
            with open(CUSTOM_FILE) as f:
                apps = json.load(f)
            return [a for a in apps if "_comment" not in a]
        except Exception:
            return []

    def add_custom_app(self, app_dict):
        apps = self.load_custom_apps()
        apps = [a for a in apps if a.get("name") != app_dict["name"]]
        apps.append(app_dict)
        with open(CUSTOM_FILE, "w") as f:
            json.dump(apps, f, indent=2)

    def remove_custom_app(self, name):
        apps = [a for a in self.load_custom_apps() if a.get("name") != name]
        with open(CUSTOM_FILE, "w") as f:
            json.dump(apps, f, indent=2)

    # ── Preferences ───────────────────────────────────────

    def get(self, key, default=None):
        return self._data["preferences"].get(key, default)

    def set(self, key, value):
        self._data["preferences"][key] = value
        self.save()

    # ── Disabled / Pinned ─────────────────────────────────

    def is_disabled(self, name):
        return name in self._data.get("disabled_apps", [])

    def toggle_disabled(self, name):
        lst = self._data.setdefault("disabled_apps", [])
        if name in lst: lst.remove(name)
        else: lst.append(name)
        self.save()

    def is_pinned(self, name):
        return name in self._data.get("pinned_apps", [])

    def toggle_pinned(self, name):
        lst = self._data.setdefault("pinned_apps", [])
        if name in lst: lst.remove(name)
        else: lst.append(name)
        self.save()

    # ── Export / Import ───────────────────────────────────

    def export_config(self, path):
        with open(path, "w") as f:
            json.dump(self._data, f, indent=2)

    def import_config(self, path):
        with open(path) as f:
            self._data = json.load(f)
        self.save()

    def get_config_path(self):
        return str(CONFIG_FILE)

    def get_custom_path(self):
        return str(CUSTOM_FILE)
