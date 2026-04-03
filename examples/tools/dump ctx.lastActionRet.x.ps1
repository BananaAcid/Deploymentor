param($ctx)

write-host "--------Start--------"

Write-Host "PWD", $PWD

$ctx | ConvertTo-Json -Depth 10 | Write-Host -ForegroundColor DarkGreen

Write-Host "ctx.lastExecResults.Count: ", $ctx.lastExecResults.Count

#$ctx.lastExecResults | Format-List | Out-String | Write-Host -ForegroundColor DarkBlue 


write-host "--------XML-"

ConvertTo-NiceXml $ctx -RootName "Context" -Indent $true | Write-Host

write-host "--------DOne--------"