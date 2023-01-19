$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument  '-command "Restart-Computer -Force"'
$trigger = New-ScheduledTaskTrigger -Once -At "day/month/year 00:00:00 AM"
$principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -MultipleInstances Parallel
Register-ScheduledTask -TaskName "insert task name here" -Action $action -Trigger $trigger -Settings $settings -Principal $principal
