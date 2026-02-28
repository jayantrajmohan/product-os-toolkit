param(
  [ValidateSet("init","run","approve","status","runstage","approvestage","validate","agentpack","planday","startsession","closesession","endday")]
  [string]$Action = "status",
  [ValidateSet("G1","G2","G3")]
  [string]$Gate,
  [ValidateSet("discover","prioritize","define","build_ready","release_ready","learn_ready","discovery","prioritization","definition","delivery_ready","launch_ready","learning")]
  [string]$Stage,
  [string]$Initiative = "global",
  [string]$WorkspaceRoot = "product-intel",
  [string]$RepoRoot = "",
  [string]$Session = "",
  [string]$ConfigVersion = "",
  [ValidateSet("codex","claude","generic")]
  [string]$Provider = "generic"
)

$ErrorActionPreference = "Stop"
$EngineVersion = "2.0.0"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
  throw "RepoRoot is required. Use generated wrappers (scripts/product_os.cmd or scripts/product_os.sh) or pass -RepoRoot explicitly."
}
$resolvedRepoRoot = Resolve-Path -Path $RepoRoot -ErrorAction SilentlyContinue
if ($null -eq $resolvedRepoRoot) {
  throw "RepoRoot does not exist: $RepoRoot"
}
$Root = $resolvedRepoRoot.Path
$Pi = Join-Path $Root $WorkspaceRoot
$Raw = Join-Path $Pi "raw"
$Norm = Join-Path $Pi "normalized"
$Reports = Join-Path $Pi "reports"
$InitiativesRoot = Join-Path $Pi "initiatives"
$Registry = Join-Path $Norm "feedback_registry.csv"
$RegistryXlsx = Join-Path $Norm "feedback_registry.xlsx"
$PortfolioStatus = Join-Path $Reports "portfolio-status.md"
$InitiativeIndex = Join-Path $Reports "initiative-index.md"
$DailyRoot = Join-Path $Pi "daily"
$DailySessions = Join-Path $DailyRoot "sessions"
$DailyToday = Join-Path $DailyRoot "today-plan.md"
$DailyRegister = Join-Path $DailyRoot "session-register.md"
$DailyEod = Join-Path $DailyRoot "end-of-day-rollup.md"

$InitiativeKey = ([string]$Initiative).Trim().ToLowerInvariant()
if ([string]::IsNullOrWhiteSpace($InitiativeKey)) { $InitiativeKey = "global" }
$InitiativeKey = ($InitiativeKey -replace "[^a-z0-9\-_.]", "-")
if ([string]::IsNullOrWhiteSpace($InitiativeKey)) { $InitiativeKey = "global" }

$InitiativeDir = Join-Path $InitiativesRoot $InitiativeKey
$InitiativeReports = Join-Path $InitiativeDir "reports"
$InitiativeApprovals = Join-Path $InitiativeDir "approvals"
$InitiativePacks = Join-Path $InitiativeDir "agent-packs"
$InitiativeLogs = Join-Path $InitiativeDir "logs"
$InitiativeContext = Join-Path $InitiativeDir "context"

$Insights = Join-Path $InitiativeReports "insights-summary.md"
$InsightsPM = Join-Path $InitiativeReports "discovery-insights.md"
$DiscoveryBrief = Join-Path $InitiativeReports "discovery-brief.md"
$Prioritization = Join-Path $InitiativeReports "prioritization.csv"
$PrioritizationPM = Join-Path $InitiativeReports "prioritization-matrix.csv"
$Roadmap = Join-Path $InitiativeReports "roadmap-proposal.md"
$RoadmapPM = Join-Path $InitiativeReports "roadmap-plan.md"
$PrioritizationDecisionLog = Join-Path $InitiativeReports "prioritization-decision-log.md"
$DefinePRD = Join-Path $InitiativeReports "prd.md"
$DefinePRDPM = Join-Path $InitiativeReports "requirements-prd.md"
$ExecutionPlan = Join-Path $InitiativeReports "execution-plan.md"
$BuildReadiness = Join-Path $InitiativeReports "build-readiness.md"
$BuildReadinessPM = Join-Path $InitiativeReports "delivery-readiness.md"
$TestCaseMapping = Join-Path $InitiativeReports "test-case-mapping.md"
$ReleaseCard = Join-Path $InitiativeReports "release-readiness.md"
$ReleaseCardPM = Join-Path $InitiativeReports "launch-readiness.md"
$ReleaseChecklist = Join-Path $InitiativeReports "release-checklist.md"
$LearningReview = Join-Path $InitiativeReports "learning-review.md"
$IterationBacklog = Join-Path $InitiativeReports "iteration-backlog.md"
$DecisionLog = Join-Path $InitiativeLogs "decisions.md"
$PortfolioStatusPM = Join-Path $Reports "pm-portfolio-dashboard.md"
$CurrentState = Join-Path $InitiativeContext "current-state.md"
$ChangeLog = Join-Path $InitiativeContext "change-log.md"
$SessionBrief = Join-Path $InitiativeContext "session-brief.md"
$InitiativeMeta = Join-Path $InitiativeContext "initiative-meta.md"

function Normalize-StageName {
  param([string]$Name)
  switch (($Name + "").Trim().ToLowerInvariant()) {
    "discover" { return "discover" }
    "discovery" { return "discover" }
    "prioritize" { return "prioritize" }
    "prioritization" { return "prioritize" }
    "define" { return "define" }
    "definition" { return "define" }
    "build_ready" { return "build_ready" }
    "delivery_ready" { return "build_ready" }
    "release_ready" { return "release_ready" }
    "launch_ready" { return "release_ready" }
    "learn_ready" { return "learn_ready" }
    "learning" { return "learn_ready" }
    default { return $Name }
  }
}

function Get-NextStageLabel {
  param([string]$InitId = $InitiativeKey)
  if (-not (Is-StageApproved -StageName "discover" -ScopeInitiative $InitId)) { return "discovery" }
  if (-not (Is-StageApproved -StageName "prioritize" -ScopeInitiative $InitId)) { return "prioritization" }
  if (-not (Is-StageApproved -StageName "define" -ScopeInitiative $InitId)) { return "definition" }
  if (-not (Is-StageApproved -StageName "build_ready" -ScopeInitiative $InitId)) { return "delivery_ready" }
  if (-not (Is-StageApproved -StageName "release_ready" -ScopeInitiative $InitId)) { return "launch_ready" }
  if (-not (Is-StageApproved -StageName "learn_ready" -ScopeInitiative $InitId)) { return "learning" }
  return "completed"
}

function Ensure-InitiativeContextFiles {
  Ensure-InitiativeMeta
  Ensure-Path -Path $InitiativeContext
  $meta = Parse-InitiativeMetaFile -Path $InitiativeMeta -FallbackInitiative $InitiativeKey
  if (-not (Test-Path $CurrentState)) {
    Write-TextFileSafe -Path $CurrentState -Lines @(
      "# Current State",
      "- initiative_id: $InitiativeKey",
      "- initiative_type: $($meta.initiative_type)",
      "- product_area: $($meta.product_area)",
      "- priority_tier: $($meta.priority_tier)",
      "- owner: $($meta.owner)",
      "- updated_at: $(Get-Date -Format o)",
      "- active_stage: $(Get-NextStageLabel)",
      "",
      "## Today Focus",
      "-",
      "",
      "## Blockers",
      "-",
      "",
      "## Next Actions",
      "-"
    )
  }
  if (-not (Test-Path $ChangeLog)) {
    Write-TextFileSafe -Path $ChangeLog -Lines @(
      "# Change Log",
      "",
      "| timestamp | session_id | stage | summary |",
      "|---|---|---|---|"
    )
  }
  if (-not (Test-Path $SessionBrief)) {
    Write-TextFileSafe -Path $SessionBrief -Lines @(
      "# Session Brief",
      "- initiative_id: $InitiativeKey",
      "- generated_at: $(Get-Date -Format o)",
      "",
      "## Current Stage",
      "- $(Get-NextStageLabel)",
      "",
      "## Must Read",
      "- reports/discovery-brief.md",
      "- reports/requirements-prd.md",
      "- reports/execution-plan.md",
      "- reports/delivery-readiness.md",
      "- reports/test-case-mapping.md",
      "- reports/launch-readiness.md",
      "- reports/release-checklist.md",
      "- reports/learning-review.md",
      "- reports/iteration-backlog.md",
      "- context/current-state.md"
    )
  }
}

