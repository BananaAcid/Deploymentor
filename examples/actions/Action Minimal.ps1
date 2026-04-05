return @{
    
    # required
    installFn = {
        param($ctx, [string]$title = "Warning", [string]$message = "Some Messagebox Text")
        
        Write-Host "Messagebox: $title`n$message" # always log to console as well!
        Show-MessageBox $message $title
    }
}