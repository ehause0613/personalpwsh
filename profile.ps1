$debug = $false

# Define the path to the file that stores the last execution time
$timeFilePath = [Environment]::GetFolderPath("MyDocuments") + "\PowerShell\LastExecutionTime.txt"

# Define the update interval in days, set to -1 to always check
$updateInterval = 1

if ($debug) {
    Write-Host "#######################################" -ForegroundColor Red
    Write-Host "#           Debug mode enabled        #" -ForegroundColor Red
    Write-Host "#          ONLY FOR DEVELOPMENT       #" -ForegroundColor Red
    Write-Host "#                                     #" -ForegroundColor Red
    Write-Host "#       IF YOU ARE NOT DEVELOPING     #" -ForegroundColor Red
    Write-Host "#      JUST RUN \`Update-Profile\`    #" -ForegroundColor Red
    Write-Host "#        to discard all changes       #" -ForegroundColor Red
    Write-Host "#   and update to the latest profile  #" -ForegroundColor Red
    Write-Host "#               version               #" -ForegroundColor Red
    Write-Host "#######################################" -ForegroundColor Red
}

#################################################################################################################################
############                                                                                                         ############
############                                          !!!   WARNING:   !!!                                           ############
############                                                                                                         ############
############                DO NOT MODIFY THIS FILE. THIS FILE IS HASHED AND UPDATED AUTOMATICALLY.                  ############
############                    ANY CHANGES MADE TO THIS FILE WILL BE OVERWRITTEN BY COMMITS TO                      ############
############                             https://github.com/ehause0613/personalpwsh.git.                             ############
############                                                                                                         ############
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#
############                                                                                                         ############
############                      IF YOU WANT TO MAKE CHANGES, USE THE Edit-Profile FUNCTION                         ############
############                              AND SAVE YOUR CHANGES IN THE FILE CREATED.                                 ############
############                                                                                                         ############
#################################################################################################################################

# Initial GitHub.com connectivity check with 1 second timeout
$global:canConnectToGitHub = Test-Connection github.com -Count 1 -Quiet -TimeoutSeconds 1

# Check for Personal Profile Updates
function Update-Profile {
    try {
        $url = "https://raw.githubusercontent.com/ehause0613/personalpwsh/main/profile.ps1"
        $oldhash = Get-FileHash $HOME/Documents/PowerShell/profile.ps1 # C:\Users\<username>\Documents\PowerShell\profile.ps1
        Invoke-RestMethod $url -OutFile "$env:temp/profile.ps1"
        $newhash = Get-FileHash "$env:temp/profile.ps1"
        if ($newhash.Hash -ne $oldhash.Hash) {
            Copy-Item -Path "$env:temp/profile.ps1" -Destination $HOME/Documents/PowerShell/profile.ps1 -Force
            Write-Host "Personal Profile has been updated. Please restart to reflect changes" -ForegroundColor Magenta
        }
        else {
            Write-Host "Personal Profile is up to date." -ForegroundColor Green
        }
    }
    catch {
        Write-Error "Unable to check for `$profile updates: $_"
    }
    finally {
        Remove-Item "$env:temp/profile.ps1" -ErrorAction SilentlyContinue
    }
}

# Check if not in debug mode AND (updateInterval is -1 OR file doesn't exist OR time difference is greater than the update interval)
if (-not $debug -and `
    ($updateInterval -eq -1 -or `
            -not (Test-Path $timeFilePath) -or `
        ((Get-Date) - [datetime]::ParseExact((Get-Content -Path $timeFilePath), 'yyyy-MM-dd', $null)).TotalDays -gt $updateInterval)) {

    Update-Profile
    $currentTime = Get-Date -Format 'yyyy-MM-dd'
    $currentTime | Out-File -FilePath $timeFilePath

}
elseif ($debug) {
    Write-Warning "Skipping profile check in debug mode"
}

# Weather
function Wx { (Invoke-WebRequest https://wttr.in).Content }

# Network Utilities
function PubIP { (Invoke-WebRequest https://ifconfig.me/ip).Content }

function NetIP {Get-NetIPConfiguration}

function IPInfo {
    try {
        $IPaddress = Read-Host "Enter IP address to locate"

        $result = Invoke-RestMethod -Method Get -Uri "https://ip-api.com/json/$IPaddress"
        Write-Output $result
    }
    catch {
        Write-Host "⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# WinGet App Updates
function WG { winget upgrade --all --accept-package-agreements --accept-source-agreements --silent --force --include-unknown}

# Time
function Time { (Invoke-RestMethod -Uri "https://worldtimeapi.org/api/timezone/America/New_York") }

