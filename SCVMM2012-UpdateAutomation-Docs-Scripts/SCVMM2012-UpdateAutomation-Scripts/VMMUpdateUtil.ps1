# Function to get current week of month
Function Get-WeekOfMonth ([datetime]$Date = $(Get-Date)) {
     $firstDayOfMonth = $Date.AddDays($Date.Day - $Date.Day + 1);
	 $lastDayOfMonth = $firstDayOfMonth.AddMonths(1).AddDays(-1);
	 $currDayOfMonth = $Date
	 $Culture = [System.Globalization.CultureInfo]::CurrentCulture
	 $currWeek = $Culture.Calendar.GetWeekOfYear($currDayOfMonth, [System.Globalization.CalendarWeekRule]::FirstFourDayWeek, [DayOfWeek]::Monday);     
	 $firstWeek = $Culture.Calendar.GetWeekOfYear($firstDayOfMonth, [System.Globalization.CalendarWeekRule]::FirstFourDayWeek, [DayOfWeek]::Monday);   
     return $currWeek - $firstWeek + 1;
}

# FUNCTION to check current time is in Servicing Window or not
function CheckCurrTimeInSW 
{
	Param( [string] $swName )
	Process 
	{
		$sw=get-scservicingwindow -Name $swName
		$sw
		if($sw -eq $null) {	
			$message="ERROR: No SW record exists by Name : " + $swName
			UpdateLogFile $message
			$global:retFlag=1
			return
		}
		
		$swdatetimefrom=$sw.GetStartDateTimeInLocalTimeZone()
		$message="INFO: SW in LocalTimeZone : " + $swdatetimefrom.ToString()
		UpdateLogFile $message

		$swdatefrom=$swdatetimefrom.get_Date()
		$swtimefrom=$swdatetimefrom.get_TimeOfDay()
		$swtimeto=$swdatetimefrom.AddMinutes($sw.MinutesDuration).get_TimeOfDay()
		
		$message="INFO: SW Record Date : " + $swdatefrom.ToString()
		UpdateLogFile $message
		$message="INFO: SW Record From Time : " + $swtimefrom.ToString()
		UpdateLogFile $message
		$message="INFO: SW Record To Time : " + $swtimeto.ToString()
		UpdateLogFile $message
		
		$swdatefromtmp = $swdatefrom
		$swtimefromtmp = $swtimefrom
		$swtimetotmp = $swtimeto

		$currdatetime=[System.DateTime]::Now;

		$message="INFO: Current Date Time : " + $currdatetime.ToString()
		UpdateLogFile $message
		
		$currdatetmp = $currdatetime.get_Date();
		$message="INFO: Current Date : " + $currdatetmp.ToString()
		UpdateLogFile $message
		
		$currtimetmp = $currdatetime.get_TimeOfDay();
		$message="INFO: Current Time : " + $currtimetmp.ToString()
		UpdateLogFile $message
		
		$dailyScheduleType=[Microsoft.VirtualManager.Remoting.ServicingWindowScheduleType]::Daily
		$weeklyScheduleType=[Microsoft.VirtualManager.Remoting.ServicingWindowScheduleType]::Weekly
		$monthlyScheduleType=[Microsoft.VirtualManager.Remoting.ServicingWindowScheduleType]::Monthly
		$monthlyRelativeScheduleType=[Microsoft.VirtualManager.Remoting.ServicingWindowScheduleType]::MonthlyRelative

		if($sw.ScheduleType -eq $monthlyScheduleType){
			$dayOfMonth=$currdatetmp.Day
			if($sw.DayOfMonth -ne $dayOfMonth){
 				$message="ERROR: Today's date not match the concerned DAY for Monthly maintenance SW Day : " + $sw.DayOfMonth + "Today's Day :" + $dayOfMonth
				UpdateLogFile $message
				$global:retFlag=1					
				return
			}
		}
		
		if($sw.ScheduleType -eq $monthlyRelativeScheduleType){
			if($sw.MonthlyScheduleDayOfWeek -ne $currdatetmp.DayOfWeek){
				$message="ERROR: Today's date not match the concerned WEEK DAY for Monthly Relative maintenance SW WEEK Day : " + $sw.MonthlyScheduleDayOfWeek + "Today's WEEK Day :" + $currdatetmp.DayOfWeek
				UpdateLogFile $message
				$global:retFlag=1					
				return
			}
			$weeksInMonths=Get-WeekOfMonth $currdatetmp
			switch($weeksInMonths){
				1 {
				    $noOfWeeksInMonths = [Microsoft.VirtualManager.Remoting.WeekOfMonthType]::First
				}	
				2 {
					$noOfWeeksInMonths = [Microsoft.VirtualManager.Remoting.WeekOfMonthType]::Second
				}
				3 {
					$noOfWeeksInMonths = [Microsoft.VirtualManager.Remoting.WeekOfMonthType]::Third
				}
				4 {
					$noOfWeeksInMonths = [Microsoft.VirtualManager.Remoting.WeekOfMonthType]::Fourth
				}
				5 {
					$noOfWeeksInMonths = [Microsoft.VirtualManager.Remoting.WeekOfMonthType]::Last
				}
			}

			if($sw.WeekOfMonth -ne $noOfWeeksInMonths){
				$message="ERROR: Today's date not match the concerned WEEK for Monthly Relative maintenance SW WEEK : " + $sw.WeekOfMonth + "Today's WEEK :" + $noOfWeeksInMonths
				UpdateLogFile $message
				$global:retFlag=1					
				return
			}
		}

		if($sw.ScheduleType -eq $weeklyScheduleType){
		    $currDayOfWeek = $currdatetmp.DayOfWeek
			$splitWeeklyScheduleDayOfWeek=@()
			$splitWeeklyScheduleDayOfWeek=$sw.WeeklyScheduleDayOfWeek -split ","
			$currdateInWeek=0
			foreach($splitItem in $splitWeeklyScheduleDayOfWeek){
				Write-Host $splitItem.Trim()
				if($splitItem.Trim() -match $currDayOfWeek){
					$currdateInWeek=1
					break;
				}
			}
			if($currdateInWeek -eq 0){
	 			Write-Host "Current date is NOT in DayOFWeek List"
				$message="Today's date not match the concerned WEEK Days for Weekly maintenance"
				UpdateLogFile $message				
				$global:retFlag=1					
				return
			}
		}
				
		$dateFlag=0
		while($swdatefromtmp -le $currdatetmp){
			$message="INFO: Next Maintenance Date : " + $swdatefromtmp.DateTime
			UpdateLogFile $message				
				
			if($currdatetmp -eq $swdatefromtmp){
				$message="INFO: Today's day match Maintenance Date : " + $swdatefromtmp
				UpdateLogFile $message				
	 			$dateFlag=1
				break;
	 		}
			
			if($sw.ScheduleType -eq $dailyScheduleType){
	 			$swdatefromtmp=$swdatefromtmp.AddDays($sw.DaysToRecur)
			}
			if($sw.ScheduleType -eq $weeklyScheduleType){
			    if($swdatefromtmp.DayOfWeek -eq $currdatetmp.DayOfWeek){				  
				  $swdatefromtmp=$swdatefromtmp.AddDays(+7 * $sw.WeeksToRecur)
				} else {
	 			  $swdatefromtmp=$swdatefromtmp.AddDays(+1)
				}
			}			
			if($sw.ScheduleType -eq $monthlyScheduleType){
			    if($swdatefromtmp.Day -eq $currdatetmp.Day){
				  $noDaysInMonth = [datetime]::DaysInMonth($swdatefromtmp.Year, $swdatefromtmp.Month)
				  $swdatefromtmp=$swdatefromtmp.AddDays($noDaysInMonth * $sw.MonthsToRecur)
				} else {
	 			  $swdatefromtmp=$swdatefromtmp.AddDays(+1)
				}
			}			
			if($sw.ScheduleType -eq $monthlyRelativeScheduleType){
			    if($swdatefromtmp.Day -eq $currdatetmp.Day){
				  $noDaysInMonth = [datetime]::DaysInMonth($swdatefromtmp.Year, $swdatefromtmp.Month)
				  $swdatefromtmp=$swdatefromtmp.AddDays($noDaysInMonth * $sw.MonthsToRecur)
				} else {
	 			  $swdatefromtmp=$swdatefromtmp.AddDays(+1)
				}
			}						
		}

		if($dateFlag -eq 1){
		    $maintdatetimefrom = [datetime]($swdatefromtmp + $swtimefromtmp)
			$message="INFO: Maintenance start date/time : " + $maintdatetimefrom.ToString()
			UpdateLogFile $message
			$maintdatetimeto = $maintdatetimefrom.AddMinutes($sw.MinutesDuration)
			$message="INFO: Maintenance end date/time : " + $maintdatetimeto.ToString()
			UpdateLogFile $message
			
			$message="INFO: Today's current date time : " + $currdatetime.ToString()
			UpdateLogFile $message

	 		if ( ([System.DateTime]::Compare($currdatetime, $maintdatetimefrom) -ge 0) -and 
			     ([System.DateTime]::Compare($currdatetime, $maintdatetimeto) -le 0) )
			{
				$message="INFO: Today's date & time match SW time"
				UpdateLogFile $message
	 		} else {
				$message="ERROR: Today's date matched, whereas TIME NOT matched SW time"
				UpdateLogFile $message
				$global:retFlag=1					
			}
	 	}else {
				$message="ERROR: Today's date NOT matched SW maint. date"
				UpdateLogFile $message
				$global:retFlag=1					
		}
	}
}

