<#	
.NOTES
===========================================================================
Original script from /u/TheLazyAdministrator, with modifications.
Sanitized for public portfolio by Rachel Bulmer.
===========================================================================
.DESCRIPTION
Generate an interactive HTML report on an Office 365 tenant. Reports on
Users, Licenses, Groups, Admins, and more.

.Link
https://thelazyadministrator.com/2018/06/22/create-an-interactive-html-report-for-office-365-with-powershell/
#>
#########################################
#                                       #
#            VARIABLES                  #
#                                       #
#########################################
#Company logo that will be displayed on the left, can be URL or UNC
$CompanyLogo = "https://placehold.co/200x50/cccccc/EFEFEF?text=Your+Logo"
#Logo that will be on the right side, UNC or URL
$RightLogo = ""
#Location the report will be saved to
$ReportSavePath = "C:\Temp\"
#Variable to filter licenses out
$LicenseFilter = "9000"
#If you want to include users last logon mailbox timestamp, set this to true
$IncludeLastLogonTimestamp = $False
#Set to $True if your global admin requires 2FA (MFA)
$2FA = $True
########################################

# --- Module Connection ---
try {
    if ($2FA -eq $False) {
        $credential = Get-Credential -Message "Please enter your Office 365 credentials"
        Import-Module AzureAD -ErrorAction Stop
        Connect-AzureAD -Credential $credential
        $exchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid/" -Authentication "Basic" -AllowRedirection -Credential $credential -ErrorAction Stop
        Import-PSSession $exchangeSession -AllowClobber -ErrorAction Stop
    }
    Else {
        Import-Module AzureAD -ErrorAction Stop
        Connect-AzureAD
        Import-Module ExchangeOnlineManagement -ErrorAction Stop
        Connect-ExchangeOnline
    }
    Import-Module ReportHTML -ErrorAction Stop
}
catch {
    Write-Error "Failed to connect to required modules. Make sure AzureAD, ExchangeOnlineManagement, and ReportHTML are installed."
    return
}

# --- Initialize Tables ---
$Table = New-Object 'System.Collections.Generic.List[System.Object]'
$LicenseTable = New-Object 'System.Collections.Generic.List[System.Object]'
$UserTable = New-Object 'System.Collections.Generic.List[System.Object]'
$SharedMailboxTable = New-Object 'System.Collections.Generic.List[System.Object]'
$GroupTypetable = New-Object 'System.Collections.Generic.List[System.Object]'
$IsLicensedUsersTable = New-Object 'System.Collections.Generic.List[System.Object]'
$ContactTable = New-Object 'System.Collections.Generic.List[System.Object]'
$ContactMailUserTable = New-Object 'System.Collections.Generic.List[System.Object]'
$RoomTable = New-Object 'System.Collections.Generic.List[System.Object]'
$EquipTable = New-Object 'System.Collections.Generic.List[System.Object]'
$GlobalAdminTable = New-Object 'System.Collections.Generic.List[System.Object]'
$StrongPasswordTable = New-Object 'System.Collections.Generic.List[System.Object]'
$CompanyInfoTable = New-Object 'System.Collections.Generic.List[System.Object]'
$MessageTraceTable = New-Object 'System.Collections.Generic.List[System.Object]'
$DomainTable = New-Object 'System.Collections.Generic.List[System.Object]'

# --- SKU (License Name) Hashtable ---
$Sku = @{
    "O365_BUSINESS_ESSENTIALS" = "Office 365 Business Essentials"
    "O365_BUSINESS_PREMIUM" = "Office 365 Business Premium"
    "ENTERPRISEPACK" = "Enterprise Plan E3"
    "ENTERPRISEPREMIUM" = "Enterprise E5 (with Audio Conferencing)"
    "SPE_E3" = "Microsoft 365 E3"
    "SPE_E5" = "Microsoft 365 E5"
    "AAD_PREMIUM" = "Azure Active Directory Premium"
    "AAD_PREMIUM_P2" = "Azure Active Directory Premium P2"
    "EMS" = "Enterprise Mobility Suite"
    # Add more SKUs as needed
}

