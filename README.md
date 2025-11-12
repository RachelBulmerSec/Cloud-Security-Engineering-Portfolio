# **Rachel Bulmer's Security Engineering Portfolio**



This repository contains a collection of PowerShell scripts I have authored for security auditing, endpoint hardening, and automation within a Microsoft 365 and Azure environment. These tools demonstrate practical, hands-on experience in solving real-world engineering challenges, moving beyond "out-of-the-box" configurations to build custom, automated, and secure solutions.

## **Portfolio Highlights**

Advanced Identity Auditing: Scripts that audit complex, inherited permissions for Azure Service Principals and report on modern MFA registration status.

Intune Proactive Remediations: A suite of detection and remediation script pairs designed to be deployed via Intune to continuously enforce security baselines (e.g., removing rogue local admins, enforcing firewall rules).

Modern API & Automation: A focus on using the modern Microsoft Graph API (as opposed to deprecated modules) and PowerShell for scalable, automated solutions.

KQL Threat Hunting: Custom, tuned KQL queries for proactive threat hunting in Microsoft Sentinel, focused on high-fidelity, low-noise alerts.

## 1. Identity & Access Management (IAM)

(Files stored in `01_Identity_IAM`)
Scripts focused on auditing and securing identities in Azure Active Directory.

---

### 🔑 `Audit_Azure_ServicePrincipal_Permissions.ps1`

* **Problem:** Standard Azure audits don't show the effective permissions of a **Service Principal**, especially permissions inherited from being in a group.
* **Solution:** This advanced script audits all Service Principals, finds their direct **Azure RBAC roles**, and then recursively audits their group memberships to find all inherited permissions. This is critical for identifying **over-privileged service accounts**.

---

### 🔑 `Audit_MFA_Registration_Status.ps1`

* **Problem:** Needing a fast, modern way to audit which users have not registered any **MFA** methods.
* **Solution:** Uses the **Microsoft Graph API** (`Get-MgUserAuthenticationMethod`) to get a definitive report of all users who have no MFA methods registered. This is superior to older, deprecated AzureAD module methods.

---

### 🔑 `Utility_Get_OAuth_Token.ps1`

* **Problem:** Needing to programmatically get an **OAuth 2.0 token** for a service principal to interact with a custom API.
* **Solution:** A sanitized utility script demonstrating how to perform a **`client_credentials` grant flow** to acquire an access token from the Microsoft identity platform.

---

### 🔑 `Utility_Rotate_AzureAD_Password.ps1`

* **Problem:** Manually rotating passwords for Azure AD service accounts is tedious.
* **Solution:** A simple utility script to generate a strong random password and apply it to a specified **Azure AD user account** (by ObjectId).

<br>

## 2. Endpoint Hardening (Intune Proactive Remediations)

(Files stored in `02_Endpoint_Intune`)
A collection of Detection and Remediation script pairs designed for deployment via Microsoft Intune to enforce endpoint compliance.

---

### 🛡️ Intune_Detect_LocalAdmin.ps1 / Intune_Remediate_LocalAdmin.ps1

* **Problem:** A rogue local administrator account (LAdmin) exists on some endpoints, violating the security baseline.
* **Detection (Detect):** Exits with `1` (non-compliant) if the LAdmin account is found.
* **Solution (Remediation):** Removes the LAdmin account from the local machine.

---

### 🛡️ Intune_Detect_MappedDrive.ps1 / Intune_Remediate_MappedDrive.ps1

* **Problem:** A critical shared folder (synced via OneDrive) has a dynamic path (e.g., `C:\Users\...`), making traditional GPO mapping impossible. This is a robust solution for a complex, real-world engineering problem.
* **Detection (Detect):** Dynamically searches the user's profile and all OneDrive sync locations to find the correct path. It then checks if the 'S:' drive is mapped correctly to this dynamic path.
* **Solution (Remediation):** Performs the same dynamic search and then uses `subst` to create a persistent mapped drive for the user.

---

### 🛡️ Intune_Detect_RemoteAccess.ps1 / Intune_Remediate_RemoteAccess.ps1

* **Problem:** Key remote administration firewall rules (like for Ping, Remote Registry) are sometimes disabled, blocking administrative tools.
* **Detection (Detect):** Checks the status of key firewall rule groups ("Remote Event Log Management," etc.). Exits with `1` if any are disabled.
* **Solution (Remediation):** Re-enables all required firewall rule groups for remote administration.

---

### **2. Endpoint Hardening (Intune Proactive Remediations)**
___
#### (Files stored in 02_Endpoint_Intune)
A collection of Detection and Remediation script pairs designed for deployment via Microsoft Intune to enforce endpoint compliance.

|Filename | Problem | Detect | Solution |
|---------|---------|-----------|--------|
| **Intune_Detect_LocalAdmin.ps1 / Intune_Remediate_LocalAdmin.ps1** | A rogue local administrator account (LAdmin) exists on some endpoints, violating the security baseline. | Exits with 1 (non-compliant) if the LAdmin account is found. | Removes the LAdmin account from the local machine. |
| **Intune_Detect_MappedDrive.ps1 / Intune_Remediate_MappedDrive.ps1** | A critical shared folder (synced via OneDrive) has a dynamic path (C:\Users\...) making traditional GPO mapping impossible. This is a robust solution for a complex, real-world engineering problem. | Dynamically searches the user's profile and all OneDrive sync locations to find the correct path. It then checks if the 'S:' drive is mapped correctly to this dynamic path. | Performs the same dynamic search and then uses subst to create a persistent mapped drive for the user. |
| **Intune_Detect_RemoteAccess.ps1 / Intune_Remediate_RemoteAccess.ps1** | Key remote administration firewall rules (like for Ping, Remote Registry) are sometimes disabled, blocking administrative tools. | Checks the status of key firewall rule groups ("Remote Event Log Management," etc.). Exits with 1 if any are disabled. | Re-enables all required firewall rule groups for remote administration. |

