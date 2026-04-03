return @{

    title="Set new `Administrator` PW" #optional: if not given, the folder's name is used

    description = "Set the local `"Administrator`" password" #optional: detault is empty

    isSelected = $false  #optional: default is false, only used if a profile does not specify this

    hasValue = $TRUE
    value = ""

    # required
    installFn = {
        Param($ctx, [string]$value1)

        echo "New password for 'Administrator': $value1"

        $Password = $value1 | ConvertTo-SecureString
        Set-LocalUser -Name "Administrator" -Password $Password
    }
}