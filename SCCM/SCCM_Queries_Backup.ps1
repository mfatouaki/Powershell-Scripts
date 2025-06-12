# Export all SCCM queries to sanitized XML files
$SiteCode = "CAS"  # Replace with your site code
$Namespace = "root\sms\site_$SiteCode"
$ExportPath = "C:\Temp\SCCM_Queries_Backup"

if (!(Test-Path $ExportPath)) { New-Item -Path $ExportPath -ItemType Directory }

$Queries = Get-WmiObject -Namespace $Namespace -Class SMS_Query
foreach ($Query in $Queries) {
    $SafeName = ($Query.Name -replace '[\\\/:*?"<>|]', '_')  # Sanitize invalid characters
    $FileName = "$ExportPath\$SafeName.xml"
    $QueryText = $Query.GetText("MOF")
    $QueryText | Out-File -FilePath $FileName -Encoding UTF8
}

Write-Host "Exported $($Queries.Count) queries to $ExportPath"
