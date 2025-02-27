# List of apps to install
$apps = @(
    "Microsoft.VisualStudioCode",
    "Google.Chrome",
    "Mozilla.Firefox",
    "7zip.7zip",
    "Notepad++.Notepad++",
    "Git.Git",
    "Spotify.Spotify"
)

# Install apps
foreach ($app in $apps) {
    Write-Host "Installing $app..."
    winget install --id $app --silent --accept-package-agreements --accept-source-agreements
}

# Update all installed apps
Write-Host "Updating all installed apps..."
winget upgrade --all --silent --accept-package-agreements --accept-source-agreements

Write-Host "All tasks completed."