# Define the path to the file that stores the last execution time
$timeFilePath = [Environment]::GetFolderPath("MyDocuments") + "\PowerShell\LastExecutionTime.txt"

# Define the update interval in days, set to -1 to always check
$updateInterval = -1

# Initial GitHub.com connectivity check with 1 second timeout
#$global:canConnectToGitHub = Test-Connection github.com -Count 1 -Quiet -TimeoutSeconds 1

# Check for Personal Profile Updates
function Update-PersonalProfile {
    try {
        $url = "https://raw.githubusercontent.com/ehause0613/personalpwsh/main/profile.ps1"
        $oldhash = Get-FileHash $HOME/Documents/PowerShell/profile.ps1 # C:\Users\<username>\Documents\PowerShell\profile.ps1
        Invoke-RestMethod $url -OutFile "$env:temp/profile.ps1"
        $newhash = Get-FileHash "$env:temp/profile.ps1"
        if ($newhash.Hash -ne $oldhash.Hash) {
            Copy-Item -Path "$env:temp/profile.ps1" -Destination $HOME/Documents/PowerShell/profile.ps1 -Force
            Write-Host "Personal Profile Updated. Restart To Reflect Changes" -ForegroundColor Magenta
        }
        else {
            Write-Host "Personal Profile Up To Date." -ForegroundColor Green
        }
    }
    catch {
        Write-Error "Unable to check for `$profile updates: $_"
    }
    finally {
        Remove-Item "$env:temp/profile.ps1" -ErrorAction SilentlyContinue
    }
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
############                                         System Info / Diagnostics                                       ############
############                                                                                                         ############
#################################################################################################################################

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

# Ping a specified IP to confirm reachability
function PingIP {
    try {
        $target = Read-Host "Enter IP Address To Ping:"
        Test-Connection $target -Count 4 -ErrorAction Stop
    }
    catch {
        Write-Host "⚠ Error in line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Flush DNS cache
function FlushDNS { Clear-DnsClientCache; Write-Host "DNS cache cleared!" -ForegroundColor Green }

# Quick port check
function TestPort {
    try {
        $target = Read-Host "Enter Hostname Or IP:"
        $port = Read-Host "Enter Port:"
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
        $IPaddress = Read-Host "Enter IPv4/IPv6 Address Or Domain To Locate:"

        $result = Invoke-RestMethod -Method Get -Uri "http://ip-api.com/json/$IPaddress"
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
        $MACaddress = Read-Host "Enter MAC Address To Lookup:"

        $result = Invoke-RestMethod -Method Get -Uri "https://api.macvendors.com/$MACaddress"
        Write-Output $result
    }
    catch {
        Write-Host "⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Speedtest (Must have Ookla Speedtest CLI Installed)
function SPEED { 
    try {SPEEDTEST }
    catch {Write-Host "⚠️ Install/Configure Ookla Speedtest CLI !" -ForegroundColor Red
        exit 1
        }
}

#################################################################################################################################
############                                                                                                         ############
############                                            Process Management                                           ############
############                                                                                                         ############
#################################################################################################################################

# Kill a process by name
function KillProc($name) {
    try {
        Get-Process $name -ErrorAction Stop | Stop-Process -Force
    }
    catch {
        Write-Host "⚠ Error in line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Watch a process's resource usage live
function WatchProc($name) {
    while ($true) {
        Clear-Host
        Get-Process $name -ErrorAction SilentlyContinue | Select-Object Name, CPU, WorkingSet, Id
        Start-Sleep -Seconds 2
    }
}


#################################################################################################################################
############                                                                                                         ############
############                                         VPN / Connectivity                                              ############
############                                                                                                         ############
#################################################################################################################################

# Quick check: am I on the VPN right now?
function VPNStatus {
    try {
        Get-NetAdapter | Where-Object { $_.InterfaceDescription -like "*WireGuard*" } |
            Select-Object Name, Status, LinkSpeed
    }
    catch {
        Write-Host "⚠ Error in line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Ping your gateway/router to confirm home network reachability
function PingHome {
    try {
        Test-Connection 10.0.1.1 -Count 4 -ErrorAction Stop
    }
    catch {
        Write-Host "⚠ Error in line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}


#################################################################################################################################
############                                                                                                         ############
############                                          Clipboard & Misc Utilities                                     ############
############                                                                                                         ############
#################################################################################################################################

# Generate a random password
function NewPassword($length = 30) {
    -join ((48..57) + (65..90) + (97..122) | Get-Random -Count $length | ForEach-Object { [char]$_ })
}

# Quick file hash
function Hash($path) {
    try {
        (Get-FileHash $path -Algorithm SHA256 -ErrorAction Stop).Hash
    }
    catch {
        Write-Host "⚠ Error in line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Clear Windows temp files
function ClearTemp {
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Temp Files Cleared !" -ForegroundColor Green
}

# Empty recycle bin
function EmptyBin {
    Clear-RecycleBin -Confirm:$false
    Write-Host "Recycle Bin Emptied !" -ForegroundColor Green
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

# Quick "go up N directories"
function up($n = 1) { for ($i = 0; $i -lt $n; $i++) { Set-Location .. } }

# Copy current directory path to clipboard
function cpwd { (Get-Location).Path | Set-Clipboard }


#################################################################################################################################
############                                                                                                         ############
############                                               Profile Management                                        ############
############                                                                                                         ############
#################################################################################################################################

# List all custom functions currently loaded from this profile
function MyFunctions { Get-Command -CommandType Function | Where-Object { $_.Source -eq '' } | Select-Object Name }


#################################################################################################################################
############                                                                                                         ############
############                                                WinGet Functions                                         ############
############                                                                                                         ############
#################################################################################################################################

# WinGet App Updates
function WGA { winget upgrade --all --accept-package-agreements --accept-source-agreements --silent --force }

# WinGet App Updates List
function WGL { winget upgrade }

# WinGet App Updates Including Unknown
function WGUN { winget upgrade --all --accept-package-agreements --accept-source-agreements --silent --force --include-unknown }

