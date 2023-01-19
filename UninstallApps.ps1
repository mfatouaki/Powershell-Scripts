# Define the name of the app to be deleted
$appName = "Bonjour"


# Check if the app is currently installed
$app = Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -like $appName}
if ($app) {
    # Uninstall the app
    $app.Uninstall()
    Write-Output "$appName has been successfully uninstalled."
} else {
    Write-Output "$appName is not currently installed."
}
