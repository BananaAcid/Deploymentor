# Fix for -> Write-Error: Failed to generate the compressed file for module 'Cannot index into a null array.'.
$env:DOTNET_CLI_UI_LANGUAGE="en_US"

# pack all files from this repo
Update-ModuleManifest -Path ".\Deploymentor.psd1" -FileList $(git ls-files | ForEach-Object { Get-Item "$_" })

Test-ModuleManifest -Path ".\Deploymentor.psd1"
pause
Publish-Module -Path ".\" -NuGetApiKey $env:NUGET_API_KEY -Verbose

<#
# find module
Find-Module Deploymentor

# Import test
Import-Module .\Deploymentor
#>



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
xaml gui visual-studio dotnet powershell wpf desktop-application rapid-prototyping powershell-module ui-framework xaml-gui
#>

<#
Invoke-PS2EXE -InputFile "MyScript.ps1" -OutputFile "MyApp.exe" -Title "Custom Title" -Description "My Branded App"
#>