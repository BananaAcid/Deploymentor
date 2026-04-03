
#! NOT working


return @{

    title="restart with Admin privileges" #optional: if not given, the folder's name is used

    isSelected = $false  #optional: default is false, only used if a profile does not specify this

    # required
    installFn = {
        param($ctx)

        # guard
        if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { return }


        $global:DoCancel = $true

     
        echo "*********************************************************************"
        echo " Warning: administrator rights required!"
        echo "*********************************************************************"

        
        
        Show-MessageBox "Warning:`r`n`r`n ADMIN PRIVILEGES REQUIRED! `r`n`r`n Starting GUI again ..." "WARNING" -Type "Asterisk"

        
        $currentShell, $avail = Get-PowershellInterpreter
        
        $argList = "-Command '.\deploymentor.ps1 -Profile $($ctx.activeProfile.Index) ; pause'"

        Start-Process $currentShell -ArgumentList $argList -Verb RunAs
        
        
        #Exit-PSHostProcess
    }
}