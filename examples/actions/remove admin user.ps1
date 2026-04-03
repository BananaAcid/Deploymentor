return @{

    title="Remove `"admin`" user" #optional: if not given, the folder's name is used

    description = "Removes the local `"admin`" profile" #optional: detault is empty

    isSelected = $false  #optional: default is false, only used if a profile does not specify this

    # required
    installFn = {
        echo "Remove `"admin`" user"
        Remove-LocalGroupMember admin -Group "Administratoren" # most european variants
        Remove-LocalGroupMember admin -Group "Administrators"  #  are these
    }
}