# FUNCTION to perform Update Server Synchronization
function SyncUpdateServer
{
	#Param( [string] $updtServer )
	Begin 
	{
		#$us=get-scupdateserver -ComputerName $updtServer
		$us=get-scupdateserver
		$us
		if($us -eq $null) {	
			$message="ERROR: No Update Server Found by Name : " + $updtServer
			UpdateLogFile $message
			$global:retFlag=1
			return
		}
	}
	Process 
	{	
		$syncUpdateServer = Start-SCUpdateServerSynchronization -UpdateServer $us -RunAsynchronously
		if ($syncUpdateServer -ne $null){
			$message="INFO: Update Server Sync Job Submitted For : " + $updtServer
			UpdateLogFile $message 			
		} else {
			$message="ERROR: Update Server Sync Job Submission Failed : " + $updtServer
			UpdateLogFile $message
		    $global:retFlag=1
		}		
	}
	End
	{
		#Start-Sleep 5 #wait few seconds for the job to start
		$cmdletName = "Start-SCUpdateServerSynchronization"
		WaitForLatJobComplete $cmdletName
		if($retFlag -eq 1){
			$message="Failed checking job for Update Server Sync Return Code:" + $retFlag
			UpdateLogFile $message
			return
		}
		$message="INFO: LastSynchronizationStartTime :" + $syncUpdateServer.LastSynchronizationDetails.LastSynchronizationStartTime
		UpdateLogFile $message
		$message="INFO: LastSynchronizationEndTime :" + $syncUpdateServer.LastSynchronizationDetails.LastSynchronizationEndTime
		UpdateLogFile $message
		$message="INFO: LastSynchronizationResult :" + $syncUpdateServer.LastSynchronizationDetails.LastSynchronizationResult
		UpdateLogFile $message
		$message="INFO: LastSynchronizationResultString :" + $syncUpdateServer.LastSynchronizationDetails.LastSynchronizationResultString
		UpdateLogFile $message
		$message="INFO: LastSynchronizationError :" + $syncUpdateServer.LastSynchronizationDetails.LastSynchronizationError
		UpdateLogFile $message
		$message="INFO: NumberOfNewUpdates :" + $syncUpdateServer.LastSynchronizationDetails.NumberOfNewUpdates
		UpdateLogFile $message
		$message="INFO: NumberOfRevisedUpdates :" + $syncUpdateServer.LastSynchronizationDetails.NumberOfRevisedUpdates
		UpdateLogFile $message
		$message="INFO: NumberOfExpiredUpdates :" + $syncUpdateServer.LastSynchronizationDetails.NumberOfExpiredUpdates
		UpdateLogFile $message
		$message="INFO: NumberOfErrors :" + $syncUpdateServer.LastSynchronizationDetails.NumberOfErrors
		UpdateLogFile $message
	}
}

