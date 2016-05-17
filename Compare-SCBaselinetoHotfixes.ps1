$InstalledPatches = get-hotfix -ComputerName 'cl-hyperv1' | Select-object @{N='KBArticle'; E={$_.HotFixID -replace 'KB',''}}

$BaselinePatches = (Get-SCBaseline -VMMServer 'rwva-scvmm' -Name '2015 - Patches').Updates | where {(( $_.IsExpired -eq $False) -and ($_.IsSuperseded -eq $False ))  }

#$BaselinePatches

Compare-Object -ReferenceObject $InstalledPatches -DifferenceObject $BaselinePatches -Property KBArticle | where SideIndicator -eq "=>" | foreach {
    $KBArticle = $_.KBArticle
    $BaselinePatches | where { ( ( $_.KBArticle -eq $KBArticle ) -and ( ($_.Products -notlike 'office*') -and ( $_.Products -notlike '*2008*' ) -and $_.Products -NotLike 'System Center *') )  } | ft Products

} 
