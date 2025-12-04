$env:Path += ";C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools\x64"
$env:Path += ";C:\cmdtools"

# Proxy settings
#[System.Net.WebRequest]::DefaultWebProxy = [System.Net.WebRequest]::GetSystemWebProxy()
#[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials

Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Chord 'Ctrl+f' -Function ForwardWord
Set-PSReadLineKeyHandler -Chord 'Enter' -Function ValidateAndAcceptLine
$PSROptions = @{
    ContinuationPrompt = '  '
    Colors             = @{
        Operator         = $PSStyle.Foreground.Magenta
        Parameter        = $PSStyle.Foreground.Magenta
        Selection        = $PSStyle.Background.BrightBlack
        InLinePrediction = $PSStyle.Foreground.BrightYellow + $PSStyle.Background.BrightBlack
    }
}
Set-PSReadLineOption @PSROptions

$vsVersions = @(
    "C:\Program Files\Microsoft Visual Studio\18\Enterprise\Common7\IDE\devenv.exe",
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\IDE\devenv.exe"
)

$ssmsPath = "C:\Program Files\Microsoft SQL Server Management Studio 22\Release\Common7\IDE\Ssms.exe"
$ssmsSlnxPath = "C:\SQLScripts.slnx"

$slnSearchPath = "C:\dev\"

function prompt {

    $CmdWasSuccessfull = $?

    $host.ui.RawUI.WindowTitle = "$pwd"
    $CmdPromptCurrentFolder = Split-Path -Path $pwd -Leaf
    $IsHome = $pwd.Path -eq $HOME

    $inGitRepo = (git rev-parse --is-inside-work-tree 2> $null)

    $IsAdmin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

    $LastCommand = Get-History -Count 1
    if ($lastCommand) { 
        $RunTime = ($lastCommand.EndExecutionTime - $lastCommand.StartExecutionTime)
    }

    if ($RunTime.TotalSeconds -ge 60) {
        $ElapsedTime = $RunTime.ToString("mm\:ss")
    }
    elseif ($RunTime.TotalSeconds -lt 1) {
        $ElapsedTime = -join ([math]::Round(($RunTime.TotalMilliseconds), 0), "ms")
    }
    else {
        $ElapsedTime = -join ([math]::Round(($RunTime.TotalSeconds), 2), "s")
    }

    Write-Host ""
    
    # Top line with user info, path, and git branch
    Write-Host "╭─" -ForegroundColor DarkGray -NoNewline
    
    # Admin indicator
    if ($IsAdmin) {
	    Write-Host "  " -ForegroundColor DarkRed -NoNewline
        Write-Host "" -ForegroundColor DarkGray -NoNewline
    }
    
    # User and computer
    Write-Host " $($env:USERNAME) " -ForegroundColor Cyan -NoNewline
    
    Write-Host "│" -ForegroundColor DarkGray -NoNewline
    
    # Path
    Write-Host " 󰝰 " -ForegroundColor Green -NoNewline
    If ($IsHome) { 
        Write-Host "~" -ForegroundColor Green -NoNewline
    }
    ElseIf ($CmdPromptCurrentFolder -like "*:*") { 
        Write-Host "$CmdPromptCurrentFolder" -ForegroundColor Green -NoNewline
    }
    Else { 
        Write-Host ".\$CmdPromptCurrentFolder\" -ForegroundColor Green -NoNewline
    }
    
    Write-Host " " -NoNewline
    
    # Git branch
    if ($inGitRepo) {
        $gitBranch = git rev-parse --abbrev-ref HEAD
        
        # Get git status
        $gitStatus = git status --porcelain 2>$null
        $added = ($gitStatus | Where-Object { $_ -match '^\?\?' -or $_ -match '^A' }).Count
        $modified = ($gitStatus | Where-Object { $_ -match '^ M' -or $_ -match '^M' }).Count
        $deleted = ($gitStatus | Where-Object { $_ -match '^ D' -or $_ -match '^D' }).Count
        
        Write-Host "│" -ForegroundColor DarkGray -NoNewline
        Write-Host "  $($gitBranch)" -ForegroundColor Yellow -NoNewline
        
        # Show git stats
        if ($added -gt 0) {
            Write-Host " +$added" -ForegroundColor Green -NoNewline
        }
        if ($modified -gt 0) {
            Write-Host " ~$modified" -ForegroundColor Yellow -NoNewline
        }
        if ($deleted -gt 0) {
            Write-Host " -$deleted" -ForegroundColor Red -NoNewline
        }
        
        Write-Host " " -NoNewline
    }
    
    # Execution time
    Write-Host "│" -ForegroundColor DarkGray -NoNewline
    Write-Host " 󱎫 $elapsedTime" -ForegroundColor Blue -NoNewline
    
    Write-Host ""
    
    # Bottom line with prompt
    Write-Host "╰─" -ForegroundColor DarkGray -NoNewline
    
    If ($CmdWasSuccessfull) {
        Write-Host "❯" -ForegroundColor Green -NoNewline
    }
    else {
        Write-Host "✗" -ForegroundColor Red -NoNewline
    }
    
    return " "
}

