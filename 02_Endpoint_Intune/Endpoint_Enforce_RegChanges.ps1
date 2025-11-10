# This script enforces common quality-of-life and security-related
# registry changes for the current user.
#
# Original script authored by Rachel Bulmer. Sanitized for public portfolio.

try {
    # Ensure file extensions are always shown in File Explorer
    $regPathExt = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    if (Test-Path $regPathExt) {
        Set-ItemProperty -Path $regPathExt -Name "HideFileExt" -Value 0 -ErrorAction Stop
        Write-Host "Set 'HideFileExt' to 0 (Show Extensions)."
    }

    # Ensure "Show more options" is always displayed in the context menu (Windows 11)
    # This is done by removing the blocking key.
    $regPathContext = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
    if (Test-Path $regPathContext) {
        Remove-Item -Path $regPathContext -Force -ErrorAction Stop
        Write-Host "Removed Windows 11 context menu block."
    }

    Write-Host "Settings applied successfully. Please restart File Explorer for changes to take effect."
    exit 0
}
catch {
    Write-Error "An error occurred: $_"
    exit 1
}
