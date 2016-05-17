<#
    .Description
        retrieves updates from the SCCM Software update group and adds them to the SCVMM Baseline

    .Note
        Author: Jeff Buenting
        Date: 28 Jul 2015
#>

$Year = Get-Date -UFormat %Y

$SoftwareUpdateGroup = "$Year - Patches"

import-module virtualmachinemanager
Import-Module C:\Scripts\SCVMM\SCVMM_Module.psm1 -Force

import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')

set-location RWV:

# ----- Sych VMM with WSUS and wait for job to finish
Start-Job -Name Sync -scriptblock { Start-SCUpdateServerSynchronization -UpdateServer (Get-SCUpdateServer -ComputerName rwva-sccm) }
wait-job -Name Sync

# ----- Since what patches are applied to the Hyper-V hosts is handled by SCCM, Any removed patch from the softwareupdate group needs to be removed from the SCVMM Baseline.
# ----- Easiest way to do that is to remove all updates prior to adding updates from the SUG.  This way if an update has been removed from the SUG it will no be retained
# ----- in the SCVMM Baseline
Remove-SCVMMUpdateFromBaseline -Name $SoftwareUpdateGroup

# ----- Sync VMM Baseline with SCCM Software update Group
Get-CMSoftwareUpdate -UpdateGroupName $SoftwareUpdateGroup | Select-object -ExpandProperty articleid | Add-SCVMMUpdateToBaseline -Name $SoftwareUpdateGroup -Verbose