function goto {
    param (
        $location
    )

    Switch ($location) {
        "repos" {
            Set-Location -Path "C:\Udvikler\git"
        }
        "r" {
            Set-Location -Path "C:\Udvikler\git"
        }
        "home" {
            Set-Location -Path "~\"
        }
        "h" {
            Set-Location -Path "~\"
        }
        default {
            Write-Output "Invalid location"
        }
    }
}

Set-Alias -Name g -Value goto

function touch {
    param(
        $filename
    )

    New-Item -Path $filename
}

function Get-AdUser {
    param(
        $username
    )

    (New-Object System.DirectoryServices.DirectorySearcher("(&(objectCategory=User)(samAccountName=$($username)))")).FindOne().GetDirectoryEntry().memberOf | Sort-Object
}

Set-Alias -Name aduser -Value Get-AdUser

function Get-AdGroup {
    param(
        $groupname
    )

    (New-Object System.DirectoryServices.DirectoryEntry((New-Object System.DirectoryServices.DirectorySearcher("(&(objectCategory=Group)(name=$($groupname)))")).FindOne().GetDirectoryEntry().Path)).member | % { (New-Object System.DirectoryServices.DirectoryEntry("LDAP://" + $_)) } | Sort-Object sAMAccountName | SELECT @{name = "User Name"; expression = { $_.Name } }, @{name = "User sAMAccountName"; expression = { $_.sAMAccountName } }
}

Set-Alias -Name adgroup -Value Get-AdGroup

function grep($regex, $dir) {
    if ( $dir ) {
        Get-ChildItem $dir | select-string $regex
        return
    }
    $input | select-string $regex
}

function find-file($name) {
    Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        $place_path = $_.directory
        Write-Output "${place_path}\${_}"
    }
}

