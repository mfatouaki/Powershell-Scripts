#Select Partition
Get-Partition -DriveLetter C

#Resize the choosen partition
Resize-Partition -DriveLetter C -Size (237GB)

#Create a new partition and format disk
New-Partition -DiskNumber 0 -UseMaximumSize -DriveLetter D | Format-Volume



