<#
    .Synopsis
    Deployment Helper and Administration Tool
    
    .Description
    Provides a GUI to trigger PowerShell snippets and software install scripts

    .Notes
    .NAME      Deploymentor
    .AUTHOR    Nabil Redmann <repo+deploymentor@bananaacid.de>
    .LICENSE   MIT
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '', Scope = 'Function', Target = '*')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Scope = 'Function', Target = '*')]
param(
    [Parameter(Mandatory=$false, Position=0, HelpMessage="start with a specific profile")]
    [Alias("Profile")]
    $ProfileSelected = $null, # int or name string
    
    [Parameter(Mandatory=$false, Position=1)]
    [ValidateSet('actions','software','all')]
    [string]$AutoStart = '',

    [Parameter(Mandatory=$false, Position=2)]
    [string]$ConfigFile = "$PSScriptRoot\data\config.ps1",

    [Parameter(Mandatory=$false, Position=3)]
    [string]$Logs = "$PSScriptRoot\logs"
)

<# ------------------------------------------------------------------------------------------------ #>

# do NOT use  -UseMinimalHeader  -> we want to know the user it was started with, in case of errors
Start-Transcript -Path "$Logs\$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log" -Append -ErrorAction SilentlyContinue | Out-Null

# save current path
$backupPWD = $PWD

# config requirements
#  always load as base config
$ConfigFileBase = (Get-Item "$PSScriptRoot\data\config.ps1","$PSScriptRoot\config.ps1" -ErrorAction SilentlyContinue | Select-Object -First 1)
. $ConfigFileBase
# just "examples" is a special case
if ($ConfigFile -eq "examples") { $ConfigFile = "$PSScriptRoot\examples\data\config.ps1" }
# can be configured by the user (if its the same default one ... nothing happens)
if ($ConfigFile) {
    $configFile = $(if ([System.IO.Path]::IsPathRooted($configFile)) { $configFile } else { Join-Path $backupPWD $configFile })

    if (Test-Path $ConfigFile) {
        $ConfigFile = Resolve-Path $ConfigFile
        . $ConfigFile 
    }
    elseif ($ConfigFile -and -not (Test-Path $ConfigFile)) {
        Write-Host "Config file not found: $ConfigFile" -ForegroundColor Red
        Stop-Transcript
        Exit 99
    }
}
else {
    # make sure, it is always set
    $ConfigFile = $ConfigFileBase
}

# get version from psd1
$PSD1 = Import-PowerShellDataFile $PSScriptRoot\Deploymentor.psd1 -ErrorAction SilentlyContinue
$VERSION = If ($PSD1) { 'v' + $PSD1.ModuleVersion } Else { '' }
Write-Host "Deploymentor $VERSION" -ForegroundColor Yellow

# make sure, we are in the right dir
# Set-Location $PSScriptRoot
Write-Host "Working dir: $PWD"

# ensure ps-modules dir exists
if (!(Test-Path $PSScriptRoot\ps-modules)) { mkdir $PSScriptRoot\ps-modules | Out-Null }
# To be able to use a local module, because deploying the app on an USB stick
# will need it and might not have internet access
Function Find-LocalModulePath { param( [Parameter(Mandatory=$true, Position=0)] [String] $Name, [String] $Path = ".\ps-modules" ) return ls "$Path\$Name" -ErrorAction SilentlyContinue | select -Last 1 |% FullName }
Function Import-LocalModule { param( [Parameter(Mandatory=$true, Position=0)] [String] $Name, [String] $Path = ".\ps-modules", [Boolean] $Download = $True ) if (-not (Find-LocalModulePath $Name -Path $Path) -and $Download) { Save-Module -Name $Name -Path $Path } $fullPath = Find-LocalModulePath $Name -Path $Path; if (-not $fullPath) { Write-Error "Unable to find $Name module, could not download. Aborting."; Exit 99 } Import-Module (Join-Path $fullPath $Name); }
Function Get-LocalModule { param( [Parameter(Mandatory=$true, Position=0)] [String] $Name, [String] $Path = ".\ps-modules", [Boolean] $Download = $True ) if (-not (Find-LocalModulePath $Name -Path $Path) -and $Download) { Save-Module -Name $Name -Path $Path } $fullPath = Find-LocalModulePath $Name -Path $Path; if (-not $fullPath) { Write-Error "Unable to find $Name module, could not download. Aborting."; Exit 99 } return $fullPath; }

## DO NOT USE THIS
## We use a local version of the XAMLgui module, because deploying the app on an USB stick
## will need it and might not have internet access
###Import-LocalModule XAMLgui

#! Dev - use Dev version of XAMLgui
if (Test-Path -Path ..\XAMLgui\XAMLgui) { ls "..\XAMLgui\XAMLgui\*.ps1" |% { . $_.FullName } }
#! import the module functions into the current session
#! we do not import, because the handlers are not picked up -- TODO: FIX this.
else { ls "$(Get-LocalModule XAMLgui)\*.ps1" |% { . $_.FullName } }

