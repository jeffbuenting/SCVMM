param ( $VMMServer="localhost", 
		$DomainUser="xxx", 
		$Password="yyy", 
		$SCCMServer="sccmserver",
		$SCCMUser="aaa",
		$SCCMPass="bbb"
	)

$scriptdir="c:\SCVMM\UpdateAutomation"
$scriptout=$scriptdir + "\Output"
$logfile="VMMUpdateBaselineFromSCCM" + (Get-Date -Format "yyyyMMddHHmmss")

. $scriptdir\VMMUpdateUtil.ps1
. $scriptdir\SCCMUpdateUtil.ps1

$global:retFlag=0
$global:noOfJobs=0

UpdateLogFile -message "***SCCM Update for Baseline and Update List data*** <START>" -appendflag $false

#Import SCVMM module
if((Get-Module -Name "virtualmachinemanager") -eq $null) {
 	 Import-Module "virtualmachinemanager"	
 }

$vmmspwd = ConvertTo-SecureString $Password -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential $DomainUser,$vmmspwd
if($Credential -eq $null){
	$message="Invalid credential to access VMM server : " + $DomainUser
	UpdateLogFile $message
	return
}

# Connect to the VMM server.
$VMMServerObj=Get-SCVMMServer -ComputerName $VMMServer -Credential $Credential

# Check Servicing Window time range
$swName = "SWForUpdateBaseLineFromSCCM"
CheckCurrTimeInSW $swName
if($retFlag -eq 1){
	$message="ERROR: The Current date/time is not in SW for Baseline Update From SCCM:" + $retFlag
	UpdateLogFile $message
	return
}

$ConfigMgrServer=$SCCMServer
$sccmspwd = ConvertTo-SecureString $SCCMPass -AsPlainText -Force
$sccmcred = New-Object System.Management.Automation.PSCredential $SCCMuser, $sccmspwd
if($sccmcred -eq $null){
	$message="Invalid Credential for SCCM Server connection " 
	UpdateLogFile $message
	return
}

$BaselineList = “Windows Server 2003 - Security”,“Windows Server 2003, Datacenter Edition - Security”
$UpdateList = “Windows Server 2003 - Critical”,“Windows Server 2003, Datacenter Edition - Critical”
#$BaselineList = $null
#$UpdateList = $null

if($BaselineList -eq $null){
	$message="No Baseline Update List available for data collect from SCCM : "
	UpdateLogFILe $message
}

if($BaselineList -ne $null){
#Update All Baseline data from SCCM
foreach($BaselineName in $BaselineList){
	$KBArticle=@()
	$SUForBaseline = GetBaseLineFromSCCM -ConfigMgrServer $ConfigMgrServer -BaselineName $BaselineName 
	if($retFlag -eq 1){
		$message="Failed to get SCCM Software Update Baseline For " + $BaseLineName
		UpdateLogFile $message
		continue
	}
	foreach($su in $SUForBaseline){
	   	$KB=$su.ArticleID
		$ID=$su.CI_UniqueID
		$Rev=$su.RevisionNumber
		$EA=$su.EULAAccepted
		$EE=$su.EULAExists
		$ESOD=$su.EULASignoffDate
		$ESOU=$su.EULASignoffUser
		$Key="$KB,$ID,$Rev,$EA,$EE,$ESOD,$ESOU"
	
		if($KBArticle -contains $Key){
			continue
		} else {
			$KBArticle += $Key
		}
	}
	$KBArticle.Length
	$KBArticle
	if($KBArticle.Length -eq 0){
		$message="No KBArticle from SCCM To Update for Baseline : " + $BaselineName
		UpdateLogFile $message
		continue
	}
	
	$baseLineUpdateCount=AddUpdateToVMMBaseline -KBArticle $KBArticle -BaselineName $BaselineName
	#$baseLineUpdateCount=AddUpdateToVMMBaseline -KBArticle $KBArticle -BaselineName $BaselineName -Purged $true

	if($baseLineUpdateCount -gt 0){
		$cmdletName = "Set-SCBaseline"
		WaitForLatJobComplete $cmdletName
		if($retFlag -eq 1){
			$message="Job Failed to add SCCM Baseline data for - " + $BaselineName
			UpdateLogFile $message
			continue
		}
	}
	$message="Completed updating the software update baseline from :" + $BaselineName + " Updates Count :" + $baseLineUpdateCount
	UpdateLogFile $message		
}
}

if($UpdateList -eq $null){
	$message="No Software Update List available for data collect from SCCM : "
	UpdateLogFILe $message
	return
}

#Update All Software UpdateList data from SCCM
foreach($BaselineName in $UpdateList){
	$KBArticle=@()
	$SUForBaseline=GetAuthSoftwareUpdateFromSCCM -ConfigMgrServer $ConfigMgrServer -UpdateListName $BaselineName 
	if($retFlag -eq 1){
		$message="Failed to get SCCM Software Update List For " + $BaselineName
		UpdateLogFile $message
		continue
	}

	foreach($su in $SUForBaseline){
	    $KB=$su.ArticleID
		$ID=$su.CI_UniqueID
		$Rev=$su.RevisionNumber
		$EA=$su.EULAAccepted
		$EE=$su.EULAExists
		$ESOD=$su.EULASignoffDate
		$ESOU=$su.EULASignoffUser
		$Key="$KB,$ID,$Rev,$EA,$EE,$ESOD,$ESOU"
		if($KBArticle -contains $Key){
			continue
		} else {
			$KBArticle += $Key
		}
	}
	$KBArticle.Length
	$KBArticle
	if($KBArticle.Length -eq 0){
		$message="No KBArticle from SCCM To Update for Baseline : " + $BaselineName
		UpdateLogFile $message
		continue
	}
	
	$baseLineUpdateCount=AddUpdateToVMMBaseline -KBArticle $KBArticle -BaselineName $BaselineName
	#$baseLineUpdateCount=AddUpdateToVMMBaseline -KBArticle $KBArticle -BaselineName $BaselineName -Purged $true

	if($baseLineUpdateCount -gt 0){
		$cmdletName = "Set-SCBaseline"
		WaitForLatJobComplete $cmdletName
		if($retFlag -eq 1){
			$message="Job Failed to add SCCM Baseline data for - " + $BaselineName
			UpdateLogFile $message
			continue
		}
	}
	$message="Completed updating the software update list from SCCM :" + $BaselineName + " Updates Count : " + $baseLineUpdateCount
	UpdateLogFile $message
}

$message="Completed updating the software updates from SCCM for all baselines and update lists "
UpdateLogFile $message		

UpdateLogFile -message "***SCCM Update for Baseline and Update List data*** <START>" -appendflag $true

