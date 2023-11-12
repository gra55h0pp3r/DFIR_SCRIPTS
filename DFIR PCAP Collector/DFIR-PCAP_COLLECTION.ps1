<#
.SYNOPSIS
    Captures network traffic (PCAP) on system, then compresses file into a password protected ZIP file that is split every 1.5GB.
.DESCRIPTION
    This sript will collect network traffic utilizing built-in Windows tool, converts ETL file to PCAP, then compresses PCAP 
    file into a password protected ZIP that is split every 1.5GB. (Default Password: infected)
.INPUTS
    Enter in the amount of time to collect network traffic for between 1-10 minutes. (default 2 minutes)
.OUTPUTS
    None
.NOTES
    Version:        1.0
    Author:         Elite Grassh0pp3r
    Creation Date:  11/11/2023
    Purpose/Change: Initial creation of the script to capture networ traffic and compress PCAP folder to a password protected ZIP file.
.EXAMPLE
    Powershell Command Prompt: DFIR-PCAP_COLLECTION.ps1
    MDE: run DFIR-PCAP_COLLECTION.ps1
#>

[cmdletbinding()]
Param(
    [Parameter(Mandatory=$false,Position=0,HelpMessage='Enter in the amount of time to collect network traffic for between 1-10 minutes. (default 2 minutes)')]
        [Int][ValidateRange(1,15)]$XMIN='2'
)

Set-ExecutionPolicy Bypass

$StartTime = Get-Date
$Name = $env:computername
$OS64bit = [Environment]::Is64BitOperatingSystem
$LogDate = $StartTime.ToString('yyyMMdd_HHmmss')
$ScriptDir = $PSScriptRoot
$ZIPFile = "C:\DFIRLog\${LogDate}_${Name}_PCAP.zip"
$DFIRLogDir = "C:\DFIRLog"
$ScriptVersion = 1.0

$Logo = @"
    ____  _______________________    __       __________  ____  _______   _______ _______________
   / __ \/  _/ ____/  _/_  __/   |  / /      / ____/ __ \/ __ \/ ____/ | / / ___//  _/ ____/ ___/
  / / / // // / __ / /  / / / /| | / /      / /_  / / / / /_/ / __/ /  |/ /\__ \ / // /    \__ \
 / /_/ // // /_/ // /  / / / ___ |/ /___   / __/ / /_/ / _, _/ /___/ /|  /___/ // // /___ ___/ /
/_____/___/\____/___/ /_/ /_/  |_/_____/  /_/    \____/_/ |_/_____/_/ |_//____/___/\____//____/

    _____   ________________  _______   ________   ___  ___________ ____  ____  _   _______ ______
   /  _/ | / / ____/  _/ __ \/ ____/ | / /_  __/  /__ \/ ____/ ___// __ \/ __ \/ | / / ___// ____/
   / //  |/ / /    / // / / / __/ /  |/ / / /    / /_/ / __/  \__ \/ /_/ / / / /  |/ /\__ \/ __/  
 _/ // /|  / /____/ // /_/ / /___/ /|  / / /    / _, _/ /___ ___/ / ____/ /_/ / /|  /___/ / /___  
/___/_/ |_/\____/___/_____/_____/_/ |_/ /_/    /_/ |_/_____//____/_/    \____/_/ |_//____/_____/


                                                          Script Version $ScriptVersion
                                                          POC: Elite Grassh0pp3r


"@

Write-Host $Logo -ForegroundColor Green
Write-Host "PowerShell version: $($PSVersionTable.PSVersion)`n`n"

###############################################################################
#region Create Directories DFIRLog and RAM                                      #
###############################################################################

