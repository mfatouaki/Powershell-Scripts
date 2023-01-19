

$src = "C:\source folder"
$dest = "C:\destination folder"
$i = 0

Get-ChildItem -Path $src -Recurse -File | %{ 
    if(Test-Path -Path ($dest + "\" + $_.Name))
    {
       $i++
       Move-Item -Path $_.FullName -Destination ($dest + "\" + $_.Name + $i)
    }
    else
    {
       Move-Item -Path $_.FullName -Destination $dest
    }
}


