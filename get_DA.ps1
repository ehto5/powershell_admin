$admins = get-adgroupmember 'domain admins' | get-aduser -properties * | select samaccountname,name,enabled,mail,whencreated
 
$denygroup = Read-Host "Enter the name of the Deny Interactive Logon group, or leave blank to skip"
 
#shows which DA accounts are also denied interactive login
if ($denygroup) {
    foreach ($admin in $admins) {
        Write-host $admin.name
        Get-ADPrincipalGroupMembership $admin.samaccountname | Where-object name -like $denygroup
        }
    }
 
$admins | export-csv C:\temp\domainadmins.csv