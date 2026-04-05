
return @{

    title = "Check IP Protocols"
    
    description = "Checks if IPv4 and IPv6 are enabled on network adapters"

    isSelected = $false

    installFn = {
        param([System.Collections.Hashtable]$ctx)
        
        Write-Host "Checking IP Protocol Status...`n"
        
        # Get all network adapters with IP enabled
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        
        $ipv4Enabled = $false
        $ipv6Enabled = $false
        
        foreach ($adapter in $adapters) {
            $ipConfig = Get-NetIPInterface -InterfaceIndex $adapter.InterfaceIndex -ErrorAction SilentlyContinue
            
            foreach ($ip in $ipConfig) {
                if ($ip.AddressFamily -eq "IPv4" -and $ip.ConnectionState -eq "Connected") {
                    $ipv4Enabled = $true
                }
                if ($ip.AddressFamily -eq "IPv6" -and $ip.ConnectionState -eq "Connected") {
                    $ipv6Enabled = $true
                }
            }
        }
        
        # Also check if IPv6 is disabled at system level via registry
        $ipv6DisabledReg = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -ErrorAction SilentlyContinue
        
        $result = @"
╔══════════════════════════════════════╗
║        IP Protocol Status            ║
╠══════════════════════════════════════╣
║  IPv4: $($(if($ipv4Enabled){"Enabled "}else{"Disabled"}) )                 ║
║  IPv6: $($(if($ipv6Enabled -and -not $ipv6DisabledReg){"Enabled "}else{"Disabled"}) )                 ║
╚══════════════════════════════════════╝
"@
        
        Write-Host $result
    }
}

