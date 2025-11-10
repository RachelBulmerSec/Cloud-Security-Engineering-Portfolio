# This script audits the Windows Registry to find all installed versions
# of the .NET Framework.
#
# Original script authored by Rachel Bulmer. Sanitized for public portfolio.

function Get-DotNetFrameworkVersions {
    $regKeys = @(
        "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full",
        "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Client",
        "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5",
        "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.0",
        "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v2.0.50727"
    )

    foreach ($key in $regKeys) {
        if (Test-Path $key) {
            $version = Get-ItemProperty -Path $key -Name Version -ErrorAction SilentlyContinue
            if ($version) {
                [PSCustomObject]@{
                    Path    = $key
                    Version = $version.Version
                }
            }
        }
    }
}

# Get and display .NET Framework versions
$dotNetVersions = Get-DotNetFrameworkVersions
if ($dotNetVersions) {
    $dotNetVersions | Format-Table -AutoSize
} else {
    Write-Output "No .NET Framework versions found."
}
