# TestConnection / ValidateConnection path tests, executed on the Windows test machine by
# run-tests.sh. Verifies the probe routing: Flight-first success, immediate credential-failure
# propagation (no fallback masking), legacy fallback for non-Flight ports, and the combined
# two-transport error when nothing answers.
param([string]$TargetHost, [int]$FlightPort, [int]$HttpPort, [string]$Label, [string]$PqTest, [string]$TestsRoot, [string]$FlightEncrypt = 'false')
$pq = $PqTest
$dir = Join-Path $TestsRoot 'ConnTest'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
Set-Location $dir
$mez = Join-Path $TestsRoot 'ClickHouse.mez'

function WriteQuery($name, $port) {
    Set-Content (Join-Path $dir $name) ("let Source = ClickHouse.Database(""$TargetHost"", $port, ""pqtest"") in Source") -Encoding utf8
}
WriteQuery 'cx_flight.pq' $FlightPort
WriteQuery 'cx_http.pq' $HttpPort
WriteQuery 'cx_dead.pq' 59999

function SetCred($q, $pw, $enc) {
    $tpl = & $pq credential-template -e $mez -q $q -ak UsernamePassword | ConvertFrom-Json
    $tpl.AuthenticationProperties.Username = 'default'
    $tpl.AuthenticationProperties.Password = $pw
    $tpl.AuthenticationProperties | Add-Member -NotePropertyName EncryptConnection -NotePropertyValue $enc -Force
    ($tpl | ConvertTo-Json -Compress) | & $pq set-credential -e $mez -q $q | Out-Null
}
$flightEnc = ($FlightEncrypt -eq 'true')
function TC($q) { (& $pq test-connection -e $mez -q $q) -join ' ' | ConvertFrom-Json }

$pass = 0; $fail = 0
function Assert($name, $cond) {
    if ($cond) { $script:pass++ } else { $script:fail++; Write-Output "  FAIL: $name" }
}

SetCred 'cx_flight.pq' 'clickhouse' $flightEnc
$a = TC 'cx_flight.pq'
Assert 'flight-good-credentials' ($a.Status -eq 'Success')

SetCred 'cx_flight.pq' 'WRONG_PASSWORD' $flightEnc
$b = TC 'cx_flight.pq'
Assert 'flight-bad-credentials-fails' ($b.Status -eq 'Failure')
Assert 'flight-bad-credentials-is-credential-error' ($b.Details -match 'credentials')
SetCred 'cx_flight.pq' 'clickhouse' $flightEnc   # restore: same data-source path as the suite credential

SetCred 'cx_http.pq' 'clickhouse' $false
$c = TC 'cx_http.pq'
Assert 'http-legacy-fallback' ($c.Status -eq 'Success')

# Desktop's default shape: encrypted credential against a plaintext HTTP (ODBC) port. The
# Flight-TLS probe hits a protocol mismatch, which must fall through to the legacy transport
# (the ODBC path does not read EncryptConnection).
SetCred 'cx_http.pq' 'clickhouse' $true
$c2 = TC 'cx_http.pq'
Assert 'http-fallback-with-encrypted-credential' ($c2.Status -eq 'Success')
SetCred 'cx_http.pq' 'clickhouse' $false

SetCred 'cx_dead.pq' 'clickhouse' $false
$d = TC 'cx_dead.pq'
Assert 'dead-port-fails' ($d.Status -eq 'Failure')
Assert 'dead-port-reports-both-transports' ($d.Details -match 'Arrow Flight SQL attempt also failed')

Write-Output "[$Label] CONNECTION PASSED=$pass FAILED=$fail"
if ($fail -gt 0) { exit 1 }
