# Deploymentor

<img width="49%" alt="Image" src="https://github.com/user-attachments/assets/d101f61e-2129-4e96-bf98-19fa9ad8bac1" />
<img width="49%" alt="Image" src="https://github.com/user-attachments/assets/aba27bdc-13a3-42dd-8cc0-e411edff63a8" />

## Installation into a system

```powershell
Install-Module Deploymentor ; Import-Module Deploymentor # only needed for the first run

Edit-Deploymentor -VSCode # without any param it will open the folder in explorer instead

Start-Deploymentor  # -Config  and other params, see 'Usage' below
# with example data
Start-Deploymentor -Config examples  # config path is relative to to the current folder
```

## Installation as portable version / offline use

1. get the folder, do either:
    - clone this repository: `git clone https://github.com/BananaAcid/Deploymentor.git`
    - download as zip and extract: [`https://github.com/BananaAcid/Deploymentor/archive/refs/heads/main.zip`](https://github.com/BananaAcid/Deploymentor/archive/refs/heads/main.zip)
    - get it from PSGallery: `Save-Module Deploymentor -Path .\`

2. *optionally:* configure `.\data\config.ps1`

2. run once to be ready for offline use (will place the MainWindow.xaml into data, save the required PowerShell modules, create missing folders, ...)

## Start

```powershell
.\deploymentor
```

Run with example data
```powershell
.\deploymentor -Config examples
```

## Usage

```powershell
.\deploymentor [-Profile <0|index|name>] [-AutoStart <'none'|'actions'|'software'|'all'>] [-Config <"<Deploymentor>\data\config.ps1"|"<Deploymentor>\config.ps1"|"examples"|path>] [-Logs <".\logs"|path>] [-Debug]
```
*NOte: First value in a param is the default*

`-Profile <name>` does pattern matching (using `-like`), so case does not matter and you could use `mainloc*`

`-AutoStart <'none'|'actions'|'software'|'all'>` executes the specified category, like the buttons would

`-Config <path>` is relative to your current folder; Deploymentor looks in the install folder for `.\data\config.ps1` then `.\config.ps1` and loads it as base config, then loads the config from param on top. `"examples"` is a special value that loads the examples config from the install folder.

`-Logs <path>` target path for the automatically created log (it defaults to the Deplomentor folder)

`-Debug` also outputs XAMLgui info

`deploymentor.ps1` is the main script, can by run directly from within powershell (with `.\deploymentor <params>`).<br>
`deploymentor.cmd` is openning a new console window with powershell and will run the main script (params work as well) - Helpful if you want to double click in the explorer to run it.<br>
`deploymentor-example.ps1` is like `deploymentor.ps1` but runs with `-Config examples` to prefill with examples.<br>
`deploymentor-example.cmd` is like `deploymentor.cmd` but runs with `-Config examples` to prefill with examples.<br>
For publishing as Module: Deploymentor.psd1, Deploymentor.psm1, publish.ps1<br>
To run, the minimal required files are: `deploymentor.ps1`, `.\data\config.ps1` (base config), `.\data\MainWindow.xaml` (the GUI), empy folders for each `$dir` in config.ps1


**Note:** On every run, a new logfile will be created in the .\log folder. This can not be configured, but changed by param.

### Tricks
- **After Profile 1 restart and continue with profile `MainLocation Second`**
    - If you have an `action` that adds Deploymentor to run-once/registry (`Set-RunOnce` is imported with XAMLgui) and then does a reboot (should check context for previous actions errors), the GUI would open with the next proifle selected on restart and run automatically<br>
    `.\actions\Continue Phase 2.ps1`:
        ```powershell
        @{
            hasValue = $true
            Value = $env:USERNAME
            
            hasValue2 = $true
            Value2 = $password

            installFn = {
                param ( $ctx, <#Value#>[string]$username, <#Value2#>[string]$password )

                Run-Once "-executionpolicy bypass -file $PSScriptRoot\Deploymentor.ps1" -Params "-Config '$PSScriptRoot\data\config.ps1' -Profile *Second -AutoStart all"

                # Set registry keys for AutoAdminLogon -- VALUES MUST BE REMOVED AFTER RESTART
                $path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
                Set-ItemProperty -Path $path -Name "AutoAdminLogon" -Value "1"
                Set-ItemProperty -Path $path -Name "DefaultUserName" -Value $username
                Set-ItemProperty -Path $path -Name "DefaultPassword" -Value $password
                Set-ItemProperty -Path $path -Name "DefaultDomainName" -Value "$env:USERDOMAIN" # To force local acount: "."

                shutdown /r /t 10 /f /e "Rollout - Phase 2"
                Exit 0
            }
        }
        ```
    - it us 
- **Fresh deployment package**
    - create a new `start.ps1` with the following
    - Get updated version
        - You can download a zip from a network server:
            ```powershell
            Invoke-WebRequest "https//server.local/deployments/Deploymentor-MainLocation.zip" -OutFile .\
            ```
        - You could copy a zip from a network location:
            ```powershell
            Copy-Item -r \\sever\deployments\Deploymentor-MainLocation.zip .\
            ```
    - Handle updated files and start
        ```powershell
        #Extract the new content to current folder: 
        Expand-Archive .\Deploymentor-MainLocation.zip -Force;
        Remove-Item .\Deploymentor-MainLocation.zip
        Start-Deploymentor -Config .\Deploymentor-MainLocation\data\config.ps1
        ```


## Structure

> [!NOTE]
> Files starting with `.` or `_.` will be ignored and NOT shown in the software, actions and tools lists.

**None of the examples in this repository include the actual exe/msi/zip, because of possible legal reasons. But the download paths should be in the deploy/install files as comment.**

### \logs

- `yyyy-MM-dd_HH-mm-ss.log`

### \actions
Single actions for configuring the system (**NOT** software installs), with: 0, 1 or 2 text input fields<br>
Use `$global:DoCancel = $false` within software (only in deploy.ps1) or action.

**Note:** You should always log to the console window (with `Write-Host` not something else) to make sure, your execution protocol shows any info about what steps have been performed - it will help any one using it to spot errors to fix

- `\Action Minimal.ps1`
    ```ps1
    return @{

        # title will be "Action Minimal" - the file name

        # required
        installFn = {
            param($ctx, [string]$title = "Warning", [string]$message) # 2 value input fields in actions
            
            Write-Host "Messagebox: $title`n$message" # always log to console as well!
            Show-MessageBox $message $title
        }
    }
    ```

- `\Action name or title.ps1`
    ```ps1
    return @{

        # newline `n is required, if you want to output 2 lables (1st row for first inputbox, 2nd row for second inputbox)

        title = "Title`nMessage" #optional: if not given, the files's name is used

        description = "Shows a messagebox" #optional: detault is empty

        isSelected = $TRUE  #optional: default is false, only used if a profile does not specify this

        hasValue = $TRUE   #optional: shows a text field next to the value
        Value = "Title"  #optional: if given, the textbox will be prefilled

        hasValue2 = $TRUE   #optional: shows a text field next to the value
        Value2 = "Message"  #optional: if given, the textbox will be prefilled


        # .. using Value here, allows the use of variables - like accessing $global:ctx
        #   Value = "Current profile: $($global:ctx.activeProfile.Title)"  #optional: if given, the textbox will be prefilled
        
        # instead of hasValue and Value, the installFn params can be used, but with defaults only as string

        # required
        installFn = {
            param($ctx, [string]$title, [string]$message)
            
            # Import another module from the main ps_modules folder.
            #Import-LocalModule SomeOtherImportantModule -Path ..\ps_modules
            # using `Import-LocalModule`, the module will be downloaded into .\ps-modules if missing

            # Some Modules and functions are preloaded,
            # you have access to all of XAMLGui, ConvertTo-NiceXml

            Write-Host "Messagebox: $title`n$message" # always log to console as well!
            Show-MessageBox $message $title
        }
    }
    ```

#### Instead of hasValue and Value, the installFn params can be used, with defaults as string
```ps1
installFn = {
    param($ctx, [string]$title = "The Title", [string]$message = "Default message")
    
    Write-Host "Messagebox: $title`n$message" # always log to console as well!
    Show-MessageBox $message $title
}
```

### \data
- `\cache\*.bmp` (cached application icons)
- `\config.ps1`
    ```ps1
    # ALL variables are REQUIRED in the main config, if -Config param is used,
    #  the provided config may only contain what is supposed to be overwriten

    $darkMode = $true

    # paths are relative to this config, these paths are absolutely required to exist
    $dir = @{
        data = "..\data"
        cache = "..\data\cache"  # will be created if missing, could be $env:TEMP but a local path is better for portable use

        profiles = "..\profiles"
        actions = "..\actions"
        software = "..\software"
        tools = "..\tools"

        psmodules = "..\ps-modules" # will be created if missing, defaults to Deploymenter's installation dir .\ps-modules
    }

    # when showing the button caption, remove the extension from the displayed caption
    $toolsExtHide = @(".lnk", ".exe")

    $showConsole = $true

    $softwareInstallers = @{
        "install.ps1" = "dpx"  # is parsed for additional info, special Deploymentor file

        "deploy.ps1" = "ps"

        "deploy.vbs" = "wsh"
        "install.vbs" = "wsh"  # alias for deploy.vbs
        
        "deploy.wsf" = "wsh"    # Windows script file (XML based)
        "install.wsf" = "wsh"
        
        "deploy.js" = "wsh"
        "install.js" = "wsh"
        
        "deploy.cmd" = "exec"
        #"deploy.bat" = "exec" # ... don't ever use batch files -> use .cmd
        
        "setup.exe" = "exec"
        "deploy.msi" = "exec"
        "deploy.sh" = "bash"
    }

    $contextFormat = @{
        "deploy.ps1" = "native" # special case - software installer runs in same session
        ".ps1" = "nativefile"   # is a temp xmlfile with types to be able to convert it back (using Import-CliXml) - relevant for tools - they run in a separate session
        ".x.ps1" = "native"     # tool in same session -- works like an action or software (should be avoided)
        ".vbs" = "xml"          # xml str as param 1 to script (probably buggy)
        ".wsf" = "xml"          # xml str as param 1 to script (probably buggy)
        ".js"  = "json"         # json str as param 1 (probably buggy)
        ".bat" = ""             # defaults to key:val list in temp-file
        ".cmd" = ""             # defaults to key:val list in temp-file
        ".exe" = "jsonfile"     # is a temp jsonfile as param 1 to executable
        ".msi" = "xmlfile"      # is a temp xmlfile as param 1 to executable
        ".sh"  = "jsonfile"     # is a temp jsonfile as param 1 to script / linux has usually `jq`/`awk` nativly installed
    }
    ```
    - Example for `nativefile` usage, to get the `$ctx` like in `native`
        ```powershell
        param($ctxFileName)
        $ctx = Import-CliXml -Path $ctxFileName
        ```

### \profiles
any PS1 here will define a list of software and actions to be shown in the lists

- `\MainLocation.ps1`
    ```ps1
    # add globals for use in actions, you should overwrite them within the other profiles
    $Global:IMPORTANT_VAR = "MAINLOCATION"
    $Global:adminGroups = @("MLOC\AdminOU", "MLOC\AdminPC")
    $Global:printerDefaultDomain = "\\printer100\"

    return @{

        title = "MainLocation"  # optional, fallback to filename

        actionsFirst = $true # optional, default is true

        # folders in .\software made available in the list, and preselected (some may have isSelected also set internaly) - if list is not set, all folders are shown
        software = @(
            "HardCopy (free)"
            @{Name="OOSU10"; isSelected=$true}
            "AcrobatReader"
            "7Zip"
            @{Name="BIOS"; isSelected=$false}
        )

        # files in .\actions made available in the list, and preselected (some may have isSelected also set internaly) - if list is not set, all files are shown
        actions = @(
            "require admin.ps1"
            @{Name="require admin by dialog.ps1"; isSelected=$false}
            "set important env.ps1"
            "remove admin user.ps1"
            "set new Administrator PW.ps1"

            "add user as admin.ps1"

            "run telemtry tool.ps1"
            "remove unneded c dirs.ps1"
            "service files patch.ps1"
            "remove default apps.ps1"
            @{Name="msg plug cable.ps1"; isSelected=$true}
            "disable iv6.ps1"
            "open cumputername dialog.ps1"

            "install bios patch and restart.ps1"
        )

        # files in .\tools
        tools = $null # show all
    }
    ```

#### Note:
- `tools = $null` **shows all**, if the key is `missing` it **shows all**. To **not show** any items use `@()`
    - same for `software` and `actions`

- The order **within** software and action and tools matter. To reorder the UI, do it here.

- Multiple occurences of the same action / software / tool is possible (like retrying VCRedist multiple times, until defender leaves it alone).


### \ps-modules
Any downloaded PowerShell module goes into this folder. Use `Import-LocalModule` to use them (and to download them on first use).
Manually install them there: `Save-Module -Name SomeModuleName -Path .\ps-modules`

### \software
Any folder that should be listed in the software list. See `config.ps1` -> `$softwareInstallers` to see what files will be looked for to determine if there is an installer or deploy script to run and `$contextFormat` how the 1st params gets context formatted. The scripts can either contain code or just install the exe with silent params.

- `\...application name...`
    - `\some_application.exe` (optional)
    - `\install.vbs` (optional)
    - `\deploy.ps1`
        ```ps1
        return @{

            title="Acrobat Reader" #optional: if not given, the folder's name is used

            description = "Version 2025.001.21223" #optional: detault is empty

            icon = ".\Reader_en_install.exe" #optional: default is default-app.png

            isSelected = $TRUE  #optional: default is false, only used if a profile does not specify this

            ctxType = 'native' #optional: default is 'native', but could be changed to anything in config.ps1 > $contextFormat

            # required, param() is optional
            installFn = {
                param( $ctx )

                # Import another module from the main ps_modules folder.
                #Import-LocalModule SomeOtherImportantModule -Path ..\ps_modules
                # using `Import-LocalModule`, the module will be downloaded into .\ps-modules if missing

                # Some Modules and functions are preloaded,
                # you have access to all of XAMLGui, ConvertTo-NiceXml, native Expand-Archive (un-zip), ...


                if (-not (Test-Path  .\Reader_en_install.exe)) {
                    # open download page
                    start "https://get.adobe.com/de/reader/download?....."
                    # open current folder in explorer
                    start ".\"
                    # wait for user
                    Show-MessageBox "Press ok after download to the correct folder: `nThe installer will be run with silent options afterwards." -Title "Acrobat Reader Setup missing"
                }

                Start-Process ".\Reader_en_install.exe /sPB /rs /msi" -Wait
            }
        }
        ```

### \tools
**Any file** in this folder will be shown as button in the Tools section and clicking the button will launch it using `Start-Proccess`.

The tool gets the context passed as first param, see `config.ps1` -> `$contextFormat` how context is formatted (`.ps1` = `nativefile` -> use `Import-CliXml`).

⚠️ Windows must know about the file extension to be able to launch it - anything that can be double clicked will work.

#### Difference: .ps1 and .x.ps1
- `.ps1` will be launched in an isolated terminal but gets a copy of the context
- `.x.ps1` will be launcehd in the same session - like an action or software script

### \window
The Visual Studio project solution. This houses the MainWindow.xaml and all required files, to edit it visually in Visual Studio.

- `\MainWindow.xaml`
- `\...` other VS files

### ROOT: \
- `\deploymentor.cmd`
    - this runs `powershell.exe` with `.\deploymentor.ps1`
- `\deploymentor.ps1`
    - This is the app code - can be run directly if in powershell
    - requires `.\data\config.ps1`
    - params: see section `start` above

### `$ctx`

```ps1
$ctx = @{
    dir = $dir          # == config.ps1 > $dir
    activeProfile = @{  # data of the currently selected profile
        File = $null    # current profile filename path
        Title = $null   # the displayed title
        Data = $null    # the profile files returned settings content
    }
    item = $null        # @{ Folder = $dir.software; FilePath; FileName; }
    lastExecResult = @{ # may contain content returned from an action / software
        ".\acton\set admin pw.ps1" = "admin"        # example for an action returning the set user name
        ".\tools\some_tool.x.ps1" = "Everyting ok"  # example for a tool witin the scope, that returned someting
    }
}
```

You can access the `$ctx.lastExecResult` in a **tool** or **action** or **software**, to check if prerequisites ran, and more.

Your tool `.ps1`/`.x.ps1` or software `deploy.ps1` would need a `param( $ctx )` first row, to receive the context object. Any script, like VBS, can access its shell arguments list.

  - VBS Example:
    ```vbs
    If WScript.Arguments.Count = 0 Then
        WScript.Echo "Error: Missing context parameter"
        WScript.Quit 1 ' Exit with an error code
    End If

    Set ctxXmlStr = WScript.Arguments(0)

    Set xmlDoc = CreateObject("MSXML2.DOMDocument.6.0")
    xmlDoc.async = False ' Ensures the document loads synchronously
    xmlDoc.loadXML(ctxXmlStr) ' Load the XML from the string

    someValue = xmlDoc.selectSingleNode("/ .... ")
    '  '-> ... welcome to PowerShell's lovely extreamly verbose XML structure
    ```

> [!NOTE]
> The context is provied to each script (ps, wsh: vbs/wsf/js, ...) and each executable as the first param.
>
> It depends on the `config.ps1` > `$contextFormat` settings, what how the context data is encoded
> - wsh scripts support XML way better, except for a .js wsh script - it will prefer JSON,
> - a powershell script in a new session can restore the ctx by converting it from XML with datatypes

## Attribution

- default-app.png
    - https://icons8.com/ - https://icons8.com/icons/set/software--style-ultraviolet (Free PNG)
