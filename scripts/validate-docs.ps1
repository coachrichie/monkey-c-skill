[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$CacheRoot,
    [Parameter(Mandatory)][string]$ExpectedPages
)

$ErrorActionPreference = 'Stop'
$cache = [IO.Path]::GetFullPath($CacheRoot)
$expected = Get-Content -LiteralPath $ExpectedPages -Raw | ConvertFrom-Json
$missing = [Collections.Generic.List[string]]::new()
$broken = [Collections.Generic.List[string]]::new()

function Get-LocalPath([string]$Group, [string]$PagePath) {
    if ($Group -eq 'api-docs') { return Join-Path $cache "$Group/$PagePath" }
    $suffix = if ([string]::IsNullOrWhiteSpace($PagePath)) { 'index.html' } else { "$($PagePath.TrimEnd('/'))/index.html" }
    return Join-Path $cache "$Group/$suffix"
}

foreach ($item in @(
    @{name='monkey-c'; data=$expected.monkeyC},
    @{name='core-topics'; data=$expected.coreTopics},
    @{name='api-docs'; data=$expected.apiDocs}
)) {
    foreach ($page in $item.data.pages) {
        $target = Get-LocalPath $item.name $page.path
        if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { $missing.Add("$($item.name)/$($page.path)") }
    }
}

$files = @(Get-ChildItem -LiteralPath $cache -File -Recurse -ErrorAction SilentlyContinue)
foreach ($file in $files | Where-Object Extension -eq '.html') {
    $text = Get-Content -LiteralPath $file.FullName -Raw
    $relativeFile = [IO.Path]::GetRelativePath($cache, $file.FullName)
    $groupRoot = Join-Path $cache (($relativeFile -split '[\\/]')[0])
    foreach ($match in [regex]::Matches($text, '(?:href|src)=["'']([^"''#?]+)', 'IgnoreCase')) {
        $value = $match.Groups[1].Value
        if ($value -match '^(?:[a-z]+:|//|/)') { continue }
        $target = [IO.Path]::GetFullPath((Join-Path $file.DirectoryName $value.Replace('/', [IO.Path]::DirectorySeparatorChar)))
        if (-not $target.StartsWith([IO.Path]::GetFullPath($groupRoot), [StringComparison]::OrdinalIgnoreCase)) {
            continue
        } elseif (-not (Test-Path -LiteralPath $target)) {
            $broken.Add("$($file.FullName) -> $value")
        }
    }
}

$duplicateGroups = @($files | Where-Object Name -ne 'manifest.json' | Group-Object { (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash } | Where-Object Count -gt 1)
if ($missing.Count -or $broken.Count -or $duplicateGroups.Count) {
    $details = @($missing | ForEach-Object { "missing: $_" }) + @($broken | ForEach-Object { "broken: $_" }) + @($duplicateGroups | ForEach-Object { "duplicate hash: $($_.Name)" })
    throw "Documentation validation failed: missing=$($missing.Count) broken=$($broken.Count) duplicates=$($duplicateGroups.Count)`n$($details -join "`n")"
}

[pscustomobject]@{
    Files = $files.Count
    Html = @($files | Where-Object Extension -eq '.html').Count
    Bytes = ($files | Measure-Object Length -Sum).Sum
    Missing = 0
    BrokenLinks = 0
    DuplicateGroups = 0
}
