# =====================================================================================
# SCRIPT: Intune_Detect_RemoteAccess.ps1
# DESCRIPTION: Intune Remediation - DETECTION Script
# Checks if core remote admin firewall rules (Ping, Remote Registry) are enabled.
#
# Original script authored by Rachel Bulmer. Sanitized for public portfolio.
#
# EXIT CODES:
#   Exit 0 = Compliant (All rules are enabled)
#   Exit 1 = Non-Compliant (One or more rules are disabled)
# =====================================================================================

try {
    $rulesToVerify = @(
        "File and Printer Sharing (Echo Request - ICMPv4-In)",
        "COM+ Network Access (DCOM-In)"
    )
    $groupsToVerify = @(
        "Remote Event Log Management",
        "Remote Service Management"
    )

    $allRulesEnabled = $true

    foreach ($ruleName in $rulesToVerify) {
        $rule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
        if (-not $rule -or $rule.Enabled -ne "True") {
            Write-Host "NON-COMPLIANT: Rule '$ruleName' is disabled or not found."
            $allRulesEnabled = $false
        }
    }
    
    foreach ($groupName in $groupsToVerify) {
        $rulesInGroup = Get-NetFirewallRule -DisplayGroup $groupName -ErrorAction SilentlyContinue
        if (-not $rulesInGroup -or ($rulesInGroup | Where-Object { $_.Enabled -ne "True" })) {
            Write-Host "NON-COMPLIANT: One or more rules in group '$groupName' are disabled."
            $allRulesEnabled = $false
        }
    }

    if ($allRulesEnabled) {
        Write-Host "COMPLIANT: All required remote access firewall rules are enabled."
        exit 0
    } else {
        exit 1
    }
}
catch {
    Write-Host "An error occurred during detection: $_"
    exit 1
}
