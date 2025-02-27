$env:Path += ";C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools\x64"
$env:Path += ";C:\dev\cmdtools"

# Proxy settings
[System.Net.WebRequest]::DefaultWebProxy = [System.Net.WebRequest]::GetSystemWebProxy()
[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials

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

#Install-Module -Name Terminal-Icons -Repository PSGallery
Import-Module -Name Terminal-Icons

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
    Write-host ($(if ($IsAdmin) { ' Elevated ' } else { '' })) -BackgroundColor DarkRed -ForegroundColor White -NoNewline
    Write-Host " $($env:USERNAME)@$($env:COMPUTERNAME) " -BackgroundColor DarkCyan -ForegroundColor Black -NoNewline

    If ($IsHome) { Write-Host "  Home "  -ForegroundColor White -BackgroundColor DarkGray -NoNewline }
    ElseIf ($CmdPromptCurrentFolder -like "*:*") { Write-Host " $CmdPromptCurrentFolder "  -ForegroundColor White -BackgroundColor DarkGray -NoNewline }
    Else { Write-Host " .\$CmdPromptCurrentFolder\ "  -ForegroundColor White -BackgroundColor DarkGray -NoNewline }

    Write-Host "" -NoNewline

    if ($inGitRepo) {
        $gitBranch = git rev-parse --abbrev-ref HEAD
        Write-Host "  $($gitBranch) " -BackgroundColor Yellow -ForegroundColor Black -NoNewline
    }

    Write-Host " $elapsedTime " -BackgroundColor Green -ForegroundColor Black -NoNewline
    Write-Host ""
    
    If ($CmdWasSuccessfull) {
        Write-Host "=>" -ForegroundColor Green -NoNewline
    }
    else {
        Write-Host "X" -ForegroundColor Red -NoNewline
    }
    return " "
}

function goto {
    param (
        $location
    )

    Switch ($location) {
        "repos" {
            Set-Location -Path "C:\dev\Repos"
        }
        "r" {
            Set-Location -Path "C:\dev\Repos"
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

function ll { 
    Get-ChildItem -Path $pwd -File 
}

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
