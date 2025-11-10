# This script demonstrates how to get an OAuth2 access token from Azure AD
# using the Client Credentials flow. This is a core concept for modern,
# secure, app-only authentication.
#
# Original script authored by Rachel Bulmer. Sanitized for public portfolio.

# --- Configuration ---
# You would replace these with your application's details
$tenantId = "YOUR_TENANT_ID"
$clientId = "YOUR_APPLICATION_CLIENT_ID"
$clientSecret = "YOUR_CLIENT_SECRET"
$scope = "https://your-api-scope-url/.default" # e.g., https://graph.microsoft.com/.default

# --- Get the token ---
try {
    $tokenResponse = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" `
        -ContentType "application/x-www-form-urlencoded" `
        -Body @{
            client_id     = $clientId
            client_secret = $clientSecret
            scope         = $scope
            grant_type    = "client_credentials"
        } -ErrorAction Stop

    # Extract the token
    $accessToken = $tokenResponse.access_token
    Write-Host "Access Token (first 20 chars): $($accessToken.Substring(0,20))..."
    # Uncomment the line below to see the full token (NOT recommended)
    # Write-Host "Access Token: $accessToken"
}
catch {
    Write-Error "Failed to get access token. Error: $_"
}
