<#
pipeline-windows-ml.ps1 - one command that turns a bare Windows box into a
working ML/DevOps workstation, and records what it did.

This is the orchestrator above the individual installers. Each stage is
idempotent, timed, and written to a machine-readable state file that the
dashboard (tools/mlops_dashboard.py) renders. Re-running is safe: completed
stages are skipped unless -Force.

  !! THIS PIPELINE NEVER INSTALLS, UPDATES, OR MODIFIES GPU DRIVERS. !!
  The preflight stage only *reads* nvidia-smi. Driver management stays manual.

Stages (in order):
  preflight  probe machine, GPU, disk - changes nothing
  base       setup.ps1          -> winget core + scoop CLI toolset
  apps       install-windows-apps.ps1 -> the restored application set
  ml         install-ml-windows.ps1   -> Python + uv + CUDA-matched PyTorch
  wsl        install-wsl-ubuntu.ps1   -> WSL2 + Ubuntu (needs admin; opt-in)
  verify     tool inventory + live torch/CUDA probe

Usage:
  powershell -ExecutionPolicy Bypass -File .\pipeline-windows-ml.ps1 -DryRun
  powershell -ExecutionPolicy Bypass -File .\pipeline-windows-ml.ps1
  powershell -ExecutionPolicy Bypass -File .\pipeline-windows-ml.ps1 -Stages preflight,ml,verify
  powershell -ExecutionPolicy Bypass -File .\pipeline-windows-ml.ps1 -From ml
  powershell -ExecutionPolicy Bypass -File .\pipeline-windows-ml.ps1 -IncludeWsl
  powershell -ExecutionPolicy Bypass -File .\pipeline-windows-ml.ps1 -Stages verify   # refresh dashboard data

State file: setup/state/pipeline-state.json
#>