function Refresh-InitiativeContext {
  Ensure-InitiativeContextFiles
  $nextStage = Get-NextStageLabel
  $meta = Parse-InitiativeMetaFile -Path $InitiativeMeta -FallbackInitiative $InitiativeKey
  $summaryLines = @(
    "# Current State",
    "- initiative_id: $InitiativeKey",
    "- initiative_type: $($meta.initiative_type)",
    "- product_area: $($meta.product_area)",
    "- priority_tier: $($meta.priority_tier)",
    "- owner: $($meta.owner)",
    "- updated_at: $(Get-Date -Format o)",
    "- active_stage: $nextStage",
    "",
    "## Stage Progress",
    "- discovery: $(if (Is-StageApproved -StageName 'discover') {'approved'} else {'pending'})",
    "- prioritization: $(if (Is-StageApproved -StageName 'prioritize') {'approved'} else {'pending'})",
    "- definition: $(if (Is-StageApproved -StageName 'define') {'approved'} else {'pending'})",
    "- delivery_ready: $(if (Is-StageApproved -StageName 'build_ready') {'approved'} else {'pending'})",
    "- launch_ready: $(if (Is-StageApproved -StageName 'release_ready') {'approved'} else {'pending'})",
    "- learning: $(if (Is-StageApproved -StageName 'learn_ready') {'approved'} else {'pending'})",
    "",
    "## Next Actions",
    "- Run or review stage: $nextStage",
    "- Update stage artifact and approve when ready",
    "- Start focused agent session if work is substantial"
  )
  Write-TextFileSafe -Path $CurrentState -Lines $summaryLines

  $brief = @(
    "# Session Brief",
    "- initiative_id: $InitiativeKey",
    "- initiative_type: $($meta.initiative_type)",
    "- product_area: $($meta.product_area)",
    "- priority_tier: $($meta.priority_tier)",
    "- owner: $($meta.owner)",
    "- generated_at: $(Get-Date -Format o)",
    "- active_stage: $nextStage",
    "",
    "## Read First",
    "- context/current-state.md",
    "- reports/discovery-insights.md",
    "- reports/discovery-brief.md",
    "- reports/prioritization-matrix.csv",
    "- reports/prioritization-decision-log.md",
    "- reports/requirements-prd.md",
    "- reports/execution-plan.md",
    "- reports/delivery-readiness.md",
    "- reports/test-case-mapping.md",
    "- reports/launch-readiness.md",
    "- reports/release-checklist.md",
    "- reports/learning-review.md",
    "- reports/iteration-backlog.md",
    "",
    "## Session Objective",
    "- Advance initiative to next approval-ready state for $nextStage",
    "",
    "## Guardrails",
    "- Edit only initiative-scoped files",
    "- Keep outputs concise and testable",
    "- Record decisions in logs/decisions.md and context/change-log.md"
  )
  Write-TextFileSafe -Path $SessionBrief -Lines $brief
}

function Append-ChangeLog {
  param([string]$SessionId,[string]$StageName,[string]$Summary)
  Ensure-InitiativeContextFiles
  $line = "| $(Get-Date -Format o) | $SessionId | $StageName | $Summary |"
  Add-Content -Path $ChangeLog -Value $line -Encoding ascii
}

function Parse-SessionMeta {
  param([string]$Path)
  $txt = Get-Content -Path $Path -Raw
  $meta = @{
    session_id = ""
    initiative_id = ""
    stage = ""
    status = "Open"
    started_at = ""
    closed_at = ""
  }
  foreach ($k in @("session_id","initiative_id","stage","status","started_at","closed_at")) {
    $m = [regex]::Match($txt, "(?im)^" + [regex]::Escape($k) + ":\s*(.+)$")
    if ($m.Success) { $meta[$k] = $m.Groups[1].Value.Trim() }
  }
  return $meta
}

function Parse-InitiativeMetaFile {
  param([string]$Path,[string]$FallbackInitiative = "")
  $meta = @{
    initiative_id = $FallbackInitiative
    initiative_type = "enhancement"
    product_area = "general"
    priority_tier = "P2"
    owner = "unassigned"
    target_outcome = ""
  }
  if (-not (Test-Path $Path)) { return $meta }
  $txt = Get-Content -Path $Path -Raw
  foreach ($k in @("initiative_id","initiative_type","product_area","priority_tier","owner","target_outcome")) {
    $m = [regex]::Match($txt, "(?im)^" + [regex]::Escape($k) + ":\s*(.+)$")
    if ($m.Success) { $meta[$k] = $m.Groups[1].Value.Trim() }
  }
  return $meta
}

function Get-InitiativeMetaById {
  param([string]$InitId)
  $id = (($InitId + "").Trim().ToLowerInvariant())
  if ([string]::IsNullOrWhiteSpace($id)) { $id = "unassigned" }
  $path = Join-Path (Join-Path (Join-Path $InitiativesRoot $id) "context") "initiative-meta.md"
  return (Parse-InitiativeMetaFile -Path $path -FallbackInitiative $id)
}

function Ensure-InitiativeMeta {
  Ensure-Path -Path $InitiativeContext
  if (-not (Test-Path $InitiativeMeta)) {
    Write-TextFileSafe -Path $InitiativeMeta -Lines @(
      "# Initiative Meta",
      "initiative_id: $InitiativeKey",
      "initiative_type: enhancement",
      "product_area: general",
      "priority_tier: P2",
      "owner: unassigned",
      "target_outcome:"
    )
  }
}

function Rebuild-SessionRegister {
  Ensure-Path -Path $DailySessions
  $files = Get-ChildItem -Path $DailySessions -Filter *.md -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
  $out = @(
    "# Session Register",
    "- updated_at: $(Get-Date -Format o)",
    "",
    "| session_id | initiative_id | stage | status | started_at | closed_at |",
    "|---|---|---|---|---|---|"
  )
  foreach ($f in $files) {
    $m = Parse-SessionMeta -Path $f.FullName
    $out += "| $($m.session_id) | $($m.initiative_id) | $($m.stage) | $($m.status) | $($m.started_at) | $($m.closed_at) |"
  }
  Write-TextFileSafe -Path $DailyRegister -Lines $out
}

function Build-DayPlan {
  Ensure-Path -Path $DailyRoot
  Ensure-Path -Path $InitiativesRoot
  $dirs = Get-ChildItem -Path $InitiativesRoot -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "global" -and $_.Name -ne "unassigned" }
  $items = @()
  foreach ($d in $dirs) {
    $id = $d.Name
    $next = Get-NextStageLabel -InitId $id
    $meta = Get-InitiativeMetaById -InitId $id
    $score = 0.0
    $p = Join-Path $d.FullName "reports/prioritization.csv"
    if (Test-Path $p) {
      $rows = Import-Csv -Path $p
      if ($rows.Count -gt 0) {
        $top = $rows | Sort-Object {[double]$_.priority_score} -Descending | Select-Object -First 1
        $score = [double]$top.priority_score
      }
    }
    $items += [pscustomobject]@{
      initiative_id = $id
      initiative_type = $meta.initiative_type
      product_area = $meta.product_area
      priority_tier = $meta.priority_tier
      owner = $meta.owner
      next_stage = $next
      top_score = $score
    }
  }
  $items = $items | Sort-Object -Property @{Expression = "top_score"; Descending = $true}, initiative_id
  $out = @(
    "# Today Plan",
    "- generated_at: $(Get-Date -Format o)",
    "",
    "## Priority Queue",
    "| rank | initiative_id | type | product_area | priority_tier | owner | next_stage | top_priority_score | today_action |",
    "|---:|---|---|---|---|---|---|---:|---|"
  )
  $rank = 0
  foreach ($i in $items) {
    $rank++
    $out += "| $rank | $($i.initiative_id) | $($i.initiative_type) | $($i.product_area) | $($i.priority_tier) | $($i.owner) | $($i.next_stage) | $([math]::Round($i.top_score,2)) | Start a focused session and progress to stage approval |"
  }
  if ($items.Count -eq 0) {
    $out += ""
    $out += "No active initiatives found."
  }
  Write-TextFileSafe -Path $DailyToday -Lines $out
}

