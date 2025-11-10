# This script is an admin utility to securely generate a new, strong,
# random password for an Azure AD user.
#
# Original script authored by Rachel Bulmer. Sanitized for public portfolio.

# Prerequisites:
# - AzureAD PowerShell Module
# - Run 'Connect-AzureAD' before executing.

# Prompt for the ObjectId of the user
$userId = Read-Host "Enter the ObjectId or UserPrincipalName of the user"

# Generate a strong random password
try {
    Add-Type -AssemblyName System.Web
    $Password = [System.Web.Security.Membership]::GeneratePassword(32, 4)

    # Convert to secure string
    $SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force

    # Set the new password
    Set-AzureADUserPassword -ObjectId $userId -Password $SecurePassword -ErrorAction Stop

    # Output the new password
    Write-Host "New password for user $userId is: $Password" -ForegroundColor Green
}
catch {
    Write-Error "Failed to reset password for $userId. Error: $_"
}
