function start-removeBOM {
param(
    [parameter(Mandatory)]
    [string]$inputFile 
)
$inputFile         = $inputFile -replace '"'
$MyRawString       = Get-Content -Raw "$inputFile"
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
$OutputLocation    = "$(Split-Path $inputFile)\$(((Split-Path $inputFile -Leaf) -split "\.")[0])_NoBOM.ps1"
[System.IO.File]::WriteAllLines($OutputLocation, $MyRawString, $Utf8NoBomEncoding)
}

start-removeBOM 