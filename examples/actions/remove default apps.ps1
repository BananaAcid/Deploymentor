return @{

    title="Uninstalls unneded Win10/11 Apps" #optional: if not given, the folder's name is used

    description = "and Flash, Shockwave" #optional: detault is empty

    isSelected = $true  #optional: default is false, only used if a profile does not specify this

    # required
    installFn = {

        echo "remove win 10/11 apps"

        echo "3D Builder"
        Get-AppxPackage *3dbuilder* | Remove-AppxPackage

        echo "Calendar and Mail"
        Get-AppxPackage *windowscommunicationsapps* | Remove-AppxPackage

        echo "Camera"
        Get-AppxPackage *windowscamera* | Remove-AppxPackage

        echo "Get Office"
        Get-AppxPackage *officehub* | Remove-AppxPackage

        echo "Get Skype"
        Get-AppxPackage *skypeapp* | Remove-AppxPackage

        echo "Get Started"
        Get-AppxPackage *getstarted* | Remove-AppxPackage

        echo "Groove Music"
        Get-AppxPackage *zunemusic* | Remove-AppxPackage

        echo "Maps"
        Get-AppxPackage *windowsmaps* | Remove-AppxPackage

        echo "Microsoft Solitaire Collection"
        Get-AppxPackage *solitairecollection* | Remove-AppxPackage

        echo "Money"
        Get-AppxPackage *bingfinance* | Remove-AppxPackage

        echo "Movies & TV"
        Get-AppxPackage *zunevideo* | Remove-AppxPackage

        echo "News"
        Get-AppxPackage *bingnews* | Remove-AppxPackage

        echo "OneNote"
        Get-AppxPackage *onenote* | Remove-AppxPackage

        echo "People"
        Get-AppxPackage *people* | Remove-AppxPackage

        echo "Phone Companion"
        Get-AppxPackage *windowsphone* | Remove-AppxPackage

        echo "Sports"
        Get-AppxPackage *bingsports* | Remove-AppxPackage

        echo "Voice Recorder"
        Get-AppxPackage *soundrecorder* | Remove-AppxPackage

        echo "Weather"
        Get-AppxPackage *bingweather* | Remove-AppxPackage

        echo "Xbox"
        Get-AppxPackage *xboxapp* | Remove-AppxPackage

        # yes ... Win 10
        echo "Remove Flash"
        Start-Process "C:\Windows\SysWOW64\Macromed\Flash\FlashUtil32_32_0_0_132_Plugin.exe" "-maintain plugin"  -Wait
        Start-Process "C:\Windows\SysWOW64\Macromed\Flash\FlashUtil32_32_0_0_156_pepper.exe" "-maintain plugin"  -Wait

        echo "Remove Shockwave"
        Start-Process 'C:\Windows\SysWOW64\Adobe\Shockwave 12\uninstaller.exe'  -Wait
        
    }
}