#Install-Module Microsoft.Graph.Intune -ErrorAction Stop -Force -Confirm:$false -Verbose
#Install-Module AzureAD -ErrorAction Stop -Force -Confirm:$false -Verbose

$computer_list = Import-Csv "c:\Scripts\exportDevice_2022-8-23.csv"
foreach ($computer in $computer_list)
{
powershell -ExecutionPolicy ByPass .\Delete-AutopilotedDeviceRecords.ps1 -ComputerName $($computer.ComputerName) -Autopilot -AAD -Intune
}
