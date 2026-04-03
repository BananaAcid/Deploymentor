return @{

    #title="overwrite with this" #optional: if not given, the folder's name is used

    description = "v26.00 (2026-02-12)" #optional: detault is empty

    icon = ".\7z2600-x64.exe" #optional: default is default-app.png

    isSelected = $TRUE  #optional: default is false, only used if a profile does not specify this

    # download:
    #  page: https://www.7-zip.org/download.html
    #  link: https://www.7-zip.org/a/7z2600-x64.exe

    # required
    installFn = {
        Start-Process ".\7z2600-x64.exe" "/S /qn -" -Wait
    }
}