function Open-VS([string]$Path = ".") {
    try {
        # Resolve the full path
        $fullPath = Resolve-Path -Path $Path -ErrorAction Stop

        # Check if path exists
        if (-not (Test-Path -Path $fullPath)) {
            Write-Error "Path '$fullPath' does not exist."
            return
        }

        $devenvPath = $null
        foreach ($vsPath in $vsVersions) {
            if (Test-Path $vsPath) {
                $devenvPath = $vsPath
                break
            }
        }

        if (-not $devenvPath) {
            Write-Error "Visual Studio installation not found. Please ensure Visual Studio is installed."
            return
        }

        # Check if the path is a solution file
        if ((Get-Item $fullPath).PSIsContainer) {
            # It's a folder - look for solution files
            $solutionFiles = Get-ChildItem -Path $fullPath -Include "*.sln","*.slnx" -File -Recurse
        
            if ($solutionFiles.Count -eq 1) {
                # Open the single solution file
                Write-Host "Opening solution '$($solutionFiles[0].Name)' in Visual Studio..." -ForegroundColor Cyan
                Start-Process -FilePath $devenvPath -ArgumentList "`"$($solutionFiles[0].FullName)`""
            }
            elseif ($solutionFiles.Count -gt 1) {
                # Multiple solutions found - let user choose
                Write-Host "Multiple solution files found:" -ForegroundColor Yellow
                for ($i = 0; $i -lt $solutionFiles.Count; $i++) {
                    Write-Host "[$i] $($solutionFiles[$i].Name)"
                }
                $choice = Read-Host "Enter the number of the solution to open (or press Enter to open folder)"
            
                if ($choice -match '^\d+$' -and [int]$choice -lt $solutionFiles.Count) {
                    $selectedSolution = $solutionFiles[[int]$choice]
                    Write-Host "Opening solution '$($selectedSolution.Name)' in Visual Studio..." -ForegroundColor Cyan
                    Start-Process -FilePath $devenvPath -ArgumentList "`"$($selectedSolution.FullName)`""
                }
                else {
                    # Open as folder
                    Write-Host "Opening folder '$fullPath' in Visual Studio..." -ForegroundColor Cyan
                    Start-Process -FilePath $devenvPath -ArgumentList "`"$fullPath`""
                }
            }
            else {
                # No solution files - open as folder
                Write-Host "No solution files found. Opening folder '$fullPath' in Visual Studio..." -ForegroundColor Cyan
                Start-Process -FilePath $devenvPath -ArgumentList "`"$fullPath`""
            }
        }
        else {
            # It's a file - open it directly
            Write-Host "Opening file '$fullPath' in Visual Studio..." -ForegroundColor Cyan
            Start-Process -FilePath $devenvPath -ArgumentList "`"$fullPath`""
        }

        Write-Host "Successfully opened in Visual Studio." -ForegroundColor Green

    }
    catch {
        Write-Error "An error occurred: $_"
    }
}

Set-Alias -Name vs -Value Open-VS

function Open-SSMS() {
    try {
        if (-not (Test-Path $ssmsPath)) {
            Write-Error "SQL Server Management Studio not found. Please ensure SSMS is installed."
            return
        }

        Start-Process -FilePath $ssmsPath -ArgumentList "`"$ssmsSlnxPath`""
        Write-Host "Successfully opened SQL Server Management Studio." -ForegroundColor Green
    }
    catch {
        Write-Error "An error occurred: $_"
    }       
}

Set-Alias -Name sql -Value Open-SSMS

function Git-Clean() {
    try {
        # Check if we're in a git repository
        $isGitRepo = git rev-parse --is-inside-work-tree 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Not a git repository."
            return
        }

        # Get current branch
        $currentBranch = git branch --show-current
        Write-Host "Current branch: $currentBranch" -ForegroundColor Cyan

        # Switch to main branch
        $MainBranch = "master"
        Write-Host "Switching to $MainBranch..." -ForegroundColor Yellow
        git checkout $MainBranch
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to switch to $MainBranch."
            return
        }

        # Pull latest changes
        Write-Host "Pulling latest changes..." -ForegroundColor Yellow
        git pull
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to pull changes."
            return
        }

        # Delete the local merged branch
        Write-Host "Deleting local branch '$currentBranch'..." -ForegroundColor Yellow
        git branch -D $currentBranch
    
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Branch '$currentBranch' deleted successfully." -ForegroundColor Green
        }
        else {
            Write-Error "Failed to delete branch. The branch may not be fully merged. Use 'git branch -D $currentBranch' to force delete."
        }

    }
    catch {
        Write-Error "An error occurred: $_"
    }
}

Set-Alias -Name gitc -Value Git-Clean

function Git-Reset() {
    git reset --hard origin/master
}

Set-Alias -Name gitr -Value Git-Reset

