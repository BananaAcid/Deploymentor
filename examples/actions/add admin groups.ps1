return @{

    title="Add Administrator groups" #optional: if not given, the folder's name is used

    isSelected = $false  #optional: default is false, only used if a profile does not specify this

    hasValue = $TRUE
    value = $Global:adminGroups -join " "

    # required
    installFn = {
        Param($ctx, $value1)

        If ($value1) {
            echo "Add user to Administrator group: $value1"

            $value1 -split " " |% { Add-LocalGroupMember -Group "Administratoren" -Member $_ } 
        }
    }
}