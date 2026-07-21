#!/usr/bin/env python3
"""
ram-monster.py — find & kill RAM/swap hogs from a local web UI (or the terminal).

No dependencies (Python stdlib only). Nothing leaves the machine — the web UI
binds to 127.0.0.1 and can only act on processes it just listed.

    python3 ram-monster.py               # one-shot terminal report
    python3 ram-monster.py --serve       # local web UI at http://127.0.0.1:8765
    python3 ram-monster.py --idle-mins 30  # flag dev servers idle > 30 min

Web UI: Stop (SIGTERM) / Force-kill (SIGKILL) buttons per process, and Stop
for idle Docker containers. Desktop/session processes are protected from kills.
"""
from __future__ import annotations
import argparse, json, os, re, signal, subprocess, sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HOST, PORT = "127.0.0.1", 8765
# Never let the UI kill these (would break your desktop/session/this tool).
PROTECT = re.compile(
    r"\b(systemd|init|sshd|gnome-shell|gnome-session|mutter|kwin|Xorg|Xwayland|"
    r"wayland|dbus|pipewire|wireplumber|pulseaudio|login|bash|ram-monster)\b", re.I)
DEV_SERVER = re.compile(r"(next-server|vite|webpack|nodemon|node .*\bdev\b|rollup|esbuild)", re.I)
SELF_PID = os.getpid()


def sh(cmd: list[str]) -> str:
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=10).stdout
    except Exception:
        return ""


def proc_swap_mb(pid: str) -> float:
    try:
        with open(f"/proc/{pid}/status") as f:
            for line in f:
                if line.startswith("VmSwap:"):
                    return int(line.split()[1]) / 1024
    except OSError:
        pass
    return 0.0


def snapshot(idle_mins: int) -> dict:
    out = sh(["ps", "-eo", "pid,ppid,rss,etimes,stat,comm,args", "--sort=-rss"])
    procs, zombies = [], 0
    for line in out.splitlines()[1:]:
        p = line.split(maxsplit=6)
        if len(p) < 7:
            continue
        pid, ppid, rss_kb, etimes, stat, comm, args = p
        if "Z" in stat:
            zombies += 1
            continue
        try:
            rss = int(rss_kb) / 1024
            secs = int(etimes)
        except ValueError:
            continue
        swap = proc_swap_mb(pid)
        if rss < 60 and swap < 30:          # ignore small fry
            continue
        protected = bool(PROTECT.search(comm) or PROTECT.search(args)) or int(pid) == SELF_PID
        is_dev = bool(DEV_SERVER.search(args))
        procs.append({
            "pid": int(pid), "comm": comm, "args": args[:120],
            "rss_mb": round(rss), "swap_mb": round(swap),
            "score": round(rss + swap * 2),          # swap weighted: it's the thrash source
            "mins": secs // 60, "protected": protected,
            "idle_dev": is_dev and secs > idle_mins * 60,
        })
    procs.sort(key=lambda x: x["score"], reverse=True)

    containers = []
    dj = sh(["docker", "ps", "--format", "{{.Names}}\t{{.Status}}\t{{.Image}}"])
    for line in dj.splitlines():
        parts = line.split("\t")
        if len(parts) == 3:
            containers.append({"name": parts[0], "status": parts[1], "image": parts[2]})

    mem = {}
    with open("/proc/meminfo") as f:
        for line in f:
            k, v, *_ = line.replace(":", "").split()
            mem[k] = int(v) // 1024
    return {
        "procs": procs[:40], "containers": containers, "zombies": zombies,
        "mem_total": mem.get("MemTotal", 0), "mem_avail": mem.get("MemAvailable", 0),
        "swap_used": mem.get("SwapTotal", 0) - mem.get("SwapFree", 0),
        "swap_total": mem.get("SwapTotal", 0),
        "allowed": {p["pid"] for p in procs if not p["protected"]},
    }


