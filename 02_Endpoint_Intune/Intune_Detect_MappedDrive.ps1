# =====================================================================================
# SCRIPT: Intune_Detect_MappedDrive.ps1
# DESCRIPTION: Intune Remediation - DETECTION Script
# Detects if a drive is correctly mapped to a dynamically located folder.
#
# Original script authored by Rachel Bulmer. Sanitized for public portfolio.
#
# EXIT CODES:
#   Exit 0 = Compliant (drive is mapped correctly)
#   Exit 1 = Non-Compliant (drive is missing or mapped incorrectly)
# =====================================================================================

try {
    # --- Configuration ---
    $driveLetter = "S"
    $targetFolderName = "My-Synced-Business-Folder" # <-- Specify folder name
    $correctPath = $null

    # --- Part 1: Dynamically find what the CORRECT path should be ---
    $searchPaths = [System.Collections.Generic.List[string]]::new()
    $searchPaths.Add($env:USERPROFILE)
    
    # Get potential OneDrive paths from environment variables
    $oneDrivePaths = @(
        (Get-Item -Path "env:OneDriveCommercial" -ErrorAction SilentlyContinue).Value,
        (Get-Item -Path "env:OneDrive" -ErrorAction SilentlyContinue).Value
    ) | Where-Object { $_ -ne $null -and $_ -ne "" }

    # Add OneDrive paths and their parents to the search list
    foreach ($odPath in $oneDrivePaths) {
        $searchPaths.Add($odPath)
        $parentOfOdPath = Split-Path -Path $odPath -Parent
        if ($parentOfOdPath) { $searchPaths.Add($parentOfOdPath) }
    }
    $uniqueSearchPaths = $searchPaths | Get-Unique

    # Search for the folder
    foreach ($path in $uniqueSearchPaths) {
        $foundFolder = Get-ChildItem -Path $path -Filter $targetFolderName -Directory -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($foundFolder) {
            $correctPath = $foundFolder.FullName
            break
        }
    }

    if (-not $correctPath) {
        Write-Host "The source folder '$targetFolderName' could not be found. Remediation required."
        exit 1
    }

    # --- Part 2: Check the CURRENT state of the drive ---
    $drive = Get-PSDrive -Name $driveLetter -ErrorAction SilentlyContinue
    if (-not $drive) {
        Write-Host "Drive $driveLetter: does not exist. Remediation required."
        exit 1
    }

    # --- Part 3: Compare the current state to the correct path ---
    $currentMapping = $drive.DisplayRoot.TrimEnd('\')
    if ($currentMapping -eq $correctPath) {
        Write-Host "COMPLIANT: Drive $driveLetter: is correctly mapped to '$currentMapping'."
        exit 0 # Compliant!
    } else {
        Write-Host "NON-COMPLIANT: Drive $driveLetter: is mapped to '$currentMapping' but should be '$correctPath'."
        exit 1 # Non-Compliant!
    }
}
catch {
    Write-Host "An error occurred during detection. Remediation is required. Error: $_"
    exit 1 # Non-Compliant!
}