# Get all users right away.
$AllUsers = get-azureaduser -All:$true

# --- Company Information ---
$CompanyInfo = Get-AzureADTenantDetail
$CompanyName = $CompanyInfo.DisplayName
$TechEmail = $CompanyInfo.TechnicalNotificationMails | Out-String
$DirSync = $CompanyInfo.DirSyncEnabled
$LastDirSync = $CompanyInfo.CompanyLastDirSyncTime
If ($DirSync -eq $Null) {
    $LastDirSync = "Not Available"
    $DirSync = "Disabled"
}
$obj = [PSCustomObject]@{
    'Name' = $CompanyName
    'Technical E-mail' = $TechEmail
    'Directory Sync' = $DirSync
    'Last Directory Sync' = $LastDirSync
}
$CompanyInfoTable.add($obj)

# --- Get Tenant Global Admins ---
$role = Get-AzureADDirectoryRole | Where-Object { $_.DisplayName -match "Company Administrator" }
$Admins = Get-AzureADDirectoryRoleMember -ObjectId $role.ObjectId
Foreach ($Admin in $Admins) {
    $Name = $Admin.DisplayName
    $EmailAddress = $Admin.Mail
    if (($admin.assignedlicenses.SkuID) -ne $Null) { $Licensed = $True }
    else { $Licensed = $False }
    $obj = [PSCustomObject]@{
        'Name' = $Name
        'Is Licensed' = $Licensed
        'E-Mail Address' = $EmailAddress
    }
    $GlobalAdminTable.add($obj)
}

# --- Users with Strong Password Disabled ---
$LooseUsers = $AllUsers | Where-Object { $_.PasswordPolicies -eq "DisableStrongPassword" }
Foreach ($LooseUser in $LooseUsers) {
    $NameLoose = $LooseUser.DisplayName
    $UPNLoose = $LooseUser.UserPrincipalName
    $StrongPasswordLoose = "False"
    if (($LooseUser.assignedlicenses.SkuID) -ne $Null) { $LicensedLoose = $true }
    else { $LicensedLoose = $false }
    $obj = [PSCustomObject]@{
        'Name' = $NameLoose
        'UserPrincipalName' = $UPNLoose
        'Is Licensed' = $LicensedLoose
        'Strong Password Required' = $StrongPasswordLoose
    }
    $StrongPasswordTable.add($obj)
}
If (($StrongPasswordTable).count -eq 0) {
    $StrongPasswordTable = [PSCustomObject]@{ 'Information' = 'Information: No Users were found with Strong Password Enforcement disabled' }
}

# --- Message Trace ---
$RecentMessages = Get-MessageTrace
Foreach ($RecentMessage in $RecentMessages) {
    $obj = [PSCustomObject]@{
        'Received Date' = $RecentMessage.Received
        'E-Mail Subject' = $RecentMessage.Subject
        'Sender' = $RecentMessage.SenderAddress
        'Recipient' = $RecentMessage.RecipientAddress
        'Status' = $RecentMessage.Status
    }
    $MessageTraceTable.add($obj)
}
If (($MessageTraceTable).count -eq 0) {
    $MessageTraceTable = [PSCustomObject]@{ 'Information' = 'Information: No recent E-Mails were found' }
}

# --- Tenant Domain ---
$Domains = Get-AzureAdDomain
foreach ($Domain in $Domains) {
    $obj = [PSCustomObject]@{
        'Domain Name' = $Domain.Name
        'Verification Status' = $Domain.IsVerified
        'Default' = $Domain.IsDefault
    }
    $DomainTable.add($obj)
}