<br>

|Filename | Problem | Solution |
|---------|---------|-----------|
| **Intune_Remediate_Uninstall_Software.ps1** | A specific, unapproved application (e.g., "Splashtop") needs to be removed from all endpoints. | This is a remediation-only script that runs as System, finds the application by name in WMI, and silently uninstalls it. |
| **Endpoint_Enforce_RegChanges.ps1** | Need to enforce specific, non-standard registry settings for compliance or user experience (e.g., "Show File Extensions"). |  A simple but effective script to directly set registry values, designed to be deployed via Intune. |


### **3. Auditing & Reporting**
___
#### (Files stored in 03_Audit_Reporting)
Scripts designed for inventory, auditing, and reporting on the security posture of endpoints and cloud services.

|Filename | Problem | Solution |
|---------|---------|-----------|
| **Audit_Exchange_SharedMailboxes.ps1** | Need to find unused or inactive shared mailboxes for cleanup. | Connects to Exchange Online and audits all shared mailboxes for their last login and last email access time. |
| **Audit_Defender_ASR_Rules.ps1** | Need to verify that Attack Surface Reduction (ASR) rules are correctly applied and configured on endpoints. | Audits the local machine's MpPreference to report all configured ASR rules and their current state ("Block", "Audit", "Disabled"). |
| **Audit_DotNetFramework_Versions.ps1 / Audit_DotNetCore_Versions.ps1** | Need to audit endpoints for outdated and vulnerable .NET runtimes. | Two separate scripts that audit the registry and file system to report all installed versions of .NET Framework and .NET Core. |
| **Audit_Email_Scheduled_Tasks.ps1** | Problem: Need to audit all Scheduled Tasks on a locked-down server (like a Domain Controller) for persistence mechanisms. | Solution: Gets all scheduled tasks, exports them to a CSV, and securely emails the report to an administrator using credentials. |
| **Audit_Registry_TrustedSites.ps1** | Need to audit Internet Explorer "Trusted Sites" registry keys for potential misconfigurations or security risks. | Recursively audits the ZoneMap registry keys to export a list of all configured "Trusted Sites". |
| **Reporting_O365_Tenant_Report.ps1** | Need a comprehensive, high-level "state of the nation" report for a Microsoft 365 tenant. | An adapted script that generates a multi-tabbed HTML report detailing user accounts, licenses, admin roles, groups, domains, and more. Demonstrates the ability to adapt and maintain existing community tools. |
| **Utility_Find_Python.ps1** | Need to find all installed versions of Python on a machine, even those installed in user profiles. | A utility script that searches all user profiles and common program paths to locate python.exe installations. |
| **Utility_Test_RemoteAccess.ps1** | Problem: A machine is online, but remote administration tools (like Event Viewer or Registry) are failing. | A senior-level troubleshooting utility that, from the admin's machine, remotely tests Ping, WinRM connection, core service status (RPC, Remote Registry), and firewall rule state on the target computer. |

___
## **4. KQL Analytic Rules (Microsoft Sentinel)**

(Files stored in 04_Sentinel_KQL)
This section contains a collection of custom-built KQL queries I have developed for threat hunting and creating high-fidelity analytic rules in Microsoft Sentinel. These queries are custom-built solutions designed to solve specific detection challenges and have been tuned with environment-specific exclusions to reduce false positives.

### **4.1 Endpoint & ASR Detections**

### _**Suspicious Child Process from msiexec.exe**_

Purpose: Detects when the legitimate Windows Installer (msiexec.exe) spawns a known attacker tool (e.g., PowerShell, cmd, cscript). The rule is custom-tuned to exclude known-good processes from HP and Intune to reduce alert noise.

MITRE ATT&CK Tactic(s): Defense Evasion
```kql
// This query is specifically tuned to hunt for suspicious child processes
// spawned by msiexec.exe. These are often indicators of defense evasion
// or malicious payload execution.
let suspiciousChildren = dynamic([
    "powershell.exe",
    "pwsh.exe",
    "cmd.exe",
    "wscript.exe",
    "cscript.exe",
    "rundll32.exe",
    "net.exe",
    "net1.exe",
    "whoami.exe",
    "certutil.exe",
    "bitsadmin.exe",
    "regsvr32.exe"
    ]);
DeviceProcessEvents
| where InitiatingProcessFileName =~ "msiexec.exe"
| where FileName in~ (suspiciousChildren)
| where not (
            // Exclusion for Intune-related rundll32.exe processes
            (
    FileName =~ "rundll32.exe" and
    (
    ProcessCommandLine contains "IntuneWindowsAgent.SideCar.Setup" or
    ProcessCommandLine contains "SideCarSetupCustomActions" or
    (ProcessCommandLine contains "ClientBroker" and ProcessCommandLine contains "CustomActions")
    )
    )
    or
    // Consolidated exclusions for HP processes running via cmd.exe
    (
    FileName =~ "cmd.exe" and
    (
    ProcessCommandLine contains @"\HP\HP System Default Settings\" or
    ProcessCommandLine contains @"Hewlett-Packard"
    )
    )
    or
    // NEW: Exclusion for HP Sure Click uninstallation script
    (
    FileName =~ "powershell.exe" and
    ProcessCommandLine contains @"HP\Sure Click\" and
    ProcessCommandLine contains @"Deploy-SBXEdge.ps1" and
    ProcessCommandLine contains "-Uninstall"
    )
        )
| project
    Timestamp,
    DeviceName,
    AccountName,
    InitiatingProcessFileName,
    InitiatingProcessCommandLine,
    FileName,
    ProcessCommandLine,
    SHA256,
    InitiatingProcessParentFileName,
    InitiatingProcessVersionInfoOriginalFileName
| sort by Timestamp desc
```
<br>