# FUNCTION to perform Compliance Scan for all Baselines for all assigned scope
function StartComplianceScan-All
{
	Param( )
	Process 
	{
		$baseLines=Get-SCBaseLine
        if($baseLines -eq $null){
			$message="ERROR: No Baseline Record Exists for Compliance Scan "
			UpdateLogFile $message
			$global:retFlag=1
			return
		}
		
		foreach($baseLine in $baseLines){
			$assignScopes = $baseLine.AssignmentScopes
			foreach($assignScope in $assignScopes){
				if($assignScope.ComputerName -ne $null){
					$message="INFO: Compliance Scan For Baseline - " + $baseLine.Name + " Assigned Computer Scope :" + $assignScope.ComputerName
					UpdateLogFile $message
				    StartComplianceScan-ForComputer -computerFQDN $assignScope.FQDN -baseLineName $baseLine.Name
                } elseif($assignScope.Path -ne $null) {
					$message="INFO: Compliance Scan For Baseline - " + $baseLine.Name + " Assigned Hostgroup Scope :" + $assignScope.Name
					UpdateLogFile $message
					StartComplianceScan-ForHostGroup -hostGroup $assignScope.Name -baseLineName $baseLine.Name
				} elseif($assignScope.ClusterName -ne $null) {
					$message="INFO: Compliance Scan For Baseline - " + $baseLine.Name + " Assigned Cluster Scope :" + $assignScope.ClusterName
					UpdateLogFile $message
					StartComplianceScan-ForHostCluster -hostCluster $assignScope.Name -baseLineName $baseLine.Name
				}
				if($retFlag -eq 1){
					$message="ERROR: Compliance Scan Failed For Baseline :" + $baseLine.Name
					UpdateLogFile $message
					return
				}
			}
		}
	}
}

