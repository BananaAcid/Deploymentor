param($ctx)

write-host "--------Start--------"

Write-Host "CTX", $ctx

$ctx | ConvertTo-Json -Depth 10 | Write-Host -ForegroundColor DarkGreen

Write-Host "ctx.lastExecResults.Count: ", $ctx.lastExecResults.Count

$ctx.lastExecResults | Format-List | Out-String | Write-Host -ForegroundColor DarkBlue 


write-host "--------DOne--------"