# --- Group Information ---
$Groups = Get-AzureAdGroup -All $True | Sort-Object DisplayName
$DistroCount = ($Groups | Where-Object { $_.MailEnabled -eq $true -and $_.SecurityEnabled -eq $false }).Count
$GroupTypetable.add([PSCustomObject]@{'Name' = 'Distribution Group'; 'Count' = $DistroCount })
$SecurityCount = ($Groups | Where-Object { $_.MailEnabled -eq $false -and $_.SecurityEnabled -eq $true }).Count
$GroupTypetable.add([PSCustomObject]@{'Name' = 'Security Group'; 'Count' = $SecurityCount })
$SecurityMailEnabledCount = ($Groups | Where-Object { $_.MailEnabled -eq $true -and $_.SecurityEnabled -eq $true }).Count
$GroupTypetable.add([PSCustomObject]@{'Name' = 'Mail Enabled Security Group'; 'Count' = $SecurityMailEnabledCount })

Foreach ($Group in $Groups) {
    $Type = New-Object 'System.Collections.Generic.List[System.Object]'
    if ($group.MailEnabled -eq $True -and $group.SecurityEnabled -eq $False) { $Type = "Distribution Group" }
    if ($group.MailEnabled -eq $False -and $group.SecurityEnabled -eq $True) { $Type = "Security Group" }
    if ($group.MailEnabled -eq $True -and $group.SecurityEnabled -eq $True) { $Type = "Mail Enabled Security Group" }
    
    $Users = (Get-AzureADGroupMember -ObjectId $Group.ObjectID | Sort-Object DisplayName | Select-Object -ExpandProperty DisplayName) -join ", "
    $obj = [PSCustomObject]@{
        'Name' = $Group.DisplayName
        'Type' = $Type
        'Members' = $users
        'E-mail Address' = $Group.Mail
    }
    $table.add($obj)
}
If (($table).count -eq 0) {
    $table = [PSCustomObject]@{ 'Information' = 'Information: No Groups were found in the tenant' }
}

# --- License Information ---
$Licenses = Get-AzureADSubscribedSku
Foreach ($License in $Licenses) {
    $TextLic = $null
    $ASku = ($License).SkuPartNumber
    $TextLic = $Sku.Item("$ASku")
    If (!($TextLic)) { $OLicense = $License.SkuPartNumber }
    Else { $OLicense = $TextLic }
    $TotalAmount = $License.PrepaidUnits.enabled
    $Assigned = $License.ConsumedUnits
    $Unassigned = ($TotalAmount - $Assigned)
    If ($TotalAmount -lt $LicenseFilter) {
        $obj = [PSCustomObject]@{
            'Name' = $Olicense
            'Total Amount' = $TotalAmount
            'Assigned Licenses' = $Assigned
            'Unassigned Licenses' = $Unassigned
        }
        $licensetable.add($obj)
    }
}
If (($licensetable).count -eq 0) {
    $licensetable = [PSCustomObject]@{ 'Information' = 'Information: No Licenses were found in the tenant' }
}

$IsLicensed = ($AllUsers | Where-Object { $_.assignedlicenses.count -gt 0 }).Count
$IsLicensedUsersTable.add([PSCustomObject]@{'Name' = 'Users Licensed'; 'Count' = $IsLicensed })
$ISNotLicensed = ($AllUsers | Where-Object { $_.assignedlicenses.count -eq 0 }).Count
$IsLicensedUsersTable.add([PSCustomObject]@{'Name' = 'Users Not Licensed'; 'Count' = $ISNotLicensed })