# we need a variant, that works with transcript - but we ignore the error pipeline. Overwrite the one from XAMLgui.
Function Write-ErrorClean { param( [Parameter(Mandatory=$false, Position=0, ValueFromPipeline=$true)] [String] $Message, [Parameter(Mandatory=$false, Position=1)] [String] $ForegroundColor = $Host.PrivateData.ErrorForegroundColor <# ='Red'#> ); Write-Host "ERROR: $Message" -ForegroundColor $ForegroundColor; }

# early config handling
If (!$showConsole) { Hide-Console }

Write-Host "Config File: $ConfigFile"

# ensure cache dir exists
$cacheDir = if ([System.IO.Path]::IsPathRooted($dir["cache"])) { $dir["cache"] } else { Join-Path (Split-Path $ConfigFile) $dir["cache"] }
if (!(Test-Path $cacheDir)) { mkdir $cacheDir | Out-Null }

#resolve all paths, relative to the config.ps1
$dirAbs = @{}
$dir.Keys |% { $dirAbs[$_] = Resolve-Path $(if ([System.IO.Path]::IsPathRooted($dir["$_"])) { $dir["$_"] } else { Join-Path (Split-Path $ConfigFile) $dir["$_"] }) -ErrorAction Stop }
$dir = $dirAbs

Write-Debug ("Config Dirs Resolved:" + ($dir | Format-Table | Out-String))

# usefull for actions/software
$ctxBase =  @{
    dir = $dir          # == config.ps1 > $dir
    activeProfile = @{  # data of the currently selected profile
        File = $null    # current profile filename path
        Title = $null   # the displayed title
        Data = $null    # the profile files returned settings content
        Index = 0       # the index of the currently selected profile
    }
    item = $null        # @{ Folder = $dir.software; FilePath; FileName; }
    doCancel = $false   # setting this will abort any actions/software in queue
    lastExecResults = @{} # may contain content returned from an action / software
}
$script:ctx = New-ClonedObject $ctxBase
$script:contextFNs = "" # set in Load-ContextFns, will pass helper functions to actions/apps

#globals
$script:profilesAvailable = @()
$Elements = $null
$MainWindow = $null



Function Load-ContextFns {
    # get functions into context (Actions, Software)
    $script:contextFNs = @(
        Get-FnAsString Find-LocalModulePath
        Get-FnAsString Import-LocalModule   # requires Find-LocalModulePath
        # Get-FnAsString Get-LocalModule    # gets added by Import-LocalModule within context
        Get-FnAsString ConvertTo-NiceXml    # good to have
        "Import-LocalModule XAMLgui -Path $(Join-Path $PSScriptRoot .\ps-modules -Resolve)"  # requires Import-LocalModule to be available
        'Enable-VisualStyles'
        Get-FnAsString Write-ErrorClean     # we make sure, we have an error handler that is able to be cought by transcript
    ) -join "`n"
}


# --- UI Event-Handlers -------------------------------



# handler - have to be available before loading form
function Deploymentor.MainWindow.DoInstallSoftware_Click($Sender1, $EventArgs1) { 
    if ( (Show-MessageBox "Are you sure you want to run all selected installations?" -Title "Really sure?"  -Buttons OkCancel -Type Warning) -ne "Ok") { return }

    Reset-lastExecResults
    Reset-Progressbars
    
    Enable-Ui -Enable $false
    Invoke-Software
    Enable-Ui -Enable $true
}

function Deploymentor.MainWindow.DoInstallActions_Click($Sender1, $EventArgs1) { 
    if ( (Show-MessageBox "Are you sure you want to run all selected actions?" -Title "Really sure?"  -Buttons OkCancel -Type Warning) -ne "Ok") { return }

    Reset-lastExecResults
    Reset-Progressbars
    
    Enable-Ui -Enable $false
    Invoke-Actions
    Enable-Ui -Enable $true
}

function Deploymentor.MainWindow.BtnCancel_Click($Sender1, $EventArgs1) {
    Write-Warning "Canceling execution of tasks ..."
    
    $ctx.doCancel = $true
}

function Deploymentor.MainWindow.CbProfileSelect_SelectionChanged($Sender1, $EventArgs1) {
    $s = [System.Windows.Controls.Combobox]$sender1
    if ($s.SelectedIndex -gt 0) {
        Write-Host "Profile selected: ", $s.SelectedIndex, " -> ", $s.SelectedValue -ForegroundColor Green
    }
    else {
        Write-Host "Profile selected: none" -ForegroundColor Green
    }
    Load-Profile -Index $s.SelectedIndex -Title $s.SelectedValue
    Reset-Progressbars
}

function Deploymentor.MainWindow.DoSoftwareDir_Click($Sender1, $EventArgs1) {
    Start $dir.software
}

function Deploymentor.MainWindow.DoActionsDir_Click($Sender1, $EventArgs1) {
    Start $dir.actions
}

function Deploymentor.MainWindow.DoOpenConfig_Click($Sender1, $EventArgs1) {
    Start-Process "explorer.exe" "/select,`"$configFile`""
}

function Deploymentor.MainWindow.LbCopy_MouseDown($Sender1, $EventArgs1) {
    Start "mailto:repo+deploymentor@bananaacid.de"
}

function Deploymentor.MainWindow.doInstallAll_Click($Sender1, $EventArgs1) {

    $actionsCount = $Elements.lvSoftware.SelectedItems.Count + $Elements.lvActions.SelectedItems.Count
    $counter = 0

    if ( (Show-MessageBox "Are you sure you want to run all selected actions and all selected installations?" -Title "Really sure?"  -Buttons OkCancel -Type Warning) -ne "Ok") { return }
    
    Reset-lastExecResults
    Reset-Progressbars
    
    Enable-Ui $false
    
    Write-Host "Total tasks: $actionsCount" -ForegroundColor Green
    
    $af = $ctx.activeProfile.Data.actionsFirst -ne $false
    
    If ($af) {
        Invoke-Actions -Counter ([ref]$counter)
        Invoke-Software -Counter ([ref]$counter)
    }
    else {
        Invoke-Software -Counter ([ref]$counter)
        Invoke-Actions -Counter ([ref]$counter)
    }
    
    Enable-Ui $true
    
    Write-Host "Installing done." -ForegroundColor Green
}

function Deploymentor.MainWindow.LvTools_SelectionChanged($Sender1, $EventArgs1) {
    # prevent errors
    If (!$ctx.toolsLoaded) { return }
    
    $listbox = [System.Windows.Controls.ListBox]$Sender1
    
    # if it was deselected
    If(!$listbox.SelectedItem) { return }

    # get the selected item
    $item = ($EventArgs1.AddedItems | Select-Object -First 1)

    # Pretend to be a button -> Deselect
    $listbox.SelectedItem = $null
    
    Invoke-Tool $item
}

Add-KnownEvents "PreviewMouseRightButtonDown"
$script:lvSoftwareLastClicked = $null
function Deploymentor.MainWindow.lvSoftware_PreviewMouseRightButtonDown($Sender1, $EventArgs1) {
    $e = [System.Windows.Input.MouseButtonEventArgs]$EventArgs1
    $s = [System.Windows.Controls.ListView]$Sender1
    $script:lvSoftwareLastClicked = ([System.Windows.FrameworkElement]$e.OriginalSource).DataContext
    
    $e.Handled = $true;  # block right click

    if ($null -ne $script:lvSoftwareLastClicked) {
        $s.ContextMenu.PlacementTarget = $s;
        $s.ContextMenu.IsOpen = $true;
    }
}

function Deploymentor.MainWindow.lvSoftware_ContextMenu_Click($Sender1, $EventArgs1) {
    $item = $script:lvSoftwareLastClicked
    
    if ($null -ne $item) {
        Write-Host "Started `"$($item.Title)`"" -ForegroundColor Green
        
        Start-AwaitJob $item.Data.installFn -ArgumentList $($ctx) -Dir $item.FilePath -InitBlock $script:contextFNs
    }
}

function Deploymentor.MainWindow.cbActonsFirst_Checked($Sender1, $EventArgs1) {
    $cb = [System.Windows.Controls.CheckBox]$Sender1
    
    if ($cb.IsChecked) {
        # $Elements.software."Grid.Column" = 0
        # $Elements.actions."Grid.Column" = 2
        [System.Windows.Controls.Grid]::SetColumn($Elements.software, 2)
        [System.Windows.Controls.Grid]::SetColumn($Elements.actions, 0)
    }
    else {
        # $Elements.software."Grid.Column" = 2
        # $Elements.actions."Grid.Column" = 0
        [System.Windows.Controls.Grid]::SetColumn($Elements.software, 0)
        [System.Windows.Controls.Grid]::SetColumn($Elements.actions, 2)
    }
}



# load main gui

# copy if it exists (we do not need the window dir when deploying this)
Copy-Item $PSScriptRoot\window\MainWindow.xaml "$($dir.data)\MainWindow.xaml" -Force -ErrorAction SilentlyContinue # try or don't care
$Elements,$MainWindow = . New-Window "$($dir.data)\MainWindow.xaml" # -Debug  # for debugging handlers and see error messages


# --- Main functions ------------------------------------------


Function Set-ActionsBeforeSoftware {
    param (
        $actionsFirst = $true
    )

    $Elements.cbActonsFirst.IsChecked = $actionsFirst -eq $true
}


Function Load-ProfileByParam {
    Param( $profileName )
    
    # Preselect by param if available
    $cb = [System.Windows.Controls.ComboBox]$Elements.CbProfileSelect
    if ($null -eq $profileName -or "" -eq $profileName -or -1 -eq $profileName) {
        # force 0 to trigger a select on the item -> this triggers a change event and is cought as a profile change -> Load-Profile -> Load-Actions, ... 
        #   otherwise it is -1 and will not trigger the event / load the profile
        $profileName = 0 
    } 

    # Try to parse the string to an integer
    if ([int]::TryParse($profileName, [ref]$null)) {
        if ($profileName -ge $script:profilesAvailable.Count) {
            if ($profileName -ne 0) {
                Write-ErrorClean "Profile not found for index: $profileName"
            }
            $profileName = 0
        }
        $cb.SelectedIndex = [int]$profileName
    }
    else {
        # find the correct filename -> is the profile name
        $profileNameNew = $cb.Items |? { $_ -ilike $profileName } | select -first 1
        if ($null -eq $profileNameNew) { 
            Write-ErrorClean "Profile not found matching: $profileName"
            $cb.SelectedIndex = 0
        }
        else {
            $cb.SelectedItem = $profileNameNew
        }
    } 
}

# data handler 
<#
1. load profile files
2. add to combobox CbProfileSelect

3. preselected: none -> all options / software
#>
Function Load-ProfileList {
    $script:profilesAvailable = ls "$($dir.profiles)\*.ps1" -File |? { $_.Name -notlike "_.*" -and $_.Name -notlike ".*" }
    $cb = [System.Windows.Controls.Combobox]$Elements.CbProfileSelect
    $cb.Items.Clear()
    $cb.AddText("")

    if ($script:profilesAvailable.Count -eq 0) {
        Write-ErrorClean "No profiles found in: $($dir.profiles)"
        $script:profilesAvailable = @()
        return
    }

    Foreach ($file in $script:profilesAvailable) {
        Write-Debug "Found profile: $file"
        
        $data = & $file
        $title = ($file | % {$_.BaseName})
        
        If ($data.title) {
            $title = $data.title
        }
        
        $cb.AddText( $title )
    }
}

Function Load-Profile {
    Param( $Index, $Title )
    
    # fresh ctx
    $script:ctx = New-ClonedObject $ctxBase
    
    $realIndex = $Index - 1  # 0 => "ALL"
    $currentProfile = $script:profilesAvailable[$realIndex]

    $settings = if ($currentProfile) { & $currentProfile } else { @{} }
    
    # store current profile to be used by any script
    $ctx.activeProfile = @{
        File = $currentProfile
        Title = $title
        Data = $Settings
        Index = $realIndex
    }
    
    Set-ActionsBeforeSoftware ($null -eq $Settings.actionsFirst -or $Settings.actionsFirst -eq $true)
    # check:   $ctx.activeProfile.Data.actionsFirst -ne $false
    
    If ($Index -ne 0 -and $null -ne $Settings.software) {
        $filter = $Settings.software
        
        Load-Software $filter
    }
    else {
        Load-Software
    }
    
    If ($Index -ne 0 -and $null -ne $Settings.actions) {
        $filter = $Settings.actions
        
        Load-Actions $filter
    }
    else {
        Load-Actions
    }

    If ($Index -ne 0 -and $null -ne $Settings.tools) {
        $filter = $Settings.Tools
        
        Load-Tools $filter
    }
    else {
        Load-Tools
    }
}

Function Load-Software {
    Param( $Filter )
    
    # load defaults
    If ($null -eq $filter) {
        $filter = ls "$($dir.software)\*" -Directory |? { $_.Name -notlike "_.*" -and $_.Name -notlike ".*" }
    }

    # add software
    $Elements.lvSoftware.Items.Clear();
    Foreach ($itemAorB in $filter) {
        $isSelected = $null

        # is string or object? We only want file items - this item is only the case for items provided by a profile
        #   @{Name="FolderName"; isSelected=$true}
        if ($null -ne $itemAorB.isSelected -and $null -ne $itemAorB.Name) {
            # the item is an action item config: @{Name="...filename.ps1..."; isSelected=$true} object
            $item = gi "$($dir.software)\$($itemAorB.Name)" -ErrorAction SilentlyContinue
            $isSelected = $itemAorB.isSelected -eq $true
        }
        elseif ($itemAorB.FullName) { # by the !$filter check, they are files
            # the item is a file
            $item = $itemAorB
        }
        elseif ($itemAorB -is [string]) {
            # the item is a filename
            $item = gi "$($dir.software)\$itemAorB" -ErrorAction SilentlyContinue
        }
        else {
            Write-ErrorClean "Unknown software item type:"
            $itemAorB | Format-List | Out-String | Write-ErrorClean
            continue
        }
        
        if ($null -eq $item) {
            # gi *  might not actually found a file
            Write-ErrorClean "Software folder does not exist: '$($dir.software)\$itemAorB'"
            continue
        }

        
        $data = $NULL
        $deploymentFilePath = $NULL
        
        ForEach ($typeKey in $softwareInstallers.Keys) {
            $typeValue = $softwareInstallers[$typeKey]
            $deploymentFilePath = Join-Path -Path $item.FullName -ChildPath $typeKey
            
            If (Test-Path $deploymentFilePath) {
                # load data
                $deploymentFilePath = $deploymentFilePath | gi
                
                Switch ($typeValue) {
                    # is parsed for additional info, special Deploymentor file: must return Description, installFn
                    "dpx" {
                        $data = & $deploymentFilePath
                        if (-not $data.ctxType) {
                            $data.ctxType = "native"
                        }
                    }
                    "ps" {
                        $data = @{
                            Description = "Running as Powershell Script"
                            installFn = [scriptblock]::Create("param(`$ctx) ; & '$deploymentFilePath' `$ctx")
                        }
                    }
                    "exec" {
                        $data = @{
                            Description = "Running an Executable"
                            installFn = [scriptblock]::Create("param(`$ctx) ; Start '$deploymentFilePath' -WorkingDirectory '$($deploymentFilePath.DirectoryName)' -ArgumentList `$ctx")
                        }
                    }
                    "wsh" {
                        $data = @{
                            Description = "Running through Windows Scripting Host ($($deploymentFilePath.Extension))"
                            installFn = [scriptblock]::Create("param(`$ctx) ; cd '$($deploymentFilePath.DirectoryName)' ; & cscript.exe '$deploymentFilePath' `$ctx")
                        }
                    }
                    "bash" {
                        $data = @{
                            Description = "Running a Script through Bash"
                            #! TODO: check if this works ... '\' and '/', in windows with bash and on linux with bash
                            installFn = [scriptblock]::Create("param(`$ctx) ; & bash -c `". '$deploymentFilePath' `$ctx `"") 
                        }
                    }
                    default {
                        Write-ErrorClean "Unknown deployment file type: $typeValue `n - for $($deploymentFilePath.FullName)"
                    }
                }
                break
            }
        }
        
        if (-not $data) {
            Write-Warning "Software installer not found in folder: `"$($dir.software)\$($item.Name)\`""
            continue
        }
        
        # if config
        $iconFile = Resolve-Path "$($dir.data)\default-app.png"
        $title = $item.Name
        
        If ($data.title) {
            $title = $data.title
        }
        
        # cache icon
        $iconFileProvider = Join-Path -Path $item.FullName -ChildPath $data.icon # resolve makes it $Null if it does not exist, -ErrorAction does not work with -Resolve
        if (Test-Path $iconFileProvider) { $iconFileProvider = Resolve-Path $iconFileProvider} else { $iconFileProvider = $null }
        
        If ($Null -eq $iconFileProvider) { Write-ErrorClean ("Icon providing file does not exist (but was set in deployment file): " + (Join-Path -Path $item.FullName -ChildPath $data.icon).replace('\.\','\')) }
        If ($Null -ne $data.icon -and $Null -ne $iconFileProvider) {
            $iconPath = Join-Path -Path $dir.cache -ChildPath ($data.icon -replace '.\\','' -replace '\\','_')
            $iconFile = "$iconPath.bmp"
            
            If (!(Test-Path $iconFile)) { 
                [System.Drawing.Icon]::ExtractAssociatedIcon( $iconFileProvider ).ToBitmap().Save($iconFile)
                #Write-Host "writing file"
            }
            
            $iconFile = Resolve-Path $iconFile
        }
        
        # if it was NOT defined by the profile, check the file itself
        If ($null -eq $isSelected) {
            $isSelected = $data.isSelected -eq $true
        }
        
        $id = Resolve-Path $deploymentFilePath.FullName -Relative
        
        # add item
        <# $pos = #> $Elements.lvSoftware.Items.Add([PSCustomObject]@{Id=$id; Title=$title; Description=$data.description; Folder="software"; FilePath=$(Resolve-Path $item.FullName); FileName=$deploymentFilePath.Name; IsSelected=[bool]$isSelected; Icon=[string]$iconFile; Data=$data}) | Out-Null
    }
}

Function Load-Actions {
    Param( $Filter )
    
    # load defaults
    If ($null -eq $filter) {
        $filter = ls "$($dir.actions)\*.ps1" |? { $_.Name -notlike "_.*" -and $_.Name -notlike ".*" }
    }
    
    # add actions
    $Elements.lvActions.Items.Clear();
    Foreach ($itemAorB in $filter) {
        $isSelected = $null
        
        # is string or object? We only want file items
        If ($null -ne $itemAorB.isSelected -and $null -ne $itemAorB.Name) {
            # the item is an action item config: @{Name="...filename.ps1..."; isSelected=$true} object
            $item = gi "$($dir.actions)\$($itemAorB.Name)" -ErrorAction SilentlyContinue
            $isSelected = $itemAorB.isSelected -eq $true
        }
        elseif ($itemAorB.FullName) { # by the !$filter check, they are files
            # the item is a file object
            $item = $itemAorB
        }
        elseif ($itemAorB -is [string]) {
            # the item is a filename
            $item = gi "$($dir.actions)\$itemAorB" -ErrorAction SilentlyContinue
        }
        else {
            Write-ErrorClean "Unknown action item type:"
            $itemAorB | Format-List | Out-String | Write-ErrorClean
            continue
        }
        
        if ($null -eq $item) {
            # gi *  might not actually found a file
            Write-ErrorClean "Action file does not exist: '$($dir.actions)\$itemAorB'"
            continue
        }
        
        
        # load data from file item
        $data = & $item.FullName
        
        $title = $item.BaseName
        If ($data.title) {
            $title = $data.title
        }
        
        $descriptionVisibility = "Visible"
        if (!$data.description) {
            $descriptionVisibility = "Collapsed"
        }
        
        if ($null -ne $data.hasValue) {
            # use hasValue/Value properties
            
            $textBoxVisibility = "Visible"
            if ($data.hasValue -ne $true) {
                $textBoxVisibility = "Collapsed"
            }
            
            $textBoxVisibility2 = "Visible"
            if ($data.hasValue2 -ne $true) {
                $textBoxVisibility2 = "Collapsed"
            }
        }
        elseif ($data.installFn -and $data.installFn.Ast) {
            # get params from installFn
            
            $paramBlock = $data.installFn.Ast.ParamBlock
            $params = $paramBlock.Parameters
            
            $textBoxVisibility = "Collapsed"
            $textBoxVisibility2 = "Collapsed"
            # first ist $ctx
            if ($params.Count -ge 2) {
                $textBoxVisibility = "Visible"
                if ($null -ne $params[1].Defaultvalue.value) {
                    $data.value = $params[1].Defaultvalue.value.toString()
                }
            }
            if ($params.Count -ge 3) {
                $textBoxVisibility2 = "Visible"
                if ($null -ne $params[2].Defaultvalue.value) {
                    $data.value2 = $params[2].Defaultvalue.value.toString()
                }
            }
        }
        
        
        # if it was NOT defined by the profile, check the file itself
        If ($null -eq $isSelected) {
            $isSelected = $data.isSelected -eq $true
        }
        
        $id = Resolve-Path $item.FullName -Relative
        
        # add item
        $itemData = [PSCustomObject]@{Id=$id; Title=$title; Description=$data.description; Folder="actions"; FilePath=$dir.actions; FileName=$item.Name; IsSelected=[bool]$isSelected; DescriptionVisibility=$descriptionVisibility; TextBoxVisibility=$textBoxVisibility; Value=$data.value; TextBoxVisibility2=$textBoxVisibility2; Value2=$data.value2; Data=$data}
        <# $pos = #> $Elements.lvActions.Items.Add($itemData) | Out-Null
    }
}

Function Load-Tools {
    Param( $filter )
    
    $Elements.lvTools.Items.clear()
    
    if ($null -eq $filter) {
        $filter = ls "$($dir.tools)\*" |? {$_.Name -notlike "_.*" -and $_.Name -notlike ".*" }
    }
    
    $current, $avail = Get-PowershellInterpreter

    Foreach ($itemAorB in $filter) {
        # is string or object? We only want file items
        If ($null -ne $itemAorB.isSelected -and $null -ne $itemAorB.Name) {
            # the item is an tools item config: @{Name="...filename.ps1..."; isSelected=$true} object
            $item = gi "$($dir.tools)\$($itemAorB.Name)" -ErrorAction SilentlyContinue
        }
        elseif ($itemAorB.FullName) { # by the !$filter check, they are files
            # the item is a file object
            $item = $itemAorB
        }
        elseif ($itemAorB -is [string]) {
            # the item is a filename
            $item = gi "$($dir.tools)\$itemAorB" -ErrorAction SilentlyContinue
        }
        else {
            Write-ErrorClean "Unknown tools item type:"
            $itemAorB | Format-List | Out-String | Write-ErrorClean
            continue
        }
        
        if ($null -eq $item) {
            # gi *  might not actually found a file
            Write-ErrorClean "Tools file does not exist: '$($dir.tools)\$itemAorB'"
            continue
        }



        $ext = $item.Extension

        if ($item.Name.EndsWith(".x.ps1", [System.StringComparison]::OrdinalIgnoreCase)) {
            $ext = ".x.ps1"
        }

        switch ($ext) {
            ".ps1" { # get its own console window and own session
                $data = @{
                    type = "default"
                    execFn = [scriptblock]::Create("param(`$ctx); start " + $current + @"
                    -Verb RunAs " -ExecutionPolicy ByPass -Command ```"cd '$($item.DirectoryName)\' ; Import-Module ..\ps-modules\XAMLgui\ ; & '$($item.FullName)' `$ctx ; Read-Host 'Press Enter to close ...' ```" "
"@
                    )
                }
            }
            ".x.ps1" { # run in local session - and get ctx
                $data = @{
                    type = "psx"
                    execFn = [scriptblock]::Create("param(`$ctx) ; & '$($item.FullName)' `$ctx") # is filename
                }
            }
            default {
                $data = @{
                    type = "default"
                    execFn = [scriptblock]::Create("param(`$ctx) ; Start '$item' -WorkingDirectory '$($item.DirectoryName)' ")
                }
            }
        }
        
        $iconFile = Resolve-Path "$($dir.data)\default-app.png"  #fallback
        
        # cache icon
        try {
            $iconPath = Join-Path -Path $dir.cache -ChildPath ($item.Name -replace "\\","_")
            $iconFile = "$iconPath.bmp"
            
            If (!(Test-Path $iconFile)) { 
                [System.Drawing.Icon]::ExtractAssociatedIcon( $item.FullName ).ToBitmap().Save($iconFile)
                #Write-Host "writing file"
            }
            
            $iconFile = Resolve-Path $iconFile
        }
        catch {}
        
        $title = $item.Name
        If ($toolsExtHide -contains $item.Extension) {
            $title = $item.BaseName
        }
        
        $id = Resolve-Path $item.FullName -Relative
        
        <# $pos = #> $Elements.lvTools.Items.Add([PSCustomObject]@{Id=$id; Title=$title; Icon=[string]$iconFile; Folder="tools"; FilePath=$dir.tools; FileName=$item.Name; Data=$data}) | Out-Null
    }
    
    $ctx.toolsLoaded = $true
}


