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
}
