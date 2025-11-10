# This script discovers sign-in capable Service Principals in an Azure AD tenant,
# analyzes their direct and inherited (via group membership) Azure RBAC roles and
# Microsoft Entra ID / Graph API permissions, and generates a comprehensive report.
#
# Original script authored by Rachel Bulmer. Sanitized for public portfolio.

# Prerequisites:
# - Azure PowerShell Az modules: Az.Accounts, Az.Graph, Az.Resources
# - Microsoft Graph PowerShell SDK modules: Microsoft.Graph.Authentication, Microsoft.Graph.Applications, Microsoft.Graph.Groups, Microsoft.Graph.Identity.DirectoryManagement
# - ImportExcel PowerShell module (for Excel export)

#region Configuration
$reportOutputPath = "C:\Temp\ServicePrincipalPermissionsReport.xlsx" # Output for the final report

# Define App IDs to exclude from common Microsoft applications
$microsoftAppIdsToExclude = @(
    "00000002-0000-0000-c000-000000000000", # Microsoft Graph
    "1950a258-227b-4e31-a9cf-717495945fc2", # Azure CLI
    "1edb8580-c13f-4e2b-b5d1-678b40ec7c2b", # Azure Resource Manager
    "0000000a-0000-0000-c000-000000000000", # Other common Microsoft apps
    "c44b4088-3bb0-49c1-b47d-974e53cbdfc6"  # Azure PowerShell
)

# Define prefixes for your internal/custom service principals to prioritize or include
$yourCustomAppPrefixes = @(
    "your-internal-app-prefix-",
    "my-automation-"
)
#endregion

Write-Host "--- Starting Combined Script: Discovering and Analyzing Service Principal Permissions ---" -ForegroundColor Green

#region Azure Connection Check
Write-Host "`n--- Connecting to Azure ---" -ForegroundColor Yellow
try {
    $currentAzContext = Get-AzContext -ErrorAction Stop
    Write-Host "Connected to Azure tenant: $($currentAzContext.Tenant.Id) (Name: $($currentAzContext.Tenant.Name))" -ForegroundColor Green
}
catch {
    Write-Error "Not connected to Azure. Please run 'Connect-AzAccount' first."
    exit 1
}
#endregion

#region Connect to Microsoft Graph
Write-Host "`n--- Connecting to Microsoft Graph ---" -ForegroundColor Yellow
try {
    Connect-MgGraph -Scopes "Application.Read.All", "Directory.Read.All", "Group.Read.All", "RoleManagement.Read.Directory", "RoleManagement.Read.All" -ErrorAction Stop
    Write-Host "Connected to Microsoft Graph for permission analysis." -ForegroundColor Green
} catch {
    Write-Error "Could not connect to Microsoft Graph. Ensure you have the necessary permissions granted and run 'Connect-MgGraph'."
    exit 1
}
#endregion

#region 1. Discover Sign-in Capable Service Principals
Write-Host "`n--- Discovering Sign-in Capable Service Principals ---" -ForegroundColor Yellow
try {
    $foundServicePrincipals = Get-AzADServicePrincipal |
        Where-Object {
            ($_.AppId -notin $microsoftAppIdsToExclude) -and
            (
                ($_.AppId -eq $_.Id) -or
                ($_.SignInAudience -eq "AzureADMyOrg") -or
                ($yourCustomAppPrefixes | ForEach-Object { $_.StartsWith($_.DisplayName) }) -contains $true 
            ) -and
            (
                ($_.PasswordCredentials -ne $null -and $_.PasswordCredentials.Count -gt 0) -or
                ($_.KeyCredentials -ne $null -and $_.KeyCredentials.Count -gt 0)
            )
        } |
        Select-Object DisplayName, Id, AppId, SignInAudience,
            @{Name='HasSecrets'; Expression={$_.PasswordCredentials.Count -gt 0}},
            @{Name='HasCertificates'; Expression={$_.KeyCredentials.Count -gt 0}},
            @{Name='SecretExpirationDates'; Expression={($_.PasswordCredentials | Select-Object -ExpandProperty EndDate | Sort-Object | ForEach-Object { $_.ToString("yyyy-MM-dd") }) -join ', '}},
            @{Name='CertificateExpirationDates'; Expression={($_.KeyCredentials | Select-Object -ExpandProperty EndDate | Sort-Object | ForEach-Object { $_.ToString("yyyy-MM-dd") }) -join ', '}}

}
catch {
    Write-Error "An error occurred during service principal discovery: $($_.Exception.Message)"
    exit 1
}

if ($foundServicePrincipals.Count -eq 0) {
    Write-Host "No sign-in capable service principals found matching the criteria. Nothing to analyze." -ForegroundColor Yellow
    exit 0 
}
else {
    Write-Host "Found $($foundServicePrincipals.Count) sign-in capable service principals." -ForegroundColor Green
}
#endregion