### _**Untrusted process detected on device**_

Purpose: Ensures that only approved, digitally-signed applications can run. This rule flags any process that runs from an untrusted folder (like a 'Downloads' folder) and isn't signed by a trusted vendor (like Microsoft or Google). This is a common attacker technique to run malicious tools.

MITRE ATT&CK Tactic(s): Defense Evasion
```kql
// --- Configuration: Define trusted properties ---
let trustedSigners = dynamic([
    "Microsoft Corporation",
    "Adobe Inc.",
    "Microsoft Windows",
    "Adobe Systems, Incorporated",
    "Microsoft Windows Publisher",
    "PaperCut Software Pty Ltd",
    "Lenovo",
    "Microsoft Windows Hardware Compatibility Publisher",
    "Google LLC",
    "Elliptic Laboratories ASA",
    "ConnectWise, Inc.",
    "Dolby Laboratories, Inc.",
    "HP Inc.",
    "Microsoft Dynamic Code Publisher",
    "Intel Corporation",
    "Realtek Semiconductor Corp.",
    "Intel(R) pGFX",
    "Microsoft 3rd Party Application Component",
    "GN AUDIO A/S",
    "Adobe Systems Incorporated",
    "Good Way Technology Co., Ltd.",
    "Johannes Schindelin"
]);
let trustedPathPrefixes = dynamic([
    @"C:\Program Files\",
    @"C:\Program Files (x86)\",
    @"C:\Windows\System32\",
    @"C:\Windows\SysWOW64\",
    @"C:\Windows\Microsoft.NET\",
    @"C:\Windows\SystemApps\"
]);
// --- Main Hunting Query ---
DeviceProcessEvents
| where Timestamp > ago(1h) // Use appropriate time window for analytic rule frequency
// --- ADDED FILTER FOR SPECIFIC COMMAND ---
| where FileName == "StartMenuExperienceHost.exe"
    and SHA256 == "68e2255ececae067300be751839d84cbbf888872a372c40903b49394870a118d"
| join kind=leftouter (DeviceFileCertificateInfo) on SHA1
// --- MODIFIED TRUST LOGIC ---
| extend
    IsSignerTrusted = Signer in (trustedSigners) and IsTrusted == true,
// --- REVERTED TO SUPPORTED LOGIC ---
    IsPathTrusted = FolderPath startswith trustedPathPrefixes[0] or
                    FolderPath startswith trustedPathPrefixes[1] or
                    FolderPath startswith trustedPathPrefixes[2] or
                    FolderPath startswith trustedPathPrefixes[3] or
                    FolderPath startswith trustedPathPrefixes[4] or
                    FolderPath startswith trustedPathPrefixes[5],
    IsTrustedGoogleUpdater = (Signer == "Google LLC" or (isempty(Signer) and InitiatingProcessFileName == "updater.exe")) and FileName == "updater.exe",
    IsTrustedTeamsSetup = (Signer == "Microsoft Corporation" or Signer == "Microsoft") and FileName == "MSTeamsSetup.exe",
    IsTrustedPaperCutUpdater = (Signer == "PaperCut Software Pty Ltd" and FileName == "pc-print-client-updater.exe")
// --- Core Filter with all exceptions ---
| where IsSignerTrusted == false
    and IsPathTrusted == false
    and IsTrustedGoogleUpdater == false
    and IsTrustedTeamsSetup == false
    and IsTrustedPaperCutUpdater == false
// --- Summarization for Analytic Rule ---
| summarize EventCount = count(), LastSeen = max(Timestamp), take_any(*) by DeviceName, FileName, FolderPath, Signer, InitiatingProcessFileName, ProcessCommandLine
// --- Final Projection for Alert Details ---
| project
    LastSeen,
    DeviceName,
    FileName,
    FolderPath,
    Signer,
    EventCount,
    ProcessCommandLine,
    InitiatingProcessFileName,
    SHA256
```

<br>

### _**ASR - Process Creation from PsExec or WMI**_

Purpose: ASR stands for 'Attack Surface Reduction'. This rule detects a common "lateral movement" technique where an attacker, already on one machine, uses legitimate admin tools (PsExec or WMI) to run commands on other machines in the network.

MITRE ATT&CK Tactic(s): Lateral Movement, Execution
```kql
DeviceEvents
| where ActionType in ("AsrPsexecWmiChildProcessAudited", "AsrPsexecWmiChildProcessBlocked")
| project Timestamp,
          DeviceName,
          InitiatingProcessFileName,
          InitiatingProcessCommandLine,
          FileName,
          ProcessCommandLine,
          InitiatingAccount = InitiatingProcessAccountName,
          ActionType
| sort by Timestamp desc
```

<br>

### _**ASR - Credential Stealing from LSASS Detected**_

Purpose: This ASR rule specifically detects an attempt to steal passwords from the 'LSASS' process in memory—the digital equivalent of a password vault on Windows. This is a classic (and very serious) attacker technique used by tools like Mimikatz.

MITRE ATT&CK Tactic(s): Credential Access
```kql
DeviceEvents
| where ActionType in ("AsrLsassCredentialTheftAudited", "AsrLsassCredentialTheftBlocked")
| where ProcessCommandLine != ""
| project Timestamp,
          DeviceName,
          FileName,
          ProcessCommandLine,
          InitiatingAccount = InitiatingProcessAccountName,
          ActionType
| sort by Timestamp desc
```

<br>

### _**Ransomware-like Activity - Controlled Folder Access Violation**_

