# This script uses the Microsoft Graph PowerShell SDK to audit all users
# in a tenant and identify those with no MFA methods registered.
#
# Original script authored by Rachel Bulmer. Sanitized for public portfolio.

# Prerequisites:
# - Microsoft Graph PowerShell SDK modules: Microsoft.Graph.Authentication, Microsoft.Graph.Identity.SignIns
# - Run 'Connect-MgGraph -Scopes "User.Read.All","UserAuthenticationMethod.Read.All"' before executing.

# 1. Get all users in the tenant
Write-Host "Getting all users..."
$allUsers = Get-MgUser -All -ErrorAction Stop

# 2. Create a list to hold the report of users without MFA
$nonMfaReport = [System.Collections.Generic.List[object]]::new()

Write-Host "Checking each user for registered MFA methods. This may take a while..."

# 3. Loop through each user and check their methods
foreach ($user in $allUsers) {
    try {
        # Get the registered authentication methods for the user
        $authMethods = Get-MgUserAuthenticationMethod -UserId $user.Id -ErrorAction Stop

        # If the user has NO registered methods ($authMethods is null), add them to the report
        if ($null -eq $authMethods) {
            $nonMfaReport.Add([PSCustomObject]@{
                DisplayName       = $user.DisplayName
                UserPrincipalName = $user.UserPrincipalName
                AccountEnabled    = $user.AccountEnabled
            })
        }
    }
    catch {
        Write-Warning "Could not check user $($user.UserPrincipalName). Error: $($_.Exception.Message)"
    }
}

# 4. Display the final report on the screen
Write-Host "The following users do not have any MFA methods registered:" -ForegroundColor Green
$nonMfaReport | Sort-Object DisplayName | Format-Table

# 5. Optionally, export this list to a CSV file for follow-up
# $nonMfaReport | Export-Csv -Path "C:\Temp\UsersWithoutMFA.csv" -NoTypeInformation
