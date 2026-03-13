$groups = Get-ADOrganizationalUnit -Filter * | %{(Get-ACL "AD:$($_.distinguishedname)").access} | Where-Object -Property ActiveDirectoryRights -contains "GenericAll" | Select-Object IdentityReference
foreach ($group in $groups) {
    $user = Get-ADGroupMember ([string]$group.IdentityReference).split('\')[1] | Select -Property name, samaccountname
    $users +=$user
    }
       $users | Select -Property name, samaccountname -Unique | Export-Csv C:\temp\high_priv_users.csv
 