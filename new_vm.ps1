#prep work to make sure PowerCLI is installed and ready to go
Install-Module -Name VMware.PowerCLI -confirm:$false
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false
Import-Module VMware.PowerCLI
Set-PowerCLIConfiguration -InvalidCertificateAction ignore -confirm:$false
 
 
#Get Credentials
Write-Host "========SELECT VCENTER========"
$vcenter = Read-Host "Type the vCenter site name"
$vmcred = Get-Credential -message "Enter vCenter credentials in the user@vsphere.local format"
Write-Host "========SELECT DOMAIN========"
$domain = Read-Host "Type the domain name, or leave blank for none"
$domaincred = Get-Credential -message "Enter credentials to join the domain in user@domain format"
 
#Connect to vCenter
Connect-VIServer -Server "$vcenter.$env:USERDNSDOMAIN" -Credential $vmcred
 
Write-Host "========SELECT VM TEMPLATE========"
$TemplateName = Read-Host "Type the template name.  Refer to your selected vCenter for specifics"
Write-Host "========SELECT CLUSTER========"
$Clusterchoice = Get-Cluster
Write-Host "The available clusters are"
Write-Host $Clusterchoice.Name
$Cluster = Read-Host "Type in the Cluster name for the VM"
Write-Host "========SELECT DATASTORE========"
$DSClusterchoice = Get-DatastoreCluster
Write-Host "The available Datastore Clusters are"
Write-Host $DSClusterchoice.Name
$Datastorechoice = Get-Datastore
Write-Host "The available Datastores are"
Write-Host $Datastorechoice.Name
$Datastore = Read-Host "Type the Datastore name for the VM"
Write-Host "========SELECT VM LOCATION========"
$Locationchoice = Get-Folder -Type VM
Write-Host "The available Folders are"
Write-Host $Locationchoice.Name
$Location = Read-Host "Type the name of the folder for the VM"
Write-Host "========ENTER VM NAME========"
$VMName = Read-Host "Type the name of the VM.  Do not exceed 15 characters"
Write-Host "========ENTER CORE NUMBER========"
$vCPU = Read-Host "Type the number of CPU cores for this VM"
Write-Host "========ENTER RAM SIZE========"
$Memory = Read-Host "Type in the amount of RAM in GB"
Write-Host "========ENTER HARD DRIVE SIZES========"
$DriveC = Read-Host "Enter C: Drive size in GB.  Minimum is 100.  C: will always be thin, please use another Drive for DB"
    if ( $DriveC -lt 100) {
        $DriveC = 100
    }
$DriveR = Read-Host "Enter R: Drive size in GB.  Enter 0 to omit"
    if ( $DriveR -ne 0) {
        $FormatR = Read-Host "Select 'thin' or 'thick' for drive R.  Thin is preferable unless thick is required, such as for SQL DB"
    }
$DriveS = Read-Host "Enter S: Drive size in GB.  Enter 0 to omit"
$DriveT = Read-Host "Enter T: Drive size in GB.  Enter 0 to omit"
$DriveU = Read-Host "Enter U: Drive size in GB.  Enter 0 to omit"
$DriveX = Read-Host "Enter X: Drive size in GB.  Enter 0 to omit"
Write-Host "========SELECT NETWORK========"
$Network = Read-Host "Type the name of the Network.  Be sure to check the format for the selected vCenter"
Write-Host "========ENTER THE VM IP========"
$IP = Read-Host "Type the IP.  Please ensure it is available first"
    if (test-connection -Quiet $IP) {
        $IP = Read-Host "IP address is in use, please confirm IP"
    }
$subnetmask = Read-Host "Enter subnet mask.  Usually 255.255.255.0"
$gateway = Read-Host "Enter the Default Gateway"
$DNSDC = Read-Host "Enter the IP of a local DC at this site"
$DNS1 = Read-Host "Enter the IP of the primary DNS Server"
$DNS2 = Read-Host "Enter the IP of the secondary DNS Server"
 
