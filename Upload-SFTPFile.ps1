# Upload-SFTPFile.ps1
# Uploads files matching a regex pattern from a local folder to a remote SFTP server using WinSCP .NET assembly.
# Usage: .\Upload-SFTPFile.ps1 -HostName "sftp.example.com" -UserName "myuser" -Password "mypass" `
#            -SshHostKeyFingerprint "ssh-rsa 2048 xx:xx:..." `
#            -LocalFolder "C:\Data" -FilePattern "^report.*\.csv$" -RemotePath "/uploads/"
# Or:    .\Upload-SFTPFile.ps1 -HostName "sftp.example.com" -UserName "myuser" -Password "mypass" `
#            -AcceptAnySshHostKey -LocalFolder "C:\Data" -FilePattern "^report.*\.csv$" -RemotePath "/uploads/"

param(
    [Parameter(Mandatory)][string]$HostName,
    [Parameter(Mandatory)][string]$UserName,
    [Parameter(Mandatory)][string]$Password,
    [string]$SshHostKeyFingerprint,
    [switch]$AcceptAnySshHostKey,
    [Parameter(Mandatory)][string]$LocalFolder,
    [Parameter(Mandatory)][string]$FilePattern,
    [string]$RemotePath = "/uploads/",
    [int]$PortNumber = 22
)

# ── Load WinSCP .NET assembly ────────────────────────────────────────
$dllPath = $null
$searchPaths = @(
    "$PSScriptRoot\WinSCP\netstandard2.0\WinSCPnet.dll"
    "$PSScriptRoot\WinSCP\net40\WinSCPnet.dll"
    "$PSScriptRoot\WinSCP\WinSCPnet.dll"
    "$PSScriptRoot\lib\WinSCPnet.dll"
    "$PSScriptRoot\WinSCPnet.dll"
    "${env:ProgramFiles}\WinSCP\WinSCPnet.dll"
    "${env:ProgramFiles(x86)}\WinSCP\WinSCPnet.dll"
)
foreach ($path in $searchPaths) {
    if (Test-Path $path) {
        $dllPath = $path
        break
    }
}
if (-not $dllPath) {
    throw "WinSCPnet.dll not found. Place it under .\WinSCP\ or install WinSCP."
}
Add-Type -Path $dllPath
# ─────────────────────────────────────────────────────────────────────

# ── Connect and upload ───────────────────────────────────────────────
$session = New-Object WinSCP.Session
try {
    $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
        Protocol   = [WinSCP.Protocol]::Sftp
        HostName   = $HostName
        PortNumber = $PortNumber
        UserName   = $UserName
        Password   = $Password
    }

    if ($AcceptAnySshHostKey) {
        $sessionOptions.GiveUpSecurityAndAcceptAnySshHostKey = $true
    } elseif ($SshHostKeyFingerprint) {
        $sessionOptions.SshHostKeyFingerprint = $SshHostKeyFingerprint
    } else {
        throw "You must supply either -SshHostKeyFingerprint or -AcceptAnySshHostKey."
    }

    $session.Open($sessionOptions)
    Write-Host "Connected to ${HostName}:${PortNumber} as ${UserName}"

    $transferOptions = New-Object WinSCP.TransferOptions
    $transferOptions.TransferMode = [WinSCP.TransferMode]::Binary

    $files = Get-ChildItem -Path $LocalFolder -File | Where-Object { $_.Name -match $FilePattern }
    $uploadCount = 0

    foreach ($file in $files) {
        $result = $session.PutFiles($file.FullName, $RemotePath, $false, $transferOptions)
        $result.Check()
        foreach ($transfer in $result.Transfers) {
            Write-Host "Uploaded: $($transfer.FileName) -> $($transfer.Destination)"
        }
        $uploadCount++
    }

    if ($uploadCount -eq 0) {
        Write-Host "No files matching pattern '$FilePattern' found in $LocalFolder"
    } else {
        Write-Host "Uploaded $uploadCount file(s)"
    }
}
finally {
    $session.Dispose()
}
