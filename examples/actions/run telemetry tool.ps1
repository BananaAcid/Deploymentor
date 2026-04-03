return @{

    title="Run telemetry tool" #optional: if not given, the folder's name is used

    description = "Starts O&O ShutUp10++ (Win10 + Win11) and imports config - then closes" #optional: detault is empty

    isSelected = $true  #optional: default is false, only used if a profile does not specify this

    # required
    installFn = {
        Param($ctx)

        echo "run telemetry tool to with config"
        Start-Process "$($ctx.dir.software)\OOSU\OOSU10.exe" -ArgumentList "`"$($ctx.dir.software)\OOSU\export.cfg`" /quiet" -Wait
    }
}