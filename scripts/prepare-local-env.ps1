$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

# Keys that receive a random secret when empty or still set to a change_this_ placeholder.
$SecretKeys = @(
  'POSTGRES_PASSWORD', 'CDC_PASSWORD',
  'RUSTFS_ACCESS_KEY', 'RUSTFS_SECRET_KEY',
  'SUPERSET_DB_PASSWORD', 'SUPERSET_SECRET_KEY', 'SUPERSET_ADMIN_PASSWORD',
  'GRAFANA_ADMIN_PASSWORD'
)

# Default template, used to recreate .env.example when it is missing.
$DefaultTemplate = @(
  '# AtlasFlow - local template. Run .\scripts\prepare-local-env.ps1 to generate .env'
  '# Values starting with change_this_ are replaced by random secrets.'
  ''
  '# --- PostgreSQL (source + CDC) ---'
  'POSTGRES_USER=atlasflow_admin'
  'POSTGRES_PASSWORD=change_this_postgres_password'
  'POSTGRES_DB=postgres'
  'POSTGRES_PORT=55432'
  'CDC_PASSWORD=change_this_cdc_password'
  ''
  '# --- RustFS object store (S3) ---'
  'RUSTFS_ACCESS_KEY=change_this_rustfs_access_key'
  'RUSTFS_SECRET_KEY=change_this_rustfs_secret_key'
  ''
  '# --- Superset ---'
  'SUPERSET_DB_PASSWORD=change_this_superset_db_password'
  'SUPERSET_SECRET_KEY=change_this_superset_secret_key'
  'SUPERSET_ADMIN_USERNAME=atlasadmin'
  'SUPERSET_ADMIN_PASSWORD=change_this_superset_admin_password'
  'SUPERSET_ADMIN_EMAIL=atlasadmin@local.test'
  ''
  '# --- Grafana ---'
  'GRAFANA_ADMIN_USER=atlasadmin'
  'GRAFANA_ADMIN_PASSWORD=change_this_grafana_admin_password'
)

$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)

function New-RandomHex([int]$Bytes = 24) {
  $buffer = New-Object byte[] $Bytes
  $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
  try { $rng.GetBytes($buffer) } finally { $rng.Dispose() }
  return ([System.BitConverter]::ToString($buffer)).Replace('-', '').ToLowerInvariant()
}

function Read-EnvLines([string]$Path) {
  # Strip a UTF-8 BOM if one is present, otherwise the first key would not match.
  $text = [System.IO.File]::ReadAllText($Path).TrimStart([char]0xFEFF)
  return $text -split "`r?`n"
}

$ExamplePath = Join-Path $Root '.env.example'
$EnvPath = Join-Path $Root '.env'

# 1. Template: recreate it when missing instead of failing.
if (-not (Test-Path -LiteralPath $ExamplePath)) {
  [System.IO.File]::WriteAllText($ExamplePath, ($DefaultTemplate -join "`n") + "`n", $Utf8NoBom)
  Write-Host 'INFO: .env.example was missing and has been created from the default template. Commit it.' -ForegroundColor Yellow
}

# 2. Existing .env values are kept, so secrets survive a rerun.
$Existing = @{}
if (Test-Path -LiteralPath $EnvPath) {
  foreach ($line in Read-EnvLines $EnvPath) {
    if ($line.Trim() -match '^([A-Z0-9_]+)=(.*)$') { $Existing[$Matches[1]] = $Matches[2] }
  }
}

# 3. Build .env from the template.
$Lines = @()
$Generated = @()
foreach ($line in Read-EnvLines $ExamplePath) {
  if ($line -notmatch '^([A-Z0-9_]+)=(.*)$') { $Lines += $line; continue }
  $Key = $Matches[1]
  $Default = $Matches[2]
  $Value = if ($Existing.ContainsKey($Key)) { [string]$Existing[$Key] } else { $Default }

  $NeedsSecret = [string]::IsNullOrWhiteSpace($Value) -or $Value -match '^change_this_'
  if ($NeedsSecret -and $Key -in $SecretKeys) {
    $Value = New-RandomHex 24
    $Generated += $Key
  }
  elseif ($NeedsSecret) {
    $Value = $Default
  }

  # SQL templates inject object-store keys directly, so require simple safe characters.
  if ($Key -in @('RUSTFS_ACCESS_KEY', 'RUSTFS_SECRET_KEY') -and $Value -notmatch '^[A-Za-z0-9_-]{8,80}$') {
    $Value = New-RandomHex 24
    if ($Key -notin $Generated) { $Generated += $Key }
  }
  $Lines += "$Key=$Value"
}

# 4. Every secret must be set before Docker Compose can start.
$Final = @{}
foreach ($l in $Lines) { if ($l -match '^([A-Z0-9_]+)=(.*)$') { $Final[$Matches[1]] = $Matches[2] } }
$Missing = $SecretKeys | Where-Object { -not $Final.ContainsKey($_) -or [string]::IsNullOrWhiteSpace($Final[$_]) }
if ($Missing) { throw "These keys are missing from .env.example: $($Missing -join ', ')" }

[System.IO.File]::WriteAllText($EnvPath, (($Lines -join "`n").TrimEnd() + "`n"), $Utf8NoBom)
if ($Generated) { Write-Host "INFO: generated secrets for $($Generated -join ', ')" -ForegroundColor DarkGray }
Write-Host 'PASS: local .env is ready. Existing non-placeholder secrets were preserved.' -ForegroundColor Green

# 5. Python environment.
$PythonExe = Join-Path $Root '.venv/Scripts/python.exe'
if (-not (Test-Path -LiteralPath $PythonExe)) {
  if (-not (Get-Command python -ErrorAction SilentlyContinue)) { throw 'Python 3.10+ was not found on PATH.' }
  python -m venv .venv
  if ($LASTEXITCODE -ne 0) { throw 'Could not create .venv. Check your Python installation.' }
}
& $PythonExe -c "import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)"
if ($LASTEXITCODE -ne 0) { throw 'The .venv uses Python < 3.10. Delete .venv and rerun with Python 3.10+.' }

$Requirements = Join-Path $Root 'requirements.txt'
if (-not (Test-Path -LiteralPath $Requirements)) { throw 'requirements.txt is missing from the project root.' }
& $PythonExe -m pip install --disable-pip-version-check -q -r $Requirements
if ($LASTEXITCODE -ne 0) { throw 'Python dependency installation failed.' }

Write-Host 'PASS: Python environment and required dependencies are ready.' -ForegroundColor Green
Write-Host 'Next command: docker compose up -d --build' -ForegroundColor Cyan
Write-Host 'Keep .env private; do not commit or share it.' -ForegroundColor Yellow