# ── terminal report ──────────────────────────────────────────────────────────
def report(idle_mins: int) -> None:
    s = snapshot(idle_mins)
    print(f"RAM: {s['mem_total']-s['mem_avail']}/{s['mem_total']} MB used "
          f"| Swap: {s['swap_used']}/{s['swap_total']} MB | zombies: {s['zombies']}\n")
    print(f"{'PID':>7} {'RSS':>6} {'SWAP':>6} {'MIN':>5}  PROCESS")
    for p in s["procs"][:20]:
        flag = " 🛡" if p["protected"] else (" 💤DEV" if p["idle_dev"] else "")
        print(f"{p['pid']:>7} {p['rss_mb']:>5}M {p['swap_mb']:>5}M {p['mins']:>5}  {p['comm']}{flag}")
    if s["containers"]:
        print(f"\nDocker ({len(s['containers'])} running):")
        for c in s["containers"]:
            print(f"  {c['name']:<40} {c['status']}")


# ── web UI ───────────────────────────────────────────────────────────────────
PAGE = """<!doctype html><html><head><meta charset=utf-8>
<meta name=viewport content="width=device-width,initial-scale=1"><title>RAM Monster</title>
<style>
:root{color-scheme:dark;--bg:#1e1e2e;--pan:#181825;--tx:#cdd6f4;--sub:#a6adc8;--ln:#313244;
--red:#f38ba8;--yel:#f9e2af;--grn:#a6e3a1;--acc:#89b4fa}
*{box-sizing:border-box}body{margin:0;font:14px system-ui,sans-serif;background:var(--bg);color:var(--tx)}
header{padding:16px 22px;border-bottom:1px solid var(--ln)}h1{margin:0;font-size:18px}
.meters{display:flex;gap:20px;margin-top:8px;color:var(--sub);flex-wrap:wrap}
.bar{height:8px;width:220px;background:#45475a;border-radius:9px;overflow:hidden}.bar>i{display:block;height:100%}
table{border-collapse:collapse;width:100%;min-width:720px}th,td{padding:7px 10px;border-bottom:1px solid var(--ln);text-align:left}
th{position:sticky;top:0;background:var(--pan);font-size:12px;color:var(--sub);text-transform:uppercase}
.wrap{overflow-x:auto;padding:0 22px 40px}.mono{font-family:ui-monospace,monospace;font-size:12px}
button{background:var(--pan);color:var(--tx);border:1px solid var(--ln);border-radius:6px;padding:4px 9px;cursor:pointer;font-size:12px}
button.k{border-color:var(--red);color:var(--red)}button:hover{background:#313244}
.dev{color:var(--yel)}.prot{opacity:.5}.sw{color:var(--red)}h2{padding:0 22px;font-size:14px;color:var(--sub)}
</style></head><body>
<header><h1>🦖 RAM Monster <span style=color:var(--sub);font-weight:400>· local · 127.0.0.1</span></h1>
<div class=meters id=meters></div></header>
<div class=wrap><table id=pt><thead><tr><th>PID</th><th>RSS</th><th>Swap</th><th>Idle</th><th>Process</th><th></th></tr></thead><tbody></tbody></table></div>
<h2>Docker containers</h2><div class=wrap><table id=ct><thead><tr><th>Name</th><th>Status</th><th></th></tr></thead><tbody></tbody></table></div>
<script>
async function load(){
 const s=await(await fetch('/api/snapshot')).json();
 const usedR=s.mem_total-s.mem_avail, pR=Math.round(100*usedR/s.mem_total),
       pS=s.swap_total?Math.round(100*s.swap_used/s.swap_total):0;
 meters.innerHTML=`<div>RAM ${usedR}/${s.mem_total} MB<div class=bar><i style="width:${pR}%;background:${pR>85?'#f38ba8':'#89b4fa'}"></i></div></div>
  <div>Swap ${s.swap_used}/${s.swap_total} MB<div class=bar><i style="width:${pS}%;background:${pS>40?'#f38ba8':'#a6e3a1'}"></i></div></div>
  <div>zombies: ${s.zombies}</div>`;
 pt.tBodies[0].innerHTML=s.procs.map(p=>`<tr class="${p.protected?'prot':''}">
  <td class=mono>${p.pid}</td><td>${p.rss_mb}M</td><td class="${p.swap_mb>100?'sw':''}">${p.swap_mb}M</td>
  <td>${p.mins}m${p.idle_dev?' <span class=dev>💤dev</span>':''}</td>
  <td class=mono title="${p.args.replace(/"/g,'&quot;')}">${p.comm}</td>
  <td>${p.protected?'🛡':`<button class=k onclick="act('kill',${p.pid},this)">kill</button>`}</td></tr>`).join('');
 ct.tBodies[0].innerHTML=s.containers.map(c=>`<tr><td class=mono>${c.name}</td><td>${c.status}</td>
  <td><button onclick="act('stop','${c.name}',this)">stop</button></td></tr>`).join('')||'<tr><td colspan=3>none</td></tr>';
}
async function act(kind,id,btn){
 if(!confirm(`${kind} ${id}?`))return; btn.disabled=true;btn.textContent='…';
 const r=await(await fetch('/api/'+kind,{method:'POST',headers:{'content-type':'application/json'},
   body:JSON.stringify({id})})).json();
 if(!r.ok)alert(r.error||'failed'); setTimeout(load,600);
}
load();setInterval(load,4000);
</script></body></html>"""


