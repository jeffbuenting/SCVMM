
# FUNCTION to collect baseline from SCCM
function GetBaseLineFromSCCM
{
	Param( [string] $ConfigMgrServer,
		   [string] $SiteCode = "Default",
		   [string] $BaselineName = "TestSCCMBaseLineForVMM"
	)
	Process 
	{
		$provNamespace = "root\sms"
		$getSMSProvider = Get-WmiObject -Query "select * from SMS_ProviderLocation" -Namespace $provNamespace -ComputerName $ConfigMgrServer -Credential $sccmcred

		if($SiteCode -eq "Default"){
			$ConfigMgrNamespace = $provNamespace + "\site_" + $getSMSProvider.SiteCode
		} else {
			$ConfigMgrNamespace = $provNamespace + "\site_" + $SiteCode
		}
		
   		# Get the DCM baseline to query
    	$CIBaseline = Get-WmiObject -Class "SMS_ConfigurationBaselineInfo" -filter "LocalizedDisplayName='$BaselineName'" -namespace $ConfigMgrNamespace -computername $ConfigMgrServer -Credential $sccmcred
		
		$SUQuery="SELECT SMS_SoftwareUpdate.* FROM SMS_SoftwareUpdate, sms_cirelation WHERE sms_cirelation.ToCIID = SMS_SoftwareUpdate.CI_ID AND sms_cirelation.FromCIID = " + $CIBaseline.CI_ID + " AND sms_cirelation.RelationType IN (1, 2, 3, 4) ORDER BY localizeddisplayname"
		$SUForBaseline=Get-Wmiobject -Query $SUQuery -namespace $ConfigMgrNamespace -computername $ConfigMgrServer -Credential $sccmcred

		return $SUForBaseline
	}
}

# FUNCTION to collect software update list from SCCM
function GetAuthSoftwareUpdateFromSCCM
{
	Param( [string] $ConfigMgrServer,
		   [string] $SiteCode = "Default",
		   [string] $UpdateListName = "TestSCCMUpdateListorVMM"		   
	)
	Process 
	{
		$provNamespace = "root\sms"
		$getSMSProvider = Get-WmiObject -Query "select * from SMS_ProviderLocation" -Namespace $provNamespace -ComputerName $ConfigMgrServer -Credential $sccmcred

		if($SiteCode -eq "Default"){
			$ConfigMgrNamespace = $provNamespace + "\site_" + $getSMSProvider.SiteCode
		} else {
			$ConfigMgrNamespace = $provNamespace + "\site_" + $SiteCode
		}

   		# Get the DCM baseline to query
    	$CIUpdateGroup = Get-WmiObject -Class "SMS_AuthorizationList" -filter "LocalizedDisplayName='$UpdateListName'" -namespace $ConfigMgrNamespace -computername $ConfigMgrServer -Credential $sccmcred

		$SUQuery="SELECT SMS_SoftwareUpdate.* FROM SMS_SoftwareUpdate, sms_cirelation WHERE sms_cirelation.ToCIID = SMS_SoftwareUpdate.CI_ID AND sms_cirelation.FromCIID = " + $CIUpdateGroup.CI_ID + " AND sms_cirelation.RelationType IN (1, 2, 3, 4) ORDER BY localizeddisplayname"
		$SUForBaseline=Get-Wmiobject -Query $SUQuery -namespace $ConfigMgrNamespace -computername $ConfigMgrServer -Credential $sccmcred

		return $SUForBaseline
	}
}

