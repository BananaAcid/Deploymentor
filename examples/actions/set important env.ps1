return @{

    title="Important environment variables" #optional: if not given, the folder's name is used

    description = "Set global environment variable IMPORTANT_VAR,`ndefault is `"$($Global:IMPORTANT_VAR)`"" #optional: detault is empty

    isSelected = $true  #optional: default is false, only used if a profile does not specify this

    hasValue = $TRUE
    value = $Global:IMPORTANT_VAR

    # required
    installFn = {
        Param($ctx, $value1)

        echo "set global env IMPORTANT_VAR: $value1"
        [System.Environment]::SetEnvironmentVariable('IMPORTANT_VAR',$value1,[System.EnvironmentVariableTarget]::Machine)
    }
}