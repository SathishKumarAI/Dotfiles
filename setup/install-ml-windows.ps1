<#
install-ml-windows.ps1 - Python + GPU-aware machine-learning stack for Windows 10/11.

The ML counterpart to setup-windows.ps1. That script builds the *dev environment*
(editors, shell, CLI tools, Miniforge). This one builds the *ML environment*:
a real Python, uv, an isolated venv, and a PyTorch build that actually matches
this machine's GPU.

  !! THIS SCRIPT NEVER INSTALLS, UPDATES, OR MODIFIES GPU DRIVERS. !!
  It only *reads* nvidia-smi to report what is already present and to pick the
  right PyTorch wheel. Driver management stays entirely in your hands.

Strategy:
  * winget -> real CPython + uv (Astral)
  * uv     -> venv + PyTorch from the official CUDA index + the ML library set
  * verify -> imports torch, prints device + compute capability, fails loudly

Why uv and not conda: 10-100x faster resolution, handles PyTorch's separate
package index cleanly, and it is already what the Linux side of this repo uses
(install-workflow-tools.sh). Miniforge remains installed by setup-windows.ps1
for the rare package that is conda-only - see dotfiles/windows_setup/conda/setup.md.

Usage:
  powershell -ExecutionPolicy Bypass -File .\install-ml-windows.ps1 -DryRun
  powershell -ExecutionPolicy Bypass -File .\install-ml-windows.ps1
  powershell -ExecutionPolicy Bypass -File .\install-ml-windows.ps1 -CudaChannel cpu
  powershell -ExecutionPolicy Bypass -File .\install-ml-windows.ps1 -VenvPath D:\envs\ml
#>