# --- User Information ---
Foreach ($User in $AllUsers) {
    $ProxyA = New-Object 'System.Collections.Generic.List[System.Object]'
    $NewObject02 = New-Object 'System.Collections.Generic.List[System.Object]'
    
    $UserLicenses = ($user | Select -ExpandProperty AssignedLicenses).SkuID
    If ($UserLicenses) {
        Foreach ($UserLicense in $UserLicenses) {
            $UserLicenseName = ($licenses | Where-Object { $_.skuid -match $UserLicense }).SkuPartNumber
            $TextLic = $Sku.Item("$UserLicenseName")
            If (!($TextLic)) { $NewObject02.add([PSCustomObject]@{'Licenses' = $UserLicenseName }) }
            Else { $NewObject02.add([PSCustomObject]@{'Licenses' = $textlic }) }
        }
    } Else {
        $NewObject02.add([PSCustomObject]@{'Licenses' = $Null })
    }

    $ProxyAddresses = ($User | Select-Object -ExpandProperty ProxyAddresses)
    If ($ProxyAddresses -ne $Null) {
        Foreach ($Proxy in $ProxyAddresses) {
            $ProxyB = $Proxy -split ":" | Select-Object -Last 1
            $ProxyA.add($ProxyB)
        }
        $ProxyC = $ProxyA -join ", "
    } Else {
        $ProxyC = $Null
    }

    $ResetPW = $Null
    try {
        $ResetPW = Get-User $User.DisplayName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ResetPasswordOnNextLogon
    } catch {}

    $objCommon = @{
        'Name' = $User.DisplayName
        'UserPrincipalName' = $User.UserPrincipalName
        'Licenses' = ($NewObject02 | Select-Object -ExpandProperty Licenses) -join ", "
        'Reset Password at Next Logon' = $ResetPW
        'Enabled' = $User.AccountEnabled
        'E-mail Addresses' = $ProxyC
    }

    If ($IncludeLastLogonTimestamp -eq $True) {
        $LastLogon = $Null
        try {
            $LastLogon = Get-MailboxStatistics -Identity $User.DisplayName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty LastLogonTime
        } catch {}
        $objCommon['Last Mailbox Logon'] = $LastLogon
    }
    
    $usertable.add([PSCustomObject]$objCommon)
}
If (($usertable).count -eq 0) {
    $usertable = [PSCustomObject]@{ 'Information' = 'Information: No Users were found in the tenant' }
}

# --- Shared Mailboxes ---
$SharedMailboxes = Get-Recipient -Resultsize unlimited | Where-Object { $_.RecipientTypeDetails -eq "SharedMailbox" }
Foreach ($SharedMailbox in $SharedMailboxes) {
    $ProxyA = New-Object 'System.Collections.Generic.List[System.Object]'
    $Name = $SharedMailbox.Name
    $PrimEmail = $SharedMailbox.PrimarySmtpAddress
    $ProxyAddresses = ($SharedMailbox | Where-Object { $_.EmailAddresses -notlike "*$PrimEmail*" } | Select-Object -ExpandProperty EmailAddresses)
    If ($ProxyAddresses -ne $Null) {
        Foreach ($ProxyAddress in $ProxyAddresses) {
            $ProxyB = $ProxyAddress -split ":" | Select-Object -Last 1
            If ($ProxyB -ne $PrimEmail) { $ProxyA.add($ProxyB) }
        }
    }
    $ProxyF = ($ProxyA -join ", ").TrimEnd(", ")
    $obj = [PSCustomObject]@{
        'Name' = $Name
        'Primary E-Mail' = $PrimEmail
        'E-mail Addresses' = $ProxyF
    }
    $SharedMailboxTable.add($obj)
}
If (($SharedMailboxTable).count -eq 0) {
    $SharedMailboxTable = [PSCustomObject]@{ 'Information' = 'Information: No Shared Mailboxes were found in the tenant' }
}

# --- Contacts ---
$Contacts = Get-MailContact
Foreach ($Contact in $Contacts) {
    $objContact = [PSCustomObject]@{
        'Name' = $Contact.DisplayName
        'E-mail Address' = $Contact.PrimarySmtpAddress
    }
    $ContactTable.add($objContact)
}
If (($ContactTable).count -eq 0) {
    $ContactTable = [PSCustomObject]@{ 'Information' = 'Information: No Contacts were found in the tenant' }
}

# --- Mail Users ---
$MailUsers = Get-MailUser
foreach ($MailUser in $mailUsers) {
    $MailArray = New-Object 'System.Collections.Generic.List[System.Object]'
    $MailPrimEmail = $MailUser.PrimarySmtpAddress
    $MailName = $MailUser.DisplayName
    $MailEmailAddresses = ($MailUser.EmailAddresses | Where-Object { $_ -cnotmatch '^SMTP' })
    foreach ($MailEmailAddress in $MailEmailAddresses) {
        $MailEmailAddressSplit = $MailEmailAddress -split ":" | Select-Object -Last 1
        $MailArray.add($MailEmailAddressSplit)
    }
    $obj = [PSCustomObject]@{
        'Name' = $MailName
        'Primary E-Mail' = $MailPrimEmail
        'E-mail Addresses' = $MailArray -join ", "
    }
    $ContactMailUserTable.add($obj)
}
If (($ContactMailUserTable).count -eq 0) {
    $ContactMailUserTable = [PSCustomObject]@{ 'Information' = 'Information: No Mail Users were found in the tenant' }
}

