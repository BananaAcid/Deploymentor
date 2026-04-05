return @{

    title = "Get Public IP"
    
    description = "Retrieves the current public internet IP address and stores it in `$Global:CurrentOnlineIP"

    isSelected = $false

    # No user input needed - this is automatic detection
    hasValue = $false
    hasValue2 = $false

    installFn = {
        param([System.Collections.Hashtable]$ctx)

        Write-Host "Detecting public IP address..."

        try {
            # Try multiple IP detection services for reliability
            $ipServices = @(
                "https://ipinfo.io/ip",
                "https://ifconfig.me/ip",
                "https://icanhazip.com",
                "https://api.ipify.org"
            )

            $publicIP = $null

            foreach ($service in $ipServices) {
                try {
                    Write-Host "  Trying $service ..."
                    $publicIP = (Invoke-RestMethod -Uri $service -TimeoutSec 10 -ErrorAction Stop).Trim()
                    
                    if ($publicIP -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
                        Write-Host "  ✓ Success: $publicIP"
                        break
                    }
                }
                catch {
                    Write-Host "  ✗ Failed: $($_.Exception.Message)"
                    continue
                }
            }

            if (-not $publicIP) {
                throw "Could not retrieve public IP from any service"
            }

            # Store in global variable as requested
            $Global:CurrentOnlineIP = $publicIP

            Write-Host "`nPublic IP detected and stored:"
            Write-Host "  `$Global:CurrentOnlineIP = '$publicIP'"
        }
        catch {
            Write-Host "ERROR: Failed to get public IP: $($_.Exception.Message)" -ForegroundColor Red
            
            $Global:CurrentOnlineIP = $null
        }
    }
}


