# Fix for -> Write-Error: Failed to generate the compressed file for module 'Cannot index into a null array.'.
$env:DOTNET_CLI_UI_LANGUAGE="en_US"

# pack all files from this repo -- no use ..
#Update-ModuleManifest -Path ".\Deploymentor.psd1" -FileList $(git ls-files | ForEach-Object { Get-Item "$_" })

# create build dir
Remove-Item -r -fo .\build -ErrorAction SilentlyContinue
Write-Host "Creating build dir" -ForegroundColor Yellow
git ls-files | ForEach-Object { 
    $fullPath = Join-Path -Path 'build\Deploymentor' -ChildPath $_
    $folderPath = Split-Path -Path $fullPath -Parent
    mkdir $folderPath -Force -ErrorAction SilentlyContinue | Out-Null
    Copy-Item -Path $_ -Destination $fullPath
}

Test-ModuleManifest -Path ".\build\Deploymentor\Deploymentor.psd1"
pause
Publish-Module -Path ".\build\Deploymentor" -NuGetApiKey $env:NUGET_API_KEY -Verbose

Write-Host "Done - DELETE BUILD DIR?"  -ForegroundColor Red
pause
Remove-Item -r -fo .\build



<# 
New-ModuleManifest -Path ".\Deploymentor.psd1" `
    -RootModule "Deploymentor.psm1" `
    -Author "Nabil Redmann (BananaAcid)" `
    -Description "A full PowerShell installation helper GUI - fully configurable and simple / quick to use for roll outs 🤖" `
    -CompanyName "Nabil Redmann" `
    -Copyright '(c) Nabil Redmann (BananaAcid). All rights reserved.' `
    -ModuleVersion "1.2.0" `
    -FunctionsToExport "*" `
    -CmdletsToExport '*' `
    -PowerShellVersion "5.1" `
    -CompatiblePSEditions "Desktop","Core" `
    -FileList $(git ls-files | ForEach-Object { Get-Item "$_" }) `
    -LicenseUri 'https://github.com/BananaAcid/Deploymentor/blob/main/LICENSE' `
    -ProjectUri 'https://github.com/BananaAcid/Deploymentor' `
    -ReleaseNotes 'https://github.com/BananaAcid/Deploymentor' `
    -Tags @( `
        "deployment", `
        "gui", `
        "rollout", `
        "utility", `
        "tools", `
        "installation" `
    )


#>


<#
# find module
Find-Module Deploymentor

# Import test
Import-Module .\Deploymentor
#>


<#
Invoke-PS2EXE -InputFile "MyScript.ps1" -OutputFile "MyApp.exe" -Title "Custom Title" -Description "My Branded App"
#>