#region 2. Analyze Permissions for Each Service Principal
Write-Host "`n--- Analyzing Permissions for Found Service Principals ---" -ForegroundColor Yellow

$analysisResults = @() 

foreach ($sp in $foundServicePrincipals) {
    Write-Host "`nAnalyzing: $($sp.DisplayName) (ObjectId: $($sp.Id))" -ForegroundColor Cyan

    $currentSpAnalysis = [PSCustomObject]@{
        DisplayName           = $sp.DisplayName
        ObjectId              = $sp.Id
        HasSecrets            = $sp.HasSecrets
        HasCertificates       = $sp.HasCertificates
        SecretExpirationDates = $sp.SecretExpirationDates
        CertExpirationDates   = $sp.CertificateExpirationDates
        AzureRBACText         = "No direct RBAC roles found."
        GraphAPIPermissions   = "No explicit Graph API permissions."
        GroupMemberships      = "No group memberships found."
        InheritedRBACText     = "No inherited RBAC roles from groups."
        InheritedGraphAPIText = "No inherited Graph API permissions from groups."
    }

    #region Check Azure RBAC Roles (Direct)
    Write-Host "  -- Checking Direct Azure RBAC Roles --"
    try {
        $roleAssignments = Get-AzRoleAssignment -ObjectId $sp.Id -ErrorAction SilentlyContinue

        if ($roleAssignments) {
            $rbacDetails = $roleAssignments | Select-Object @{Name='RoleName'; Expression={$_.RoleDefinitionName}}, Scope | Format-Table -AutoSize | Out-String
            $currentSpAnalysis.AzureRBACText = $rbacDetails.Trim()
            Write-Host $rbacDetails
        } else {
            Write-Host "  No direct Azure RBAC role assignments found." -ForegroundColor DarkYellow
        }
    } catch {
        Write-Warning "  Error checking direct RBAC roles for $($sp.DisplayName): $($_.Exception.Message)"
        $currentSpAnalysis.AzureRBACText = "Error checking direct RBAC roles: $($_.Exception.Message)"
    }
    #endregion

    #region Check Microsoft Entra ID / Graph API Permissions (Explicit)
    Write-Host "  -- Checking Explicit Microsoft Entra ID / Graph API Permissions --"
    try {
        $appRegistration = Get-MgApplication -Filter "appId eq '$($sp.AppId)'" -ErrorAction SilentlyContinue

        if ($appRegistration) {
            $appRoleAssignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -ErrorAction SilentlyContinue

            if ($appRoleAssignments.Count -gt 0) {
                $graphPermissions = @()
                $appRoleAssignments | ForEach-Object {
                    $permissionName = $_.ResourceSpecificAppRole.DisplayName
                    if (-not $permissionName) {
                        $permissionName = $_.AppRoleDisplayName
                    }
                    $graphPermissions += $permissionName
                }
                $graphPermissionsText = $graphPermissions -join "`n"
                $currentSpAnalysis.GraphAPIPermissions = $graphPermissionsText
                Write-Host "    Application Permissions (acting as itself):" -ForegroundColor White
                Write-Host ($graphPermissions | Out-String)
            } else {
                Write-Host "    No explicit Application Permissions (Graph API) assigned." -ForegroundColor DarkYellow
            }
        } else {
            Write-Host "    Associated Application Registration not found for AppId $($sp.AppId)." -ForegroundColor Red
            $currentSpAnalysis.GraphAPIPermissions = "Associated Application Registration not found."
        }
    } catch {
        Write-Warning "  Error checking Graph API permissions for $($sp.DisplayName): $($_.Exception.Message)"
        $currentSpAnalysis.GraphAPIPermissions = "Error checking Graph API permissions: $($_.Exception.Message)"
    }
    #endregion

    #region Check Group Memberships and Inherited Permissions (Implicit)
    Write-Host "  -- Checking Group Memberships and Inherited Permissions --"
    try {
        $memberOfGroups = Get-MgServicePrincipalMemberOf -ServicePrincipalId $sp.Id -ErrorAction SilentlyContinue | Where-Object { $_.AdditionalProperties['@odata.type'] -eq '#microsoft.graph.group' }

        if ($memberOfGroups.Count -gt 0) {
            $groupNames = ($memberOfGroups | Select-Object -ExpandProperty DisplayName) -join ', '
            $currentSpAnalysis.GroupMemberships = $groupNames
            Write-Host "  Member of the following groups: $($groupNames)" -ForegroundColor White

            $inheritedRBACText = @()
            $inheritedGraphAPIText = @()

            foreach ($group in $memberOfGroups) {
                Write-Host "    Checking group: $($group.DisplayName) (ID: $($group.Id)) for inherited permissions." -ForegroundColor DarkGray

                # Check inherited Azure RBAC Roles for the group
                $groupRoleAssignments = Get-AzRoleAssignment -ObjectId $group.Id -ErrorAction SilentlyContinue
                if ($groupRoleAssignments) {
                    $groupRbacDetails = $groupRoleAssignments | Select-Object @{Name='RoleName'; Expression={$_.RoleDefinitionName}}, Scope | Format-Table -AutoSize | Out-String
                    $inheritedRBACText += "Group $($group.DisplayName) RBAC Roles:`n$($groupRbacDetails.Trim())`n"
                }

                # Check if the group is a member of any Azure AD Directory Roles
                try {
                    $directoryRolesForGroup = Get-MgDirectoryRole | Where-Object {
                        $roleMembers = Get-MgDirectoryRoleMember -DirectoryRoleId $_.Id -ErrorAction SilentlyContinue
                        $roleMembers.Id -contains $group.Id
                    }

                    if ($directoryRolesForGroup.Count -gt 0) {
                        $inheritedGraphAPIText += "Group $($group.DisplayName) is a member of the following Directory Roles:`n"
                        $directoryRolesForGroup | ForEach-Object { $inheritedGraphAPIText += "  - $($_.DisplayName) (ID: $($_.Id))`n" }
                    }
                } catch {
                     Write-Warning "      Error checking if group $($group.DisplayName) is member of Directory Roles: $($_.Exception.Message)"
                }
            }

            if ($inheritedRBACText.Count -gt 0) {
                $currentSpAnalysis.InheritedRBACText = ($inheritedRBACText -join "`n--`n").Trim()
                Write-Host "  Inherited Azure RBAC Roles from Groups:`n$($currentSpAnalysis.InheritedRBACText)" -ForegroundColor White
            } else {
                Write-Host "  No inherited Azure RBAC roles from groups." -ForegroundColor DarkYellow
            }

            if ($inheritedGraphAPIText.Count -gt 0) {
                $currentSpAnalysis.InheritedGraphAPIText = ($inheritedGraphAPIText -join "`n--`n").Trim()
                Write-Host "  Inherited Graph API Permissions from Groups (via Directory Roles):`n$($currentSpAnalysis.InheritedGraphAPIText)" -ForegroundColor White
            } else {
                Write-Host "  No inherited Graph API permissions from groups." -ForegroundColor DarkYellow
            }

        } else {
            Write-Host "  Not a member of any Microsoft Entra ID groups." -ForegroundColor DarkYellow
        }
    } catch {
        Write-Warning "  Error checking group memberships or inherited permissions for $($sp.DisplayName): $($_.Exception.Message)"
        $currentSpAnalysis.GroupMemberships = "Error checking group memberships."
        $currentSpAnalysis.InheritedRBACText = "Error checking inherited RBAC roles."
        $currentSpAnalysis.InheritedGraphAPIText = "Error checking inherited Graph API permissions."
    }
    #endregion

    $analysisResults += $currentSpAnalysis
}
#endregion

