# Executed on the Windows test machine by run-tests.sh.
param([string]$TargetHost, [int]$Port, [string]$Label, [string]$PqTest, [string]$TestsRoot, [bool]$Encrypt = $false)
$pq = $PqTest
Set-Location (Join-Path $TestsRoot 'Tests\Settings')

$paramFile = '..\ParameterQueries\ClickHouseAdbc.parameterquery.pq'
$src = Get-Content $paramFile -Raw
$src = $src -replace 'Server = "[^"]*"', ('Server = "' + $TargetHost + '"')
$src = $src -replace 'Port = \d+', ('Port = ' + $Port)
Set-Content $paramFile $src -Encoding utf8

$tpl = & $pq credential-template -e ..\..\ClickHouse.mez -q $paramFile -ak UsernamePassword
# The connector is encrypted by default; test targets are typically plaintext dev servers,
# so the stored credential must state the choice explicitly.
$j = $tpl | ConvertFrom-Json
$j.AuthenticationProperties.Username = 'default'
$j.AuthenticationProperties.Password = 'clickhouse'
$j.AuthenticationProperties | Add-Member -NotePropertyName EncryptConnection -NotePropertyValue $Encrypt -Force
($j | ConvertTo-Json -Compress) | & $pq set-credential -e ..\..\ClickHouse.mez -q $paramFile | Out-Null

$pass = 0; $fail = 0
foreach ($s in Get-ChildItem *.testsettings.json | Where-Object Name -notlike '*Comparison*') {
    $r = & $pq compare -e ..\..\ClickHouse.mez -sf $s.Name -fomof | ConvertFrom-Json
    foreach ($t in $r) {
        if ($t.Status -eq 'Passed') { $pass++ }
        else {
            $fail++
            Write-Output ('  FAIL: ' + $t.Name)
            if ($t.Output -and $t.Output[0].SerializedSource) {
                $v = $t.Output[0].SerializedSource
                Write-Output ('    got: ' + $v.Substring(0, [Math]::Min(160, $v.Length)))
            }
        }
    }
}
Write-Output ("[$Label] PASSED=$pass FAILED=$fail")
if ($fail -gt 0) { exit 1 }