# --- Room Mailboxes ---
$Rooms = Get-Mailbox -ResultSize Unlimited -Filter '(RecipientTypeDetails -eq "RoomMailBox")'
Foreach ($Room in $Rooms) {
    $RoomArray = New-Object 'System.Collections.Generic.List[System.Object]'
    $RoomName = $Room.DisplayName
    $RoomPrimEmail = $Room.PrimarySmtpAddress
    $RoomEmails = ($Room.EmailAddresses | Where-Object { $_ -cnotmatch '^SMTP' })
    foreach ($RoomEmail in $RoomEmails) {
        $RoomEmailSplit = $RoomEmail -split ":" | Select-Object -Last 1
        $RoomArray.add($RoomEmailSplit)
    }
    $obj = [PSCustomObject]@{
        'Name' = $RoomName
        'Primary E-Mail' = $RoomPrimEmail
        'E-mail Addresses' = $RoomArray -join ", "
    }
    $RoomTable.add($obj)
}
If (($RoomTable).count -eq 0) {
    $RoomTable = [PSCustomObject]@{ 'Information' = 'Information: No Room Mailboxes were found in the tenant' }
}

# --- Equipment Mailboxes ---
$EquipMailboxes = Get-Mailbox -ResultSize Unlimited -Filter '(RecipientTypeDetails -eq "EquipmentMailBox")'
Foreach ($EquipMailbox in $EquipMailboxes) {
    $EquipArray = New-Object 'System.Collections.Generic.List[System.Object]'
    $EquipName = $EquipMailbox.DisplayName
    $EquipPrimEmail = $EquipMailbox.PrimarySmtpAddress
    $EquipEmails = ($EquipMailbox.EmailAddresses | Where-Object { $_ -cnotmatch '^SMTP' })
    foreach ($EquipEmail in $EquipEmails) {
        $EquipEmailSplit = $EquipEmail -split ":" | Select-Object -Last 1
        $EquipArray.add($EquipEmailSplit)
    }
    $obj = [PSCustomObject]@{
        'Name' = $EquipName
        'Primary E-Mail' = $EquipPrimEmail
        'E-mail Addresses' = $EquipArray -join ", "
    }
    $EquipTable.add($obj)
}
If (($EquipTable).count -eq 0) {
    $EquipTable = [PSCustomObject]@{ 'Information' = 'Information: No Equipment Mailboxes were found in the tenant' }
}

# --- Chart Definitions ---
$tabarray = @('Dashboard','Groups', 'Licenses', 'Users', 'Shared Mailboxes', 'Contacts', 'Resources')

$PieObject2 = Get-HTMLPieChartObject
$PieObject2.Title = "Office 365 Total Licenses"
$PieObject2.Size.Height = 250
$PieObject2.Size.width = 250
$PieObject2.ChartStyle.ChartType = 'doughnut'
$PieObject2.ChartStyle.ColorSchemeName = 'Random'
$PieObject2.DataDefinition.DataNameColumnName = 'Name'
$PieObject2.DataDefinition.DataValueColumnName = 'Total Amount'

$PieObject3 = Get-HTMLPieChartObject
$PieObject3.Title = "Office 365 Assigned Licenses"
$PieObject3.Size.Height = 250
$PieObject3.Size.width = 250
$PieObject3.ChartStyle.ChartType = 'doughnut'
$PieObject3.ChartStyle.ColorSchemeName = 'Random'
$PieObject3.DataDefinition.DataNameColumnName = 'Name'
$PieObject3.DataDefinition.DataValueColumnName = 'Assigned Licenses'

