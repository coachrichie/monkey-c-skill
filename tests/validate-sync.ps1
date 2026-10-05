[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/TestHelpers.ps1"
$root = Split-Path $PSScriptRoot -Parent
$sync = Join-Path $root 'scripts/sync-docs.ps1'
Assert-True (Test-Path -LiteralPath $sync) 'sync-docs.ps1 exists'

$temp = Join-Path ([IO.Path]::GetTempPath()) ("monkey-c-sync-test-" + [guid]::NewGuid())
$site = Join-Path $temp 'site'
$cache = Join-Path $temp 'cache'
New-Item -ItemType Directory -Force -Path "$site/monkey-c/functions", "$site/core-topics", "$site/api-docs" | Out-Null
Set-Content -LiteralPath "$site/monkey-c/index.html" -Value '<a href="functions/">Functions</a><a href="/outside/">Outside</a><a href="../../escape.txt">Escape</a>'
Set-Content -LiteralPath "$site/monkey-c/functions/index.html" -Value '<h1 id="functions">Functions</h1>'
Set-Content -LiteralPath "$site/core-topics/index.html" -Value '<h1>Core</h1>'
Set-Content -LiteralPath "$site/api-docs/index.html" -Value '<a href="class_list.html">Classes</a><a href="method_list.html">Methods</a>'
Set-Content -LiteralPath "$site/api-docs/class_list.html" -Value '<h1>Classes</h1>'
Set-Content -LiteralPath "$site/api-docs/method_list.html" -Value '<h1>Methods</h1>'

$expected = @{
    monkeyC = @{ baseUrl = ''; pages = @(@{path='';title='Monkey C';keywords=@('language')}, @{path='functions/';title='Functions';keywords=@('function')}) }
    coreTopics = @{ baseUrl = ''; pages = @(@{path='';title='Core';keywords=@('core')}) }
    apiDocs = @{ baseUrl = ''; pages = @(@{path='index.html';title='API';keywords=@('api')}, @{path='class_list.html';title='Classes';keywords=@('class')}, @{path='method_list.html';title='Methods';keywords=@('method')}) }
}
$expectedPath = Join-Path $temp 'expected.json'
$expected | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $expectedPath

$listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 0)
$listener.Start(); $port = ([Net.IPEndPoint]$listener.LocalEndpoint).Port; $listener.Stop()
$python = (Get-Command python).Source
$server = Start-Process -FilePath $python -ArgumentList '-m','http.server',$port,'--bind','127.0.0.1','--directory',$site -WindowStyle Hidden -PassThru
try {
    $base = "http://127.0.0.1:$port/"
    for ($i=0; $i -lt 30; $i++) {
        try { Invoke-WebRequest -Uri $base -UseBasicParsing | Out-Null; break } catch { Start-Sleep -Milliseconds 100 }
    }
    $map = @{ monkeyC="${base}monkey-c/"; coreTopics="${base}core-topics/"; apiDocs="${base}api-docs/" }
    & $sync -Destination $cache -BaseUrlMap $map -ExpectedPages $expectedPath | Out-Null
    Assert-True (Test-Path -LiteralPath "$cache/monkey-c/index.html") 'Monkey C root downloaded'
    Assert-True (Test-Path -LiteralPath "$cache/monkey-c/functions/index.html") 'child page downloaded'
    Assert-True (-not (Test-Path -LiteralPath "$temp/escape.txt")) 'traversal did not escape cache'
    Assert-True (-not (Test-Path -LiteralPath "$cache/outside")) 'outside prefix rejected'
    Assert-True (Test-Path -LiteralPath "$cache/manifest.json") 'manifest written'

    Set-Content -LiteralPath "$cache/sentinel.txt" -Value 'keep-me'
    $badMap = $map.Clone(); $badMap.coreTopics = "${base}missing/"
    Assert-Throws { & $sync -Destination $cache -BaseUrlMap $badMap -ExpectedPages $expectedPath | Out-Null } 'failed sync throws'
    Assert-Equal 'keep-me' (Get-Content -LiteralPath "$cache/sentinel.txt" -Raw).Trim() 'failed sync preserved cache'
} finally {
    if ($server -and -not $server.HasExited) { Stop-Process -Id $server.Id -Force }
    Remove-Item -LiteralPath $temp -Recurse -Force
}

Write-Output "Synchronization tests passed ($((Get-AssertionCount)) assertions)"
