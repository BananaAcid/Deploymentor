return @{

    #title = "Location Number TWO"  # optional


    # folders in .\software to be highlighted
    software = @(
        @{Name="hello world"; isSelected=$true}
        "dump direct"
        "hello world"
    )

    # files in .\actions to be highlighted
    actions = @(
        "restart with admin privileges.ps1"
        "show message.ps1"
        "Action Minimal.ps1"
    )

    tools = @(
        "dump ctx.lastActionRet.x.ps1"
    )

}