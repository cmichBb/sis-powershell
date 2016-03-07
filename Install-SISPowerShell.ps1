$currentPrincipal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent() )

if ($currentPrincipal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator ))
{
    # Make sure the destination path we want to use exists

    $WinPSDir = Join-Path -Path $env:ProgramFiles -ChildPath "WindowsPowerShell"

    Write-Host "Checking For WindowsPowerShell folder in Program Files"
    if ( Test-Path $WinPSDir ){
        Write-Host "WindowsPowerShell folder exists in Program Files." -ForegroundColor Green
    }
    else
    {
        Write-Host "WindowsPowerShell folder does not exist in Program Files. Creating." -ForegroundColor Red
        New-Item -Path $WinPSDir -ItemType Directory
    }

    $WinPSModulesDir = Join-Path -Path $WinPSDir -ChildPath "Modules"

    Write-Host "Checking For Modules folder in WindowsPowerShell"
    if ( Test-Path $WinPSModulesDir ){
        Write-Host "Modules folder exists in WindowsPowerShell." -ForegroundColor Green
    }
    else
    {
        Write-Host "Modules folder does not exist in WindowsPowerShell. Creating." -ForegroundColor Red
        New-Item -Path $WinPSModulesDir -ItemType Directory
    }
    
    # Create the SIS-PowerShell Folder
    
    $SISPSFolder = Join-Path -Path $WinPSModulesDir -ChildPath "SIS-PowerShell"
    Write-Host "Checking for SIS-PowerShell folder in Modules"
    if ( Test-Path $SISPSFolder ){
        Write-Host "SIS-PowerShell Folder exists in Modules." -ForegroundColor Green
    }
    else
    {
        Write-Host "SIS-PowerShell Folder does not exist in Modules. Creating." -ForegroundColor Red
        New-Item -Path $SISPSFolder -ItemType Directory
    }
    
    # Copy Files to the SIS-PowerShell Folder
    
    $InstallerFolder = $PSScriptRoot
    Write-Host "Copying files to SIS-PowerShell Folder"
    Get-ChildItem $InstallerFolder -Exclude "Install-SISPowerShell.ps1" | Copy-Item -Destination $SISPSFolder -Verbose
}
else
{
    Write-Host "This installer must be run as an administrator." -ForegroundColor Red
}