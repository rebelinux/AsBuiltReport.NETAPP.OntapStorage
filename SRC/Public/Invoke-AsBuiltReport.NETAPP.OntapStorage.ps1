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
    #Connect to Ontap Storage Array using supplied credentials
    foreach ($OntapArray in $Target) {
        Try {
            $Array = Connect-NcController -Name $OntapArray -Credentials $Credential
        } Catch {
            Write-Error $_
        }

        if ($Array) {
            $script:ClusterInfo = Get-NcCluster
            $script:ClusterVersion = Get-NcSystemVersion



            Section -Style Heading1 $ClusterInfo.ClusterName {
                Section -Style Heading2 'Cluster Summary' {
                    Paragraph "The following section provides a summary of the array configuration for $($ClusterInfo.ClusterName)."
                    BlankLine
                    #Provide a summary of the Storage Array
                    $ClusterSummary = [PSCustomObject] @{
                        'Cluster Name' = $ClusterInfo.ClusterName
                        'Cluster Version' = $ClusterInfo.ClusterSerialNumber
                        'Cluster Serial' = $ClusterInfo.ClusterSerialNumber
                        'Ontap Version' = $ClusterVersion.value
                    }
                    $ClusterSummary | Table -Name 'Cluster Summary' -List
                }#End System Summary
            }
        }
    }
}