# FUNCTION to perform Compliance Scan for VMM Managed Computers
function StartComplianceScan-ForComputer
{
	Param( [string] $computerFQDN, [string] $baseLineName )
	Process 
	{
		$vmmManagedComputer = Get-SCVMMManagedComputer | where {$_.FQDN -eq $computerFQDN}
		if($vmmManagedComputer -eq $null){
			$message="ERROR: No VMMManagedComputer exists by Name :" + $computerFQDN
			UpdateLogFile $message
			$global:retFlag=1
			return
		}
		$baseLines=Get-SCBaseLine -Name $baseLineName
		if($baseLines -eq $null){
			$message="ERROR: Invalid Baseline Name :" + $baseLineName
			UpdateLogFile $message
			$global:retFlag=1
			return 
		}

		foreach($baseLine in $baseLines){
				$scanComputer = Start-SCComplianceScan -BaseLine $baseLine -VMMManagedComputer $vmmManagedComputer -RunAsynchronously
				if ($scanComputer -ne $null){
					$message="INFO: Update Compliance Scan Job Submitted For Baseline : " + $baseLine.Name + "For Computer:" + $computerFQDN
					UpdateLogFile $message 			
					$script:noOfJobs++
				} else {
					$message="ERROR: Update Compliance Scan Job Failed For Baseline : " + $baseLine.Name + "For Computer:" + $computerFQDN
					UpdateLogFile $message
		    		$global:retFlag=1
					return
				}		
		}
	}
}

# FUNCTION to perform Compliance Scan for Host clusters in assigned scope
function StartComplianceScan-ForHostCluster
{
	Param( [string] $hostCluster, [string] $baseLineName )
	Process 
	{
		$hostClusterObj = Get-SCVMHostCluster -Name $hostCluster
		if($hostClusterObj -eq $null){
			$message="ERROR: No HostCluster exists by Name :" + $hostCluster
			UpdateLogFile $message
			$global:retFlag=1
			return
		}
		$baseLines=Get-SCBaseLine -Name $baseLineName
		if($baseLines -eq $null){
			$message="ERROR: No Baseline record exists by Name :" + $baseLineName
			UpdateLogFile $message
			$global:retFlag=1
			return 
		}

		foreach($baseLine in $baseLines){
				$scanComputer = Start-SCComplianceScan -BaseLine $baseLine -VMHostCluster $hostClusterObj -RunAsynchronously
				if ($scanComputer -ne $null){
					$message="INFO: Compliance Scan Job submitted For cluster :" + $hostCluster
					UpdateLogFile $message
					$script:noOfJobs++
				} else {
					$message="ERROR: Compliance Scan Job Failed For cluster :" + $hostCluster
					UpdateLogFile $message
		    		$global:retFlag=1
					return
				}
		}
	}
}

# FUNCTION to perform Compliance Scan for Host groups in assigned scope
function StartComplianceScan-ForHostGroup
{
	Param( [string] $hostGroup, [string] $baseLineName )
	Process 
	{
		$hgObj = Get-SCVMHostGroup -Name $hostGroup
		if($hgObj -eq $null){
			$message="ERROR: No HostGroup exists by name :" + $hostGroup
			UpdateLogFile $message
			$global:retFlag=1
			return 
		}

        $hostClusterObjs = Get-SCVMHostCluster -VMHostGroup $hgObj
		if($hostClusterObjs -ne $null){
		    foreach($hostClusterObj in $hostClusterObjs){
				StartComplianceScan-ForHostCluster -hostCluster $hostClusterObj.Name -baseLineName $baseLineName
			}
		}
		
		$hostObjs = Get-SCVMHost -VMHostGroup $hgObj | where {$_.HostCluster -eq $null}
		if($hostObjs -ne $null){
		    foreach($hostObj in $hostObjs){
				StartComplianceScan-ForComputer -computerFQDN $hostObj.FQDN -baseLineName $baseLineName
			}
		}
	}
}

# FUNCTION to perform Compliance Scan for a given baseline 
function StartComplianceScan-ForBaseLine
{
	Param( [string] $baseLineName )
	Process
	{
		$baseLine=Get-SCBaseLine -Name $baseLineName
		$baseLine
		if($baseLine -eq $null){
			Write-Host "No Base Line Data for Compliance Scan Exists"
			$global:retFlag=1
			return 
		}
	
			$assignScopes = $baseLine.AssignmentScopes
			foreach($assignScope in $assignScopes){
				if($assignScope.ComputerName -ne $null){
				    StartComplianceScan-ForComputer -computerFQDN $assignScope.FQDN -baseLineName $baseLine.Name
                } elseif($assignScope.Path -ne $null) {
					StartComplianceScan-ForHostGroup -hostGroup $assignScope.Name -baseLineName $baseLine.Name
				}
				if($retFlag -eq 1){
					Write-Host "Failed to do compliance scan"
					return
				}
			}
	}
}

# FUNCTION to perform compliance scan for a given baseline and an assigned scope
function StartComplianceScan-ForBaseLineForComputer
{
	Param( [string] $baseLine, [string] $scopeName )
	Process
	{
		$baseLine=Get-SCBaseLine -Name $baseLine
		$baseLine
		if($baseLine -eq $null){
			Write-Host "No Base Line Data for Compliance Scan Exists"
			$global:retFlag=1
			return 
		}

		$assignScopes = $baseLine.AssignmentScopes
		foreach($assignScope in $assignScopes){
			if($assignScope.ComputerName -eq $scopeName){
		    	StartComplianceScan-ForComputer -computerFQDN $assignScope.FQDN -baseLineName $baseLine.Name
        	} elseif($assignScope.Path -eq $scopeName) {
				StartComplianceScan-ForHostGroup -hostGroup $assignScope.Name -baseLineName $baseLine.Name
			}
			if($retFlag -eq 1){
				Write-Host "Failed to do compliance scan"
				return
			}
		}
	}
}

