function Invoke-AsBuiltReport.NETAPP.OntapStorage {
    <#
    .SYNOPSIS
        PowerShell script which documents the configuration of NetApp Ontap Storage Arrays in Word/HTML/XML/Text formats
    .DESCRIPTION
        Documents the configuration of NetApp Ontap Storage Arrays in Word/HTML/XML/Text formats using PScribo.
    .NOTES
        Version:        0.1
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         https://github.com/rebelinux
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/
    #>

    #region Script Parameters
    [CmdletBinding()]
    param (
        [string[]] $Target,
        [pscredential] $Credential,
		$StylePath
    )

    # If custom style not set, use default style
    if (!$StylePath) {
        & "$PSScriptRoot\..\..\AsBuiltReport.NETAPP.OntapStorage.Style.ps1"
    }

    $Script:Array = $Null
    $Script:Unit = "GB"
    #Connect to Ontap Storage Array using supplied credentials
    foreach ($OntapArray in $Target) {
        Try {
            $Array = Connect-NcController -Name $OntapArray -Credential $Credential
        } Catch {
            Write-Error $_
        }

        if ($Array) {
            $script:ClusterInfo = Get-NcCluster
            $script:ClusterVersion = Get-NcSystemVersion
            $script:ArrayAggr = Get-NcAggr
            $script:ArrayVolumes = Get-NcVol
            $script:AggrSpace = Get-NcAggr
            $script:NodeSum = Get-NcNodeInfo



            Section -Style Heading1 "Report for Cluster $($ClusterInfo.ClusterName)" {
                Section -Style Heading2 'Cluster Summary' {
                    Paragraph "The following section provides a summary of the array configuration for $($ClusterInfo.ClusterName)."
                    BlankLine
                    #Provide a summary of the Storage Array
                    $ClusterSummary = [PSCustomObject] @{
                        'Cluster Name' = $ClusterInfo.ClusterName
                        'Cluster UUID' = $ClusterInfo.ClusterUuid
                        'Cluster Serial' = $ClusterInfo.ClusterSerialNumber
                        'Cluster Controller' = $ClusterInfo.NcController
                        'Cluster Contact' = $ClusterInfo.ClusterContact
                        'Cluster Location' = $ClusterInfo.ClusterLocation
                        'Ontap Version' = $ClusterVersion.value
                        'Number of Aggregates' = $ArrayAggr.count
                        'Number of Volumes' = $ArrayVolumes.count

                    }
                    $ClusterSummary | Table -Name 'Cluster Summary' -List
                }#End for Cluster Summary
            }#End Report for Cluster
            
                Section -Style Heading2 'Node Summary' {
                    Paragraph "The following section provides a summary of the Node on $($ClusterInfo.ClusterName)."
                    BlankLine
                        Section -Style Heading3 'Node Inventory' {
                            Paragraph "The following section provides the Node inventory on $($ClusterInfo.ClusterName)."
                            BlankLine
                            $NodeSummary = foreach ($Nodes in $NodeSum) {
                                [PSCustomObject] @{
                                'Name' = $Nodes.SystemName
                                'Model' = $Nodes.SystemModel
                                'System Id' = $Nodes.SystemId
                                'Serial#' = $Nodes.SystemSerialNumber
                                'Type' = $Nodes.ProdType

                          }
                    }
                    $NodeSummary | Sort-Object -Property Name | Table -Name 'Aggregate Summary' 
                    }#End Section Heading3Node Summary
                        Section -Style Heading3 'Node HA Status' {
                            Paragraph "The following section provides a summary of the Node HA Status on $($ClusterInfo.ClusterName)."
                            BlankLine
                            $NodeSummary = foreach ($Nodes in $NodeSum) {
                                $ClusterHa = Get-NcClusterHa -Node $Nodes.SystemName
                                [PSCustomObject] @{
                                'Name' = $Nodes.SystemName
                                'Partner' = $ClusterHa.Partner
                                'TakeOver Possible' = $ClusterHa.TakeoverPossible
                                'TakeOver State' = $ClusterHa.TakeoverState
                                'Ha Mode' = $ClusterHa.CurrentMode
                                'Ha State' = $ClusterHa.State
                                
                            }
                        }
                        $NodeSummary | Sort-Object -Property Name | Table -Name 'Node HA Status'
                    }#End Section Heading3 Node HA Status
                }#End Section Heading2 Node Summary


                Section -Style Heading2 'Storage Summary' {
                        Paragraph "The following section provides a summary of the storage usage on $($ClusterInfo.ClusterName)."
                        BlankLine
                        $AggrSpaceSummary = foreach ($Aggr in $AggrSpace) {
                            [PSCustomObject] @{
                            'Name' = $Aggr.Name
                            'Capacity' = "$([math]::Round(($Aggr.Totalsize) / "1$($Unit)", 2))$Unit"
                            'Available' = "$([math]::Round(($Aggr.Available) / "1$($Unit)", 2))$Unit"
                            'Used %' = [int]$Aggr.Used
                            'Disk Count' = $Aggr.Disks
                            'Raid Type' = $Aggr.RaidType.Split(",")[0]
                            'State' = $Aggr.State
                        }
                    }
                        if ($AggrSpaceSummary) {
                            $AggrSpaceSummary | Where-Object { $_.'State' -eq 'failed' } | Set-Style -Style Critical -Property 'State'
                            $AggrSpaceSummary | Where-Object { $_.'State' -eq 'unknown' } | Set-Style -Style Warning -Property 'State'
                            $AggrSpaceSummary | Where-Object { $_.'Used %' -ge 90 } | Set-Style -Style Critical -Property 'Used %'
                        }
                        $AggrSpaceSummary | Sort-Object -Property Name | Table -Name 'Aggregate Summary' 
                    }#End Section Heading2 Storage Summary
                Section -Style Heading2 'License Summary' {
                        Paragraph "The following section provides a summary of the license usage on $($ClusterInfo.ClusterName)."
                        BlankLine
                        $AggrSpaceSummary = foreach ($Aggr in $AggrSpace) {
                            [PSCustomObject] @{
                            'Name' = $Aggr.Name
                            'Capacity' = "$([math]::Round(($Aggr.Totalsize) / "1$($Unit)", 2))$Unit"
                            'Available' = "$([math]::Round(($Aggr.Available) / "1$($Unit)", 2))$Unit"
                            'Used %' = [int]$Aggr.Used
                            'Disk Count' = $Aggr.Disks
                            'Raid Type' = $Aggr.RaidType.Split(",")[0]
                            'State' = $Aggr.State
                        }
                    }
                        if ($AggrSpaceSummary) {
                            $AggrSpaceSummary | Where-Object { $_.'State' -eq 'failed' } | Set-Style -Style Critical -Property 'State'
                            $AggrSpaceSummary | Where-Object { $_.'State' -eq 'unknown' } | Set-Style -Style Warning -Property 'State'
                            $AggrSpaceSummary | Where-Object { $_.'Used %' -ge 90 } | Set-Style -Style Critical -Property 'Used %'
                        }
                        $AggrSpaceSummary | Sort-Object -Property Name | Table -Name 'License Summary' 
                    }#End Section Heading2 Aggregate Summary                    
        }#End Section Heading1 Report for Cluster
    }
}