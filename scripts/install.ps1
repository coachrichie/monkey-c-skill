[CmdletBinding()]
param(
    [string]$CodexHome,
    [switch]$Sync,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$sourceRoot = Split-Path $PSScriptRoot -Parent
if ([string]::IsNullOrWhiteSpace($CodexHome)) {
    $CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' }
}
$target = [IO.Path]::GetFullPath((Join-Path $CodexHome 'skills/monkey-c'))
$marker = Join-Path $target '.monkey-c-skill-install.json'

if (Test-Path -LiteralPath $target) {
    if (-not (Test-Path -LiteralPath $marker)) {
        throw "Refusing to overwrite unrelated directory: $target"
    }
    if (-not $Force) {
        throw "Monkey C is already installed. Re-run with -Force to update: $target"
    }
}

$cacheBackup = $null
if (Test-Path -LiteralPath (Join-Path $target 'references/.generated')) {
    $cacheBackup = Join-Path ([IO.Path]::GetTempPath()) ("monkey-c-cache-" + [guid]::NewGuid())
    Move-Item -LiteralPath (Join-Path $target 'references/.generated') -Destination $cacheBackup
}

try {
    if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $target, (Join-Path $target 'agents'), (Join-Path $target 'references'), (Join-Path $target 'scripts') | Out-Null
    Copy-Item -LiteralPath (Join-Path $sourceRoot 'SKILL.md') -Destination $target
    Copy-Item -LiteralPath (Join-Path $sourceRoot 'agents/openai.yaml') -Destination (Join-Path $target 'agents')
    Get-ChildItem -LiteralPath (Join-Path $sourceRoot 'references') -Filter '*.md' -File | Copy-Item -Destination (Join-Path $target 'references')
    foreach ($scriptName in 'install.ps1','sync-docs.ps1','validate-docs.ps1') {
        Copy-Item -LiteralPath (Join-Path $sourceRoot "scripts/$scriptName") -Destination (Join-Path $target 'scripts')
    }
    Copy-Item -LiteralPath (Join-Path $sourceRoot 'tests/expected-pages.json') -Destination (Join-Path $target 'scripts/expected-pages.json')
    if ($cacheBackup) {
        Move-Item -LiteralPath $cacheBackup -Destination (Join-Path $target 'references/.generated')
        $cacheBackup = $null
    }
    [pscustomobject]@{
        repository = 'https://github.com/coachrichie/monkey-c-skill'
        schemaVersion = 1
        installedAt = [DateTimeOffset]::UtcNow.ToString('o')
    } | ConvertTo-Json | Set-Content -LiteralPath $marker -Encoding utf8
    if ($Sync) {
        & (Join-Path $target 'scripts/sync-docs.ps1') -ExpectedPages (Join-Path $target 'scripts/expected-pages.json') | Out-Null
    }
    Write-Output "Installed Monkey C skill to $target"
} finally {
    if ($cacheBackup -and (Test-Path -LiteralPath $cacheBackup)) {
        New-Item -ItemType Directory -Force -Path (Split-Path (Join-Path $target 'references/.generated') -Parent) | Out-Null
        Move-Item -LiteralPath $cacheBackup -Destination (Join-Path $target 'references/.generated') -Force
    }
}
