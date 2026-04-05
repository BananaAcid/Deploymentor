@{
    Title = "Relogin User"
    Title2 = "Password"
    
    Description = "Continue Phase 2, after reboot"

    hasValue = $true
    Value = $env:USERNAME
    
    hasValue2 = $true
    Value2 = $password

    installFn = {
        param ( $ctx, <#Value#>[string]$username, <#Value2#>[string]$password )

        Run-Once "-executionpolicy bypass -file $PSScriptRoot\Deploymentor.ps1" -Params "-Config '$PSScriptRoot\data\config.ps1' -Profile *Second -AutoStart all"

        # Set registry keys for AutoAdminLogon -- VALUES MUST BE REMOVED AFTER RESTART -> Another action for cleanup
        $path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        Set-ItemProperty -Path $path -Name "AutoAdminLogon" -Value "1"
        Set-ItemProperty -Path $path -Name "DefaultUserName" -Value $username
        Set-ItemProperty -Path $path -Name "DefaultPassword" -Value $password
        Set-ItemProperty -Path $path -Name "DefaultDomainName" -Value "$env:USERDOMAIN" # To force local acount: "."

        shutdown /r /t 10 /f /e "Rollout - Phase 2"
        Exit 0
    }
}