return @{

    title="Disable IPv6" #optional: if not given, the folder's name is used

    description = "Disables IPv6 on all currently installed adapters" #optional: detault is empty

    isSelected = $true  #optional: default is false, only used if a profile does not specify this

    # required
    installFn = {
        echo "Disable IPv6"
        Get-NetAdapterBinding -ComponentID ms_tcpip6 |% Name | %{Disable-NetAdapterBinding -Name $_ -ComponentID ms_tcpip6}
    }
}