# Check if winget is already installed
$winget = Get-Command winget


# If winget is not installed, install it
if (!$winget) {
    Invoke-WebRequest https://github.com/Axlfc/get-winget/blob/main/install-winget.ps1 -OutFile install-winget.ps1
}


# Check if the app is currently installed
$appName = "mozilla firefox"
$app = winget list --name $appName 


if ($app -like "No installed package found*") {
   
     Write-Output "$appName Not Found."
    Exit 0
} else {
    Write-Output "$appName Is Installed."
    Exit 1
}
 catch{
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
} 
