<#
.SYNOPSIS
    Collect and add a file to a password protected ZIP file.
.DESCRIPTION
    This sript will collect and add a file to password protected ZIP. (Default Password: infected)
.PARAMETER FILE
    Mandatory. Enter in full file path to file that you want to collect:.
.INPUTS
    Parameters above
.OUTPUTS
    None
.NOTES
    Version:        1.0
    Author:         Elite Grassh0pp3r
    Creation Date:  11/11/2023
    Purpose/Change: Collect and add a file to a password protected ZIP file (default password: infected).
.EXAMPLE
    DFIR-FILE_COLLECTION.ps1 -FILE 'C:\PATH\TO\FILE\FILE.EXE'
    MDE: run DFIR-FILE_COLLECTION.ps1 "'C:\PATH\TO FILE\FILE.EXE'" #URL ENCODE FILE PATH IF IT CONTAINS SPECIAL CHARACTERS
#>
[cmdletbinding()]
Param(
    [Parameter(Position=0,Mandatory=$true,HelpMessage='Enter in full file path to file that you want to collect:')]
        [String]$FILE
)

Add-Type -AssemblyName System.Web

$FILE = ([System.Web.HttpUtility]::UrlDecode($FILE)).ToLower().Replace("`"","").Replace("$","`$")

$StartTime = Get-Date
$Name = $env:computername
$OS64bit = [Environment]::Is64BitOperatingSystem
$LogDate = $StartTime.ToString('yyyMMdd_HHmmss')
$ScriptDir = $PSScriptRoot
$ZIPFile = "C:\DFIRLog\${LogDate}_${Name}_$((Split-Path $FILE -leaf).replace(".","-").replace(" ","__")).zip"
$7ZPASSWORD = "infected"
$DFIRLogDir = "C:\DFIRLog"
$ScriptVersion = 2.1

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

###############################################################################
#region Create IR Log Directory                                               #
###############################################################################

If (!(Test-Path $DFIRLogDir)){
    New-Item $DFIRLogDir -ItemType Directory | Out-Null
    Start-Process "C:\Windows\System32\attrib.exe" -ArgumentList "+S +R +H $DFIRLogDir" -Wait -WindowStyle Hidden
}

If (!(Test-Path $DFIRLogDir\Tools)){
    New-Item "$DFIRLogDir\Tools" -ItemType Directory | Out-Null
}

#endregion

###############################################################################
#region Base64 decode DFIRTOOLS and write ZIP file to current script directory#
###############################################################################

Write-Host -ForegroundColor Yellow "Decoding and writing ZIP file 'DFIR_LogCollector_Tools_FileCollect.zip' to current script directory '${DFIRLogDir}'."

#Base64 Encode string of DFIR_LogCollector_Tools_FileCollect.zip

#Base64 decode variable $DFIRTOOLS and write ZIP file to current script directory
$BINARY = [Convert]::FromBase64String($DFIRTOOLS)
Set-Content -Path "$DFIRLogDir\DFIR_LogCollector_Tools_FileCollect.zip" -Value $BINARY -Encoding Byte | Out-Null

Write-Host -ForegroundColor Green "COMPLETED: Decoded and wrote ZIP file 'DFIR_LogCollector_Tools_FileCollect.zip' to current script directory '${DFIRLogDir}'."

Start-Sleep -Seconds 5

#Checks if the ZIP file 'DFIR_LogCollector_Tools_FileCollect.zip' exists in the current script directory
If (!(Test-Path "$DFIRLogDir\DFIR_LogCollector_Tools_FileCollect.zip")){
    Write-Host -ForegroundColor Red "ERROR: The required tools ZIP file 'DFIR_LogCollector_Tools_FileCollect.zip' does not exists and could not be decoded and extracted from script."
    EXIT
}

#Extract the necessary files to $DFIRLogDir\Tools
Write-Host -ForegroundColor Yellow "Extracting additional required tools from file DFIR_LogCollector_Tools_FileCollect.zip."
Expand-Archive -Path "$DFIRLogDir\DFIR_LogCollector_Tools_FileCollect.zip" -DestinationPath "$DFIRLogDir\" -Force
Write-Host -ForegroundColor Green "COMPLETED: Extracted necessary files to '$DFIRLogDir\Tools'."

Start-Sleep -Seconds 5

#endregion

###############################################################################
#region Collect and add file to a password protected ZIP file                 #
###############################################################################

$FILE2 = $FILE.replace('[','`[').replace(']','`]')

If (!(Test-Path $FILE2)){
    Write-Host -ForegroundColor Red "ERROR: The file entered '${FILE}' does not exist.`nPlease check to make sure the directory path and filename are correct."
    EXIT
}Else {
    #Compress the files/folders into a password protected ZIP file
    If($OS64bit) {
        Start-Process "$DFIRLogDir\Tools\7zx64\7z.exe" -ArgumentList "a -mx1 -tzip -v1500m `"$ZIPFile`" `"$FILE`" -p$7ZPASSWORD" -Wait -WindowStyle Hidden
    }Else {
        Start-Process "$DFIRLogDir\Tools\7z.exe" -ArgumentList "a -mx1 -tzip -v1500m `"$ZIPFile`" `"$FILE`" -p$7ZPASSWORD" -Wait -WindowStyle Hidden
    }
    Write-Host -ForegroundColor Green "`n`nCOMPLETED: The file '$FILE' was added to the password protected ZIP located in the directory '${ZIPFile}.001'.`nIf the archive was larger than 1.5GB, then there will be multiple ZIP files with the same filename, but the number at the end will increase 002, 003, and etc..."
}

#endregion

###############################################################################
#region Clean-up                                                              #
###############################################################################

#Clean-up
Remove-Item "$DFIRLogDir\Tools\" -Force -Recurse -ErrorAction SilentlyContinue | OUT-NULL
Remove-Item "$DFIRLogDir\DFIR_LogCollector*.zip" -Force -ErrorAction SilentlyContinue | Out-Null

#Self Destruct (Deletes itself)
$DEL = Remove-Item -Path $MyInvocation.MyCommand.Source -Force -ErrorAction SilentlyContinue | OUT-NULL
$DEL = Remove-Item -Path "$ScriptDir\DFIR-FILE_COLLECTION.ps1" -Force -ErrorAction SilentlyContinue | OUT-NULL

#If enabled, Clean up PowerShell Transaction Logs
$PSLog = Get-ItemProperty -Path "HKLM:SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription\" -ErrorAction SilentlyContinue
If (($PSlog.EnableTranscripting -eq 1 ) -and ($PSlog.EnableTranscripting)){
    $PSOutputDir = $PSlog.OutputDirectory + '\' + $StartTime.ToString('yyyMMdd')
    Start-Process 'cmd.exe' -ArgumentList "/c timeout 10 & for /f `"eol=: delims=`" %F in ('findstr /M /I `"C:\DFIRLog`" $PSOutputDir\*.*') do del /f `"%F`"" -WindowStyle Hidden 
}

Remove-Variable * -ErrorAction SilentlyContinue -Force

#endregion

EXIT(0)