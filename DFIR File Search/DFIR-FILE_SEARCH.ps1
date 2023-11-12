<#
.SYNOPSIS
    Search for files on all drives.
.DESCRIPTION
    This script will enumerate all drives on a system looking for a specific filename.
.PARAMETER FILENAME
    Mandatory. Enter in the filename to search for.
.INPUTS
    Parameters above
.OUTPUTS
    None
.NOTES
    Version:        1.0
    Author:         Elite Grassh0pp3r
    Creation Date:  2/6/2023
    Purpose/Change: Initial Filename search
.EXAMPLE
    PowerShell Console: ./DFIR-FILE_SEARCH.ps1 -FILENAME "testfile" #URL ENCODE STRING WITH SPECIAL CHARACTERS
    Tanium: cmd.exe /c PowerShell.exe -ExecutionPolicy Bypass -File "%1" #Already URL encodes by default
    MDE: run DFIR-FILE_SEARCH.ps1 "'testfile'" #URL ENCODE STRING WITH SPECIAL CHARACTERS
.EXAMPLE
    PowerShell Console: ./DFIR-FILE_SEARCH.ps1 -FILENAME "testfile.txt" #URL ENCODE STRING WITH SPECIAL CHARACTERS
    Tanium: cmd.exe /c PowerShell.exe -ExecutionPolicy Bypass -File "%1" #Already URL encodes by default
    MDE: run DFIR-FILE_SEARCH.ps1 "'testfile.txt'" #URL ENCODE STRING WITH SPECIAL CHARACTERS
#>
[cmdletbinding()]
Param(
    [Parameter(Mandatory=$true,Position=0,HelpMessage='Enter in the filename to search for.')]
        [String]$FILENAME
)

Add-Type -AssemblyName System.Web
$FILENAME = ([System.Web.HttpUtility]::UrlDecode($FILENAME)).ToLower().Replace("`"","")

$StartTime = Get-Date
$LogDate = $StartTime.ToString('yyyMMdd_HHmmss')
$Name = $env:computername
$ScriptDir = $PSScriptRoot
$DFIRLogDir = "C:\DFIRLog"
$LogFile =  "$DFIRLogDir\${LogDate}_${Name}_FileSearch_Results.log"
$ScriptVersion = 1.0
$x = 0

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


                                                          Script Version $ScriptVersion
                                                          POC: Elite Grassh0pp3r


"@

Write-Host $Logo -ForegroundColor Green

Function Log-Start{  
    [CmdletBinding()]
    Param ([Parameter(Mandatory=$true)][string]$LogPath, [Parameter(Mandatory=$true)][string]$ScriptVersion)
    Process{
        Add-Content -Path $LogPath -Value "***************************************************************************************************"
        Add-Content -Path $LogPath -Value "Running FILE SEARCH COLLECTOR."
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
    Add-Content -Path $LogPath -Value "Total Files Found: ${x}."
    Add-Content -Path $LogPath -Value "***************************************************************************************************"
    Add-Content -Path $LogPath -Value "Total processing time $(((Get-Date)-$StartTime).totalseconds) seconds."
    Add-Content -Path $LogPath -Value "***************************************************************************************************"
}

If (!(Test-Path $DFIRLogDir)){
    New-Item "$DFIRLogDir" -ItemType Directory | Out-Null
    Start-Process "C:\Windows\System32\attrib.exe" -ArgumentList "+S +R +H $DFIRLogDir" -Wait -WindowStyle Hidden
}

Log-Start -LogPath $LogFile -ScriptVersion "$ScriptVersion"
Log-Write -LogPath $LogFile -LineValue "PowerShell version: $($PSVersionTable.PSVersion)"
Write-host "PowerShell version: $($PSVersionTable.PSVersion)`n`n"

###############################################################################
#region Search for File                                                       #
###############################################################################

Write-Host -ForegroundColor Yellow "Enumerating all drives searching for filenames that contain '${FILENAME}'."
Log-Write -LogPath $LogFile -LineValue "Enumerating all drives searching for filenames that contain '${FILENAME}'."

$drive_letters = (Get-PSDrive -PSProvider FileSystem).Root
$filesfound = @()

foreach ($drive in $drive_letters){
    Write-Host -ForegroundColor Yellow "Enumerating drive '${drive}' searching for files that contain '*${FILENAME}*'."
    Log-Write -LogPath $LogFile -LineValue "Enumerating drive '${drive}' searching for files that contain '*${FILENAME}*'."
    $filesfound += Get-ChildItem -Path "$drive" -Filter "*${FILENAME}*" -FILE -Recurse -ErrorAction SilentlyContinue -Force | Select-Object FullName
}

if ($filesfound){
    foreach ($file in $filesfound){
        Write-Host -ForegroundColor Green "File Found: $($file.FullName)"
        Log-Write -LogPath $LogFile -LineValue "File Found: $($file.FullName)"
        $x += 1
    }
}else {
    Write-Host -ForegroundColor Green "COMPLETED: No files were found that contain '${FILENAME}'."
    Log-Write -LogPath $LogFile -LineValue "COMPLETED: No files were found that contain '${FILENAME}'."
}

Write-Host "A total of ${x} files was found that contained '*${FILENAME}*'."
Write-Host "A list of all the filenames found is located at $LogFile"
Log-Finish -LogPath $LogFile
Write-Host -ForegroundColor Green "COMPLETED: The file search log file is located at '${LogFile}'"

#endregion

###############################################################################
#region Cleanup                                                               #
###############################################################################

#Self Destruct (Deletes itself)
$DEL = Remove-Item -Path $MyInvocation.MyCommand.Source -Force -ErrorAction SilentlyContinue | Out-Null
$DEL = Remove-Item -Path "$ScriptDir\DFIR-FILE_SEARCH.ps1" -Force -ErrorAction SilentlyContinue | Out-Null

#If enabled, Clean up PowerShell Transaction Logs
$PSLog = Get-ItemProperty -Path "HKLM:SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription\" -ErrorAction SilentlyContinue
If (($PSlog.EnableTranscripting -eq 1 ) -and ($PSlog.EnableTranscripting)){
    $PSOutputDir = $PSlog.OutputDirectory + '\' + $StartTime.ToString('yyyMMdd')
    Start-Process 'cmd.exe' -ArgumentList "/c timeout 10 & for /f `"eol=: delims=`" %F in ('findstr /M /I `"C:\DFIRLog`" $PSOutputDir\*.*') do del /f `"%F`"" -WindowStyle Hidden 
}

Remove-Variable * -ErrorAction SilentlyContinue -Force

#endregion

EXIT(0)