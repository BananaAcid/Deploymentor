return @{

    title="Title`nMessage" #optional: if not given, the folder's name is used

    description = "Shows a messagebox" #optional: detault is empty

    isSelected = $true  #optional: default is false, only used if a profile does not specify this

    # hasValue = $TRUE   #optional: shows a text field next to the value
    # Value = "Title"  #optional: if given, the textbox will be prefilled

    # hasValue2 = $TRUE   #optional: shows a text field next to the value
    # Value2 = "Message"  #optional: if given, the textbox will be prefilled


    # instead of hasValue and Value, the installFn params can be used, with defaults as string

    # required
    installFn = {
        param($ctx, [string]$title, [string]$message = "Default message")


        #Import-LocalModule XAMLgui -Path ..\ps_modules

        write-Host "show message: PWD", $PWD

        
        Write-Host "Messagebox: $title`n$message"
        Show-MessageBox $message $title
    }
}