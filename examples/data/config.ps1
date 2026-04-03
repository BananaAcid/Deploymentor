# ALL variables are REQUIRED in the main config, if -Config param is used,
#  the provided config may only contain what is supposed to be overwriten

$darkMode = $true

# paths are relative to this config
$dir = @{
    data = "..\data"
    cache = "..\data\cache"
    profiles = "..\profiles"

    actions = "..\actions"
    software = "..\software"
    tools = "..\tools"
}
