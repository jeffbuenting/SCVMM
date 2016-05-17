<#
    .Description 
        
#>

$Year = Get-Date -UFormat %Y
$BaseLine = "$Year - Patches"

import-module virtualmachinemanager

$SCVMM = Get-SCVMMServer -ComputerName RWVA-SCVMM

# ----- Dealing with Hosts from this cluster
$HostCluster = Get-SCVMHostCluster -Name RWVA -VMMServer $SCVMM

# ----- Scan for Compliance.  Need to do this as previously new Udate potentially were copied to the baseline
#Start-SCComplianceScan -VMHostCluster $HostCluster

# ----- Check for compliance
$NotCompliant = get-scvmhost -VMHostCluster $HostCluster | Select-Object -ExpandProperty ManagedComputer | Get-SCComplianceStatus -VMMServer $SCVMM |  where OverallComplianceState -ne 'Compliant' 

# ----- If any were not compliant.  Remediate.
if ( $NotCompliant -ne $Null ) {
    Write-Output "Looks like at least one host needs to be patched.`n`nRemediating Cluster" 
    #Start-SCUpdateRemediation -VMMServer $SCVMM -VMHostCluster (get-scvmhost -VMHostCluster $HostCluster) -Baseline (Get-SCBaseline -Name $BaseLine  ) -UseLiveMigration -RemediateAllClusterNodes
}

