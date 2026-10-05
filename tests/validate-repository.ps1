[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/TestHelpers.ps1"
$root = Split-Path $PSScriptRoot -Parent

$ignorePath = Join-Path $root '.gitignore'
Assert-True (Test-Path -LiteralPath $ignorePath) '.gitignore exists'
$ignore = Get-Content -LiteralPath $ignorePath -Raw
Assert-True ($ignore -match '(?m)^references/\.generated/$') 'generated Garmin cache must be ignored'

$expectedPath = Join-Path $PSScriptRoot 'expected-pages.json'
Assert-True (Test-Path -LiteralPath $expectedPath) 'expected page manifest exists'
$expected = Get-Content -LiteralPath $expectedPath -Raw | ConvertFrom-Json
Assert-Equal 9 @($expected.monkeyC.pages).Count 'Monkey C page count'
Assert-Equal 45 @($expected.coreTopics.pages).Count 'Core Topics page count'
Assert-Equal 3 @($expected.apiDocs.pages).Count 'API seed count'

foreach ($group in 'monkeyC','coreTopics','apiDocs') {
    Assert-True ($expected.$group.baseUrl -match '^https://developer\.garmin\.com/connect-iq/') "$group has official Garmin base URL"
    $groupPaths = @($expected.$group.pages.path)
    Assert-Equal $groupPaths.Count @($groupPaths | Sort-Object -Unique).Count "$group paths must be unique"
    foreach ($page in $expected.$group.pages) {
        Assert-True (-not [string]::IsNullOrWhiteSpace($page.title)) "$group page has title"
        Assert-True (@($page.keywords).Count -gt 0) "$group page has routing keywords"
    }
}

$tracked = @(git -C $root ls-files 'references/.generated/**')
Assert-Equal 0 $tracked.Count 'generated Garmin files must not be tracked'

$skillPath = Join-Path $root 'SKILL.md'
Assert-True (Test-Path -LiteralPath $skillPath) 'SKILL.md exists'
$skill = Get-Content -LiteralPath $skillPath -Raw
Assert-True ($skill -match '(?ms)^---\s*name:\s*monkey-c\s*description:\s*Use when') 'valid skill identity'
foreach ($reference in 'monkey-c-topics.md','core-topics.md','api-routing.md') {
    Assert-True ($skill -match [regex]::Escape($reference)) "SKILL routes to $reference"
    Assert-True (Test-Path -LiteralPath (Join-Path $root "references/$reference")) "$reference exists"
}
Assert-True ($skill -match 'If the generated cache is absent') 'clean-clone fallback is explicit'
Assert-True ($skill -match 'cite the exact Garmin source page') 'source citation is required'

$uiPath = Join-Path $root 'agents/openai.yaml'
Assert-True (Test-Path -LiteralPath $uiPath) 'agents/openai.yaml exists'
$ui = Get-Content -LiteralPath $uiPath -Raw
Assert-True ($ui -match 'display_name:\s*"Monkey C"') 'display name is Monkey C'
Assert-True ($ui -match 'default_prompt:.*\$monkey-c') 'default prompt invokes skill'

foreach ($source in @(
    'https://developer.garmin.com/connect-iq/monkey-c/',
    'https://developer.garmin.com/connect-iq/core-topics/',
    'https://developer.garmin.com/connect-iq/api-docs/'
)) {
    $allReferences = Get-ChildItem (Join-Path $root 'references') -Filter '*.md' -File | Get-Content -Raw
    Assert-True (($allReferences -join "`n") -match [regex]::Escape($source)) "fallback source is indexed: $source"
}

$installer = Join-Path $root 'scripts/install.ps1'
Assert-True (Test-Path -LiteralPath $installer) 'install.ps1 exists'
$tempHome = Join-Path ([IO.Path]::GetTempPath()) ("monkey-c-install-test-" + [guid]::NewGuid())
try {
    & $installer -CodexHome $tempHome | Out-Null
    $installed = Join-Path $tempHome 'skills/monkey-c'
    Assert-True (Test-Path -LiteralPath (Join-Path $installed 'SKILL.md')) 'clean install copied skill'
    Assert-True (Test-Path -LiteralPath (Join-Path $installed '.monkey-c-skill-install.json')) 'install marker written'
    Assert-True (Test-Path -LiteralPath (Join-Path $installed 'scripts/expected-pages.json')) 'runtime page manifest copied'
    $installedSync = Get-Content -LiteralPath (Join-Path $installed 'scripts/sync-docs.ps1') -Raw
    Assert-True ($installedSync -match [regex]::Escape("Join-Path `$PSScriptRoot 'expected-pages.json'")) 'installed sync resolves packaged page manifest'
    foreach ($excluded in '.git','tests','docs','references/.generated') {
        Assert-True (-not (Test-Path -LiteralPath (Join-Path $installed $excluded))) "installer excludes $excluded"
    }

    $collisionHome = Join-Path $tempHome 'collision'
    New-Item -ItemType Directory -Force -Path (Join-Path $collisionHome 'skills/monkey-c') | Out-Null
    Set-Content -LiteralPath (Join-Path $collisionHome 'skills/monkey-c/owned.txt') -Value 'do-not-touch'
    Assert-Throws { & $installer -CodexHome $collisionHome | Out-Null } 'unmarked directory is refused'
    Assert-Equal 'do-not-touch' (Get-Content -LiteralPath (Join-Path $collisionHome 'skills/monkey-c/owned.txt') -Raw).Trim() 'collision remains unchanged'

    New-Item -ItemType Directory -Force -Path (Join-Path $installed 'references/.generated') | Out-Null
    Set-Content -LiteralPath (Join-Path $installed 'references/.generated/sentinel.txt') -Value 'keep-cache'
    & $installer -CodexHome $tempHome -Force | Out-Null
    Assert-Equal 'keep-cache' (Get-Content -LiteralPath (Join-Path $installed 'references/.generated/sentinel.txt') -Raw).Trim() 'forced update preserves cache'
} finally {
    if (Test-Path -LiteralPath $tempHome) { Remove-Item -LiteralPath $tempHome -Recurse -Force }
}

$showcaseFiles = @(
    'README.md','CONTRIBUTING.md','SECURITY.md','LICENSE',
    'docs/installation.md','docs/usage.md','docs/case-study.md','docs/ai-workflow.md',
    'docs/reference-routing.md','docs/maintenance.md','docs/troubleshooting.md','docs/legal.md',
    'assets/architecture.svg','assets/workflow.svg'
)
foreach ($relative in $showcaseFiles) {
    Assert-True (Test-Path -LiteralPath (Join-Path $root $relative)) "showcase file exists: $relative"
}
$readme = Get-Content -LiteralPath (Join-Path $root 'README.md') -Raw
foreach ($required in 'Built with AI, for AI','language question','Core Topics','Toybox API','AI assisted','owner selected the goals','validation-summary:start','case-study.md','architecture.svg') {
    Assert-True ($readme -match [regex]::Escape($required)) "README includes $required"
}
foreach ($svg in 'assets/architecture.svg','assets/workflow.svg') {
    $svgText = Get-Content -LiteralPath (Join-Path $root $svg) -Raw
    Assert-True ($svgText -match '<title>') "$svg has title"
    Assert-True ($svgText -match '<desc>') "$svg has description"
}
$markdownFiles = Get-ChildItem -LiteralPath $root -Filter '*.md' -File -Recurse | Where-Object FullName -notmatch '\.generated'
foreach ($file in $markdownFiles) {
    $text = Get-Content -LiteralPath $file.FullName -Raw
    foreach ($match in [regex]::Matches($text, '\[[^\]]+\]\(([^)#]+)\)')) {
        $value = $match.Groups[1].Value
        if ($value -match '^(?:https?://|mailto:)') { continue }
        $target = [IO.Path]::GetFullPath((Join-Path $file.DirectoryName $value.Replace('/', [IO.Path]::DirectorySeparatorChar)))
        Assert-True (Test-Path -LiteralPath $target) "$($file.Name) link resolves: $value"
    }
}

Write-Output "Repository contracts passed ($((Get-AssertionCount)) assertions)"
