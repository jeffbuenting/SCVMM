param ( $VMMServer="localhost", 
        $DomainUser="xxx", 
		$Password="yyy"
		 )

$scriptdir="c:\SCVMM\UpdateAutomation"
$scriptout=$scriptdir + "\Output"
$logfile="VMMUpdateComplianceScan" + (Get-Date -Format "yyyyMMddHHmmss")

. $scriptdir\VMMUpdateUtil.ps1

$global:retFlag=0
$global:noOfJobs=0

UpdateLogFile -message "***Update Compliance Scan Process*** <START>" -appendflag $false

#Import VMM module
if((Get-Module -Name "virtualmachinemanager") -eq $null) {
 	 Import-Module "virtualmachinemanager"	
 }
$credPwd = ConvertTo-SecureString $Password -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential $DomainUser,$credPwd

# Connect to the VMM server.
$VMMServerObj=Get-SCVMMServer -ComputerName $VMMServer -Credential $Credential

# Check Servicing Window time range
$swName = "SWForUpdateComplianceScan"
CheckCurrTimeInSW $swName
if($retFlag -eq 1){
	$message="ERROR: The Current date/time is not in SW for Update Server Sync Return Code:" + $retFlag
	UpdateLogFile $message
	return
}

# Perform compliance scan for assigned scope
StartComplianceScan-All
if($retFlag -eq 1){
	$message="Failed submitting job for Update Compliance Scan Return Code:" + $retFlag
	UpdateLogFile $message
	return
}

#check the job status and log 
$cmdletName = "Start-SCComplianceScan"
WaitForAllJobComplete $cmdletName
if($retFlag -eq 1){
	$message="Failed checking job for Update Compliance Scan Return Code:" + $retFlag
	UpdateLogFile $message
	return
}

UpdateLogFile -message "***Update Compliance Scan Process*** <END>" -appendflag $true