$PieObject4 = Get-HTMLPieChartObject
$PieObject4.Title = "Office 365 Unassigned Licenses"
$PieObject4.Size.Height = 250
$PieObject4.Size.width = 250
$PieObject4.ChartStyle.ChartType = 'doughnut'
$PieObject4.ChartStyle.ColorSchemeName = 'Random'
$PieObject4.DataDefinition.DataNameColumnName = 'Name'
$PieObject4.DataDefinition.DataValueColumnName = 'Unassigned Licenses'

$PieObjectGroupType = Get-HTMLPieChartObject
$PieObjectGroupType.Title = "Office 365 Groups"
$PieObjectGroupType.Size.Height = 250
$PieObjectGroupType.Size.width = 250
$PieObjectGroupType.ChartStyle.ChartType = 'doughnut'
$PieObjectGroupType.ChartStyle.ColorSchemeName = 'Random'
$PieObjectGroupType.DataDefinition.DataNameColumnName = 'Name'
$PieObjectGroupType.DataDefinition.DataValueColumnName = 'Count'

$PieObjectULicense = Get-HTMLPieChartObject
$PieObjectULicense.Title = "License Status"
$PieObjectULicense.Size.Height = 250
$PieObjectULicense.Size.width = 250
$PieObjectULicense.ChartStyle.ChartType = 'doughnut'
$PieObjectULicense.ChartStyle.ColorSchemeName = 'Random'
$PieObjectULicense.DataDefinition.DataNameColumnName = 'Name'
$PieObjectULicense.DataDefinition.DataValueColumnName = 'Count'

# --- Build HTML Report ---
$rpt = New-Object 'System.Collections.Generic.List[System.Object]'
$rpt += get-htmlopenpage -TitleText 'Office 365 Tenant Report' -LeftLogoString $CompanyLogo -RightLogoString $RightLogo 
$rpt += Get-HTMLTabHeader -TabNames $tabarray 
$rpt += get-htmltabcontentopen -TabName $tabarray[0] -TabHeading ("Report: " + (Get-Date -Format MM-dd-yyyy))
$rpt+= Get-HtmlContentOpen -HeaderText "Office 365 Dashboard"
$rpt += Get-HTMLContentOpen -HeaderText "Company Information"
$rpt += Get-HtmlContentTable $CompanyInfoTable 
$rpt += Get-HTMLContentClose
$rpt+= get-HtmlColumn1of2
$rpt+= Get-HtmlContentOpen -BackgroundShade 1 -HeaderText 'Global Administrators'
$rpt+= get-htmlcontentdatatable  $GlobalAdminTable -HideFooter
$rpt+= Get-HtmlContentClose
$rpt+= get-htmlColumnClose
$rpt+= get-htmlColumn2of2
$rpt+= Get-HtmlContentOpen -HeaderText 'Users With Strong Password Enforcement Disabled'
$rpt+= get-htmlcontentdatatable $StrongPasswordTable -HideFooter 
$rpt+= Get-HtmlContentClose
$rpt+= get-htmlColumnClose
$rpt += Get-HTMLContentOpen -HeaderText "Recent E-Mails"
$rpt += Get-HTMLContentDataTable $MessageTraceTable -HideFooter
$rpt += Get-HTMLContentClose
$rpt += Get-HTMLContentOpen -HeaderText "Domains"
$rpt += Get-HtmlContentTable $DomainTable 
$rpt += Get-HTMLContentClose
$rpt+= Get-HtmlContentClose 
$rpt += get-htmltabcontentclose

# Tab 2: Groups
$rpt += get-htmltabcontentopen -TabName $tabarray[1] -TabHeading ("Report: " + (Get-Date -Format MM-dd-yyyy))
$rpt += Get-HTMLContentOpen -HeaderText "Office 365 Groups"
$rpt += get-htmlcontentdatatable $Table -HideFooter
$rpt += Get-HTMLContentClose
$rpt += Get-HTMLContentOpen -HeaderText "Office 365 Groups Chart"
$rpt += Get-HTMLPieChart -ChartObject $PieObjectGroupType -DataSet $GroupTypetable
$rpt += Get-HTMLContentClose
$rpt += get-htmltabcontentclose

