return @{

    title="Admin privileges required" #optional: if not given, the folder's name is used

    isSelected = $false  #optional: default is false, only used if a profile does not specify this

    # required
    installFn = {
        param($ctx)

        if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
     
            echo "*********************************************************************"
            echo " Warning: administrator rights required!"
            echo "*********************************************************************"

            echo "Press [Cancel] first, then confirm with OK in the message box"

            Show-MessageBox "Warning: administrator rights required! `r`n`r`n Press [Cancel] first, then confirm with OK in the message box" "Warning" -Type "Asterisk"

        }
    }
}