param(
  [switch]$DryRun,
  [switch]$Force,
  [switch]$Reset,
  [switch]$IncludeWsl,
  [string[]]$Stages,
  [string]$From,
  [string]$VenvPath = "$env:USERPROFILE\.venvs\ml",
  [string[]]$AppGroups = @("Desktop","Dev","Docs","AI")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"
$global:LASTEXITCODE = 0
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $Here
$StateDir = Join-Path $Here "state"
$StateFile = Join-Path $StateDir "pipeline-state.json"

function Banner($msg) { Write-Host "`n########  $msg  ########" -ForegroundColor Cyan }
function Step($msg)   { Write-Host "`n== $msg ==" -ForegroundColor Magenta }
function Note($msg)   { Write-Host "   $msg" -ForegroundColor DarkGray }
function Warn($msg)   { Write-Host "   ! $msg" -ForegroundColor Yellow }
function Good($msg)   { Write-Host "   + $msg" -ForegroundColor Green }
function Have($cmd)   { return [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }
function Now()        { return (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss") }

# All stages in canonical order. 'wsl' only runs when asked for.
$AllStages = @("preflight","base","apps","ml","wsl","verify")

# powershell.exe -File passes "-Stages a,b" as ONE string, not an array (unlike
# a normal in-session call). Re-split so both invocation styles behave the same.
function Split-Arg($v) {
  if (-not $v) { return @() }
  return @($v | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}
$Stages = Split-Arg $Stages
$AppGroups = Split-Arg $AppGroups

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
function Load-State {
  if (Test-Path -LiteralPath $StateFile) {
    try { return (Get-Content -LiteralPath $StateFile -Raw | ConvertFrom-Json) } catch { }
  }
  return $null
}

function New-State {
  $stages = @()
  foreach ($s in $AllStages) {
    $stages += [ordered]@{ id = $s; status = "pending"; startedAt = $null; finishedAt = $null; durationSec = 0; detail = "" }
  }
  return [ordered]@{
    schema      = 1
    updated     = (Now)
    pipeline    = "windows-ml"
    repo        = $RepoRoot
    driverPolicy= "read-only: this pipeline never installs or modifies GPU drivers"
    machine     = [ordered]@{}
    gpu         = [ordered]@{}
    disks       = @()
    stages      = $stages
    tools       = @()
    ml          = [ordered]@{}
  }
}

# ConvertFrom-Json gives PSCustomObjects; normalise back to hashtables so we can
# mutate freely and re-serialise without surprises.
function To-Hash($obj) {
  if ($null -eq $obj) { return $null }
  if ($obj -is [System.Collections.IDictionary]) { return $obj }
  if ($obj -is [System.Management.Automation.PSCustomObject]) {
    $h = [ordered]@{}
    foreach ($p in $obj.PSObject.Properties) { $h[$p.Name] = To-Hash $p.Value }
    return $h
  }
  if ($obj -is [object[]]) { return @($obj | ForEach-Object { To-Hash $_ }) }
  return $obj
}

function Save-State($state) {
  if ($DryRun) { Note "[DryRun] would write $StateFile"; return }
  if (-not (Test-Path -LiteralPath $StateDir)) { New-Item -ItemType Directory -Force -Path $StateDir | Out-Null }
  $state.updated = (Now)
  $state | ConvertTo-Json -Depth 8 | Out-File -Encoding utf8 -LiteralPath $StateFile
}

function Get-Stage($state, $id) {
  foreach ($s in $state.stages) { if ($s.id -eq $id) { return $s } }
  return $null
}

# ---------------------------------------------------------------------------
# Stage runner
# ---------------------------------------------------------------------------
function Invoke-Stage($state, $id, [scriptblock]$body) {
  $stage = Get-Stage $state $id
  if ($null -eq $stage) { return }

  if ($stage.status -eq "ok" -and -not $Force) {
    Note "stage '$id' already ok - skipping (use -Force to re-run)"
    return
  }

  Banner "STAGE: $id"
  $stage.status = "running"
  $stage.startedAt = (Now)
  Save-State $state

  $t0 = Get-Date
  try {
    $detail = & $body
    $stage.status = "ok"
    $stage.detail = [string]$detail
    Good "stage '$id' ok"
  } catch {
    $stage.status = "failed"
    $stage.detail = $_.Exception.Message
    Warn "stage '$id' FAILED: $($_.Exception.Message)"
  }
  $stage.finishedAt = (Now)
  $stage.durationSec = [math]::Round(((Get-Date) - $t0).TotalSeconds, 1)
  Save-State $state
}

function Run-Script($name, $argList) {
  $path = Join-Path $Here $name
  if (-not (Test-Path -LiteralPath $path)) { throw "missing script: $name" }
  if ($DryRun) { Note "[DryRun] & $name $($argList -join ' ')"; return "dry-run" }
  # Out-Host, not bare invocation: otherwise the child's entire stdout becomes
  # this scriptblock's return value and lands in the stage's `detail` field as
  # one unbroken multi-kilobyte line. Send it to the console (and so the log)
  # and return a short summary instead.
  & powershell -ExecutionPolicy Bypass -File $path @argList | Out-Host
  if ($LASTEXITCODE -ne 0) { throw "$name exited with $LASTEXITCODE" }
  return "ran $name"
}

# ---------------------------------------------------------------------------
# Probes (all read-only)
# ---------------------------------------------------------------------------
function Probe-Machine($state) {
  $os = Get-CimInstance Win32_OperatingSystem
  $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
  $state.machine = [ordered]@{
    os        = $os.Caption
    version   = $os.Version
    hostname  = $env:COMPUTERNAME
    cpu       = ($cpu.Name).Trim()
    cores     = $cpu.NumberOfCores
    threads   = $cpu.NumberOfLogicalProcessors
    ramGB     = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
    ramFreeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
  }

  $disks = @()
  foreach ($d in (Get-PSDrive -PSProvider FileSystem)) {
    if ($null -ne $d.Used -and ($d.Used + $d.Free) -gt 0) {
      $disks += [ordered]@{
        name    = $d.Name
        usedGB  = [math]::Round($d.Used / 1GB, 0)
        freeGB  = [math]::Round($d.Free / 1GB, 0)
        totalGB = [math]::Round(($d.Used + $d.Free) / 1GB, 0)
      }
    }
  }
  $state.disks = $disks
}

function Probe-Gpu($state) {
  # READ ONLY. Nothing here alters the driver in any way.
  if (-not (Have nvidia-smi)) {
    $state.gpu = [ordered]@{ present = $false; note = "nvidia-smi not found" }
    return
  }
  $q = & nvidia-smi --query-gpu=name,driver_version,memory.total,memory.used,compute_cap,temperature.gpu,utilization.gpu `
        --format=csv,noheader,nounits 2>$null | Select-Object -First 1
  if (-not $q) {
    $state.gpu = [ordered]@{ present = $false; note = "nvidia-smi returned nothing" }
    return
  }
  $p = $q -split "\s*,\s*"
  $cc = [double]$p[4]
  $channel = "cpu"
  if     ($cc -ge 12.0) { $channel = "cu128" }
  elseif ($cc -ge 8.9)  { $channel = "cu128" }
  elseif ($cc -ge 7.0)  { $channel = "cu126" }
  $state.gpu = [ordered]@{
    present       = $true
    name          = $p[0]
    driver        = $p[1]
    vramTotalMB   = [int]$p[2]
    vramUsedMB    = [int]$p[3]
    computeCap    = $cc
    tempC         = [int]$p[5]
    utilPct       = [int]$p[6]
    torchChannel  = $channel
    architecture  = $(if ($cc -ge 12.0) { "Blackwell (sm_120)" } elseif ($cc -ge 8.9) { "Ada/Hopper" } elseif ($cc -ge 8.0) { "Ampere" } else { "older" })
  }
}

function Probe-Tools($state) {
  # This process may have started before the installers ran, so its PATH copy is
  # stale. Re-read the authoritative value from the registry first, otherwise
  # every freshly-installed tool reports as missing.
  $env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
              [Environment]::GetEnvironmentVariable("Path","User")
  $want = @(
    @{ n = "winget";   c = "core" }, @{ n = "scoop";    c = "core" },
    @{ n = "git";      c = "core" }, @{ n = "gh";       c = "core" },
    @{ n = "python";   c = "python" }, @{ n = "uv";     c = "python" },
    @{ n = "conda";    c = "python" },
    @{ n = "node";     c = "runtime" }, @{ n = "mise";  c = "runtime" },
    @{ n = "go";       c = "runtime" },
    @{ n = "rg";       c = "cli" }, @{ n = "fd";        c = "cli" },
    @{ n = "bat";      c = "cli" }, @{ n = "eza";       c = "cli" },
    @{ n = "fzf";      c = "cli" }, @{ n = "zoxide";    c = "cli" },
    @{ n = "delta";    c = "cli" }, @{ n = "jq";        c = "cli" },
    @{ n = "starship"; c = "shell" }, @{ n = "zellij";  c = "shell" },
    @{ n = "chezmoi";  c = "shell" }, @{ n = "wezterm"; c = "shell" },
    @{ n = "nvim";     c = "editor" }, @{ n = "code";   c = "editor" },
    @{ n = "lazygit";  c = "editor" },
    @{ n = "docker";   c = "devops" }, @{ n = "minikube"; c = "devops" },
    @{ n = "psql";     c = "devops" }, @{ n = "wsl";    c = "devops" },
    @{ n = "claude";   c = "ai" },
    # Docs group. Their installers do not touch PATH, so they were installed and
    # invisible until update-user-path.ps1 learned to find them.
    @{ n = "pandoc";   c = "docs" }, @{ n = "tesseract"; c = "docs" },
    @{ n = "wget2";    c = "docs" }
  )
  $tools = @()
  foreach ($t in $want) {
    # -CommandType Application, not a bare Get-Command: a shell profile can
    # shadow a tool's name with a function (`mise activate` defines one), and a
    # function has no .Source, so an installed tool reported as missing the
    # moment a profile existed. Ask for the executable specifically.
    $cmd = Get-Command $t.n -CommandType Application -ErrorAction SilentlyContinue |
           Select-Object -First 1
    if (-not $cmd) { $cmd = Get-Command $t.n -ErrorAction SilentlyContinue | Select-Object -First 1 }
    $present = $false; $path = ""
    if ($cmd -and $cmd.Source) {
      # Only python gets the zero-byte test - that Store alias is a dead stub.
      # winget's launcher is also zero bytes but is a real, working tool, so
      # applying this test to everything reports installed tools as missing.
      $len = 1
      if ($t.n -in @("python","python3")) {
        try { $len = (Get-Item -LiteralPath $cmd.Source).Length } catch { }
      }
      if ($len -gt 0) { $present = $true; $path = $cmd.Source }
    }
    # mise-managed runtimes live behind mise shims, not on the raw PATH.
    if (-not $present -and (Get-Command mise -ErrorAction SilentlyContinue)) {
      $shim = (& mise which $t.n 2>$null | Select-Object -First 1)
      if ($shim -and (Test-Path -LiteralPath $shim)) { $present = $true; $path = "$shim  (mise)" }
    }
    $tools += [ordered]@{ name = $t.n; category = $t.c; present = $present; path = $path }
  }
  $state.tools = $tools
}

function Probe-Ml($state) {
  $py = Join-Path $VenvPath "Scripts\python.exe"
  if (-not (Test-Path -LiteralPath $py)) {
    $state.ml = [ordered]@{ venvPresent = $false; venvPath = $VenvPath }
    return
  }
  $probe = @'
import json, sys
out = {"venvPresent": True, "python": sys.version.split()[0]}
try:
    import torch
    out["torch"] = torch.__version__
    out["cudaBuild"] = torch.version.cuda
    out["cudaAvailable"] = bool(torch.cuda.is_available())
    if out["cudaAvailable"]:
        out["device"] = torch.cuda.get_device_name(0)
        out["capability"] = ".".join(str(x) for x in torch.cuda.get_device_capability(0))
        try:
            x = torch.randn(1024, 1024, device="cuda"); (x @ x).sum().item()
            torch.cuda.synchronize()
            out["matmulOk"] = True
        except Exception as e:
            out["matmulOk"] = False
            out["matmulError"] = str(e)[:200]
except ImportError:
    out["torch"] = None
pkgs = {}
for m in ("transformers","jupyterlab","mlflow","sklearn","pandas","polars","xgboost","langchain"):
    try:
        __import__(m); pkgs[m] = True
    except Exception:
        pkgs[m] = False
out["packages"] = pkgs
print(json.dumps(out))
'@
  $tmp = Join-Path $env:TEMP "pipeline_ml_probe.py"
  $probe | Out-File -Encoding utf8 -LiteralPath $tmp
  $raw = & $py $tmp 2>$null
  Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue
  if ($raw) {
    try {
      $obj = $raw | ConvertFrom-Json
      $h = To-Hash $obj
      $h["venvPath"] = $VenvPath
      $state.ml = $h
      return
    } catch { }
  }
  $state.ml = [ordered]@{ venvPresent = $true; venvPath = $VenvPath; error = "probe failed" }
}

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
Write-Host "=== Windows -> ML/DevOps pipeline ===" -ForegroundColor Cyan
Note "repo:  $RepoRoot"
Note "state: $StateFile"
Note "GPU drivers are never touched by this pipeline."

$state = To-Hash (Load-State)
# -Force means "re-run the selected stages even if already ok" - NOT "erase
# history". Wiping state here made `-Stages verify -Force` reset every other
# stage to pending, misreporting a fully-provisioned machine as untouched.
# Use -Reset for a genuine clean slate.
if ($null -eq $state -or $Reset) { $state = New-State } else {
  # Keep the stage list in sync if new stages were added since the last run.
  $known = @($state.stages | ForEach-Object { $_.id })
  foreach ($s in $AllStages) {
    if ($known -notcontains $s) {
      $state.stages += [ordered]@{ id = $s; status = "pending"; startedAt = $null; finishedAt = $null; durationSec = 0; detail = "" }
    }
  }
}

# Work out which stages to run.
$selected = $AllStages
if ($Stages) { $selected = $Stages }
elseif ($From) {
  $i = [array]::IndexOf($AllStages, $From)
  if ($i -lt 0) { Warn "unknown -From '$From'; running all"; } else { $selected = $AllStages[$i..($AllStages.Count - 1)] }
}
if (-not $IncludeWsl -and -not ($Stages -and $Stages -contains "wsl")) {
  $selected = $selected | Where-Object { $_ -ne "wsl" }
}
Note "stages: $($selected -join ' -> ')"

foreach ($id in $selected) {
  switch ($id) {

    "preflight" {
      Invoke-Stage $state $id {
        Probe-Machine $state
        Probe-Gpu $state
        Note "$($state.machine.cpu)"
        Note "RAM $($state.machine.ramGB) GB"
        if ($state.gpu.present) {
          Note "GPU $($state.gpu.name) - $($state.gpu.architecture) - cc $($state.gpu.computeCap) -> $($state.gpu.torchChannel)"
        } else { Warn "no NVIDIA GPU detected" }
        return "probed machine + gpu (read-only)"
      }
    }

    "base"  { Invoke-Stage $state $id { return (Run-Script "setup.ps1" @()) } }

    "apps"  { Invoke-Stage $state $id { return (Run-Script "install-windows-apps.ps1" @("-Groups", ($AppGroups -join ","))) } }

    "ml"    { Invoke-Stage $state $id { return (Run-Script "install-ml-windows.ps1" @("-VenvPath", $VenvPath)) } }

    "wsl"   { Invoke-Stage $state $id { return (Run-Script "install-wsl-ubuntu.ps1" @()) } }

    "verify" {
      Invoke-Stage $state $id {
        Probe-Machine $state
        Probe-Gpu $state
        Probe-Tools $state
        Probe-Ml $state
        $have = @($state.tools | Where-Object { $_.present }).Count
        $all  = @($state.tools).Count
        Note "tools present: $have / $all"
        if ($state.ml.Contains("cudaAvailable") -and $state.ml["cudaAvailable"]) {
          Good "torch $($state.ml['torch']) - CUDA available on $($state.ml['device'])"
        } elseif ($state.ml.Contains("venvPresent") -and $state.ml["venvPresent"]) {
          Warn "ML venv present but CUDA not available"
        } else {
          Warn "ML venv not found at $VenvPath"
        }
        return "$have/$all tools present"
      }
    }
  }
}

Save-State $state

Write-Host "`n=== Pipeline summary ===" -ForegroundColor Cyan
foreach ($s in $state.stages) {
  $mark = switch ($s.status) { "ok" { "  OK  " } "failed" { " FAIL " } "running" { " RUN  " } default { " ---- " } }
  $colour = switch ($s.status) { "ok" { "Green" } "failed" { "Red" } default { "DarkGray" } }
  Write-Host ("[{0}] {1,-10} {2,6}s  {3}" -f $mark, $s.id, $s.durationSec, $s.detail) -ForegroundColor $colour
}

Write-Host "`nState written to: $StateFile" -ForegroundColor DarkGray
Write-Host "See it visually:  python tools/mlops_dashboard.py" -ForegroundColor Cyan
Write-Host "No GPU driver was installed or modified.`n" -ForegroundColor DarkGray