param(
  [switch]$DryRun,
  [switch]$SkipTorch,
  # PyTorch wheel channel. cu128 = CUDA 12.8, the first channel with Blackwell
  # (sm_120) kernels - required for RTX 50-series. Auto-detected below unless set.
  [string]$CudaChannel = "",
  [string]$VenvPath = "$env:USERPROFILE\.venvs\ml",
  [string]$PythonVersion = "3.12"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"
$global:LASTEXITCODE = 0
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path

function Step($msg) { Write-Host "`n== $msg ==" -ForegroundColor Magenta }
function Note($msg) { Write-Host "   $msg" -ForegroundColor DarkGray }
function Warn($msg) { Write-Host "   ! $msg" -ForegroundColor Yellow }
function Have($cmd) { return [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

function Winget-Install([string]$id) {
  if ($DryRun) { Write-Host "[DryRun] winget install $id"; return }
  if (-not (Have winget)) { Warn "winget missing - skip $id"; return }
  Write-Host "+ winget install $id"
  winget install --id $id -e --accept-source-agreements --accept-package-agreements `
    --silent --disable-interactivity 2>$null
  if ($LASTEXITCODE -ne 0) { Note "(winget $id failed or already installed - continuing)" }
}

Write-Host "=== Windows ML setup ===" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# 0. GPU - READ ONLY. No driver is installed, updated, or altered here.
# ---------------------------------------------------------------------------
Step "GPU detection (read-only - no driver changes)"
$detectedChannel = "cpu"
if (Have nvidia-smi) {
  $smi = & nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader 2>$null
  if ($smi) {
    foreach ($line in $smi) { Note "GPU: $line" }
    # Compute capability tells us which wheel channel has kernels for this card.
    $cc = & nvidia-smi --query-gpu=compute_cap --format=csv,noheader 2>$null | Select-Object -First 1
    if ($cc) {
      $ccNum = [double]($cc.Trim())
      Note "Compute capability: $ccNum"
      if     ($ccNum -ge 12.0) { $detectedChannel = "cu128"; Note "Blackwell (sm_120+) -> needs CUDA 12.8+ wheels" }
      elseif ($ccNum -ge 8.9)  { $detectedChannel = "cu128"; Note "Ada/Hopper -> CUDA 12.8 wheels" }
      elseif ($ccNum -ge 7.0)  { $detectedChannel = "cu126"; Note "Volta/Turing/Ampere -> CUDA 12.6 wheels" }
      else                     { $detectedChannel = "cpu";   Warn "GPU too old for current PyTorch CUDA builds - using CPU wheels" }
    } else {
      $detectedChannel = "cu128"
      Warn "compute_cap unavailable from this driver - defaulting to cu128"
    }
  }
} else {
  Warn "nvidia-smi not found - no NVIDIA GPU detected, using CPU wheels"
}

if ([string]::IsNullOrWhiteSpace($CudaChannel)) { $CudaChannel = $detectedChannel }
Note "PyTorch channel: $CudaChannel  (override with -CudaChannel)"

# ---------------------------------------------------------------------------
# 1. Python - and the Microsoft Store stub trap
# ---------------------------------------------------------------------------
Step "Python $PythonVersion"

# Windows ships 0-byte "App Execution Alias" stubs at
# %LOCALAPPDATA%\Microsoft\WindowsApps\python.exe that only open the Store.
# If that folder precedes the real install on PATH, every python call is a no-op.
$stub = Join-Path $env:LOCALAPPDATA "Microsoft\WindowsApps\python.exe"
if ((Test-Path -LiteralPath $stub) -and ((Get-Item -LiteralPath $stub).Length -eq 0)) {
  Warn "Microsoft Store python stub detected at:"
  Warn "  $stub"
  Warn "It is a 0-byte alias and will shadow real Python. Turn it off in:"
  Warn "  Settings > Apps > Advanced app settings > App execution aliases"
  Warn "  -> switch OFF 'python.exe' and 'python3.exe'"
  Warn "This script cannot flip that toggle for you - it is a per-user Windows setting."
}

$realPython = $null
foreach ($cand in (Get-Command python.exe -All -ErrorAction SilentlyContinue)) {
  if ((Get-Item -LiteralPath $cand.Source).Length -gt 0) { $realPython = $cand.Source; break }
}
if ($realPython) {
  Note "Found real Python: $realPython"
} else {
  Note "No real Python on PATH - installing CPython $PythonVersion"
  Winget-Install "Python.Python.$PythonVersion"
}

# ---------------------------------------------------------------------------
# 2. uv - the environment + package manager
# ---------------------------------------------------------------------------
Step "uv (Astral)"
if (Have uv) { Note "uv already installed" } else { Winget-Install "astral-sh.uv" }

# winget just changed PATH in the registry; this process still has the old copy.
$env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
            [Environment]::GetEnvironmentVariable("Path","User")

if (-not (Have uv) -and -not $DryRun) {
  Warn "uv still not on PATH. Close this terminal, reopen it, and re-run."
  Warn "Stopping here so nothing half-installs."
  exit 1
}

# ---------------------------------------------------------------------------
# 3. venv
# ---------------------------------------------------------------------------
Step "Virtual environment -> $VenvPath"
if ($DryRun) {
  Write-Host "[DryRun] uv venv $VenvPath --python $PythonVersion"
} else {
  $parent = Split-Path -Parent $VenvPath
  if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
  # Reuse an existing venv rather than failing or clearing it. `uv venv` errors
  # out when the target exists, and --clear would delete a multi-GB torch
  # install on every re-run. The pip installs below are idempotent anyway.
  if (Test-Path -LiteralPath (Join-Path $VenvPath "Scripts\python.exe")) {
    Note "venv already exists - reusing it (packages below are re-checked)"
  } else {
    uv venv $VenvPath --python $PythonVersion
    if ($LASTEXITCODE -ne 0) { Warn "uv venv failed - stopping"; exit 1 }
  }
}
$venvPython = Join-Path $VenvPath "Scripts\python.exe"

# ---------------------------------------------------------------------------
# 4. PyTorch - from the official index, matched to the GPU
# ---------------------------------------------------------------------------
Step "PyTorch ($CudaChannel)"
if ($SkipTorch) {
  Note "-SkipTorch set - skipping"
} else {
  $torchIndex = "https://download.pytorch.org/whl/$CudaChannel"
  # A plain `pip install torch` can resolve to a wheel without kernels for this
  # card, which fails at runtime with "no kernel image is available for
  # execution on the device". Always pin the index explicitly.
  if ($DryRun) {
    Write-Host "[DryRun] uv pip install --python $venvPython torch torchvision torchaudio --index-url $torchIndex"
  } else {
    uv pip install --python $venvPython torch torchvision torchaudio --index-url $torchIndex
    if ($LASTEXITCODE -ne 0) { Warn "torch install failed - check that channel '$CudaChannel' exists at download.pytorch.org/whl/" }
  }
}

# ---------------------------------------------------------------------------
# 5. The rest of the ML stack
# ---------------------------------------------------------------------------
Step "ML libraries"
$reqs = Join-Path $Here "ml\requirements-ml.txt"
if (-not (Test-Path -LiteralPath $reqs)) {
  Warn "missing: $reqs - skipping library install"
} elseif ($DryRun) {
  Write-Host "[DryRun] uv pip install --python $venvPython -r $reqs"
} else {
  uv pip install --python $venvPython -r $reqs
  if ($LASTEXITCODE -ne 0) { Warn "some libraries failed - re-run to retry" }
}

# ---------------------------------------------------------------------------
# 6. Verify - never assume the GPU works, prove it
# ---------------------------------------------------------------------------
Step "Verification"
if ($DryRun) {
  Write-Host "[DryRun] would import torch and print device info"
} elseif (Test-Path -LiteralPath $venvPython) {
  $probe = @'
import sys
print("python     :", sys.version.split()[0])
try:
    import torch
except ImportError:
    print("torch      : NOT INSTALLED")
    raise SystemExit(0)
print("torch      :", torch.__version__)
print("cuda build :", torch.version.cuda)
avail = torch.cuda.is_available()
print("cuda avail :", avail)
if avail:
    print("device     :", torch.cuda.get_device_name(0))
    print("capability :", torch.cuda.get_device_capability(0))
    # Prove kernels actually run - is_available() alone is not enough.
    try:
        x = torch.randn(2048, 2048, device="cuda")
        torch.cuda.synchronize()
        print("matmul     : OK", float((x @ x).sum()) == float((x @ x).sum()))
    except Exception as e:
        print("matmul     : FAILED ->", e)
        print(">> Wheel has no kernels for this GPU. Re-run with a newer -CudaChannel.")
else:
    print(">> CUDA not available: torch will run on CPU only.")
'@
  $tmp = Join-Path $env:TEMP "ml_verify.py"
  $probe | Out-File -Encoding utf8 $tmp
  & $venvPython $tmp
  Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue
}

Write-Host "`n== Done ==" -ForegroundColor Green
@"
Activate the environment:
  $VenvPath\Scripts\Activate.ps1

Register it as a Jupyter kernel:
  $venvPython -m ipykernel install --user --name ml --display-name "Python (ml)"

Per-project envs (preferred over one shared env):
  uv init myproject; cd myproject; uv add torch --index-url https://download.pytorch.org/whl/$CudaChannel

Reminder: no GPU driver was installed or modified by this script.
"@ | Write-Host
