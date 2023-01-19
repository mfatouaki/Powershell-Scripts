# Check if the app is currently installed
$appName = "mozilla firefox"
$app = winget list --name $appName 


if ($app -notlike "No installed package found*") {
    Write-Output "Uninstalling $appName..."
    winget uninstall $appName --silent
    Write-Output "$appName has been uninstalled."
    Exit 0
} else {
    Write-Output "$appName not found."
}
