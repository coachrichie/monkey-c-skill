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

Write-Output "Repository contracts passed ($((Get-AssertionCount)) assertions)"
