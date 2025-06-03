Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
Set-Location "CAS:"

# --- Applications Section ---
$apps = Get-CMApplication | Select-Object LocalizedDisplayName, CI_ID, PackageID
$allTS = Get-CMTaskSequence | Select-Object Name, Sequence

# Get application deployments
$appDeployments = Get-CMDeployment -FeatureType Application

# For dependency/supersedence checks, load all app XMLs
$allAppXmls = @{}
foreach ($app in $apps) {
    $appObj = Get-CMApplication -CI_ID $app.CI_ID
    $xml = [xml]$appObj.SDMPackageXML
    $allAppXmls[$app.CI_ID] = $xml
}

$appResults = foreach ($app in $apps) {
    # Task Sequence reference
    $foundInTS = @()
    foreach ($ts in $allTS) {
        if ($ts.Sequence -and ($ts.Sequence.ToString() -match "AppModelAppId=`"$($app.CI_ID)`"")) {
            $foundInTS += $ts.Name
        }
    }
    # Active deployment
    $foundInDeployment = $appDeployments | Where-Object { $_.CI_ID -eq $app.CI_ID }

    # As dependency or superseded app
    $isDependency = $false
    $isSuperseded = $false

    foreach ($xml in $allAppXmls.Values) {
        # Check for dependencies
        if ($xml.AppMgmtDigest.Application.Dependencies.Dependency | Where-Object { $_.DependencyCI_UniqueID -eq $app.CI_ID }) {
            $isDependency = $true
        }
        # Check for supersedence
        if ($xml.AppMgmtDigest.Application.SupersedenceInfo.SupersededApplications.SupersededApplication | Where-Object { $_.CI_UniqueID -eq $app.CI_ID }) {
            $isSuperseded = $true
        }
    }

    [PSCustomObject]@{
        Type          = "Application"
        Name          = $app.LocalizedDisplayName
        CI_ID         = $app.CI_ID
        PackageID     = $app.PackageID
        TaskSequence  = if ($foundInTS) { $foundInTS -join ', ' } else { "" }
        InTaskSeq     = ($foundInTS.Count -gt 0)
        HasDeployment = ($null -ne $foundInDeployment)
        IsDependency  = $isDependency
        IsSuperseded  = $isSuperseded
        SafeToDelete  = -not($foundInTS.Count -gt 0 -or $isDependency -or $isSuperseded -or $null -ne $foundInDeployment)
    }
}

# --- Packages Section ---
$packages = Get-CMPackage | Select-Object Name, PackageID
$pkgDeployments = Get-CMDeployment -FeatureType Package

$pkgResults = foreach ($pkg in $packages) {
    # Task Sequence reference (look for PackageID in TS Sequence)
    $foundInTS = @()
    foreach ($ts in $allTS) {
        if ($ts.Sequence -and ($ts.Sequence.ToString() -match [regex]::Escape($pkg.PackageID))) {
            $foundInTS += $ts.Name
        }
    }
    # Active deployment
    $foundInDeployment = $pkgDeployments | Where-Object { $_.PackageID -eq $pkg.PackageID }

    [PSCustomObject]@{
        Type          = "Package"
        Name          = $pkg.Name
        CI_ID         = ""
        PackageID     = $pkg.PackageID
        TaskSequence  = if ($foundInTS) { $foundInTS -join ', ' } else { "" }
        InTaskSeq     = ($foundInTS.Count -gt 0)
        HasDeployment = ($null -ne $foundInDeployment)
        IsDependency  = $false # Not checked for classic packages
        IsSuperseded  = $false # Not checked for classic packages
        SafeToDelete  = -not($foundInTS.Count -gt 0 -or $null -ne $foundInDeployment)
    }
}

# --- Combine and Output ---
$results = $appResults + $pkgResults
$results | Sort-Object Type, SafeToDelete, Name | Format-Table -AutoSize

# Optional: Export to CSV
$results | Export-Csv -Path C:\Temp\SCCM_AppPkg_Usage.csv -NoTypeInformation
