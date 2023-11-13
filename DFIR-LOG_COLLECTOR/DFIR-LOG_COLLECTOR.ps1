<#
.SYNOPSIS
    Collects forensics data for analyst.
.DESCRIPTION
    This script will collect a variety of forensic data for an analyst.
.PARAMETER OPERATOR
    Mandatory. Enter your name as "FIRST.LAST".
.PARAMETER CASE
    Mandatory. Enter a SOAR event or case number.
.PARAMETER USERNAME
    Optional. Enter one or more specific USERNAMES (separated by comma) to collect. (Default: allusers)
.PARAMETER RAM
    Optional. Enter 'yes' or 'no' to capture RAM.
.PARAMETER PROCESSES
    Optional. Enter 'yes' or 'no' to dump all running processes.
.PARAMETER EVENTLOG
    Optional. Enter 'yes' or 'no' to parse the eventlogs.
.PARAMETER PCAP
    Optional. Enter 'yes' or 'no' to capture PCAP (5 minutes).
.PARAMETER RANSOMWARE
    Optional. Enter 'yes' or 'no' check for known RANSOMWARE file extensions.
.INPUTS
    Parameters above
.OUTPUTS
    None
.NOTES
    Version:        1.0
    Author:         Elite Grassh0pp3r
    Creation Date:  11/11/2023
    Purpose/Change: Initial Fornesic Log Collector script creation
.EXAMPLE
    PowerShell Console: ./DFIR-LOG_COLLECTOR.ps1 -OPERATOR "John.Doe" -CASE "23-1234" #Minimum Parameters that must be passed
    Tanium: cmd.exe /c PowerShell.exe -ExecutionPolicy Bypass -File DFIR-LOG_COLLECTOR.ps1 -OPERATOR %1 -CASE %2
    MDE: run DFIR-LOG_COLLECTOR.ps1 "'John.Doe' '23-1234'" #Minimum Parameters that must be passed
.EXAMPLE
    PowerShell Console: ./DFIR-LOG_COLLECTOR.ps1 -OPERATOR "John.Doe" -CASE "23-1234" -USERNAME "Johnny.Deed" -RAM "yes" -PROCESSES "yes" -EVENTLOG "yes" -PCAP "yes" -RANSOMWARE "yes"
    Tanium: cmd.exe /c PowerShell.exe -ExecutionPolicy Bypass -File DFIR-LOG_COLLECTOR.ps1 -OPERATOR %1 -CASE %2 -USERNAME %3 -RAM %4 -PROCESSES %5 -EVENTLOG %6 -PCAP %7 -RANSOMWARE %8
    MDE: run DFIR-LOG_COLLECTOR.ps1 "'John.Doe' '23-1234' 'Johnny.Deed' 'no' 'no' 'no' 'no' 'no'"
#>
[cmdletbinding()]
Param(
    [Parameter(Mandatory=$true,Position=0,HelpMessage='Enter your name (first.last)')]
        [String]$OPERATOR,
    [Parameter(Mandatory=$true,Position=1,HelpMessage='Enter a SOAR event or case number.')]
        [String]$CASE,
    [Parameter(Mandatory=$false,Position=2,HelpMessage='Enter one or more specific USERNAMES (separated by comma) to collect. (Default: allusers)')]
        [String[]]$USERNAME = 'allusers',
#    [Parameter(Mandatory=$false,Position=2,HelpMessage='Enter yes or no to capture MFT.')]
#        [String]$MFT = 'no',
    [Parameter(Mandatory=$false,Position=3,HelpMessage='Enter yes or no to capture RAM.')]
        [String]$RAM = 'no',
    [Parameter(Mandatory=$false,Position=4,HelpMessage='Enter yes or no to dump all running processes.')]
        [String]$PROCESSES = 'no',
    [Parameter(Mandatory=$false,Position=5,HelpMessage='Enter yes or no to parse the eventlogs.')]
        [String]$EVENTLOG = 'no',
    [Parameter(Mandatory=$false,Position=6,HelpMessage='Enter yes or no to capture PCAP (5 minutes).')]
        [String]$PCAP = 'no',
    [Parameter(Mandatory=$false,Position=7,HelpMessage='Enter yes or no to check for known RANSOMWARE file extensions.')]
        [String]$RANSOMWARE = 'no'
)

Import-Module Microsoft.Powershell.LocalAccounts
Import-Module "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\PnpDevice\PnpDevice.psd1"
Add-Type -AssemblyName System.Web