Write-Host "==============================================================="
Write-Host "vCenter: $vcenter.$env:USERDNSDOMAIN"
Write-Host "Domain: $domain"
Write-Host "Name:$VMName CPU: $vCPU cores Memory: $Memory GB"
Write-Host "C: Drive $DriveC GB"
Write-Host "R: Drive $DriveR GB $FormatR "
Write-Host "S: Drive $DriveS GB"
Write-Host "T: Drive $DriveT GB"
Write-Host "U: Drive $DriveU GB"
Write-Host "X: Drive $DriveX GB"
Write-Host "Cluster: $Cluster Datastore: $Datastore Location: $Location"
Write-Host "Template: $Template"
Write-host "vSphere credentials:"
Write-host $vmcred.UserName
Write-Host "domain credentials:"
Write-Host $domaincred.UserName
Write-Host "Please review the above information and confirm to continue"
Write-Host "==============================================================="
$confirm = Read-Host "Enter 'Y' to continue"
if ( $confirm -ne "Y") {exit}
 
$Template = Get-Template -Name $TemplateName
 
#Generate a temporary customization spec that clears after the script is run.  Joins the domain and configures the NIC to the DC so it can join the domain
$OSCustomizationSpecExists = Get-OSCustomizationSpec -name scriptspec
if ($OSCustomizationSpecExists -eq "scriptspec"){
    Remove-OSCustomizationSpec -OSCustomizationSpec scriptspec -Confirm:$false
    }
 
$localAdminPassword = Read-Host "Enter the local Administrator password" -AsSecureString
$localAdminPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($localAdminPassword)
)
 
New-OSCustomizationSpec -Name scriptspec -OrgName "My Organization" -OSType Windows -ChangeSid -Server "$vcenter.$env:USERDNSDOMAIN" -FullName "Administrator" -Type NonPersistent -AdminPassword $localAdminPlain -TimeZone 'Central (U.S. and Canada)' -AutoLogonCount 1 -Domain $domain -DomainCredentials $domaincred -NamingScheme Vm -LicenseMode PerServer -LicenseMaxConnections 5 -Confirm:$false
Get-OSCustomizationNicMapping -OSCustomizationSpec scriptspec | Set-OSCustomizationNicMapping -Position 1 -IpMode UseStaticIP -IpAddress $IP -SubnetMask $subnetmask -DefaultGateway $gateway -Dns $DNSDC,$DNS2 -Confirm:$false
 
#Building the VM
New-VM -Name $VMName -Template $Template -ResourcePool $Cluster -Datastore $Datastore -StorageFormat Thin -Location $Location -OSCustomizationSpec scriptspec
Start-Sleep -Seconds 10
 
#Configure settings
$NewVM = Get-VM -Name $VMName
$NewVM | Set-VM -MemoryGB $Memory -NumCpu $vCPU -Confirm:$false
$NewVM | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $Network -Confirm:$false
 
 
#configure disks
if ($DriveR -ne 0){
$NewVM | New-HardDisk -CapacityGB $DriveR -Persistence persistent -StorageFormat $FormatR
}
if ($DriveS -ne 0){
    $NewVM | New-HardDisk -CapacityGB $DriveS -Persistence persistent -StorageFormat thick
}
if ($DriveT -ne 0){
    $NewVM | New-HardDisk -CapacityGB $DriveT -Persistence persistent -StorageFormat thick
}
if ($DriveU -ne 0){
    $NewVM | New-HardDisk -CapacityGB $DriveU -Persistence persistent -StorageFormat thick
}
if ($DriveX -ne 0){
    $NewVM | New-HardDisk -CapacityGB $DriveX -Persistence persistent -StorageFormat thick
}
 
#Power on the VM and finish configuration, including setting the IP and proper network.
 
Start-VM -VM $NewVM
Start-Sleep -s 15
Write-Host "waiting for domain join and reboot"
do {
    $VMStatus =  (Get-VM -Name $NewVM).ExtensionData.guest.guestState
    Start-Sleep -s 0.5
} until ($VMStatus -eq "notRunning")
write-host "rebooting!"
Wait-Tools -VM $NewVM
Start-Sleep -s 60
Mount-Tools $NewVM
Start-Sleep -s 120
Update-Tools $NewVM
Start-Sleep -s 15
Wait-Tools -VM $NewVM
Dismount-Tools $NewVM
 
#fix the DNS to final values
invoke-command -computername $NewVM.Name -credential $domaincred -Scriptblock {Set-DnsClientServerAddress -InterfaceIndex (Get-Netadapter).ifIndex[0] -ServerAddresses $using:DNS1,$using:DNS2}
#all done
Disconnect-VIServer -Server * -Force -confirm:$false
 