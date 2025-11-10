# This script audits all shared mailboxes for last login and last email
# access activity within a 30-day period.
#
# Original script authored by Rachel Bulmer. Sanitized for public portfolio.

# Prerequisites:
# - Exchange Online PowerShell Module (EXO V2 or V3)
# - Run 'Connect-ExchangeOnline' before executing.

# Get all shared mailboxes
$sharedMailboxes = Get-Mailbox -RecipientTypeDetails SharedMailbox | Select-Object DisplayName, PrimarySmtpAddress

# Initialize results array
$results = @()

foreach ($mailbox in $sharedMailboxes) {
    Write-Host "Checking mailbox: $($mailbox.DisplayName)"
    
    # Get last login activity (if any)
    $loginAudit = Search-UnifiedAuditLog -Operations MailboxLogin -StartDate (Get-Date).AddDays(-30) -EndDate (Get-Date) -UserIds $mailbox.PrimarySmtpAddress -ErrorAction SilentlyContinue
    $lastLogin = if ($loginAudit) { ($loginAudit | Sort-Object CreationDate -Descending | Select-Object -First 1).CreationDate } else { "No direct login found" }

    # Get last activity (email read, sent, or modified)
    $activityAudit = Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-30) -EndDate (Get-Date) -Operations MailItemsAccessed, SendOnBehalf, SendAs -ErrorAction SilentlyContinue | Where-Object {$_.AuditData -match $mailbox.PrimarySmtpAddress}
    $lastActivity = if ($activityAudit) { ($activityAudit | Sort-Object CreationDate -Descending | Select-Object -First 1).CreationDate } else { "No activity found" }

    # Store results
    $results += [PSCustomObject]@{
        DisplayName     = $mailbox.DisplayName
        PrimarySmtp     = $mailbox.PrimarySmtpAddress
        LastLogin       = $lastLogin
        LastEmailAccess = $lastActivity
    }
}

# Display results
$results | Format-Table -AutoSize

# Optional: Export to CSV
# $results | Export-Csv -Path "C:\Temp\SharedMailbox_AccessReport.csv" -NoTypeInformation
