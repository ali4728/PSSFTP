# Remove-SFTPFile.ps1
# Connects to a remote SFTP server and deletes files matching a regex pattern.
# Usage: .\Remove-SFTPFile.ps1 -HostName "sftp.example.com" -UserName "myuser" -Password "mypass" `
#            -SshHostKeyFingerprint "ssh-rsa 2048 xx:xx:..." `
#            -RemotePath "/uploads/" -FilePattern "^qwerty.*\.csv$"
# Or:    .\Remove-SFTPFile.ps1 -HostName "sftp.example.com" -UserName "myuser" -Password "mypass" `
#            -AcceptAnySshHostKey -RemotePath "/uploads/" -FilePattern "^qwerty.*\.csv$"

param(
    [Parameter(Mandatory)][string]$HostName,
    [Parameter(Mandatory)][string]$UserName,
    [Parameter(Mandatory)][string]$Password,
    [string]$SshHostKeyFingerprint,
    [switch]$AcceptAnySshHostKey,
    [string]$RemotePath = "/uploads/",
    [string]$FilePattern = "^qwerty.*\.csv$"
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

# ── Connect and delete matching files ────────────────────────────────
$session = New-Object WinSCP.Session
try {
    $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
        Protocol   = [WinSCP.Protocol]::Sftp
        HostName   = $HostName
        PortNumber = 22
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
    Write-Host "Connected to ${HostName} as ${UserName}"

    $directoryInfo = $session.ListDirectory($RemotePath)
    $matchCount = 0

    foreach ($file in $directoryInfo.Files) {
        if ($file.IsDirectory) { continue }
        if ($file.Name -match $FilePattern) {
            $fullPath = $RemotePath + $file.Name
            $session.RemoveFile($fullPath)
            Write-Host "Deleted: $fullPath"
            $matchCount++
        }
    }

    if ($matchCount -eq 0) {
        Write-Host "No files matching pattern '$FilePattern' found in $RemotePath"
    } else {
        Write-Host "Deleted $matchCount file(s)"
    }
}
finally {
    $session.Dispose()
}
