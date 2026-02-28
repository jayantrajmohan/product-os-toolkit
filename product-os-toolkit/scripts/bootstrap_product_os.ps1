param(
  [string]$TargetRoot = (Get-Location).Path,
  [string]$WorkspaceRoot = "product-intel",
  [string]$EnginePath = "",
  [ValidateSet("codex","claude","generic")]
  [string]$Provider = "generic",
  [string]$Version = "2.0.0"
)

$ErrorActionPreference = "Stop"

function Ensure-Dir {
  param([string]$Path)
  if (-not (Test-Path $Path)) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
  }
}

$cfgDir = Join-Path $TargetRoot ".product-os"
$scriptsDir = Join-Path $TargetRoot "scripts"
$skillsDir = Join-Path $cfgDir "skills"
$mcpDir = Join-Path $cfgDir "mcp"
$providersDir = Join-Path $cfgDir "providers"
$cfgPath = Join-Path $cfgDir "config.json"
$psPath = Join-Path $scriptsDir "product_os.ps1"
$cmdPath = Join-Path $scriptsDir "product_os.cmd"
$shPath = Join-Path $scriptsDir "product_os.sh"
$skillPath = Join-Path $skillsDir "product-os-skill.md"
$mcpPath = Join-Path $mcpDir "mcp-config.template.json"

$workspacePath = Join-Path $TargetRoot $WorkspaceRoot
Ensure-Dir -Path $cfgDir
Ensure-Dir -Path $scriptsDir
Ensure-Dir -Path $skillsDir
Ensure-Dir -Path $mcpDir
Ensure-Dir -Path $providersDir
Ensure-Dir -Path $workspacePath
Ensure-Dir -Path (Join-Path $workspacePath "raw")
Ensure-Dir -Path (Join-Path $workspacePath "normalized")
Ensure-Dir -Path (Join-Path $workspacePath "reports")
Ensure-Dir -Path (Join-Path $workspacePath "initiatives")

if ([string]::IsNullOrWhiteSpace($EnginePath)) {
  $candidateInTarget = Join-Path $TargetRoot "product-os-toolkit/scripts/product_os_engine.ps1"
  $candidateSibling = Join-Path $TargetRoot "../product-os-toolkit/scripts/product_os_engine.ps1"
  if (Test-Path $candidateInTarget) {
    $EnginePath = "product-os-toolkit/scripts/product_os_engine.ps1"
  } elseif (Test-Path $candidateSibling) {
    $EnginePath = "../product-os-toolkit/scripts/product_os_engine.ps1"
  } else {
    $EnginePath = "product-os-toolkit/scripts/product_os_engine.ps1"
  }
}
$EnginePath = $EnginePath -replace "\\", "/"
$resolvedEngine = Join-Path $TargetRoot $EnginePath
if (-not (Test-Path $resolvedEngine)) {
  throw "Engine path does not exist: $resolvedEngine. Pass -EnginePath with a valid path from target repo root."
}

@"
{
  "name": "Product OS",
  "workspace_root": "$WorkspaceRoot",
  "engine_path": "$EnginePath",
  "provider": "$Provider",
  "version": "$Version"
}
"@ | Set-Content -Path $cfgPath -Encoding ascii

