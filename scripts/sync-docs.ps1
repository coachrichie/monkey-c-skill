[CmdletBinding()]
param(
    [string]$Destination = (Join-Path $PSScriptRoot '..\references\.generated'),
    [hashtable]$BaseUrlMap = @{
        monkeyC = 'https://developer.garmin.com/connect-iq/monkey-c/'
        coreTopics = 'https://developer.garmin.com/connect-iq/core-topics/'
        apiDocs = 'https://developer.garmin.com/connect-iq/api-docs/'
    },
    [string]$ExpectedPages,
    [switch]$SkipApiDocs
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ExpectedPages)) {
    $packagedManifest = Join-Path $PSScriptRoot 'expected-pages.json'
    $ExpectedPages = if (Test-Path -LiteralPath $packagedManifest) { $packagedManifest } else { Join-Path $PSScriptRoot '..\tests\expected-pages.json' }
}
$destinationRoot = [IO.Path]::GetFullPath($Destination)
$parent = Split-Path $destinationRoot -Parent
$staging = Join-Path $parent ('.staging-' + [guid]::NewGuid())
$backup = "$destinationRoot.backup"
$expected = Get-Content -LiteralPath $ExpectedPages -Raw | ConvertFrom-Json
$http = [Net.Http.HttpClient]::new()
$records = [Collections.Generic.List[object]]::new()

$groups = @(
    @{ key='monkeyC'; folder='monkey-c'; base=[Uri]$BaseUrlMap.monkeyC; pages=$expected.monkeyC.pages },
    @{ key='coreTopics'; folder='core-topics'; base=[Uri]$BaseUrlMap.coreTopics; pages=$expected.coreTopics.pages },
    @{ key='apiDocs'; folder='api-docs'; base=[Uri]$BaseUrlMap.apiDocs; pages=$expected.apiDocs.pages }
)
if ($SkipApiDocs) { $groups = @($groups | Where-Object key -ne 'apiDocs') }

function Resolve-Target([string]$Folder, [Uri]$Base, [Uri]$Uri) {
    if ($Uri.Host -ne $Base.Host -or -not $Uri.AbsolutePath.StartsWith($Base.AbsolutePath, [StringComparison]::Ordinal)) { return $null }
    $relative = [Uri]::UnescapeDataString($Uri.AbsolutePath.Substring($Base.AbsolutePath.Length))
    if ($relative -match '(^|[\\/])\.\.([\\/]|$)') { return $null }
    if ([string]::IsNullOrWhiteSpace($relative) -or $relative.EndsWith('/')) { $relative += 'index.html' }
    $candidate = [IO.Path]::GetFullPath((Join-Path $staging "$Folder/$($relative.Replace('/', [IO.Path]::DirectorySeparatorChar))"))
    if (-not $candidate.StartsWith([IO.Path]::GetFullPath($staging), [StringComparison]::OrdinalIgnoreCase)) { return $null }
    return $candidate
}

try {
    New-Item -ItemType Directory -Force -Path $staging | Out-Null
    foreach ($group in $groups) {
        $queue = [Collections.Generic.Queue[Uri]]::new()
        $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($page in $group.pages) { $queue.Enqueue([Uri]::new($group.base, [string]$page.path)) }

        while ($queue.Count) {
            $uri = $queue.Dequeue()
            $canonical = $uri.GetLeftPart([UriPartial]::Path)
            if (-not $seen.Add($canonical)) { continue }
            $target = Resolve-Target $group.folder $group.base $uri
            if (-not $target) { continue }
            $bytes = $http.GetByteArrayAsync($uri).GetAwaiter().GetResult()
            New-Item -ItemType Directory -Force -Path (Split-Path $target -Parent) | Out-Null
            [IO.File]::WriteAllBytes($target, $bytes)
            $records.Add([pscustomobject]@{
                sourceUrl = $canonical
                path = [IO.Path]::GetRelativePath($staging, $target).Replace('\','/')
                sha256 = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant()
                bytes = $bytes.Length
            })

            if ([IO.Path]::GetExtension($target) -eq '.html') {
                $text = [Text.Encoding]::UTF8.GetString($bytes)
                foreach ($match in [regex]::Matches($text, '(?:href|src)=["'']([^"''#?]+)', 'IgnoreCase')) {
                    $value = $match.Groups[1].Value
                    if ($value -match '^(?:data:|mailto:|javascript:)') { continue }
                    try {
                        $candidate = [Uri]::new($uri, $value)
                        if (Resolve-Target $group.folder $group.base $candidate) { $queue.Enqueue($candidate) }
                    } catch {}
                }
            }
        }
    }

    [pscustomobject]@{
        generatedAt = [DateTimeOffset]::UtcNow.ToString('o')
        sources = @($groups | ForEach-Object { $_.base.AbsoluteUri })
        files = @($records)
    } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $staging 'manifest.json') -Encoding utf8

    $validation = & (Join-Path $PSScriptRoot 'validate-docs.ps1') -CacheRoot $staging -ExpectedPages $ExpectedPages
    if (Test-Path -LiteralPath $backup) { Remove-Item -LiteralPath $backup -Recurse -Force }
    if (Test-Path -LiteralPath $destinationRoot) { Move-Item -LiteralPath $destinationRoot -Destination $backup }
    Move-Item -LiteralPath $staging -Destination $destinationRoot
    if (Test-Path -LiteralPath $backup) { Remove-Item -LiteralPath $backup -Recurse -Force }
    [pscustomobject]@{ Destination=$destinationRoot; Files=$validation.Files; Html=$validation.Html; Bytes=$validation.Bytes }
} catch {
    if (Test-Path -LiteralPath $staging) { Remove-Item -LiteralPath $staging -Recurse -Force }
    throw
} finally {
    $http.Dispose()
}