function Get-PrettyListing {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromRemainingArguments)]
        [string]$Path = ".",
        
        [switch]$All
    )

    # Icon mappings
    $folderIcon = "📁"
    $fileIcons = @{
        # Programming
        '.ps1' = '📜'
        '.psm1' = '📜'
        '.psd1' = '📜'
        '.py' = '🐍'
        '.js' = '📜'
        '.ts' = '📘'
        '.cs' = '🔷'
        '.java' = '☕'
        '.cpp' = '⚙️'
        '.c' = '⚙️'
        '.go' = '🐹'
        '.rs' = '🦀'
        '.rb' = '💎'
        '.php' = '🐘'
        
        # Web
        '.html' = '🌐'
        '.htm' = '🌐'
        '.css' = '🎨'
        '.scss' = '🎨'
        '.json' = '📋'
        '.xml' = '📋'
        '.yaml' = '📋'
        '.yml' = '📋'
        
        # Documents
        '.txt' = '📄'
        '.md' = '📝'
        '.pdf' = '📕'
        '.doc' = '📘'
        '.docx' = '📘'
        '.xls' = '📗'
        '.xlsx' = '📗'
        '.ppt' = '📙'
        '.pptx' = '📙'
        
        # Images
        '.png' = '🖼️'
        '.jpg' = '🖼️'
        '.jpeg' = '🖼️'
        '.gif' = '🖼️'
        '.bmp' = '🖼️'
        '.svg' = '🖼️'
        '.ico' = '🖼️'
        
        # Archives
        '.zip' = '📦'
        '.rar' = '📦'
        '.7z' = '📦'
        '.tar' = '📦'
        '.gz' = '📦'
        
        # Executables
        '.exe' = '⚙️'
        '.msi' = '⚙️'
        '.dll' = '⚙️'
        '.bat' = '⚙️'
        '.cmd' = '⚙️'
        
        # Media
        '.mp3' = '🎵'
        '.wav' = '🎵'
        '.flac' = '🎵'
        '.mp4' = '🎬'
        '.avi' = '🎬'
        '.mkv' = '🎬'
        '.mov' = '🎬'
        
        # Git
        '.git' = '📂'
        '.gitignore' = '🚫'
        '.gitattributes' = '📋'
        
        # Config
        '.config' = '⚙️'
        '.ini' = '⚙️'
        '.cfg' = '⚙️'
        '.conf' = '⚙️'
        
        # Default
        'default' = '📄'
    }

    # Get items
    $items = if ($All) {
        Get-ChildItem -Path $Path -Force | Sort-Object -Property @{Expression = {$_.PSIsContainer}; Descending = $true}, Name
    } else {
        Get-ChildItem -Path $Path | Sort-Object -Property @{Expression = {$_.PSIsContainer}; Descending = $true}, Name
    }

    if ($items.Count -eq 0) {
        Write-Host "Empty directory" -ForegroundColor DarkGray
        return
    }

    # Header
    Write-Host ""
    Write-Host "  Name  " -ForegroundColor Cyan -NoNewline
    Write-Host (" " * 50) -NoNewline
    Write-Host "Size" -ForegroundColor Cyan -NoNewline
    Write-Host "        Modified" -ForegroundColor Cyan
    Write-Host "  ──────────────────────────────────────────────────────  ────────────  ────────────────────" -ForegroundColor DarkGray

    foreach ($item in $items) {
        # Get icon
        if ($item.PSIsContainer) {
            $icon = $folderIcon
            $color = "Blue"
        } else {
            $extension = $item.Extension.ToLower()
            $icon = if ($fileIcons.ContainsKey($extension)) { $fileIcons[$extension] } else { $fileIcons['default'] }
            
            # Color based on extension
            $color = switch ($extension) {
                {$_ -in '.ps1', '.psm1', '.psd1', '.bat', '.cmd'} { "Green" }
                {$_ -in '.exe', '.msi', '.dll'} { "Red" }
                {$_ -in '.zip', '.rar', '.7z', '.tar', '.gz'} { "Yellow" }
                {$_ -in '.txt', '.md', '.log'} { "Gray" }
                {$_ -in '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.svg'} { "Magenta" }
                default { "White" }
            }
        }

        # Format size
        $size = if ($item.PSIsContainer) {
            "<DIR>"
        } else {
            if ($item.Length -lt 1KB) {
                "$($item.Length) B"
            } elseif ($item.Length -lt 1MB) {
                "{0:N2} KB" -f ($item.Length / 1KB)
            } elseif ($item.Length -lt 1GB) {
                "{0:N2} MB" -f ($item.Length / 1MB)
            } else {
                "{0:N2} GB" -f ($item.Length / 1GB)
            }
        }

        # Format date
        $modifiedDate = $item.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")

        # Print row
        Write-Host "  $icon  " -NoNewline
        Write-Host $item.Name.PadRight(54) -ForegroundColor $color -NoNewline
        Write-Host $size.PadLeft(12) -ForegroundColor DarkGray -NoNewline
        Write-Host "  $modifiedDate" -ForegroundColor DarkGray
    }

    Write-Host ""
    
    # Summary
    $folderCount = ($items | Where-Object { $_.PSIsContainer }).Count
    $fileCount = ($items | Where-Object { -not $_.PSIsContainer }).Count
    $totalSize = ($items | Where-Object { -not $_.PSIsContainer } | Measure-Object -Property Length -Sum).Sum
    
    $sizeFormatted = if ($totalSize -lt 1KB) {
        "$totalSize B"
    } elseif ($totalSize -lt 1MB) {
        "{0:N2} KB" -f ($totalSize / 1KB)
    } elseif ($totalSize -lt 1GB) {
        "{0:N2} MB" -f ($totalSize / 1MB)
    } else {
        "{0:N2} GB" -f ($totalSize / 1GB)
    }
    
    Write-Host "  $folderCount folders, $fileCount files" -ForegroundColor DarkCyan -NoNewline
    Write-Host "  │  " -ForegroundColor DarkGray -NoNewline
    Write-Host "Total: $sizeFormatted" -ForegroundColor DarkCyan
    Write-Host ""
}

# Create aliases
Set-Alias -Name ll -Value Get-PrettyListing -Force
Set-Alias -Name la -Value Get-PrettyListing -Force
Set-Alias -Name l -Value Get-PrettyListing -Force