# Tab 3: Licenses
$rpt += get-htmltabcontentopen -TabName $tabarray[2]  -TabHeading ("Report: " + (Get-Date -Format MM-dd-yyyy))
$rpt += Get-HTMLContentOpen -HeaderText "Office 365 Licenses"
$rpt += get-htmlcontentdatatable $LicenseTable -HideFooter
$rpt += Get-HTMLContentClose
$rpt += Get-HTMLContentOpen -HeaderText "Office 365 Licensing Charts"
$rpt += Get-HTMLColumnOpen -ColumnNumber 1 -ColumnCount 2
$rpt += Get-HTMLPieChart -ChartObject $PieObject2 -DataSet $licensetable
$rpt += Get-HTMLColumnClose
$rpt += Get-HTMLColumnOpen -ColumnNumber 2 -ColumnCount 2
$rpt += Get-HTMLPieChart -ChartObject $PieObject3 -DataSet $licensetable
$rpt += Get-HTMLColumnClose
$rpt += Get-HTMLContentclose
$rpt += get-htmltabcontentclose

# Tab 4: Users
$rpt += get-htmltabcontentopen -TabName $tabarray[3] -TabHeading ("Report: " + (Get-Date -Format MM-dd-yyyy))
$rpt += Get-HTMLContentOpen -HeaderText "Office 365 Users"
$rpt += get-htmlcontentdatatable $UserTable -HideFooter
$rpt += Get-HTMLContentClose
$rpt += Get-HTMLContentOpen -HeaderText "Licensed & Unlicensed Users Chart"
$rpt += Get-HTMLPieChart -ChartObject $PieObjectULicense -DataSet $IsLicensedUsersTable
$rpt += Get-HTMLContentClose
$rpt += get-htmltabcontentclose

# Tab 5: Shared Mailboxes
$rpt += get-htmltabcontentopen -TabName $tabarray[4] -TabHeading ("Report: " + (Get-Date -Format MM-dd-yyyy)) 
$rpt += Get-HTMLContentOpen -HeaderText "Office 365 Shared Mailboxes"
$rpt += get-htmlcontentdatatable $SharedMailboxTable -HideFooter
$rpt += Get-HTMLContentClose
$rpt += get-htmltabcontentclose

# Tab 6: Contacts
$rpt += get-htmltabcontentopen -TabName $tabarray[5] -TabHeading ("Report: " + (Get-Date -Format MM-dd-yyyy)) 
$rpt += Get-HTMLContentOpen -HeaderText "Office 365 Contacts"
$rpt += get-htmlcontentdatatable $ContactTable -HideFooter
$rpt += Get-HTMLContentClose
$rpt += Get-HTMLContentOpen -HeaderText "Office 365 Mail Users"
$rpt += get-htmlcontentdatatable $ContactMailUserTable -HideFooter
$rpt += Get-HTMLContentClose
$rpt += get-htmltabcontentclose

# Tab 7: Resources
$rpt += get-htmltabcontentopen -TabName $tabarray[6] -TabHeading ("Report: " + (Get-Date -Format MM-dd-yyyy)) 
$rpt += Get-HTMLContentOpen -HeaderText "Office 365 Room Mailboxes"
$rpt += get-htmlcontentdatatable $RoomTable -HideFooter
$rpt += Get-HTMLContentClose
$rpt += Get-HTMLContentOpen -HeaderText "Office 365 Equipment Mailboxes"
$rpt += get-htmlcontentdatatable $EquipTable -HideFooter
$rpt += Get-HTMLContentClose
$rpt += get-htmltabcontentclose

$rpt += Get-HTMLClosePage

# --- Save Report ---
$ReportName = ("O365_Tenant_Report_" + (Get-Date -Format "yyyyMMdd"))
Save-HTMLReport -ReportContent $rpt -ShowReport -ReportName $ReportName -ReportPath $ReportSavePath
