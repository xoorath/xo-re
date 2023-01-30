param(
    $InstallDir=$PSScriptRoot
)

if(-not (Test-Path "$InstallDir\Installers")) {
    New-Item -ItemType Directory -Path "$InstallDir\Installers" | Out-Null
}


function Install-Ida
{
    $idaVersion="82"

    # Download the installer
    $installerExe = "idafree$($idaVersion)_windows.exe";
    $installerExePath = "$InstallDir\Installers\$installerExe";
    if(-not (Test-Path -Path $installerExePath))
    {
        # Define IDA Free download URL
        $url = "https://out7.hex-rays.com/files/$installerExe"
        # Download the IDA Free installer to the destination folder
        Invoke-WebRequest -Uri $url -OutFile $installerExePath
    } else {
        Write-Host "Ida installer already downloaded."
    }

    # Run the installer
    $destination = "$InstallDir\idafree$idaVersion"
    if(-not (Test-Path $destination)) {
        # Start the installer and specify the destination folder as the installation location
        Start-Process $installerExePath "--unattendedmodeui minimalWithDialogs --mode unattended --prefix $destination"
    } else {
        Write-Host "Ida free already installed at $destination"
    }

    # Create shortcut
    $targetPath = "$destination\ida64.exe"
    $shortcutPath = "$InstallDir\ida64.lnk"
    if(-not (Test-Path -Path $shortcutPath))
    {
        $wsh = New-Object -ComObject WScript.Shell
        $shortcut = $wsh.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $targetPath
        $shortcut.Save()
    }

}

function Install-ILSpy {
    $ilspyVersion = "8.0-preview3"
    $installerExe = "ILSpy_Installer_8.0.0.7246-preview3.msi"
    $installerExePath =  "$InstallDir\Installers\$installerExe"

    if (-not (Test-Path -Path $installerExePath)) {
        $url = "https://github.com/icsharpcode/ILSpy/releases/download/v8.0-preview3/ILSpy_Installer_8.0.0.7246-preview3.msi"
        Invoke-WebRequest -Uri $url -OutFile $installerExePath
    } else {
        Write-Host "ILSpy installer already downloaded."
    }

    $destination = "$InstallDir\ILSpy-$ilspyVersion"

    if (-not (Test-Path $destination) -or $true) {
        Start-Process msiexec.exe -Wait -ArgumentList "INSTALLDIR=""$destination"" /i ""$installerExePath"" /passive /qb"
    } else {
        Write-Host "ILSpy already installed at $destination"
    }

    # Create shortcut
    $targetPath = "$destination\ILSpy.exe"
    $shortcutPath = "$InstallDir\ILSpy.lnk"
    if(-not (Test-Path -Path $shortcutPath))
    {
        $wsh = New-Object -ComObject WScript.Shell
        $shortcut = $wsh.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $targetPath
        $shortcut.Save()
    }
}

function Install-dnSpy {
    $zipPath = "$InstallDir/Installers/dnSpy.zip"
    $installedPath = "$InstallDir/dnSpy"

    if(-not (Test-Path $zipPath))
    {
        $url = "https://github.com/dnSpy/dnSpy/releases/download/v6.1.8/dnSpy-net-win64.zip"
        Invoke-WebRequest -Uri $url -OutFile $zipPath
    }
    else
    {
        Write-Host "dnSpy zip already downloaded"
    }
    
    $targetPath = "$installedPath\dnSpy.exe"
    if(-not (Test-Path $targetPath))
    {
        Expand-Archive -Path $zipPath -DestinationPath $installedPath
    }
    else
    {
        Write-Host "dnSpy already extracted"
    }
    
    $shortcutPath = "$InstallDir\dnSpy.lnk"
    if(-not (Test-Path $shortcutPath))
    {
        $wsh = New-Object -ComObject WScript.Shell
        $shortcut = $wsh.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $targetPath
        $shortcut.Save()
    }
}

function Install-VSCode {
    $zipPath = "$InstallDir/Installers/VSCode.zip"
    $installedPath = "$InstallDir/VSCode"

    if(-not (Test-Path $zipPath))
    {
        $url = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-archive"
        Invoke-WebRequest -Uri $url -OutFile $zipPath
    }
    else
    {
        Write-Host "VSCode zip already downloaded"
    }
    
    $targetPath = "$installedPath\Code.exe"
    if(-not (Test-Path $targetPath))
    {
        Expand-Archive -Path $zipPath -DestinationPath $installedPath
    }
    else
    {
        Write-Host "VSCode already extracted"
    }
    
    $shortcutPath = "$InstallDir\Code.lnk"
    if(-not (Test-Path $shortcutPath))
    {
        $wsh = New-Object -ComObject WScript.Shell
        $shortcut = $wsh.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $targetPath
        $shortcut.Save()
    }
}

function Install-x64dbg
{
    $x64dbgVersion="snapshot_2023-01-25_11-53"
    # Download the installer
    
 
    $zipPath = "$InstallDir/Installers/$x64dbgVersion.zip"
    $installedPath = "$InstallDir/x64dbg"

    if(-not (Test-Path $zipPath))
    {
        $url = "https://gigenet.dl.sourceforge.net/project/x64dbg/snapshots/$x64dbgVersion.zip"
        Invoke-WebRequest -Uri $url -OutFile $zipPath
    }
    else
    {
        Write-Host "x64dbg zip already downloaded"
    }
    
    $targetPath = "$installedPath\release\x64\x64dbg.exe"
    if(-not (Test-Path $targetPath))
    {
        Expand-Archive -Path $zipPath -DestinationPath $installedPath
    }
    else
    {
        Write-Host "x64dbg already extracted"
    }
    
    $shortcutPath = "$InstallDir\x64dbg.lnk"
    if(-not (Test-Path $shortcutPath))
    {
        $wsh = New-Object -ComObject WScript.Shell
        $shortcut = $wsh.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $targetPath
        $shortcut.Save()
    }
}

Install-Ida
Install-ILSpy
Install-dnSpy
Install-VSCode
Install-x64dbg
