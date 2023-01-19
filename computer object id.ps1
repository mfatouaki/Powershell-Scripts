Install-module -name msonline -force 
Connect-MsolService
$CHGList = Import-Csv -path "C:\temp\MachineNames.csv"
$ObjectID = @(
    @{ Name = 'version:v1.0'; Expression = { $_.'ObjectId' } }
)
'*'| Select-Object -Property $ObjectID |Export-CSV -Path "C:\temp\testx.csv" -NoTypeInformation -Append -Force
ForEach ($displayName in $CHGList) {
    Get-MsolDevice -Name $displayName.displayName | Select-Object -Property $ObjectID |Export-CSV -Path "C:\temp\BulkUploadtemplate.csv" -NoTypeInformation -Append
}