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

Write-Output "Repository contracts passed ($((Get-AssertionCount)) assertions)"