# FUNCTION to remediate all baselines for all assigned scope
function StartComplianceRemediate-All
{
	Param( [bool] $forced )
	Process 
	{
		$baseLines=Get-SCBaseLine
        if($baseLines -eq $null){
			$message="ERROR: No Baseline Record Exists for Compliance Remediate "
			UpdateLogFile $message
			$global:retFlag=1
			return
		}
		
		foreach($baseLine in $baseLines){
			$assignScopes = $baseLine.AssignmentScopes
			foreach($assignScope in $assignScopes){
				if($assignScope.ComputerName -ne $null){
					$message="INFO: Compliance Remediate For Baseline :" + $baseLine.Name + " Assigned Computer Scope :" + $assignScope.ComputerName
					UpdateLogFile $message
					StartComplianceRemediate-ForComputer -computerFQDN $assignScope.FQDN -baseLineName $baseLine.Name -forced $forced
                } elseif($assignScope.Path -ne $null) {
					$message="INFO: Compliance Remediate For Baseline :" + $baseLine.Name + " Assigned Hostgroup Scope :" + $assignScope.Name
					UpdateLogFile $message
					StartComplianceRemediate-ForHostGroup -hostGroup $assignScope.Name -baseLineName $baseLine.Name -forced $forced
				} elseif($assignScope.ClusterName -ne $null) {
					$message="INFO: Compliance Remediate For Baseline " + $baseLine.Name + " Assigned Cluster Scope :" + $assignScope.ClusterName
					UpdateLogFile $message
					StartComplianceRemediate-ForHostClusterNode -hostCluster $assignScope.Name -baseLineName $baseLine.Name
				}
				if($retFlag -eq 1){
					$message="ERROR: Compliance Remediate Failed For Baseline :" + $baseLine.Name
					UpdateLogFile $message
					return
				}
			}
		}
	}
}

# FUNCTION to remediate baseline for VMM Managed Computer
function StartComplianceRemediate-ForComputer
{
	Param( [string] $computerFQDN, [string] $baseLineName, [bool] $forced )
	Process 
	{
		$vmmManagedComputer = Get-SCVMMManagedComputer | where {$_.FQDN -eq $computerFQDN}
		if($vmmManagedComputer -eq $null){
			$message="ERROR: No VMMManagedComputer exists by Name :" + $computerFQDN
			UpdateLogFile $message
			$global:retFlag=1
			return		
		}
        if($forced -eq $false){
			$message="INFO: Remediation will be done only for non-compliant VMM Managed computers"
			UpdateLogFile $message 			
			$complianceStatus=Get-SCComplianceStatus -VMMManagedComputer $vmmManagedComputer
		} else {
			$message="INFO: Remediation will be done forcibly for all VMM Managed computers"
			UpdateLogFile $message 			
		}
		if($complianceStatus.Status.Length -gt 0){
			$message="INFO: Skipping Computer" + $vmmManagedComputer.FQDN + "as there is pending action on it " + $complianceStatus.StatusString
			UpdateLogFile $message 			
			return
		}
				
		$baseLines=Get-SCBaseLine -Name $baseLineName
		if($baseLines -eq $null){
			$message="ERROR: Invalid Baseline Name :" + $baseLineName
			UpdateLogFile $message
			$global:retFlag=1
			return			
		}

		foreach($baseLine in $baseLines){
				if($forced -eq $false){
					$baseLineLevelComplianceStatus = $complianceStatus.BaseLineLevelComplianceStatus | where {$_.BaseLine -eq $baseLine.Name}
					if($baseLineLevelComplianceStatus.BaselineLevelComplianceState -eq "Compliant"){
						$message="INFO: Skipping Computer" + $vmmManagedComputer.FQDN + "already compliant for BaseLine" + $baseLine.Name
						UpdateLogFile $message 			
						continue
					}
				}
				
				$remediateComputer = Start-SCUpdateRemediation -BaseLine $baseLine -VMMManagedComputer $vmmManagedComputer -RunAsynchronously
				if ($remediateComputer -ne $null){
					$message="INFO: Update Compliance Remediate Job Submitted For Baseline : " + $baseLine.Name + "For Computer:" + $computerFQDN
					UpdateLogFile $message 			
					$script:noOfJobs++
				} else {
					$message="ERROR: Update Compliance Remediate Job Failed For Baseline : " + $baseLine.Name + "For Computer:" + $computerFQDN
					UpdateLogFile $message
		    		$global:retFlag=1
					return
				}		
		}
	}
}