@'
param(
  [ValidateSet("init","run","approve","status","runstage","approvestage","validate","agentpack","planday","startsession","closesession","endday")]
  [string]$Action = "status",
  [ValidateSet("G1","G2","G3")]
  [string]$Gate,
  [ValidateSet("discover","prioritize","define","build_ready","release_ready","learn_ready","discovery","prioritization","definition","delivery_ready","launch_ready","learning")]
  [string]$Stage,
  [string]$Initiative = "global",
  [string]$Session = "",
  [ValidateSet("codex","claude","generic")]
  [string]$Provider = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $root ".product-os/config.json"
if (-not (Test-Path $configPath)) { throw "Missing .product-os/config.json. Run bootstrap_product_os.ps1 first." }

$cfg = Get-Content -Path $configPath -Raw | ConvertFrom-Json
$engineRel = if ([string]::IsNullOrWhiteSpace([string]$cfg.engine_path)) { "product-os-toolkit/scripts/product_os_engine.ps1" } else { [string]$cfg.engine_path }
$workspaceRoot = if ([string]::IsNullOrWhiteSpace([string]$cfg.workspace_root)) { "product-intel" } else { [string]$cfg.workspace_root }
$configVersion = if ([string]::IsNullOrWhiteSpace([string]$cfg.version)) { "" } else { [string]$cfg.version }
$providerResolved = if (-not [string]::IsNullOrWhiteSpace($Provider)) { $Provider } elseif (-not [string]::IsNullOrWhiteSpace([string]$cfg.provider)) { [string]$cfg.provider } else { "generic" }
$enginePath = Join-Path $root $engineRel
if (-not (Test-Path $enginePath)) { throw "Engine not found at $enginePath. Update .product-os/config.json -> engine_path." }

$invoke = @{
  Action = $Action
  Initiative = $Initiative
  WorkspaceRoot = $workspaceRoot
  RepoRoot = $root
  ConfigVersion = $configVersion
  Provider = $providerResolved
}
if (-not [string]::IsNullOrWhiteSpace($Gate)) { $invoke["Gate"] = $Gate }
if (-not [string]::IsNullOrWhiteSpace($Stage)) { $invoke["Stage"] = $Stage }
if (-not [string]::IsNullOrWhiteSpace($Session)) { $invoke["Session"] = $Session }
try {
  & $enginePath @invoke
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  exit 0
} catch {
  Write-Host ("ERROR: " + $_.Exception.Message)
  exit 1
}
'@ | Set-Content -Path $psPath -Encoding ascii

@'
@echo off
setlocal
if "%~1"=="" (
  echo Usage:
  echo   .\scripts\product_os.cmd init [initiative]
  echo   .\scripts\product_os.cmd run [initiative]
  echo   .\scripts\product_os.cmd status [initiative]
  echo   .\scripts\product_os.cmd validate [initiative]
  echo   .\scripts\product_os.cmd planday
  echo   .\scripts\product_os.cmd startsession ^<initiative^> ^<stage^>
  echo   .\scripts\product_os.cmd closesession ^<session_id^>
  echo   .\scripts\product_os.cmd endday
  echo   .\scripts\product_os.cmd approve G1^|G2^|G3 [initiative]
  echo   .\scripts\product_os.cmd runstage discovery^|prioritization^|definition^|delivery_ready^|launch_ready^|learning [initiative]
  echo   .\scripts\product_os.cmd approvestage discovery^|prioritization^|definition^|delivery_ready^|launch_ready^|learning [initiative]
  echo   .\scripts\product_os.cmd agentpack discovery^|prioritization^|definition^|delivery_ready^|launch_ready^|learning [initiative]
  exit /b 1
)
set ACTION=%~1
set ARG2=%~2
set ARG3=%~3
if /I "%ACTION%"=="approve" (
  if "%ARG2%"=="" ( echo Missing gate. Use G1, G2, or G3. & exit /b 1 )
  if "%ARG3%"=="" set ARG3=global
  powershell -ExecutionPolicy Bypass -File "%~dp0product_os.ps1" -Action approve -Gate %ARG2% -Initiative %ARG3%
  if errorlevel 1 exit /b 1
  exit /b 0
)
if /I "%ACTION%"=="runstage" (
  if "%ARG2%"=="" ( echo Missing stage. & exit /b 1 )
  if "%ARG3%"=="" set ARG3=global
  powershell -ExecutionPolicy Bypass -File "%~dp0product_os.ps1" -Action runstage -Stage %ARG2% -Initiative %ARG3%
  if errorlevel 1 exit /b 1
  exit /b 0
)
if /I "%ACTION%"=="approvestage" (
  if "%ARG2%"=="" ( echo Missing stage. & exit /b 1 )
  if "%ARG3%"=="" set ARG3=global
  powershell -ExecutionPolicy Bypass -File "%~dp0product_os.ps1" -Action approvestage -Stage %ARG2% -Initiative %ARG3%
  if errorlevel 1 exit /b 1
  exit /b 0
)
if /I "%ACTION%"=="agentpack" (
  if "%ARG2%"=="" ( echo Missing stage. & exit /b 1 )
  if "%ARG3%"=="" set ARG3=global
  powershell -ExecutionPolicy Bypass -File "%~dp0product_os.ps1" -Action agentpack -Stage %ARG2% -Initiative %ARG3%
  if errorlevel 1 exit /b 1
  exit /b 0
)
if /I "%ACTION%"=="startsession" (
  if "%ARG2%"=="" ( echo Missing initiative. & exit /b 1 )
  if "%ARG3%"=="" ( echo Missing stage. & exit /b 1 )
  powershell -ExecutionPolicy Bypass -File "%~dp0product_os.ps1" -Action startsession -Initiative %ARG2% -Stage %ARG3%
  if errorlevel 1 exit /b 1
  exit /b 0
)
if /I "%ACTION%"=="closesession" (
  if "%ARG2%"=="" ( echo Missing session_id. & exit /b 1 )
  powershell -ExecutionPolicy Bypass -File "%~dp0product_os.ps1" -Action closesession -Session %ARG2%
  if errorlevel 1 exit /b 1
  exit /b 0
)
if /I "%ACTION%"=="planday" (
  powershell -ExecutionPolicy Bypass -File "%~dp0product_os.ps1" -Action planday
  if errorlevel 1 exit /b 1
  exit /b 0
)
if /I "%ACTION%"=="endday" (
  powershell -ExecutionPolicy Bypass -File "%~dp0product_os.ps1" -Action endday
  if errorlevel 1 exit /b 1
  exit /b 0
)
if "%ARG2%"=="" set ARG2=global
powershell -ExecutionPolicy Bypass -File "%~dp0product_os.ps1" -Action %ACTION% -Initiative %ARG2%
if errorlevel 1 exit /b 1
exit /b 0
'@ | Set-Content -Path $cmdPath -Encoding ascii

@'
#!/usr/bin/env bash
set -euo pipefail
ACTION="${1:-}"
ARG2="${2:-}"
ARG3="${3:-}"
if [[ -z "$ACTION" ]]; then
  echo "Usage:"
  echo "  ./scripts/product_os.sh init [initiative]"
  echo "  ./scripts/product_os.sh run [initiative]"
  echo "  ./scripts/product_os.sh status [initiative]"
  echo "  ./scripts/product_os.sh validate [initiative]"
  echo "  ./scripts/product_os.sh planday"
  echo "  ./scripts/product_os.sh startsession <initiative> <stage>"
  echo "  ./scripts/product_os.sh closesession <session_id>"
  echo "  ./scripts/product_os.sh endday"
  echo "  ./scripts/product_os.sh approve G1|G2|G3 [initiative]"
  echo "  ./scripts/product_os.sh runstage discovery|prioritization|definition|delivery_ready|launch_ready|learning [initiative]"
  echo "  ./scripts/product_os.sh approvestage discovery|prioritization|definition|delivery_ready|launch_ready|learning [initiative]"
  echo "  ./scripts/product_os.sh agentpack discovery|prioritization|definition|delivery_ready|launch_ready|learning [initiative]"
  exit 1
fi
if [[ "$ACTION" == "approve" ]]; then
  [[ -n "$ARG2" ]] || { echo "Missing gate."; exit 1; }
  [[ -n "$ARG3" ]] || ARG3="global"
  pwsh -File "$(dirname "$0")/product_os.ps1" -Action approve -Gate "$ARG2" -Initiative "$ARG3"
  exit $?
fi
if [[ "$ACTION" == "runstage" || "$ACTION" == "approvestage" || "$ACTION" == "agentpack" ]]; then
  [[ -n "$ARG2" ]] || { echo "Missing stage."; exit 1; }
  [[ -n "$ARG3" ]] || ARG3="global"
  pwsh -File "$(dirname "$0")/product_os.ps1" -Action "$ACTION" -Stage "$ARG2" -Initiative "$ARG3"
  exit $?
fi
if [[ "$ACTION" == "startsession" ]]; then
  [[ -n "$ARG2" ]] || { echo "Missing initiative."; exit 1; }
  [[ -n "$ARG3" ]] || { echo "Missing stage."; exit 1; }
  pwsh -File "$(dirname "$0")/product_os.ps1" -Action startsession -Initiative "$ARG2" -Stage "$ARG3"
  exit $?
fi
if [[ "$ACTION" == "closesession" ]]; then
  [[ -n "$ARG2" ]] || { echo "Missing session_id."; exit 1; }
  pwsh -File "$(dirname "$0")/product_os.ps1" -Action closesession -Session "$ARG2"
  exit $?
fi
if [[ "$ACTION" == "planday" || "$ACTION" == "endday" ]]; then
  pwsh -File "$(dirname "$0")/product_os.ps1" -Action "$ACTION"
  exit $?
fi
[[ -n "$ARG2" ]] || ARG2="global"
pwsh -File "$(dirname "$0")/product_os.ps1" -Action "$ACTION" -Initiative "$ARG2"
'@ | Set-Content -Path $shPath -Encoding ascii

@'
# Product OS Skill (LLM-Agnostic)

Use this skill with Codex, Claude Code, or generic LLM agents.

Stage flow:

1. discovery -> approvestage discovery
1. prioritization -> approvestage prioritization
1. definition -> approvestage definition
1. delivery_ready -> approvestage delivery_ready
1. launch_ready -> approvestage launch_ready
1. learning -> approvestage learning

Daily cycle:

1. planday
1. startsession <initiative> <stage>
1. closesession <session_id>
1. endday

Required final artifacts:

- reports/requirements-prd.md
- reports/delivery-readiness.md
- reports/launch-readiness.md
- reports/learning-review.md
- reports/pm-portfolio-dashboard.md
- reports/initiative-index.md
'@ | Set-Content -Path $skillPath -Encoding ascii

@"
{
  "mcpServers": {
    "product-os-filesystem": {
      "command": "node",
      "args": ["path/to/filesystem-mcp-server.js"],
      "env": { "PRODUCT_OS_ROOT": "$WorkspaceRoot" }
    },
    "product-os-analytics": {
      "command": "python",
      "args": ["path/to/analytics_mcp.py"]
    }
  },
  "notes": "Template only. Replace command/args with your MCP server implementations."
}
"@ | Set-Content -Path $mcpPath -Encoding ascii

"codex`nclaude`ngeneric" | Set-Content -Path (Join-Path $providersDir "supported.txt") -Encoding ascii

Write-Output "Product OS bootstrap complete."
Write-Output "Config: $cfgPath"
Write-Output "Run: .\\scripts\\product_os.cmd status"
