New-Alias g goto

oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/powerlevel10k_rainbow.omp.json" | Invoke-Expression

$env:Path += ";C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools\x64"
$env:Path += ";C:\dev\cmdtools"

# Proxy settings
[System.Net.WebRequest]::DefaultWebProxy = [System.Net.WebRequest]::GetSystemWebProxy()
[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials

Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete

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
