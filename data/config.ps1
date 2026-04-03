$darkMode = $true


$dir = @{
    data = ".\data"
    cache = ".\data\cache"
    profiles = ".\profiles"

    actions = ".\actions"
    software = ".\software"
    tools = ".\tools"
}

# when showing the button caption, remove the extension from the displayed caption
$toolsExtHide = @(".lnk", ".exe")

$showConsole = $true

<#
    dpx - parse as Deploymentor file. Is parsed for additional info, special Deploymentor file: must return Description, installFn
    ps - just start it
    wsh - start it with windows schipting host
    exec - just start it
#>
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
    ".x.ps1" = "native"     # tool in same session -- like an action or software
    ".vbs" = "xml"          # xml str as param 1 to script (probably buggy)
    ".wsf" = "xml"          # xml str as param 1 to script (probably buggy)
    ".js"  = "json"         # json str as param 1 (probably buggy)
    ".bat" = ""             # defaults to key:val list in temp-file
    ".cmd" = ""             # defaults to key:val list in temp-file
    ".exe" = "jsonfile"     # is a temp jsonfile as param 1 to executable
    ".msi" = "xmlfile"      # is a temp xmlfile as param 1 to executable
    ".sh"  = "jsonfile"     # is a temp jsonfile as param 1 to script / linux has usually `jq`/`awk` nativly installed
}