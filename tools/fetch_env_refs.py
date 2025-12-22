from pathlib import Path

links = [
    ("WezTerm Docs", "https://wezfurlong.org/wezterm/"),
    ("WezTerm Config (Lua)", "https://wezfurlong.org/wezterm/config/files.html"),
    ("WezTerm GitHub", "https://github.com/wez/wezterm"),
    ("Starship Docs", "https://starship.rs/config/"),
    ("Starship GitHub", "https://github.com/starship/starship"),
    ("Zellij Docs", "https://zellij.dev/documentation/"),
    ("Zellij GitHub", "https://github.com/zellij-org/zellij"),
    ("GlazeWM GitHub", "https://github.com/glzr-io/glazewm"),
    ("GlazeWM Cheatsheet", "https://github.com/glzr-io/glazewm/blob/main/resources/assets/cheatsheet.png"),
    ("PowerToys Docs", "https://learn.microsoft.com/windows/powertoys/"),
    ("PowerToys GitHub", "https://github.com/microsoft/PowerToys"),
    ("WinGet Docs", "https://learn.microsoft.com/windows/package-manager/winget/"),
    ("Conda Docs", "https://docs.conda.io/projects/conda/en/latest/"),
    ("Git for Windows", "https://gitforwindows.org/"),
]

md = ["# Tool Links (Source of Truth)\n", "Official / primary references used in this environment.\n"]
for name, url in links:
    md.append(f"- {name}: {url}\n")

out = Path("TOOLS_LINKS.md")
out.write_text("".join(md), encoding="utf-8")
print(f"Wrote {out.resolve()}")