Function Prepare-Window {
    $MainWindow.title = "Deploymentor $VERSION"
}

Function Enable-Ui {
    Param( [bool]$Enable )
    
    $ctx.doCancel = $false   # always reset
    
    If ($Enable) {
        $Elements.tabControl.IsEnabled = $true
        $Elements.overlayCancel.Visibility = "Collapsed"
    }
    else {
        $Elements.tabControl.IsEnabled = $false
        $Elements.overlayCancel.Visibility = "Visible"
    }
}

Function Reset-Progressbars {
    $selectedItems = $Elements.lvSoftware.items |? IsSelected -eq $true
    $Elements.pbSoftware.Maximum = $selectedItems.Count
    $Elements.pbSoftware.Value = 0

    $selectedItems = $Elements.lvActions.items |? IsSelected -eq $true
    $Elements.pbActions.Maximum = $selectedItems.Count
    $Elements.pbActions.Value = 0
}

Function Reset-lastExecResults {
    $script:ctx.lastExecResults = @{}
}


Function Get-CtxTypeByFilename {
    param( $filename ) # allow filename strings and file objects

    $filenameStr = $filename;
    if ($filename.Name) {
        $filenameStr = $filename.Name
    }

    $resultExt = ""
    $resultCtxType = ""
    Foreach ($ext in $contextFormat.Keys) {
        if ($filenameStr.EndsWith($ext, [System.StringComparison]::OrdinalIgnoreCase)) {
            # in case there is a longer extension, use that one (support .x.ps1 for example)
            if ($ext.length -gt $resultExt.length) {
                $resultCtxType = $contextFormat[$ext]
                $resultExt = $ext
            }
        }
    }

    return $resultCtxType
}

