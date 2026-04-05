@{
    Title = ""
    Description = "Continue Phase 2 - END"

    installFn = {
        param ( $ctx )

        # ReSet registry keys for AutoAdminLogon -- VALUES MUST BE REMOVED AFTER RESTART
        $path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        Set-ItemProperty -Path $path -Name "AutoAdminLogon" -Value "0"
        Set-ItemProperty -Path $path -Name "DefaultUserName" -Value ""
        Set-ItemProperty -Path $path -Name "DefaultPassword" -Value ""
        # Keep Domain?
        #Set-ItemProperty -Path $path -Name "DefaultDomainName" -Value "$env:USERDOMAIN" # To force local acount: "."
    }
}