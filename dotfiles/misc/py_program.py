import winreg
import subprocess
import os

def get_installed_programs():
    """Programs from Add/Remove Programs (registry)."""
    programs = []
    registry_paths = [
        (winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"),
        (winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"),
        (winreg.HKEY_CURRENT_USER, r"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"),
    ]
    
    for hive, path in registry_paths:
        try:
            with winreg.OpenKey(hive, path) as key:
                for i in range(winreg.QueryInfoKey(key)[0]):
                    try:
                        subkey_name = winreg.EnumKey(key, i)
                        with winreg.OpenKey(key, subkey_name) as subkey:
                            try:
                                name = winreg.QueryValueEx(subkey, "DisplayName")[0]
                            except FileNotFoundError:
                                continue
                            
                            def get_val(field):
                                try:
                                    return winreg.QueryValueEx(subkey, field)[0]
                                except FileNotFoundError:
                                    return "N/A"
                            
                            programs.append({
                                "name": name,
                                "version": get_val("DisplayVersion"),
                                "publisher": get_val("Publisher"),
                            })
                    except OSError:
                        continue
        except FileNotFoundError:
            continue
    
    # Dedupe
    seen = set()
    unique = []
    for p in sorted(programs, key=lambda x: x["name"].lower()):
        if p["name"] not in seen:
            seen.add(p["name"])
            unique.append(p)
    return unique


def get_store_apps():
    """Microsoft Store / UWP apps via PowerShell."""
    try:
        result = subprocess.run(
            ["powershell", "-Command",
             "Get-AppxPackage | Select-Object Name, Publisher, Version | ConvertTo-Csv -NoTypeInformation"],
            capture_output=True, text=True, timeout=60
        )
        lines = result.stdout.strip().split("\n")[1:]  # skip header
        apps = []
        for line in lines:
            parts = [p.strip('"') for p in line.split('","')]
            if len(parts) >= 3:
                apps.append({
                    "name": parts[0].strip('"'),
                    "publisher": parts[1],
                    "version": parts[2].strip('"'),
                })
        return sorted(apps, key=lambda x: x["name"].lower())
    except Exception as e:
        return [{"error": str(e)}]


def get_running_processes():
    """Currently running processes via tasklist."""
    try:
        result = subprocess.run(
            ["tasklist", "/fo", "csv", "/nh"],
            capture_output=True, text=True
        )
        processes = []
        for line in result.stdout.strip().split("\n"):
            parts = [p.strip('"') for p in line.split('","')]
            if len(parts) >= 5:
                processes.append({
                    "name": parts[0].strip('"'),
                    "pid": parts[1],
                    "memory": parts[4].strip('"'),
                })
        # Dedupe by name (same process can have multiple instances)
        seen = set()
        unique = []
        for p in sorted(processes, key=lambda x: x["name"].lower()):
            if p["name"] not in seen:
                seen.add(p["name"])
                unique.append(p)
        return unique
    except Exception as e:
        return [{"error": str(e)}]


def get_startup_programs():
    """Programs that run at startup."""
    startup = []
    paths = [
        (winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Microsoft\Windows\CurrentVersion\Run"),
        (winreg.HKEY_CURRENT_USER, r"SOFTWARE\Microsoft\Windows\CurrentVersion\Run"),
        (winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"),
    ]
    for hive, path in paths:
        try:
            with winreg.OpenKey(hive, path) as key:
                for i in range(winreg.QueryInfoKey(key)[1]):
                    try:
                        name, value, _ = winreg.EnumValue(key, i)
                        startup.append({"name": name, "command": value})
                    except OSError:
                        continue
        except FileNotFoundError:
            continue
    return sorted(startup, key=lambda x: x["name"].lower())


def write_section(f, title, items, fields):
    f.write(f"\n{'=' * 80}\n{title} ({len(items)})\n{'=' * 80}\n\n")
    print(f"\n{title}: {len(items)} found")
    for item in items:
        line = " | ".join(str(item.get(field, "N/A")) for field in fields)
        f.write(line + "\n")


if __name__ == "__main__":
    print("Gathering all programs... (this takes 10-30 seconds)\n")
    
    installed = get_installed_programs()
    store = get_store_apps()
    running = get_running_processes()
    startup = get_startup_programs()
    
    output_file = "all_programs.txt"
    with open(output_file, "w", encoding="utf-8") as f:
        f.write("COMPLETE PROGRAMS REPORT\n")
        f.write(f"Total installed: {len(installed)}\n")
        f.write(f"Total store apps: {len(store)}\n")
        f.write(f"Total running: {len(running)}\n")
        f.write(f"Total startup: {len(startup)}\n")
        
        write_section(f, "INSTALLED PROGRAMS", installed,
                      ["name", "version", "publisher"])
        write_section(f, "MICROSOFT STORE APPS", store,
                      ["name", "version", "publisher"])
        write_section(f, "RUNNING PROCESSES", running,
                      ["name", "pid", "memory"])
        write_section(f, "STARTUP PROGRAMS", startup,
                      ["name", "command"])
    
    print(f"\nFull report saved to: {os.path.abspath(output_file)}")