# This script queries the local machine to verify which Attack Surface
# Reduction (ASR) rules are active and what their state is (Block, Audit, etc.).
#
# Original script authored by Rachel Bulmer. Sanitized for public portfolio.

# Get the rule IDs and their corresponding actions from Defender preferences
$ruleIds = (Get-MpPreference).AttackSurfaceReductionRules_Ids
$ruleActions = (Get-MpPreference).AttackSurfaceReductionRules_Actions

# Check if any rules are configured
if ($ruleIds) {
    # Create a custom table to display the results clearly
    $asrRules = for ($i = 0; $i -lt $ruleIds.Count; $i++) {
        # Translate the action number into a readable state
        $actionState = switch ($ruleActions[$i]) {
            0       { "Disabled" }
            1       { "Block" }
            2       { "Audit" }
            6       { "Warn" }
            default { "Unknown" }
        }
        
        # Output a custom object for each rule
        [PSCustomObject]@{
            GUID   = $ruleIds[$i]
            State  = $actionState
        }
    }
    # Display the final table
    $asrRules | Format-Table -AutoSize
} else {
    Write-Host "No Attack Surface Reduction rules are configured." -ForegroundColor Yellow
}
