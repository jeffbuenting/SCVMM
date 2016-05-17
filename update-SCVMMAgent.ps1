<#
    .Link
        https://technet.microsoft.com/en-us/library/jj613163(v=sc.20).aspx
#>

import-module virtualmachinemanager


$Credential = Get-Credential

Get-SCVMMManagedComputer | Update-SCVMMManagedComputer -Credential $Credential
