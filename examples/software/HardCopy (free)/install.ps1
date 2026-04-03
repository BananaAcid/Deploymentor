return @{

    #title="overwrite with this" #optional: if not given, the folder's name is used

    description = "free edition, v2019.01.14" #optional: detault is empty

    icon = ".\Hardcopy 2019.01.14.exe" #optional: default is default-app.png

    isSelected = $TRUE  #optional: default is false, only used if a profile does not specify this

    # Download: 
    #  Docs: http://www.info.hardcopy.de/einstellungen_verteilen.php
    #  Link: https://hardcopy.de/hc.exe

    # required
    installFn = {
        # NOT ABLE TO WAIT - DOES NOT CLOSE AFTER INSTALL END
        echo "installing HardCopy + config file"
        copy ".\hardcopy_config.ini" "C:\IT\hardcopy_config.ini" -Force
        Start-Process ".\Hardcopy 2019.01.14.exe" "/GlobalSettingsFile=C:\IT\hardcopy_config.ini"
    }
}