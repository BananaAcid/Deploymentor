return @{

    title="Message: Plug network cable" #optional: if not given, the folder's name is used

    isSelected = $false  #optional: default is false, only used if a profile does not specify this

    # required
    installFn = {
        param($ctx)

        echo "*********************************************************************"
        echo " Warning `r`n`r`n Plug in network cable! `r`n`r`n And WAIT until icon status is OK!"
        echo "*********************************************************************"
        
        Show-MessageBox "Warning `r`n`r`n Plug in network cable! `r`n`r`n And WAIT until icon status is OK!" "WARNING"

        #Read-Host -Prompt "Press Enter to continue..."
    }
}