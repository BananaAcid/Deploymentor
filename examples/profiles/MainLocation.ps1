$Global:IMPORTANT_VAR = "MAINLOCATION"
$Global:adminGroups = @("MLOC\AdminOU", "MLOC\AdminPC")
$Global:printerDefaultDomain = "\\printer100\"

return @{

    title = "MainLocation"  # optional

    actionsFirst = $false

    # folders in .\software to be highlighted
    software = @(
        "HardCopy (free)",
        @{Name="OOSU10"; isSelected=$true},
        "AcrobatReader",
        "7Zip",
        @{Name="BIOS"; isSelected=$false}

    )

    # files in .\actions to be highlighted
    actions = @(
        "require admin.ps1",
        @{Name="require admin by dialog.ps1"; isSelected=$false}
        "set important env.ps1",
        "remove admin user.ps1",
        "set new Administrator PW.ps1",

        "add user as admin.ps1",

        "run telemetry tool.ps1",
        "remove unneded c dirs.ps1",
        "service files patch.ps1",
        "remove default apps.ps1",
        @{Name="msg plug cable.ps1"; isSelected=$true},
        "disable iv6.ps1"
        "open cumputername dialog.ps1",

        "install dell bios patch and restart.ps1"

        "show message.ps1"
    )

}