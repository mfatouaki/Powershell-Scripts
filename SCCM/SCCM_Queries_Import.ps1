$SiteCode = "CAS"  # Replace with your site code
$Namespace = "root\sms\site_$SiteCode"
$ImportPath = "C:\Temp\SCCM_Queries_Backup"

# Get existing query names to avoid duplicates
$ExistingQueryNames = Get-WmiObject -Namespace $Namespace -Class SMS_Query | Select-Object -ExpandProperty Name

# Process each exported MOF file
$Files = Get-ChildItem -Path $ImportPath -Filter *.xml
foreach ($File in $Files) {
    $Mof = Get-Content $File.FullName -Raw

    # Extract query properties
    if ($Mof -match 'Name\s*=\s*"([^"]+)"') {
        $QueryName = $matches[1]

        if ($ExistingQueryNames -contains $QueryName) {
            Write-Host "Skipped (already exists): $QueryName"
            continue
        }

        if ($Mof -match 'TargetClassName\s*=\s*"([^"]+)"') { $Target = $matches[1] } else { $Target = "" }
        if ($Mof -match 'Expression\s*=\s*"([^"]+)"') { $Expression = $matches[1] } else { $Expression = "" }

        # Create and import query
        $Query = ([WMIClass]"\\.\$Namespace`:SMS_Query").CreateInstance()
        $Query.Name = $QueryName
        $Query.TargetClassName = $Target
        $Query.Expression = $Expression
        $Query.Put() | Out-Null

        Write-Host "Imported: $QueryName"
    } else {
        Write-Warning "Skipped (could not parse name): $($File.Name)"
    }
}
