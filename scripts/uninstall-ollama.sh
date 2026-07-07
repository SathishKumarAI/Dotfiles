#!/usr/bin/env bash
# Fully remove Ollama (installed via official script into /usr/local). Frees ~1.8G+.
# Run:  bash ~/coding/scripts/uninstall-ollama.sh
set -euo pipefail

LOGFILE="/home/deva/coding/scripts/uninstall-ollama.log"
: > "$LOGFILE"
exec > >(tee -a "$LOGFILE") 2>&1
log(){ printf '\n\033[1;36m== %s ==\033[0m\n' "$*"; }

sudo -v

log "What exists now"
which ollama 2>/dev/null || echo "no ollama binary in PATH"
ollama list 2>/dev/null || echo "(daemon not answering)"
for p in /usr/local/bin/ollama /usr/local/lib/ollama /usr/share/ollama \
         /etc/systemd/system/ollama.service ~/.ollama; do
  [ -e "$p" ] && du -sh "$p" 2>/dev/null || true
done

read -rp "Delete Ollama permanently (binary, libs, models, service, user)? type DELETE: " a
[ "$a" = DELETE ] || { echo "Aborted."; exit 1; }

log "Stop + disable service"
sudo systemctl stop ollama 2>/dev/null || true
sudo systemctl disable ollama 2>/dev/null || true
sudo rm -f /etc/systemd/system/ollama.service /etc/systemd/system/multi-user.target.wants/ollama.service
sudo systemctl daemon-reload || true

log "Remove binary + libs + models"
sudo rm -f /usr/local/bin/ollama
sudo rm -rf /usr/local/lib/ollama
sudo rm -rf /usr/share/ollama        # system models (was empty)
rm -rf ~/.ollama                     # any user models/config

log "Remove ollama user + group"
sudo userdel ollama 2>/dev/null || echo "(no ollama user)"
sudo groupdel ollama 2>/dev/null || echo "(no ollama group)"

log "Verify gone"
which ollama 2>/dev/null && echo "WARN still present" || echo "ollama binary gone"
log "df /"
df -hT /
echo "DONE. Ollama removed."
