#region NetApp Storage Document Style
DocumentOption -EnableSectionNumbering -PageSize Letter -DefaultFont 'Arial' -MarginLeftAndRight 55 -MarginTopAndBottom 71 -Orientation $Orientation

Style -Name 'Title' -Size 24 -Color '194fb4' -Align Center
Style -Name 'Title 2' -Size 18 -Color '2F2F2F' -Align Center
Style -Name 'Title 3' -Size 12 -Color '2F2F2F' -Align Left
Style -Name 'Heading 1' -Size 16 -Color '194fb4' 
Style -Name 'Heading 2' -Size 14 -Color '194fb4' 
Style -Name 'Heading 3' -Size 12 -Color '194fb4' 
Style -Name 'Heading 4' -Size 11 -Color '194fb4' 
Style -Name 'Heading 5' -Size 10 -Color '194fb4' -Italic
Style -Name 'H1 Exclude TOC' -Size 16 -Color '194fb4' 
Style -Name 'Normal' -Size 10 -Default
Style -Name 'TOC' -Size 16 -Color '194fb4' 
Style -Name 'TableDefaultHeading' -Size 10 -Color 'FFFFFF' -BackgroundColor '2F2F2F' 
Style -Name 'TableDefaultRow' -Size 10 
Style -Name 'TableDefaultAltRow' -Size 10 -BackgroundColor 'DDDDDD' 
Style -Name 'Critical' -Size 10 -BackgroundColor 'd75252'
Style -Name 'Warning' -Size 10 -BackgroundColor 'FFE860'
Style -Name 'Info' -Size 10 -BackgroundColor 'A6D8E7'
Style -Name 'OK' -Size 10 -BackgroundColor 'AADB1E'

TableStyle -Id 'TableDefault' -HeaderStyle 'TableDefaultHeading' -RowStyle 'TableDefaultRow' -AlternateRowStyle 'TableDefaultAltRow' -BorderColor '464547' -Align Left -BorderWidth 0.5 -Default
TableStyle -Id 'Borderless' -BorderWidth 0

# Ontap Storage Page Layout
# Set position of report titles and information based on page orientation
if ($Orientation -eq 'Portrait') {
    BlankLine -Count 11
    $LineCount = 30
} else {
    BlankLine -Count 7
    $LineCount = 20
}

# Add Report Name
Paragraph -Style Title $ReportConfig.Report.Name

if ($AsBuiltConfig.Company.FullName) {
    # Add Company Name if specified
    Paragraph -Style Title2 $AsBuiltConfig.Company.FullName
    BlankLine -Count $LineCount
} else {
    BlankLine -Count ($LineCount +1)
}
Table -Name 'Cover Page' -List -Style Borderless -Width 0 -Hashtable ([Ordered] @{
        'Author:'  = $AsBuiltConfig.Report.Author
        'Date:'    = Get-Date -Format 'dd MMMM yyyy'
        'Version:' = $ReportConfig.Report.Version
        })
PageBreak

# Add Table of Contents
TOC -Name 'Table of Contents'
PageBreak

#endregion Ontap Storage Document Style