#adjust days inactive as needed in days
$DaysInactive = 365
$date = (Get-Date).AddDays(-($DaysInactive))
#$computers = Get-ADComputer -Filter {LastLogonTimeStamp -lt $date} -ResultPageSize 2000 -ResultSetSize $null -Properties Name, OperatingSystem, SamAccountName, DistinguishedName, Created, Modified, whenChanged, whenCreated, lastlogondate, Enabled
$computers = Get-ADComputer -Filter {LastLogonTimeStamp -lt $date} -ResultPageSize 2000 -ResultSetSize $null
 
#export list to csv
#$computers | Export-CSV "C:\temp\oldcomps.csv" -NoTypeInformation
 
$TargetOU = Read-Host "Enter the full Distinguished Name of the target OU (e.g. OU=Disabled Computers,DC=domain,DC=com)"
$computers | Move-ADObject -TargetPath $TargetOU
 