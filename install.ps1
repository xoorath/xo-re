param(
    $InstallDir = $PSScriptRoot
)

####################################################################################################
# Setup
####################################################################################################

# Ensure the installers directory exists 
New-Item -ItemType Directory -Path "$InstallDir/Installers" -Force | Out-Null

####################################################################################################
# Helpers
####################################################################################################

function Get-LocalInstallMediaPath {
    param(
        [string]$ToolName,
        [string]$Extension
    )

    $localInstallerPath = [IO.Path]::Combine($InstallDir, 'Installers', "$ToolName.$Extension")
    return $localInstallerPath 
}

function Invoke-DownloadInstaller {
    param(
        [string]$Url,
        [string]$DestinationFile
    )
    
    if (Test-Path -Path $DestinationFile) {
        Write-Information "File already downloaded. $DestinationFile"
    }
    else {
        # Ensure the required directories exist.
        New-Item -ItemType Directory -Path (Split-Path $DestinationFile -Parent) -Force | Out-Null

        Invoke-WebRequest -Uri $Url -OutFile $DestinationFile
    }
    
}

function New-ToolShortcut {
    param(
        [string]$TargetPath
    )

    if (Test-Path -Path $TargetPath) {
        $shortcutPath = [IO.Path]::Combine($InstallDir, "$([System.IO.Path]::GetFileNameWithoutExtension($TargetPath)).lnk")
        if (Test-Path $shortcutPath) {
            Write-Information "[skip] Shortcut already exists. Skipping shortcut creation. ($shortcutPath)"
        }
        else {
            $wsh = New-Object -ComObject WScript.Shell
            $shortcut = $wsh.CreateShortcut($shortcutPath)
            $shortcut.TargetPath = $targetPath
            $shortcut.Save()
            return $shortcut
        }
    }
    else {
        Write-Warning "[warn] Could not find executable after install. Skipping shortcut creation. ($TargetPath)"
    }
    return $null
}

####################################################################################################
# Installation scripts
####################################################################################################

function Install-GenericZip {
    param(
        [string]$ZipUrl,
        [string]$ToolName,
        [string]$InnerExecutable
    )

    $localZipPath = [IO.Path]::Combine($InstallDir, "Installers", "$ToolName.zip")
    Invoke-DownloadInstaller -Url $ZipUrl -DestinationFile $localZipPath
    $ToolInstallLocation = [IO.Path]::Combine($InstallDir, $ToolName)
    $targetExecutable = [IO.Path]::Combine($toolInstallLocation, $InnerExecutable);
    # If there's no inner executable just check for the install directory instead.
    # This indicates no shortcut is desired at the end (ie: java for ghidra. nobody wants a java shortcut.)
    if ($null -eq $InnerExecutable) {
        $targetExecutable = $toolInstallLocation;
    }
    if (Test-Path -Path $targetExecutable) {
        Write-Information "[skip] $ToolName already exists. Skipping unpack. ($targetExecutable)"
    }
    else {
        if (-not (Test-Path -Path $toolInstallLocation)) { New-Item -ItemType Directory -Path $toolInstallLocation | Out-Null }
        Expand-Archive -Path $localZipPath -DestinationPath $ToolInstallLocation
    }
    if ([string]::IsNullOrWhiteSpace($InnerExecutable)) {
        return $null
    }
    return New-ToolShortcut -TargetPath $targetExecutable
}

function Install-GenericInstaller {
    param(
        [string]$InstallerUrl,
        # Can contain the string "{destination}" which will be replaced with the target installation directory.
        [string]$InstallerArgs,
        [string]$ToolName,
        [string]$InnerExecutable
    )
    $localInstallerPath = [IO.Path]::Combine($InstallDir, "Installers", "$ToolName.exe")
    Invoke-DownloadInstaller -Url $InstallerUrl -DestinationFile $localInstallerPath
    $toolInstallLocation = [IO.Path]::Combine($InstallDir, $ToolName)
    $InstallerArgs = $InstallerArgs -replace "{destination}", $toolInstallLocation
    $targetExecutable = [IO.Path]::Combine($toolInstallLocation, $InnerExecutable);
    # If there's no inner executable just check for the install directory instead.
    # This indicates no shortcut is desired at the end (ie: java for ghidra. nobody wants a java shortcut.)
    if ($null -eq $InnerExecutable) {
        $targetExecutable = $toolInstallLocation;
    }

    if (Test-Path -Path $targetExecutable) {
        Write-Information "[skip] $ToolName already exists. Skipping install. ($targetExecutable)"
    }
    else {
        if (-not (Test-Path -Path $toolInstallLocation)) { New-Item -ItemType Directory -Path $toolInstallLocation | Out-Null }
        Start-Process -Wait -FilePath $localInstallerPath -ArgumentList $InstallerArgs
    }
    if ([string]::IsNullOrWhiteSpace($InnerExecutable)) {
        return $null
    }
    return New-ToolShortcut -TargetPath $targetExecutable
}

