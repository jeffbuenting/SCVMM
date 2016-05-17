param ( $VMMServer="localhost", 
        $DomainUser="xxx", 
		$Password="yyy"
		 )

$scriptdir="c:\SCVMM\UpdateAutomation"
$scriptout=$scriptdir + "\Output"
$logfile="VMMUpdateComplianceRemediate" + (Get-Date -Format "yyyyMMddHHmmss")

. $scriptdir\VMMUpdateUtil.ps1

$global:retFlag=0
$global:noOfJobs=0

UpdateLogFile -message "***Update Compliance Remediate Process*** <START>" -appendflag $false

if((Get-Module -Name "virtualmachinemanager") -eq $null) {
 	 Import-Module "virtualmachinemanager"	
 }
$credPwd = ConvertTo-SecureString $Password -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential $DomainUser,$credPwd

# Connect to the VMM server.
$VMMServerObj=Get-SCVMMServer -ComputerName $VMMServer -Credential $Credential

$swName = "SWForUpdateComplianceRemediate"
CheckCurrTimeInSW $swName
if($retFlag -eq 1){
	$message="ERROR: The Current date/time is not in SW for Update Server Sync Return Code:" + $retFlag
	UpdateLogFile $message
	return
}

#StartComplianceRemediate-All -forced $true
StartComplianceRemediate-All -forced $false
if($retFlag -eq 1){
	$message="Failed submitting job for Update Compliance Remediate Return Code:" + $retFlag
	UpdateLogFile $message
	return
}

$cmdletName = "Start-SCUpdateRemediation"
WaitForAllJobComplete $cmdletName
if($retFlag -eq 1){
	$message="Failed checking job for Update Compliance Remediate Return Code:" + $retFlag
	UpdateLogFile $message
	return
}

UpdateLogFile -message "***Update Compliance Remediate Process*** <END>" -appendflag $true
