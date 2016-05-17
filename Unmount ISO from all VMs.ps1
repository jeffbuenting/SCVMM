Import-Module "C:\Program Files\Microsoft System Center 2012 r2\Virtual Machine Manager\bin\psModules\virtualmachinemanager\virtualmachinemanager"
$VMMServer = "RWVA-scvmm"
$VMs = Get-VirtualDVDDrive -VMMServer $VMMServer -All | Where-object {$_.ISO -ne $null} | select-object Name
Foreach ($VM in  $VMs)
{get-virtualDVDDrive -VM $VM.Name | set-VirtualDVDDrive -NoMedia}