function Ensure-Path { param([string]$Path) if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Force -Path $Path | Out-Null } }
function Write-TextFileSafe { param([string]$Path,[string[]]$Lines) $Lines | Set-Content -Path $Path -Encoding ascii }
function Gate-File { param([string]$GateName) (Join-Path $InitiativeApprovals "$GateName.approved") }
function Stage-File { param([string]$StageName) (Join-Path $InitiativeApprovals ("STAGE-" + $StageName + ".approved")) }

function Get-MajorVersion {
  param([string]$Version)
  if ([string]::IsNullOrWhiteSpace($Version)) { return "" }
  $parts = $Version.Split(".")
  if ($parts.Count -eq 0) { return "" }
  return $parts[0]
}

function Check-VersionCompatibility {
  if ([string]::IsNullOrWhiteSpace($ConfigVersion)) { return }
  $engineMajor = Get-MajorVersion -Version $EngineVersion
  $configMajor = Get-MajorVersion -Version $ConfigVersion
  if (-not [string]::IsNullOrWhiteSpace($engineMajor) -and -not [string]::IsNullOrWhiteSpace($configMajor) -and $engineMajor -ne $configMajor) {
    Write-Output "Version warning: config version $ConfigVersion may be incompatible with engine version $EngineVersion."
  }
}

function Get-NormalizedInitiativeId {
  param([object]$Row)
  $v = ""
  if ($null -ne $Row -and $null -ne $Row.PSObject.Properties["initiative_id"]) { $v = [string]$Row.initiative_id }
  $v = $v.Trim().ToLowerInvariant()
  if ([string]::IsNullOrWhiteSpace($v)) { return "unassigned" }
  return ($v -replace "[^a-z0-9\-_.]", "-")
}

function Get-CanonicalRowText {
  param([object]$Row)
  @(
    [string]$Row.feedback_id,
    [string]$Row.initiative_id,
    [string]$Row.source_record_id,
    [string]$Row.theme,
    [string]$Row.feedback_type,
    [string]$Row.severity,
    [string]$Row.frequency_signal,
    [string]$Row.problem_statement,
    [string]$Row.dedupe_key
  ) -join "|"
}

function Get-CycleId {
  param([string]$ScopeInitiative = $InitiativeKey)
  if (-not (Test-Path $Registry)) { return "NOREG" }
  $scope = ([string]$ScopeInitiative).Trim().ToLowerInvariant()
  if ([string]::IsNullOrWhiteSpace($scope)) { $scope = "global" }
  $rows = Import-Csv -Path $Registry
  if ($scope -ne "global") { $rows = @($rows | Where-Object { (Get-NormalizedInitiativeId -Row $_) -eq $scope }) }
  if ($rows.Count -eq 0) { return "EMPTY-" + $scope }
  $text = ($rows | Sort-Object dedupe_key,source_record_id | ForEach-Object { Get-CanonicalRowText -Row $_ }) -join "`n"
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
    $hash = ([System.BitConverter]::ToString($sha.ComputeHash($bytes)) -replace "-", "")
    return $hash.Substring(0, 12)
  } finally { $sha.Dispose() }
}

function Write-ApprovalFile {
  param([string]$Path,[string]$ScopeInitiative = $InitiativeKey)
  $cycleId = Get-CycleId -ScopeInitiative $ScopeInitiative
@"
approved_at=$(Get-Date -Format o)
cycle_id=$cycleId
"@ | Set-Content -Path $Path -Encoding ascii
}

function Is-StageApproved {
  param([string]$StageName,[string]$ScopeInitiative = $InitiativeKey)
  $initKey = ([string]$ScopeInitiative).Trim().ToLowerInvariant()
  if ([string]::IsNullOrWhiteSpace($initKey)) { $initKey = "global" }
  $path = Join-Path (Join-Path (Join-Path $InitiativesRoot $initKey) "approvals") ("STAGE-" + $StageName + ".approved")
  if (-not (Test-Path $path)) { return $false }
  $content = Get-Content -Path $path -Raw
  $cycleId = Get-CycleId -ScopeInitiative $initKey
  return $content -match ("cycle_id=" + [regex]::Escape($cycleId))
}

function Get-FieldValue {
  param([object]$Row,[string[]]$Candidates)
  foreach ($name in $Candidates) {
    $p = $Row.PSObject.Properties[$name]
    if ($null -ne $p -and -not [string]::IsNullOrWhiteSpace([string]$p.Value)) { return [string]$p.Value }
  }
  return ""
}

function Write-DefaultRegistry {
  if (-not (Test-Path $Registry)) {
@"
feedback_id,initiative_id,source_id,source_record_id,captured_at,ingested_at,channel,user_segment,journey_stage,theme,feedback_type,severity,sentiment,frequency_signal,problem_statement,evidence_link,dedupe_key,triage_status
"@ | Set-Content -Path $Registry -Encoding ascii
  }
}

function Backfill-InitiativeIds {
  if (-not (Test-Path $Registry)) { return }
  $rows = Import-Csv -Path $Registry
  if ($rows.Count -eq 0) { return }
  $changed = $false
  foreach ($r in $rows) {
    $normalized = Get-NormalizedInitiativeId -Row $r
    if ($null -eq $r.PSObject.Properties["initiative_id"]) {
      $r | Add-Member -MemberType NoteProperty -Name initiative_id -Value $normalized -Force
      $changed = $true
    } elseif ([string]$r.initiative_id -ne $normalized) {
      $r.initiative_id = $normalized
      $changed = $true
    }
  }
  if ($changed) {
    $rows | Select-Object feedback_id,initiative_id,source_id,source_record_id,captured_at,ingested_at,channel,user_segment,journey_stage,theme,feedback_type,severity,sentiment,frequency_signal,problem_statement,evidence_link,dedupe_key,triage_status |
      Export-Csv -Path $Registry -NoTypeInformation -Encoding ascii
  }
}

function Get-ChannelFromPath {
  param([string]$Path)
  $p = $Path.ToLowerInvariant()
  if ($p -match "\\transcript|\\call") { return "calls" }
  if ($p -match "\\chat|\\slack|\\teams") { return "chat" }
  return "unknown"
}

function Infer-Theme {
  param([string]$Text)
  $t = ([string]$Text).ToLowerInvariant()
  if ($t -match "dashboard|report|kpi|metric|pipeline") { return "reporting" }
  if ($t -match "slow|latency|timeout|performance") { return "performance" }
  if ($t -match "engagement|retention|notification|streak") { return "engagement" }
  return "general"
}

function Infer-Type {
  param([string]$Text)
  $t = ([string]$Text).ToLowerInvariant()
  if ($t -match "bug|error|fail|failed|crash|broken|cannot|can't|slow|timeout") { return "Bug" }
  if ($t -match "new|add|create|build") { return "New Feature" }
  return "Improvement"
}

function Infer-Severity {
  param([string]$Text)
  $t = ([string]$Text).ToLowerInvariant()
  if ($t -match "outage|data loss|crash|immediately|urgent") { return "Critical" }
  if ($t -match "fail|failed|broken|timeout|slow|blocked") { return "High" }
  if ($t -match "need|want|improve|better") { return "Medium" }
  return "Low"
}

