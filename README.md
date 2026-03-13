powershell_admin
A collection of PowerShell scripts for enterprise sysadmin tasks covering Active Directory, VMware, and certificate management.

Add_ICAcert.ps1
Choose a certificate file and configure a domain to use it for strong certificate binding by UPN suffix. Imports the cert to the local machine store, generates the thumbprint/OID/UPN binding string (tuple), updates the KDC registry policy via GPO, and publishes to NTAuth.

file_chunker.ps1
Select a file and split it into 100MB chunks. Useful for transferring large files across systems with size restrictions, trasmit with slow network, or sneakernet it on disc.

file_dechunker.ps1
Select a set of chunk files and reassemble them into the original file. Companion script to file_chunker.ps1.

get_DA.ps1
Export a list of all Domain Admin accounts including enabled status, email, and creation date. Optionally checks which DA accounts are also members of a Deny Interactive Logon group.

get_sneakypriv_accounts.ps1
Audit all OUs in the domain for accounts with GenericAll permissions — full control rights that may not be visible through standard group membership review. Exports results to CSV.

new_gmsa.ps1
Create a new Group Managed Service Account, assign it to a security group, and install it on the target servers. Validates the KDS root key before proceeding.

new_vm.ps1
Interactive script to deploy a new Windows VM in vSphere from a template. Prompts for all configuration including compute, storage, networking, and domain join, then handles the full build and VMware Tools update.

old_ad_comps.ps1
Find all computer accounts that haven't logged in within a configurable number of days and move them to a target OU for disabled computers.

