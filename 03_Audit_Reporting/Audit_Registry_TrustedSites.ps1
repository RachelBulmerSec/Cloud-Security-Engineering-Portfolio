# This script audits the current user's registry to find all entries
# listed in the "Trusted Sites" zone of Internet Options.
#
# Original script authored by Rachel Bulmer. Sanitized for public portfolio.

$trustedSites = @()
$domainsKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains"

if (-not (Test-Path $domainsKey)) {
    Write-Host "Trusted Sites registry key not found."
    return
}

$subKeys = Get-ChildItem -Path $domainsKey -Recurse -ErrorAction SilentlyContinue

foreach ($subKey in $subKeys) {
    try {
        $pathParts = $subKey.Name -split "\\"
        $domain = $pathParts[-2]
        $subdomain = $pathParts[-1]
        
        # This logic ensures we get the proper domain format
        if ($domain -eq "Domains") {
            $trustedSites += $subdomain
        } else {
             $trustedSites += "$subdomain.$domain"
        }
    }
    catch {
        # Handle potential errors with key names
    }
}

$uniqueSites = $trustedSites | Sort-Object -Unique
Write-Host "Found $($uniqueSites.Count) unique Trusted Sites:"
$uniqueSites | Format-Table

# Optional: Export to CSV
# $uniqueSites | Export-Csv -Path "C:\Temp\trusted_sites.csv" -NoTypeInformation