function Should-ExtractLine {
  param([string]$Line)
  $t = ([string]$Line).Trim()
  if ($t.Length -lt 20) { return $false }
  return $t -match "issue|problem|feedback|request|need|want|bug|error|slow|fail|cannot|improve|dashboard|report|kpi"
}

function Preprocess-UnstructuredSources {
  $targets = @((Join-Path $Raw "transcripts"),(Join-Path $Raw "chatlogs"))
  $rows = @()
  foreach ($dir in $targets) {
    if (-not (Test-Path $dir)) { continue }
    $files = Get-ChildItem -Path $dir -Recurse -File -ErrorAction SilentlyContinue
    foreach ($f in $files) {
      $channel = Get-ChannelFromPath -Path $f.FullName
      $fileInitiative = ($f.BaseName -replace "[^a-zA-Z0-9\-_.]", "-").ToLowerInvariant()
      if ([string]::IsNullOrWhiteSpace($fileInitiative)) { $fileInitiative = "unassigned" }
      if ($InitiativeKey -ne "global" -and $fileInitiative -ne $InitiativeKey) { continue }
      if ($f.Extension -in @(".txt",".md",".log")) {
        $ln = 0
        Get-Content -Path $f.FullName | ForEach-Object {
          $ln++
          $line = [string]$_
          if (Should-ExtractLine -Line $line) {
            $rows += [pscustomobject]@{
              initiative_id = $fileInitiative
              source_record_id = "$($f.BaseName)-L$ln"
              channel = $channel
              theme = (Infer-Theme -Text $line)
              feedback_type = (Infer-Type -Text $line)
              severity = (Infer-Severity -Text $line)
              frequency_signal = "Repeated"
              problem_statement = $line.Trim()
              evidence_link = $f.FullName
              captured_at = (Get-Date -Format o)
            }
          }
        }
      } elseif ($f.Extension -eq ".json") {
        try {
          $json = Get-Content -Path $f.FullName -Raw | ConvertFrom-Json
          $items = @()
          if ($json -is [System.Collections.IEnumerable] -and -not ($json -is [string])) {
            $items = @($json)
          } else {
            $items = @($json)
          }
          $idx = 0
          foreach ($item in $items) {
            $idx++
            $msg = Get-FieldValue -Row $item -Candidates @("message","text","content","summary")
            if (-not (Should-ExtractLine -Line $msg)) { continue }
            $rows += [pscustomobject]@{
              initiative_id = $fileInitiative
              source_record_id = "$($f.BaseName)-J$idx"
              channel = $channel
              theme = (Infer-Theme -Text $msg)
              feedback_type = (Infer-Type -Text $msg)
              severity = (Infer-Severity -Text $msg)
              frequency_signal = "Repeated"
              problem_statement = $msg.Trim()
              evidence_link = $f.FullName
              captured_at = (Get-Date -Format o)
            }
          }
        } catch {
          Write-Output "Preprocess warning: could not parse JSON file $($f.FullName)"
        }
      }
    }
  }
  $autoDir = Join-Path $Raw "auto"
  Ensure-Path -Path $autoDir
  $autoCsv = Join-Path $autoDir "auto_extracted_feedback.csv"
  if ($rows.Count -gt 0) {
    $rows | Export-Csv -Path $autoCsv -NoTypeInformation -Encoding ascii
  } elseif (-not (Test-Path $autoCsv)) {
@"
initiative_id,source_record_id,channel,theme,feedback_type,severity,frequency_signal,problem_statement,evidence_link,captured_at
"@ | Set-Content -Path $autoCsv -Encoding ascii
  }
  return $rows.Count
}

function Normalize-Severity {
  param([string]$Value)
  switch (([string]$Value).Trim().ToLowerInvariant()) {
    "critical" { "Critical"; break }
    "high" { "High"; break }
    "medium" { "Medium"; break }
    "low" { "Low"; break }
    default { "" }
  }
}

function Ingest-RawFeedback {
  $files = Get-ChildItem -Path $Raw -Recurse -File -Filter *.csv -ErrorAction SilentlyContinue
  if ($null -eq $files -or $files.Count -eq 0) { return 0 }
  $existing = @(); if (Test-Path $Registry) { $existing = Import-Csv -Path $Registry }
  $byDedupe = @{}
  foreach ($r in $existing) {
    $dk = if ([string]::IsNullOrWhiteSpace($r.dedupe_key)) { $r.feedback_id } else { $r.dedupe_key }
    if (-not [string]::IsNullOrWhiteSpace($dk)) { $byDedupe[$dk] = $r }
  }
  $added = 0
  foreach ($f in $files) {
    $rows = Import-Csv -Path $f.FullName
    $lineNo = 0
    foreach ($row in $rows) {
      $lineNo++
      $initiativeId = Get-FieldValue -Row $row -Candidates @("initiative_id","initiative","requirement_id")
      if ([string]::IsNullOrWhiteSpace($initiativeId)) { $initiativeId = ($f.BaseName -replace "[^a-zA-Z0-9\-_.]", "-").ToLowerInvariant() }
      if ([string]::IsNullOrWhiteSpace($initiativeId)) { $initiativeId = "unassigned" }
      if ($InitiativeKey -ne "global" -and $initiativeId -ne $InitiativeKey) { continue }
      $problem = Get-FieldValue -Row $row -Candidates @("problem_statement","feedback","message","text","summary")
      if ([string]::IsNullOrWhiteSpace($problem)) { continue }
      $channel = Get-FieldValue -Row $row -Candidates @("channel","source","source_channel")
      if ([string]::IsNullOrWhiteSpace($channel)) { $channel = $f.Directory.Name }
      $sourceRec = Get-FieldValue -Row $row -Candidates @("source_record_id","id","message_id","ticket_id")
      $dedupe = if (-not [string]::IsNullOrWhiteSpace($sourceRec)) { "$channel|$sourceRec" } else { "$($f.FullName)|$lineNo|$problem" }
      if ($byDedupe.ContainsKey($dedupe)) { continue }
      $idx = ($byDedupe.Count + 1).ToString("00000")
      $severity = Normalize-Severity (Get-FieldValue -Row $row -Candidates @("severity","priority"))
      if ([string]::IsNullOrWhiteSpace($severity)) { $severity = Infer-Severity -Text $problem }
      $theme = Get-FieldValue -Row $row -Candidates @("theme","product_area")
      if ([string]::IsNullOrWhiteSpace($theme)) { $theme = Infer-Theme -Text $problem }
      $type = Get-FieldValue -Row $row -Candidates @("feedback_type","type")
      if ([string]::IsNullOrWhiteSpace($type)) { $type = Infer-Type -Text $problem }
      $obj = [pscustomobject]@{
        feedback_id = "FB-$idx"
        initiative_id = $initiativeId
        source_id = (Get-FieldValue -Row $row -Candidates @("source_id"))
        source_record_id = $sourceRec
        captured_at = (Get-FieldValue -Row $row -Candidates @("captured_at","timestamp","date","created_at"))
        ingested_at = (Get-Date -Format o)
        channel = $channel
        user_segment = (Get-FieldValue -Row $row -Candidates @("user_segment","segment","persona"))
        journey_stage = (Get-FieldValue -Row $row -Candidates @("journey_stage","journey"))
        theme = $theme
        feedback_type = $type
        severity = $severity
        sentiment = (Get-FieldValue -Row $row -Candidates @("sentiment"))
        frequency_signal = "Repeated"
        problem_statement = $problem
        evidence_link = (Get-FieldValue -Row $row -Candidates @("evidence_link","url","link"))
        dedupe_key = $dedupe
        triage_status = "New"
      }
      if ([string]::IsNullOrWhiteSpace([string]$obj.captured_at)) { $obj.captured_at = (Get-Date -Format o) }
      if ([string]::IsNullOrWhiteSpace([string]$obj.evidence_link)) { $obj.evidence_link = $f.FullName }
      $byDedupe[$dedupe] = $obj
      $added++
    }
  }
  if ($added -gt 0) {
    $byDedupe.Values | Sort-Object feedback_id | Select-Object feedback_id,initiative_id,source_id,source_record_id,captured_at,ingested_at,channel,user_segment,journey_stage,theme,feedback_type,severity,sentiment,frequency_signal,problem_statement,evidence_link,dedupe_key,triage_status |
      Export-Csv -Path $Registry -NoTypeInformation -Encoding ascii
  }
  return $added
}

