
return @{
    title = "Check Office Versions"
    description = "Checks installed Office versions and stores them in `$Global:CurrentOfficeVersions"

    isSelected = $FALSE  

    installFn = {
        param($ctx)

        # Check installed Office versions
        $officeVersions = @()
        Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*Microsoft Office*" } | ForEach-Object {
            $officeVersions += $_.Version
        }

        # Store in Global variable
        $Global:CurrentOfficeVersions = $officeVersions

        Write-Host "Office versions:`n$($officeVersions -join "`n")"
        #Show-MessageBox "Office versions checked.`n$($officeVersions -join "`n")" $title
    }
}

