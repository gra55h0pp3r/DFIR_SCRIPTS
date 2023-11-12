<#
.SYNOPSIS
    Non interactive command execution for MDE live response.
.DESCRIPTION
    This sript will Invoke the arbitrary command (URL Encoded) passed on the endpoint.
.PARAMETER COMMAND
    Mandatory. Enter the command to be executed.
.INPUTS
    Parameters above
.OUTPUTS
    None
.NOTES
    Version:        1.0
    Author:         Elite Grassh0pp3r
    Creation Date:  11/11/2023
    Purpose/Change:  This sript will Invoke the arbitrary command passed on the endpoint.
.EXAMPLE
    MDE: run DFIR-INVOKE_COMMAND.ps1 "'Remove-Item -Path C:\PATH\TOFILE\FILE.EXE -Force" #RECOMMEND URL ENCODING THE POWERSHELL COMMAND
    MDE: run DFIR-INVOKE_COMMAND.ps1 "'remove%2Ditem%20%2DPath%20%27C%3A%5CSPACES%5CWITH%20SPECIAL%5CCHARACTERS%21%40%23%24%25%2EFAKE%27" #URL ENCODE EXAMPLE
#>

[cmdletbinding()]
Param(
    [Parameter(Position=0,Mandatory=$true,HelpMessage='Enter the command (URL ENCODED) you would like to invoke:')]
        [String]$COMMAND
)

Add-Type -AssemblyName System.Web

If($COMMAND -match '%'){
    [String]$COMMAND = ([System.Web.HttpUtility]::UrlDecode($COMMAND)).ToLower().Replace("`"","").replace('[','`[').replace(']','`]')
}Else {
    [String]$COMMAND = $COMMAND.ToLower().Replace("`"","")
}

$StartTime = Get-Date
$ScriptDir = $PSScriptRoot
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

###############################################################################
#region Execute PowerShell Command                                            #
###############################################################################

Write-Host -ForegroundColor Green "COMPLETED: The command '$COMMAND' was executed.`n`n"
Invoke-Expression -Command $COMMAND

#endregion

###############################################################################
#region Clean-up                                                              #
###############################################################################

$DEL = Remove-Item -Path $MyInvocation.MyCommand.Source -Force -ErrorAction SilentlyContinue | Out-Null
$DEL = Remove-Item -Path "$ScriptDir\DFIR-INVOKE_COMMAND.ps1" -Force -ErrorAction SilentlyContinue | Out-Null

#If enabled, Clean up PowerShell Transaction Logs
$PSLog = Get-ItemProperty -Path "HKLM:SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription\" -ErrorAction SilentlyContinue
If (($PSlog.EnableTranscripting -eq 1 ) -and ($PSlog.EnableTranscripting)){
    $PSOutputDir = $PSlog.OutputDirectory + '\' + $StartTime.ToString('yyyMMdd')
    Start-Process 'cmd.exe' -ArgumentList "/c timeout 10 & for /f `"eol=: delims=`" %F in ('findstr /M /I `"Invoke-Expression -Command`" $PSOutputDir\*.*') do del /f `"%F`"" -WindowStyle Hidden 
}

Remove-Variable * -ErrorAction SilentlyContinue -Force

#endregion

EXIT 0