Function Get-CtxTypeByExt {
    param($ext)

    return $contextFormat[$ext]
}

<# convert PS Objects to nice XML, specialized for $ctx (the lastExecResults part) #>
Function ConvertTo-NiceXml {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $InputObject,

        [Parameter()]
        [string]$RootName = "Objects",

        [Parameter()]
        [boolean]$Indent = $true
    )

    process {
        $settings = New-Object System.Xml.XmlWriterSettings
        $settings.Indent = $Indent
        $settings.IndentChars = "  "
        # This ensures that even if strings have leading/trailing spaces, they are preserved
        $settings.NewLineHandling = [System.Xml.NewLineHandling]::None 

        $stringBuilder = New-Object System.Text.StringBuilder
        $writer = [System.Xml.XmlWriter]::Create($stringBuilder, $settings)
        $writer.WriteStartDocument()

        function Write-Node {
            param($Name, $Value, $ParentName)

            # --- SPECIAL CASE: lastExecResults ---
            # Instead of <.\path\script.ps1 />, we create <result item=".\path\script.ps1">Value</result>
            if ($ParentName -eq "lastExecResults") {
                $writer.WriteStartElement("result")
                $writer.WriteAttributeString("item", $Name)
                if ($null -ne $Value) { $writer.WriteString([string]$Value) }
                $writer.WriteEndElement()
                return
            }

            # --- GENERAL CASE: Sanitize Key for Tag Name ---
            $CleanName = $Name -replace '[^a-zA-Z0-9_\-]', '_'
            if ($CleanName -match '^\d') { $CleanName = "v_$CleanName" }
            if ([string]::IsNullOrWhiteSpace($CleanName)) { $CleanName = "Item" }

            if ($Value -is [System.Collections.IDictionary]) {
                $writer.WriteStartElement($CleanName)
                foreach ($key in $Value.Keys) {
                    Write-Node -Name $key -Value $Value[$key] -ParentName $CleanName
                }
                $writer.WriteEndElement()
            }
            elseif ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string]) {
                $writer.WriteStartElement($CleanName)
                foreach ($item in $Value) {
                    Write-Node -Name "Item" -Value $item -ParentName $CleanName
                }
                $writer.WriteEndElement()
            }
            else {
                # Simple Leaf Node
                $writer.WriteStartElement($CleanName)
                if ($null -ne $Value) { 
                    # WriteString handles XML escaping (like < > &) automatically
                    $writer.WriteString([string]$Value) 
                }
                $writer.WriteEndElement()
            }
        }

        # Start recursion
        Write-Node -Name $RootName -Value $InputObject -ParentName ""

        $writer.WriteEndDocument()
        $writer.Flush()
        $writer.Close()

        return $stringBuilder.ToString()
    }
}

