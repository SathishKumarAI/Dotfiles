#!/usr/bin/env bash
# bootstrap-wsl.sh — run INSIDE the WSL2 Ubuntu distro, once.
#
#   !! THIS SCRIPT NEVER INSTALLS OR MODIFIES GPU DRIVERS. !!
#   Under WSL2 the Windows driver is projected into the distro at
#   /usr/lib/wsl/lib. Installing a Linux NVIDIA driver here would overwrite
#   those stubs and break CUDA. This script only *verifies* passthrough.
#
# Sets up: base packages, uv, and a GPU check. Then hands off to the repo's
# normal Linux installers, which work unchanged in WSL.
#
# Usage:  bash setup/wsl/bootstrap-wsl.sh

set -euo pipefail

step() { printf '\n== %s ==\n' "$1"; }
note() { printf '   %s\n' "$1"; }
warn() { printf '   ! %s\n' "$1" >&2; }

step "Sanity check"
if ! grep -qi microsoft /proc/version 2>/dev/null; then
  warn "This does not look like WSL. Run setup/setup.sh instead."
  exit 1
fi
note "WSL detected: $(grep -o 'WSL[0-9]*' /proc/version 2>/dev/null || echo WSL2)"

step "Base packages"
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
  build-essential curl wget git ca-certificates \
  pkg-config libssl-dev unzip

step "uv (Astral) — Python + package management"
if command -v uv >/dev/null 2>&1; then
  note "uv already installed: $(uv --version)"
else
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi

step "GPU passthrough check (read-only)"
if [ -e /dev/dxg ]; then
  note "/dev/dxg present — GPU is projected into this distro"
else
  warn "/dev/dxg missing — GPU passthrough is not active"
fi
if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader || true
  note "CUDA is available via the Windows driver. Do NOT apt-install nvidia-driver-*."
else
  warn "nvidia-smi not found in WSL."
  warn "Fix on the WINDOWS side (update the driver there), never inside this distro."
fi

step "Next steps"
cat <<'EOF'
   Python + ML env (mirrors setup/install-ml-windows.ps1):
     uv venv ~/.venvs/ml --python 3.12
     uv pip install --python ~/.venvs/ml/bin/python \
       torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
     uv pip install --python ~/.venvs/ml/bin/python -r setup/ml/requirements-ml.txt

   Verify torch sees the GPU:
     ~/.venvs/ml/bin/python -c "import torch;print(torch.cuda.is_available(), torch.cuda.get_device_capability())"

   Full Linux dev environment (works unchanged in WSL):
     bash setup/setup.sh --dry-run
     bash setup/setup.sh

   If you need the CUDA toolkit (nvcc) in here, install the 'wsl-ubuntu'
   repo variant only — it ships the toolkit WITHOUT a driver.
EOF

printf '\n== Done ==\n'