# FUNCTION to perform remediate baselines for all host clusters in assigned scope
function StartComplianceRemediate-ForHostClusterAll
{
	Param( [string] $hostCluster, [string] $baseLineName,[bool] $forced )
	Process 
	{
		$hostClusterObj = Get-SCVMHostCluster -Name $hostCluster
		if($hostClusterObj -eq $null){
			$message="ERROR: No HostCluster exists by Name :" + $hostCluster
			UpdateLogFile $message
			$global:retFlag=1
			return			
		}
		$baseLines=Get-SCBaseLine -Name $baseLineName
		if($baseLines -eq $null){
			$message="ERROR: No Baseline record exists by Name :" + $baseLineName
			UpdateLogFile $message
			$global:retFlag=1
			return			
		}

		foreach($baseLine in $baseLines){
			$remediateComputer = Start-SCUpdateRemediation -BaseLine $baseLine -VMHostCluster $hostClusterObj -SuspendReboot -RemediateAllClusterNodes -RunAsynchronously
			if ($remediateComputer -ne $null){
				$message="INFO: Compliance Remediate Job submitted For cluster :" + $hostCluster
				UpdateLogFile $message
				$script:noOfJobs++
			} else {
				$message="ERROR: Compliance Remediate Job Failed For cluster :" + $hostCluster
				UpdateLogFile $message
		    	$global:retFlag=1
				return
			}
		}
	}
}

# FUNCTION to perform remediate for cluster node in assigned scope
function StartComplianceRemediate-ForHostClusterNode
{
	Param( [string] $hostCluster, [string] $baseLineName, [bool] $forced )
	Process 
	{
		$hostClusterObj = Get-SCVMHostCluster -Name $hostCluster
		if($hostClusterObj -eq $null){
			$message="ERROR: No HostCluster exists by Name :" + $hostCluster
			UpdateLogFile $message
			$global:retFlag=1
			return			
		}
		
		$baseLines=Get-SCBaseLine -Name $baseLineName
		if($baseLines -eq $null){
			$message="ERROR: No Baseline record exists by Name :" + $baseLineName
			UpdateLogFile $message
			$global:retFlag=1
			return			
		}

		foreach($baseLine in $baseLines){
			$jobGroupId=[Guid]::NewGuid().ToString();
			$noOfNonCompliantNodes=0
			foreach($hostClusterNode in $hostClusterObj.Nodes){
				$complianceStatus=Get-SCComplianceStatus | where {$_.Name -eq $hostClusterNode.FullyQualifiedDomainName}
				if($complianceStatus -ne $null -and $complianceStatus.Status.Length -gt 0){
					$message="INFO: Skipping Computer " + $hostClusterNode.FullyQualifiedDomainName + " as there is pending action on it " + $complianceStatus.StatusString
					UpdateLogFile $message 			
					continue
				}					
				
				if($forced -eq $false){
					$baseLineLevelComplianceStatus = $complianceStatus.BaseLineLevelComplianceStatus | where {$_.BaseLine -eq $baseLine.Name}
					if($baseLineLevelComplianceStatus.BaselineLevelComplianceState -eq "Compliant"){
						$message="INFO: Skipping Computer " + $hostClusterNode.FullyQualifiedDomainName + " already compliant for BaseLine" + $baseLine.Name
						UpdateLogFile $message 			
						continue
					}
				}

				$message="INFO: Adding Job For : Start-SCUpdateRemediation -BaseLine " + $baseLine + "-VMHostCluster " + $hostClusterObj + "-VMHost" + $hostClusterNode 
				UpdateLogFile $message
				Start-SCUpdateRemediation -BaseLine $baseLine -VMHostCluster $hostClusterObj -VMHost $hostClusterNode -SuspendReboot -RunAsynchronously -JobGroup $jobGroupId
				$noOfNonCompliantNodes++
			}
			$noOfNonCompliantNodes
			if($noOfNonCompliantNodes -gt 0){
				$remediateCluster = Start-SCUpdateRemediation -VMHostCluster $hostClusterObj -JobGroup $jobGroupId -RunAsynchronously -StartNow
				if ($remediateCluster -ne $null){
					$message="INFO: Compliance Remediate Job submitted For cluster nodes :" + $hostCluster
					UpdateLogFile $message
					$script:noOfJobs++
				} else {
					$message="ERROR: Compliance Remediate Job Failed For cluster nodes :" + $hostCluster
					UpdateLogFile $message
		    		$global:retFlag=1
					return
				}
			}
		}
	}
}

