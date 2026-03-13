# Obligatory import
Import-Module ActiveDirectory
 
# Check if KDS root key has already been created
$key = Get-KdsRootKey
$test = Test-KDSRootKey -KeyId "$key.keyid"
if ($test -eq $false) {
    Write-Host "KDS Root key not verified.  Good day."
    exit
}
# Add KDS root key if it does not already exist.  Uncomment this if needed, should only be for the first gMSA on a new domain
# Add-KDS-RootKey -EffectiveImmediately
 
# Define variables for the gMSA name and group names
$gMSAName = Read-Host -Prompt "Please enter the name of the new gMSA"
$servers = Read-Host -Prompt "Enter the names of the servers that will be using the gMSA"
$description = Read-Host -Prompt "Enter the description of the account"
 
# Get the domain info dynamically rather than hardcoding it
$domain = Get-ADDomain
$domainDN = $domain.DistinguishedName
$domainFQDN = $domain.DNSRoot
 
# Create the security group for managing the gMSA
New-ADGroup -Name "$gMSAName" -GroupScope Global -GroupCategory Security -Path "CN=Managed Service Accounts,$domainDN"
 
# Add the gMSA account to the security group
Add-ADGroupMember -Identity "$gMSAName" -Members $servers
 
# DNSHostName is a weird parameter which seems to exist simply because this system was copied from other AD objects which required it.  
# Create the new gMSA
New-ADServiceAccount -Name $gMSAName -DNSHostName "$gMSAName.$domainFQDN" -PrincipalsAllowedToRetrieveManagedPassword "$gMSAName" -ManagedPasswordIntervalInDays 30 -Enabled $True -description "$description. $gMSAName is configured on $servers"
 
# once created, the gMSA needs to be installed on a server.  This is done after permissions are assigned and should confirm everything was done correctly
# this needs to run on the computers that are being added
$sblock = {
    param($gMSAName)
    gpupdate /force
    KLIST Purge -li 0x3e7 
    Install-Module -Name ActiveDirectory -Force
    Install-ADServiceAccount -Identity $gMSAName
    test-adserviceaccount $gMSAName
    }
foreach ($server in $servers) {
    Invoke-Command -Computername $server -ScriptBlock $sblock -ArgumentList $gMSAName
    }
 
Write-Host "Checking gMSA..."
Get-ADServiceAccount $gMSAName -Properties PrincipalsAllowedToRetrieveManagedPassword
Get-ADGroupMember "$gMSAName"