Function Convert-Ctx {
    Param( $ctx, [Alias("Type")][string]$ctxType )
    
    switch ($ctxType) {
        "native" { $ctxConverted = $ctx }
        "nativefile" { $ctxConverted = New-TemporaryFile; $ctx | Export-Clixml -Path $ctxConverted; $ctxConverted = "'" + $ctxConverted + "'" }
        "json" { $ctxConverted = "'" + ($ctx | ConvertTo-Json -Compress).replace("'","``'") + "'" }
        "jsonfile" { $ctxConverted = New-TemporaryFile; $ctx | ConvertTo-Json | Out-File $ctxConverted; $ctxConverted = "'" + $ctxConverted + "'" }
        #"xml" { $ctxConverted = "'" + ($ctx | ConvertTo-Xml -NoTypeInformation -As String).replace("'","``'").replace("`r","").replace("`n","") + "'" }
        "xml" { $ctxConverted = "'" + ($ctx | ConvertTo-NiceXml -RootName "Context" -Indent $false).replace("'","``'").replace("`r","").replace("`n","") + "'" }
        # "xmlfile" { $ctxConverted = New-TemporaryFile; $ctx | ConvertTo-Xml -NoTypeInformation -As String | Out-File $ctxConverted; $ctxConverted = "'" + $ctxConverted + "'" }
        "xmlfile" { $ctxConverted = New-TemporaryFile; $ctx | ConvertTo-NiceXml -RootName "Context" -Indent $true | Out-File $ctxConverted; $ctxConverted = "'" + $ctxConverted + "'" }
        default { $ctxConverted = New-TemporaryFile; $ctx | Format-List | Out-File $ctxConverted }
    }
    
    return $ctxConverted
}


