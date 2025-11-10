# =====================================================================================
# SCRIPT: Intune_Remediate_RemoteAccess.ps1
# DESCRIPTION: Intune Remediation - REMEDIATION Script
# Re-enables core admin firewall rules (Ping, Remote Registry, etc.).
#
# Original script authored by Rachel Bulmer. Sanitized for public portfolio.
# =====================================================================================

Write-Host "A misconfiguration was detected. Re-enabling core admin firewall rules..."

try {
    # Enable Ping
    Enable-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" -ErrorAction SilentlyContinue

    # Enable Remote Event Log Management
    Enable-NetFirewallRule -DisplayGroup "Remote Event Log Management" -ErrorAction SilentlyContinue
    Enable-NetFirewallRule -DisplayName "COM+ Network Access (DCOM-In)" -ErrorAction SilentlyContinue

    # Enable Remote Registry Access
    Enable-NetFirewallRule -DisplayGroup "Remote Service Management" -ErrorAction SilentlyContinue

    Write-Host "Core remote administration firewall rules have been re-enabled."
    exit 0
}
catch {
    Write-Host "An error occurred during remediation: $_"
    exit 1
}
