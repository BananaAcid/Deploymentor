return @{

    title="Acrobat Reader" #optional: if not given, the folder's name is used

    description = "Version 2025.001.21223" #optional: detault is empty

    icon = ".\Reader_en_install.exe" #optional: default is default-app.png

    isSelected = $TRUE  #optional: default is false, only used if a profile does not specify this

    # required
    installFn = {
        param( $ctx )

        if (-not (Test-Path  .\Reader_en_install.exe)) {
            # open download page
            start "https://get.adobe.com/de/reader/download?os=Windows+11&name=Reader+2025.001.21223+English+for+Windows+%28Recommended%29&lang=en&nativeOs=Windows+10&accepted=&declined=mss%2Ccr%2Chrm&preInstalled=&site=otherversions"
            # open current folder in explorer
            start ".\"
            # wait for user
            Show-MessageBox "Press ok after download to the correct folder: `nThe installer will be run with silent options afterwards." -Title "Acrobat Reader Setup missing"
        }

        Start-Process ".\Reader_en_install.exe /sPB /rs /msi" -Wait
    }
}