Function Invoke-Actions {
    Param( $filter, [ref]$Counter )
    
    #! WARNING: this is not the same as $Elements.lvActions.SelectedItems - SelectedItems does not reliably contain all selected items - only if they have been selected by clicking (otherwise its random)
    $selectedItems = $Elements.lvActions.items |? IsSelected -eq $true

    Write-Host "Actions ($($selectedItems.Count))" -ForegroundColor Green
    
    # do actions, Value and Value2 are bound by the list item back into the data object, even if it did not have it in the first place
    $i = 0
    Foreach ($itemData in $selectedItems) { # only provides the data object
        If ($ctx.doCancel) {Enable-Ui $true; return}
        If ($global:DoCancel) {Enable-Ui $true; $global:DoCancel = $false; return}
        
        $i++
        If ($Counter) { $Counter.Value++ }

        Write-Host "Action #$i/$($selectedItems.Count) -> $($ItemData.FileName)(`"$($itemData.Value)`", `"$($itemData.Value2)`")" -ForegroundColor Green
        
        $ctx.item = @{
            CtxId = $itemData.Id;
            Folder=$itemData.Folder;
            FilePath=$itemData.FilePath;
            FileName=$itemData.FileName;
        }
        
        $ctxRet = Start-AwaitJob $itemData.Data.installFn -ArgumentList $ctx,$itemData.Value,$itemData.Value2 -Dir $itemData.FilePath -InitBlock $script:contextFNs
        $script:ctx.lastExecResults[$itemData.Id] = $ctXRet
        
        $Elements.pbActions.Value = $i
    }

    if ($selectedItems.Count) {
        Invoke-BalloonTip $( $selectedItems | Join-String -Property 'FileName' -Separator ', ' )   "Actions done #$i/$($selectedItems.Count)"
    }
}

