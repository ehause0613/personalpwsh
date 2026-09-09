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
function Update-PersonalProfile {
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

    Update-PersonalProfile
    $currentTime = Get-Date -Format 'yyyy-MM-dd'
    $currentTime | Out-File -FilePath $timeFilePath

}
elseif ($debug) {
    Write-Warning "Skipping profile check in debug mode"
}

# Enable My Choice of Oh My Posh Theme
function Get-Theme_Override
{
    oh-my-posh init pwsh --config https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/agnosterplus.omp.json | Invoke-Expression
}

#################################################################################################################################
############                                                                                                         ############
############                                           Weather Functions                                             ############
############                                                                                                         ############
#################################################################################################################################

function Wx { (Invoke-WebRequest https://wttr.in).Content }

#################################################################################################################################
############                                                                                                         ############
############                                             Time Functions                                              ############
############                                                                                                         ############
#################################################################################################################################


function Time {
    Invoke-RestMethod -Uri "https://timeapi.io/api/Time/current/zone?timeZone=America/New_York"
    Invoke-RestMethod -Uri "https://timeapi.io/api/Time/current/zone?timeZone=Europe/Dublin"
}


#################################################################################################################################
############                                                                                                         ############
############                                         Navigation & Filesystem                                         ############
############                                                                                                         ############
#################################################################################################################################

# Quick jump to common folders
function proj { Set-Location "C:\Users\$env:USERNAME\Projects" }
function dl { Set-Location "$HOME\Downloads" }

# ls with more detail, sorted by last modified
function lt { Get-ChildItem | Sort-Object LastWriteTime -Descending }

# Find files by name recursively
function ff($name) { Get-ChildItem -Recurse -Filter "*$name*" -ErrorAction SilentlyContinue }

# Quick "go up N directories"
function up($n = 1) { for ($i = 0; $i -lt $n; $i++) { Set-Location .. } }

# Copy current directory path to clipboard
function cpwd { (Get-Location).Path | Set-Clipboard }


#################################################################################################################################
############                                                                                                         ############
############                                         System Info / Diagnostics                                       ############
############                                                                                                         ############
#################################################################################################################################

# Quick uptime
function Uptime { (Get-CimInstance Win32_OperatingSystem).LastBootUpTime }

# Top processes by CPU
function TopCPU { Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 }

# Top processes by RAM
function TopRAM { Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10 }

# Disk space summary
function Disk {
    try {
        Get-PSDrive -PSProvider FileSystem | Select-Object Name,
            @{N='UsedGB'; E={[math]::Round($_.Used/1GB,2)}},
            @{N='FreeGB'; E={[math]::Round($_.Free/1GB,2)}}
    }
    catch {
        Write-Host "⚠ Error in line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

#################################################################################################################################
############                                                                                                         ############
############                                            Network Functions                                            ############
############                                                                                                         ############
#################################################################################################################################

# Flush DNS cache
function FlushDNS { Clear-DnsClientCache; Write-Host "DNS cache cleared" -ForegroundColor Green }

# Quick port check
function TestPort {
    try {
        $target = Read-Host "Enter hostname or IP"
        $port = Read-Host "Enter port"
        Test-NetConnection -ComputerName $target -Port $port
    }
    catch {
        Write-Host "⚠ Error in line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Show active listening ports
function Ports { Get-NetTCPConnection -State Listen | Select-Object LocalAddress, LocalPort, OwningProcess }

# What is My Public IP
function PubIP { (Invoke-WebRequest https://ifconfig.me/ip).Content }

function NetIP {Get-NetIPConfiguration}

# Find Info On a Public IP
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

# Find Info On A MAC ADDRESS
function MAC {
    try {
        $MACaddress = Read-Host "Enter MAC address to lookup"

        $result = Invoke-RestMethod -Method Get -Uri "https://api.macvendors.com/$MACaddress"
        Write-Output $result
    }
    catch {
        Write-Host "⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

#################################################################################################################################
############                                                                                                         ############
############                                                WinGet Functions                                         ############
############                                                                                                         ############
#################################################################################################################################

# WinGet App Updates List
function WGL { winget upgrade }

# WinGet App Updates
function WGA { winget upgrade --all --accept-package-agreements --accept-source-agreements --silent --force }

# WinGet App Updates Including Unknown
function WGUN { winget upgrade --all --accept-package-agreements --accept-source-agreements --silent --force --include-unknown }

# Sppedtest (Must have Ookla Speedtest CLI Installed
function SPEED { SPEEDTEST }

# Restore Windows Health - DISM
function dism { DISM /ONLINE /CLEANUP-IMAGE /RESTOREHEALTH }