# FUNCTION to remediate baselines for all host groups in assigned scope
function StartComplianceRemediate-ForHostGroup
{
	Param( [string] $hostGroup, [string] $baseLineName, [bool] $forced )
	Process 
	{
		$hgObj = Get-SCVMHostGroup -Name $hostGroup
		if($hgObj -eq $null){
			$message="ERROR: No HostGroup exists by name :" + $hostGroup
			UpdateLogFile $message
			$global:retFlag=1
			return			
		}

        $hostClusterObjs = Get-SCVMHostCluster -VMHostGroup $hgObj
		if($hostClusterObjs -ne $null){
		    foreach($hostClusterObj in $hostClusterObjs){
				StartComplianceRemediate-ForHostClusterNode -hostCluster $hostClusterObj.Name -baseLineName $baseLineName -forced $forced
			}
		}
		
		$hostObjs = Get-SCVMHost -VMHostGroup $hgObj | where {$_.HostCluster -eq $null}
		if($hostObjs -ne $null){
		    foreach($hostObj in $hostObjs){
				StartComplianceRemediate-ForComputer -computerFQDN $hostObj.FQDN -baseLineName $baseLineName -forced $forced
			}
		}
	}
}

# FUNCTION to remediate a given baseline
function StartComplianceRemediate-ForBaseLine
{
	Param( [string] $baseLineName )
	Process
	{
		$baseLine=Get-SCBaseLine -Name $baseLineName
		$baseLine
		if($baseLine -eq $null){
			Write-Host "No Base Line Data for Compliance Scan Exists"
			$global:retFlag=1
			return 
		}
	
			$assignScopes = $baseLine.AssignmentScopes
			foreach($assignScope in $assignScopes){
				if($assignScope.ComputerName -ne $null){
				    StartComplianceRemediate-ForComputer -computerFQDN $assignScope.FQDN -baseLineName $baseLine.Name
                } elseif($assignScope.Path -ne $null) {
					StartComplianceRemediate-ForHostGroup -hostGroup $assignScope.Name -baseLineName $baseLine.Name
				}
				if($retFlag -eq 1){
					Write-Host "Failed to do compliance scan"
					return
				}
			}
	}
}

# FUNCTION to remediate a baseline for a VMM Managed computer
function StartComplianceRemediate-ForBaseLineForComputer
{
	Param( [string] $baseLine, [string] $scopeName )
	Process
	{
		$baseLine=Get-SCBaseLine -Name $baseLine
		$baseLine
		if($baseLine -eq $null){
			Write-Host "No Base Line Data for Compliance Scan Exists"
			$global:retFlag=1
			return 
		}

		$assignScopes = $baseLine.AssignmentScopes
		foreach($assignScope in $assignScopes){
			if($assignScope.ComputerName -eq $scopeName){
		    	StartComplianceRemediate-ForComputer -computerFQDN $assignScope.FQDN -baseLineName $baseLine.Name
        	} elseif($assignScope.Path -eq $scopeName) {
				StartComplianceRemediate-ForHostGroup -hostGroup $assignScope.Name -baseLineName $baseLine.Name
			}
			if($retFlag -eq 1){
				Write-Host "Failed to do compliance scan"
				return
			}
		}
	}
}

# FUNCTION to update Baseline from the list of KBs (from other systems - SCCM)
function AddUpdateToVMMBaseline
{
	Param( [string[]] $KBArticle, [string] $BaselineName, [bool] $Purged )
	Process
	{
		$JobGroup=[Guid]::NewGuid().ToString();

	    $baseLine=Get-SCBaseLine -Name $BaselineName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
		if($baseLine -eq $null){
			$message="INFO: No Base Line Exists For Name" + $baseLineName
			UpdateLogFile $message
			$baseLine=New-SCBaseline -Name $BaselineName -Description "Created For SCCM baseline sync" 
			$baseLine=Get-SCBaseLine -Name $BaselineName
			if($baseLine -eq $null){
				$message="ERROR: Failed to create new baseline : " + $BaseLineName
				UpdateLogFile $message
				$global:retFlag=1
				return
			}
		}
		if($Purged -eq $true){
			$removeUpdates=$baseLine.Updates 
			$setSCBaseLine=Set-SCBaseLine -BaseLine $baseLine -RemoveUpdates $removeUpdates
			$baseLine=Get-SCBaseLine -Name $BaselineName
			$message="INFO: Purged all updates for baseline : " + $BaseLineName
			UpdateLogFile $message
		}
		
		$baseLineUpdateCount=0	
		foreach($Article in $KBArticle){
			$updateValue = $Article.split(",")
			$KB=$updateValue[0]
			$ID=$updateValue[1]
			$Rev=$updateValue[2]
			$EA=$updateValue[3]
			$EE=$updateValue[4]
			$ESOD=$updateValue[5]
			$ESOU=$updateValue[6]
				
			$catalogUpdates=Get-SCUpdate -KBArticle $KB | where {$_.UpdateId -eq $ID -and $_.RevisionId -eq $Rev }
			if($catalogUpdates -eq $null){
				$message="INFO: Missing Catalog Update For Article : " + $KB + " Update ID: " + $ID + " Revision No. : " + $Rev
				UpdateLogFile $message
				continue 
			}

			foreach($catalogUpdate in $catalogUpdates){
				$baseLineUpdate=$baseLine.Updates | where {$_.ID -eq $catalogUpdate.ID}
				if($baseLineUpdate -ne $null){
					$message="INFO: Update added already to baseline : " + $BaselineName + " For Article : " + $KB + " Update ID: " + $ID + " Revision No. : " + $Rev
					UpdateLogFile $message
					continue 
				}
				
				$message="INFO: Adding Job For : Set-SCBaseline -BaseLine " + $baseLine + " -AddUpdates " + $catalogUpdate
				UpdateLogFile $message				
				$baseLineSet=Set-SCBaseLine -Baseline $baseLine -AddUpdates $catalogUpdate -JobGroup $JobGroup -RunAsynchronously
				$baseLineUpdateCount += 1
			}
		}
		if($baseLineUpdateCount -gt 0){
			$baseLineSet=Set-SCBaseLine -Baseline $baseLine -JobGroup $JobGroup -RunAsynchronously -StartNow
			if($baseLineSet -eq $null){
				$message="ERROR: Failed to add update to baseline : " + $BaselineName + " For Article : " + $KB + "Update ID : " + $ID + " Revision No. : " + $Rev
				UpdateLogFile $message
				$global:retFlag=1
				return 
			}
			#$script:noOfJobs++
			return $baseLineUpdateCount
		}
	}
}

