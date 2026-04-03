return @{

    title="Username`nPassword" #optional: if not given, the folder's name is used

    description = "Request localadmin login" #optional: detault is empty

    isSelected = $true  #optional: default is false, only used if a profile does not specify this

    hasValue = $TRUE   #optional: shows a text field next to the value
    Value = "localadmin"  #optional: if given, the textbox will be prefilled

    hasValue2 = $TRUE   #optional: shows a text field next to the value
    Value2 = "********"  #optional: if given, the textbox will be prefilled

    # required
    installFn = {
        param($ctx, [string]$user, [string]$pass)


        #$ctx.Credentials = $creds

        Show-MessageBox "Not implemented" "WARNING"

        Write-Host "nothing yet"

        #$ctx.doCancel = $true


        return $ctx
    }
}