#param ( $ctx )
param($ctxOrFileName)
# if is filename string (.ps1)
if ($ctxOrFileName -is [string]) {
    $ctx = Import-CliXml -Path $ctxOrFileName
}
else { # .x.ps1
    $ctx = $ctxOrFileName
}

# started from Deploymentor
if ($ctx) {

    Import-LocalModule PollinationsAiPS

    Write-Host "_Get-PollinationsAiTextEx available:_", (get-command Get-PollinationsAiTextEx | out-string)

    Import-LocalModule Create-Menu
    # Write-Host "_Create-Menu available:_", (get-command Create-Menu | out-string)
}
# manually started from command line
else {
    Write-Host "No CTX provided - saving action to $PSScriptRoot", ( $null -ne $ctx )

    # fix: have some output dir
    $ctx = @{dir = @{actions = "$PSScriptRoot" }}

    Import-Module PollinationsAiPS

    Import-Module Create-Menu
}

#write-host "Get-PollinationsAiTextEx: ", (Test-Path Function:Get-PollinationsAiTextEx)


# load Create-Menu and instantiate it from GIST.GITHUB
# #Write-Host "_Create-Menu available:_", (New-Module -Name "Create Menu TUI" -ScriptBlock ([Scriptblock]::Create((New-Object System.Net.WebClient).DownloadString("https://gist.githubusercontent.com/BananaAcid/b8efca90cc6ca873fa22a7f9b98d918a/raw/cab61f5a367c73aead7bdf425cc784338efaab27/Create-Menu.ps1"))) | out-string)
# $createMenuFile = "$($ctx.dir.psmodules)\Create-Menu.ps1"
# If (-not (Test-Path "$createMenuFile")) {
#     Invoke-WebRequest "https://gist.githubusercontent.com/BananaAcid/b8efca90cc6ca873fa22a7f9b98d918a/raw/cab61f5a367c73aead7bdf425cc784338efaab27/Create-Menu.ps1" -OutFile "$createMenuFile"
# }
# New-Module -Name "Create Menu TUI" -ScriptBlock ([Scriptblock]::Create((Get-Content "$createMenuFile" -raw))) | Out-Null




# --- API Key handling -------------------------------

# debug
$noKey = $false

$key = $env:POLLINATIONSAI_API_KEY
# warn if no key, to use Get-PollinationsAiByok to set one up
if (-not $key -or $noKey) {
    switch ( Create-Menu -Title "No Pollinations.ai API key found`n" -ForegroundColor Yellow -Options "Use Temp Key","Enter your own key (temporary)","Connect your Pollinations account (BYOK)"  -MaximumColumnWidth ($Host.UI.RawUI.MaxWindowSize.Width -2) ) {
        0 { $key = 'sk_05Ray2pZpHdnQLq5wkJTBxNM7JH09Eqj' } # selected models by me only.
        1 { $key = Read-Host "Enter your Pollinations.ai API key temporary" }
        2 { Get-PollinationsAiByok }
    }

    if (-not $key) {
        Write-Host "`n`nNo key provided, exiting" -ForegroundColor Red
        return
    }
}

# --- Model handling -------------------------------

$model = $env:POLLINATIONSAI_API_MODEL
if (-not $model) {
    Write-Host "`n`n"
    $models = 'nova-fast', 'qwen-coder'  #'polly'
    $modelsTitles = 'Amazon Nova Micro (nova-fast, quick and simple results)', 'Qwen3 Coder 30B (qwen-coder, slower and complex results)', 'all models ...' #, 'Polly (polly, very slow and good for really complex tasks, can search the web - only few uses)'
    $modelSel = $modelsTitles | Create-Menu -Title "Select model:`n" -MaximumColumnWidth ($Host.UI.RawUI.MaxWindowSize.Width -2) # make it a vertical menu
    $model = $models[$modelSel]
    Write-Host "`n`n"

    if (-not $model) {
        # yes Global: because the scriptblocks are imported as string into the module scope of Create-Menu to have access the required vars - so we need to use Global: to pass $models in to the module scopes scriptblock
        $Global:models = Get-PollinationsAiTextEx -List -Details -AvailableOnlyList -POLLINATIONSAI_API_KEY $key
        $modelsTitles = $Global:models |% { $(if ($_.aliases[0]) { $_.aliases[0] } else { $_.name }) }
        $modelSel = $modelsTitles | Create-Menu -Title "Select model:`n" -Footer { "⭐ $(($Global:models |? {$_.Name -eq $SelectionValue -or $_.aliases -contains $SelectionValue } | Select -First 1).description)`nModels: https://enter.pollinations.ai/. Only those are shown, that you have enabled with your API KEY." }
        $model = $Global:models[$modelSel].name
    }
}


# --- Prompt handling -------------------------------


$systemPrompt = @'
You are a sophisticated Powershell developer.

You write powershell scripts for Deploymentor, a deployment and rollout tool.

