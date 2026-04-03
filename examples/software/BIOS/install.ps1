<#

Files I used for testing, the script expects files like these;

Dell Latitude 5280,5288,5480,5488,5580 and Precision 3520 System BIOS - Latitude_5X80_Precision_3520_1.13.0.exe
Dell Latitude 7280,7380,7480 System BIOS - Latitude_7x80_1.14.1.exe
Dell Latitude E5270,E5470,E5570 and Precision 3510 System BIOS - Latitude_E5x70_Precision_3510_1.19.3.exe
Dell Precision Workstation T5810 - T5810A30.exe
OptiPlex 7020 vA17---O7020A17.exe
OptiPlex_5040_1.13.0 BIOS.exe
OptiPlex_5050_1.11.1.exe

#>

return @{

    title="DELL BIOS Update" #optional: if not given, the folder's name is used

    description = "The BIOS patcher restarts the pc by itself" #optional: detault is empty

    isSelected = $FALSE  #optional: default is false, only used if a profile does not specify this

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