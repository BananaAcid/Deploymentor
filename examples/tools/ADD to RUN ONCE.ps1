param($ctxFileName)

#Write-Host "Context from file:" ($ctxFileName | ConvertTo-Json)

$ctx = Import-CliXml -Path $ctxFileName

# Write-Host ($ctx | ConvertTo-Json)

Write-Host "Adding to Run once, with current profile '$($ctx.activeProfile.Title)' (Index: $($ctx.activeProfile.Index))"

Set-RunOnce -Params "-Profile '$($ctx.activeProfile.Title -replace "'", "`'")'" | Write-Host