## Action example
```ps1
return @{
    title = "Title" #optional: if not given, the files's name is used.
    
    # newline `n can be used, if you want to output 2 rows of information.
    description = "Shows a messagebox" #optional: detault is empty

    isSelected = $FALSE  #optional: default is false, only used if a profile does not specify this. Only set to true if specifically requested.

    # only use if a manual input of this value is needed, this will be passed to the installFn after $ctx as value var
    hasValue = $TRUE   #optional: shows a textbox next to the value for manual input in the GUI. If true, the 'title=' (from above) is next to the textbox in the GUI
    Value = "Title"  #optional: if given, the textbox will be prefilled

    # only use if a manual input of this value is needed, this will be passed to the installFn after the first value var
    title2 = "Message" #optional: shows a title for this value
    hasValue2 = $TRUE   #optional: shows a textbox next to the value for manual input in the GUI
    Value2 = "Message"  #optional: if given, the textbox will be prefilled


    # .. using Value here, allows the use of variables - like accessing $global:ctx
    #   Value = "Current profile: $($global:ctx.activeProfile.Title)"  #optional: if given, the textbox will be prefilled
    
    # instead of hasValue and Value, the installFn params can be used, but with defaults only as string

    # required
    installFn = {
        # $ctx is mandatory (and must always be the first param named $ctx), optional values only if needed
        param($ctx, <#Value#>[string]$title, <#Value2#>[string]$message)
        
        # Import another module from the main ps-modules folder.
        #Import-LocalModule SomeOtherImportantModule -Path ..\ps-modules
        # using `Import-LocalModule`, the module will be downloaded into .\ps-modules if missing

        # Some Modules and functions are preloaded,
        # you have access to all of XAMLGui, ConvertTo-NiceXml, native Expand-Archive (un-zip), ...

        Write-Host "Messagebox: $title`n$message" # always log to console as well!

        # Only use a messagebox, if something dangerous is going to happen, or if asked for specific information to show
        Show-MessageBox $message $title
    }
}
```

## How to create:
You are able to save the created action to a file
- Filename can have spaces
- Mind how escaping works in powershell (with backtick instead of backslash)
- Do not forget to Escape $var in Descriptions and Titles if it is ment to be text
- Drop default comments from the example
- The action's code is between the <SAVE as="..."> and </SAVE>

You must use the following template (and no code-fencing blocks):

<SAVE as="filename only.ps1">
... the action code ...
</SAVE>

## What to create:
{{whatToCreate}}
'@

Write-Host ""
Write-Host @'
Example prompts:

    Get current internet IP and store it in $Global:CurrentOnlineIp, show no messagebox

    Check which protocols are enabled and store them in $Global:CurrentIPv4Enabled and $Global:CurrentIPv6Enabled

    Check which DNS servers are used and store them in $Global:CurrentIPv4DnsServers and $Global:CurrentIPv6DnsServers

    Check which Office versions are installed and store them in $Global:CurrentOfficeVersions

    Remove all installed Office versions

'@


$whatToCreate = Read-Host "What action do you want to create"

if ($whatToCreate.Trim() -eq "") {
    return
}

$content = $systemPrompt -replace "{{whatToCreate}}", $whatToCreate

do {

    Write-Host "This can really take a while, please wait..."

    try {
        $result = Get-PollinationsAiTextEx -Content $content -Model $model -POLLINATIONSAI_API_KEY $key -bypassCache
    }
    catch {
        Write-Host "ERROR: Failed to get response from Pollinations.ai ($model)" -back red -fore black
        #Write-Host "ERROR: $($_.Exception.Message | Format-List | Out-String)" -back red -fore black
        Write-Error $_
        return "FAILED"
    }

    Write-Host "Result: ------------------------------------------------------------------------" -ForegroundColor Green
    Write-Host $result -ForegroundColor Blue
    Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Green


    # --- Save to file -------------------------------


    # find <SAVE and get filename, and content between the save tags
    if ($result -match '(?s)<SAVE as="(?<filename>.*?)">(?<content>.*)</SAVE>') {
        $filename = $Matches['filename']
        $content  = $Matches['content']

        if ( (Read-Host "Do you want to save it? (Y/n)") -eq "n") {
            return "- No"
        }
            
        # write content to file to $ctx.dir.actions, if file doesn't exist
        if (!(Test-Path "$($ctx.dir.actions)\$filename")) {
            #
        }
        else {
            Write-Host "File already exists: $($ctx.dir.actions)\$filename"
            if ( (Read-Host "Do you want to overwrite it? (y/N)") -ne "y") {
                return "- No"
            }
        }
        $content | Out-File "$($ctx.dir.actions)\$filename"
        Write-Host "Saved to: $($ctx.dir.actions)\$filename"

        Write-Host "`nMake sure you check the file content before running it!`n" -ForegroundColor Yellow

        switch (Create-Menu -Title "Open file now?`n" -Options "No", "VSCode", "Notepad") {
            1 { Start-Process "code" "$($ctx.dir.actions)\$filename" }
            2 { Start-Process "notepad.exe" "$($ctx.dir.actions)\$filename" }
            default { }
        }


        #return "Saved to: $($ctx.dir.actions)\$filename"
    }
    else {
        Write-Error "No <SAVE> tag found"

        if ( (Read-Host "Do you want to let the AI retry? (y/N)") -ne "y") {
            $retry = $true
        }
    }

} while ($retry)