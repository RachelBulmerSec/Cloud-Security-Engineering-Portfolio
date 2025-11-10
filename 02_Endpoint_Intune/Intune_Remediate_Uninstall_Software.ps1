# =====================================================================================
# SCRIPT: Intune_Remediate_Uninstall_Software.ps1
# DESCRIPTION: Intune Remediation - REMEDIATION Script
# Detects and uninstalls specific unwanted software using WMI.
#
# Original script authored by Rachel Bulmer. Sanitized for public portfolio.
# =====================================================================================

# Define the names of the software to uninstall
$softwareNames = @(
    "Splashtop Streamer",
    "Splashtop Business"
    # Add any other unwanted software names here
)

# Use a separate process to avoid issues with WMI in Intune
Start-Process powershell -ArgumentList "-NoProfile -WindowStyle Hidden -Command {
    foreach (`$name in $using:softwareNames) {
        try {
            `$app = Get-WmiObject -Query ""SELECT * FROM Win32_Product WHERE Name = '`$name'"" -ErrorAction Stop
            if (`$app -ne `$null) {
                `$app.Uninstall() | Out-Null
                Write-Host ""Successfully uninstalled '`$name'""
            }
        }
        catch {
            Write-Host ""Could not uninstall '`$name' or it was not found.""
        }
    }
}" -NoNewWindow -Wait
