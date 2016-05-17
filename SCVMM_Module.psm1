#---------------------------------------------------------------------------------------
# SCVMM Module
#---------------------------------------------------------------------------------------

Function Add-SCVMMUpdatetoBaseline {

<#
    .Description
        Updates the SCVMM Baseline with the specified Update

    .Parameter Name
        Name of the baseline to update

    .Parameter ArticleID
        KB article ID for the update.

    .Example
        '972270' | Add-SCVMMUpdateToBaseline -BaselineName 'test'

    .Note
        Author: Jeff Buenting
        Date: 24 Jul 2015

    .Link
        Reference

        http://www.isolation.se/scvmm-automatic-baseline-update-script/

#>
    
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True)]
        [String]$Name,

        [Parameter(ValueFromPipeline = $True)]
        [String[]]$ArticleID
    )

    Begin {
        Write-Verbose "Get VMM Baseline"
        $Baseline = Get-SCBaseline -Name $Name
        if ( $Baseline -eq $Null ) {
            Write-Error "Baselline $Name does not exist. You must supply a valid name for BaselineName"
            break
        }
        $UpdateList = ""
        $UpdateList = @()
    }

    Process {
        ForEach ( $A in $ArticleID ) {
            Write-Verbose "Update $A"
            $Update = Get-SCUpdate -KBArticle $A
            ForEach ( $U in $Update ) { 
                if ( $U -notin $Baseline.Updates ) {
                    Write-Verbose "     Adding $($U.KBArticle) to $Name"
                    $UpdateList += $U
                }
            }
        }
    }

    End {
        if ( $UpdateList.Count -ne 0 ) {
            Write-Verbose "Writing Updates to Baseline"
            Set-SCBaseline -Baseline $Baseline -Name $Name -AddUpdates $UpdateList
        }
    }
}

#---------------------------------------------------------------------------------------

Function Remove-SCVMMUpdateFromBaseline {

    [CmdletBinding(SupportsShouldProcess=$True)]
    Param (
        [Parameter(Mandatory=$True)]
        [String]$Name,

        [Parameter(ValueFromPipeline = $True)]
        [String[]]$ArticleID
    )

    Begin {
        Write-Verbose "Get VMM Baseline"
        $Baseline = Get-SCBaseline -Name $Name
        if ( $Baseline -eq $Null ) {
            Write-Error "Baselline $Name does not exist. You must supply a valid name for BaselineName"
            break
        }
        $UpdateList = @()
    }

    Process {
        if ( [String]::IsNullOrEmpty($ArticleID) ) {
                Write-Verbose "No Update ArticleID specified, removing all updates from baseline $Name"
                $UpdateList = $Baseline.Updates
            }
            else {
                Foreach ( $A in $ArticleID ) {
                    Write-Verbose "Removing Update ArticleID $A from baseline $Baseline"
                    $Update = Get-SCUpdate -KBArticle $A
                    ForEach ( $U in $Update ) { 
                        if ( $U -in $Baseline.Updates ) {
                            Write-Verbose "     Removing $($U.KBArticle) to $Name"
                            $UpdateList += $U
                        }
                    }
                }
        }
    }

    End {
        
        if ( $UpdateList.Count -ne 0 ) {
            Write-Verbose "Removing Updates From Baseline"
            Set-SCBaseline -Baseline $Baseline -Name $Name -RemoveUpdates $UpdateList
        }
    }
}

#---------------------------------------------------------------------------------------