Purpose: This rule is a high-priority ransomware alarm. It detects when the 'Controlled Folder Access' (CFA) feature in Windows blocks an unauthorized program from modifying files in protected folders (like 'Documents'). This is a hallmark of a ransomware attack in its initial encryption phase.

MITRE ATT&CK Tactic(s): Impact
```kql
DeviceEvents
| where ActionType in ("ControlledFolderAccessViolationAudited", "ControlledFolderAccessViolationBlocked")
| project Timestamp,
          DeviceName,
          FileName,
          FolderPath,
          InitiatingProcessFileName,
          InitiatingProcessCommandLine,
          InitiatingAccount = InitiatingProcessAccountName
| sort by Timestamp desc
```

<br>

### _**WDAC Audit Event Detected**_

Purpose: WDAC (Windows Defender Application Control) is a strict 'Application Control' policy. This rule simply alerts when a user tries to run a program that was blocked by the policy. It provides visibility into policy enforcement and helps identify if/when employees are attempting to run unauthorized software.

MITRE ATT&CK Tactic(s): Defense Evasion, Execution
```kql
DeviceEvents
| where ActionType startswith "AppControlCodeIntegrity"
| where ActionType contains "Audited"
```
<br>

### _**COM Registry Key Modified to Point to File in Color Profile Folder**_

Purpose: Highly specific detection for a persistence technique involving modifying COM registry keys (CLSID) to point to the color profile folder (System32\spool\drivers\color) for persistent execution.

MITRE ATT&CK Tactic(s): Persistence
```kql
let guids = dynamic(["{ddc05a5a-351a-4e06-8eaf-54ec1bc2dcea}","{1f486a52-3cb1-48fd-8f50-b8dc300d9f9d}","{4590f811-1d3a-11d0-891f-00aa004b2e24}", "{4de225bf-cf59-4cfc-85f7-68b90f185355}", "{F56F6FDD-AA9D-4618-A949-C1B91AF43B1A}"]);
  let mde_data = DeviceRegistryEvents
  | where ActionType =~ "RegistryValueSet"
  | where RegistryKey contains "HKEY_LOCAL_MACHINE\\SOFTWARE\\Classes\\CLSID"
  | where RegistryKey has_any (guids)
  | where RegistryValueData has "System32\\spool\\drivers\\color";
  let event_data = SecurityEvent
  | where EventID == 4657
  | where ObjectName contains "HKEY_LOCAL_MACHINE\\SOFTWARE\\Classes\\CLSID"
  | where ObjectName has_any (guids)
  | where NewValue has "System32\\spool\\drivers\\color"
  | extend RegistryKey = ObjectName, RegistryValueData = NewValue, DeviceName=Computer, InitiatingProcessFileName = Process, InitiatingProcessAccountName=SubjectUserName, InitiatingProcessAccountDomain = SubjectDomainName;
  union mde_data, event_data
  | extend HostName = tostring(split(DeviceName, ".")[0]), DomainIndex = toint(indexof(DeviceName, '.'))
  | extend HostNameDomain = iff(DomainIndex != -1, substring(DeviceName, DomainIndex + 1), DeviceName)
```

<br>

## **4.2 Identity & Access Management Detections**

### _**Emergency Admin Login Detected**_

Purpose: This is a high-priority alert for a specific 'break-glass' emergency administrator account. Nobody should be logging in with this account during normal operations. This alert ensures any use of this highly-privileged account (identified by its unique UserId) is immediately investigated.

MITRE ATT&CK Tactic(s): Persistence, Privilege Escalation, Defense Evasion
```kql
SigninLogs
// GUID redacted for security (placeholder added). This targets a specific 'break-glass' account.
| where UserId contains "EMERGENCY_ACCOUNT_OBJECT_ID_REDACTED"
| extend parsedData = parse_json(DeviceDetail)
| extend deviceId = tostring(parsedData.deviceId)
| extend deviceName = tostring(parsedData.displayName)
| extend compliancy = tostring(parsedData.isCompliant)
| extend managed = tostring(parsedData.isManaged)
| extend operatingSystem = tostring(parsedData.operatingSystem)
| extend browser = tostring(parsedData.browser)
| project-away DeviceDetail, parsedData
| project TimeGenerated, Identity, OperationName, ResultType, ResultSignature, ResultDescription, IPAddress, Location, ResourceDisplayName, AppDisplayName, deviceId, operatingSystem, browser, deviceName, compliancy, managed
```

<br>

### _**Risky Sign in Detected**_

Purpose: This rule validates that our automated MFA policies are working. It alerts when a user's sign-in is flagged as 'risky' by Microsoft (e.g., from a new country) and that sign-in was then correctly challenged by the "Require multifactor authentication for risky sign-ins" Conditional Access policy.

MITRE ATT&CK Tactic(s): Initial Access
```kql
SigninLogs
| where RiskLevelAggregated != "none"
| mv-expand PolicyDetails = ConditionalAccessPolicies
| project TimeGenerated, UserPrincipalName, PolicyName = tostring(PolicyDetails.displayName), ConditionalAccessStatus, RiskLevelAggregated
| where PolicyName contains "Require multifactor authentication for risky sign-ins"
```

<br>

### _**Sign-ins from IPs that attempt sign-ins to disabled accounts**_

Purpose: This rule spots an attacker probing for active accounts. It finds IP addresses that tried to log into disabled accounts and then checks if that same IP successfully logged into an active account, indicating a successful breach and providing a high-confidence alert.

