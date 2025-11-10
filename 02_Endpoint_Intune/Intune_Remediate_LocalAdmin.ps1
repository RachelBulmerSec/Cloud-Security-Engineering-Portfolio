# =====================================================================================
# SCRIPT: Intune_Remediate_LocalAdmin.ps1
# DESCRIPTION: Intune Remediation - REMEDIATION Script
# Removes the local administrator account identified by the detection script.
#
# Original script authored by Rachel Bulmer. Sanitized for public portfolio.
# =====================================================================================

$userName = "LAdmin" # <-- Specify the rogue admin account name here

try {
    # Ensure the user actually exists before attempting removal
    $user = Get-LocalUser -Name $userName -ErrorAction SilentlyContinue
    
    if ($user) {
        Remove-LocalUser -Name $userName -ErrorAction Stop
        Write-Host "Successfully removed user '$userName'."
        exit 0 # Exit 0 to report the fix was successful.
    } else {
        Write-Host "User '$userName' does not exist. No action needed."
        exit 0 # Report success as the end state is compliant.
    }
}
catch {
    Write-Host "Failed to remove user '$userName'. Error: $_"
    exit 1 # Exit 1 to report the fix failed.
}
