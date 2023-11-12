<#
.SYNOPSIS
    Captures a single process or all running processes.
.DESCRIPTION
    This sript will capture a single process or all processes that are currently running on the system. (DEFAULT: ALLPROCESSES)
.PARAMETER FILE
    Optional. Enter in the PID number of the PROCESS to DUMP. (Default: ALLPROCESSES)
.INPUTS
    Parameters above
.OUTPUTS
    None
.NOTES
    Version:        1.0
    Creation Date:  11/11/2023
    Author: Elite Grassh0pp3r
    Purpose/Change: Initial creation of the script to captures all processes curently running and ZIP dumped files into a password protected ZIP file.
.EXAMPLE
    Powershell Command Prompt: DFIR-PROCESS_COLLECTION.ps1
    Powershell Command Prompt: DFIR-PROCESS_COLLECTION.ps1 -PROCESSID [PID_NUMBER]
    Tanium: cmd.exe /c PowerShell.exe -ExecutionPolicy Bypass -File DFIR-PROCESS_COLLECTION.ps1 %1
    MDE: run DFIR-PROCESS_COLLECTION.ps1
    MDE: run DFIR-PROCESS_COLLECTION.ps1 "'[PID_NUMBER]'"
#>
[cmdletbinding()]
Param(
    [Parameter(Position=0,Mandatory=$false,HelpMessage='Enter in the PID number of the PROCESS to DUMP.')]
        [String]$PROCESSID="ALLPROCESSES"
)

Add-Type -AssemblyName System.Web

