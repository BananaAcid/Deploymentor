param ($ctx)

Write-Host "_CTX_", ($ctx | Select-Object * | Format-List | Out-String)

Write-Host "PWD", $PWD

Write-Host "PSCommandPath", $PSCommandPath
Write-Host "PSScriptRoot", $PSScriptRoot
Write-Host "PSSessionApplicationName", $PSSessionApplicationName

Write-Host "_Invocation_", ($MyInvocation | Select-Object * | Format-List | Out-String)

