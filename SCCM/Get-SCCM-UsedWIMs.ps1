Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
Set-Location "CAS:"

$wims = Get-CMOperatingSystemImage | Select-Object Name, PackageID
$allTS = Get-CMTaskSequence | Select-Object Name, Sequence

$results = foreach ($wim in $wims) {
    $foundIn = @()
    foreach ($ts in $allTS) {
        if ($ts.Sequence -and ($ts.Sequence.ToString() -match "OSDApplyOS\.exe\s+/image:$($wim.PackageID)\b")) {
            $foundIn += $ts.Name
        }
    }
    [PSCustomObject]@{
        Name         = $wim.Name
        PackageID    = $wim.PackageID
        Status       = if ($foundIn.Count -gt 0) { "Used" } else { "Unused" }
        TaskSequence = $foundIn -join ', '
    }
}

$results | Sort-Object Status, Name | Format-Table -AutoSize