$PROCESSID = ([System.Web.HttpUtility]::UrlDecode($PROCESSID)).ToLower().Replace("`"","")

$StartTime = Get-Date
$Name = $env:computername
$OS64bit = [Environment]::Is64BitOperatingSystem
$LogDate = $StartTime.ToString('yyyMMdd_HHmmss')
$ScriptDir = $PSScriptRoot
$ZIPFile = "C:\DFIRLog\${LogDate}_PROCESS_${Name}.zip"
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
Write-host "PowerShell version: $($PSVersionTable.PSVersion)`n`n"

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

If ((!($PROCESSID -match "^\d+$")) -AND (!($PROCESSID -eq "ALLPROCESSES"))){
    Write-Host -ForegroundColor Red "ERROR: The PID parameter '$PROCESSID' that was entered contains characters other than numbers only.'n Re-run that command and ensure you are only entering numbers within the PID parameter."
    EXIT
}

###############################################################################
#region Create Directories DFIRLog and RAM                                      #
###############################################################################

If (!(Test-Path $DFIRLogDir)){
    New-Item $DFIRLogDir -ItemType Directory | Out-Null
    Start-Process "C:\Windows\System32\attrib.exe" -ArgumentList "+S +R +H $DFIRLogDir" -Wait -WindowStyle Hidden
    Write-Host -ForegroundColor Yellow "Created Directory: '$DFIRLogDir'."
}

If (!(Test-Path $DFIRLogDir\Tools)){
    New-Item "$DFIRLogDir\Tools" -ItemType Directory | Out-Null
    Write-Host -ForegroundColor Yellow "Created Directory: '$DFIRLogDir\Tools'."
}

If (!(Test-Path $DFIRLogDir\ProcessCapture)){
    New-Item "$DFIRLogDir\ProcessCapture" -ItemType Directory | Out-Null
    Write-Host -ForegroundColor Yellow "Created Directory: '$DFIRLogDir\ProcessCapture'."
}

#endregion

###############################################################################
#region Base64 decode DFIRTOOLS and write ZIP file to current script directory#
###############################################################################

Write-Host -ForegroundColor Yellow "Decoding and writing ZIP file 'DFIR_LogCollector_Tools.zip' to current script directory '${DFIRLogDir}'."

#Base64 Encode string of DFIR_LogCollector_Tools.zip

#Base64 decode variable $DFIRTOOLS and write ZIP file to current script directory
$BINARY = [Convert]::FromBase64String($DFIRTOOLS)
Set-Content -Path "$DFIRLogDir\DFIR_LogCollector_Tools_Process.zip" -Value $BINARY -Encoding Byte | Out-Null

Write-Host -ForegroundColor Green "COMPLETED: Decoded and wrote ZIP file 'DFIR_LogCollector_Tools.zip' to current script directory '${DFIRLogDir}'."

Start-Sleep -Seconds 5

#Checks if the ZIP file 'DFIR_LogCollector_Tools_Process.zip' exists in the current script directory
If (!(Test-Path "$DFIRLogDir\DFIR_LogCollector_Tools_Process.zip")){
    Write-Host -ForegroundColor Red "ERROR: The required tools ZIP file 'DFIR_LogCollector_Tools_Process.zip' does not exists and could not be decoded and extracted from script."
    EXIT
}

#Extract the necessary files to $DFIRLogDir\Tools
Write-Host -ForegroundColor Yellow "Extracting additional required tools from file DFIR_LogCollector_Tools_Process.zip."
Expand-Archive -Path "$DFIRLogDir\DFIR_LogCollector_Tools_Process.zip" -DestinationPath "$DFIRLogDir\" -Force
Write-Host -ForegroundColor Green "COMPLETED: Extracted necessary files to '$DFIRLogDir\Tools'."

Start-Sleep -Seconds 5

#endregion

###############################################################################
#region Dump Running Processes                                                #
###############################################################################

$TOTALFREEDISKSPACE = (Get-Volume -DriveLetter C).SizeRemaining

IF ($PROCESSID -eq "ALLPROCESSES"){
    #Checks if the Root Drive has enough free disk space for dumping all processes (Greater than 10GB (10737418240))
    IF ($TOTALFREEDISKSPACE -gt 10737418240){
        Write-Host -ForegroundColor Yellow "Dumping all running processes and/or single process."
        Start-Process "$DFIRLogDir\Tools\MagnetProcessCapture.exe" -ArgumentList "/saveallsilent `"$DFIRLogDir\ProcessCapture`"" -Wait -WindowStyle Hidden
    }Else {
        Remove-Item "$DFIRLogDir" -Force -Recurse -ErrorAction SilentlyContinue
        Write-Host -ForegroundColor Red "ERROR: There is not enough free disk space available on the C: drive to capture running processes."
        EXIT
    }
}Else {
    IF (Get-Process | Where-Object { $_.Id -eq $PROCESSID}){
        IF ($OS64bit){
            Write-Host -ForegroundColor Yellow "System is a 64-bit. Dumping process ID '$PROCESSID'."
            Start-Process "$DFIRLogDir\Tools\procdump64.exe" -ArgumentList "-accepteula -ma $PROCESSID `"$DFIRLogDir\ProcessCapture\PROCESSNAME_YYMMDD_HHMMSS.dmp`"" -Wait -WindowStyle Hidden
        }Else {
            Write-Host -ForegroundColor Yellow "System is a 32-bit. Dumping process ID '$PROCESSID'."
            Start-Process "$DFIRLogDir\Tools\procdump.exe" -ArgumentList "-accepteula -ma $PROCESSID `"$DFIRLogDir\ProcessCapture\PROCESSNAME_YYMMDD_HHMMSS.dmp`"" -Wait -WindowStyle Hidden
        }
    }
}

IF ((Get-ChildItem "$DFIRLogDir\ProcessCapture" | Measure-Object).count -gt 0){
    Write-Host -ForegroundColor Yellow "Archiving dumped processes captured. Archive is split into files no larger than 1.5GB."
    If($OS64bit) {
        Start-Process "$DFIRLogDir\Tools\7zx64\7z.exe" -ArgumentList "a -mx1 -tzip -v1500m $ZIPFile `"$DFIRLogDir\ProcessCapture`" -p$7ZPASSWORD" -Wait -WindowStyle Hidden
    }Else {
        Start-Process "$DFIRLogDir\Tools\7z.exe" -ArgumentList "a -mx1 -tzip -v1500m $ZIPFile `"$DFIRLogDir\ProcessCapture`" -p$7ZPASSWORD" -Wait -WindowStyle Hidden
    }
    Write-Host -ForegroundColor Green "COMPLETED: Dumped all running processes and/or single process was added to a password protected ZIP located in the directory '$ZIPFile.001'.`nIf the archive was larger than 1.5GB, then there will be multiple ZIP files with the same filename, but the number at the end will increase 002, 003, and etc..."
}Else {
    Write-Host -ForegroundColor Red "ERROR: The directory '$DFIRLogDir\ProcessCapture' did not contain any dumped process file(s)."
}


}
#endregion

###############################################################################
#region Clean up Files and Folders                                            #
###############################################################################
#Clean up Files and Folders
Remove-Item "$DFIRLogDir\ProcessCapture\" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
Remove-Item "$DFIRLogDir\Tools\" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
Remove-Item "$DFIRLogDir\DFIR_LogCollector*.zip" -Force -ErrorAction SilentlyContinue | Out-Null

#Self Destruct (Deletes itself)
$DEL = Remove-Item -Path $MyInvocation.MyCommand.Source -Force -ErrorAction SilentlyContinue | Out-Null
$DEL = Remove-Item -Path "$ScriptDir\DFIR-PROCESS_COLLECTION.ps1" -Force -ErrorAction SilentlyContinue | Out-Null

#If enabled, Clean up PowerShell Transaction Logs
$PSLog = Get-ItemProperty -Path "HKLM:SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription\" -ErrorAction SilentlyContinue
If (($PSlog.EnableTranscripting -eq 1 ) -and ($PSlog.EnableTranscripting)){
    $PSOutputDir = $PSlog.OutputDirectory + '\' + $StartTime.ToString('yyyMMdd')
    Start-Process 'cmd.exe' -ArgumentList "/c timeout 10 & for /f `"eol=: delims=`" %F in ('findstr /M /I `"C:\DFIRLog`" $PSOutputDir\*.*') do del /f `"%F`"" -WindowStyle Hidden 

Remove-Variable * -ErrorAction SilentlyContinue -Force

#endregion

Exit(0)