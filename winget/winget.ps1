#
# irm -Uri "https://raw.githubusercontent.com/bodav/dotfiles/refs/heads/main/winget/winget.ps1" | Invoke-Expression
#

# URL to fetch the list of apps
$url = "https://raw.githubusercontent.com/bodav/dotfiles/refs/heads/main/winget/install.txt"

# Fetch the list of apps from the URL
try {
    $apps = Invoke-RestMethod -Uri $url -ErrorAction Stop
    $apps = $apps -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
}
catch {
    Write-Host "Failed to fetch the list of apps from the URL."
    exit 1
}

# Install apps
foreach ($app in $apps) {
    Write-Host "Installing $app..."
    winget install --id $app --silent --accept-package-agreements --accept-source-agreements
}

# Update all installed apps
Write-Host "Updating all installed apps..."
winget upgrade --all --silent --accept-package-agreements --accept-source-agreements

Write-Host "All tasks completed."


function del-desktop-shortcuts {
    # TODO: Remove desktop shortcuts
    # Register events for removing desktop shortcuts
    $desktopPaths = [Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('CommonDesktop')

    foreach ($dir in $desktopPaths) {
        $Watcher = [System.IO.FileSystemWatcher]::new([Environment]::GetFolderPath($dir), "*.lnk")
        [void](Register-ObjectEvent -InputObject $Watcher -EventName "Created" -SourceIdentifier $dir -Action { Remove-Item -Force $EventArgs.FullPath })
    }
  
    # Install WinGet
    winget install $args
  
    # Unregister Events
    foreach ($dir in $desktopPaths) { Unregister-Event -SourceIdentifier $dir }
}