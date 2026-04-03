return @{

    title="O&O ShutUp10++ (Win10 + Win11)" #optional: if not given, the folder's name is used

    description = "Disable Windows telemetry" #optional: detault is empty

    icon = "./OOSU10.exe" #optional: default is default-app.png

    isSelected = $TRUE  #optional: default is false, only used if a profile does not specify this

    # Download: 
    #  Docs: https://www.oo-software.com/en/download/current/ooshutup10
    #  Link: https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe

    # required
    installFn = {
        Start-Process "./OOSU10.exe" -Wait
    }
}