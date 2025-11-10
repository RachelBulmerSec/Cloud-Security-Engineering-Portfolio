# =====================================================================================
# SCRIPT: Intune_Remediate_MappedDrive.ps1
# DESCRIPTION: Intune Remediation - REMEDIATION Script
# Creates a persistent mapped drive by searching multiple user locations.
#
# Original script authored by Rachel Bulmer. Sanitized for public portfolio.
# =====================================================================================

# --- Configuration ---
$driveLetter = "S"
$targetFolderName = "My-Synced-Business-Folder" # <-- Specify folder name
$targetPath = $null 

# --- Script Body ---
try {
    # --- Part 1: Find the target folder path (copy of detection logic) ---
    $searchPaths = [System.Collections.Generic.List[string]]::new()
    $searchPaths.Add($env:USERPROFILE)
    $oneDrivePaths = @(
        (Get-Item -Path "env:OneDriveCommercial" -ErrorAction SilentlyContinue).Value,
        (Get-Item -Path "env:OneDrive" -ErrorAction SilentlyContinue).Value
    ) | Where-Object { $_ -ne $null -and $_ -ne "" }

    foreach ($odPath in $oneDrivePaths) {
        $searchPaths.Add($odPath)
        $parentOfOdPath = Split-Path -Path $odPath -Parent
        if ($parentOfOdPath) { $searchPaths.Add($parentOfOdPath) }
    }
    $uniqueSearchPaths = $searchPaths | Get-Unique

    foreach ($path in $uniqueSearchPaths) {
        $foundFolder = Get-ChildItem -Path $path -Filter $targetFolderName -Directory -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($foundFolder) {
            $targetPath = $foundFolder.FullName
            break 
        }
    }

    # --- Part 2: Map the drive if the path was found ---
    if ($targetPath) {
        # Create a persistent mapping using a registry run key
        $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        $valueName = "MapBusinessDocsTo_ $($driveLetter)"
        $commandToRun = "subst $($driveLetter): `"$targetPath`""

        Set-ItemProperty -Path $registryPath -Name $valueName -Value $commandToRun -Type String -Force
        Write-Host "Successfully created registry entry for logon."

        # Map drive for the current session
        if (Test-Path -Path "$($driveLetter):") {
            subst "$($driveLetter):" /D
            Write-Host "Removed existing mapping for $($driveLetter):"
        }
        Invoke-Expression -Command $commandToRun
        Write-Host "Drive $($driveLetter): has been mapped for the current session."
        exit 0 # Success
        
    } else {
        Write-Host "FAILURE: Target folder '$targetFolderName' was not found. No action taken."
        exit 1 # Failure
    }
}
catch {
    Write-Error "An unexpected error occurred: $_"
    exit 1
}
