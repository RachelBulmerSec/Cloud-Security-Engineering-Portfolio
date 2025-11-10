# This script is a utility to find all python.exe installations on
# a Windows machine, including in other user profiles.
#
# Original script authored by Rachel Bulmer. Sanitized for public portfolio.

$foundPaths = [System.Collections.Generic.List[string]]::new()

# Function to check if a command exists
function CommandExists {
    param ([string]$command)
    $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
}

# 1. Check if 'where' command is available (fastest method)
if (CommandExists 'where') {
    $pythonPaths = where.exe python.exe 2>$null
    if ($pythonPaths) {
        $pythonPaths | ForEach-Object { $foundPaths.Add($_) }
    }
}

# 2. Additional method to find Python in common user/program paths
$commonPaths = @(
    "$env:ProgramFiles\Python*",
    "$env:ProgramFiles(x86)\Python*"
)

# Include all user profiles
$usersPath = "C:\Users"
$users = Get-ChildItem -Path $usersPath -Directory -ErrorAction SilentlyContinue

foreach ($user in $users) {
    $userProfilePath = $user.FullName
    $commonPaths += "$userProfilePath\AppData\Local\Programs\Python\Python*"
}

foreach ($path in $commonPaths | Get-Unique) {
    $pythonDirs = Get-ChildItem -Path $path -Directory -ErrorAction SilentlyContinue
    foreach ($dir in $pythonDirs) {
        $pythonExe = Join-Path -Path $dir.FullName -ChildPath "python.exe"
        if (Test-Path $pythonExe) {
            $foundPaths.Add($pythonExe)
        }
    }
}

# Display unique results
$uniquePaths = $foundPaths | Sort-Object -Unique
if ($uniquePaths.Count -gt 0) {
    Write-Output "Python installations found:"
    $uniquePaths | Format-Table -AutoSize
} else {
    Write-Output "No Python installations found."
}
