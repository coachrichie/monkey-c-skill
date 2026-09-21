Set-StrictMode -Version Latest
$script:Assertions = 0

function Assert-True([bool]$Condition, [string]$Message) {
    $script:Assertions++
    if (-not $Condition) { throw "ASSERT TRUE FAILED: $Message" }
}

function Assert-Equal($Expected, $Actual, [string]$Message) {
    $script:Assertions++
    if ($Expected -ne $Actual) {
        throw "ASSERT EQUAL FAILED: $Message; expected=$Expected actual=$Actual"
    }
}

function Assert-Throws([scriptblock]$Action, [string]$Message) {
    $script:Assertions++
    try { & $Action } catch { return }
    throw "ASSERT THROWS FAILED: $Message"
}

function Get-AssertionCount { return $script:Assertions }

