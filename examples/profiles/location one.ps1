return @{

    title = "Error Testing"  # optional

    actionsFirst = $false

    software = @(
        @{Name="Some name"; Selected=$true}   # error -> must be isSelected
        "none existant"     # error -> folder does not exist
        "empty"             # error -> has no deployment file
        $true               # error -> bool is not a folder
        ""                  # error -> \software is checked for a deployment file
    )

    actions = @(

    )

    #tools = $null   === all, for empty use @()
    
}