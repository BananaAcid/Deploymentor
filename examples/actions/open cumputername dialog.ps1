return @{

    title="Open cumputer name dialog" #optional: if not given, the folder's name is used

    description = "Starts SystemPropertiesComputerName.exe" #optional: detault is empty

    isSelected = $true  #optional: default is false, only used if a profile does not specify this

    # required
    installFn = {
        Param($ctx)

        echo "Open cumputer name dialog"
        Start-Process SystemPropertiesComputerName.exe -Wait
    }
}