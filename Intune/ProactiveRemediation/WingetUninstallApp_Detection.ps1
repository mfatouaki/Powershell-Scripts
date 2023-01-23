# Check if winget is already installed
$winget = Get-Command winget -ErrorAction SilentlyContinue


# If winget is not installed, install it
if (!$winget) {
$MyLink = "https://github.com/microsoft/winget-cli/releases/download/v1.3.431/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
Invoke-WebRequest -Uri $MyLink -OutFile winget-installer.msixbundle
Add-AppxPackage -Path .\winget-installer.msixbundle -ForceUpdateFromAnyVersion -ForceTargetApplicationShutdown
}


# Check if the app is currently installed
$appName = "mozilla firefox"
$app = winget list --name $appName --accept-source-agreements


if ($app -like "No installed package found*") {
   
     Write-Output "$appName Not Found."
    Exit 0
} else {
    Write-Output "$appName Is Installed."
    Exit 1
}