Function Invoke-Software {
    Param( $filter, [ref]$Counter )

    #! WARNING: this is not the same as $Elements.lvSoftware.SelectedItems - SelectedItems does not reliably contain all selected items - only if they have been selected by clicking (otherwise its random)
    $selectedItems = $Elements.lvSoftware.items |? IsSelected -eq $true

    Write-Host "Apps ($($selectedItems.Count))" -ForegroundColor Green
    
    # do apps
    $i = 0
    Foreach ($itemData in $selectedItems) {
        If ($ctx.doCancel) {Enable-Ui $true; return}
        If ($global:DoCancel) {Enable-Ui $true; $global:DoCancel = $false; return}
        
        $i++
        If ($Counter) { $Counter.Value++ }
        
        Write-Host "Installing #$i/$($selectedItems.Count) -> $($itemData.FileName)" -ForegroundColor Green
        
        $ctx.item = @{
            CtxId = $itemData.Id;
            Folder=$itemData.Folder;
            FilePath=$itemData.FilePath;
            FileName=$itemData.FileName;
        }

        $ctxType = $itemData.Data.ctxType
        if (!$ctxType) {
            $ctxType = Get-CtxTypeByFilename $itemData.FileName
        }
        $ctxConverted = Convert-Ctx $ctx -Type $ctxType
        
        # Unblocking the UI !
        $ctxRet = Start-AwaitJob $itemData.Data.installFn -ArgumentList $($ctxConverted) -Dir $itemData.FilePath -InitBlock $script:contextFNs
        $script:ctx.lastExecResults[$itemData.Id] = $ctXRet
        
        Invoke-BalloonTip $itemData.FileName "App done #$i/$($selectedItems.Count)"
        
        $Elements.pbSoftware.Value = $i
    }
}

