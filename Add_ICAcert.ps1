#Acquire the cert first.  easiest method is by installroot or exporting from a computer that already has it
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Windows.Forms
$filebrowser = New-Object System.Windows.Forms.OpenFileDialog
$filebrowser.InitialDirectory = [Environment]::GetFolderPath('Desktop')
$filebrowser.Filter = "certificate files (*.cer)|*.cer"
if ($filebrowser.ShowDialog() -eq "OK") {
    $certpath = $filebrowser.FileName
    }
$confirm = Read-Host "proceed with $certpath ? (Y/N)"
if ($confirm -match '^[Yy]$') {
    Write-Host "Proceeding with $certpath"
    }
else {
    Write-host "Aborting"
    return
    }
 
 
 
#pull the certificate file
Try {
    $cert = get-pfxcertificate -filepath $certpath
    $extension = $cert.Extensions | where-object {$_.oid.value -eq "2.5.29.32"}
    $certname = $cert.Subject
 
    Write-Host "---------------------------------------------------------------------------"
    Write-Host "Certificate Imported"
    Write-Host "$certname"
    Write-Host "---------------------------------------------------------------------------"
    }
Catch { 
    Write-Host "Certificate not loaded"
    }
 
try {
    #isolate the thumbprint
    $thumb = $cert.Thumbprint
    $fullpath = join-path -Path "Cert:\LocalMachine\CA" -ChildPath $thumb
    if (Test-Path -Path $fullpath) {
        $confirm2 = Read-host "certificate already exists, continue? Y/N"
            if ($confirm2 -match '^[Yy]$') {}
            else {return}
        }
    try {
        Import-Certificate -FilePath $certpath -CertStoreLocation "Cert:\LocalMachine\CA"
        }
    catch {
        Write-Error "Error: $($_.Exception.Message)"
        }  
    $allowedOids = @(
            "2.16.840.1.101.2.1.11.38",
            "2.16.840.1.101.2.1.11.36",
            "2.16.840.1.101.2.1.11.42"
        )
         
    #create a comma separated list of the policy identifiers, aka the cert usage
    $oidarray = @()
    if ($extension) {
        $decoded = $extension.Format(0)
        $alloids = $decoded | select-string -Pattern '(\d+(\.\d+)+)' -AllMatches | foreach-object {
            $_.matches.value
            }
            $oidarray = $alloids | Where-Object { $allowedOids -contains $_ }
    } else {write-host "Error retrieving certificate usages / OIDs"}
 
    #prep the other parts of the list for use in the GPO
    $oidlist = $oidarray -join ","
    $suffix = "UpnSuffix=mil"
    
    #create the final output in the format thumbprint;usages;upnsuffix
    $finalout = "$thumb;$oidlist;$suffix"
    Write-Host "---------------------------------------------------------------------------"
    Write-Host "Strong cert binding string created:" 
    Write-host "$finalout"
    Write-Host "---------------------------------------------------------------------------"
    }
Catch {
    Write-Host "Error generating the cert string"
    }
 
Try {
    $gponame = Read-Host "Enter the name of the Domain Controllers GPO to update"
    $regkey = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\KDC\Parameters"
    $reg = Get-GPRegistryValue -name $gponame -key $regkey -valuename "StrongNameMatchesList"
    $oldvalue = $reg.value
    $newvalue = $oldvalue + $finalout
    $cleanvalue = $newvalue | sort-object -Unique
 
    Set-GPRegistryValue -Name $gponame -Key $regkey -ValueName "StrongNameMatchesList" -Type MultiString -Value $cleanvalue
    }
Catch {
    Write-Host "Error writing GPO"
    }
 
 
#add the cert to the NTauth
$certlist = certutil -store -enterprise NTauth | where-object { $_ -match "Cert Hash" } | ForEach-Object { ($_ -split ":")[1].Trim().Replace(" ", "") }
if ($certlist -contains $thumb) {}
else {
    Certutil -dspublish -enterprise NTAuth $certpath
    }
 
    Write-Host "Don't forget to add the cert to your organization's Root Certificates GPO"