function Open-SLN() {
    # Search for solution files
    Write-Host "Searching for solution files..." -ForegroundColor Cyan

    if (-not (Test-Path $slnSearchPath)) {
        Write-Host "Path $slnSearchPath does not exist." -ForegroundColor Red
        return
    }

    $solutions = @(Get-ChildItem -Path $slnSearchPath -Include "*.sln", "*.slnx" -Recurse -Depth 2 -ErrorAction SilentlyContinue | 
        Select-Object -Property FullName, Name, @{Name='RelativePath';Expression={$_.FullName.Replace($slnSearchPath, '')}} |
        Sort-Object -Property Name)

    if ($solutions.Count -eq 0) {
        Write-Host "No solution files found in $slnSearchPath" -ForegroundColor Yellow
        return
    }

    # Simple menu-based selection
    $searchTerm = ""
    $selectedIndex = 0

    function Get-FilteredSolutions {
        param([string]$filter)
        
        if ([string]::IsNullOrWhiteSpace($filter)) {
            return $solutions
        }
        
        return $solutions | Where-Object { 
            $_.Name -like "*$filter*" -or 
            $_.RelativePath -like "*$filter*"
        }
    }

    function Show-Menu {
        param(
            [array]$items,
            [int]$selected,
            [string]$filter
        )
        
        Clear-Host
        Write-Host "======================================" -ForegroundColor Cyan
        Write-Host "  Visual Studio Solution Selector" -ForegroundColor Cyan
        Write-Host "======================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Search: $filter" -ForegroundColor Yellow
        Write-Host ""
        
        if ($items.Count -eq 0) {
            Write-Host "No solutions found matching '$filter'" -ForegroundColor Red
            Write-Host ""
        } else {
            $maxDisplay = [Math]::Min(20, $items.Count)
            
            for ($i = 0; $i -lt $maxDisplay; $i++) {
                if ($i -eq $selected) {
                    Write-Host "  > " -NoNewline -ForegroundColor Green
                    Write-Host "$($items[$i].Name)" -ForegroundColor White
                    Write-Host "    $($items[$i].RelativePath)" -ForegroundColor DarkGray
                } else {
                    Write-Host "    $($items[$i].Name)" -ForegroundColor Gray
                }
            }
            
            if ($items.Count -gt $maxDisplay) {
                Write-Host ""
                Write-Host "  ... and $($items.Count - $maxDisplay) more" -ForegroundColor DarkGray
            }
        }
        
        Write-Host ""
        Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "Type to filter | Up/Down: Navigate | Enter: Open | Esc: Exit" -ForegroundColor DarkGray
    }

    $filteredSolutions = Get-FilteredSolutions -filter $searchTerm
    Show-Menu -items $filteredSolutions -selected $selectedIndex -filter $searchTerm

    while ($true) {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            
            switch ($key.Key) {
                'UpArrow' {
                    if ($selectedIndex -gt 0) {
                        $selectedIndex--
                    }
                    Show-Menu -items $filteredSolutions -selected $selectedIndex -filter $searchTerm
                }
                'DownArrow' {
                    if ($filteredSolutions.Count -gt 0 -and $selectedIndex -lt ($filteredSolutions.Count - 1)) {
                        $selectedIndex++
                    }
                    Show-Menu -items $filteredSolutions -selected $selectedIndex -filter $searchTerm
                }
                'Enter' {
                    if ($filteredSolutions.Count -gt 0) {
                        $selectedSolution = $filteredSolutions[$selectedIndex]
                        Write-Host ""
                        Write-Host "Opening $($selectedSolution.Name) in Visual Studio..." -ForegroundColor Green
                        Open-VS -Path $selectedSolution.FullName
                        return
                    }
                }
                'Escape' {
                    Write-Host ""
                    Write-Host "Cancelled" -ForegroundColor Yellow
                    return
                }
                'Backspace' {
                    if ($searchTerm.Length -gt 0) {
                        $searchTerm = $searchTerm.Substring(0, $searchTerm.Length - 1)
                        $selectedIndex = 0
                        $filteredSolutions = Get-FilteredSolutions -filter $searchTerm
                        Show-Menu -items $filteredSolutions -selected $selectedIndex -filter $searchTerm
                    }
                }
                default {
                    if ($key.KeyChar -match '[a-zA-Z0-9\-_.\\ ]') {
                        $searchTerm += $key.KeyChar
                        $selectedIndex = 0
                        $filteredSolutions = Get-FilteredSolutions -filter $searchTerm
                        Show-Menu -items $filteredSolutions -selected $selectedIndex -filter $searchTerm
                    }
                }
            }
        }
        
        Start-Sleep -Milliseconds 50
    }
}

Set-Alias -Name sln -Value Open-SLN
Set-Alias -Name repo -Value Open-SLN
