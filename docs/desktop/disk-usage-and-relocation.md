---
title: Disk Usage & Relocation Status
description: What eats disk on this Rocky box, what got relocated root→home, what's left to move, and how to finish it.
status: live
tags: [desktop, disk, storage, docker, containerd, flatpak, relocation]
---

# Disk Usage & Relocation Status

**Snapshot: 2026-07-06** · Rocky Linux 10.1 · disks `rl-root` (/) and `rl-home` (/home)

## Filesystems now

| Mount | Size | Used | Free | Use% | Notes |
|-------|------|------|------|------|-------|
| `/` (rl-root) | 70G | 47G | 24G | **67%** | tight — target of relocation |
| `/home` (rl-home) | 852G | 165G | 688G | **20%** | huge headroom |

Goal: shift heavy app stores off the small 70G root onto the 852G home LV via **bind mounts** (paths stay identical, apps don't notice).

## Biggest consumers on root `/`

| Path | Size | What | Status |
|------|------|------|--------|
| `/var/lib/containerd` | **22G** | container image store (claude-code, edge-runtime images) | ❌ still on root |
| `/var/lib/docker` | **8.4G** | docker image/layer store | ❌ still on root |
| `/usr` | ~8G | system files | keep (system) |
| `/opt` | 839M | Brave Nightly, Chrome, Google browsers | optional move |
| `/var/lib/flatpak` | 0 on root | — | ✅ relocated to home |

**30.4G** (containerd + docker) is the reclaimable chunk still stuck on root — that's why root sits at 67%.

`ollama` was **removed** (`uninstall-ollama.sh`), freeing its ~1.8G of CUDA libs from `/usr/local/lib`.

## On home `/home/.system` (relocation target)

| Path | Size | Status |
|------|------|--------|
| `/home/.system/var/lib/flatpak` | 13G | ✅ **live** — bind-mounted to `/var/lib/flatpak`, working |
| `/home/.system/var/lib/docker` | 9.1G | ⚠️ **orphan** — stale partial copy from a failed Jun 30 attempt, NOT mounted, dead weight |

## What the relocation actually did

Ran via `~/coding/scripts/disk-relocate-all.sh`:

- **flatpak (13G): DONE** ✅ — moved, bind-mounted, fstab entry valid, reboot-safe.
- **docker: FAILED** ❌ — `sudo: timed out reading password` mid-rsync. Left a 9.1G partial orphan on home; live store still on root.
- **containerd (22G): never ran** ❌ — was queued after docker, never reached.
- **/opt: never reached** ❌.

**Root cause of the failure:** the script calls `sudo -v` once at the top, but the 13G flatpak rsync outlived sudo's credential cache (~5 min default). By the time docker's rsync started, sudo had expired and the non-interactive rsync died. Any re-run needs a **sudo keep-alive** or it fails the same way.

## Docker audit (2026-07-06)

`docker system df`:

| Type | Count | Size | Reclaimable | Verdict |
|------|-------|------|-------------|---------|
| Images | 27 (24 active) | 22.25G | 810M (3%) | **keep** — active dev stacks |
| **Build cache** | 157 | 10.83G | **9.33G** | **prune — pure junk** |
| Containers | 26 (23 active) | 33M | 0.2M | keep |
| Volumes | 8 (active) | 469M | 0 | **keep — data** |

**Images are live projects, not junk:** Supabase stack (edge-runtime, gotrue, imgproxy, kong, logflare), Firefly III, loan-division-tracker, job/program-manager, postgres, mariadb, nginx. Only ~810M of dangling images is safely removable — do **not** mass-`prune -a`.

**containerd is docker's image store.** `systemctl show containerd` → `WantedBy=docker.service`. This docker uses the containerd snapshotter, so `/var/lib/containerd` (22G) holds the image layers and `/var/lib/docker` (8.4G) holds containers/build-cache/metadata. One system (~30G), not two. No k8s / nerdctl / crictl consuming it.

### Suggestions (audit takeaways)

1. **Biggest safe win — prune build cache: `docker builder prune -f` frees ~9.3G.** Rebuilds regenerate it. Do this regularly.
2. **Relocate the rest to home** (script below). After prune, only ~20G moves.
3. **Delete the 9.1G orphan** `/home/.system/var/lib/docker` (stale Jun-30 partial, unmounted, dead weight).
4. **Don't** run `docker system prune -a` or `docker volume prune` — that would nuke your active dev images and database volumes.
5. **Recurring hygiene:** a monthly `docker builder prune -f` keeps build cache from creeping back to 10G.

## To finish (recommended)

Two viable paths — pick based on whether you still use those containers:

**Option A — relocate the 30G (keep the images):**
1. Remove the stale orphan first: `sudo rm -rf /home/.system/var/lib/docker` (it's a dead partial, not the live store).
2. Re-run relocation with a sudo keep-alive so it survives the long rsync (see fixed script below).
3. Result: root drops ~30G → ~17G used (~24%).

**Option B — prune instead of move (if the images are stale CI/build junk):**
- `docker system prune -a` and `sudo crictl rmi --prune` (containerd) may reclaim most of the 30G without moving anything. containerd's 22G looks like leftover claude-code / edge-runtime build images.
- Faster, simpler, but destroys the images.

## Fix for the relocation script

Add a sudo keep-alive loop after `sudo -v` so credentials never expire mid-rsync:

```sh
sudo -v
# keep sudo alive in background until script exits
( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) &
```

Without this, any dir larger than what rsyncs inside the ~5 min sudo window will fail exactly like docker did.

## Undo (reference)

Each relocated dir is a bind mount defined in `/etc/fstab`. To undo one:
```sh
sudo umount /var/lib/<dir>
sudo sed -i '\#/home/.system/var/lib/<dir>#d' /etc/fstab
# data still lives at /home/.system/var/lib/<dir>
```
