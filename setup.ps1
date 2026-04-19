if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as an Administrator!"
    break
}

if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Error "PowerShell 7 or higher is required to run this script."
    Write-Host "Current version: $($PSVersionTable.PSVersion)"
    Write-Host "Please install PowerShell 7+ from: https://aka.ms/PSWindows"
    Write-Host "Or run: winget install Microsoft.PowerShell"
    break
}

try {
    $gitVersion = git --version 2>$null
    if (-not $gitVersion) {
        throw "Git not found"
    }
    Write-Host "Git is installed: $gitVersion"
}
catch {
    Write-Error "Git is required but not installed."
    Write-Host "Please install Git from: https://git-scm.com/download/win"
    Write-Host "Or run: winget install Git.Git"
    break
}

function Test-InternetConnection {
    try {
        Test-Connection -ComputerName www.google.com -Count 1 -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        Write-Warning "Internet connection is required but not available. Please check your connection."
        return $false
    }
}

function Install-NerdFonts {
    param (
        [string]$FontName = "CascadiaCode",
        [string]$FontDisplayName = "CaskaydiaCove NF",
        [string]$Version = "3.2.1"
    )

    try {
        [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
        $fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name
        if ($fontFamilies -notcontains "${FontDisplayName}") {
            $fontZipUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v${Version}/${FontName}.zip"
            $zipFilePath = "$env:TEMP\${FontName}.zip"
            $extractPath = "$env:TEMP\${FontName}"

            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFileAsync((New-Object System.Uri($fontZipUrl)), $zipFilePath)

            while ($webClient.IsBusy) {
                Start-Sleep -Seconds 2
            }

            Expand-Archive -Path $zipFilePath -DestinationPath $extractPath -Force
            $destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
            Get-ChildItem -Path $extractPath -Recurse -Filter "*.ttf" | ForEach-Object {
                If (-not(Test-Path "C:\Windows\Fonts\$($_.Name)")) {
                    $destination.CopyHere($_.FullName, 0x10)
                }
            }

            Remove-Item -Path $extractPath -Recurse -Force
            Remove-Item -Path $zipFilePath -Force
        }
        else {
            Write-Host "Font ${FontDisplayName} already installed"
        }
    }
    catch {
        Write-Error "Failed to download or install ${FontDisplayName} font. Error: $_"
    }
}

function Get-ProfileDir {
    if ($PSVersionTable.PSEdition -eq "Core") {
        return "$env:userprofile\Documents\PowerShell"
    }
    elseif ($PSVersionTable.PSEdition -eq "Desktop") {
        return "$env:userprofile\Documents\WindowsPowerShell"
    }
    else {
        Write-Error "Unsupported PowerShell edition: $($PSVersionTable.PSEdition)"
        break
    }
}

function Test-WingetPackageInstalled {
    param (
        [string]$PackageId
    )
    try {
        $result = winget list --id $PackageId --exact 2>$null
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
}

function Test-ScoopPackageInstalled {
    param (
        [string]$PackageName
    )
    try {
        $result = scoop list $PackageName 2>$null
        return ($result -match $PackageName)
    }
    catch {
        return $false
    }
}

function Test-ChocolateyInstalled {
    try {
        $null = Get-Command choco -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

function Test-ScoopInstalled {
    try {
        $null = Get-Command scoop -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

function Test-ModuleInstalled {
    param (
        [string]$ModuleName
    )
    return (Get-Module -ListAvailable -Name $ModuleName -ErrorAction SilentlyContinue)
}

if (-not (Test-InternetConnection)) {
    break
}

if (!(Test-Path -Path $PROFILE -PathType Leaf)) {
    try {
        $profilePath = Get-ProfileDir

        if (!(Test-Path -Path $profilePath)) {
            New-Item -Path $profilePath -ItemType "directory" -Force
        }

        Invoke-RestMethod https://github.com/akrista/pwsh-pf/raw/master/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
        Write-Host "The profile @ [$PROFILE] has been created."
        Write-Host "If you want to make any personal changes or customizations, please do so at [$profilePath\Profile.ps1] as there is an updater in the installed profile which uses the hash to update the profile and will lead to loss of changes"
    }
    catch {
        Write-Error "Failed to create or update the profile. Error: $_"
    }
}
else {
    try {
        $backupPath = Join-Path (Split-Path $PROFILE) "oldprofile.ps1"
        Move-Item -Path $PROFILE -Destination $backupPath -Force
        Invoke-RestMethod https://github.com/akrista/pwsh-pf/raw/main/Microsoft.PowerShell_profile.ps1 -OutFile $PROFILE
        Write-Host "✅ PowerShell profile at [$PROFILE] has been updated."
        Write-Host "📦 Your old profile has been backed up to [$backupPath]"
        Write-Host "⚠️ NOTE: Please back up any persistent components of your old profile to [$HOME\Documents\PowerShell\Profile.ps1] as there is an updater in the installed profile which uses the hash to update the profile and will lead to loss of changes"
    }
    catch {
        Write-Error "❌ Failed to backup and update the profile. Error: $_"
    }
}

function Install-OhMyPoshTheme {
    param (
        [string]$ThemeName = "lambdageneration",
        [string]$ThemeUrl = "https://raw.githubusercontent.com/akrista/pwsh-pf/main/lambdageneration.omp.json"
    )
    $profilePath = Get-ProfileDir
    if (!(Test-Path -Path $profilePath)) {
        New-Item -Path $profilePath -ItemType "directory"
    }
    $themeFilePath = Join-Path $profilePath "$ThemeName.omp.json"
    try {
        Invoke-RestMethod -Uri $ThemeUrl -OutFile $themeFilePath
        Write-Host "Oh My Posh theme '$ThemeName' has been downloaded to [$themeFilePath]"
        return $themeFilePath
    }
    catch {
        Write-Error "Failed to download Oh My Posh theme. Error: $_"
        return $null
    }
}

try {
    if (Test-WingetPackageInstalled -PackageId "JanDeDobbeleer.OhMyPosh") {
        Write-Host "Oh My Posh is already installed. Skipping installation."
    }
    else {
        winget install -e --accept-source-agreements --accept-package-agreements JanDeDobbeleer.OhMyPosh
        Write-Host "Oh My Posh installed successfully."
    }
}
catch {
    Write-Error "Failed to install Oh My Posh. Error: $_"
}

$themeInstalled = Install-OhMyPoshTheme -ThemeName "lambdageneration"

Install-NerdFonts -FontName "CascadiaCode" -FontDisplayName "CaskaydiaCove NF"

if ((Test-Path -Path $PROFILE) -and (winget list --name "OhMyPosh" -e) -and ($fontFamilies -contains "CaskaydiaCove NF") -and $themeInstalled) {
    Write-Host "Setup completed successfully. Please restart your PowerShell session to apply changes."
}
else {
    Write-Warning "Setup completed with errors. Please check the error messages above."
}

try {
    if (Test-ChocolateyInstalled) {
        Write-Host "Chocolatey is already installed. Skipping installation."
    }
    else {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        $chocoScript = (New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')
        Invoke-Expression $chocoScript
        Write-Host "Chocolatey installed successfully."
    }
}
catch {
    Write-Error "Failed to install Chocolatey. Error: $_"
}
try {
    if (Test-ScoopInstalled) {
        Write-Host "Scoop is already installed. Skipping installation."
    }
    else {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
        Invoke-RestMethod -Uri https://get.scoop.sh -OutFile "$env:TEMP\install-scoop.ps1"
        & "$env:TEMP\install-scoop.ps1" -RunAsAdmin
        Remove-Item "$env:TEMP\install-scoop.ps1" -Force
        Write-Host "Scoop installed successfully."
    }
    
    # Add extras bucket if not already added
    $buckets = scoop bucket list 2>$null
    if ($buckets -notmatch "extras") {
        scoop bucket add extras
        Write-Host "Added extras bucket to Scoop."
    }
}
catch {
    Write-Error "Failed to install Scoop. Error: $_"
}
try {
    if (Test-ModuleInstalled -ModuleName "Terminal-Icons") {
        Write-Host "Terminal-Icons module is already installed. Skipping installation."
    }
    else {
        Install-Module -Name Terminal-Icons -Repository PSGallery -Force
        Write-Host "Terminal Icons module installed successfully."
    }
}
catch {
    Write-Error "Failed to install Terminal Icons module. Error: $_"
}
try {
    if (Test-WingetPackageInstalled -PackageId "ajeetdsouza.zoxide") {
        Write-Host "zoxide is already installed. Skipping installation."
    }
    else {
        winget install -e --id ajeetdsouza.zoxide
        Write-Host "zoxide installed successfully."
    }
}
catch {
    Write-Error "Failed to install zoxide. Error: $_"
}
try {
    if (Test-ScoopPackageInstalled -PackageName "bat") {
        Write-Host "bat is already installed. Skipping installation."
    }
    else {
        scoop install bat
        Write-Host "bat installed successfully."
    }
}
catch {
    Write-Error "Failed to install bat. Error: $_"
}
try {
    if (Test-ScoopPackageInstalled -PackageName "gsudo") {
        Write-Host "gsudo is already installed. Skipping installation."
    }
    else {
        scoop install gsudo
        Write-Host "gsudo installed successfully."
    }
}
catch {
    Write-Error "Failed to install gsudo. Error: $_"
}
try {
    if (Test-ScoopPackageInstalled -PackageName "ripgrep") {
        Write-Host "ripgrep is already installed. Skipping installation."
    }
    else {
        scoop install ripgrep
        Write-Host "ripgrep installed successfully."
    }
}
catch {
    Write-Error "Failed to install ripgrep. Error: $_"
}
try {
    if (Test-ScoopPackageInstalled -PackageName "fd") {
        Write-Host "fd is already installed. Skipping installation."
    }
    else {
        scoop install fd
        Write-Host "fd installed successfully."
    }
}
catch {
    Write-Error "Failed to install fd. Error: $_"
}
try {
    if (Test-ScoopPackageInstalled -PackageName "gitui") {
        Write-Host "gitui is already installed. Skipping installation."
    }
    else {
        scoop install gitui
        Write-Host "gitui installed successfully."
    }
}
catch {
    Write-Error "Failed to install gitui. Error: $_"
}

# Set execution policy to allow running PowerShell profiles
try {
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force
    Write-Host "Execution policy set to Unrestricted for CurrentUser scope."
    Write-Host "This allows your PowerShell profile to run automatically."
}
catch {
    Write-Warning "Failed to set execution policy. You may need to run 'Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser' manually."
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Setup completed!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Please restart your PowerShell session to apply all changes." -ForegroundColor Yellow