#region 3. Generate Report and Summary
Write-Host "`n--- Generating Report and Summary ---" -ForegroundColor Yellow

# Generate Summary Statistics
Write-Host "`n--- Tenant-Wide SPN Summary ---" -ForegroundColor Green
$totalSPs = $analysisResults.Count
$secretsSPs = ($analysisResults | Where-Object HasSecrets -eq $true).Count
$certsSPs = ($analysisResults | Where-Object HasCertificates -eq $true).Count

$privilegedSPs = ($analysisResults | Where-Object {
    $_.AzureRBACText -notlike "No direct RBAC roles found.*" -or
    $_.GraphAPIPermissions -notlike "No explicit Graph API permissions.*" -or
    $_.InheritedRBACText -notlike "No inherited RBAC roles from groups.*" -or
    $_.InheritedGraphAPIText -notlike "No inherited Graph API permissions from groups.*"
}).Count

Write-Host "Total Sign-in Capable Service Principals Identified: $($totalSPs)"
Write-Host "SPs with Client Secrets (Passwords): $($secretsSPs)"
Write-Host "SPs with Certificates: $($certsSPs)"
Write-Host "SPs with Any Direct or Inherited Permissions (beyond default): $($privilegedSPs)"

# Export comprehensive report to Excel
if ($analysisResults.Count -gt 0) {
    try {
        if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
            Write-Warning "ImportExcel module not found. Please install it using: Install-Module -Name ImportExcel. Cannot export report to Excel."
        } else {
            Import-Module ImportExcel -ErrorAction SilentlyContinue
            $analysisResults | Export-Excel -Path $reportOutputPath -WorksheetName "SP Permissions Report" -AutoSize -TableStyle Light10 -ClearSheet
            Write-Host "Comprehensive service principal permissions report exported to: $reportOutputPath" -ForegroundColor Green
        }
    }
    catch {
        Write-Error "Could not export report to Excel: $($_.Exception.Message)"
    }
} else {
    Write-Host "No service principals were analyzed, so no report to generate." -ForegroundColor Yellow
}

Write-Host "`n--- Script execution complete ---" -ForegroundColor Green
