# Download-SFTPFile.ps1
# Downloads files matching a regex pattern from a remote SFTP server to a local folder using WinSCP .NET assembly.
# Usage: .\Download-SFTPFile.ps1 -HostName "sftp.example.com" -UserName "myuser" -Password "mypass" `
#            -SshHostKeyFingerprint "ssh-rsa 2048 xx:xx:..." `
#            -RemotePath "/uploads/" -FilePattern "^report.*\.csv$" -LocalFolder "C:\Downloads"
# Or:    .\Download-SFTPFile.ps1 -HostName "sftp.example.com" -UserName "myuser" -Password "mypass" `
#            -AcceptAnySshHostKey -RemotePath "/uploads/" -FilePattern "^report.*\.csv$" -LocalFolder "C:\Downloads"

param(
    [Parameter(Mandatory)][string]$HostName,
    [Parameter(Mandatory)][string]$UserName,
    [Parameter(Mandatory)][string]$Password,
    [string]$SshHostKeyFingerprint,
    [switch]$AcceptAnySshHostKey,
    [string]$RemotePath = "/uploads/",
    [Parameter(Mandatory)][string]$FilePattern,
    [Parameter(Mandatory)][string]$LocalFolder,
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

# ── Connect and download matching files ──────────────────────────────
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

    $directoryInfo = $session.ListDirectory($RemotePath)
    $downloadCount = 0

    foreach ($file in $directoryInfo.Files) {
        if ($file.IsDirectory) { continue }
        if ($file.Name -match $FilePattern) {
            $remoteFull = $RemotePath + $file.Name
            $localDest = Join-Path $LocalFolder $file.Name
            $result = $session.GetFiles($remoteFull, $localDest, $false, $transferOptions)
            $result.Check()
            foreach ($transfer in $result.Transfers) {
                Write-Host "Downloaded: $($transfer.FileName) -> $($transfer.Destination)"
            }
            $downloadCount++
        }
    }

    if ($downloadCount -eq 0) {
        Write-Host "No files matching pattern '$FilePattern' found in $RemotePath"
    } else {
        Write-Host "Downloaded $downloadCount file(s)"
    }
}
finally {
    $session.Dispose()
}
