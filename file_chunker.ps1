Add-Type -AssemblyName System.Windows.Forms
$filebrowser = New-Object System.Windows.Forms.OpenFileDialog
$filebrowser.InitialDirectory = [Environment]::GetFolderPath('Desktop')
$filebrowser.Filter = "iso (*.iso)|*.iso"
if ($filebrowser.ShowDialog() -eq "OK") {
    $filepath = $filebrowser.FileName
    }
$confirm = Read-Host "proceed with $filepath ? (Y/N)"
if ($confirm -match '^[Yy]$') {
    Write-Host "Making $filepath extra chunky"
    }
else {
    Write-host "Aborting"
    return
    }

$chunkthiccness = 100MB  # Define chunk size
$buffer = New-Object byte[] $chunkthiccness
$fs = [System.IO.File]::OpenRead($filepath)
$index = 0  # Initialize chunk index

while ($bytesRead = $fs.Read($buffer, 0, $buffer.Length)) {
    $chunkFile = "$filepath.part$index"
    [System.IO.File]::WriteAllBytes($chunkFile, $buffer[0..($bytesRead - 1)])
    $index++
}

$fs.Close()
Write-Host "File chunking complete. Created $index chunks."