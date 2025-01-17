########################################################
##
##  This script enables an OSD Failed Message which is showed 
##  until a Success Message is set, commonly with OSDEnableOSDMessage_005.ps1
##
##  Author: Thomas Kurth/Netree
##  Date:   11.3.2014
##
##  Histroy 
##        001: Basis version
##
########################################################
$ErrorActionPreference = "Stop"

$LogFilePath = "C:\Windows\Temp\OSIEnableOSDFailedMessage_" + (get-date -uformat %Y%m%d%H%M) + ".log"

function WriteLog($Text){
    Out-file -FilePath $LogFilePath -force -append -InputObject ((Get-Date –f o) + "        " +  $Text)
    Write-Host $Text
}

# Type = Binary, DWord, ExpandString, MultiString, String, QWord
function SetRegValue ([string]$Path, [string]$Name, [string]$Value, [string]$Type) {
    try {
        $ErrorActionPreference = 'Stop' # convert all errors to terminating errors
        Start-Transaction

	   if (Test-Path $Path -erroraction silentlycontinue) {      
        } else {
            New-Item -Path $Path -Force
            WriteLog "Registry key $Path created"  
        } 
    
        $null = New-ItemProperty -Path $Path -Name $Name -PropertyType $Type -Value $Value -Force
        WriteLog "Registry Value $Path, $Name, $Type, $Value set"
        Complete-Transaction
    }
    catch {
        Undo-Transaction
        WriteLog "ERROR Registry value not set $Path, $Name, $Value, $Type"
    }

}

function CreateFolder ([string]$Path) {

	# Check if the folder Exists

	if (Test-Path $Path) {
		WriteLog "Folder: $Path Already Exists"
	} else {
		WriteLog "Creating $Path"
		New-Item -Path $Path -type directory | Out-Null
	}
}

function SetExitMessageRegistry () {
  #All Parameters must be passed or the function does not run
  param(
    [Parameter(Mandatory=$True,
      HelpMessage='The Name of the running Script')]
    [string]$Scriptname,
    [Parameter(Mandatory=$True,
      HelpMessage='The Path of the Logfile')]
    [string]$LogfileLocation,
    [Parameter(Mandatory=$True,
      HelpMessage='The ExitMessage for the current Script')]
    [string]$ExitMessage
  )

  $DateTime = Get-Date –f o
  #The registry Key into which the information gets written must be checked and if not existing created
  if((Test-Path "HKLM:\SOFTWARE\_Custom") -eq $False)
  {
    $null = New-Item -Path "HKLM:\SOFTWARE\_Custom"
  }
  if((Test-Path "HKLM:\SOFTWARE\_Custom\Scripts") -eq $False)
  {
    $null = New-Item -Path "HKLM:\SOFTWARE\_Custom\Scripts"
  }
  try
  { 
    #The new key gets created and the values written into it
    $null = New-Item -Path "HKLM:\SOFTWARE\_Custom\Scripts\$Scriptname" -ErrorAction Stop
    $null = New-ItemProperty -Path "HKLM:\SOFTWARE\_Custom\Scripts\$Scriptname" -Name "Scriptname" -Value "$Scriptname" -ErrorAction Stop
    $null = New-ItemProperty -Path "HKLM:\SOFTWARE\_Custom\Scripts\$Scriptname" -Name "Time" -Value "$DateTime" -ErrorAction Stop
    $null = New-ItemProperty -Path "HKLM:\SOFTWARE\_Custom\Scripts\$Scriptname" -Name "ExitMessage" -Value "$ExitMessage" -ErrorAction Stop
    $null = New-ItemProperty -Path "HKLM:\SOFTWARE\_Custom\Scripts\$Scriptname" -Name "LogfileLocation" -Value "$LogfileLocation" -ErrorAction Stop
  }
  catch
  { 
    #If the registry keys can not be written the Error Message is returned and the indication which line (therefore which Entry) had the error
    $Error[0].Exception
    $Error[0].InvocationInfo.PositionMessage
  }
}

# Try get actual ScriptName
try{
    $ScriptNameTemp = $MyInvocation.MyCommand.Name
    If($ScriptNameTemp -eq $null -or $ScriptNameTemp -eq ""){
        $ScriptName = $LogFilePathScriptName
    } else {
        $ScriptName = $ScriptNameTemp
    }
} catch {
    $ScriptName = $LogFilePathScriptName
}



CreateFolder "C:\Windows\Logs\SCCM"
try{
    WriteLog "Start OSI Enable OSD Failed Message"

    # Basic Information
    WriteLog "Basic Information"
    $ComputerName = gc env:computername
    $header = "$ComputerName FAILED installing!!!"


    # Building Message
    WriteLog "Building Message"

    $Message = "Error during staging, check the staging state of this machine in netECM!"

    WriteLog "Message to display:"
    WriteLog $Message

    WriteLog "Set registry Keys for Legal Notice"
    SetRegValue "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\" "LegalNoticeCaption" $header "String"
    SetRegValue "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\" "LegalNoticeText" $Message "String"


    WriteLog "Ending OSI Enable OSD Failed Message"
} catch {
    WriteLog "Error: $($_.Exception.Message)"
    $ExitMessage = "Error: $($_.Exception.Message)"
    SetExitMessageRegistry -Scriptname $ScriptName -LogfileLocation "$LogFilePath" -ExitMessage "$ExitMessage"
    exit 99001
}
$ExitMessage = "Successfully completed the script"
SetExitMessageRegistry -Scriptname $ScriptName -LogfileLocation "$LogFilePath" -ExitMessage "$ExitMessage"