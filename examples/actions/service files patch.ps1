return @{

    title="Service files patch" #optional: if not given, the folder's name is used

    description = "Copies service files to C:\Windows\System32\drivers" #optional: detault is empty

    isSelected = $true  #optional: default is false, only used if a profile does not specify this

    # required
    installFn = {
        echo "Service files patch"
        copy .\service files\* C:\Windows\System32\drivers\ -Recurse -force
    }
}