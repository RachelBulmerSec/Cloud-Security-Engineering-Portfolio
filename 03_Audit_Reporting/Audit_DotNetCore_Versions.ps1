# This script audits the file system to find all installed versions
# of the .NET Core runtime.
#
# Original script authored by Rachel Bulmer. Sanitized for public portfolio.

function Get-DotNetCoreVersions {
    $dotnetPath = "C:\Program Files\dotnet\shared\Microsoft.NETCore.App"
    if (Test-Path $dotnetPath) {
        Get-ChildItem -Path $dotnetPath | Select-Object Name
    } else {
        # No error message needed for a simple audit
    }
}

# Get and display .NET Core versions
$dotNetCoreVersions = Get-DotNetCoreVersions
if ($dotNetCoreVersions) {
    $dotNetCoreVersions | Format-Table -AutoSize
} else {
    Write-Output "No .NET Core versions found."
}
