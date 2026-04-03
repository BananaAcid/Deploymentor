return @{

    title="Install DELL BIOS patch (and restart)" #optional: if not given, the folder's name is used

    description = "The BIOS patcher restarts by itself" #optional: detault is empty

    isSelected = $true  #optional: default is false, only used if a profile does not specify this

    # required
    installFn = {
        Param($ctx)

        Write-Host "Install BIOS patch and restart"
        # get Model Name
        $id = (wmic csproduct get name | Select-String -Pattern "([^\s]*[0-9]+)").Matches[0].Groups[1].Value
        If ($id -ne $Null) {
            $el = Get-ChildItem -Path "$($ctx.dir.software)\BIOS\*$($id)*" -File
            if ($id -ne $Null) {
                & $el
            }
            else {
                Write-Host "BIOS FILE NOT FOUND! $id"
                Start "$($ctx.dir.software)\BIOS"
                Start "https://www.dell.com/support/home/?app=drivers"
                # https://www.dell.com/support/product-details/product/ ... /drivers

                $file = Select-FileDialog -Title "DELL BIOS Patch" -Path "$($ctx.dir.software)\BIOS" -Filter "*.exe"
                if ($file -ne "") {
                    & $file
                }
            }
        }
        else {
            Start "$($ctx.dir.software)\BIOS"
        }
    }
}