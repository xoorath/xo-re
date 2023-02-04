# xo-re
A small toolkit of reverse engineering tools (bootstrapping installer)

# Setting up the environment

The following is intended to setup an environment with some tools that will be helpful from a new virtual machine or new computer. The installation script can be customized by commenting out features at the bottom of the file before running it.

## Admin Powershell
```
Set-ExecutionPolicy Unrestricted; (New-Object System.Net.WebClient).DownloadFile("https://raw.githubusercontent.com/xoorath/xo-re/main/install.ps1","$([Environment]::GetFolderPath('Desktop'))\install.ps1")
```

## User Powershell
```
&"$([Environment]::GetFolderPath('Desktop'))/install.ps1"
```