function Sync-RegistryExcel {
  if (-not (Test-Path $Registry)) { return $false }
  try { $excel = New-Object -ComObject Excel.Application } catch { return $false }
  try {
    $excel.Visible = $false
    $excel.DisplayAlerts = $false
    $wb = $excel.Workbooks.Open($Registry)
    $wb.SaveAs($RegistryXlsx, 51)
    $wb.Close($false)
    return $true
  } catch {
    return $false
  } finally {
    if ($null -ne $excel) { $excel.Quit(); [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) }
    [GC]::Collect(); [GC]::WaitForPendingFinalizers()
  }
}

function Get-ScopedRows {
  param([object[]]$Rows)
  if ($InitiativeKey -eq "global") { return $Rows }
  return @($Rows | Where-Object { (Get-NormalizedInitiativeId -Row $_) -eq $InitiativeKey })
}

function Build-Insights {
  $rows = Get-ScopedRows -Rows (Import-Csv -Path $Registry)
  $themeCounts = $rows | Group-Object -Property theme | Sort-Object Count -Descending
  $sevCounts = $rows | Group-Object -Property severity | Sort-Object Count -Descending
  $out = @("# Insights Summary","- initiative_scope: $InitiativeKey","- rows: $($rows.Count)","","## Theme Counts")
  foreach ($g in $themeCounts) { $name = if ([string]::IsNullOrWhiteSpace($g.Name)) { "(unlabeled)" } else { $g.Name }; $out += "- $name : $($g.Count)" }
  $out += ""; $out += "## Severity Counts"
  foreach ($g in $sevCounts) { $name = if ([string]::IsNullOrWhiteSpace($g.Name)) { "(unlabeled)" } else { $g.Name }; $out += "- $name : $($g.Count)" }
  Write-TextFileSafe -Path $Insights -Lines $out
  Write-TextFileSafe -Path $InsightsPM -Lines $out
}

function Build-Prioritization {
  $rows = Get-ScopedRows -Rows (Import-Csv -Path $Registry)
  if ($rows.Count -eq 0) { @() | Export-Csv -Path $Prioritization -NoTypeInformation -Encoding ascii; return }
  if ($InitiativeKey -eq "global") {
    $groups = $rows | Group-Object -Property { "$($_.initiative_id)::$(if ([string]::IsNullOrWhiteSpace($_.theme)) { "unlabeled" } else { $_.theme })" } | Sort-Object Count -Descending | Select-Object -First 20
  } else {
    $groups = $rows | Group-Object -Property { if ([string]::IsNullOrWhiteSpace($_.theme)) { "unlabeled" } else { $_.theme } } | Sort-Object Count -Descending | Select-Object -First 20
  }
  $result = @()
  foreach ($t in $groups) {
    $groupRows = @($t.Group)
    $sev = ($groupRows | ForEach-Object { switch ($_.severity) { "Critical" {5} "High" {4} "Medium" {3} "Low" {2} default {2} } } | Measure-Object -Maximum).Maximum
    $freq = ($groupRows | Measure-Object).Count
    $score = ($sev * 0.6) + ([math]::Min($freq,5) * 0.4)
    $initiativeOut = if ($InitiativeKey -eq "global") { [string]$groupRows[0].initiative_id } else { $InitiativeKey }
    $themeOut = if ($InitiativeKey -eq "global") {
      $parts = ([string]$t.Name).Split("::", 2)
      if ($parts.Count -eq 2) { $parts[1] } else { "unlabeled" }
    } else {
      [string]$t.Name
    }
    $themeOut = ($themeOut + "").TrimStart(":")
    $result += [pscustomobject]@{
      opportunity_id = "OPP-" + ($result.Count + 1).ToString("000")
      initiative_id = $initiativeOut
      theme = $themeOut
      evidence_count = $t.Count
      priority_score = [math]::Round($score, 2)
      recommendation = if ($score -ge 3.5) { "Build now" } elseif ($score -ge 2.5) { "Validate first" } else { "Defer" }
    }
  }
  $result | Export-Csv -Path $Prioritization -NoTypeInformation -Encoding ascii
  $result | Export-Csv -Path $PrioritizationPM -NoTypeInformation -Encoding ascii
}

function Build-RoadmapProposal {
  $rows = Import-Csv -Path $Prioritization | Sort-Object {[double]$_.priority_score} -Descending | Select-Object -First 5
  $out = @("# Roadmap Proposal","- initiative_scope: $InitiativeKey","","Top candidate opportunities:")
  foreach ($r in $rows) { $out += "- $($r.opportunity_id) | theme: $($r.theme) | score: $($r.priority_score) | $($r.recommendation)" }
  Write-TextFileSafe -Path $Roadmap -Lines $out
  Write-TextFileSafe -Path $RoadmapPM -Lines $out
}

function Ensure-Artifact {
  param([string]$Path,[string[]]$DefaultContent)
  if (-not (Test-Path $Path)) { Write-TextFileSafe -Path $Path -Lines $DefaultContent }
}

function Render-StageArtifacts {
  param([string]$StageName)
  if ($StageName -eq "define") {
    Ensure-Artifact -Path $DefinePRD -DefaultContent @("# PRD","Status: Draft","Initiative: $InitiativeKey","","## Problem","","## Users","","## Success Metrics","","## Requirements","- R1:")
    Ensure-Artifact -Path $DefinePRDPM -DefaultContent @("# Requirements PRD","Status: Draft","Initiative: $InitiativeKey","","## Problem","","## Users","","## Success Metrics","","## Requirements","- R1:")
  }
  if ($StageName -eq "build_ready") {
    Ensure-Artifact -Path $BuildReadiness -DefaultContent @("# Build Readiness","Status: Not Ready","Initiative: $InitiativeKey","","## Scope","","## Acceptance Criteria","- AC1:","","## Test Plan","- Unit:","- Integration:","- UAT:")
    Ensure-Artifact -Path $BuildReadinessPM -DefaultContent @("# Delivery Readiness","Status: Not Ready","Initiative: $InitiativeKey","","## Scope","","## Acceptance Criteria","- AC1:","","## Test Plan","- Unit:","- Integration:","- UAT:")
  }
  if ($StageName -eq "release_ready") {
    Ensure-Artifact -Path $ReleaseCard -DefaultContent @("# Release Readiness","Status: Draft","Initiative: $InitiativeKey","","## Release Scope","","## Rollout Plan","","## Monitoring","","## Rollback Plan")
    Ensure-Artifact -Path $ReleaseCardPM -DefaultContent @("# Launch Readiness","Status: Draft","Initiative: $InitiativeKey","","## Release Scope","","## Rollout Plan","","## Monitoring","","## Rollback Plan")
  }
  if ($StageName -eq "learn_ready") {
    Ensure-Artifact -Path $LearningReview -DefaultContent @("# Learning Review","Status: Draft","Initiative: $InitiativeKey","","## Outcomes vs Success Metrics","","## What Worked","","## What Did Not Work","","## Next Iteration")
  }
  Ensure-Artifact -Path $DecisionLog -DefaultContent @("# Decision Log","","| date | stage | decision | owner | rationale |","|---|---|---|---|---|")
}