function Install-MSIInstaller {
    param(
        [string]$InstallerUrl,
        [string]$ToolName,
        [string]$InnerExecutable
    )
    
    $localInstallerPath = [IO.Path]::Combine($InstallDir, 'Installers', "$ToolName.msi")
    Invoke-DownloadInstaller -Url $InstallerUrl -DestinationFile $localInstallerPath
    $toolInstallLocation = [IO.Path]::Combine($InstallDir, $ToolName)
    $targetExecutable = [IO.Path]::Combine($toolInstallLocation, $InnerExecutable);
    # If there's no inner executable just check for the install directory instead.
    # This indicates no shortcut is desired at the end (ie: java for ghidra. nobody wants a java shortcut.)
    if ($null -eq $InnerExecutable) {
        $targetExecutable = $toolInstallLocation;
    }
    if (Test-Path -Path $targetExecutable) {
        Write-Information "[skip] $ToolName already exists. Skipping install. ($targetExecutable)"
    }
    else {
        if (-not (Test-Path -Path $toolInstallLocation)) { New-Item -ItemType Directory -Path $toolInstallLocation | Out-Null }
        Write-Host "installing $localInstallerPath"
        if (-not (Test-Path -Path $localInstallerPath)) { Write-Error "$localInstallerPath cant be found" }
        $msiexec = [IO.Path]::Combine([System.Environment]::SystemDirectory, "msiexec.exe")
        Start-Process -FilePath $msiexec -ArgumentList "/passive /i $localInstallerPath INSTALLDIR=""$toolInstallLocation""" -Wait
    }
    if ([string]::IsNullOrWhiteSpace($InnerExecutable)) {
        return $null
    }
    return New-ToolShortcut -TargetPath $targetExecutable
}

function Install-Ida {
    [void](Install-GenericInstaller -InstallerUrl "https://out7.hex-rays.com/files/idafree82_windows.exe" -InstallerArgs "--unattendedmodeui minimalWithDialogs --mode unattended --prefix {destination}" -ToolName "IdaFree" -InnerExecutable "ida64.exe")
}

function Install-ILSpy {
    [void](Install-MSIInstaller -InstallerUrl "https://github.com/icsharpcode/ILSpy/releases/download/v8.0-preview3/ILSpy_Installer_8.0.0.7246-preview3.msi" -ToolName "ILSpy" -InnerExecutable "ILSpy.exe")
}

function Install-dnSpy {
    [void](Install-GenericZip -ZipUrl "https://github.com/dnSpy/dnSpy/releases/download/v6.1.8/dnSpy-net-win64.zip" -ToolName "dnSpy" -InnerExecutable "dnSpy.exe")
}

function Install-VSCode {
    [void](Install-GenericZip -ZipUrl "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-archive" -ToolName "VSCode" -InnerExecutable "code.exe")
}

function Install-x64dbg {
    [void](Install-GenericZip -ZipUrl "https://gigenet.dl.sourceforge.net/project/x64dbg/snapshots/snapshot_2023-01-25_11-53.zip" -ToolName "x64dbg" -InnerExecutable "release\x64\x64dbg.exe")
}

function Install-ghidra {
    # jdk
    [void](Install-GenericZip -ZipUrl "https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.18%2B10/OpenJDK11U-jdk_x64_windows_hotspot_11.0.18_10.zip" -ToolName "JDK")
    # ghidra
    [void](Install-GenericZip -ZipUrl "https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_10.2.2_build/ghidra_10.2.2_PUBLIC_20221115.zip" -ToolName "ghidra")

    $batchFile = "$InstallDir/ghidraRun.bat"
    $batchCommands = "@echo off`n"+
    "set JAVA_HOME=$InstallDir/jdk-11.0.18+10`n"+
    "set PATH=%JAVA_HOME%\bin;%PATH%`n"+
    "cd %~dp0ghidra/ghidra_10.2.2_PUBLIC`n"+
    "CALL ghidraRun.bat`n"+
    "cd %~dp0`n";
    
    # write the commands to the batch file
    $batchCommands | Out-File -FilePath $batchFile
}

function Install-7Zip
{
    [void](Install-GenericInstaller -InstallerUrl "https://www.7-zip.org/a/7z2201-x64.exe" -InstallerArgs "/S /D={destination}" -ToolName "7zip" -InnerExecutable "7zFM.exe")
}

Install-Ida
Install-ILSpy
Install-dnSpy
Install-VSCode
Install-x64dbg
Install-ghidra
Install-7Zip
