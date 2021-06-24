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
		[String]$StylePath
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
            Write-Verbose "Unable to connect to the $OntapArray Array"
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
            $script:License = Get-NcLicense
            $script:LicenseFeature = Get-NcFeatureStatus
            $script:DiskInv = Get-NcDisk
            $script:NodeDiskCount = get-ncdisk | %{ $_.DiskOwnershipInfo.HomeNodeName } | Group-Object
            $script:NodeDiskContainerType = Get-NcDisk | %{ $_.DiskRaidInfo.ContainerType } | Group-Object
            $script:NodeDiskBroken = Get-NcDisk | ?{ $_.DiskRaidInfo.ContainerType -eq "broken" }




            Section -Style Heading1 "Report for Cluster $($ClusterInfo.ClusterName)" {
                Section -Style Heading2 'Cluster Summary' {
                    Paragraph "The following section provides a summary of the array configuration for $($ClusterInfo.ClusterName)."
                    BlankLine
                    Section -Style Heading3 'Cluster Information' {
                        Paragraph "The following section provides a summary of the Cluster Information on $($ClusterInfo.ClusterName)."
                        BlankLine
                        $ClusterDiag = Get-NcDiagnosisStatus
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
                            'Overall System Health' = $ClusterDiag.Status.ToUpper()
                        }
                        if ($ClusterSummary) {
                            $ClusterSummary | Where-Object { $_.'Overall System Health' -like 'OK' } | Set-Style -Style OK -Property 'Overall System Health'
                            $ClusterSummary | Where-Object { $_.'Overall System Health' -notlike 'OK' } | Set-Style -Style Critical -Property 'Overall System Health'
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
                    }#End Section Heading2 Node Summary
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
                        }#End Section Heading3 Node Hardware Information
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
                        }#End Section Heading3 Node Service-Processor Information
                    }#End Section Heading2 Node Summary
                Section -Style Heading2 'Storage Summary' {
                    Paragraph "The following section provides a summary of the storage hardware on $($ClusterInfo.ClusterName)."
                    BlankLine
                        Section -Style Heading3 'Aggregate Summary' {
                            Paragraph "The following section provides the Aggregates on $($ClusterInfo.ClusterName)."
                            BlankLine
                            $AggrSpaceSummary = foreach ($Aggr in $AggrSpace) {
                                $RootAggr = Get-NcAggr $Aggr.Name | %{ $_.AggrRaidAttributes.HasLocalRoot } 
                                [PSCustomObject] @{
                                    'Name' = $Aggr.Name
                                    'Capacity' = "$([math]::Round(($Aggr.Totalsize) / "1$($Unit)", 2))$Unit"
                                    'Available' = "$([math]::Round(($Aggr.Available) / "1$($Unit)", 2))$Unit"
                                    'Used %' = [int]$Aggr.Used
                                    'Disk Count' = $Aggr.Disks
                                    'Root' = $RootAggr
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
                        }#End Section Heading3 Aggregate Summary
                        Section -Style Heading3 'Disk Summary' {
                            Paragraph "The following section provides the disk summary information on controller $($ClusterInfo.ClusterName)."
                            BlankLine
                            Section -Style Heading4 'Assigned Disk Summary' {
                                Paragraph "The following section provides the number of disks assigned to each controller on $($ClusterInfo.ClusterName)."
                                BlankLine
                                $DiskSummary = foreach ($Disks in $NodeDiskCount) {
                                    [PSCustomObject] @{
                                        'Node' = $Disks.Name
                                        'Disk Count' = $Disks | Select-Object -ExpandProperty Count
                                        }
                                }
                                $DiskSummary | Table -Name 'Assigned Disk Summary'
                            }#End Section Heading4 Assigned Disk Summary
                            Section -Style Heading4 'Disk Container Type Summary' {
                                Paragraph "The following section provides a summary of disk status on $($ClusterInfo.ClusterName)."
                                BlankLine
                                $DiskSummary = foreach ($DiskContainers in $NodeDiskContainerType) {
                                    [PSCustomObject] @{
                                        'Container' = $DiskContainers.Name
                                        'Disk Count' = $DiskContainers | Select-Object -ExpandProperty Count
                                        }
                                    }
                                    if ($DiskSummary) {
                                        $DiskSummary | Where-Object { $_.'Container' -like 'broken' } | Set-Style -Style Critical -Property 'Disk Count'
                                    }
                                $DiskSummary | Table -Name 'Disk Container Type Summary'
                            }#End Section Heading4 Disk Container Type Summary
                            if ($NodeDiskBroken) {
                                Section -Style Heading4 'Failed Disk Summary' {
                                    Paragraph "The following section show failed disks on cluster $($ClusterInfo.ClusterName)."
                                    BlankLine
                                    $DiskFailed = foreach ($DiskBroken in $NodeDiskBroken) {
                                        [PSCustomObject] @{
                                            'Disk Name' = $DiskBroken.Name
                                            'Shelf' = $DiskBroken.Shelf
                                            'Bay' = $DiskBroken.Bay
                                            'Pool' = $DiskBroken.Pool
                                            'Disk Paths' = $DiskBroken.DiskPaths
                                            }
                                        }
                                        if ($DiskFailed) {
                                            $DiskFailed | Set-Style -Style Critical -Property 'Disk Name','Shelf','Bay','Pool','Disk Paths'
                                        }
                                    $DiskFailed | Table -Name 'Failed Disk Summary'
                                }#End Section Heading4 Disk Container Type Summary
                            }
                        }#End Section Heading3 Disk Summary
                        Section -Style Heading3 'Disk Inventory' {
                            Paragraph "The following section provides the Disks installed on $($ClusterInfo.ClusterName)."
                            BlankLine
                            $DiskInventory = foreach ($Disks in $DiskInv) {
                                $DiskType = Get-NcDisk -Name $Disks.Name | %{ $_.DiskInventoryInfo }
                                $DiskFailed = $NodeDiskBroken | Where-Object { $_.'Name' -eq $Disks.Name }
                                if ($DiskFailed.Name -eq $Disks.Name ) {
                                    $Disk = " $($DiskFailed.Name)(*)"
                                    }
                                    else {
                                        $Disk =  $Disks.Name
                                    }
                                [PSCustomObject] @{
                                    'Disk Name' = $Disk
                                    'Shelf' = $Disks.Shelf
                                    'Bay' = $Disks.Bay
                                    'Capacity' = "$([math]::Round(($Disks.Capacity) / "1$($Unit)", 2))$Unit"
                                    'Model' = $Disks.Model
                                    'SerialNumber' = $DiskType.SerialNumber
                                    'Type' = $DiskType.DiskType
                                }
                            }
                            if ($DiskInventory) {
                                $DiskInventory | Where-Object { $_.'Disk Name' -like '*(*)' } | Set-Style -Style Critical -Property 'Disk Name'
                            }
                            $DiskInventory | Sort-Object -Property Name | Table -Name 'Disk Inventory' 
                        }#End Section Heading3 Disk Inventory
                        Section -Style Heading3 'Shelf Inventory' {
                            Paragraph "The following section provides the available Shelf on $($ClusterInfo.ClusterName)."
                            BlankLine
                            $ShelfInventory = foreach ($Nodes in $NodeSum) {
                                try {
                                    $Nodeshelf = Get-NcShelf -NodeName $Nodes.Node | Out-Null
                                }
                                catch {
                                    Write-Host "An error occurred:"
                                    Write-Host $_
                                }
                                [PSCustomObject] @{
                                    'Node Name' = $Nodeshelf.NodeName
                                    'Channel' = $Nodeshelf.ChannelName
                                    'Shelf Name' = $Nodeshelf.ShelfName
                                    'Shelf ID' = $Nodeshelf.ShelfId
                                    'State' = $Nodeshelf.ShelfState
                                    'Type' = $Nodeshelf.ShelfType
                                    'Firmware' = $Nodeshelf.FirmwareRevA+$Nodeshelf.FirmwareRevB
                                    'Bay Count' = $Nodeshelf.ShelfBayCount
                                }
                            }
                            if ($ShelfInventory) {
                                $ShelfInventory | Where-Object { $_.'State' -like 'offline' -or $_.'State' -like 'missing' } | Set-Style -Style Critical -Property 'State'
                                $ShelfInventory | Where-Object { $_.'State' -like 'unknown' -or $_.'State' -like 'no-status' } | Set-Style -Style Warning -Property 'State'
                            }
                            $ShelfInventory | Sort-Object -Property 'Node Name' | Table -Name 'Shelf Inventory' 
                        }#End Section Heading3 Shelf Inventory
                    }#End Section Heading2 Storage Summary
                Section -Style Heading2 'License Summary' {
                        Paragraph "The following section provides a summary of the license usage on $($ClusterInfo.ClusterName)."
                        BlankLine
                        Section -Style Heading3 'License Usage Summary' {
                            Paragraph "The following section provides the installed licenses on $($ClusterInfo.ClusterName)."
                            BlankLine
                            $LicenseSummary = foreach ($Licenses in $License) {
                                $EntitlementRisk = Get-NcLicenseEntitlementRisk -Package $Licenses.Package
                                [PSCustomObject] @{
                                    'Name' = $Licenses.Owner
                                    'Package' = $Licenses.Package
                                    'Type' = $Licenses.Type
                                    'Description' = $Licenses.Description
                                    'Risk' = $EntitlementRisk.Risk
                                }
                            }
                            if ($LicenseSummary) {
                                $LicenseSummary | Where-Object { $_.'Risk' -like 'low' } | Set-Style -Style Ok -Property 'Risk'
                                $LicenseSummary | Where-Object { $_.'Risk' -like 'medium' -or $_.'Risk' -like 'unknown' } | Set-Style -Style Warning -Property 'Risk'
                                $LicenseSummary | Where-Object { $_.'Risk' -like 'High' } | Set-Style -Style Critical -Property 'Risk'
                            }
                            $LicenseSummary | Sort-Object -Property Description| Table -Name 'License Summary' 
                        }#End Section Heading3 License Usage Summary
                        Section -Style Heading3 'License Feature Summary' {
                            Paragraph "The following section provides the License Feature Usage on $($ClusterInfo.ClusterName)."
                            BlankLine
                            $LicenseFeature = foreach ($NodeLFs in $LicenseFeature) {
                                [PSCustomObject] @{
                                    'Name' = $NodeLFs.FeatureName
                                    'Status' = $NodeLFs.Status
                                    'Notes' = $NodeLFs.Notes
                                }
                            }
                            $LicenseFeature | Sort-Object -Property Status | Table -Name 'License Feature Summary' 
                        }#End Section Heading3 License Feature Summary
                    }#End Section Heading2 License Summary    
                }#End Section Heading1 Report for Cluster
            }
        }