function Build-AgentPack {
  param([string]$StageName)
  $packDir = Join-Path $InitiativePacks $StageName
  Ensure-Path -Path $packDir
  Write-TextFileSafe -Path (Join-Path $packDir "task.md") -Lines @(
    "# Agent Task: $StageName",
    "initiative_id: $InitiativeKey",
    "provider: $Provider",
    "",
    "Produce stage-complete artifacts for this stage using Product OS contracts."
  )
  @{
    initiative_id = $InitiativeKey
    stage = $StageName
    workspace_root = $WorkspaceRoot
    reports_path = "$WorkspaceRoot/initiatives/$InitiativeKey/reports"
    approvals_path = "$WorkspaceRoot/initiatives/$InitiativeKey/approvals"
    contracts = @("specs/ARTIFACT_CONTRACT.md","specs/STAGE_GATE_CONTRACT.md","specs/AGENT_COMPATIBILITY.md")
  } | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $packDir "context.json") -Encoding ascii
  Write-TextFileSafe -Path (Join-Path $packDir "codex.prompt.md") -Lines @("Use task.md + context.json. Update only initiative files. Validate contracts before finish.")
  Write-TextFileSafe -Path (Join-Path $packDir "claude.prompt.md") -Lines @("Use task.md + context.json. Produce stage artifacts and gate readiness.")
  Write-TextFileSafe -Path (Join-Path $packDir "generic.prompt.md") -Lines @("Use task.md + context.json. Follow Product OS contracts.")
}

function Validate-Initiative {
  $issues = @()
  if (-not (Test-Path $Registry)) { $issues += "Registry missing: $Registry" }
  if (-not (Test-Path $Insights)) { $issues += "Insights missing: $Insights" }
  if (-not (Test-Path $DiscoveryBrief)) { $issues += "Discovery brief missing: $DiscoveryBrief" }
  if (-not (Test-Path $Prioritization)) { $issues += "Prioritization missing: $Prioritization" }
  if (-not (Test-Path $PrioritizationDecisionLog)) { $issues += "Prioritization decision log missing: $PrioritizationDecisionLog" }
  if (-not (Test-Path $Roadmap)) { $issues += "Roadmap missing: $Roadmap" }
  if (-not (Test-Path $DefinePRD)) { $issues += "PRD missing: $DefinePRD" }
  if (-not (Test-Path $ExecutionPlan)) { $issues += "Execution plan missing: $ExecutionPlan" }
  if (-not (Test-Path $BuildReadiness)) { $issues += "Build Readiness missing: $BuildReadiness" }
  if (-not (Test-Path $TestCaseMapping)) { $issues += "Test case mapping missing: $TestCaseMapping" }
  if (-not (Test-Path $ReleaseCard)) { $issues += "Release Readiness missing: $ReleaseCard" }
  if (-not (Test-Path $ReleaseChecklist)) { $issues += "Release checklist missing: $ReleaseChecklist" }
  if (-not (Test-Path $LearningReview)) { $issues += "Learning Review missing: $LearningReview" }
  if (-not (Test-Path $IterationBacklog)) { $issues += "Iteration backlog missing: $IterationBacklog" }
  if (Test-Path $DefinePRD) {
    $prd = Get-Content -Path $DefinePRD -Raw
    if ($prd -notmatch "Success Metrics") { $issues += "PRD missing Success Metrics section." }
    if ($prd -notmatch "Requirements") { $issues += "PRD missing Requirements section." }
  }
  if (Test-Path $BuildReadiness) {
    $br = Get-Content -Path $BuildReadiness -Raw
    if ($br -notmatch "Acceptance Criteria") { $issues += "Build Readiness missing Acceptance Criteria section." }
    if ($br -notmatch "Test Plan") { $issues += "Build Readiness missing Test Plan section." }
    if ($br -notmatch "Status:\s*Ready") { $issues += "Build Readiness is not marked Status: Ready." }
  }
  if (Test-Path $ReleaseCard) {
    $rr = Get-Content -Path $ReleaseCard -Raw
    if ($rr -notmatch "Rollout Plan") { $issues += "Release Readiness missing Rollout Plan section." }
    if ($rr -notmatch "Rollback Plan") { $issues += "Release Readiness missing Rollback Plan section." }
  }
  if (Test-Path $LearningReview) {
    $lr = Get-Content -Path $LearningReview -Raw
    if ($lr -notmatch "Outcomes vs Success Metrics") { $issues += "Learning Review missing outcomes section." }
  }
  if ($issues.Count -eq 0) { Write-Host "Validation passed for initiative '$InitiativeKey'."; return $true }
  Write-Host "Validation failed for initiative '$InitiativeKey':"
  foreach ($i in $issues) { Write-Host "- $i" }
  return $false
}

function Update-InitiativeIndex {
  Ensure-Path -Path $InitiativesRoot
  $dirs = Get-ChildItem -Path $InitiativesRoot -Directory -ErrorAction SilentlyContinue
  $out = @("# Initiative Index","","- updated_at: $(Get-Date -Format o)","","| initiative_id | type | product_area | priority_tier | owner | status | reports | approvals |","|---|---|---|---|---|---|---|---|")
  foreach ($d in $dirs) {
    $id = $d.Name
    if ($id -eq "global" -or $id -eq "unassigned") { continue }
    $meta = Get-InitiativeMetaById -InitId $id
    $status = if (Test-Path (Join-Path $d.FullName "approvals\\STAGE-learn_ready.approved")) { "completed" } else { "active" }
    $out += "| $id | $($meta.initiative_type) | $($meta.product_area) | $($meta.priority_tier) | $($meta.owner) | $status | `$WorkspaceRoot/initiatives/$id/reports/` | `$WorkspaceRoot/initiatives/$id/approvals/` |"
  }
  Write-TextFileSafe -Path $InitiativeIndex -Lines $out
}

function Update-PortfolioStatus {
  if (-not (Test-Path $Registry)) { return }
  $rows = Import-Csv -Path $Registry
  $fromRows = @($rows | ForEach-Object { Get-NormalizedInitiativeId -Row $_ } | Where-Object { $_ -ne "global" -and $_ -ne "unassigned" })
  $fromDirs = @((Get-ChildItem -Path $InitiativesRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.Name }) | Where-Object { $_ -ne "global" -and $_ -ne "unassigned" })
  $inits = @($fromRows + $fromDirs | Sort-Object -Unique)
  $out = @("# Portfolio Status","","- updated_at: $(Get-Date -Format o)","- cycle_id: $(Get-CycleId)","- initiatives: $($inits.Count)","","| initiative_id | type | product_area | priority_tier | owner | feedback_rows | discover | prioritize | define | build_ready | release_ready | learn_ready |","|---|---|---|---|---|---:|---|---|---|---|---|---|")
  foreach ($init in $inits) {
    $meta = Get-InitiativeMetaById -InitId $init
    $cnt = @($rows | Where-Object { (Get-NormalizedInitiativeId -Row $_) -eq $init }).Count
    $s1 = if (Is-StageApproved -StageName "discover" -ScopeInitiative $init) { "yes" } else { "no" }
    $s2 = if (Is-StageApproved -StageName "prioritize" -ScopeInitiative $init) { "yes" } else { "no" }
    $s3 = if (Is-StageApproved -StageName "define" -ScopeInitiative $init) { "yes" } else { "no" }
    $s4 = if (Is-StageApproved -StageName "build_ready" -ScopeInitiative $init) { "yes" } else { "no" }
    $s5 = if (Is-StageApproved -StageName "release_ready" -ScopeInitiative $init) { "yes" } else { "no" }
    $s6 = if (Is-StageApproved -StageName "learn_ready" -ScopeInitiative $init) { "yes" } else { "no" }
    $out += "| $init | $($meta.initiative_type) | $($meta.product_area) | $($meta.priority_tier) | $($meta.owner) | $cnt | $s1 | $s2 | $s3 | $s4 | $s5 | $s6 |"
  }
  Write-TextFileSafe -Path $PortfolioStatus -Lines $out
  Write-TextFileSafe -Path $PortfolioStatusPM -Lines $out
}

