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
            $script:NodeSum = Get-NcNode
            $script:NodeHW = Get-NcNodeInfo
            $script:AutoSupport = Get-NcAutoSupportConfig
            $script:ServiceProcessor = Get-NcServiceProcessor



            Section -Style Heading1 "Report for Cluster $($ClusterInfo.ClusterName)" {
                Section -Style Heading2 'Cluster Summary' {
                    Paragraph "The following section provides a summary of the array configuration for $($ClusterInfo.ClusterName)."
                    BlankLine
                    Section -Style Heading3 'Cluster Information' {
                        Paragraph "The following section provides a summary of the Cluster Information on $($ClusterInfo.ClusterName)."
                        BlankLine
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
                        $ClusterSummary | Table -Name 'Cluster Information' -List -ColumnWidths 25, 75

                }#End Section Heading3 Cluster HA Status
            }
                    Section -Style Heading3 'Cluster HA Status' {
                        Paragraph "The following section provides a summary of the Cluster HA Status on $($ClusterInfo.ClusterName)."
                        BlankLine
                        $NodeSummary = foreach ($Nodes in $NodeSum) {
                            $ClusterHa = Get-NcClusterHa -Node $Nodes.Node
                            [PSCustomObject] @{
                            'Name' = $Nodes.Node
                            'Partner' = $ClusterHa.Partner
                            'TakeOver Possible' = $ClusterHa.TakeoverPossible
                            'TakeOver State' = $ClusterHa.TakeoverState
                            'HA Mode' = $ClusterHa.CurrentMode.ToUpper()
                            'HA State' = $ClusterHa.State.ToUpper()
                            
                        }
                    }
                    if ($NodeSummary) {
                        $NodeSummary | Where-Object { $_.'TakeOver State' -like 'in_takeover' } | Set-Style -Style Warning -Property 'TakeOver State'
                        $NodeSummary | Where-Object { $_.'HA State' -notlike 'connected' } | Set-Style -Style Warning -Property 'HA State'
                    }
                    $NodeSummary | Sort-Object -Property Name | Table -Name 'Cluster HA Status'
            }#End Section Heading3 Cluster HA Status
                    Section -Style Heading3 'Cluster AutoSupport Status' {
                        Paragraph "The following section provides a summary of the Cluster AutoSupport Status on $($ClusterInfo.ClusterName)."
                        BlankLine
                        $AutoSupportSummary = foreach ($NodesAUTO in $AutoSupport) {
                            [PSCustomObject] @{
                            'Node Name' = $NodesAUTO.NodeName
                            'Protocol' = $NodesAUTO.Transport
                            'Enabled' = $NodesAUTO.IsEnabled
                            'Last Time Stamp' = $NodesAUTO.LastTimestampDT
                            'Last Subject' = $NodesAUTO.LastSubject
                        }
                    }
                    if ($AutoSupportSummary) {
                        $AutoSupportSummary | Where-Object { $_.'Enabled' -like 'False' } | Set-Style -Style Warning -Property 'Enabled'
                    }
                    $AutoSupportSummary | Table -Name 'Cluster AutoSupport Status' -List -ColumnWidths 25, 75
            }#End Section Heading3 Cluster HA Status
            }#End for Cluster Summary
            
                Section -Style Heading2 'Node Summary' {
                    Paragraph "The following section provides a summary of the Node on $($ClusterInfo.ClusterName)."
                    BlankLine
                        Section -Style Heading3 'Node Inventory' {
                            Paragraph "The following section provides the Node inventory on $($ClusterInfo.ClusterName)."
                            BlankLine
                            $NodeSummary = foreach ($Nodes in $NodeSum) {
                                [PSCustomObject] @{
                                'Name' = $Nodes.Node
                                'System Model' = $Nodes.NodeModel
                                'System Id' = $Nodes.NodeSystemId
                                'Serial Number' = $Nodes.NodeSerialNumber
                                'Node Uptime' = $Nodes.NodeUptimeTS

                          }
                    }
                    $NodeSummary | Sort-Object -Property Name | Table -Name 'Node Summary'
                    }#End Section Heading Node Summary
                        Section -Style Heading3 'Node Hardware Information' {
                            Paragraph "The following section provides the Node Hardware inventory on $($ClusterInfo.ClusterName)."
                            BlankLine
                            $NodeHardWare = foreach ($NodeHWs in $NodeHW) {
                                $NodeInfo = Get-NcNode -Node $NodeHWs.SystemName
                                [PSCustomObject] @{
                                'Name' = $NodeHWs.SystemName
                                'System Type' = $NodeHWs.SystemMachineType
                                'CPU Count' = $NodeHWs.NumberOfProcessors
                                'Total Memory' = "$($NodeHWs.MemorySize / 1024)GB"
                                'Vendor' = $NodeHWs.VendorId
                                'AFF/FAS' = $NodeHWs.ProdType
                                'All Flash Optimized' = $NodeInfo.IsAllFlashOptimized
                                'Epsilon' = $NodeInfo.IsEpsilonNode
                                'System Healthy' = $NodeInfo.IsNodeHealthy.ToString().Replace("False", "UnHealthy").Replace("True", "Healthy")
                                'Failed Fan Count' = $NodeInfo.EnvFailedFanCount
                                'Failed Fan Error' = $NodeInfo.EnvFailedFanMessage
                                'Failed PowerSupply Count' = $NodeInfo.EnvFailedPowerSupplyCount
                                'Failed PowerSupply Error' = $NodeInfo.EnvFailedPowerSupplyMessage
                                'Over Temperature' = $NodeInfo.EnvOverTemperature.ToString().Replace("False", "Normal Temperature").Replace("True", "High Temperature")
                                'NVRAM Battery Healthy' = $NodeInfo.NvramBatteryStatus

                        }
                    }
                    if ($NodeHardWare) {
                        $NodeHardWare | Where-Object { $_.'System Healthy' -like 'UnHealthy' } | Set-Style -Style Critical -Property 'System Healthy'
                        $NodeHardWare | Where-Object { $_.'Failed Fan Count' -gt 0 } | Set-Style -Style Critical -Property 'Failed Fan Count'
                        $NodeHardWare | Where-Object { $_.'Failed PowerSupply Count' -gt 0 } | Set-Style -Style Critical -Property 'Failed PowerSupply Count'
                        $NodeHardWare | Where-Object { $_.'Over Temperature' -like 'High Temperature' } | Set-Style -Style Critical -Property 'Over Temperature'
                        $NodeHardWare | Where-Object { $_.'NVRAM Battery Healthy' -notlike 'battery_ok' } | Set-Style -Style Critical -Property 'NVRAM Battery Healthy'
                    }
                    $NodeHardWare | Sort-Object -Property Name | Table -Name 'Node Hardware Information' -List -ColumnWidths 40, 60
                    }#End Section Heading Node Hardware Information
                        Section -Style Heading3 'Node Service-Processor Information' {
                            Paragraph "The following section provides the Node Service-Processor Information on $($ClusterInfo.ClusterName)."
                            BlankLine
                            $NodeHardWare = foreach ($NodeSPs in $ServiceProcessor) {
                                [PSCustomObject] @{
                                'Name' = $NodeSPs.Node
                                'Type' = $NodeSPs.Type
                                'IP Address' = $NodeSPs.IpAddress
                                'MAC Address' = $NodeSPs.MacAddress
                                'Network Configured' = $NodeSPs.IsIpConfigured
                                'Firmware' = $NodeSPs.FirmwareVersion
                                'Status' = $NodeSPs.Status
                        }
                    }
                    if ($NodeHardWare) {
                        $NodeHardWare | Where-Object { $_.'Status' -like 'offline' -or $_.'Status' -like 'degraded' } | Set-Style -Style Critical -Property 'Status'
                        $NodeHardWare | Where-Object { $_.'Status' -like 'unknown' -or $_.'Status' -like 'sp-daemon-offline' } | Set-Style -Style Warning -Property 'Status'
                        $NodeHardWare | Where-Object { $_.'Network Configured' -like "false" } | Set-Style -Style Critical -Property 'Network Configured'
                    }
                    $NodeHardWare | Sort-Object -Property Name | Table -Name 'Node Service-Processor Information' 
                    }#End Section Heading Node Service-Processor Information
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
                            $AggrSpaceSummary | Where-Object { $_.'State' -eq 'unknown' -or $_.'State' -eq 'offline' } | Set-Style -Style Warning -Property 'State'
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