MITRE ATT&CK Tactic(s): Initial Access, Persistence
```kql
let aadFunc = (tableName: string) {
let failed_signins = table(tableName)
| where ResultType == "50057"
| where ResultDescription == "User account is disabled. The account has been disabled by an administrator.";
let disabled_users = failed_signins | summarize by UserPrincipalName;
table(tableName)
| where ResultType == 0
| where isnotempty(UserPrincipalName)
| where UserPrincipalName !in (disabled_users)
| summarize
        successfulAccountsTargettedCount = dcount(UserPrincipalName),
        successfulAccountSigninSet = make_set(UserPrincipalName, 100),
        successfulApplicationSet = make_set(AppDisplayName, 100)
    by IPAddress, Type
    // Assume IPs associated with sign-ins from 100+ distinct user accounts are safe
| where successfulAccountsTargettedCount < 50
| where isnotempty(successfulAccountsTargettedCount)
| join kind=inner (failed_signins
| summarize
    StartTime = min(TimeGenerated),
    EndTime = max(TimeGenerated),
    totalDisabledAccountLoginAttempts = count(),
    disabledAccountsTargettedCount = dcount(UserPrincipalName),
    applicationsTargeted = dcount(AppDisplayName),
    disabledAccountSet = make_set(UserPrincipalName, 100),
    disabledApplicationSet = make_set(AppDisplayName, 100)
by IPAddress, Type
| order by totalDisabledAccountLoginAttempts desc) on IPAddress
| project StartTime, EndTime, IPAddress, totalDisabledAccountLoginAttempts, disabledAccountsTargettedCount, disabledAccountSet, disabledApplicationSet, successfulApplicationSet, successfulAccountsTargettedCount, successfulAccountSigninSet, Type
| order by totalDisabledAccountLoginAttempts};
let aadSignin = aadFunc("SigninLogs");
let aadNonInt = aadFunc("AADNonInteractiveUserSignInLogs");
union isfuzzy=true aadSignin, aadNonInt
| join kind=leftouter (
    BehaviorAnalytics
| where ActivityType in ("FailedLogOn", "LogOn")
| where EventSource =~ "Azure AD"
| project UsersInsights, DevicesInsights, ActivityInsights, InvestigationPriority, SourceIPAddress, UserPrincipalName
| project-rename IPAddress = SourceIPAddress
| summarize
        Users = make_set(UserPrincipalName, 100),
        UsersInsights = make_set(UsersInsights, 100),
        DevicesInsights = make_set(DevicesInsights, 100),
        IPInvestigationPriority = sum(InvestigationPriority)
    by IPAddress
) on IPAddress
| extend SFRatio = toreal(toreal(disabledAccountsTargettedCount)/toreal(successfulAccountsTargettedCount))
| where SFRatio >= 0.5
| sort by IPInvestigationPriority desc
```


<br>

### _**SharePointFileOperation via devices with previously unseen user agents**_

Purpose: Detects when a user accesses SharePoint from a new device or browser they've never used before. This query builds a 14-day baseline of "normal" User Agents for each user and then flags any new ones, which could indicate a session-hijacking attempt.

MITRE ATT&CK Tactic(s): Defense Evasion, Initial Access
```kql
// Set threshold for the number of downloads/uploads from a new user agent
  let threshold = 5;
  // Define constants for SharePoint file operations
  let szSharePointFileOperation = "SharePointFileOperation";
  let szOperations = dynamic(["FileDownloaded", "FileUploaded"]);
  // Define the historical activity for analysis
  let starttime = 14d; // Define the start time for historical data (14 days ago)
  let endtime = 1d;   // Define the end time for historical data (1 day ago)
  // Extract the base events for analysis
  let Baseevents =
    OfficeActivity
    | where TimeGenerated between (ago(starttime) .. ago(endtime))
    | where RecordType =~ szSharePointFileOperation
    | where Operation in~ (szOperations)
    | where isnotempty(UserAgent);
  // Identify frequently occurring user agents
  let FrequentUA = Baseevents
    | summarize FUACount = count() by UserAgent, RecordType, Operation
    | where FUACount >= threshold
    | distinct UserAgent;
  // Calculate a user baseline for further analysis
  let UserBaseLine = Baseevents
    | summarize Count = count() by UserId, Operation, Site_Url
    | summarize AvgCount = avg(Count) by UserId, Operation, Site_Url;
  // Extract recent activity for analysis
  let RecentActivity = OfficeActivity
    | where TimeGenerated > ago(endtime)
    | where RecordType =~ szSharePointFileOperation
    | where Operation in~ (szOperations)
    | where isnotempty(UserAgent)
    | where UserAgent in~ (FrequentUA)
    | summarize StartTime = min(TimeGenerated), EndTime = max(TimeGenerated), OfficeObjectIdCount = dcount(OfficeObjectId), OfficeObjectIdList = make_set(OfficeObjectId), UserAgentSeenCount = count()
    by RecordType, Operation, UserAgent, UserType, UserId, ClientIP, OfficeWorkload, Site_Url;
  // Analyze user behavior based on baseline and recent activity
  let UserBehaviorAnalysis = UserBaseLine
    | join kind=inner (RecentActivity) on UserId, Operation, Site_Url
    | extend Deviation = abs(UserAgentSeenCount - AvgCount) / AvgCount;
  // Filter and format results for specific user behavior analysis
  UserBehaviorAnalysis
    | where Deviation > 25
    | extend UserIdName = tostring(split(UserId, '@')[0]), UserIdUPNSuffix = tostring(split(UserId, '@')[1])
    | project-reorder StartTime, EndTime, UserAgent, UserAgentSeenCount, UserId, ClientIP, Site_Url
    | project-away Site_Url1, UserId1, Operation1
    | order by UserAgentSeenCount desc, UserAgent asc, UserId asc, Site_Url asc
```

## **4.3 Threat Intelligence (TI) Detections**

### _**TI Map IP Entity to SigninLogs**_