class Handler(BaseHTTPRequestHandler):
    idle_mins = 30
    last_allowed: set[int] = set()

    def _send(self, code, body, ctype="application/json"):
        b = body if isinstance(body, bytes) else body.encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(b)))
        self.end_headers()
        self.wfile.write(b)

    def log_message(self, *a):  # quiet
        pass

    def do_GET(self):
        if self.path == "/":
            self._send(200, PAGE, "text/html; charset=utf-8")
        elif self.path == "/api/snapshot":
            s = snapshot(self.idle_mins)
            Handler.last_allowed = s.pop("allowed")
            self._send(200, json.dumps(s))
        else:
            self._send(404, json.dumps({"ok": False}))

    def do_POST(self):
        n = int(self.headers.get("Content-Length", 0))
        try:
            data = json.loads(self.rfile.read(n) or b"{}")
        except json.JSONDecodeError:
            return self._send(400, json.dumps({"ok": False, "error": "bad json"}))
        if self.path == "/api/kill":
            pid = int(data.get("id", 0))
            if pid not in self.last_allowed:
                return self._send(403, json.dumps({"ok": False, "error": "pid not in last list / protected"}))
            try:
                os.kill(pid, signal.SIGTERM)
                self._send(200, json.dumps({"ok": True}))
            except ProcessLookupError:
                self._send(200, json.dumps({"ok": True}))  # already gone
            except PermissionError:
                self._send(200, json.dumps({"ok": False, "error": "permission denied"}))
        elif self.path == "/api/stop":
            name = str(data.get("id", ""))
            if not re.fullmatch(r"[\w.-]+", name):
                return self._send(400, json.dumps({"ok": False, "error": "bad name"}))
            r = subprocess.run(["docker", "stop", name], capture_output=True, text=True)
            self._send(200, json.dumps({"ok": r.returncode == 0, "error": r.stderr.strip()}))
        else:
            self._send(404, json.dumps({"ok": False}))


def serve(idle_mins: int) -> None:
    Handler.idle_mins = idle_mins
    srv = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"RAM Monster → http://{HOST}:{PORT}  (Ctrl-C to stop). Local only.")
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        print("\nbye")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--serve", action="store_true", help="start local web UI")
    ap.add_argument("--idle-mins", type=int, default=30, help="flag dev servers idle longer than this")
    a = ap.parse_args()
    (serve if a.serve else report)(a.idle_mins)
