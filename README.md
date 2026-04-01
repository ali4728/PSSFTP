# PSSFTP

**PowerShell SFTP file operations using the WinSCP .NET assembly.**

PSSFTP is a lightweight collection of PowerShell scripts for transferring and managing files on remote SFTP servers. It wraps the [WinSCP .NET assembly](https://winscp.net/eng/docs/library) to provide simple, scriptable commands for uploading files to and deleting files from SFTP endpoints — no GUI required.

## Features

- **Upload files** — Transfer local files matching a regex pattern to a remote SFTP directory.
- **Delete remote files** — Remove files on the server that match a regex pattern.
- **Regex-based file matching** — Target exactly the files you need using PowerShell regular expressions.
- **Flexible DLL discovery** — Automatically locates `WinSCPnet.dll` from several common paths.
- **SSH host key options** — Verify the server with a fingerprint, or bypass verification for testing with `-AcceptAnySshHostKey`.

## Scripts

| Script | Description |
|---|---|
| `Upload-SFTPFile.ps1` | Uploads local files matching a regex pattern to a remote SFTP path. |
| `Remove-SFTPFile.ps1` | Deletes remote files matching a regex pattern from an SFTP server. |

## Prerequisites

- **PowerShell** 5.1+ or PowerShell 7+
- **WinSCP .NET assembly** (`WinSCPnet.dll`) — place it under `.\WinSCP\netstandard2.0\`, `.\WinSCP\net40\`, or any of the other search paths listed in the scripts. Both .NET Framework 4.0 and .NET Standard 2.0 builds are supported.

## Usage

### Upload files

```powershell
.\Upload-SFTPFile.ps1 -HostName "sftp.example.com" -UserName "myuser" -Password "mypass" `
    -SshHostKeyFingerprint "ssh-rsa 2048 xx:xx:..." `
    -LocalFolder "C:\Data" -FilePattern "^report.*\.csv$" -RemotePath "/uploads/"
```

### Delete remote files

```powershell
.\Remove-SFTPFile.ps1 -HostName "sftp.example.com" -UserName "myuser" -Password "mypass" `
    -SshHostKeyFingerprint "ssh-rsa 2048 xx:xx:..." `
    -RemotePath "/uploads/" -FilePattern "^report.*\.csv$"
```

### Accept any SSH host key (testing only)

Replace `-SshHostKeyFingerprint "..."` with `-AcceptAnySshHostKey` on either script:

```powershell
.\Upload-SFTPFile.ps1 -HostName "sftp.example.com" -UserName "myuser" -Password "mypass" `
    -AcceptAnySshHostKey -LocalFolder "C:\Data" -FilePattern ".*\.txt$" -RemotePath "/incoming/"
```

## Parameters

### Upload-SFTPFile.ps1

| Parameter | Required | Default | Description |
|---|---|---|---|
| `-HostName` | Yes | — | SFTP server hostname or IP. |
| `-UserName` | Yes | — | SFTP username. |
| `-Password` | Yes | — | SFTP password. |
| `-SshHostKeyFingerprint` | No* | — | Server SSH host key fingerprint. |
| `-AcceptAnySshHostKey` | No* | — | Skip host key verification (testing only). |
| `-LocalFolder` | Yes | — | Local directory containing files to upload. |
| `-FilePattern` | Yes | — | Regex pattern to match file names. |
| `-RemotePath` | No | `/uploads/` | Destination path on the SFTP server. |
| `-PortNumber` | No | `22` | SFTP port number. |

\* One of `-SshHostKeyFingerprint` or `-AcceptAnySshHostKey` is required.

### Remove-SFTPFile.ps1

| Parameter | Required | Default | Description |
|---|---|---|---|
| `-HostName` | Yes | — | SFTP server hostname or IP. |
| `-UserName` | Yes | — | SFTP username. |
| `-Password` | Yes | — | SFTP password. |
| `-SshHostKeyFingerprint` | No* | — | Server SSH host key fingerprint. |
| `-AcceptAnySshHostKey` | No* | — | Skip host key verification (testing only). |
| `-RemotePath` | No | `/uploads/` | Remote directory to search for files. |
| `-FilePattern` | No | `^qwerty.*\.csv$` | Regex pattern to match remote file names. |

## Project Structure

```
PSSFTP/
├── Upload-SFTPFile.ps1       # Upload script
├── Remove-SFTPFile.ps1       # Delete script
├── Examples/
│   └── Example-Usage.ps1     # Quick-start example
└── WinSCP/
    ├── net40/                # WinSCP .NET Framework 4.0 assembly
    └── netstandard2.0/       # WinSCP .NET Standard 2.0 assembly
```

## License

The WinSCP .NET assembly is distributed under its own license — see `WinSCP/license-winscp.txt` and `WinSCP/license-dotnet.txt` for details.
