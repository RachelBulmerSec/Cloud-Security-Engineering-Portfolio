# =====================================================================================
# SCRIPT: Intune_Detect_LocalAdmin.ps1
# DESCRIPTION: Intune Remediation - DETECTION Script
# Detects if a specified local administrator account exists.
#
# Original script authored by Rachel Bulmer. Sanitized for public portfolio.
#
# EXIT CODES:
#   Exit 0 = Compliant (account does NOT exist)
#   Exit 1 = Non-Compliant (account EXISTS)
# =====================================================================================

$userName = "LAdmin" # <-- Specify the rogue admin account name here

try {
    $userExists = (Get-LocalUser -Name $userName -ErrorAction SilentlyContinue)

    if ($userExists) {
        Write-Host "NON-COMPLIANT: Rogue admin account '$userName' was found."
        Exit 1 # Account exists, remediation is needed
    } else {
        Write-Host "COMPLIANT: Account '$userName' not found."
        Exit 0 # Account does not exist, no remediation needed
    }
}
catch {
    # This catch block handles any unexpected errors during Get-LocalUser
    Write-Host "An error occurred during detection. Error: $_"
    Exit 1 # Assume non-compliant on error
}