function Show-Status {
  Write-Output "Product OS Status"
  Write-Output "Engine version: $EngineVersion"
  Write-Output "Initiative scope: $InitiativeKey"
  Write-Output "Provider: $Provider"
  Write-Output "Cycle ID: $(Get-CycleId)"
  Write-Output "Registry: $(Test-Path $Registry)"
  Write-Output "Insights: $(Test-Path $Insights)"
  Write-Output "Prioritization: $(Test-Path $Prioritization)"
  Write-Output "PRD: $(Test-Path $DefinePRD)"
  Write-Output "Build readiness: $(Test-Path $BuildReadiness)"
  Write-Output "Release readiness: $(Test-Path $ReleaseCard)"
  Write-Output "Learning review: $(Test-Path $LearningReview)"
  Write-Output "Portfolio status: $(Test-Path $PortfolioStatus)"
}

Ensure-Path -Path $Raw
Ensure-Path -Path $Norm
Ensure-Path -Path $Reports
Ensure-Path -Path $InitiativesRoot
Ensure-Path -Path $DailyRoot
Ensure-Path -Path $DailySessions
Ensure-Path -Path $InitiativeDir
Ensure-Path -Path $InitiativeReports
Ensure-Path -Path $InitiativeApprovals
Ensure-Path -Path $InitiativePacks
Ensure-Path -Path $InitiativeLogs
Ensure-Path -Path $InitiativeContext

Write-DefaultRegistry
Backfill-InitiativeIds
Check-VersionCompatibility