If (!(Test-Path $DFIRLogDir)){
    New-Item "$DFIRLogDir" -ItemType Directory | Out-Null
    Start-Process "C:\Windows\System32\attrib.exe" -ArgumentList "+S +R +H $DFIRLogDir" -Wait -WindowStyle Hidden
    Write-Host -ForegroundColor Yellow "Created Directory: '$DFIRLogDir'."
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

If (!(Test-Path $DFIRLogDir\Tools)){
    New-Item "$DFIRLogDir\Tools" -ItemType Directory | Out-Null
    Write-Host -ForegroundColor Yellow "Created Directory: '$DFIRLogDir\Tools'."
}

New-Item "$DFIRLogDir\${LogDate}_${Name}_PCAP" -ItemType Directory | Out-Null
Write-Host -ForegroundColor Yellow "Created Directory: '$DFIRLogDir\${LogDate}_${Name}_PCAP'."


#endregion

###############################################################################
#region Base64 decode DFIRTOOLS and write ZIP file to current script directory#
###############################################################################
Write-Host -ForegroundColor Yellow "Decoding and writing ZIP file 'DFIR_LogCollector_Tools.zip' to current script directory '${DFIRLogDir}'."

#Base64 Encode string of DFIR_LogCollector_Tools.zip

#Base64 decode variable $DFIRTOOLS and write ZIP file to current script directory
$BINARY = [Convert]::FromBase64String($DFIRTOOLS)
Set-Content -Path "$DFIRLogDir\DFIR_LogCollector_Tools_PCAP.zip" -Value $BINARY -Encoding Byte | Out-Null

Write-Host -ForegroundColor Green "COMPLETED: Decoded and wrote ZIP file 'DFIR_LogCollector_Tools.zip' to current script directory '${DFIRLogDir}'."

Start-Sleep -Seconds 5

#Checks if the ZIP file 'DFIR_LogCollector_Tools_PCAP.zip' exists in the current script directory
If (!(Test-Path "$DFIRLogDir\DFIR_LogCollector_Tools_PCAP.zip")){
    Write-Host -ForegroundColor Red "ERROR: The required tools ZIP file 'DFIR_LogCollector_Tools_PCAP.zip' does not exists and could not be decoded and extracted from script."
    EXIT
}

#Extract the necessary files to $DFIRLogDir\Tools
Write-Host -ForegroundColor Yellow "Extracting additional required tools from file DFIR_LogCollector_Tools_PCAP.zip."
Expand-Archive -Path "$DFIRLogDir\DFIR_LogCollector_Tools_PCAP.zip" -DestinationPath "$DFIRLogDir\" -Force
Write-Host -ForegroundColor Green "COMPLETED: Extracted necessary files to '$DFIRLogDir\Tools'."

Start-Sleep -Seconds 5

#endregion

###############################################################################
#region Network Traffic Capture and compress PCAP into a password protected   #
# ZIP file. Split ZIP every 1.5GB.                                            #
###############################################################################

$TRACEFILE = "$DFIRLogDir\${LogDate}_${Name}_PCAP\${LogDate}_${Name}_netrace.etl"
Write-Host -ForegroundColor Yellow "Starting Network Trace Collection. Collection set for $XMIN minutes."

New-NetEventSession -Name "Capture" -CaptureMode SaveToFile -LocalFilePath $TRACEFILE | Out-Null
Add-NetEventPacketCaptureProvider -SessionName "Capture" -Level 5 -CaptureType BothPhysicalAndSwitch -EtherType 0x0800 | Out-Null
$CAPTURE = Start-NetEventSession -Name "Capture" | Out-Null

Start-Sleep -Seconds $($XMIN*60)
Stop-NetEventSession -Name "Capture"
Remove-NetEventSession -Name "Capture"

Write-Host -ForegroundColor Green "COMPLETED: Network Trace Complete."
Write-Host -ForegroundColor Yellow "Converting ETL to PCAP file."

Start-Process "$DFIRLogDir\Tools\etl2pcapng.exe" -ArgumentList "$TRACEFILE `"$DFIRLogDir\${LogDate}_${Name}_PCAP\${LogDate}_${Name}_PCAP.pcap`"" -Wait -WindowStyle Hidden
Write-Host -ForegroundColor Green "COMPLETED: Converted ETL to PCAP file."
Write-Host -ForegroundColor Yellow "Compressing the directory '$DFIRLogDir\${LogDate}_${Name}_PCAP\' into a password protected ZIP file."


If($OS64bit) {
    Start-Process "$DFIRLogDir\Tools\7zx64\7z.exe" -ArgumentList "a -mx1 -tzip -v1500m $ZIPFile `"$DFIRLogDir\${LogDate}_${Name}_PCAP\`" -p$7ZPASSWORD" -Wait -WindowStyle Hidden
}Else {
    Start-Process "$DFIRLogDir\Tools\7z.exe" -ArgumentList "a -mx1 -tzip -v1500m $ZIPFile `"$DFIRLogDir\${LogDate}_${Name}_PCAP`" -p$7ZPASSWORD" -Wait -WindowStyle Hidden
}
Write-Host -ForegroundColor Green "COMPLETED: Compressed the PCAP directory into a password protected ZIP file."

#endregion


###############################################################################
#region Clean up Files and Folders                                            #
###############################################################################

#Clean-up
Remove-Item "$DFIRLogDir\${LogDate}_${Name}_PCAP\" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
Remove-Item "$DFIRLogDir\Tools\" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
Remove-Item "$DFIRLogDir\DFIR_LogCollector*.zip" -Force -ErrorAction SilentlyContinue | Out-Null

#Self Destruct (Deletes itself)
$DEL = Remove-Item -Path $MyInvocation.MyCommand.Source -Force -ErrorAction SilentlyContinue | Out-Null
$DEL = Remove-Item -Path "$ScriptDir\DFIR-PCAP_COLLECTION.ps1" -Force -ErrorAction SilentlyContinue | Out-Null

#If enabled, Clean up PowerShell Transaction Logs
$PSLog = Get-ItemProperty -Path "HKLM:SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription\" -ErrorAction SilentlyContinue
If (($PSlog.EnableTranscripting -eq 1 ) -and ($PSlog.EnableTranscripting)){
    $PSOutputDir = $PSlog.OutputDirectory + '\' + $StartTime.ToString('yyyMMdd')
    Start-Process 'cmd.exe' -ArgumentList "/c timeout 10 & for /f `"eol=: delims=`" %F in ('findstr /M /I `"C:\DFIRLog`" $PSOutputDir\*.*') do del /f `"%F`"" -WindowStyle Hidden 
}

Remove-Variable * -ErrorAction SilentlyContinue -Force

#endregion

Exit