$OPERATOR = ([System.Web.HttpUtility]::UrlDecode($OPERATOR)).ToLower().Replace("`"","")
$CASE = ([System.Web.HttpUtility]::UrlDecode($CASE)).ToLower().Replace("`"","")
$USERNAME = ([System.Web.HttpUtility]::UrlDecode($USERNAME)).ToLower().Replace("`"","")
#$MFT = ([System.Web.HttpUtility]::UrlDecode($MFT)).ToLower().Replace("`"","")
$RAM = ([System.Web.HttpUtility]::UrlDecode($RAM)).ToLower().Replace("`"","")
$PROCESSES = ([System.Web.HttpUtility]::UrlDecode($PROCESSES)).ToLower().Replace("`"","")
$EVENTLOG = ([System.Web.HttpUtility]::UrlDecode($EVENTLOG)).ToLower().Replace("`"","")
$PCAP = ([System.Web.HttpUtility]::UrlDecode($PCAP)).ToLower().Replace("`"","")
$RANSOMWARE = ([System.Web.HttpUtility]::UrlDecode($RANSOMWARE)).ToLower().Replace("`"","")

$StartTime = Get-Date
$LogDate = $StartTime.ToString('yyyMMdd_HHmmss')
$Name = $env:computername
$FQDN = $env:userdnsdomain
$OS64bit = [Environment]::Is64BitOperatingSystem
$ScriptDir = $PSScriptRoot
$DFIRLogDir = "C:\DFIRLog\${LogDate}_${Name}"
$IRDir = "C:\DFIRLog"
$MFT = 'yes'
$LogFile =  "$DFIRLogDir\Log\${LogDate}_${Name}.log"
$ScriptVersion = 2.1

$Logo = @"
    ____  _______________________    __       __________  ____  _______   _______ _______________
   / __ \/  _/ ____/  _/_  __/   |  / /      / ____/ __ \/ __ \/ ____/ | / / ___//  _/ ____/ ___/
  / / / // // / __ / /  / / / /| | / /      / /_  / / / / /_/ / __/ /  |/ /\__ \ / // /    \__ \
 / /_/ // // /_/ // /  / / / ___ |/ /___   / __/ / /_/ / _, _/ /___/ /|  /___/ // // /___ ___/ /
/_____/___/\____/___/ /_/ /_/  |_/_____/  /_/    \____/_/ |_/_____/_/ |_//____/___/\____//____/

    _____   ________________  _______   ________   ____  ___________ ____  ____  _   _______ ______
   /  _/ | / / ____/  _/ __ \/ ____/ | / /_  __/  / __ \/ ____/ ___// __ \/ __ \/ | / / ___// ____/
   / //  |/ / /    / // / / / __/ /  |/ / / /    / /_/ / __/  \__ \/ /_/ / / / /  |/ /\__ \/ __/   
 _/ // /|  / /____/ // /_/ / /___/ /|  / / /    / _, _/ /___ ___/ / ____/ /_/ / /|  /___/ / /___   
/___/_/ |_/\____/___/_____/_____/_/ |_/ /_/    /_/ |_/_____//____/_/    \____/_/ |_//____/_____/   

            __    ____  ______   __________  __    __    ______________________  ____
           / /   / __ \/ ____/  / ____/ __ \/ /   / /   / ____/ ____/_  __/ __ \/ __ \
          / /   / / / / / __   / /   / / / / /   / /   / __/ / /     / / / / / / /_/ /
         / /___/ /_/ / /_/ /  / /___/ /_/ / /___/ /___/ /___/ /___  / / / /_/ / _, _/
        /_____/\____/\____/   \____/\____/_____/_____/_____/\____/ /_/  \____/_/ |_|  


                                                          Script Version $ScriptVersion
                                                          POC: Elite Grassh0pp3r


"@

Write-Host $Logo -ForegroundColor Green
Write-Host "Operator: $OPERATOR" -ForegroundColor Cyan
Write-Host "Case Number: $CASE" -ForegroundColor Cyan

Function Log-Start{  
    [CmdletBinding()]
    Param ([Parameter(Mandatory=$true)][string]$LogPath, [Parameter(Mandatory=$true)][string]$ScriptVersion)
    Process{
        Add-Content -Path $LogPath -Value "***************************************************************************************************"
        Add-Content -Path $LogPath -Value "Running DFIR LOG COLLECTOR."
        Add-Content -Path $LogPath -Value "Script executed by $OPERATOR."
        Add-Content -Path $LogPath -Value "Case Number: $CASE."
        Add-Content -Path $LogPath -Value "Started processing at $([DateTime]::Now)."
        Add-Content -Path $LogPath -Value "Running script version [$ScriptVersion]."
        Add-Content -Path $LogPath -Value "---------------------------------------------------------------------------------------------------"
        Add-Content -Path $LogPath -Value ""
    }
}

Function Log-Write{
    [CmdletBinding()]
    Param ([Parameter(Mandatory=$true)][string]$LogPath, [Parameter(Mandatory=$true)][string]$LineValue)
    Process{
        $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
        $Line = "$Stamp $LineValue"
        Add-Content -Path $LogPath -Value $Line
    }
}

Function Log-Finish{
    [CmdletBinding()]
    Param ([Parameter(Mandatory=$true)][string]$LogPath)
    Add-Content -Path $LogPath -Value ""
    Add-Content -Path $LogPath -Value "***************************************************************************************************"
    Add-Content -Path $LogPath -Value "Finished processing at $([DateTime]::Now)."
    Add-Content -Path $LogPath -Value "***************************************************************************************************"
    Add-Content -Path $LogPath -Value "Total processing time $(((Get-Date)-$StartTime).totalseconds) seconds."
    Add-Content -Path $LogPath -Value "***************************************************************************************************"
}

Function EncStr {
    param($string, $key)
    $xkey = [System.Text.Encoding]::UTF8.GetBytes($key)

    $byteString = [System.Text.Encoding]::UTF8.GetBytes($string)
    $encData = $(for ($i = 0; $i -lt $byteString.length; ) {
        for ($j = 0; $j -lt $xkey.length; $j++) {
            $byteString[$i] -bxor $xkey[$j]
            $i++
            if ($i -ge $byteString.Length) {
                $j = $xkey.length
            }
        }
    })

    $encData = [System.Convert]::ToBase64String($encData)
    return $encData
}

$7ZPASSWORD = EncStr "${Name}" "HidEnS33k"

If (!(Test-Path $DFIRLogDir)){
    New-Item "$DFIRLogDir" -ItemType Directory | Out-Null
    New-Item "$DFIRLogDir\Log" -ItemType Directory | Out-Null
}

Start-Process "C:\Windows\System32\attrib.exe" -ArgumentList "+S +R +H $IRDir" -Wait -WindowStyle Hidden

Log-Start -LogPath $LogFile -ScriptVersion "$ScriptVersion"
Log-Write -LogPath $LogFile -LineValue "PowerShell version: $($PSVersionTable.PSVersion)"
Write-host "PowerShell version: $($PSVersionTable.PSVersion)`n`n"

#Checks to see if you're running the script with administrator rights.
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")){
    Write-Host -ForegroundColor Red "ERROR: The DFIR Log Collector script was not executed with a user account that has ADMINISTRATOR rights on the system."
    Log-Write -LogPath $LogFile -LineValue "ERROR: The DFIR Log Collector script was not executed with a user account that has ADMINISTRATOR rights on the system."
    Log-Finish -LogPath $LogFile
    EXIT
}

###############################################################################
#region Base64 decode DFIRTOOLS and write ZIP file to current script directory#
###############################################################################

Write-Host -ForegroundColor Yellow "Decoding and writing ZIP file 'DFIR_LogCollector_Tools.zip' to current script directory '${DFIRLogDir}'."
Log-Write -LogPath $LogFile -LineValue "Decoding and writing ZIP file 'DFIR_LogCollector_Tools.zip' to current script directory '${DFIRLogDir}'."

#Base64 Encode string of DFIR_LogCollector_Tools.zip

#Base64 decode variable $DFIRTOOLS and write ZIP file to current script directory
$BINARY = [Convert]::FromBase64String($DFIRTOOLS)
Set-Content -Path "$IRDir\DFIR_LogCollector_Tools.zip" -Value $BINARY -Encoding Byte | Out-Null

Write-Host -ForegroundColor Green "COMPLETED: Decoded and wrote ZIP file 'DFIR_LogCollector_Tools.zip' to current script directory '${IRDir}'."
Log-Write -LogPath $LogFile -LineValue "COMPLETED: Decoded and wrote ZIP file 'DFIR_LogCollector_Tools.zip' to current script directory '${IRDir}'."

Start-Sleep -Seconds 5

#Checks if the ZIP file 'DFIR_LogCollector_Tools.zip' exists in the current script directory
If (!(Test-Path "$IRDir\DFIR_LogCollector_Tools.zip")){
    Write-Host -ForegroundColor Red "ERROR: The required tools ZIP file 'DFIR_LogCollector_Tools.zip' does not exists and could not be decoded and extracted from script."
    Log-Write -LogPath $LogFile -LineValue "ERROR:  The required tools ZIP file 'DFIR_LogCollector_Tools.zip' does not exists and could not be decoded and extracted from script."
    Log-Finish -LogPath $LogFile
    EXIT
}

#Extract the necessary files used by the to C:\DFIRLog\Tools
Write-Host -ForegroundColor Yellow "Extracting additional required tools from file DFIR_LogCollector_Tools.zip."
Log-Write -LogPath $LogFile -LineValue "Extracting additional required tools from file DFIR_LogCollector_Tools.zip to C:\DFIRLog\Tools."
Expand-Archive -Path "$IRDir\DFIR_LogCollector_Tools.zip" -DestinationPath "C:\DFIRLog\" -Force
Log-Write -LogPath $LogFile -LineValue "COMPLETED: Extracted necessary files to 'C:\DFIRLog\Tools'."
Write-Host -ForegroundColor Green "COMPLETED: Extracted necessary files to 'C:\DFIRLog\Tools'."

Start-Sleep -Seconds 5

#endregion

Write-Host -ForegroundColor Yellow "Setting Power Configurations to ensure computer does not sleep."
Log-Write -LogPath $LogFile -LineValue "Setting Power Configurations to ensure computer does not sleep."

# Make sure the computer does not go back to sleep
powercfg /x standby-timeout-ac 0 > $null
powercfg /x monitor-timeout-ac 0 > $null
Log-Write -LogPath $LogFile -LineValue "COMPLETED: Power Configurations set."

Write-Host -ForegroundColor Green "COMPLETED: Power Configurations set."

###############################################################################
#region Network Information and Settings                                      #
###############################################################################

If (!(Test-Path "$DFIRLogDir\Collection\System")){
    New-Item "$DFIRLogDir\Collection\System" -ItemType Directory | Out-Null
    Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\System"
    Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\System"
}

Write-Host -ForegroundColor Yellow "Gathering Network Information and Settings"
Log-Write -LogPath $LogFile -LineValue "Gathering Network Information and Settings"

Write-Host -ForegroundColor Yellow "Collecting DNS Cache Information."
Log-Write -LogPath $LogFile -LineValue "Collecting DNS Cache Information."
#Gets DNS cache
$DNSCache = Get-DnsClientCache | select Entry,Name, Status, TimeToLive, Data
$DNSCache | Sort-Object Name | Export-Csv "$DFIRLogDir\Collection\System\DNSCache.csv" -NoTypeInformation

Write-Host -ForegroundColor Yellow "Collecting Network Adapters Information."
Log-Write -LogPath $LogFile -LineValue "Collecting Network Adapters Information."
#Gets Network Adapter Informations
$NetworkAdapter = Get-WmiObject -class Win32_NetworkAdapter | Select-Object -Property AdapterType,ServiceName,ProductName,Description,Manufacturer,MACAddress,Availability,NetconnectionStatus,NetEnabled,PhysicalAdapter
$NetworkAdapter | Export-Csv "$DFIRLogDir\Collection\System\All_Network_Adapters.csv" -NoTypeInformation

#Gets Network Adapter Information only
$NetAdapter = Get-NetAdapter | select Name, InterfaceDescription, Status, MacAddress, LinkSpeed
$NetAdapter | Sort-Object Name| Export-Csv "$DFIRLogDir\Collection\System\Network_Adapter_Info.csv" -NoTypeInformation

Write-Host -ForegroundColor Yellow "Collecting IP Address Configuration Information."
Log-Write -LogPath $LogFile -LineValue "Collecting IP Address Configuration Information."
#Gets All Network IP address configuration
$IPConfiguration = Get-WmiObject Win32_NetworkAdapterConfiguration |  select Description, @{Name='IpAddress';Expression={$_.IpAddress -join '; '}}, @{Name='IpSubnet';Expression={$_.IpSubnet -join '; '}}, MACAddress, @{Name='DefaultIPGateway';Expression={$_.DefaultIPGateway -join '; '}}, DNSDomain, @{Name='DNSDomainSuffixSearchOrder';Expression={$_.DNSDomainSuffixSearchOrder -join '; '}}, DNSHostName, DHCPEnabled, ServiceName, WINSEnableLMHostsLookup, IPEnabled
$IPConfiguration | Export-Csv "$DFIRLogDir\Collection\System\All_IP_Configs.csv" -NoTypeInformation

Write-Host -ForegroundColor Yellow "Collecting Network IP Address Information."
Log-Write -LogPath $LogFile -LineValue "Collecting Network IP Address Information."
#Gets Adapter and IP address information only
$NetIPAddress = Get-NetIPaddress | select InterfaceAlias, IPaddress
$NetIPAddress | Export-Csv "$DFIRLogDir\Collection\System\Network_Adapter_and_IP_Addresses_Only.csv" -NoTypeInformation

Write-Host -ForegroundColor Yellow "Collecting Network Connection Profiles Information."
Log-Write -LogPath $LogFile -LineValue "Collecting Network Connection Profiles Information."
#Gets Network Profiles
$NetConnectProfile = Get-NetConnectionProfile | select Name, InterfaceAlias, NetworkCategory, IPV4Connectivity, IPv6Connectivity
$NetConnectProfile | Sort-Object Name| Export-Csv "$DFIRLogDir\Collection\System\Network_Connection_Profile.csv" -NoTypeInformation

Write-Host -ForegroundColor Yellow "Collecting Network Neighbor Information (ARP) Information."
Log-Write -LogPath $LogFile -LineValue "Collecting Network Neighbor Information (ARP) Information."
#Gets Network Neighbor Information (ARP)
$NetNeighbor = Get-NetNeighbor | select InterfaceAlias, IPAddress, LinkLayerAddress, State, AddressFamily
$NetNeighbor | Sort-Object InterfaceAlias| Export-Csv "$DFIRLogDir\Collection\System\Network_Neighbors_ARP.csv" -NoTypeInformation

Write-Host -ForegroundColor Yellow "Collecting All Current TCP Connections Information."
Log-Write -LogPath $LogFile -LineValue "Collecting All Current TCP Connections Information."
#Gets All Current TCP Connections
$NetTCPConnect = Get-NetTCPConnection | Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess, @{Name="Process";Expression={(Get-Process -Id $_.OwningProcess).ProcessName}}
$NetTCPConnect | Sort-Object Process | Export-Csv "$DFIRLogDir\Collection\System\All_Current_TCP_Connections.csv" -NoTypeInformation

Write-Host -ForegroundColor Yellow "Collecting WIFI Information."
Log-Write -LogPath $LogFile -LineValue "Collecting WIFI Information."
#Gets WIFI Names and Passwords
$WlanPasswords = netsh.exe wlan show profiles | Select-String "\:(.+)$" | %{$wlanname=$_.Matches.Groups[1].Value.Trim(); $_} | %{(netsh wlan show profile name="$wlanname" key=clear)}  | Select-String 'Key Content\W+\:(.+)$' | %{$wlanpass=$_.Matches.Groups[1].Value.Trim(); $_} | %{[PSCustomObject]@{ PROFILE_NAME=$wlanname;PASSWORD=$wlanpass }}
$WlanPasswords | Export-Csv "$DFIRLogDir\Collection\System\WLAN_Passwords.csv" -NoTypeInformation

Write-Host -ForegroundColor Yellow "Collecting Windows Firewall Information."
Log-Write -LogPath $LogFile -LineValue "Collecting Windows Firewall Information."
#Get Firewall Information.
$FirewallRule = Get-NetFirewallRule | Select-Object Profile, Enabled, Name, DisplayName, Description, Direction, Action, EdgeTraversalPolicy, PolicyStoreSource, PolicyStoreSourceType, Owner, EnforcementStatus
$FirewallRule | Sort-Object DisplayName | Export-Csv "$DFIRLogDir\Collection\System\Windows_Firewall_Information.csv" -NoTypeInformation

Write-Host -ForegroundColor Yellow "Collecting SMB Sessions Information."
Log-Write -LogPath $LogFile -LineValue "Collecting SMB Sessions Information."
#Gets Active Samba Sessions
$SMBSessions = Get-SMBSession -ErrorAction silentlycontinue
$SMBSessions | Export-Csv "$DFIRLogDir\Collection\System\Current_SMB_Sessions.csv" -NoTypeInformation

Write-Host -ForegroundColor Yellow "Collecting SMB Shares Information."
Log-Write -LogPath $LogFile -LineValue "Collecting SMB Shares Information."
#Gets Active Samba shares
$SMBShares = Get-SMBShare | select Name, Description, Path, Volume, ShareState
$SMBShares | Sort-Object Name | Export-Csv "$DFIRLogDir\Collection\System\Current_SMB_Shares.csv" -NoTypeInformation

Write-Host -ForegroundColor Yellow "Collecting IP Routes to Non-Local Destinations Information."
Log-Write -LogPath $LogFile -LineValue "Collecting IP Routes to Non-Local Destinations Information."
#Gets IP Routes to Non-Local Destinations
$NetHops = Get-NetRoute | Where-Object -FilterScript { $_.NextHop -Ne "::" } | Where-Object -FilterScript { $_.NextHop -Ne "0.0.0.0" } | Where-Object -FilterScript { ($_.NextHop.SubString(0,6) -Ne "fe80::") }
$NetHops | Export-Csv "$DFIRLogDir\Collection\System\Network_Route.csv" -NoTypeInformation

Write-Host -ForegroundColor Yellow "Collecting Network Adapters that have IP Routes to Non-Local Destinations Information."
Log-Write -LogPath $LogFile -LineValue "Collecting Network Adapters that have IP Routes to Non-Local Destinations Information."
#Gets Network Adapters that have IP Routes to Non-Local Destinations
$AdaptHops = Get-NetRoute | Where-Object -FilterScript {$_.NextHop -Ne "::"} | Where-Object -FilterScript { $_.NextHop -Ne "0.0.0.0" } | Where-Object -FilterScript { ($_.NextHop.SubString(0,6) -Ne "fe80::") } | Get-NetAdapter
$AdaptHops | Export-Csv "$DFIRLogDir\Collection\System\Network_IP_Routes_non-local_dst.csv" -NoTypeInformation

Write-Host -ForegroundColor Yellow "Collecting IP Routes that have an Infinite Valid Lifetime Information."
Log-Write -LogPath $LogFile -LineValue "Collecting IP Routes that have an Infinite Valid Lifetime Information."
#Gets IP Routes that have an Infinite Valid Lifetime
$IpHops = Get-NetRoute | Where-Object -FilterScript { $_.ValidLifetime -Eq ([TimeSpan]::MaxValue) }
$IpHops | Export-Csv "$DFIRLogDir\Collection\System\Network_IP_Routes_infinite_lifetime.csv" -NoTypeInformation

$SectionCompletion = (Get-Date)
Write-Host -ForegroundColor Green "COMPLETED: Collected all the necessary Network Information and Settings."
Log-Write -LogPath $LogFile -LineValue "COMPLETED: Collected all the necessary Network Information and Settings."
Log-Write -LogPath $LogFile -LineValue "Total processing time $(($SectionCompletion-$StartTime).totalseconds) seconds."
Add-Content -Path $LogFile -Value "---------------------------------------------------------------------------------------------------"

###############################################################################
#region Users Account and Groups Information                                  #
###############################################################################

If (!(Test-Path "$DFIRLogDir\Collection\User-DATA")){
    New-Item "$DFIRLogDir\Collection\User-DATA" -ItemType Directory | Out-Null
    Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\User-DATA"
    Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\User-DATA"
}

Write-Host -ForegroundColor Yellow "Gathering Users Account and Groups Information."
Log-Write -LogPath $LogFile -LineValue "Gathering Users Account and Groups Information."

$LogonType_map = @{
    2 = 'Interactive'
    3 = 'Network'
    4 = 'Batch'
    5 = 'Service'
    6 = 'Proxy'
    7 = 'Unlock'
    8 = 'NetworkCleartext'
    9 = 'NewCredentials'
    10 = 'RemoteInteractive'
    11 = 'CachedInteractive'
    12 = 'CachedRemoteInteractive'
    13 = 'CachedUnlock'
}

Write-Host -ForegroundColor Yellow "Collecting Local Users Account Information."
Log-Write -LogPath $LogFile -LineValue "Collecting Local Users Account Information."
#Gets Local Users Account Information
$useraccounts = Get-LocalUser | Select-Object -Property Name, Description, PasswordLastSet, PasswordExpires, LastLogon, PasswordRequired, SID, PrincipalSource
$useraccounts | Sort-Object Name | Export-Csv "$DFIRLogDir\Collection\User-DATA\All_Local_User_Accounts.csv" -NoTypeInformation

Write-Host -ForegroundColor Yellow "Collecting All Logon Sessions Information."
Log-Write -LogPath $LogFile -LineValue "Collecting All Logon Sessions Information."
#Gets All Logon Sessions
$logonsession = Get-WmiObject -Class Win32_LogonSession | Select-Object -Property LogonID, @{Name='Logon Type';Expression={$LogonType_map[[int]$_.LogonType]}}, @{Name='Start Time';Expression={$_.ConvertToDateTime($_.starttime)}}
$logonsession | Sort-Object LogonID | Export-Csv "$DFIRLogDir\Collection\User-DATA\All_logon_sessions.csv" -NoTypeInformation

Write-Host -ForegroundColor Yellow "Collecting Currently Logged on Users Information."
Log-Write -LogPath $LogFile -LineValue "Collecting Currently Logged on Users Information."
#Gets Currently Logged on Users
$logonsession2 = cmd.exe /c query user
$logonsession2 |  Out-file "$DFIRLogDir\Collection\User-DATA\All_Current_Logged_on_Users.txt"

Write-Host -ForegroundColor Yellow "Collecting Users Profile Information."
Log-Write -LogPath $LogFile -LineValue "Collecting Users Profile Information."
#Gets Users Profile Information
$userprofiles = Get-WmiObject -Class Win32_UserProfile | Select-Object -Property LocalPath, SID, @{Name='Last Used';Expression={$_.ConvertToDateTime($_.lastusetime)}}
$userprofiles | Sort-Object LocalPath | Export-Csv "$DFIRLogDir\Collection\User-DATA\User_Profile_Info.csv" -NoTypeInformation

Write-Host -ForegroundColor Yellow "Collecting All Users that are in the Local Administrators Information."
Log-Write -LogPath $LogFile -LineValue "Collecting All Users that are in the Local Administrators Information."
#Gets All Users that are in the Local Administrators
$localadministrators = Get-LocalGroupMember -Group "Administrators" | Select-Object -Property Name, SID, PrincipalSource, ObjectClass
$localadministrators | Sort-Object Name | Export-Csv "$DFIRLogDir\Collection\User-DATA\Local_Administrators_group_memberships.csv" -NoTypeInformation

Write-Host -ForegroundColor Yellow "Collecting All Local Groups Information."
Log-Write -LogPath $LogFile -LineValue "Collecting All Local Groups Information."
#Gets a List of All Local Groups
$LocalGroup = Get-LocalGroup | Select-Object -Property Name, Description, SID, PrincipalSource, ObjectClass
$LocalGroup | Sort-Object Name | Export-Csv "$DFIRLogDir\Collection\User-DATA\Local_Administrators_group_memberships.csv" -NoTypeInformation

$SectionCompletion2 = (Get-Date)
Write-Host -ForegroundColor Green "COMPLETED: Collected User Accounts and Groups Information."
Log-Write -LogPath $LogFile -LineValue "COMPLETED: Collected User Accounts and Groups Information."
Log-Write -LogPath $LogFile -LineValue "Total processing time $(($SectionCompletion2-$SectionCompletion).totalseconds) seconds."
$SectionCompletion = $SectionCompletion2
Add-Content -Path $LogFile -Value "---------------------------------------------------------------------------------------------------"

#endregion

###############################################################################
#region Installed Programs                                                    #
###############################################################################

Write-Host -ForegroundColor Yellow "Gathering a List of Installed Programs."
Log-Write -LogPath $LogFile -LineValue "Gathering a List of Installed Programs."

$InstProgs = Get-CimInstance -ClassName win32_product | Select-Object Name, Version, Vendor, InstallDate, InstallSource, PackageName, LocalPackage
$InstProgs | Sort-Object Name | Export-Csv "$DFIRLogDir\Collection\System\Installed_Programs.csv" -NoTypeInformation
Log-Write -LogPath $LogFile -LineValue "Collected a list of installed programs."

$SectionCompletion2 = (Get-Date)
Write-Host -ForegroundColor Green "COMPLETED: Collected a List of Installed Programs."
Log-Write -LogPath $LogFile -LineValue "COMPLETED: Collected a List of Installed Programs."
Log-Write -LogPath $LogFile -LineValue "Total processing time $(($SectionCompletion2-$SectionCompletion).totalseconds) seconds."
$SectionCompletion = $SectionCompletion2
Add-Content -Path $LogFile -Value "---------------------------------------------------------------------------------------------------"

Start-Sleep -Seconds 5

#endregion

###############################################################################
#region Copying Log Files (evetx, WER, etc)                                   #
###############################################################################

If (!(Test-Path "$DFIRLogDir\Collection\LogFiles")){
    New-Item "$DFIRLogDir\Collection\LogFiles" -ItemType Directory | Out-Null
    Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\LogFiles"
    Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\LogFiles"
}

Write-Host -ForegroundColor Yellow "Collecting Multiple Log Files (Event Logs, WDI StartupInfo, other misc. log files (%WINDIR%))."
Log-Write -LogPath $LogFile -LineValue "Collecting Multiple Log Files (Event Logs, WDI StartupInfo, other misc. log files (%WINDIR%))."

If (!(Test-Path "$DFIRLogDir\Collection\LogFiles\winevt\Logs")){
    New-Item "$DFIRLogDir\Collection\LogFiles\winevt\Logs" -ItemType Directory | Out-Null
    ROBOCOPY "C:\Windows\System32\winevt\Logs" "$DFIRLogDir\Collection\LogFiles\winevt\Logs" /MIR /W:2 /R:1 > $null
    If(!(Test-Path "$DFIRLogDir\Collection\LogFiles\winevt\logs\Application.evtx")){
        Copy-Item -Path "C:\Windows\System32\winevt\logs\*" -Destination "$DFIRLogDir\Collection\LogFiles\winevt\Logs\" -Recurse -ErrorAction SilentlyContinue -Force | Out-Null
    }
}

If (!(Test-Path "$DFIRLogDir\Collection\LogFiles\WDI-StartUP")){
    New-Item "$DFIRLogDir\Collection\LogFiles\WDI-StartUP" -ItemType Directory | Out-Null
    ROBOCOPY "C:\Windows\System32\WDI\LogFiles\StartupInfo\" "$DFIRLogDir\Collection\LogFiles\WDI-StartUP" /S /W:2 /R:1 > $null
}

If (!(Test-Path "$DFIRLogDir\Collection\LogFiles\Logs")){
    New-Item "$DFIRLogDir\Collection\LogFiles\Logs" -ItemType Directory | Out-Null
    ROBOCOPY "$env:windir" "$DFIRLogDir\Collection\LogFiles\Logs" *.log *.trc /S /W:10 /R:2 /XD SoftwareDistribution SysWOW64  /W:2 /R:1 > $null
}

Start-Process "C:\Windows\System32\attrib.exe" -ArgumentList "-S -H -I -R -A /S /D $DFIRLogDir\Collection\LogFiles\*.*" -Wait -WindowStyle Hidden
Start-Process "C:\Windows\System32\attrib.exe" -ArgumentList "-S -H -I -R -A /S /D $DFIRLogDir\Collection\LogFiles\*" -Wait -WindowStyle Hidden

$SectionCompletion2 = (Get-Date)
Write-Host -ForegroundColor Green "COMPLETED: Collected Multiple Log Files (Event Logs, WDI StartupInfo, other MISC. log files (%WINDIR%))."
Log-Write -LogPath $LogFile -LineValue "COMPLETED: Collected Multiple Log Files (Event Logs, WDI StartupInfo, other MISC. log files (%WINDIR%))."
Log-Write -LogPath $LogFile -LineValue "Total processing time $(($SectionCompletion2-$SectionCompletion).totalseconds) seconds."
$SectionCompletion = $SectionCompletion2
Add-Content -Path $LogFile -Value "---------------------------------------------------------------------------------------------------"

Start-Sleep -Seconds 5

#endregion

###############################################################################
#region Collecting RemoteDesktop (LogMeIn)                                    #
###############################################################################

If ((Test-Path "$env:allusersprofile\LogMeIn") -and !(Test-Path "$DFIRLogDir\Collection\LogMeIn")){
    New-Item "$DFIRLogDir\Collection\LogMeIn" -ItemType Directory | Out-Null
    Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\LogMeIn"
    Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\LogFiles"
    Write-Host -ForegroundColor Yellow "Collecting LogMeIn Remote Desktop Information."
    Log-Write -LogPath $LogFile -LineValue "Collecting LogMeIn Remote Desktop Information."
    ROBOCOPY "$env:ALLUSERSPROFILE\LogMeIn" "$DFIRLogDir\Collection\LogMeIn" /MIR /W:2 /R:1 > $null
    Log-Write -LogPath $LogFile -LineValue "COMPLETED: Collected LogMeIn Remote Desktop Information."
    Write-Host -ForegroundColor Green "COMPLETED: Collected LogMeIn Remote Desktop Information."
}Else {
    Write-Host -ForegroundColor Green "The LogMeIn Remote Desktop folder was not found and nothing was collected."
    Log-Write -LogPath $LogFile -LineValue "COMPLETED: The LogMeIn Remote Desktop folder was not found and nothing was collected."
}

$SectionCompletion2 = (Get-Date)
Log-Write -LogPath $LogFile -LineValue "Total processing time $(($SectionCompletion2-$SectionCompletion).totalseconds) seconds."
$SectionCompletion = $SectionCompletion2
Add-Content -Path $LogFile -Value "---------------------------------------------------------------------------------------------------"

#endregion

###############################################################################
#region AntiVirus Logs and Quaratine Files                                    #
###############################################################################

If (!(Test-Path "$DFIRLogDir\Collection\Antivirus")){
    New-Item "$DFIRLogDir\Collection\Antivirus" -ItemType Directory | Out-Null
    Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\Antivirus"
    Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\Antivirus"
}

Write-Host -ForegroundColor Yellow "Gathering AntiVirus Logs and Quaratine Files."
Log-Write -LogPath $LogFile -LineValue "Gathering AntiVirus Logs and Quaratine Files."

# AVAST
If ((Test-Path "$env:allusersprofile\AVAST") -and !(Test-Path "$DFIRLogDir\Collection\Antivirus\AVAST")){
    Write-Host -ForegroundColor Yellow "Collecting AVAST Files."
    Log-Write -LogPath $LogFile -LineValue "Collecting AVAST Files."
    New-Item "$DFIRLogDir\Collection\Antivirus\AVAST" -ItemType Directory | Out-Null
    ROBOCOPY "$env:allusersprofile\Avast Software\Avast\Log\" "$DFIRLogDir\Collection\Antivirus\AVAST\Log\" /MIR /W:2 /R:1 > $null
    ROBOCOPY "$env:allusersprofile\Avast Software\Avast\Chest\" "$DFIRLogDir\Collection\Antivirus\AVAST\Chest\" /MIR /W:2 /R:1 > $null
}

# Avira
If ((Test-Path "$env:allusersprofile\Avira") -and !(Test-Path "$DFIRLogDir\Collection\Antivirus\Avira")){
    Write-Host -ForegroundColor Yellow "Collecting AVIRA Files."
    Log-Write -LogPath $LogFile -LineValue "Collecting AVIRA Files."
    New-Item "$DFIRLogDir\Collection\Antivirus\Avira" -ItemType Directory | Out-Null
    ROBOCOPY "$env:allusersprofile\Avira\Antivirus\LOGFILES\" "$DFIRLogDir\Collection\Antivirus\Avira\Antivirus\LOGFILES\" /MIR /W:2 /R:1 > $null
}

# Bitdefender
If ((Test-Path "$env:allusersprofile\Bitdefender") -and !(Test-Path "$DFIRLogDir\Collection\Antivirus\Bitdefender")){
    Write-Host -ForegroundColor Yellow "Collecting Bitdefender Files."
    Log-Write -LogPath $LogFile -LineValue "Collecting Bitdefender Files."
    New-Item "$DFIRLogDir\Collection\Antivirus\Bitdefender" -ItemType Directory | Out-Null
    ROBOCOPY "$env:allusersprofile\Bitdefender\Endpoint Security\Logs\" "$DFIRLogDir\Collection\Antivirus\Bitdefender\Endpoint Security\Logs\" /MIR /W:2 /R:1 > $null
    ROBOCOPY "$env:allusersprofile\Bitdefender\Desktop\Profiles\Logs\" "$DFIRLogDir\Collection\Antivirus\Bitdefender\Desktop\Profiles\Logs\" /MIR /W:2 /R:1 > $null
    ROBOCOPY "C:\Program Files\Bitdefender\ " "$DFIRLogDir\Collection\Antivirus\Bitdefender" /MIR /W:2 /R:1 > $null
}

# Cylance
If ((Test-Path "$env:allusersprofile\Cylance") -and !(Test-Path "$DFIRLogDir\Collection\Antivirus\Cylance")){
    Write-Host -ForegroundColor Yellow "Collecting Cylance Files."
    Log-Write -LogPath $LogFile -LineValue "Collecting Cylance Files."
    New-Item "$DFIRLogDir\Collection\Antivirus\Cylance" -ItemType Directory | Out-Null
    ROBOCOPY "$env:allusersprofile\Cylance" "$DFIRLogDir\Collection\Antivirus\Cylance" /MIR /W:2 /R:1 > $null
}

# F-Secure
If ((Test-Path "$env:allusersprofile\F-Secure") -and !(Test-Path "$DFIRLogDir\Collection\Antivirus\F-Secure")){
    Write-Host -ForegroundColor Yellow "Collecting F-Secure Files."
    Log-Write -LogPath $LogFile -LineValue "Collecting F-Secure Files."
    New-Item "$DFIRLogDir\Collection\Antivirus\F-Secure" -ItemType Directory | Out-Null
    ROBOCOPY "$env:allusersprofile\F-Secure\Log\ " "$DFIRLogDir\Collection\Antivirus\F-Secure" /MIR /W:2 /R:1 > $null
    ROBOCOPY "$env:allusersprofile\F-Secure\Antivirus\ScheduledScanReports\" "$DFIRLogDir\Collection\Antivirus\F-Secure\Antivirus\ScheduledScanReports\" /MIR /W:2 /R:1 > $null
}

# Malwarebytes
If ((Test-Path "$env:allusersprofile\Malwarebytes") -and !(Test-Path "$DFIRLogDir\Collection\Antivirus\MalwareBytes")){
    Write-Host -ForegroundColor Yellow "Collecting Malwarebytes Files."
    Log-Write -LogPath $LogFile -LineValue "Collecting Malwarebytes Files."
    New-Item "$DFIRLogDir\Collection\Antivirus\MalwareBytes" -ItemType Directory | Out-Null
    ROBOCOPY "$env:allusersprofile\Malwarebytes" "$DFIRLogDir\Collection\Antivirus\MalwareBytes" /MIR /W:2 /R:1 > $null
}

# McAfee
If ((Test-Path "$env:allusersprofile\McAfee") -and !(Test-Path "$DFIRLogDir\Collection\Antivirus\McAfee")){
    Write-Host -ForegroundColor Yellow "Collecting McAfee Files."
    Log-Write -LogPath $LogFile -LineValue "Collecting McAfee Files."
    New-Item "$DFIRLogDir\Collection\Antivirus\McAfee" -ItemType Directory| Out-Null
    ROBOCOPY "$env:allusersprofile\McAfee\Endpoint Security" "$DFIRLogDir\Collection\Antivirus\McAfee\Endpoint Security" /MIR /W:2 /R:1 > $null
    ROBOCOPY "$env:allusersprofile\McAfee\DesktopProtection" "$DFIRLogDir\Collection\Antivirus\McAfee\DesktopProtection" /MIR /W:2 /R:1 > $null
    ROBOCOPY "$env:allusersprofile\McAfee\VirusScan\" "$DFIRLogDir\Collection\Antivirus\McAfee\VirusScan\" /MIR /W:2 /R:1 > $null
    ROBOCOPY "C:\Quarantine" "$DFIRLogDir\Collection\Antivirus\McAfee\Quarantine" /MIR /W:2 /R:1 > $null
}

# Microsoft Windows Antimalware
If ((Test-Path "$env:allusersprofile\Microsoft\Microsoft Antimalware") -and !(Test-Path "$DFIRLogDir\Collection\Antivirus\Microsoft_Antimalware")){
    Write-Host -ForegroundColor Yellow "Collecting Microsoft Windows Antimalware Files."
    Log-Write -LogPath $LogFile -LineValue "Collecting Microsoft Windows Antimalware Files."
    New-Item "$DFIRLogDir\Collection\Antivirus\Microsoft_Antimalware" -ItemType Directory | Out-Null
    ROBOCOPY "$env:allusersprofile\Microsoft\Microsoft Antimalware\Support\" "$DFIRLogDir\Collection\Antivirus\Microsoft_Antimalware\Support" /MIR /W:2 /R:1 > $null
}

# Microsoft Windows Defender
If ((Test-Path "$env:allusersprofile\Microsoft\Windows Defender") -and !(Test-Path "$DFIRLogDir\Collection\Antivirus\Microsoft_Defender")){
    Write-Host -ForegroundColor Yellow "Collecting Microsoft Windows Defender Files."
    Log-Write -LogPath $LogFile -LineValue "Collecting Microsoft Windows Defender Files."
    New-Item "$DFIRLogDir\Collection\Antivirus\Microsoft_Defender" -ItemType Directory | Out-Null
    ROBOCOPY "$env:allusersprofile\Microsoft\Windows Defender\Support" "$DFIRLogDir\Collection\Antivirus\Microsoft_Defender\Support" /MIR /XD /W:2 /R:1 > $null
    ROBOCOPY "$env:allusersprofile\Microsoft\Windows Defender\Quaratine" "$DFIRLogDir\Collection\Antivirus\Microsoft_Defender\Quaratine" /MIR /XD /W:2 /R:1 > $null
}

# Trend Micro
If ((Test-Path "$env:allusersprofile\Symantec\Trend_Micro") -and !(Test-Path "$DFIRLogDir\Collection\Antivirus\Trend_Micro")){
    Write-Host -ForegroundColor Yellow "Collecting Trend Micro Files."
    Log-Write -LogPath $LogFile -LineValue "Collecting Trend Micro Files."
    New-Item "$DFIRLogDir\Collection\Antivirus\Trend_Micro" -ItemType Directory
    ROBOCOPY "C:\Program Files\Trend Micro\Security Agent\Report\" "$DFIRLogDir\Collection\Antivirus\Trend_Micro\Security Agent\Report\" /MIR /W:2 /R:1 > $null
    ROBOCOPY "C:\Program Files\Trend Micro\Security Agent\ConnLog\" "$DFIRLogDir\Collection\Antivirus\Trend_Micro\Security Agent\ConnLog\" /MIR /W:2 /R:1 > $null
    ROBOCOPY "$env:allusersprofile\Trend Micro" "$DFIRLogDir\Collection\Antivirus\Trend_Micro" /MIR /W:2 /R:1 > $null
}

# Sophos
If ((Test-Path "$env:allusersprofile\Sophos") -and !(Test-Path "$DFIRLogDir\Collection\Antivirus\Sophos")){
    Write-Host -ForegroundColor Yellow "Collecting Sophos Files."
    Log-Write -LogPath $LogFile -LineValue "Collecting Sophos Files."
    New-Item "$DFIRLogDir\Collection\Antivirus\Sophos" -ItemType Directory| Out-Null
    ROBOCOPY "$env:allusersprofile\Sophos" "$DFIRLogDir\Collection\Antivirus\Sophos" /MIR /W:2 /R:1 > $null
}

# Symantec Endpoint Protection (SEP)
If ((Test-Path "$env:allusersprofile\Symantec\Symantec Endpoint Protection") -and !(Test-Path "$DFIRLogDir\Collection\Antivirus\Symantec_Endpoint_Protection")){
    Write-Host -ForegroundColor Yellow "Collecting Symantec Endpoint Protection (SEP) Files."
    Log-Write -LogPath $LogFile -LineValue "Collecting Symantec Endpoint Protection (SEP) Files."
    New-Item "$DFIRLogDir\Collection\Antivirus\Symantec_Endpoint_Protection" -ItemType Directory
    ROBOCOPY "$env:allusersprofile\Symantec\Symantec Endpoint Protection" "$DFIRLogDir\Collection\Antivirus\Symantec_Endpoint_Protection" /MIR /W:2 /R:1 > $null
}

# Webroot
If ((Test-Path "$env:allusersprofile\WRDATA") -and !(Test-Path "$DFIRLogDir\Collection\Antivirus\WebRootData")){
    Write-Host -ForegroundColor Yellow "Collecting Webroot Files."
    Log-Write -LogPath $LogFile -LineValue "Collecting Webroot Files."
    New-Item "$DFIRLogDir\Collection\Antivirus\WebRootData" -ItemType Directory| Out-Null
    ROBOCOPY "$env:allusersprofile\WRDATA" "$DFIRLogDir\Collection\Antivirus\WebRootData" /MIR /W:2 /R:1 > $null
}

$SectionCompletion2 = (Get-Date)
Write-Host -ForegroundColor Green "COMPLETED: Collected AntiVirus Logs and Quaratine Files."
Log-Write -LogPath $LogFile -LineValue "COMPLETED: Collected AntiVirus Logs and Quaratine Files."
Log-Write -LogPath $LogFile -LineValue "Total processing time $(($SectionCompletion2-$SectionCompletion).totalseconds) seconds."
$SectionCompletion = $SectionCompletion2
Add-Content -Path $LogFile -Value "---------------------------------------------------------------------------------------------------"

#endregion

###############################################################################
#region Windows Update Log Files                                              #
###############################################################################

Write-Host -ForegroundColor Yellow "Gathering Windows Update Log Files"
Log-Write -LogPath $LogFile -LineValue "Gathering Windows Update Log Files"

If ((Test-Path "$env:allusersprofile\Microsoft\Network\downloader") -and !(Test-Path "$DFIRLogDir\Collection\Windows_Updates")){
    New-Item "$DFIRLogDir\Collection\Windows_Update" -ItemType Directory | Out-Null
    Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\Windows_Updates"
    Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\Windows_Updates"
    ROBOCOPY "$env:allusersprofile\Microsoft\Network\Downloader" "$DFIRLogDir\Collection\Windows_Update" /MIR /W:2 /R:1 > $null
}

$SectionCompletion2 = (Get-Date)
Write-Host -ForegroundColor Green "COMPLETED: Collected Windows Update Log Files."
Log-Write -LogPath $LogFile -LineValue "COMPLETED: Collected Windows Update Log Files."
Log-Write -LogPath $LogFile -LineValue "Total processing time $(($SectionCompletion2-$SectionCompletion).totalseconds) seconds."
$SectionCompletion = $SectionCompletion2
Add-Content -Path $LogFile -Value "---------------------------------------------------------------------------------------------------"

#endregion

###############################################################################
#region Search for Torrent Files                                              #
###############################################################################

If (!(Test-Path "$DFIRLogDir\Collection\Torrents")){
    New-Item "$DFIRLogDir\Collection\Torrents" -ItemType Directory | Out-Null
    Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\Torrents"
    Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\Torrents"
}


Write-Host -ForegroundColor Yellow "Searching for Torrent files."
Log-Write -LogPath $LogFile -LineValue "Searching for Torrent files."

$DRIVE_LETTERS = (Get-PSDrive -PSProvider FileSystem).Root
$TORRENTFILES = @()

ForEach ($DRIVE in $DRIVE_LETTERS){
    $VOLSIZE = (Get-Volume -DriveLetter $DRIVE[0] -ErrorAction SilentlyContinue).size
    If (($VOLSIZE) -and ($VOLSIZE -lt 2684354560000)){
        $TORRENTFILES += Get-ChildItem -Path "$DRIVE" -Filter *.torrent -File -Recurse -ErrorAction SilentlyContinue -Force | Select-Object FullName
    }Else {
        Write-Host -ForegroundColor Green "Did not search drive $DRIVE as the size of the disk is more than 2.5TB."
        Log-Write -LogPath $LogFile -LineValue "COMPLETED: Did not search drive $DRIVE as the size of the disk is more than 2.5TB."
    }
}

If ($TORRENTFILES){
    ForEach ($file in $TORRENTFILES){
        Copy-Item -Path "$($file.FullName)" -Destination "$DFIRLogDir\Collection\Torrents" -Force
    }
    $TORRENTFILES | Export-Csv "$DFIRLogDir\Collection\Torrents\List_of_All_Torrent_Files.csv" -NoTypeInformation
    Write-Host -ForegroundColor Green "COMPLETED: Searched for all Torrents files and copied for further analysis."
    Log-Write -LogPath $LogFile -LineValue "COMPLETED: Searched for all Torrents files and copied for further analysis."
}Else {
    Write-Host -ForegroundColor Green "COMPLETED: No Torrent files were found."
    Log-Write -LogPath $LogFile -LineValue "COMPLETED: No Torrent files were found."
}

$SectionCompletion2 = (Get-Date)
Log-Write -LogPath $LogFile -LineValue "Total processing time $(($SectionCompletion2-$SectionCompletion).totalseconds) seconds."
$SectionCompletion = $SectionCompletion2
Add-Content -Path $LogFile -Value "---------------------------------------------------------------------------------------------------"

#endregion

###############################################################################
#region Bitlocker Key                                                         #
###############################################################################

If (!(Test-Path "$DFIRLogDir\Collection\BITLOCKER")){
    New-Item "$DFIRLogDir\Collection\BITLOCKER" -ItemType Directory | Out-Null
    Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\BITLOCKER"
    Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\BITLOCKER"
}

Write-Host -ForegroundColor Yellow "Capturing Bitlocker Key."
Log-Write -LogPath $LogFile -LineValue "Capturing Bitlocker Key."
$DRIVE_LETTERS = (Get-PSDrive -PSProvider FileSystem).Root

ForEach ($DRIVE in $DRIVE_LETTERS){
    $VOLTYPE = (Get-Volume -DriveLetter $DRIVE[0] -ErrorAction SilentlyContinue).DriveType
    If (($VOLTYPE) -And ($VOLTYPE -eq "Fixed")){
        & "C:\Windows\System32\manage-bde.exe" -protectors -get "$($DRIVE[0]+$DRIVE[1])" | Out-File -FilePath "$DFIRLogDir\Collection\BITLOCKER\KEY_Drive_$($DRIVE[0]).txt"
    }
}

$SectionCompletion2 = (Get-Date)
Write-Host -ForegroundColor Green "COMPLETED: Captured Bitlocker Key."
Log-Write -LogPath $LogFile -LineValue "COMPLETED: Captured Bitlocker Key."
Log-Write -LogPath $LogFile -LineValue "Total processing time $(($SectionCompletion2-$SectionCompletion).totalseconds) seconds."
$SectionCompletion = $SectionCompletion2
Add-Content -Path $LogFile -Value "---------------------------------------------------------------------------------------------------"

#endregion

###############################################################################
#region Various Users and System Artifacts                                    #
###############################################################################

If (!(Test-Path "$DFIRLogDir\Collection\Registry-System")){
    New-Item "$DFIRLogDir\Collection\Registry-System" -ItemType Directory | Out-Null
    Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\Registry-System"
    Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\Registry-System"
}

Write-Host -ForegroundColor Yellow "Gathering various Users and System artifacts from Volume Shadow Copy (VSC)."
Log-Write -LogPath $LogFile -LineValue "Gathering various Users and System artifacts from Volume Shadow Copy (VSC)."

Log-Write -LogPath $LogFile -LineValue "Creating Volume Shadow Copy and mounting it as 'C:\VSC\'."
Write-Host -ForegroundColor Yellow "Creating Volume Shadow Copy and mounting it as 'C:\VSC\'."
$vss = (gwmi -List Win32_ShadowCopy).Create("c:\\", "ClientAccessible")
$vvs_id = $vss.GetPropertyValue("ShadowID")
$vss_instance = gwmi Win32_ShadowCopy | ? { $_.ID -eq $vvs_id }
$vss_do = $vss_instance.DeviceObject + "\"
cmd.exe /c mklink /d "C:\VSC" $vss_do > $null
Start-Sleep -Seconds 5
Write-Host -ForegroundColor Green "VSC created and mapped as 'C:\VSC\'"
Log-Write -LogPath $LogFile -LineValue "COMPLETED: VSC created and mapped as 'C:\VSC\'."

If ($USERNAME -eq "allusers"){
    [string[]]$allUsers = (Get-ChildItem -Path "C:\Users\").Name
}else {
    [string[]]$allUsers = (Get-ChildItem -Path "C:\Users\" -Filter "*${USERNAME}*").Name
}

ForEach ($user in $allUsers){
    If (Test-Path "C:\VSC") {
        New-item "$DFIRLogDir\Collection\USER-DATA\$user" -ItemType Directory | Out-Null
        Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\USER-DATA\$user"
        Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\USER-DATA\$user"

        Write-Host -ForegroundColor Yellow "Copying NTUSER.DAT, UsrClass.dat, and any file with the file extension '.DAT'."
        Log-Write -LogPath $LogFile -LineValue "Copying NTUSER.DAT, UsrClass.dat, and any file with the file extension '.DAT'."
        ROBOCOPY "C:\VSC\Users\$user" "$DFIRLogDir\Collection\USER-DATA\$user" *.DAT* /W:2 /R:1 > $null
        ROBOCOPY "C:\VSC\Users\$user\AppData\Local\Microsoft\Windows" "$DFIRLogDir\Collection\USER-DATA\$user" *.DAT* /W:2 /R:1 > $null
    }Else {
        Log-Write -LogPath $LogFile -LineValue "The volume shadow copy directory 'C:\VSC\' does not exist."
        Write-Host -ForegroundColor Yellow "The volume shadow copy directory 'C:\VSC\' does not exist."
    }

    #Chrome Browser Artifacts
    If (Test-Path "C:\Users\$user\AppData\Local\Google\Chrome\User Data\Default"){
        Write-Host -ForegroundColor Yellow "Copying Google Chrome Browser artifacts."
        Log-Write -LogPath $LogFile -LineValue "Copying Google Chrome Browser artifacts."
        New-item "$DFIRLogDir\Collection\USER-DATA\$user\Google_Chrome" -ItemType Directory | Out-Null
        New-item "$DFIRLogDir\Collection\USER-DATA\$user\Google_Chrome\Network" -ItemType Directory | Out-Null
        New-item "$DFIRLogDir\Collection\USER-DATA\$user\Google_Chrome\Cache" -ItemType Directory | Out-Null
        Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\USER-DATA\$user\Google_Chrome"
        Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\USER-DATA\$user\Google_Chrome"
        ROBOCOPY "C:\Users\$user\AppData\Local\Google\Chrome\User Data\Default" "$DFIRLogDir\Collection\USER-DATA\$user\Google_Chrome" /W:2 /R:1 > $null
        ROBOCOPY "C:\Users\$user\AppData\Local\Google\Chrome\User Data\Default\Network" "$DFIRLogDir\Collection\USER-DATA\$user\Google_Chrome\Network" /MIR /W:2 /R:1 > $null
        ROBOCOPY "C:\Users\$user\AppData\Local\Google\Chrome\User Data\Default\Cache" "$DFIRLogDir\Collection\USER-DATA\$user\Google_Chrome\Cache" /MIR /W:2 /R:1 > $null
    }

    #Microsoft Edge Browser Artifacts
    If (Test-Path "C:\Users\$user\AppData\Local\Microsoft\Edge\User Data\Default"){
        Write-Host -ForegroundColor Yellow "Copying Microsoft Edge Browser artifacts."
        Log-Write -LogPath $LogFile -LineValue "Copying Microsoft Edge Browser artifacts."
        New-item "$DFIRLogDir\Collection\USER-DATA\$user\Microsoft_Edge" -ItemType Directory | Out-Null
        New-item "$DFIRLogDir\Collection\USER-DATA\$user\Microsoft_Edge\Network" -ItemType Directory | Out-Null
        New-item "$DFIRLogDir\Collection\USER-DATA\$user\Microsoft_Edge\Cache" -ItemType Directory | Out-Null
        Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\USER-DATA\$user\Microsoft_Edge"
        Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\USER-DATA\$user\Microsoft_Edge"
        ROBOCOPY "C:\Users\$user\AppData\Local\Microsoft\Edge\User Data\Default" "$DFIRLogDir\Collection\USER-DATA\$user\Microsoft_Edge" /W:2 /R:1 > $null
        ROBOCOPY "C:\Users\$user\AppData\Local\Microsoft\Edge\User Data\Default\Network" "$DFIRLogDir\Collection\USER-DATA\$user\Microsoft_Edge\Network" /MIR /W:2 /R:1 > $null
        ROBOCOPY "C:\Users\$user\AppData\Local\Microsoft\Edge\User Data\Default\Cache" "$DFIRLogDir\Collection\USER-DATA\$user\Microsoft_Edge\Cache" /MIR /W:2 /R:1 > $null
    }

    #Mozilla Firefox Browser Artifacts
    If (Test-Path "C:\Users\$user\AppData\Roaming\Mozilla\Firefox\Profiles"){
        Write-Host -ForegroundColor Yellow "Copying Mozilla Firefox Browser artifacts."
        Log-Write -LogPath $LogFile -LineValue "Copying Mozilla Firefox Browser artifacts."
        New-item "$DFIRLogDir\Collection\USER-DATA\$user\Mozilla" -ItemType Directory | Out-Null
        Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\USER-DATA\$user\Mozilla"
        Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\USER-DATA\$user\Mozilla"
        ROBOCOPY "C:\Users\$user\AppData\Roaming\Mozilla\Firefox\Profiles" "$DFIRLogDir\Collection\USER-DATA\$user\Mozilla" /MIR /W:2 /R:1 > $null
    }

    #Microsoft Internet Explorer Browser Artifacts
    If (Test-Path "C:\Users\$user\AppData\Local\Microsoft\Windows"){
        New-item "$DFIRLogDir\Collection\USER-DATA\$user\Internet_Explorer\History" -ItemType Directory | Out-Null
        Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\USER-DATA\$user\Internet_Explorer\History"
        Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\USER-DATA\$user\Internet_Explorer\History"
        ROBOCOPY "C:\Users\$user\AppData\Local\Microsoft\Windows\History" "$DFIRLogDir\Collection\USER-DATA\$user\Internet_Explorer\History" /MIR /W:2 /R:1 > $null
        New-item "$DFIRLogDir\Collection\USER-DATA\$user\Internet_Explorer\WebCache" -ItemType Directory | Out-Null
        Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\USER-DATA\$user\Internet_Explorer\WebCache"
        Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\USER-DATA\$user\Internet_Explorer\WebCache"
        ROBOCOPY "C:\Users\$user\AppData\Local\Microsoft\Windows\WebCache" "$DFIRLogDir\Collection\USER-DATA\$user\Internet_Explorer\WebCache" /MIR /W:2 /R:1 > $null
    }

    #Google Drive Artifacts
    If (Test-Path "C:\Users\$user\AppData\Local\Google\Drive"){
        Write-Host -ForegroundColor Yellow "Copying Google Drive artifacts."
        Log-Write -LogPath $LogFile -LineValue "Copying Google Drive artifacts."
        New-item "$DFIRLogDir\Collection\USER-DATA\$user\GoogleDrive" -ItemType Directory | Out-Null
        Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\USER-DATA\$user\GoogleDrive"
        Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\USER-DATA\$user\GoogleDrive"
        ROBOCOPY "C:\Users\$user\AppData\Local\Google\Drive" "$DFIRLogDir\Collection\USER-DATA\$user\GoogleDrive" /MIR /W:2 /R:1 > $null
    }

    #Microsoft OneDrive
    If (Test-Path "C:\Users\$user\AppData\Local\Microsoft\OneDrive"){
        Write-Host -ForegroundColor Yellow "Copying Microsoft OneDrive artifacts."
        Log-Write -LogPath $LogFile -LineValue "Copying Microsoft OneDrive artifacts."
        New-item "$DFIRLogDir\Collection\USER-DATA\$user\Microsoft_OneDrive" -ItemType Directory | Out-Null
        Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\USER-DATA\$user\Microsoft_OneDrive"
        Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\USER-DATA\$user\Microsoft_OneDrive"
        ROBOCOPY "C:\Users\$user\AppData\Local\Microsoft\OneDrive" "$DFIRLogDir\Collection\USER-DATA\$user\Microsoft_OneDrive" /MIR /W:2 /R:1 > $null
    }

    #Users OneDrive
    [string[]]$UsersOneDrive =(GCI "c:\Users\$user").Name | Where-Object {$_ -like "OneDrive*"}
    If ($UsersOneDrive){
        Write-Host -ForegroundColor Yellow "Collecting a list of filenames from Users OneDrive directoies."
        Log-Write -LogPath $LogFile -LineValue "Collecting a list of filenames from Users OneDrive directoies."
        ForEach ($ODFolder in $UsersOneDrive){
            New-item "$DFIRLogDir\Collection\USER-DATA\$user\$ODFolder" -ItemType Directory | Out-Null
            Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\USER-DATA\$user\$ODFolder"
            Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\USER-DATA\$user\$ODFolder"
            ROBOCOPY "C:\Users\$user\$ODFolder" "$DFIRLogDir\Collection\USER-DATA\$user\$ODFolder" /MIR /W:0 /R:0 > $null
            Get-ChildItem -Path "C:\Users\$user\$ODFolder" -Recurse -ErrorAction SilentlyContinue -Force | Select-Object FullName, Name, CreationTime, CreationTimeUtc, LastAccessTime, LastAccessTimeUtc, LastWriteTime, LastWriteTimeUtc, VersionInfo | Export-Csv "$DFIRLogDir\Collection\USER-DATA\$user\$ODFolder\List_of_All_Files_in_OneDrive_Directory.csv" -NoTypeInformation
        }
    }

    #Dropbox
    If (Test-Path "C:\Users\$user\AppData\Local\Dropbox"){
        Write-Host -ForegroundColor Yellow "Copying Dropbox artifacts."
        Log-Write -LogPath $LogFile -LineValue "Copying Dropbox artifacts."
        New-item "$DFIRLogDir\Collection\USER-DATA\$user\Dropbox" -ItemType Directory | Out-Null
        Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\USER-DATA\$user\Dropbox"
        Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\USER-DATA\$user\Dropbox"
        ROBOCOPY "C:\Users\$user\AppData\Local\Dropbox" "$DFIRLogDir\Collection\USER-DATA\$user\Dropbox" /MIR /W:2 /R:1 > $null
    }

    #Connected Devices Platform
    If (Test-Path "C:\Users\$user\AppData\Local\ConnectedDevicesPlatform"){
        Write-Host -ForegroundColor Yellow "Copying ConnectedDevicesPlatform artifacts."
        Log-Write -LogPath $LogFile -LineValue "Copying ConnectedDevicesPlatform artifacts."
        New-item "$DFIRLogDir\Collection\USER-DATA\$user\ConnectedDevicesPlatform" -ItemType Directory | Out-Null
        Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\USER-DATA\$user\ConnectedDevicesPlatform"
        Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\USER-DATA\$user\ConnectedDevicesPlatform"
        ROBOCOPY "C:\Users\$user\AppData\Local\ConnectedDevicesPlatform" "$DFIRLogDir\Collection\USER-DATA\$user\ConnectedDevicesPlatform" /MIR /W:2 /R:1 > $null
    }

    #Microsoft Terminal Server Client
    If (Test-Path "C:\Users\$user\AppData\Local\Microsoft\Terminal Server Client"){
        Write-Host -ForegroundColor Yellow "Copying Terminal Server Client artifacts."
        Log-Write -LogPath $LogFile -LineValue "Copying Terminal Server Client artifacts."
        New-item "$DFIRLogDir\Collection\USER-DATA\$user\Terminal-Service" -ItemType Directory | Out-Null
        Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\USER-DATA\$user\Terminal-Service"
        Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\USER-DATA\$user\Terminal-Service"
        ROBOCOPY "C:\Users\$user\AppData\Local\Microsoft\Terminal Server Client" "$DFIRLogDir\Collection\USER-DATA\$user\Terminal-Server" /MIR /W:2 /R:1 > $null
    }

    #Recent Folder
    If (Test-Path "C:\Users\$user\AppData\Roaming\Microsoft\Windows\Recent"){
        Write-Host -ForegroundColor Yellow "Copying Recent Folder artifacts."
        Log-Write -LogPath $LogFile -LineValue "Copying Recent Folder  artifacts."
        New-item "$DFIRLogDir\Collection\USER-DATA\$user\Recent" -ItemType Directory | Out-Null
        Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\USER-DATA\$user\Recent"
        Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\USER-DATA\$user\Recent"
        ROBOCOPY "C:\Users\$user\AppData\Roaming\Microsoft\Windows\Recent" "$DFIRLogDir\Collection\USER-DATA\$user\Recent" /MIR /W:2 /R:1 > $null
    }

    #Office Recent Folder
    If (Test-Path "C:\Users\$user\AppData\Roaming\Microsoft\Office\Recent"){
        Write-Host -ForegroundColor Yellow "Copying Office Recent Folder artifacts."
        Log-Write -LogPath $LogFile -LineValue "Copying Office Recent Folder artifacts."
        New-item "$DFIRLogDir\Collection\USER-DATA\$user\Recent-Office" -ItemType Directory | Out-Null
        Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\USER-DATA\$user\Recent-Office"
        Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\USER-DATA\$user\Recent-Office"
        ROBOCOPY "C:\Users\$user\AppData\Roaming\Microsoft\Office\Recent" "$DFIRLogDir\Collection\USER-DATA\$user\Recent-Office" /MIR /W:2 /R:1 > $null
    }

    #User Account Information
    If ($user -ne 'Public') {
        Write-Host -ForegroundColor Yellow "Gathering User Account Information."
        Log-Write -LogPath $LogFile -LineValue "Gathering User Account Information"
        If ((Get-LocalUser | Where-Object {$_.Name -eq $user})){
            (net user $user) | Out-File "$DFIRLogDir\Collection\User-DATA\$user\USER_Account_Info_net-user.txt" > $null
        }Else {
            (net user /domain $user) | Out-File "$DFIRLogDir\Collection\User-DATA\$user\USER_Account_Info_net-user.txt" > $null
        }
    }

    #PowerShell Console History
    If (Test-Path ("C:\Users\$user\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt")){
        Write-Host -ForegroundColor Yellow "Copying PowerShell Console History artifacts."
        Log-Write -LogPath $LogFile -LineValue "Copying PowerShell Console History artifacts."
        ROBOCOPY "C:\Users\$user\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine" "$DFIRLogDir\Collection\User-DATA\$user\" ConsoleHost_history.txt /W:2 /R:1 > $null
    }
    
    #Collect list of Filenames from Users %TEMP% Directory
    If (Test-Path ("C:\Users\$user\AppData\Local\Temp\")){
        Write-Host -ForegroundColor Yellow "Collecting a list of filenames from the Users Temp Directory."
        Log-Write -LogPath $LogFile -LineValue "Collecting a list of filenames from the Users Temp Directory."
        $USERSTEMP = Get-ChildItem -Path "C:\Users\$user\AppData\Local\Temp\"  -Recurse -ErrorAction SilentlyContinue -Force | Select-Object FullName, Name, CreationTime, CreationTimeUtc, LastAccessTime, LastAccessTimeUtc, LastWriteTime, LastWriteTimeUtc, VersionInfo
        $USERSTEMP | Export-Csv "$DFIRLogDir\Collection\User-DATA\$user\List_of_All_Files_in_TEMP.csv" -NoTypeInformation
        
    }

    Write-Host -ForegroundColor Yellow "Collecting User Browser History (ALL BROWSERS)."
    Log-Write -LogPath $LogFile -LineValue "Collecting User Browser History (ALL BROWSERS)."
    #Gets User Browser History (ALL)
    Start-Process "$IRDir\Tools\BHV.exe" -ArgumentList "/HistorySource 4 /HistorySourceFolder `"C:\Users\${user}`" /VisitTimeFilterType 1 /SaveDirect /scomma `"$DFIRLogDir\Collection\User-DATA\${user}\${user}_Internet_History_ALL.csv`"" -Wait -WindowStyle Hidden
}

#Application Compatibility (AppCompat)
If (Test-Path "C:\VSC\Windows\appcompat\Programs"){
    Write-Host -ForegroundColor Yellow "Collecting Application Compatibility (AppCompat)."
    Log-Write -LogPath $LogFile -LineValue "Collecting Application Compatibility (AppCompat)."
    New-item "$DFIRLogDir\Collection\Registry-System\Amcache" -ItemType Directory | Out-Null
    Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\Registry-System\Amcache"
    Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\Registry-System\Amcache"
    ROBOCOPY  "C:\VSC\Windows\appcompat\Programs" "$DFIRLogDir\Collection\Registry-System\Amcache" *.hv* /W:2 /R:1 > $null
}

#LOCALSERVICE Account
If (Test-Path "C:\VSC\Windows\ServiceProfiles\LocalService"){
    Write-Host -ForegroundColor Yellow "Collecting LOCALSERVICE Account artificats."
    Log-Write -LogPath $LogFile -LineValue "Collecting LOCALSERVICE Account artificats."
    New-item "$DFIRLogDir\Collection\Registry-System\LocalService" -ItemType Directory | Out-Null
    Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\Registry-System\LocalService"
    Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\Registry-System\LocalService"
    ROBOCOPY  "C:\VSC\Windows\ServiceProfiles\LocalService" "$DFIRLogDir\Collection\Registry-System\LocalService" *.DA* /W:2 /R:1 > $null
    ROBOCOPY  "C:\VSC\Windows\ServiceProfiles\LocalService\AppData\Local\Microsoft\Windows" "$DFIRLogDir\Collection\Registry-System\LocalService" *.DA* /W:2 /R:1 > $null
}

#NETWORKSERVICE Account
If (Test-Path "C:\VSC\Windows\ServiceProfiles\NetworkService"){
    Write-Host -ForegroundColor Yellow "Collecting NETWORKSERVICE Account artificats."
    Log-Write -LogPath $LogFile -LineValue "Collecting NETWORKSERVICE Account artificats."
    New-item "$DFIRLogDir\Collection\Registry-System\NetworkService" -ItemType Directory | Out-Null
    Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\Registry-System\NetworkService"
    Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\Registry-System\NetworkService"
    ROBOCOPY  "C:\VSC\Windows\ServiceProfiles\NetworkService" "$DFIRLogDir\Collection\Registry-System\NetworkService" *.DA* /W:2 /R:1 > $null
    ROBOCOPY  "C:\VSC\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows" "$DFIRLogDir\Collection\Registry-System\NetworkService" *.DA* /W:2 /R:1 > $null
}

#Windows Registry Files
If (Test-Path "C:\VSC\Windows\System32\config"){
    Write-Host -ForegroundColor Yellow "Collecting Windows Registry Files artificats."
    Log-Write -LogPath $LogFile -LineValue "Collecting Windows Registry Files artificats."
    New-item "$DFIRLogDir\Collection\Registry-System\config" -ItemType Directory | Out-Null
    Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\Registry-System\config"
    Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\Registry-System\config"
    ROBOCOPY  "C:\VSC\Windows\System32\config" "$DFIRLogDir\Collection\Registry-System\config" /MIR /XD systemprofile /W:2 /R:1 > $null
    If(!(Test-Path "$DFIRLogDir\Collection\Registry-System\config\SOFTWARE")){
        & reg.exe SAVE "HKLM\SOFTWARE" "$DFIRLogDir\Collection\Registry-System\config\SOFTWARE"
    }
    If(!(Test-Path "$DFIRLogDir\Collection\Registry-System\config\SYSTEM")){
        & reg.exe SAVE "HKLM\SOFTWARE" "$DFIRLogDir\Collection\Registry-System\config\SYSTEM"
    }
}

#System Resource Utilization Monitor (SRUM)
If (Test-Path "C:\Windows\system32\sru"){
    Write-Host -ForegroundColor Yellow "Collecting System Resource Utilization Monitor (SRUM) artificats."
    Log-Write -LogPath $LogFile -LineValue "Collecting System Resource Utilization Monitor (SRUM) artificats."
    New-item "$DFIRLogDir\Collection\System\SRUDB" -ItemType Directory | Out-Null
    Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\System\SRUDB"
    Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\System\SRUDB"
    ROBOCOPY  "C:\Windows\system32\sru" "$DFIRLogDir\Collection\System\SRUDB" /MIR /W:2 /R:1 > $null
}

#Software Update Manager (SUM) Log Files
If (Test-Path "C:\Windows\System32\LogFiles\Sum"){
    Write-Host -ForegroundColor Yellow "Collecting Software Update Manager (SUM) Log Files artificats."
    Log-Write -LogPath $LogFile -LineValue "Collecting Software Update Manager (SUM) Log Files artificats."
    New-item "$DFIRLogDir\Collection\System\SUM" -ItemType Directory | Out-Null
    Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\System\SUM"
    Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\System\SUM"
    ROBOCOPY  "C:\Windows\System32\LogFiles\Sum" "$DFIRLogDir\Collection\System\SUM" /MIR /W:2 /R:1 > $null
}

#Windows Updates Database Tracker
If (Test-Path "C:\Windows\SoftwareDistribution\DataStore\DataStore.edb"){
    Write-Host -ForegroundColor Yellow "Collecting Windows Updates Database Tracker artificats."
    Log-Write -LogPath $LogFile -LineValue "Collecting Windows Updates Database Tracker artificats."
    New-item "$DFIRLogDir\Collection\System\DataStore" -ItemType Directory | Out-Null
    Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\System\DataStore"
    Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\System\DataStore"
    ROBOCOPY  "C:\Windows\SoftwareDistribution\DataStore" "$DFIRLogDir\Collection\System\DataStore" DataStore.edb /W:2 /R:1 > $null
}

Log-Write -LogPath $LogFile -LineValue "Removing attributes from folders and files (attrib)."
Write-Host -ForegroundColor Yellow "Removing attributes from folders and files (attrib)."

Start-Process "C:\Windows\System32\attrib.exe" -ArgumentList "-S -H -I -R /S /D $DFIRLogDir\Collection\*.*" -Wait -WindowStyle Hidden
Start-Process "C:\Windows\System32\attrib.exe" -ArgumentList "-S -H -I -R /S /D $DFIRLogDir\Collection\*" -Wait -WindowStyle Hidden

$SectionCompletion2 = (Get-Date)
Write-Host -ForegroundColor Green "COMPLETED: Gathering various Users and System artifacts."
Log-Write -LogPath $LogFile -LineValue "COMPLETED: Gathering various Users and System artifacts."
Log-Write -LogPath $LogFile -LineValue "Total processing time $(($SectionCompletion2-$SectionCompletion).totalseconds) seconds."
$SectionCompletion = $SectionCompletion2
Add-Content -Path $LogFile -Value "---------------------------------------------------------------------------------------------------"

#endregion

###############################################################################
#region Collecting Tanium Database                                            #
###############################################################################

Write-Host -ForegroundColor Yellow "Gathering Tanium database."
Log-Write -LogPath $LogFile -LineValue "Gathering Tanium database."

If(Test-Path "C:\VSC\Program Files (x86)\Tanium\Tanium Client\extensions\recorder\"){
    Write-Host -ForegroundColor Yellow "Collecting Tanium database file."
    Log-Write -LogPath $LogFile -LineValue "Collecting Tanium database file."
    If(!(Test-Path "$DFIRLogDir\Collection\Tanium\Recorder")){
        New-Item "$DFIRLogDir\Collection\Tanium\Recorder" -ItemType Directory | Out-Null
    }
    ROBOCOPY "C:\VSC\Program Files (x86)\Tanium\Tanium Client\extensions\recorder" "$DFIRLogDir\Collection\Tanium\Recorder" /MIR /W:2 /R:1 > $null
}

$SectionCompletion2 = (Get-Date)
Write-Host -ForegroundColor Green "COMPLETED: Gathered Tanium database."
Log-Write -LogPath $LogFile -LineValue "COMPLETED: Gathered Tanium database."
Log-Write -LogPath $LogFile -LineValue "Total processing time $(($SectionCompletion2-$SectionCompletion).totalseconds) seconds."
$SectionCompletion = $SectionCompletion2
Add-Content -Path $LogFile -Value "---------------------------------------------------------------------------------------------------"

Write-Host -ForegroundColor Green "Unmap VSC folder 'C:\VSC\'."
Log-Write -LogPath $LogFile -LineValue "COMPLETED: Unmap VSC folder 'C:\VSC\'."
cmd.exe /c rd "C:\VSC" > $null

#endregion

###############################################################################
#region Collecting Prefetch Files                                             #
###############################################################################

Write-Host -ForegroundColor Yellow "Collecting Prefetch Files."
Log-Write -LogPath $LogFile -LineValue "Collecting Prefetch Files."

If (Test-Path "$env:windir\Prefetch"){
    New-item "$DFIRLogDir\Collection\System\Prefetch" -ItemType Directory | Out-Null
    Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\System\Prefetch"
    Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\System\Prefetch"
    ROBOCOPY  "$env:windir\Prefetch" "$DFIRLogDir\Collection\System\Prefetch" /MIR /W:2 /R:1 > $null
}

$SectionCompletion2 = (Get-Date)
Write-Host -ForegroundColor Green "COMPLETED: Collected Prefetch files."
Log-Write -LogPath $LogFile -LineValue "COMPLETED: Collected Prefetch files."
Log-Write -LogPath $LogFile -LineValue "Total processing time $(($SectionCompletion2-$SectionCompletion).totalseconds) seconds."
$SectionCompletion = $SectionCompletion2
Add-Content -Path $LogFile -Value "---------------------------------------------------------------------------------------------------"

#endregion

##################################################
#region Collecting Power Report and SRUM         #
##################################################

New-item "$DFIRLogDir\Collection\System\Power" -ItemType Directory | Out-Null
Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\System\Power"
Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\System\Power"

Set-Location "$DFIRLogDir\Collection\System\Power"

Write-Host -ForegroundColor Yellow "Collecting Power Reports and SRUM."
Log-Write -LogPath $LogFile -LineValue "Collecting Power Reports and SRUM."

#Generate a diagnostic system power transition report
powercfg /systempowerreport > $null
#Generate a diagnostic system power transition report
powercfg /systempowerreport > $null
#Generate a report of battery usage
powercfg /batteryreport > $null
Set-Location $ScriptDir

$SectionCompletion2 = (Get-Date)
Write-Host -ForegroundColor Green "COMPLETED: Collected Power Reports and SRUM."
Log-Write -LogPath $LogFile -LineValue "COMPLETED: Collected Power Reports and SRUM."
Log-Write -LogPath $LogFile -LineValue "Total processing time $(($SectionCompletion2-$SectionCompletion).totalseconds) seconds."
$SectionCompletion = $SectionCompletion2
Add-Content -Path $LogFile -Value "---------------------------------------------------------------------------------------------------"

#endregion

###############################################################################
#region Gathering System Information                                          #
###############################################################################

If (!(Test-Path "$DFIRLogDir\Collection\System-Info")){
    New-Item "$DFIRLogDir\Collection\System-Info" -ItemType Directory | Out-Null
    Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\System-Info"
    Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\System-Info"
}

Write-Host -ForegroundColor Yellow "Gathering System Information."
Log-Write -LogPath $LogFile -LineValue "Gathering System Information."

Write-Host -ForegroundColor Yellow "Collecting Environemnt Variables."
Log-Write -LogPath $LogFile -LineValue "Collecting Environemnt Variables."
#Environment Variables
$env = Get-ChildItem ENV: | select Name, Value
$env | Export-Csv "$DFIRLogDir\Collection\System-Info\Environment_Variables.csv" -NoTypeInformation

Write-Host -ForegroundColor Yellow "Collecting System Information (systeminfo)."
Log-Write -LogPath $LogFile -LineValue "Collecting System Information (systeminfo)."
#System Information
$systeminfo = get-computerinfo | Select-Object @{Name='BiosBIOSVersion';Expression={$_.BiosBIOSVersion -join '; '}}, BiosCaption, BiosDescription, BiosFirmwareType, BiosManufacturer, BiosName, BiosReleaseDate, CsDNSHostName, CsDomain, CsDomainRole, CsEnableDaylightSavingsTime, CsManufacturer, CsNetworkAdapters, CsNumberOfLogicalProcessors, CsNumberOfProcessors, CsPartOfDomain, CsPauseAfterReset, CsPCSystemType, CsPhyicallyInstalledMemory, CsPrimaryOwnerContact, CsPrimaryOwnerName, CsProcessors, CsSystemType, CsTotalPhysicalMemory, CsUserName, CsWorkgroup, LogonServer, OsArchitecture, OsBootDevice, OsBuildNumber, OsCountryCode, OSDisplayVersion, OsFreePhysicalMemory, OsFreeSpaceInPagingFiles, OsFreeVirtualMemory, OsHardwareAbstractionLayer, OsInstallDate, OsInUseVirtualMemory, OsLanguage, OsLastBootUpTime, OsLocalDateTime, OsLocale, OsLocaleID, OsManufacturer, OsMaxNumberOfProcesses, OsMaxProcessMemorySize, OsName, OsPagingFiles, OsProductType, OsRegisteredUser, OsSizeStoredInPagingFiles, OsSystemDevice, OsSystemDirectory, OsSystemDrive, OsTotalVirtualMemorySize, OsTotalVisibleMemorySize, OsUptime, OsVersion, OsWindowsDirectory, TimeZone, WindowsBuildLabEx, WindowsCurrentVersion, WindowsEditionId, WindowsInstallDateFromRegistry, WindowsProductName, WindowsRegisteredOwner, WindowsSystemRoot, WindowsVersion
$systeminfo | Export-Csv "$DFIRLogDir\Collection\System-Info\System_Information.csv" -NoTypeInformation

Write-Host -ForegroundColor Yellow "Collecting Operating System (OS) Information."
Log-Write -LogPath $LogFile -LineValue "Collecting Operating System (OS) Information."
#OS Info
$OSinfo = Get-ComputerInfo | Select-Object -Property OsName, OsArchitecture, OsVersion, OsBuildNumber, OsInstallDate, OsSystemDrive, OsSystemDevice, OsWindowsDirectory, OsLastBootUpTime, OsLocale, OsLocalDateTime, OsNumberOfUsers, OsRegisteredUser, OsOrganization
$OSinfo | Export-Csv "$DFIRLogDir\Collection\System-Info\OS_Information.csv" -NoTypeInformation

Write-Host -ForegroundColor Yellow "Collecting OS Hotfixes."
Log-Write -LogPath $LogFile -LineValue "Collecting OS Hotfixes."
#Hotfixes
$Hotfixes = Get-Hotfix | Select-Object -Property CSName, Caption,Description, HotfixID, InstalledBy, InstalledOn
$Hotfixes | Sort-Object InstalledOn | Export-Csv "$DFIRLogDir\Collection\System-Info\Installed_Hotfixes.csv" -NoTypeInformation

Write-Host -ForegroundColor Yellow "Collecting Windows Defender Status."
Log-Write -LogPath $LogFile -LineValue "Collecting Windows Defender Status."
#Get Windows Defender Status
$WinDefender = Get-MpComputerStatus
$WinDefender | Export-Csv "$DFIRLogDir\Collection\System-Info\Windows_Defender_Status.csv" -NoTypeInformation

$SectionCompletion2 = (Get-Date)
Write-Host -ForegroundColor Green "COMPLETED: Gathered System Information."
Log-Write -LogPath $LogFile -LineValue "COMPLETED: Gathered System Information."
Log-Write -LogPath $LogFile -LineValue "Total processing time $(($SectionCompletion2-$SectionCompletion).totalseconds) seconds."
$SectionCompletion = $SectionCompletion2
Add-Content -Path $LogFile -Value "---------------------------------------------------------------------------------------------------"

#endregion

###############################################################################
#region Gather Running Processes, Services, Scheduled Tasks, Startup Programs #
###############################################################################

If (!(Test-Path "$DFIRLogDir\Collection\Process")){
    New-Item "$DFIRLogDir\Collection\Process" -ItemType Directory | Out-Null
    Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\Process"
    Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\Process"
}

If (!(Test-Path "$DFIRLogDir\Collection\Scheduled_Task")){
    New-Item "$DFIRLogDir\Collection\Scheduled_Task" -ItemType Directory | Out-Null
    Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\Scheduled_Task"
    Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\Scheduled_Task"
}

If (!(Test-Path "$DFIRLogDir\Collection\Services")){
    New-Item "$DFIRLogDir\Collection\Services" -ItemType Directory | Out-Null
    Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\Services"
    Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\Services"
}

Write-Host -ForegroundColor Yellow "Gathering Running Processes, Services, Schedule Tasks,and Startup Programs."
Log-Write -LogPath $LogFile -LineValue "Gathering Running Processes, Services, Schedule Tasks,and Startup Programs."

Write-Host -ForegroundColor Yellow "Collecting Running Processes."
Log-Write -LogPath $LogFile -LineValue "Collecting Running Processes."
#Gets Running Processes
$RunProcesses = Get-Process | Select Handles, StartTime, PM, VM, SI, id, ProcessName, Path, Product, FileVersion
$RunProcesses | Export-Csv "$DFIRLogDir\Collection\Process\Running_Processes.csv" -NoTypeInformation

Write-Host -ForegroundColor Yellow "Collecting Startup Programs."
Log-Write -LogPath $LogFile -LineValue "Collecting Running Processes."
#Items set to run on startup
$StartupProgs = Get-CimInstance Win32_StartupCommand | Select-Object Name, command, Location, User
$StartupProgs | Export-Csv "$DFIRLogDir\Collection\System\AutoStartup_Programs.csv" -NoTypeInformation

Write-Host -ForegroundColor Yellow "Collecting Scheduled Tasks Information."
Log-Write -LogPath $LogFile -LineValue "Collecting Scheduled Tasks Information."

# Gets All Scheduled Tasks
$AllScheduledTasksInfo = Get-ScheduledTask | Get-ScheduledTaskInfo | Select-Object -Property TaskName, TaskPath, LastRunTime, LastTaskResult, NextRunTime, NumberOfMissedRuns, State
$AllScheduledTasksInfo | Export-Csv "$DFIRLogDir\Collection\Scheduled_Task\All_Scheduled_Task_Detailed.csv" -NoTypeInformation
$AllScheduledTasks = Get-ScheduledTask |  Select-Object -Property TaskName, TaskPath, State, Description
$AllScheduledTasks | Export-Csv "$DFIRLogDir\Collection\Scheduled_Task\All_Scheduled_Tasks.csv" -NoTypeInformation

Write-Host -ForegroundColor Yellow "Collecting Scheduled Tasks State."
Log-Write -LogPath $LogFile -LineValue "Collecting Scheduled Tasks State."

# Get Running Tasks and Their state
$ScheduledTaskRunning = Get-ScheduledTask | ? State -eq running | Get-ScheduledTaskInfo | Select-Object -Property TaskName, TaskPath, LastRunTime, LastTaskResult, NextRunTime, NumberOfMissedRuns
$ScheduledTaskRunning | Export-Csv "$DFIRLogDir\Collection\Scheduled_Task\Scheduled_Tasks_Running.csv" -NoTypeInformation

Write-Host -ForegroundColor Yellow "Collecting Windows Services."
Log-Write -LogPath $LogFile -LineValue "Collecting Windows Services."

#Services
$Services = Get-Service | Select-Object Name, DisplayName, Status, StartType
$Services | Export-Csv "$DFIRLogDir\Collection\Services\Windows_Services.csv" -NoTypeInformation
$Error.Clear()
$RegServices = Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\* -ErrorAction SilentlyContinue | Select-Object -Property PSChildName, DisplayName, ImagePath, Start, Type
$RegServices | Export-Csv "$DFIRLogDir\Collection\Services\Windows_Services_Registry.csv" -NoTypeInformation
If ($Error){
    $Error | Out-File "$DFIRLogDir\Collection\Services\Registry_Error_Potential_Persistence.txt"
    $Error.Clear()
}

$SectionCompletion2 = (Get-Date)
Write-Host -ForegroundColor Green "COMPLETED: Gathered Running Processes, Services, Schedule Tasks,and Startup Programs."
Log-Write -LogPath $LogFile -LineValue "COMPLETED: Gathered Running Processes, Services, Schedule Tasks,and Startup Programs."
Log-Write -LogPath $LogFile -LineValue "Total processing time $(($SectionCompletion2-$SectionCompletion).totalseconds) seconds."
$SectionCompletion = $SectionCompletion2
Add-Content -Path $LogFile -Value "---------------------------------------------------------------------------------------------------"

#endregion

###############################################################################
#region Gather AutoRuns                                                       #
###############################################################################

Write-Host -ForegroundColor Yellow "Collecting Autoruns."
Log-Write -LogPath $LogFile -LineValue "Collecting Autoruns."

If (!(Test-Path "$DFIRLogDir\Collection\AutoRuns")){
    New-Item "$DFIRLogDir\Collection\AutoRuns" -ItemType Directory | Out-Null
    Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\AutoRuns"
    Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\AutoRuns"
}

Write-Host -ForegroundColor Yellow "Collecting All AutoRuns Information."
Log-Write -LogPath $LogFile -LineValue "Collecting Collecting All AutoRuns Information."
Start-Process "C:\DFIRLog\Tools\autorunsc.exe" -ArgumentList "/accepteula -a * -c -h -s '*' -o `"$DFIRLogDir\Collection\AutoRuns\AutoRuns.csv`" -nobanner" -Wait -WindowStyle Hidden

$SectionCompletion2 = (Get-Date)
Write-Host -ForegroundColor Green "COMPLETED: Gathered Autoruns All AutoRuns Information."
Log-Write -LogPath $LogFile -LineValue "COMPLETED: Gathered Autoruns All AutoRuns Information."
Log-Write -LogPath $LogFile -LineValue "Total processing time $(($SectionCompletion2-$SectionCompletion).totalseconds) seconds."
$SectionCompletion = $SectionCompletion2
Add-Content -Path $LogFile -Value "---------------------------------------------------------------------------------------------------"

#endregion

###############################################################################
#region USB Device, PNP Device, and Logical Disk Information                  #
###############################################################################

Push-Location -Path (Get-Module -Name PnPDevice).ModuleBase
Write-Host -ForegroundColor Yellow "Gathering USB Device, PNP Device, and Logical Disk Information."
Log-Write -LogPath $LogFile -LineValue "Gathering USB Device, PNP Device, and Logical Disk Information."

Write-Host -ForegroundColor Yellow "Collecting Logical Drive Information."
Log-Write -LogPath $LogFile -LineValue "Collecting Collecting Logical Drive Information."
#Logical Drives (current session)
$LogicalDrives = Get-WmiObject -Class Win32_LogicalDisk | Select-Object -Property Name, VolumeName, VolumeSerialNumber, SerialNumber, FileSystem, Description, @{"Label"="DiskSize(GB)";"Expression"={"{0:N}" -f ($_.Size/1GB) -as [float]}}, @{"Label"="FreeSpace(GB)";"Expression"={"{0:N}" -f ($_.FreeSpace/1GB) -as [float]}}
$LogicalDrives | Sort-Object Name | Export-Csv "$DFIRLogDir\Collection\System\Logical_Drives_Current_Session.csv" -NoTypeInformation

Write-Host -ForegroundColor Yellow "Collecting USB Device Information."
Log-Write -LogPath $LogFile -LineValue "Collecting Collecting USB Device Information."
#Gets list of USB devices
$USBDevices = Get-ItemProperty -Path HKLM:\System\CurrentControlSet\Enum\USB*\*\* | select FriendlyName, Driver, mfg, DeviceDesc, PSChildName
$USBDevices | Sort-Object FriendlyName | Export-Csv "$DFIRLogDir\Collection\System\All_USB_Devices.csv" -NoTypeInformation
If (Test-Path HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR){
    $USBDevicesName = Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR\*\* | Select FriendlyName, Driver, mfg, DeviceDesc, PSChildName
    $USBDevicesName | Sort-Object FriendlyName | Export-Csv "$DFIRLogDir\Collection\System\List_of_USB_Devices.csv" -NoTypeInformation
}

Write-Host -ForegroundColor Yellow "Collecting PNP Device Information."
Log-Write -LogPath $LogFile -LineValue "Collecting Collecting PNP Device Information."
#All currently connected PNP devices
$UPNPDevices = Get-PnpDevice -PresentOnly -class 'USB', 'DiskDrive', 'Mouse', 'Keyboard', 'Net', 'Image', 'Media', 'Monitor'
$UPNPDevices | Export-Csv "$DFIRLogDir\Collection\System\UPNP_Devices.csv" -NoTypeInformation

Set-Location $ScriptDir
$SectionCompletion2 = (Get-Date)
Write-Host -ForegroundColor Green "COMPLETED: Gathered USB Device, PNP Device, and Logical Disk Information."
Log-Write -LogPath $LogFile -LineValue "COMPLETED: Gathered USB Device, PNP Device, and Logical Disk Information."
Log-Write -LogPath $LogFile -LineValue "Total processing time $(($SectionCompletion2-$SectionCompletion).totalseconds) seconds."
$SectionCompletion = $SectionCompletion2
Add-Content -Path $LogFile -Value "---------------------------------------------------------------------------------------------------"

#endregion

###############################################################################
#region Shortcut Links File Created Last 180 days and Executables in Users    #
#Download Folder and other Obscure Directories                                #
###############################################################################

Write-Host -ForegroundColor Yellow "Gathering Shortcut Links File Created Last 180 days and Executables in Users Download Folder and other Obscure Directories"
Log-Write -LogPath $LogFile -LineValue "Gathering Shortcut Links File Created Last 180 days and Executables in Users Download Folder and other Obscure Directories"

Write-Host -ForegroundColor Yellow "Collecting Shortcut Link Files Created in Last 180 Days."
Log-Write -LogPath $LogFile -LineValue "Collecting Shortcut Link Files Created in Last 180 Days."
#Gets all shortcut link files created in last 180 days.
$LinkFiles = Get-WmiObject Win32_ShortcutFile | select Filename, Caption, @{NAME='CreationDate';Expression={$_.ConvertToDateTime($_.CreationDate)}}, @{Name='LastAccessed';Expression={$_.ConvertToDateTime($_.LastAccessed)}}, @{Name='LastModified';Expression={$_.ConvertToDateTime($_.LastModified)}}, Target | Where-Object {$_.LastModified -gt ((Get-Date).AddDays(-180)) } | sort LastModified -Descending
$LinkFiles | Export-Csv "$DFIRLogDir\Collection\System\Shortcut_Link_Files_Created_Last180days.csv" -NoTypeInformation

Write-Host -ForegroundColor Yellow "Collecting Executable Files Located in Users Download Folders."
Log-Write -LogPath $LogFile -LineValue "Collecting Executable Files Located in Users Download Folders."
#Executeables located in Users Download Folder.
$AllUsersDownload = Get-ChildItem C:\Users\*\Downloads\* -recurse  |  select  PSChildName, Root, Name, FullName, Extension, CreationTimeUTC, LastAccessTimeUTC, LastWriteTimeUTC, Attributes | where {$_.extension -in '.exe','.vbs','.js','.bat','.cmd','.zip','.iso','.dll'}
$AllUsersDownload | Export-Csv "$DFIRLogDir\Collection\User-DATA\List_of_Executables_from_Users_Download_Folder.csv" -NoTypeInformation

Write-Host -ForegroundColor Yellow "Collecting Executables Located in Obscure Directories."
Log-Write -LogPath $LogFile -LineValue "Collecting Executables Located in Obscure Directories."
#Executables Running From Obscure Places
$HiddenExecs1 = Get-ChildItem C:\Users\*\AppData\Local\Temp\* -recurse  |  select  PSChildName, Root, Name, FullName, Extension, CreationTimeUTC, LastAccessTimeUTC, LastWriteTimeUTC, Attributes | where {$_.extension -in '.exe','.vbs','.js','.bat','.cmd','.zip','.iso','.dll'}
$HiddenExecs1 | Export-Csv "$DFIRLogDir\Collection\User-DATA\List_of_Executables_from_Users_TEMP_Folder.csv" -NoTypeInformation
$HiddenExecs2 = Get-ChildItem C:\Windows\Temp\* -recurse  |  select  PSChildName, Root, Name, FullName, Extension, CreationTimeUTC, LastAccessTimeUTC, LastWriteTimeUTC, Attributes | where {$_.extension -in '.exe','.vbs','.js','.bat','.cmd','.zip','.iso','.dll'}
$HiddenExecs2 | Export-Csv "$DFIRLogDir\Collection\User-DATA\List_of_Executables_from_Windows_TEMP_Folder.csv" -NoTypeInformation

$SectionCompletion2 = (Get-Date)
Write-Host -ForegroundColor Green "COMPLETED: Gathered Shortcut Links File Created Last 180 days and Executables in Users Download Folder and other Obscure Directories."
Log-Write -LogPath $LogFile -LineValue "COMPLETED: Gathered Shortcut Links File Created Last 180 days and Executables in Users Download Folder and other Obscure Directories."
Log-Write -LogPath $LogFile -LineValue "Total processing time $(($SectionCompletion2-$SectionCompletion).totalseconds) seconds."
$SectionCompletion = $SectionCompletion2
Add-Content -Path $LogFile -Value "---------------------------------------------------------------------------------------------------"

#endregion

###############################################################################
#region Gather IIS and Apache Weblogs                                         #
###############################################################################

Write-Host -ForegroundColor Yellow "Gathering IIS and Apache Weblogs."
Log-Write -LogPath $LogFile -LineValue "Gathering IIS and Apache Weblogs."

If(Test-Path "C:\inetpub\logs\"){
    Write-Host -ForegroundColor Yellow "Collecting IIS Logs."
    Log-Write -LogPath $LogFile -LineValue "Collecting IIS Logs."
    If(!(Test-Path "$DFIRLogDir\Collection\IIS_Logs")){
        New-Item "$DFIRLogDir\Collection\IIS_Logs" -ItemType Directory | Out-Null
    }
    ROBOCOPY "C:\inetpub\logs\" "$DFIRLogDir\Collection\IIS_Logs\Logs" /MIR /W:2 /R:1 > $null
}

If(Test-Path "HKLM:\Software\Apache Software Foundation"){
    Write-Host -ForegroundColor Yellow "Collecting Apache Logs."
    Log-Write -LogPath $LogFile -LineValue "Collecting Apache Logs."

    If(!(Test-Path "$DFIRLogDir\Collection\Apache_Logs")){
        New-Item "$DFIRLogDir\Collection\Apache_Logs" -ItemType Directory | Out-Null
    }

    Get-ChildItem 'HKLM:\Software\Apache Software Foundation' -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        If ($_.Property -match 'InstallPath') 
        {$ApacheRegKey = Get-ItemProperty $_.pspath | Select InstallPath}
    }

    If($ApacheRegKey){
        $ApacheLogDir = ($ApacheRegKey.InstallPath+'\logs')
        ROBOCOPY "$ApacheLogDir" "$DFIRLogDir\Collection\Apache_Logs\Logs" /MIR /W:2 /R:1 > $null
    }Else {
        Write-Host -ForegroundColor Red "ERROR: Unable to find Apache InstallPath registry key."
        Log-Write -LogPath $LogFile -LineValue "ERROR: Unable to find Apache InstallPath registry key."
    }
}

$SectionCompletion2 = (Get-Date)
Write-Host -ForegroundColor Green "COMPLETED: Gathered IIS and Apache Weblogs."
Log-Write -LogPath $LogFile -LineValue "COMPLETED: Gathered IIS and Apache Weblogs."
Log-Write -LogPath $LogFile -LineValue "Total processing time $(($SectionCompletion2-$SectionCompletion).totalseconds) seconds."
$SectionCompletion = $SectionCompletion2
Add-Content -Path $LogFile -Value "---------------------------------------------------------------------------------------------------"

#endregion

###############################################################################
#region Parsing Eventlogs                                                     #
###############################################################################
If ($EVENTLOG -eq 'yes'){
    If (!(Test-Path "$DFIRLogDir\Collection\Parsed_Event_Logs")){
        New-Item "$DFIRLogDir\Collection\Parsed_Event_Logs" -ItemType Directory | Out-Null
        Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\Parsed_Event_Logs"
        Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\Parsed_Event_Logs"
    }

    Write-Host -ForegroundColor Yellow "Parsing Security Event Logs for Logon/Logoff events."
    Log-Write -LogPath $LogFile -LineValue "Parsing Security Event Logs for Logon/Logoff events."

    $EventCategory_map = @{
        4624 = 'Logon'
        4625 = 'Account Lockout'
        4634 = 'Logoff'
        4647 = 'Logoff'
        4720 = 'Add User'
        4722 = 'Enabled User'
        4724 = 'Password Reset'
        4726 = 'User Deleted'
        4728 = 'Group Membership modified'
        4732 = 'Group Membership modified'
        4798 = 'Enumerate Local Group Membership'
        4800 = 'Lock Workstation'
        4801 = 'Unlock Workstation'
    }

    $EventMessage_map = @{
        
        4624 = 'An account was successfully logged on.'
        4625 = 'An account failed to log on.'
        4634 = 'An account was logged off.'
        4647 = 'User initiated logoff.'
        4720 = 'A user account was created.'
        4722 = 'A user account was enabled.'
        4724 = "An attempt was made to reset an account's password."
        4726 = 'A user account was deleted.'
        4728 = 'A member was added to a security-enabled global group.'
        4732 = 'A member was added to a security-enabled local group.'
        4798 = "A user's local group membership was enumerated."
        4800 = 'The workstation was locked.'
        4801 = 'The workstation was unlocked.'
    }

    $KeywordCode_map = @{
        '0x8010000000000000' = 'Audit Failure'
        '0x8020000000000000' = 'Audit Success'
    }

    $EventStatusCode_map = @{
    '0XC000005E' = 'There are currently no logon servers available to service the logon request.'
    '0xC0000064' = 'User logon with misspelled or bad user account'
    '0xC000006A' = 'User logon with misspelled or bad password'
    '0XC000006D' = 'The cause is either a bad username or authentication information'
    '0XC000006E' = 'Indicates a referenced user name and authentication information are valid, but some user account restriction has prevented successful authentication (such as time-of-day restrictions).'
    '0xC000006F' = 'User logon outside authorized hours'
    '0xC0000070' = 'User logon from unauthorized workstation'
    '0xC0000071' = 'User logon with expired password'
    '0xC0000072' = 'User logon to account disabled by administrator'
    '0XC00000DC' = 'Indicates the Sam Server was in the wrong state to perform the desired operation.'
    '0XC0000133' = 'Clocks between DC and other computer too far out of sync'
    '0XC000015B' = 'The user has not been granted the requested logon type (also called the logon right) at this machine'
    '0XC000018C' = 'The logon request failed because the trust relationship between the primary domain and the trusted domain failed.'
    '0XC0000192' = 'An attempt was made to logon, but the Netlogon service was not started.'
    '0xC0000193' = 'User logon with expired account'
    '0XC0000224' = 'User is required to change password at next logon'
    '0XC0000225' = 'Evidently a bug in Windows and not a risk'
    '0xC0000234' = 'User logon with account locked'
    '0XC00002EE' = 'Failure Reason: An Error occurred during Logon'
    '0XC0000413' = 'Logon Failure: The machine you are logging on to is protected by an authentication firewall. The specified account is not allowed to authenticate to the machine.'
    '0x0' = 'Status OK.'
    }

    $LogonLogoffEvents = Get-WinEvent -LogName 'Security' -FilterXPath "(Event[System[EventID=4624]] or Event[System[EventID=4634]] or Event[System[EventID=4647]] or Event[System[EventID=4674]] or Event[System[EventID=4800]] or Event[System[EventID=4801]]) and Event[EventData[Data[@Name='TargetDomainName'] != 'NT AUTHORITY']] and Event[EventData[Data[@Name='TargetDomainName'] != 'Window Manager']] and Event[EventData[Data[@Name='TargetDomainName'] != 'Font Driver Host']]" -ErrorAction SilentlyContinue | ForEach-Object {
        # convert the event to XML and grab the Event node
        $LogonSessionsEventXml = ([xml]$_.ToXml()).Event
        $LogonSessionsLogonUser = ($LogonSessionsEventXml.EventData.Data | Where-Object { $_.Name -eq 'TargetUserName' }).'#text'
        $LogonSessionsLogonUserDomain = ($LogonSessionsEventXml.EventData.Data | Where-Object { $_.Name -eq 'TargetDomainName' }).'#text'
        $LogonSessionsLogonLoginID = ($LogonSessionsEventXml.EventData.Data | Where-Object { $_.Name -eq 'TargetLogonId' }).'#text'
        $LogonSessionsLogonIP = ($LogonSessionsEventXml.EventData.Data | Where-Object { $_.Name -eq 'IpAddress' }).'#text'
        $LogonSessionsLogonType = ($LogonSessionsEventXml.EventData.Data | Where-Object { $_.Name -eq 'LogonType' }).'#text'
        # output the properties you need
        [PSCustomObject]@{
        Time = [DateTime]$LogonSessionsEventXml.System.TimeCreated.SystemTime
        EventID = $LogonSessionsEventXml.System.EventID
        Category = $EventCategory_map[[int]$LogonSessionsEventXml.System.EventID]
        Message = $EventMessage_map[[int]$LogonSessionsEventXml.System.EventID]
        LogonUser = $LogonSessionsLogonUser
        LogonUserDomain = $LogonSessionsLogonUser
        LogonId = $LogonSessionsLogonLoginID
        LogonIP = $LogonSessionsLogonIP
        LogonType = $LogonType_map[[int]$LogonSessionsLogonType]
        }
    }

    If ($LogonLogoffEvents){
        $LogonLogoffEvents | Sort-Object Time | Export-Csv "$DFIRLogDir\Collection\Parsed_Event_Logs\All_Logon_Logoff.csv" -NoTypeInformation
        Write-Host -ForegroundColor Green "COMPLETED: Parsed the Security Event Logs and extracted all Logon/Logoff events."
        Log-Write -LogPath $LogFile -LineValue "COMPLETED: Parsed the Security Event Logs and extracted all Logon/Logoff events."
    }Else {
        Write-Host -ForegroundColor Green "COMPLETED: Parsed the Security Event Logs and found NO Logon/Logoff events."
        Log-Write -LogPath $LogFile -LineValue "COMPLETED: Parsed the Security Event Logs and found NO Logon/Logoff events."
    }

    Write-Host -ForegroundColor Yellow "Parsing Security Event Logs for Failed Login events."
    Log-Write -LogPath $LogFile -LineValue "Parsing Security Event Logs for Failed Login events."

    $FailedLogin = Get-WinEvent -LogName 'Security' -FilterXPath "Event[System[EventID=4625]]" -ErrorAction SilentlyContinue | ForEach-Object {
        # convert the event to XML and grab the Event node
        $LogonSessionsEventXml = ([xml]$_.ToXml()).Event
        $LogonSessionsLogonUser = ($LogonSessionsEventXml.EventData.Data | Where-Object { $_.Name -eq 'TargetUserName' }).'#text'
        $LogonSessionsLogonUserDomain = ($LogonSessionsEventXml.EventData.Data | Where-Object { $_.Name -eq 'TargetDomainName' }).'#text'
        $LogonSessionsLogonIP = ($LogonSessionsEventXml.EventData.Data | Where-Object { $_.Name -eq 'IpAddress' }).'#text'
        $LogonSessionsLogonType = ($LogonSessionsEventXml.EventData.Data | Where-Object { $_.Name -eq 'LogonType' }).'#text'
        $LogonSessionsStatus = ($LogonSessionsEventXml.EventData.Data | Where-Object { $_.Name -eq 'Status' }).'#text'
        $LogonSessionsSubStatus = ($LogonSessionsEventXml.EventData.Data | Where-Object { $_.Name -eq 'SubStatus' }).'#text'
        [PSCustomObject]@{
            Time = [DateTime]$LogonSessionsEventXml.System.TimeCreated.SystemTime
            EventID = $LogonSessionsEventXml.System.EventID
            Category = $EventCategory_map[[int]$LogonSessionsEventXml.System.EventID]
            Message = $EventMessage_map[[int]$LogonSessionsEventXml.System.EventID]
            Status = $EventStatusCode_map[$LogonSessionsStatus]
            SubStatus = $EventStatusCode_map[$LogonSessionsSubStatus]
            LogonUser = $LogonSessionsLogonUser
            LogonUserDomain = $LogonSessionsLogonUserDomain
            LogonIP = $LogonSessionsLogonIP
            LogonType = $LogonType_map[[int]$LogonSessionsLogonType]
        }
    }

    If ($FailedLogin){
        $FailedLogin | Sort-Object Time | Export-Csv "$DFIRLogDir\Collection\Parsed_Event_Logs\Failed_Logins.csv" -NoTypeInformation
        Write-Host -ForegroundColor Green "COMPLETED: Parsed the Security Event Logs and extracted all Failed Login events."
        Log-Write -LogPath $LogFile -LineValue "COMPLETED: Parsed the Security Event Logs and extracted all Failed Login events."
    }Else {
        Write-Host -ForegroundColor Green "COMPLETED: Parsed the Security Event Logs and found NO Failed Login events."
        Log-Write -LogPath $LogFile -LineValue "COMPLETED: Parsed the Security Event Logs and found NO Failed Login events."
    }

    Write-Host -ForegroundColor Yellow "Parsing the Security Event Logs to extract all password reset attempt events."
    Log-Write -LogPath $LogFile -LineValue "Parsing the Security Event Logs to extract all password reset attempt events."

    $PasswordReset = Get-WinEvent -LogName 'Security' -FilterXPath "Event[System[EventID=4724]]" -ErrorAction SilentlyContinue | ForEach-Object {
        # convert the event to XML and grab the Event node
        $PassResetEventXml = ([xml]$_.ToXml()).Event
        $PassResetTargetUserName = ($PassResetEventXml.EventData.Data | Where-Object { $_.Name -eq 'TargetUserName' }).'#text'
        $PassResetTargetSID = ($PassResetEventXml.EventData.Data | Where-Object { $_.Name -eq 'TargetSid' }).'#text'
        $PassResetTargetDomain = ($PassResetEventXml.EventData.Data | Where-Object { $_.Name -eq 'TargetDomainName' }).'#text'
        $PassResetSubjectUserName = ($PassResetEventXml.EventData.Data | Where-Object { $_.Name -eq 'SubjectUserName' }).'#text'
        $PassResetSubjectUserSID = ($PassResetEventXml.EventData.Data | Where-Object { $_.Name -eq 'SubjectUserSid' }).'#text'
        [PSCustomObject]@{
            Time = [DateTime]$PassResetEventXml.System.TimeCreated.SystemTime
            EventID = $PassResetEventXml.System.EventID
            Category = $EventCategory_map[[int]$PassResetEventXml.System.EventID]
            Message = $EventMessage_map[[int]$PassResetEventXml.System.EventID]
            Keywords = $KeywordCode_map[ $PassResetEventXml.System.Keywords]
            TargetUserName = $PassResetTargetUserName
            TargetSID = $PassResetTargetSID
            TargetDomain = $PassResetTargetDomain
            SubjectUserName = $PassResetSubjectUserName
            SubjectUserSID = $PassResetSubjectUserSID
        }
    }

    If ($PasswordReset){
        $PasswordReset | Sort-Object Time | Export-Csv "$DFIRLogDir\Collection\Parsed_Event_Logs\Password_Reset.csv" -NoTypeInformation
        Write-Host -ForegroundColor Green "COMPLETED: Parsed the Security Event Logs and extracted all password reset attempt events."
        Log-Write -LogPath $LogFile -LineValue "COMPLETED: Parsed the Security Event Logs and extracted all password reset attempt events."
    }Else {
        Write-Host -ForegroundColor Green "COMPLETED: Parsed the Security Event Logs and found NO password reset attempt events."
        Log-Write -LogPath $LogFile -LineValue "COMPLETED: Parsed the Security Event Logs and found NO password reset attempt events."
    }

    Write-Host -ForegroundColor Yellow "Parsing the Security Event Logs to extract all processes that enumerated the local groups to which a the specified user belongs on the computer events."
    Log-Write -LogPath $LogFile -LineValue "Parsing the Security Event Logs to extract all processes that enumerated the local groups to which a the specified user belongs on the computer events."

    $GroupMembership = Get-WinEvent -LogName 'Security' -FilterXPath "Event[System[EventID=4798]]" -ErrorAction SilentlyContinue | ForEach-Object {
        # convert the event to XML and grab the Event node
        $GroupMembershipEventXml = ([xml]$_.ToXml()).Event
        $GroupMembershipTargetUserName = ($GroupMembershipEventXml.EventData.Data | Where-Object { $_.Name -eq 'TargetUserName' }).'#text'
        $GroupMembershipTargetSID = ($GroupMembershipEventXml.EventData.Data | Where-Object { $_.Name -eq 'TargetSid' }).'#text'
        $GroupMembershipTargetDomain = ($GroupMembershipEventXml.EventData.Data | Where-Object { $_.Name -eq 'TargetDomainName' }).'#text'
        $GroupMembershipSubjectUserName = ($GroupMembershipEventXml.EventData.Data | Where-Object { $_.Name -eq 'SubjectUserName' }).'#text'
        $GroupMembershipSubjectUserSID = ($GroupMembershipEventXml.EventData.Data | Where-Object { $_.Name -eq 'SubjectUserSid' }).'#text'
        $GroupMembershipCallerProcessId = ($GroupMembershipEventXml.EventData.Data | Where-Object { $_.Name -eq 'CallerProcessId' }).'#text'
        $GroupMembershipCallerProcessName = ($GroupMembershipEventXml.EventData.Data | Where-Object { $_.Name -eq 'CallerProcessName' }).'#text'
        [PSCustomObject]@{
            Time = [DateTime]$GroupMembershipEventXml.System.TimeCreated.SystemTime
            EventID = $GroupMembershipEventXml.System.EventID
            Category = $EventCategory_map[[int]$GroupMembershipEventXml.System.EventID]
            Message = $EventMessage_map[[int]$GroupMembershipEventXml.System.EventID]
            TargetUserName = $GroupMembershipTargetUserName
            TargetSID = $GroupMembershipTargetSID
            TargetDomain = $GroupMembershipTargetDomain
            SubjectUserName = $GroupMembershipSubjectUserName
            SubjectUserSID = $GroupMembershipSubjectUserSID
            CallerProcessId = $GroupMembershipCallerProcessId
            CallerProcessName = $GroupMembershipCallerProcessName
        }
    }

    If ($GroupMembership){
        $GroupMembership | Sort-Object Time | Export-Csv "$DFIRLogDir\Collection\Parsed_Event_Logs\Local_Group_Membership_Enumerated.csv" -NoTypeInformation
        Write-Host -ForegroundColor Green "COMPLETED: Parsed the Security Event Logs and extracted all processes that enumerated the local groups to which a the specified user belongs on the computer events."
        Log-Write -LogPath $LogFile -LineValue "COMPLETED: Parsed the Security Event Logs and extracted all processes that enumerated the local groups to which a the specified user belongs on the computer events."
    }Else {
        Write-Host -ForegroundColor Green "COMPLETED: Parsed the Security Event Logs and found NO processes that enumerated the local groups to which a the specified user belongs on the computer events."
        Log-Write -LogPath $LogFile -LineValue "COMPLETED: Parsed the Security Event Logs and found NO processes that enumerated the local groups to which a the specified user belongs on the computer events."
    }

    Write-Host -ForegroundColor Yellow "Parsing the Security Event Logs to extract all new user accounts created events."
    Log-Write -LogPath $LogFile -LineValue "Parsing the Security Event Logs to extract all new user accounts created events."

    $CreatedUsers = Get-WinEvent -LogName 'Security' -FilterXPath "Event[System[EventID=4720]]" -ErrorAction SilentlyContinue | ForEach-Object {
        # convert the event to XML and grab the Event node
        $CreatedUsersEventXml = ([xml]$_.ToXml()).Event
        $CreatedUsersTargetUserName = ($CreatedUsersEventXml.EventData.Data | Where-Object { $_.Name -eq 'TargetUserName' }).'#text'
        $CreatedUsersTargetSID = ($CreatedUsersEventXml.EventData.Data | Where-Object { $_.Name -eq 'TargetSid' }).'#text'
        $CreatedUsersTargetDomain = ($CreatedUsersEventXml.EventData.Data | Where-Object { $_.Name -eq 'TargetDomainName' }).'#text'
        $CreatedUsersSubjectUserName = ($CreatedUsersEventXml.EventData.Data | Where-Object { $_.Name -eq 'SubjectUserName' }).'#text'
        $CreatedUsersSubjectUserSID = ($CreatedUsersEventXml.EventData.Data | Where-Object { $_.Name -eq 'SubjectUserSid' }).'#text'
        [PSCustomObject]@{
            Time = [DateTime]$CreatedUsersEventXml.System.TimeCreated.SystemTime
            EventID = $CreatedUsersEventXml.System.EventID
            Category = $EventCategory_map[[int]$CreatedUsersEventXml.System.EventID]
            Message = $EventMessage_map[[int]$CreatedUsersEventXml.System.EventID]
            UserCreated = $CreatedUsersTargetUserName
            UserSID = $CreatedUsersTargetSID
            UserDomain = $CreatedUsersTargetDomain
            CreatedBy = $CreatedUsersSubjectUserName
            CreatedBySID = $CreatedUsersSubjectUserSID
        }
    }

    If ($CreatedUsers){
        $CreatedUsers | Sort-Object Time | Export-Csv "$DFIRLogDir\Collection\Parsed_Event_Logs\User_Accounts_Created.csv" -NoTypeInformation
        Write-Host -ForegroundColor Green "COMPLETED: Parsed the Security Event Logs and extracted all new user accounts created events."
        Log-Write -LogPath $LogFile -LineValue "COMPLETED: Parsed the Security Event Logs and extracted all new user accounts created events."
    }Else {
        Write-Host -ForegroundColor Green "COMPLETED: Parsed the Security Event Logs and found NO new user accounts created events."
        Log-Write -LogPath $LogFile -LineValue "COMPLETED: Parsed the Security Event Logs and found NO new user accounts created events."
    }

    Write-Host -ForegroundColor Yellow "Parsing the Security Event Logs to extract all user accounts that have been added to a group events."
    Log-Write -LogPath $LogFile -LineValue "Parsing the Security Event Logs to extract all user accounts that have been added to a group events."

    $UserAddedGroup = Get-WinEvent -LogName 'Security' -FilterXPath "(Event[System[EventID=4728]] or Event[System[EventID=4732]])" -ErrorAction SilentlyContinue | ForEach-Object {
        # convert the event to XML and grab the Event node
        $UserAddedGroupEventXml = ([xml]$_.ToXml()).Event
        $UserAddedGroupMemberSID = ($UserAddedGroupEventXml.EventData.Data | Where-Object { $_.Name -eq 'MemberSid' }).'#text'
        #$UserAddedGroupobjSID = New-Object System.Security.Principal.SecurityIdentifier($UserAddedGroupMemberSID)
        #$UserAddedGroupobjUser = $UserAddedGroupobjSID.Translate([System.Security.Principal.NTAccount])
        $UserAddedGroupTargetDomain = ($UserAddedGroupEventXml.EventData.Data | Where-Object { $_.Name -eq 'TargetDomainName' }).'#text'
        $UserAddedGroupSubjectUserName = ($UserAddedGroupEventXml.EventData.Data | Where-Object { $_.Name -eq 'SubjectUserName' }).'#text'
        $UserAddedGroupSubjectUserSID = ($UserAddedGroupEventXml.EventData.Data | Where-Object { $_.Name -eq 'SubjectUserSid' }).'#text'
        [PSCustomObject]@{
            Time = [DateTime]$UserAddedGroupEventXml.System.TimeCreated.SystemTime
            EventID = $UserAddedGroupEventXml.System.EventID
            Category = $EventCategory_map[[int]$UserAddedGroupEventXml.System.EventID]
            Message = $EventMessage_map[[int]$UserAddedGroupEventXml.System.EventID]
            #UserModified = $UserAddedGroupobjUser
            UserSIDModified = $UserAddedGroupMemberSID
            UserDomain = $UserAddedGroupTargetDomain
            AddedByUser = $UserAddedGroupSubjectUserName
            AddedByUserSID = $UserAddedGroupSubjectUserSID
        }
        $UserAddedGroupobjUser = ''
    }

    If ($UserAddedGroup){
        $UserAddedGroup | Sort-Object Time | Export-Csv "$DFIRLogDir\Collection\Parsed_Event_Logs\User_Group_Membership_Modified.csv" -NoTypeInformation
        Write-Host -ForegroundColor Green "COMPLETED: Parsed the Security Event Logs and extracted all user accounts that have been added to a group events."
        Log-Write -LogPath $LogFile -LineValue "COMPLETED: Parsed the Security Event Logs and extracted all user accounts that have been added to a group events."
    }Else {
        Write-Host -ForegroundColor Green "COMPLETED: Parsed the Security Event Logs and found NO user accounts that have been added to a group created events."
        Log-Write -LogPath $LogFile -LineValue "COMPLETED: Parsed the Security Event Logs and found NO user accounts that have been added to a group created events."
    }

    Write-Host -ForegroundColor Yellow "Parsing the Security Event Logs to extract all user accounts that have been enabled events."
    Log-Write -LogPath $LogFile -LineValue "Parsing the Security Event Logs to extract all user accounts that have been enabled events."

    $EnabledUser = Get-WinEvent -LogName 'Security' -FilterXPath "Event[System[EventID=4722]]" -ErrorAction SilentlyContinue | ForEach-Object {
        # convert the event to XML and grab the Event node
        $EnabledUserEventXml = ([xml]$_.ToXml()).Event
        $EnabledUserTargetUserName = ($EnabledUserEventXml.EventData.Data | Where-Object { $_.Name -eq 'TargetUserName' }).'#text'
        $EnabledUserTargetSID = ($EnabledUserEventXml.EventData.Data | Where-Object { $_.Name -eq 'TargetSid' }).'#text'
        $EnabledUserTargetDomain = ($EnabledUserEventXml.EventData.Data | Where-Object { $_.Name -eq 'TargetDomainName' }).'#text'
        $EnabledUserSubjectUserName = ($EnabledUserEventXml.EventData.Data | Where-Object { $_.Name -eq 'SubjectUserName' }).'#text'
        $EnabledUserSubjectUserSID = ($EnabledUserEventXml.EventData.Data | Where-Object { $_.Name -eq 'SubjectUserSid' }).'#text'
        [PSCustomObject]@{
            Time = [DateTime]$EnabledUserEventXml.System.TimeCreated.SystemTime
            EventID = $EnabledUserEventXml.System.EventID
            Category = $EventCategory_map[[int]$EnabledUserEventXml.System.EventID]
            Message = $EventMessage_map[[int]$EnabledUserEventXml.System.EventID]
            UserEnabled = $EnabledUserTargetUserName
            UserSID = $EnabledUserTargetSID
            UserDomain = $EnabledUserTargetDomain
            EnabledByUser = $EnabledUserSubjectUserName
            EnabledByUserSID = $EnabledUserSubjectUserSID
        }
    }

    If ($EnabledUser){
        $EnabledUser | Sort-Object Time | Export-Csv "$DFIRLogDir\Collection\Parsed_Event_Logs\User_Accounts_Enabled.csv" -NoTypeInformation
        Write-Host -ForegroundColor Green "COMPLETED: Parsed the Security Event Logs and extracted all user accounts that have been enabled events."
        Log-Write -LogPath $LogFile -LineValue "COMPLETED: Parsed the Security Event Logs and extracted all user accounts that have been enabled events."
    }Else {
        Write-Host -ForegroundColor Green "COMPLETED: Parsed the Security Event Logs and found NO user accounts that have been enabled events."
        Log-Write -LogPath $LogFile -LineValue "COMPLETED: Parsed the Security Event Logs and found NO user accounts that have been enabled events."
    }

    Write-Host -ForegroundColor Yellow "Parsing the Security Event Logs to extract all user accounts that have been deleted events."
    Log-Write -LogPath $LogFile -LineValue "Parsing the Security Event Logs to extract all user accounts that have been deleted events."

    $DeletedUser = Get-WinEvent -LogName 'Security' -FilterXPath "Event[System[EventID=4726]]" -ErrorAction SilentlyContinue | ForEach-Object {
        # convert the event to XML and grab the Event node
        $DeletedUserEventXml = ([xml]$_.ToXml()).Event
        $DeletedUserTargetUserName = ($DeletedUserEventXml.EventData.Data | Where-Object { $_.Name -eq 'TargetUserName' }).'#text'
        $DeletedUserTargetSID = ($DeletedUserEventXml.EventData.Data | Where-Object { $_.Name -eq 'TargetSid' }).'#text'
        $DeletedUserTargetDomain = ($DeletedUserEventXml.EventData.Data | Where-Object { $_.Name -eq 'TargetDomainName' }).'#text'
        $DeletedUserSubjectUserName = ($DeletedUserEventXml.EventData.Data | Where-Object { $_.Name -eq 'SubjectUserName' }).'#text'
        $DeletedUserSubjectUserSID = ($DeletedUserEventXml.EventData.Data | Where-Object { $_.Name -eq 'SubjectUserSid' }).'#text'
        [PSCustomObject]@{
            Time = [DateTime]$DeletedUserEventXml.System.TimeCreated.SystemTime
            EventID = $DeletedUserEventXml.System.EventID
            Category = $EventCategory_map[[int]$DeletedUserEventXml.System.EventID]
            Message = $EventMessage_map[[int]$DeletedUserEventXml.System.EventID]
            UserDeleted = $DeletedUserTargetUserName
            UserSID = $DeletedUserTargetSID
            UserDomain = $DeletedUserTargetDomain
            DeletedByUser = $DeletedUserSubjectUserName
            DeletedByUserSID = $DeletedUserSubjectUserSID
        }
    }

    If ($DeletedUser){
        $DeletedUser | Sort-Object Time | Export-Csv "$DFIRLogDir\Collection\Parsed_Event_Logs\User_Accounts_Deleted.csv" -NoTypeInformation
c
    }Else {
        Write-Host -ForegroundColor Green "COMPLETED: Parsed the Security Event Logs and found NO user accounts that have been deleted events."
        Log-Write -LogPath $LogFile -LineValue "COMPLETED: Parsed the Security Event Logs and found NO user accounts that have been deleted events."
    }

    $SectionCompletion2 = (Get-Date)
    Write-Host -ForegroundColor Green "Done"
    Log-Write -LogPath $LogFile -LineValue "Completed Parsing Event Logs."
    Log-Write -LogPath $LogFile -LineValue "Total processing time $(($SectionCompletion2-$SectionCompletion).totalseconds) seconds."
    $SectionCompletion = $SectionCompletion2
    Add-Content -Path $LogFile -Value "---------------------------------------------------------------------------------------------------"
}Else {
    Write-Host -ForegroundColor Green "WARNING: Eventlogs was not parsed as the parameter was specified."
    Log-Write -LogPath $LogFile -LineValue "WARNING: Eventlogs was not parsed as the parameter was specified."
}
#endregion

###############################################################################
#region Export MFT for all fixed drives                                       #
###############################################################################
If ($MFT -eq 'yes'){
    If (!(Test-Path "$DFIRLogDir\Collection\MFT")){
        New-Item "$DFIRLogDir\Collection\MFT" -ItemType Directory | Out-Null
        Write-Host -ForegroundColor Yellow "Created Directory: $DFIRLogDir\Collection\MFT"
        Log-Write -LogPath $LogFile -LineValue "Created Directory: $DFIRLogDir\Collection\MFT"
    }
    Write-Host -ForegroundColor Yellow "Exporting MFT to CSV for All Local Disk."
    Log-Write -LogPath $LogFile -LineValue "Exporting MFT to CSV for All Local Disk."
    $DRIVE_LETTERS = (Get-PSDrive -PSProvider FileSystem).Root

    ForEach ($DRIVE in $DRIVE_LETTERS){
        $VOLTYPE = (Get-Volume -DriveLetter $DRIVE[0] -ErrorAction SilentlyContinue).DriveType
        If (($VOLTYPE) -And ($VOLTYPE -eq "Fixed")){
            Start-Process "PowerShell.exe" -ArgumentList "-ExecutionPolicy Bypass -Command `"Import-Module `"$IRDir\Tools\PowerForensics\PowerForensicsv2.dll`" -Force;`"Get-ForensicFileRecord -VolumeName $($DRIVE[0]+$DRIVE[1]) | Export-Csv `"$DFIRLogDir\Collection\MFT\Exported_MFT_Drive_$($DRIVE[0]).csv`" -NoTypeInformation`"`"" -Wait -WindowStyle Hidden
        }
    }
    Write-Host -ForegroundColor Green "COMPLETED: Exported MFT for all local disks."
    Log-Write -LogPath $LogFile -LineValue "COMPLETED: Exported MFT for all local disks."
<#    Write-Host -ForegroundColor Yellow "Archiving exported MFT files. Archive is split into files no larger than 1.5GB."
    If($OS64bit) {
        Start-Process "$IRDir\Tools\7z.exe" -ArgumentList "a -mx1 -tzip -v1500m `"$IRDir\Collection_MFT_${LogDate}_${Name}.zip`" `"$IRDir\MFT_${Name}`" -p$7ZPASSWORD" -Wait -WindowStyle Hidden
    }Else {
        Start-Process "$IRDir\Tools\7z.exe" -ArgumentList "a -mx1 -tzip -v1500m `"$IRDir\Collection_MFT_${LogDate}_${Name}.zip`" `"$IRDir\MFT_${Name}`" -p$7ZPASSWORD" -Wait -WindowStyle Hidden
    }
    
    Write-Host -ForegroundColor Green "COMPLETED: All exported MFT files have been archived '$IRDir\Collection_MFT_${LogDate}_${Name}.zip.001'.`nIf the archive was larger than 1.5GB, then there will be multiple ZIP files with the same filename, but the number at the end will increase 002, 003, and etc..."
#>
}Else {
    Write-Host -ForegroundColor Green "WARNING: MFT was not collected as the parameter was set to 'no'."
    Log-Write -LogPath $LogFile -LineValue "WARNING: MFT was not collected as the parameter was set to 'no'."
}

    $SectionCompletion2 = (Get-Date)
    Write-Host -ForegroundColor Green "Done"
    Log-Write -LogPath $LogFile -LineValue "COMPLETED: Exported MFT for all local disks."
    Log-Write -LogPath $LogFile -LineValue "Total processing time $(($SectionCompletion2-$SectionCompletion).totalseconds) seconds."
    $SectionCompletion = $SectionCompletion2
    Add-Content -Path $LogFile -Value "---------------------------------------------------------------------------------------------------"

#endregion

Log-Finish -LogPath $LogFile

###############################################################################
#region Creating ZIP Archive of Forensic Artifacts Collected                  #
###############################################################################

Write-Host -ForegroundColor Yellow "Archiving forensic artifacts collected. Archive is split into files no larger than 1.5GB."
    If($OS64bit) {
        Start-Process "$IRDir\Tools\7z.exe" -ArgumentList "a -mx1 -tzip -v1500m `"$IRDir\Collection_${LogDate}_${Name}.zip`" $DFIRLogDir -p$7ZPASSWORD" -Wait -WindowStyle Hidden
    }Else {
        Start-Process "$IRDir\Tools\7z.exe" -ArgumentList "a -mx1 -tzip -v1500m `"$IRDir\Collection_${LogDate}_${Name}.zip`" $DFIRLogDir -p$7ZPASSWORD" -Wait -WindowStyle Hidden
    }



Write-Host -ForegroundColor Green "COMPLETED: All forensic artifact have been archived '$IRDir\Collection_${LogDate}_${Name}.zip.001'.`nIf the archive was larger than 1.5GB, then there will be multiple ZIP files with the same filename, but the number at the end will increase 002, 003, and etc..."

Remove-Item "$DFIRLogDir" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
Start-Process "C:\Windows\System32\cmd.exe" -ArgumentList "/c `"rmdir /S /Q $DFIRLogDir`"" -Wait -WindowStyle Hidden
Remove-Item "$IRDir\DFIR_LogCollector*.zip" -Force -ErrorAction SilentlyContinue | Out-Null

#endregion

###############################################################################
#region Dump Running Processes                                                #
###############################################################################

If ($PROCESSES -eq 'yes'){
    If (!(Test-Path "$IRDir\ProcessCapture_${Name}")){
        New-Item "$IRDir\ProcessCapture_${Name}" -ItemType Directory | Out-Null
        Write-Host -ForegroundColor Yellow "Created Directory: $IRDir\ProcessCapture_${Name}"
    }

    $TOTALFREEDISKSPACE = (Get-Volume -DriveLetter C).SizeRemaining

    Write-Host -ForegroundColor Yellow "Dumping all running processes."

    #Checks if the Root Drive has enough free disk space for dumping all processes (Greater than 10GB (10737418240))
    IF ($TOTALFREEDISKSPACE -gt 10737418240){
        Start-Process "$IRDir\Tools\MagnetProcessCapture.exe" -ArgumentList "/saveallsilent `"$IRDir\ProcessCapture_${Name}`"" -Wait -WindowStyle Hidden
    }

    Write-Host -ForegroundColor Yellow "Archiving dumped processes captured. Archive is split into files no larger than 1.5GB."
    If($OS64bit) {
        Start-Process "$IRDir\Tools\7z.exe" -ArgumentList "a -mx1 -tzip -v1500m `"$IRDir\Collection_DUMPED_PROCESSES_${LogDate}_${Name}.zip`" `"$IRDir\ProcessCapture_${Name}`" -p$7ZPASSWORD" -Wait -WindowStyle Hidden
    }Else {
        Start-Process "$IRDir\Tools\7z.exe" -ArgumentList "a -mx1 -tzip -v1500m `"$IRDir\Collection_DUMPED_PROCESSES_${LogDate}_${Name}.zip`" `"$IRDir\ProcessCapture_${Name}`" -p$7ZPASSWORD" -Wait -WindowStyle Hidden
    }
    Write-Host -ForegroundColor Green "COMPLETED: Dumped all running processes and have been archived 'C:\DFIRLog\Collection_DUMPED_PROCESSES_${LogDate}_${Name}.zip.001'.`nIf the archive was larger than 1.5GB, then there will be multiple ZIP files with the same filename, but the number at the end will increase 002, 003, and etc..."
}Else {
    Write-Host -ForegroundColor Green "WARNING: Processes were not dumped as the parameter was not specified."
}

#endregion

###############################################################################
#region Network Traffic Capture and compress PCAP into a password protected   #
# ZIP file. Split ZIP every 1.5GB.                                            #
###############################################################################
If ($PCAP -eq 'yes'){
    If (!(Test-Path "$IRDir\PCAP_${Name}")){
        New-Item "$IRDir\PCAP_${Name}" -ItemType Directory | Out-Null
        Write-Host -ForegroundColor Yellow "Created Directory: $IRDir\PCAP_${Name}"
    }
    $TRACEFILE = "$IRDir\PCAP_${Name}\${LogDate}_${Name}_netrace.etl"
    Write-Host -ForegroundColor Yellow "Starting Network Trace Collection. Collection set for 5 minutes."

    New-NetEventSession -Name "Capture" -CaptureMode SaveToFile -LocalFilePath $TRACEFILE | Out-Null
    Add-NetEventPacketCaptureProvider -SessionName "Capture" -Level 5 -CaptureType BothPhysicalAndSwitch -EtherType 0x0800 | Out-Null
    $CAPTURE = Start-NetEventSession -Name "Capture" | Out-Null

    Start-Sleep -Seconds 300
    Stop-NetEventSession -Name "Capture"
    Remove-NetEventSession -Name "Capture"

    Write-Host -ForegroundColor Green "COMPLETED: Network Trace Complete."
    Write-Host -ForegroundColor Yellow "Converting ETL to PCAP file."

    Start-Process "$IRDir\Tools\etl2pcapng.exe" -ArgumentList "$TRACEFILE `"$IRDir\PCAP_${Name}\${LogDate}_${Name}_PCAP.pcap`"" -Wait -WindowStyle Hidden
    Write-Host -ForegroundColor Green "COMPLETED: Converted ETL to PCAP file."
    Write-Host -ForegroundColor Yellow "Compressing the directory '$IRDir\PCAP_${Name}\' into a password protected ZIP file."

    Write-Host -ForegroundColor Yellow "Archiving PCAP Collected. Archive is split into files no larger than 1.5GB."
    If($OS64bit) {
        Start-Process "$IRDir\Tools\7z.exe" -ArgumentList "a -mx1 -tzip -v1500m `"$IRDir\Collection_PCAP_${LogDate}_${Name}.zip`" `"$IRDir\PCAP_${Name}`" -p$7ZPASSWORD" -Wait -WindowStyle Hidden
    }Else {
        Start-Process "$IRDir\Tools\7z.exe" -ArgumentList "a -mx1 -tzip -v1500m `"$IRDir\Collection_PCAP_${LogDate}_${Name}.zip`" `"$IRDir\PCAP_${Name}`" -p$7ZPASSWORD" -Wait -WindowStyle Hidden
    }
    Write-Host -ForegroundColor Green "COMPLETED: Compressed the PCAP directory and have been archived 'C:\DFIRLog\Collection_PCAP_${LogDate}_${Name}.zip.001'.`nIf the archive was larger than 1.5GB, then there will be multiple ZIP files with the same filename, but the number at the end will increase 002, 003, and etc..."
}Else {
    Write-Host -ForegroundColor Green "WARNING: PCAP was not collected on the host as the parameter was not specified."
}
#endregion

###############################################################################
#region RAM Capturing                                                         #
###############################################################################

If ($RAM -eq 'yes'){
    If (!(Test-Path "$IRDir\RAM_${Name}")){
        New-Item "$IRDir\RAM_${Name}" -ItemType Directory | Out-Null
        Write-Host -ForegroundColor Yellow "Created Directory: '$IRDir\RAM_${Name}'."
    }
    
    $TOTALRAMSIZE = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).sum
    $TOTALFREEDISKSPACE = (Get-Volume -DriveLetter C).SizeRemaining

    Write-Host -ForegroundColor Yellow "Dumping RAM. This process could take a while depending on how much memory is installed."

    #Checks if the Root Drive has enough free disk space for RAM  (Greater than 1GB (1073741824))
    IF (($TOTALFREEDISKSPACE - $TOTALRAMSIZE) -gt 1073741824){
        Start-Process "$IRDir\Tools\MagnetRAMCapture.exe" -ArgumentList "/accepteula /go `"$IRDir\RAM_${Name}\RAM_${Name}.raw`" /silent" -Wait -WindowStyle Hidden
    }Else {
        Write-Host -ForegroundColor Red "ERROR: There is not enough free disk space available on the C: drive to capture RAM."
    }

    Write-Host -ForegroundColor Yellow "Archiving RAM dump file. Archive is split into files no larger than 1.5GB."
    If($OS64bit) {
        Start-Process "$IRDir\Tools\7z.exe" -ArgumentList "a -mx1 -tzip -v1500m `"$IRDir\Collection_RAM_${LogDate}_${Name}.zip`" `"$IRDir\RAM_${Name}`" -p$7ZPASSWORD" -Wait -WindowStyle Hidden
    }Else {
        Start-Process "$IRDir\Tools\7z.exe" -ArgumentList "a -mx1 -tzip -v1500m `"$IRDir\Collection_RAM_${LogDate}_${Name}.zip`" `"$IRDir\RAM_${Name}`" -p$7ZPASSWORD" -Wait -WindowStyle Hidden
    }

    Write-Host -ForegroundColor Green "COMPLETED: RAM was successfully dumped to a RAW file and have been archived 'C:\DFIRLog\Collection_RAM_${LogDate}_${Name}.zip.001'.`nIf the archive was larger than 1.5GB, then there will be multiple ZIP files with the same filename, but the number at the end will increase 002, 003, and etc..."
}Else {
    Write-Host -ForegroundColor Green "WARNING: RAM was not dumped as the parameter was not specified."
}

#endregion

###############################################################################
#region Search for Known Ransomware File Extensions                           #
###############################################################################

If ($RANSOMWARE -eq 'yes'){
    If (!(Test-Path "$IRDir\Ransomware_${Name}")){
        New-Item "$IRDir\Ransomware_${Name}" -ItemType Directory | Out-Null
        Write-Host -ForegroundColor Yellow "Created Directory: $IRDir\Ransomware_${Name}"
    }

    Write-Host -ForegroundColor Yellow "Searching for known RANSOMWARE file extensions."

    $DRIVE_LETTERS = (Get-PSDrive -PSProvider FileSystem).Root
    $RANSOMWAREFILES = @()

    ForEach ($DRIVE in $DRIVE_LETTERS){
        $VOLTYPE = (Get-Volume -DriveLetter $DRIVE[0] -ErrorAction SilentlyContinue).DriveType
        $VOLSIZE = (Get-Volume -DriveLetter $DRIVE[0] -ErrorAction SilentlyContinue).Size
        If (($VOLTYPE -And $VOLSIZE) -And ($VOLSIZE -lt 2684354560000) -And ($VOLTYPE -eq "Fixed")){
            $RANSOMWAREFILES += Get-ChildItem -Path "$DRIVE" -Include *._AiraCropEncrypted,*.1cbu1,*.1txt,*.73i87A,*.a5zfn,*.aaa,*.abc,*.adk,*.aesir,*.alcatraz,*.angelamerkel,*.AngleWare,*.antihacker2017,*.atlas,*.axx,*.BarRax,*.bitstak,*.braincrypt,*.breaking_bad,*.bript,*.btc,*.ccc,*.CCCRRRPPP,*.cerber,*.cerber2,*.cerber3,*.coded,*.comrade,*.conficker,*.coverton,*.crab,*.crinf,*.crjoker,*.crptrgr,*.cry,*.cryeye,*.cryp1,*.crypt,*.crypte,*.crypted,*.cryptolocker,*.cryptowall,*.crypz,*.czvxce,*.d4nk,*.dale,*.damage,*.darkness,*.dCrypt,*.decrypt2017,*.Dexter,*.dharma,*.dxxd,*.ecc,*.edgel,*.enc,*.enc,*.enciphered,*.EnCiPhErEd,*.encr,*.encrypt,*.encrypted,*.encrypted,*.encrypted,*.enigma,*.evillock,*.exotic,*.exx,*.ezz,*.fantom,*.file0locked,*.fucked,*.fun,*.fun,*.gefickt,*.globe,*.good,*.grt,*.ha3,*.helpmeencedfiles,*.herbst,*.hnumkhotep,*.hush,*.ifuckedyou,*.info,*.kernel_complete,*.kernel_pid,*.kernel_time,*.keybtc@inbox_com,*.kimcilware,*.kkk,*.kostya,*.kraken,*.kratos,*.kyra,*.lcked,*.LeChiffre,*.legion,*.lesli,*.lock93,*.locked,*.locklock,*.locky,*.lol!,*.loli,*.lovewindows,*.madebyadam,*.magic,*.maya,*.MERRY,*.micro,*.mole,*.MRCR1,*.noproblemwedecfiles​,*.nuclear55,*.odcodc,*.odin,*.onion,*.oops,*.osiris,*.p5tkjw,*.padcrypt,*.paym,*.paymrss,*.payms,*.paymst,*.paymts,*.payrms,*.pays,*.pdcr,*.pec,*.PEGS1,*.perl,*.PoAr2w,*.potato,*.powerfulldecrypt,*.pubg,*.purge,*.pzdc,*.R16m01d05,*.r5a,*.raid10,*.RARE1,*.razy,*.rdm,*.realfs0ciety@sigaint.org.fs0ciety,*.rekt,*.rekt,*.rip,*.RMCM1,*.rmd,*.rnsmwr,*.rokku,*.rrk,*.ruby,*.sage,*.SecureCrypted,*.serp,*.serpent,*.sexy,*.shit,*.spora,*.stn,*.surprise,*.szf,*.theworldisyours,*.thor,*.ttt,*.unavailable,*.vbransom,*.venusf,*.VforVendetta,*.vindows,*.vvv,*.vxlock,*.wallet,*.wcry,*.wflx,*.Whereisyourfiles,*.windows10,*.xxx,*.xxx,*.xyz,*.ytbl,*.zcrypt,*.zepto,*.zorro,*.zyklon,*.zzz,*.zzzzz -File -Recurse -ErrorAction SilentlyContinue -Force | Select-Object FullName
        }Else {
            Write-Host -ForegroundColor Green "Did not search drive $DRIVE as the size of the disk is more than 2.5TB."
        }
    }

    If ($RANSOMWAREFILES){
        $RANSOMWAREFILES | Export-Csv "$IRDir\Ransomware_${Name}\${Name}_List_of_All_Possible_RANSOMWARE_Files.csv" -NoTypeInformation
        Write-Host -ForegroundColor Green "COMPLETED: Searched for all known RANSOMWARE file extensions."

        Write-Host -ForegroundColor Yellow "Archiving list of possible RANSOMWARE files. Archive is split into files no larger than 1.5GB."
        If($OS64bit) {
            Start-Process "$IRDir\Tools\7z.exe" -ArgumentList "a -mx1 -tzip -v1500m `"$IRDir\Collection_RANSOMWARE_FILE_LIST_${LogDate}_${Name}.zip`" `"$IRDir\Ransomware_${Name}`" -p$7ZPASSWORD" -Wait -WindowStyle Hidden
        }Else {
            Start-Process "$IRDir\Tools\7z.exe" -ArgumentList "a -mx1 -tzip -v1500m `"$IRDir\Collection_RANSOMWARE_FILE_LIST_${LogDate}_${Name}.zip`" `"$IRDir\Ransomware_${Name}`" -p$7ZPASSWORD" -Wait -WindowStyle Hidden
        }
        Write-Host -ForegroundColor Green "COMPLETED: Searched for known RANSOMWARE file extension and have been archived 'C:\DFIRLog\Collection_RANSOMWARE_FILE_LIST_${LogDate}_${Name}.zip.001'.`nIf the archive was larger than 1.5GB, then there will be multiple ZIP files with the same filename, but the number at the end will increase 002, 003, and etc..."
    }Else {
        Write-Host -ForegroundColor Green "COMPLETED: No known RANSOMWARE file extensions were found."
    }
}Else {
    Write-Host -ForegroundColor Green "WARNING: Did not search for known RANSOMWARE file extensions as the parameter was not specified."
}

#endregion

###############################################################################
#region Clean-up                                                              #
###############################################################################

Write-Host -ForegroundColor Yellow "Cleaning up Tools and artifacts folder."
Write-Host -ForegroundColor Yellow "Remove PowerForensic DLL module."

Write-Host -ForegroundColor Yellow "Reset Power Configuration settings."
powercfg /x standby-timeout-ac 20
powercfg /x monitor-timeout-ac 5

Start-Sleep -Seconds 15

Write-Host -ForegroundColor Yellow "Cleaning up folders/Files in the directory '$IRDir'."
Remove-Item "$IRDir\MFT_${Name}\" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
Remove-Item "$IRDir\RAM_${Name}\" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
Remove-Item "$IRDir\ProcessCapture_${Name}\" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
Remove-Item "$IRDir\PCAP_${Name}\" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
Remove-Item "$IRDir\Ransomware_${Name}" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
Remove-Item "$DFIRLogDir" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
Start-Process "C:\Windows\System32\cmd.exe" -ArgumentList "/c `"rmdir /S /Q $DFIRLogDir`"" -Wait -WindowStyle Hidden
Remove-Item "$IRDir\Tools" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
Remove-Item "$IRDir\DFIR_LogCollector*.zip" -Force -ErrorAction SilentlyContinue | Out-Null

#Self Destruct (Deletes itself)
$DEL = Remove-Item -Path $MyInvocation.MyCommand.Source -ErrorAction SilentlyContinue | Out-Null
$DEL = Remove-Item -Path "$ScriptDir\DFIR-LOG_COLLECTOR.ps1" -Force -ErrorAction SilentlyContinue | Out-Null

$PSLog = Get-ItemProperty -Path "HKLM:SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription\" -ErrorAction SilentlyContinue
If (($PSlog.EnableTranscripting -eq 1 ) -and ($PSlog.EnableTranscripting)){
    $PSOutputDir = $PSlog.OutputDirectory + '\' + $StartTime.ToString('yyyMMdd')
    Start-Process 'cmd.exe' -ArgumentList "/c timeout 10 & for /f `"eol=: delims=`" %F in ('findstr /M /I `"C:\DFIRLog`" $PSOutputDir\*.*') do del /f `"%F`"" -WindowStyle Hidden 
}

Remove-Variable * -ErrorAction SilentlyContinue -Force

#endregion

EXIT