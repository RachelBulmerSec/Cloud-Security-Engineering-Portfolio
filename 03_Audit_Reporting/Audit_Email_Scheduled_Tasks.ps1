<#
.SYNOPSIS
    Retrieves all scheduled tasks on a local computer and emails the list
    as a CSV attachment using Exchange Online (Microsoft 365).
    
.DESCRIPTION
    This script is designed for high-security environments (e.g., Domain
    Controllers) where direct remote access may be limited. It fetches all
    scheduled tasks, saves them to a temporary CSV, emails the file,
    and then cleans up.

    Original script authored by Rachel Bulmer. Sanitized for public portfolio.
#>
[CmdletBinding()]
param()

# Define a path for the temporary file.
$tempFilePath = Join-Path -Path $env:TEMP -ChildPath "ScheduledTasks_$(hostname)_$(Get-Date -Format 'yyyyMMddHHmmss').csv"

try {
    # --- !! EDIT REQUIRED !! ---
    $To = "admin@your-domain.com"   # <-- Replace with your email address
    $From = "reports@your-domain.com" # <-- Replace with the sending account's email

    # --- Exchange Online SMTP Settings ---
    $SmtpServer = "smtp.office365.com"
    $SmtpPort = 587

    # Securely get credentials for the sending account
    $credential = Get-Credential -UserName $From -Message "Enter password for Exchange Online account: $From"

    # Get all scheduled tasks and select the desired properties
    $tasks = Get-ScheduledTask | Select-Object TaskName, TaskPath, State, Author, Description

    if ($null -eq $tasks) {
        Write-Warning "No scheduled tasks were found."
        return # Exit if there's nothing to send
    }

    # Export the task list to the temporary CSV file
    $tasks | Export-Csv -Path $tempFilePath -NoTypeInformation -Force

    # Prepare the parameters for Send-MailMessage
    $mailParams = @{
        To          = $To
        From        = $From
        SmtpServer  = $SmtpServer
        Port        = $SmtpPort
        Subject     = "Scheduled Task Report from $(hostname)"
        Body        = "Attached is the scheduled task report generated on $(Get-Date)."
        Attachments = $tempFilePath
        Credential  = $credential
        UseSsl      = $true
    }

    # Send the email
    Send-MailMessage @mailParams

    Write-Host "Successfully sent the scheduled tasks report to $To" -ForegroundColor Green
}
catch {
    Write-Error "An error occurred: $_"
}
finally {
    # This block will run whether the script succeeds or fails.
    if (Test-Path -Path $tempFilePath) {
        Remove-Item -Path $tempFilePath -Force -ErrorAction SilentlyContinue
    }
}