Purpose: Stands for 'Threat Intelligence Map'. This rule automatically checks all user sign-ins against a live, external list of known-malicious IP addresses (Threat Intelligence) to flag any employee sign-in originating from a command-and-control server.

MITRE ATT&CK Tactic(s): Command And Control
```kql
let dt_lookBack = 1h;
let ioc_lookBack = 14d;
let Signins = materialize(union isfuzzy=true
  (SigninLogs
  | where TimeGenerated >= ago(dt_lookBack)),
  (AADNonInteractiveUserSignInLogs
  | where TimeGenerated >= ago(dt_lookBack)
  | extend Status = todynamic(Status), LocationDetails = todynamic(LocationDetails)));
let SigninIPs = Signins | summarize make_list(IPAddress);
let TI = materialize(ThreatIntelIndicators
//extract key part of kv pair
| extend IndicatorType = replace(@"\[|\]|\""", "", tostring(split(ObservableKey, ":", 0)))
| where IndicatorType in ("ipv4-addr", "ipv6-addr", "network-traffic")
| extend NetworkSourceIP = toupper(ObservableValue)
| extend TrafficLightProtocolLevel = tostring(parse_json(AdditionalFields).TLPLevel)
| where TimeGenerated >= ago(ioc_lookBack)
| extend TI_ipEntity = NetworkSourceIP
| extend Url = iff(ObservableKey == "url:value", ObservableValue, "")
| where TI_ipEntity in (SigninIPs)
| summarize LatestIndicatorTime = arg_max(TimeGenerated, *) by Id, ObservableValue
| extend Description = tostring(parse_json(Data).description)
| where IsActive and (ValidUntil > now() or isempty(ValidUntil))
| where Description !contains_cs "State: inactive;" and Description !contains_cs "State: falsepos;");
TI
| project-reorder *, Tags, TrafficLightProtocolLevel, NetworkSourceIP, Type, TI_ipEntity
// using innerunique to keep perf fast and result set low, we only need one match to indicate potential malicious activity that needs to be investigated
| join kind=innerunique (Signins) on $left.TI_ipEntity == $right.IPAddress
| project-rename SigninLogs_TimeGenerated = TimeGenerated
| where SigninLogs_TimeGenerated < ValidUntil
| extend StatusCode = tostring(Status.errorCode), StatusDetails = tostring(Status.additionalDetails), StatusReason = tostring(Status.failureReason)
| summarize SigninLogs_TimeGenerated = arg_max(SigninLogs_TimeGenerated, *) by Id, IPAddress
| extend Description = tostring(parse_json(Data).description)
| extend ActivityGroupNames = extract(@"ActivityGroup:(\S+)", 1, tostring(parse_json(Data).labels))
| project SigninLogs_TimeGenerated, Description, ActivityGroupNames, Id, ValidUntil, Confidence, TI_ipEntity, IPAddress, UserPrincipalName, AppDisplayName, StatusCode, StatusDetails, StatusReason, NetworkSourceIP, Type, Url
| extend timestamp = SigninLogs_TimeGenerated, Name = tostring(split(UserPrincipalName, '@', 0)[0]), UPNSuffix = tostring(split(UserPrincipalName, '@', 1)[0])
```

<br>

### _**TI Map IP Entity to AzureActivity**_

Purpose: Similar to the rule above, but this one checks administrator activity within Azure (like creating a virtual machine) against the same malicious IP list. This helps catch attackers who have already compromised an admin account and are using it to build infrastructure.

MITRE ATT&CK Tactic(s): Command And Control
```kql
let dt_lookBack = 1h; // Look back 1 hour for AzureActivity logs
let ioc_lookBack = 14d; // Look back 14 days for threat intelligence indicators
// Fetch threat intelligence indicators related to IP addresses
let IP_Indicators = ThreatIntelIndicators
 //extract key part of kv pair
     | extend IndicatorType = replace(@"\[|\]|\""", "", tostring(split(ObservableKey, ":", 0)))
     | where IndicatorType in ("ipv4-addr", "ipv6-addr", "network-traffic")
     | extend NetworkSourceIP = toupper(ObservableValue)
     | extend TrafficLightProtocolLevel = tostring(parse_json(AdditionalFields).TLPLevel)
  // Filter out indicators without relevant IP address fields
  | where TimeGenerated >= ago(ioc_lookBack)
  // Select the IP entity based on availability of different IP fields
  | extend TI_ipEntity = iff(isnotempty(NetworkSourceIP), NetworkSourceIP, NetworkSourceIP)
  | extend TI_ipEntity = iff(isempty(TI_ipEntity) and isnotempty(NetworkSourceIP), NetworkSourceIP, TI_ipEntity)
  | extend Url = iff(ObservableKey == "url:value", ObservableValue, "")
  // Exclude local addresses using the ipv4_is_private operator and filtering out specific address prefixes
  | where ipv4_is_private(TI_ipEntity) == false and  TI_ipEntity !startswith "fe80" and TI_ipEntity !startswith "::" and TI_ipEntity !startswith "127."
  | summarize LatestIndicatorTime = arg_max(TimeGenerated, *) by Id, ObservableValue
  | where IsActive and (ValidUntil > now() or isempty(ValidUntil));
// Perform a join between IP indicators and AzureActivity logs to identify potential malicious activity
IP_Indicators
   | project-reorder *, Tags, TrafficLightProtocolLevel, NetworkSourceIP, Type, TI_ipEntity
// using innerunique to keep perf fast and result set low, we only need one match to indicate potential malicious activity that needs to be investigated
| join kind=innerunique (
    AzureActivity | where TimeGenerated >= ago(dt_lookBack)
    // renaming time column so it is clear the log this came from
    | extend AzureActivity_TimeGenerated = TimeGenerated
) on $left.TI_ipEntity == $right.CallerIpAddress
| where AzureActivity_TimeGenerated < ValidUntil
| summarize AzureActivity_TimeGenerated = arg_max(AzureActivity_TimeGenerated, *) by Id, CallerIpAddress
| extend Description = tostring(parse_json(Data).description)
| extend ActivityGroupNames = extract(@"ActivityGroup:(\S+)", 1, tostring(parse_json(Data).labels))
| project AzureActivity_TimeGenerated, Description, ActivityGroupNames, Id, ValidUntil, Confidence, TI_ipEntity, CallerIpAddress,
Caller, OperationNameValue, ActivityStatusValue, CategoryValue, ResourceId, NetworkSourceIP, Type, Url
| extend timestamp = AzureActivity_TimeGenerated
| extend Name = iif(Caller has '@', tostring(split(Caller,'@',0)[0]), "")
| extend UPNSuffix = iif(Caller has '@', tostring(split(Caller,'@',1)[0]), "")
| extend AadUserId = iif(Caller !has '@', tostring(Caller), "")
```

