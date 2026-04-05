#param ( $ctx )
param($ctxOrFileName)
# if is filename string (.ps1)
if ($ctxOrFileName -is [string]) {
    $ctx = Import-CliXml -Path $ctxOrFileName
}
else { # .x.ps1
    $ctx = $ctxOrFileName
}

Write-Host "CTX", ( $null -ne $ctx )

# started from Deploymentor
if ($ctx) {

    Import-LocalModule PollinationsAiPS

    Write-Host "_Get-PollinationsAiTextEx available:_", (get-command Get-PollinationsAiTextEx | out-string)
}
# manually started from command line
else {
    # fix: have some output dir
    $ctx = @{dir = @{actions = "$PSScriptRoot" }}

    Import-Module PollinationsAiPS
}

#write-host "Get-PollinationsAiTextEx: ", (Test-Path Function:Get-PollinationsAiTextEx)


# warn if no key, to use Get-PollinationsAiByok to set one up
if (-not $env:POLLINATIONSAI_API_KEY) {
    Write-Warning "No Pollinations.ai API key found, use Get-PollinationsAiByok to set one up"
    # temp key is used
    $key = 'sk_05Ray2pZpHdnQLq5wkJTBxNM7JH09Eqj' # Polly only
    $model = 'polly'
}
else {
    $key = $env:POLLINATIONSAI_API_KEY
    $model = if ($env:POLLINATIONSAI_API_MODEL) { $env:POLLINATIONSAI_API_MODEL } else { 'polly' }
}




$systemPrompt = @'
You are a sophisticated Powershell developer.

You write powershell scripts for Deploymentor, a deployment and rollout tool.

## Action example
```ps1
return @{
    # newline `n can be used, if you want to output 2 lables (1st row for first inputbox, 2nd row for second inputbox) with just 1 title.
    title = "Title`nMessage" #optional: if not given, the files's name is used. If newline is used, It gets split into tile and title2

    description = "Shows a messagebox" #optional: detault is empty

    isSelected = $TRUE  #optional: default is false, only used if a profile does not specify this

    hasValue = $TRUE   #optional: shows a text field next to the value
    Value = "Title"  #optional: if given, the textbox will be prefilled

    #title2 = "Message" #optional: shows a title for this value
    hasValue2 = $TRUE   #optional: shows a text field next to the value
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

        # Only use messagebox, if something dangerous is going to happen, or if asked for specific information to show
        Show-MessageBox $message $title
    }
}
```

## How to create:
You are able to save the created action to a file, filename can have spaces, but you must use the following template:

<SAVE as="filename only.ps1">
... the action code ...
</SAVE>

## What to create:
{{whatToCreate}}
'@


$whatToCreate = Read-Host "What action do you want to create"

if ($whatToCreate.Trim() -eq "") {
    return
}

$content = $systemPrompt -replace "{{whatToCreate}}", $whatToCreate

Write-Host "This can really take a while, please wait..."

try {
    $result = Get-PollinationsAiTextEx -Content $content -Model $model -POLLINATIONSAI_API_KEY $key
}
catch {
    Write-Host "ERROR: Failed to get response from Pollinations.ai ($model)"
    Write-Error $_
    return "FAILED"
}

Write-Host "Result: ------------------------------------------------------------------------"
Write-Host $result
Write-Host "--------------------------------------------------------------------------------"

# find <SAVE and get filename, and content between the save tags
if ($result -match '(?s)<SAVE as="(?<filename>.*?)">(?<content>.*)</SAVE>') {
    $filename = $Matches['filename']
    $content  = $Matches['content']

    # write content to file to $ctx.dir.actions, if file doesn't exist
    if (!(Test-Path "$($ctx.dir.actions)\$filename")) {
        #
    }
    else {
        Write-Host "File already exists: $($ctx.dir.actions)\$filename"
        $result = Read-Host "Do you want to overwrite it? (y/n)"
        if ($result -ne "y") {
            return
        }
    }
    $content | Out-File "$($ctx.dir.actions)\$filename"
    Write-Host "Saved to: $($ctx.dir.actions)\$filename"

    #return "Saved to: $($ctx.dir.actions)\$filename"
}
else {
    Write-Error "No <SAVE> tag found"
}