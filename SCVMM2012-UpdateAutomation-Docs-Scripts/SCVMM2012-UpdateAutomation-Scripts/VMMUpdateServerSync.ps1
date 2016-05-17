param ( $VMMServer="localhost", 
        $DomainUser="xxx", 
		$Password="yyy")

$scriptdir="c:\scvmm\UpdateAutomation"
$scriptout=$scriptdir + "\Output"
$logfile="VMMUpdateServerSync" + (Get-Date -Format "yyyyMMddHHmmss")

. $scriptdir\VMMUpdateUtil.ps1

$global:retFlag=0

UpdateLogFile -message "***Update Server Sync Process*** <START>" -appendflag $false

# Import VMM Module.
if((Get-Module -Name "virtualmachinemanager") -eq $null) {
 	 Import-Module "virtualmachinemanager"	
}
$vmmspwd = ConvertTo-SecureString $Password -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential $DomainUser,$vmmspwd

# Connect to the VMM server.
$VMMServerObj=Get-SCVMMServer -ComputerName $VMMServer -Credential $Credential

# Check Servicing Window time range
$swName = "SWForUpdateSync"
CheckCurrTimeInSW $swName
if($retFlag -eq 1){
	$message="ERROR: The Current date/time is not in SW for Update Server Sync Return Code:" + $retFlag
	UpdateLogFile $message
	return
}

# Synchronize Update Server
#$updtServer=$UpdateServer
#SyncUpdateServer $updtServer
SyncUpdateServer
if($retFlag -eq 1){
	$message="Failed submitting job for Update Server Sync Return Code:" + $retFlag
	UpdateLogFile $message
	return
}

UpdateLogFile -message "***Update Server Sync Process*** <END>" -appendflag $true

