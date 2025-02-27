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