<br>

### _**TI Map URL Entity to UrlClickEvents**_

Purpose: This 'Threat Intelligence' rule scans the links users are clicking in their emails (via Microsoft Defender's "Safe Links"). It compares every clicked link against a live list of known-malicious phishing websites and alerts if there's a match.

MITRE ATT&CK Tactic(s): Command And Control
```kql
let dt_lookBack = 1h;
let ioc_lookBack = 14d;
let UrlClickEvents_ = materialize(UrlClickEvents
| where TimeGenerated >= ago(dt_lookBack)
| extend UrlClickEvents_TimeGenerated = TimeGenerated);
let ChainReportID = UrlClickEvents_
| mv-expand todynamic(UrlChain)
| extend UrlChain = tolower(UrlChain)
| project ReportId, Url, UrlChain;
// Url is not always in UrlChain, so we need to check both
let ClickedUrls =
  (union isfuzzy=false (ChainReportID), (ChainReportID | project Url = UrlChain))
| distinct Url
| summarize make_list(Url);
let TI = materialize(ThreatIntelligenceIndicator
| where TimeGenerated >= ago(ioc_lookBack)
| where isnotempty(Url) and tolower(Url) in (ClickedUrls)
| summarize LatestIndicatorTime = arg_max(TimeGenerated, *) by IndicatorId
| where Active == true and ExpirationDateTime > now()
| project-rename TI_Url = Url, TI_Type = Type
);
(union isfuzzy=false (TI | join kind=innerunique (ChainReportID) on $left.TI_Url == $right.UrlChain),
(TI | join kind=innerunique (ChainReportID) on $left.TI_Url == $right.Url))
| project-away UrlChain
| join kind=innerunique (UrlClickEvents_) on ReportId
| where UrlClickEvents_TimeGenerated < ExpirationDateTime
| summarize UrlClickEvents_TimeGenerated = arg_max(UrlClickEvents_TimeGenerated, *) by IndicatorId
| project UrlClickEvents_TimeGenerated, AccountUpn, Description, ActivityGroupNames, IndicatorId, ThreatType, ExpirationDateTime, ConfidenceScore, Url, NetworkMessageId
| extend timestamp = UrlClickEvents_TimeGenerated
| extend timestamp = UrlClickEvents_TimeGenerated, Name = tostring(split(AccountUpn, '@', 0)[0]), UPNSuffix = tostring(split(AccountUpn, '@', 1)[0])
```

## **4.4 M365 & Exchange Detections**

### _**SharePointFileOperation via devices with previously unseen user agents**_

Purpose: Detects when a user accesses SharePoint from a new device or browser they've never used before. This query builds a 14-day baseline of "normal" User Agents for each user and then flags any new ones, which could indicate a session-hijacking attempt.

MITRE ATT&CK Tactic(s): Defense Evasion, Initial Access
```kql
// Set threshold for the number of downloads/uploads from a new user agent
  let threshold = 5;
  // Define constants for SharePoint file operations
  let szSharePointFileOperation = "SharePointFileOperation";
  let szOperations = dynamic(["FileDownloaded", "FileUploaded"]);
  // Define the historical activity for analysis
  let starttime = 14d; // Define the start time for historical data (14 days ago)
  let endtime = 1d;   // Define the end time for historical data (1 day ago)
  // Extract the base events for analysis
  let Baseevents =
    OfficeActivity
    | where TimeGenerated between (ago(starttime) .. ago(endtime))
    | where RecordType =~ szSharePointFileOperation
    | where Operation in~ (szOperations)
    | where isnotempty(UserAgent);
  // Identify frequently occurring user agents
  let FrequentUA = Baseevents
    | summarize FUACount = count() by UserAgent, RecordType, Operation
    | where FUACount >= threshold
    | distinct UserAgent;
  // Calculate a user baseline for further analysis
  let UserBaseLine = Baseevents
    | summarize Count = count() by UserId, Operation, Site_Url
    | summarize AvgCount = avg(Count) by UserId, Operation, Site_Url;
  // Extract recent activity for analysis
  let RecentActivity = OfficeActivity
    | where TimeGenerated > ago(endtime)
    | where RecordType =~ szSharePointFileOperation
    | where Operation in~ (szOperations)
    | where isnotempty(UserAgent)
    | where UserAgent in~ (FrequentUA)
    | summarize StartTime = min(TimeGenerated), EndTime = max(TimeGenerated), OfficeObjectIdCount = dcount(OfficeObjectId), OfficeObjectIdList = make_set(OfficeObjectId), UserAgentSeenCount = count()
    by RecordType, Operation, UserAgent, UserType, UserId, ClientIP, OfficeWorkload, Site_Url;
  // Analyze user behavior based on baseline and recent activity
  let UserBehaviorAnalysis = UserBaseLine
    | join kind=inner (RecentActivity) on UserId, Operation, Site_Url
    | extend Deviation = abs(UserAgentSeenCount - AvgCount) / AvgCount;
  // Filter and format results for specific user behavior analysis
  UserBehaviorAnalysis
    | where Deviation > 25
    | extend UserIdName = tostring(split(UserId, '@')[0]), UserIdUPNSuffix = tostring(split(UserId, '@')[1])
    | project-reorder StartTime, EndTime, UserAgent, UserAgentSeenCount, UserId, ClientIP, Site_Url
    | project-away Site_Url1, UserId1, Operation1
    | order by UserAgentSeenCount desc, UserAgent asc, UserId asc, Site_Url asc
```

<br>

### _**SharePointFileOperation via previously unseen IPs**_

Purpose: This rule detects anomalous file activity in SharePoint. It builds a 14-day baseline of who accesses what from which IP address. It then flags a user who, for example, suddenly downloads or uploads 25x (2500%) more files than their personal average from a specific IP, indicating a potential data breach or exfiltration.

MITRE ATT&CK Tactic(s): Exfiltration
```kql
// Define a threshold for significant deviations
let threshold = 25;
// Define the name for the SharePoint File Operation record type
let szSharePointFileOperation = "SharePointFileOperation";
// Define an array of SharePoint operations of interest
let szOperations = dynamic(["FileDownloaded", "FileUploaded"]);
// Define the start and end time for the analysis period
let starttime = 14d;
let endtime = 1d;
// Define a baseline of normal user behavior
let userBaseline = OfficeActivity
| where TimeGenerated between(ago(starttime)..ago(endtime))
| where RecordType =~ szSharePointFileOperation
| where Operation in~ (szOperations)
| where isnotempty(UserAgent)
| summarize Count = count() by UserId, Operation, Site_Url, ClientIP
| summarize AvgCount = avg(Count) by UserId, Operation, Site_Url, ClientIP;
// Get recent user activity
let recentUserActivity = OfficeActivity
| where TimeGenerated > ago(endtime)
| where RecordType =~ szSharePointFileOperation
| where Operation in~ (szOperations)
| where isnotempty(UserAgent)
| summarize StartTimeUtc = min(TimeGenerated), EndTimeUtc = max(TimeGenerated), RecentCount = count() by UserId, UserType, Operation, Site_Url, ClientIP, OfficeObjectId, OfficeWorkload, UserAgent;
// Join the baseline and recent activity, and calculate the deviation
let UserBehaviorAnalysis = userBaseline | join kind=inner (recentUserActivity) on UserId, Operation, Site_Url, ClientIP
| extend Deviation = abs(RecentCount - AvgCount) / AvgCount;
// Filter for significant deviations
UserBehaviorAnalysis
| where Deviation > threshold
| project StartTimeUtc, EndTimeUtc, UserId, UserType, Operation, ClientIP, Site_Url, OfficeObjectId, OfficeWorkload, UserAgent, Deviation, Count=RecentCount
| order by Count desc, ClientIP asc, Operation asc, UserId asc
| extend AccountName = tostring(split(UserId, "@")[0]), AccountUPNSuffix = tostring(split(UserId, "@")[1])
```

<br>

### _**Malicious Inbox Rule**_

Purpose: Detects when an attacker, after compromising an email account, creates an 'Inbox Rule' to hide their tracks. This rule specifically looks for rules that automatically delete emails containing keywords like 'phishing', 'malicious', or 'suspicious', which attackers use to prevent the real user from seeing warning messages.

MITRE ATT&CK Tactic(s): Persistence, Defense Evasion
```kql
let Keywords = dynamic(["helpdesk", " alert", " suspicious", "fake", "malicious", "phishing", "spam", "do not click", "do not open", "hijacked", "Fatal"]);
OfficeActivity
| where OfficeWorkload =~ "Exchange"
| where Operation =~ "New-InboxRule" and (ResultStatus =~ "True" or ResultStatus =~ "Succeeded")
| where Parameters has "Deleted Items" or Parameters has "Junk Email"  or Parameters has "DeleteMessage"
| extend Events=todynamic(Parameters)
| parse Events  with * "SubjectContainsWords" SubjectContainsWords '}'*
| parse Events  with * "BodyContainsWords" BodyContainsWords '}'*
| parse Events  with * "SubjectOrBodyContainsWords" SubjectOrBodyContainsWords '}'*
| where SubjectContainsWords has_any (Keywords)
or BodyContainsWords has_any (Keywords)
or SubjectOrBodyContainsWords has_any (Keywords)
| extend ClientIPAddress = case( ClientIP has ".", tostring(split(ClientIP,":")[0]), ClientIP has "[", tostring(trim_start(@'[[]',tostring(split(ClientIP,"]")[0]))), ClientIP )
| extend Keyword = iff(isnotempty(SubjectContainsWords), SubjectContainsWords, (iff(isnotempty(BodyContainsWords),BodyContainsWords,SubjectOrBodyContainsWords )))
| extend RuleDetail = case(OfficeObjectId contains '/' , tostring(split(OfficeObjectId, '/')[-1]) , tostring(split(OfficeObjectId, '\\')[-1]))
| summarize count(), StartTimeUtc = min(TimeGenerated), EndTimeUtc = max(TimeGenerated) by  Operation, UserId, ClientIPAddress, ResultStatus, Keyword, OriginatingServer, OfficeObjectId, RuleDetail
| extend AccountName = tostring(split(UserId, "@")[0]), AccountUPNSuffix = tostring(split(UserId, "@")[1])
| extend OriginatingServerName = tostring(split(OriginatingServer, " ")[0])
```