# FUNCTION to wait for all jobs of a cmdlet to complete
function WaitForAllJobComplete 
{
	Param( [string] $cmdletName )
	Process 
	{
		Start-Sleep 5 #wait few seconds for the job to start
		$jobCount=$script:noOfJobs
		Write-Host $script:noOfJobs
		Write-Output "Job started running for cmdlet" $cmdletName
		$runningjobs = Get-SCJob | where {  $_.CmdletName -eq $cmdletName }
        if($runningjobs.Length -gt 0){
			while($jobCount -gt 0){
				$latestrunningjob = $runningjobs[$jobCount - 1]
				$message="Latest Job Running for Cmdlet :" + $cmdletName + " Job ID :" + $latestrunningjob.ID + " Job Name :" + $latestrunningjob.Name + " Job Progress : " + $latestrunningjob.Progress + " Job status :" + $latestrunningjob.Status
				UpdateLogFile $message		
				while( $latestrunningjob.IsCompleted -eq $FALSE )
				{
					Write-Output "Waiting for the latest job to complete ID:" $latestrunningjob.ID 
					Start-Sleep -Seconds 10
					$latestrunningjob = Get-SCJob -ID $latestrunningjob.ID 
				}
				$message="Latest Job Completed for Cmdlet :" + $cmdletName + " Job ID :" + $latestrunningjob.ID + " Job Name :" + $latestrunningjob.Name + " Job Progress : " + $latestrunningjob.Progress + " Job status :" + $latestrunningjob.Status
				UpdateLogFile $message
				$jobCount = $jobCount - 1
			}		
		} else{
				$message="No jobs were submitted for cmdlet :" + $cmdletName
				UpdateLogFile $message
		}
	}
}

# FUNCTION to wait for the latest job of a cmdlet to complete
function WaitForLatJobComplete 
{
	Param( [string] $cmdletName )
	Process 
	{
		Start-Sleep 5 #wait few seconds for the job to start
		Write-Output "Job started running for cmdlet" $cmdletName
		$runningjobs = Get-SCJob | where {  $_.CmdletName -eq $cmdletName }
        if($runningjobs.Length -gt 0){
			$latestrunningjob = $runningjobs[0]
			$message="Latest Job Started for Cmdlet :" + $cmdletName + " Job ID :" + $latestrunningjob.ID + " Job Name :" + $latestrunningjob.Name + " Job Progress : " + $latestrunningjob.Progress + " Job status :" + $latestrunningjob.Status
			UpdateLogFile $message		
			while( $latestrunningjob.IsCompleted -eq $FALSE )
			{
				Write-Output "Waiting for the latest job to complete ID:" $latestrunningjob.ID 
				Start-Sleep -Seconds 10
				$latestrunningjob = Get-SCJob -ID $latestrunningjob.ID 
			}
			$message="Latest Job Completed for Cmdlet :" + $cmdletName + " Job ID :" + $latestrunningjob.ID + " Job Name :" + $latestrunningjob.Name + " Job Progress : " + $latestrunningjob.Progress + " Job status :" + $latestrunningjob.Status
			UpdateLogFile $message
		} else{
			$message="No jobs were submitted for cmdlet :" + $cmdletName
			UpdateLogFile $message
		}
	}
}

# FUNCTION to update the common log file
function UpdateLogFile
{
	Param( [string] $message, $appendflag=$true )
    Process {
			$logTime=[System.DateTime]::Now.ToString();
			$message = $logTime + "-" + $message
			if($appendflag){
				Write-Output $message | Out-File $scriptout\$logfile.txt -Encoding Default -Append
			} else{
				Write-Output $message | Out-File $scriptout\$logfile.txt -Encoding Default
			}
	}
}