Function Invoke-Tool {
    Param( $itemData )
    
    Write-Host "Starting Tool $($itemData.Id) - $($itemData.Type)"

    try {
        $ctx.item = @{
            CtxId = $itemData.Id;
            Folder=$itemData.Folder;
            FilePath=$itemData.FilePath;
            FileName=$itemData.FileName;
        }

        $ctxType = $itemData.Data.CtxType
        if (!$ctxType) {
            $ctxType = Get-CtxTypeByFilename $itemData.FileName
        }
        $ctxConverted = Convert-Ctx $ctx -Type $ctxType

        #execute command
        if ($itemData.Data.type -eq "psx") {
            $ctxRet = Start-AwaitJob $itemData.Data.execFn -ArgumentList $($ctxConverted) -Dir $itemData.FilePath -InitBlock $script:contextFNs
            $script:ctx.lastExecResults[$itemData.Id] = $ctXRet
        }
        else {
            # context info for all
            & $itemData.data.execFn $ctxConverted
        }
    }
    catch {
        Write-ErrorClean ("Error executing tool: " + $itemData.Id)
        Write-Error $_
    }
}


Function Handle-AutoStart {
    $AutoStart = $AutoStart.ToLower()

    switch ($AutoStart) {
        'actions' { 
            Deploymentor.MainWindow.DoInstallActions_Click
        }
        'software' {
            Deploymentor.MainWindow.DoInstallSoftware_Click
        }
        'all' {
            Deploymentor.MainWindow.doInstallAll_Click
        }
        Default {}
    }
}

$didRunAutoStart = $false
$MainWindow.Add_ContentRendered({
    if ($didRunAutoStart) { return }
    $didRunAutoStart = $true

    Handle-AutoStart
})


# --- Titlebar Darkmode --------------------------



Function Set-DarkModeTitlebar {
    param (
        [System.Windows.Window]$Window,
        [bool]$IsDark
    )

    Add-Type -AssemblyName System.Runtime.InteropServices
    Add-Type -Namespace Deploymentor -Name DwmApi -MemberDefinition '
        [DllImport("dwmapi.dll", PreserveSig = true)]
        public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);
    '

    # 20 is the code for DWMWA_USE_IMMERSIVE_DARK_MODE on modern Windows
    $DWMWA_USE_IMMERSIVE_DARK_MODE = 20
    
    # Get standard window handle
    $interopHelper = New-Object System.Windows.Interop.WindowInteropHelper($Window)
    $hwnd = $interopHelper.Handle
    
    if ($hwnd -ne [IntPtr]::Zero) {
        $trueValue = if ($IsDark) { 1 } else { 0 }
        [Deploymentor.DwmApi]::DwmSetWindowAttribute($hwnd, $DWMWA_USE_IMMERSIVE_DARK_MODE, [ref]$trueValue, 4) | Out-Null
    }
}

# Window initialized
$MainWindow.Add_SourceInitialized({
    $Elements.tglDarkMode.IsChecked = ($darkMode -eq $true)
})

$Elements.tglDarkMode.Add_Checked({
    Set-DarkModeTitlebar -Window $MainWindow -IsDark $true
})
$Elements.tglDarkMode.Add_Unchecked({
    Set-DarkModeTitlebar -Window $MainWindow -IsDark $false
})



# --- INIT --------------------------------------------------------------------------------------



# Set window title
Prepare-Window
# In case I forgot to hide the cancel banner in Visual Studio again ...
Enable-Ui $true
# Reset for use
Reset-Progressbars

# Initial load
Load-ContextFns
Load-ProfileList
Load-ProfileByParam $ProfileSelected # or without :)

Write-Host "Waiting for main window to close."
$MainWindow | Show-Window

# Return to previous location
#Set-Location $backupPWD

# stop logging
Stop-Transcript -ErrorAction SilentlyContinue