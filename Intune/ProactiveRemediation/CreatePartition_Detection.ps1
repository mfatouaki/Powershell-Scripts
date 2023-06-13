#Detection script
$DriveLetter = "D"
$partition = get-partition -driveletter $DriveLetter -ErrorAction SilentlyContinue

if( $partition) { Write-Host "Disk Partition Exist.";
Exit 0}
else 
{Write-Host "Disk partition doesn't exist" 
Exit 1 }