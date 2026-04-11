<#
Info: EMLs can be send later, by dragging into outlook and clicking send
PROMPT to nova-fast

Manually: I had to fix line endings for the eml file
---

create an email as EML file with a small text that says the deployment of one computer is done.

from $env include 
- the computer name
- domain

and a list of existing users on the computer

receiver is support@example.com

subject should be something identifyable, starting with "[Deplyoment at Mainlocation] ..."

save as eml file to "$ctx.deploymentor.Root\EML Files" (path might not exist yet)
- filename should contain the compername and date

#>

return @{
    title = "Deployment Complete Notification"
    
    # newline `n can be used, if you want to output 2 rows of information.
    description = "Creates an EML file notification of deployment completion"

    isSelected = $FALSE  #optional: default is false, only used if a profile does not specify this. Only set to true if specifically requested.

    hasValue = $FALSE   #optional: shows a textbox next to the value for manual input in the GUI
    Value = $NULL  #optional: if given, the textbox will be prefilled

    title2 = "Email Receiver"
    hasValue2 = $TRUE   #optional: shows a textbox next to the value for manual input in the GUI
    Value2 = "support@example.com"  #optional: if given, the textbox will be prefilled

    # required
    installFn = {
        param($ctx, $placeholder, [string]$receiver)

        $crlf = "`r`n"

        $envComputerName = $env:COMPUTERNAME
        $envDomain = $env:USERDOMAIN
        $existingUsers = Get-LocalUser
        
        # Create the email content
        $subject = "[Deployment at Mainlocation] $envComputerName Deployment Complete"
        $body = "Deployment of $envComputerName in domain $envDomain is complete.`n`nExisting users:"
        foreach ($user in $existingUsers) {
            $body += "`n- $($user.Name)"
        }

        # Create the EML file
        $emlContent = @"
From: Deployment Automation <deployment@example.com>
To: $receiver
Subject: $subject
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 7bit

$body
"@ -replace "`r","" -replace "`n",$crlf
        
        $emlPath = Join-Path -Path $ctx.deploymentor.Root -ChildPath "EML Files"
        
        if (-not (Test-Path -Path $emlPath)) {
            New-Item -Path $emlPath -ItemType Directory | Out-Null
        }

        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $fileName = "$($env:COMPUTERNAME)_$timestamp.eml"
        $emlFilePath = Join-Path -Path $emlPath -ChildPath $fileName

        # Write the EML content to the file, using UTF-8 encoding with no BOM
        [System.IO.File]::WriteAllText($emlFilePath, $emlContent, [System.Text.UTF8Encoding]::new($false))
        
        Write-Host "Email notification saved to $emlFilePath"
    }
}

