# =====================================================================================
# SCRIPT: Utility_Test_RemoteAccess.ps1
# DESCRIPTION: Remotely diagnoses connectivity, firewall, and service status for
#              Windows remote administration.
#
# Original script authored by Rachel Bulmer. Sanitized for public portfolio.
# =====================================================================================

param (
    [string]$computerName = (Read-Host "Enter the remote computer name or IP")
)

Write-Host "--- Starting remote diagnostics for $computerName ---" -ForegroundColor Yellow

# Step 1: Check Basic Network Connectivity (Ping)
Write-Host "`n[Step 1] Testing network connection..."
if (Test-Connection -ComputerName $computerName -Count 1 -Quiet) {
    Write-Host "  [SUCCESS] Ping successful. The computer is reachable on the network." -ForegroundColor Green
} else {
    Write-Host "  [FAIL] Ping failed. The computer is unreachable or blocking ICMP." -ForegroundColor Red
    Write-Host "--- Diagnostics stopped. ---" -ForegroundColor Yellow
    return # Exit script if ping fails
}

# Step 2 & 3: Remotely Check Firewall and Services
Write-Host "`n[Step 2 & 3] Connecting to remotely check Firewall and Services..."
try {
    Invoke-Command -ComputerName $computerName -ScriptBlock {
        Write-Host "`n--- Checking Firewall Rules ---"
        
        # Define the rules/groups to check
        $firewallChecks = @{
            "Remote Event Log Group" = Get-NetFirewallRule -DisplayGroup "Remote Event Log Management" -ErrorAction SilentlyContinue | Where-Object { $_.Enabled }
            "COM+ Network Access Rule" = Get-NetFirewallRule -DisplayName "COM+ Network Access (DCOM-In)" -ErrorAction SilentlyContinue | Where-Object { $_.Enabled }
            "Remote Registry Group" = Get-NetFirewallRule -DisplayGroup "Remote Service Management" -ErrorAction SilentlyContinue | Where-Object { $_.Enabled }
            "Ping (ICMP) Rule" = Get-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" -ErrorAction SilentlyContinue | Where-Object { $_.Enabled }
        }

        foreach ($name in $firewallChecks.Keys) {
            if ($firewallChecks[$name]) {
                Write-Host "  [ENABLED] $name" -ForegroundColor Green
            } else {
                Write-Host "  [DISABLED] $name" -ForegroundColor Red
            }
        }

        Write-Host "`n--- Checking Services ---"

        # Define services to check
        $services = @("RpcSs", "EventLog", "RemoteRegistry")
        foreach ($service in $services) {
            $svc = Get-Service -Name $service
            if ($svc.Status -eq 'Running') {
                Write-Host "  [RUNNING] $($svc.DisplayName)" -ForegroundColor Green
            } else {
                Write-Host "  [STOPPED] $($svc.DisplayName)" -ForegroundColor Red
            }
        }
    }
    Write-Host "`n--- Diagnostics complete. ---" -ForegroundColor Yellow

} catch {
    Write-Host "`n  [FAIL] Could not connect via PowerShell Remoting (WinRM)." -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)"
    Write-Host "  Please ensure WinRM is enabled on the remote computer with 'Enable-PSRemoting -Force'."
    Write-Host "--- Diagnostics stopped. ---" -ForegroundColor Yellow
}
