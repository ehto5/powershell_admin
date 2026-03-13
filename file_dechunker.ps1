Add-Type -AssemblyName System.Windows.Forms
 
# Select the first chunk file
Write-Host "Select the first chunk file (part0)"
$filebrowser = New-Object System.Windows.Forms.OpenFileDialog
$filebrowser.InitialDirectory = [Environment]::GetFolderPath('Desktop')
$filebrowser.Filter = "Part files (*.part0)|*.part0|All files (*.*)|*.*"
if ($filebrowser.ShowDialog() -eq "OK") {
    $chunkFileBasePath = $filebrowser.FileName -replace '0$', ''
    }
 
# Select the output file location
Write-Host "Select the output file location and name"
$savebrowser = New-Object System.Windows.Forms.SaveFileDialog
$savebrowser.InitialDirectory = [Environment]::GetFolderPath('Desktop')
$savebrowser.Filter = "All files (*.*)|*.*"
if ($savebrowser.ShowDialog() -eq "OK") {
    $outputFilePath = $savebrowser.FileName
    }
 
$confirm = Read-Host "Merge chunks from $chunkFileBasePath* into $outputFilePath ? (Y/N)"
if ($confirm -match '^[Yy]$') {
    Write-Host "Proceeding..."
    }
else {
    Write-Host "Aborting"
    return
    }
 
$index = 0
$outputStream = [System.IO.File]::Create($outputFilePath)
try {
    while (Test-Path "$chunkFileBasePath$index") {
        $chunkFilePath = "$chunkFileBasePath$index"
        $chunkData = [System.IO.File]::ReadAllBytes($chunkFilePath)
        $outputStream.Write($chunkData, 0, $chunkData.Length)
        Write-Host "Merged chunk: $chunkFilePath"
        $index++
    }
} finally {
    $outputStream.Close()
}
Write-Host "File reconstruction complete. Output file: $outputFilePath"
 