switch ($Action) {
  "init" {
    Render-StageArtifacts -StageName "define"
    Render-StageArtifacts -StageName "build_ready"
    Render-StageArtifacts -StageName "release_ready"
    Render-StageArtifacts -StageName "learn_ready"
    Refresh-InitiativeContext
    Rebuild-SessionRegister
    Build-DayPlan
    Update-PortfolioStatus
    Update-InitiativeIndex
    Write-Output "Initialized Product OS workspace for initiative '$InitiativeKey'."
    break
  }
  "runstage" {
    if (-not $Stage) { throw "Provide -Stage discover|prioritize|define|build_ready|release_ready|learn_ready." }
    $Stage = Normalize-StageName -Name $Stage
    switch ($Stage) {
      "discover" {
        $preExtracted = Preprocess-UnstructuredSources
        $added = Ingest-RawFeedback
        Build-Insights
        Ensure-Artifact -Path $DiscoveryBrief -DefaultContent @(
          "# Discovery Brief",
          "Status: Draft",
          "Initiative: $InitiativeKey",
          "",
          "## Problem Framing",
          "-",
          "",
          "## Sources Reviewed",
          "-",
          "",
          "## Top Insights",
          "-"
        )
        $excelSynced = Sync-RegistryExcel
        Build-AgentPack -StageName "discover"
        Refresh-InitiativeContext
        Write-Output "Stage discover complete. extracted=$preExtracted added=$added excel_sync=$excelSynced"
      }
      "prioritize" {
        if (-not (Is-StageApproved -StageName "discover")) { throw "Stage discover is not approved." }
        Build-Prioritization
        Build-RoadmapProposal
        Ensure-Artifact -Path $PrioritizationDecisionLog -DefaultContent @(
          "# Prioritization Decision Log",
          "Status: Draft",
          "Initiative: $InitiativeKey",
          "",
          "| date | opportunity_id | decision | rationale | confidence | notes |",
          "|---|---|---|---|---|---|"
        )
        Build-AgentPack -StageName "prioritize"
        Refresh-InitiativeContext
        Write-Output "Stage prioritize complete."
      }
      "define" {
        if (-not (Is-StageApproved -StageName "prioritize")) { throw "Stage prioritize is not approved." }
        Render-StageArtifacts -StageName "define"
        Ensure-Artifact -Path $ExecutionPlan -DefaultContent @(
          "# Execution Plan",
          "Status: Draft",
          "Initiative: $InitiativeKey",
          "",
          "| workstream | task | subtask | owner | dependency | estimate | status | acceptance_criteria_ref |",
          "|---|---|---|---|---|---|---|---|"
        )
        Build-AgentPack -StageName "define"
        Refresh-InitiativeContext
        Write-Output "Stage define prepared. Review PRD: $DefinePRD"
      }
      "build_ready" {
        if (-not (Is-StageApproved -StageName "define")) { throw "Stage define is not approved." }
        Render-StageArtifacts -StageName "build_ready"
        Ensure-Artifact -Path $TestCaseMapping -DefaultContent @(
          "# Test Case Mapping",
          "Status: Draft",
          "Initiative: $InitiativeKey",
          "",
          "| requirement_or_ac | test_case_id | test_type | owner | status | evidence_link |",
          "|---|---|---|---|---|---|"
        )
        Build-AgentPack -StageName "build_ready"
        Refresh-InitiativeContext
        Write-Output "Stage build_ready prepared."
      }
      "release_ready" {
        if (-not (Is-StageApproved -StageName "build_ready")) { throw "Stage build_ready is not approved." }
        Render-StageArtifacts -StageName "release_ready"
        Ensure-Artifact -Path $ReleaseChecklist -DefaultContent @(
          "# Release Checklist",
          "Status: Draft",
          "Initiative: $InitiativeKey",
          "",
          "- [ ] Scope signed off",
          "- [ ] Monitoring configured",
          "- [ ] Rollback rehearsed",
          "- [ ] Comms prepared",
          "- [ ] Go/No-Go approved"
        )
        Build-AgentPack -StageName "release_ready"
        Refresh-InitiativeContext
        Write-Output "Stage release_ready prepared."
      }
      "learn_ready" {
        if (-not (Is-StageApproved -StageName "release_ready")) { throw "Stage release_ready is not approved." }
        Render-StageArtifacts -StageName "learn_ready"
        Ensure-Artifact -Path $IterationBacklog -DefaultContent @(
          "# Iteration Backlog",
          "Status: Draft",
          "Initiative: $InitiativeKey",
          "",
          "| item_id | item | source | priority | owner | next_action |",
          "|---|---|---|---|---|---|"
        )
        Build-AgentPack -StageName "learn_ready"
        Refresh-InitiativeContext
        Write-Output "Stage learn_ready prepared."
      }
    }
    Build-DayPlan
    Update-PortfolioStatus
    Update-InitiativeIndex
    break
  }
  "approvestage" {
    if (-not $Stage) { throw "Provide -Stage discover|prioritize|define|build_ready|release_ready|learn_ready." }
    $Stage = Normalize-StageName -Name $Stage
    switch ($Stage) {
      "discover" {
        if (-not (Test-Path $Registry)) { throw "Missing $Registry." }
        if (-not (Test-Path $Insights)) { throw "Missing $Insights." }
        if (-not (Test-Path $DiscoveryBrief)) { throw "Missing $DiscoveryBrief." }
      }
      "prioritize" {
        if (-not (Is-StageApproved -StageName "discover")) { throw "discover must be approved first." }
        if (-not (Test-Path $Prioritization)) { throw "Missing $Prioritization." }
        if (-not (Test-Path $Roadmap)) { throw "Missing $Roadmap." }
        if (-not (Test-Path $PrioritizationDecisionLog)) { throw "Missing $PrioritizationDecisionLog." }
      }
      "define" {
        if (-not (Is-StageApproved -StageName "prioritize")) { throw "prioritize must be approved first." }
        if (-not (Test-Path $DefinePRD)) { throw "Missing $DefinePRD." }
        if (-not (Test-Path $ExecutionPlan)) { throw "Missing $ExecutionPlan." }
      }
      "build_ready" {
        if (-not (Is-StageApproved -StageName "define")) { throw "define must be approved first." }
        if (-not (Test-Path $BuildReadiness)) { throw "Missing $BuildReadiness." }
        if (-not (Test-Path $BuildReadinessPM)) { throw "Missing $BuildReadinessPM." }
        if (-not (Test-Path $TestCaseMapping)) { throw "Missing $TestCaseMapping." }
        $txt = Get-Content -Path $BuildReadiness -Raw
        if ($txt -notmatch "Status:\s*Ready") { throw "Build readiness must contain 'Status: Ready'." }
        $txtPm = Get-Content -Path $BuildReadinessPM -Raw
        if ($txtPm -notmatch "Status:\s*Ready") { throw "Delivery readiness must contain 'Status: Ready'." }
      }
      "release_ready" {
        if (-not (Is-StageApproved -StageName "build_ready")) { throw "build_ready must be approved first." }
        if (-not (Test-Path $ReleaseCard)) { throw "Missing $ReleaseCard." }
        if (-not (Test-Path $ReleaseChecklist)) { throw "Missing $ReleaseChecklist." }
      }
      "learn_ready" {
        if (-not (Is-StageApproved -StageName "release_ready")) { throw "release_ready must be approved first." }
        if (-not (Test-Path $LearningReview)) { throw "Missing $LearningReview." }
        if (-not (Test-Path $IterationBacklog)) { throw "Missing $IterationBacklog." }
      }
    }
    Write-ApprovalFile -Path (Stage-File -StageName $Stage)
    Refresh-InitiativeContext
    Build-DayPlan
    Update-PortfolioStatus
    Update-InitiativeIndex
    Write-Output "Approved stage $Stage"
    break
  }
  "approve" {
    if (-not $Gate) { throw "Provide -Gate G1|G2|G3." }
    if ($Gate -eq "G1" -and -not (Is-StageApproved -StageName "build_ready")) { throw "G1 requires build_ready approval." }
    if ($Gate -eq "G2" -and -not (Is-StageApproved -StageName "release_ready")) { throw "G2 requires release_ready approval." }
    if ($Gate -eq "G3" -and -not (Is-StageApproved -StageName "learn_ready")) { throw "G3 requires learn_ready approval." }
    Write-ApprovalFile -Path (Gate-File -GateName $Gate)
    Refresh-InitiativeContext
    Build-DayPlan
    Update-PortfolioStatus
    Update-InitiativeIndex
    Write-Output "Approved gate $Gate"
    break
  }
  "run" {
    $preExtracted = Preprocess-UnstructuredSources
    $added = Ingest-RawFeedback
    Build-Insights
    Build-Prioritization
    Build-RoadmapProposal
    Refresh-InitiativeContext
    Build-DayPlan
    Update-PortfolioStatus
    Update-InitiativeIndex
    Write-Output "Run complete. extracted=$preExtracted added=$added"
    break
  }
  "validate" {
    $ok = Validate-Initiative
    if (-not $ok) { exit 2 }
    break
  }
  "agentpack" {
    if (-not $Stage) { throw "Provide -Stage for agentpack." }
    $Stage = Normalize-StageName -Name $Stage
    Build-AgentPack -StageName $Stage
    Write-Output "Agent pack created: $InitiativePacks/$Stage"
    break
  }
  "planday" {
    Build-DayPlan
    Rebuild-SessionRegister
    Write-Output "Daily plan generated: $DailyToday"
    break
  }
  "startsession" {
    if (-not $Stage) { throw "Provide -Stage for startsession." }
    $Stage = Normalize-StageName -Name $Stage
    if ($InitiativeKey -eq "global") { throw "Provide a non-global initiative for startsession." }
    Ensure-InitiativeContextFiles
    Refresh-InitiativeContext
    $sessionId = "SES-" + (Get-Date -Format "yyyyMMdd-HHmmss") + "-" + $InitiativeKey
    $sessionPath = Join-Path $DailySessions ($sessionId + ".md")
    $sessionLines = @(
      "# Session Worklog",
      "session_id: $sessionId",
      "initiative_id: $InitiativeKey",
      "stage: $Stage",
      "status: Open",
      "started_at: $(Get-Date -Format o)",
      "closed_at:",
      "",
      "## Objective",
      "- Progress initiative in stage '$Stage' toward approval readiness.",
      "",
      "## Required Context",
      "- $SessionBrief",
      "- $CurrentState",
      "- $DecisionLog",
      "",
      "## Work Log",
      "-"
    )
    Write-TextFileSafe -Path $sessionPath -Lines $sessionLines
    Rebuild-SessionRegister
    Write-Output "Session started: $sessionId"
    Write-Output "Session file: $sessionPath"
    break
  }
  "closesession" {
    if ([string]::IsNullOrWhiteSpace($Session)) { throw "Provide -Session <session_id> for closesession." }
    $sessionPath = Join-Path $DailySessions ($Session + ".md")
    if (-not (Test-Path $sessionPath)) { throw "Session file not found: $sessionPath" }
    $txt = Get-Content -Path $sessionPath -Raw
    $txt = [regex]::Replace($txt, "(?im)^status:\s*.+$", "status: Closed")
    $txt = [regex]::Replace($txt, "(?im)^closed_at:\s*.*$", ("closed_at: " + (Get-Date -Format o)))
    Set-Content -Path $sessionPath -Value $txt -Encoding ascii
    $meta = Parse-SessionMeta -Path $sessionPath
    $summary = "Session closed. Review work log in daily/sessions/$Session.md"
    $savedInit = $InitiativeKey
    $InitiativeKey = (($meta.initiative_id + "").Trim().ToLowerInvariant())
    if ([string]::IsNullOrWhiteSpace($InitiativeKey)) { $InitiativeKey = $savedInit }
    $InitiativeDir = Join-Path $InitiativesRoot $InitiativeKey
    $InitiativeReports = Join-Path $InitiativeDir "reports"
    $InitiativeApprovals = Join-Path $InitiativeDir "approvals"
    $InitiativePacks = Join-Path $InitiativeDir "agent-packs"
    $InitiativeLogs = Join-Path $InitiativeDir "logs"
    $InitiativeContext = Join-Path $InitiativeDir "context"
    $CurrentState = Join-Path $InitiativeContext "current-state.md"
    $ChangeLog = Join-Path $InitiativeContext "change-log.md"
    $SessionBrief = Join-Path $InitiativeContext "session-brief.md"
    $InitiativeMeta = Join-Path $InitiativeContext "initiative-meta.md"
    Ensure-Path -Path $InitiativeContext
    Append-ChangeLog -SessionId $Session -StageName ($meta.stage + "") -Summary $summary
    Refresh-InitiativeContext
    Rebuild-SessionRegister
    Build-DayPlan
    Write-Output "Session closed: $Session"
    break
  }
  "endday" {
    Rebuild-SessionRegister
    Build-DayPlan
    $files = Get-ChildItem -Path $DailySessions -Filter *.md -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    $out = @(
      "# End Of Day Rollup",
      "- generated_at: $(Get-Date -Format o)",
      "",
      "## Sessions",
      "| session_id | initiative_id | stage | status |",
      "|---|---|---|---|"
    )
    foreach ($f in $files) {
      $m = Parse-SessionMeta -Path $f.FullName
      $out += "| $($m.session_id) | $($m.initiative_id) | $($m.stage) | $($m.status) |"
    }
    $out += ""
    $out += "## Tomorrow Restart"
    $out += "- Open daily/today-plan.md"
    $out += "- Continue highest-priority initiatives first"
    $out += "- Start new agent sessions using session briefs"
    Write-TextFileSafe -Path $DailyEod -Lines $out
    Write-Output "End-of-day rollup generated: $DailyEod"
    break
  }
  "status" {
    Refresh-InitiativeContext
    Rebuild-SessionRegister
    Build-DayPlan
    Update-PortfolioStatus
    Update-InitiativeIndex
    Show-Status
    break
  }
}
