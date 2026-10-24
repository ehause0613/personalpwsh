# Define The Path To The File That Stores The Last Execution Time
$timeFilePath = [Environment]::GetFolderPath("MyDocuments") + "\PowerShell\LastExecutionTime.txt"

# Define The Update Interval In Days, Set To -1 To Always Check
$updateInterval = -1

# Initial GitHub.com Connectivity Check With 1 Second Timeout
#$global:canConnectToGitHub = Test-Connection github.com -Count 1 -Quiet -TimeoutSeconds 1

# Check For Personal Profile Updates
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

# Checks Weather At Your Location
function Wx { (Invoke-WebRequest https://wttr.in).Content }

#################################################################################################################################
############                                                                                                         ############
############                                             Time Functions                                              ############
############                                                                                                         ############
#################################################################################################################################

# Checks Time At Pre-Defined Loacations
function Time {
    Invoke-RestMethod -Uri "https://timeapi.io/api/Time/current/zone?timeZone=America/New_York"
    Invoke-RestMethod -Uri "https://timeapi.io/api/Time/current/zone?timeZone=Europe/Dublin"
}

#################################################################################################################################
############                                                                                                         ############
############                                         System Info / Diagnostics                                       ############
############                                                                                                         ############
#################################################################################################################################

# Top Processes By CPU
function TopCPU { Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 }

# Top Processes By RAM
function TopRAM { Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10 }

# Disk Space Summary
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

# Ping A Specified IP To Confirm Reachability
function PingIP {
    try {
        $target = Read-Host "Enter IP Address To Ping"
        Test-Connection $target -Count 4 -ErrorAction Stop
    }
    catch {
        Write-Host "⚠ Error in line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Flush DNS Cache
function FlushDNS { Clear-DnsClientCache; Write-Host "DNS cache cleared!" -ForegroundColor Green }

# Quick Port Check
function TestPort {
    try {
        $target = Read-Host "Enter Hostname Or IP"
        $port = Read-Host "Enter Port"
        Test-NetConnection -ComputerName $target -Port $port
    }
    catch {
        Write-Host "⚠ Error in line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Show Active Listening Ports
function Ports { Get-NetTCPConnection -State Listen | Select-Object LocalAddress, LocalPort, OwningProcess }

# What Is My Public IP
function PubIP { (Invoke-WebRequest https://ifconfig.me/ip).Content }

function NetIP {Get-NetIPConfiguration}

# Find Info On A Public IP
function IPInfo {
    try {
        $IPaddress = Read-Host "Enter IPv4/IPv6 Address Or Domain To Locate"

        $result = Invoke-RestMethod -Method Get -Uri "http://ip-api.com/json/$IPaddress"
        Write-Output $result
    }
    catch {
        Write-Host "⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Find Info On A MAC Address
function MAC {
    try {
        $MACaddress = Read-Host "Enter MAC Address To Lookup"

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

# Kill A Process By Name
function KillProc($name) {
    try {
        Get-Process $name -ErrorAction Stop | Stop-Process -Force
    }
    catch {
        Write-Host "⚠ Error in line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Watch A Process's Resource Usage Live
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

# Quick Check: Am I On A VPN Right Now?
function VPNStatus {
    param(
        [string[]]$Pattern = @('WireGuard', 'NordLynx', 'NordVPN', 'Tailscale', 'OpenVPN', 'TAP-Windows', 'AnyConnect', 'Fortinet')
    )

    try {
        # Escape each term so special characters are treated literally, then join with |
        $regex = ($Pattern | ForEach-Object { [regex]::Escape($_) }) -join '|'

        Get-NetAdapter |
            Where-Object { $_.InterfaceDescription -match $regex -or $_.Name -match $regex } |
            Select-Object Name, InterfaceDescription, Status, LinkSpeed
    }
    catch {
        Write-Host "⚠ Error in line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        return
    }
}

# Ping Your Gateway/Router To Confirm Network Reachability
function PingHome {
    param(
        [string]$Gateway
    )

    try {
        # Auto-detect if no gateway was passed in
        if (-not $Gateway) {
            $Gateway = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue |
                Where-Object { $_.NextHop -ne '0.0.0.0' } |
                Sort-Object { $_.RouteMetric + (Get-NetIPInterface -InterfaceIndex $_.InterfaceIndex -AddressFamily IPv4).InterfaceMetric } |
                Select-Object -First 1 -ExpandProperty NextHop
        }

        # Prompt if detection failed
        if (-not $Gateway) {
            do {
                $answer = Read-Host "Could not detect a gateway. Enter its IP address"
                $ip = $null
                $valid = [ipaddress]::TryParse($answer, [ref]$ip)
                if (-not $valid) { Write-Host "That is not a valid IP address." -ForegroundColor Yellow }
            } until ($valid)
            $Gateway = $answer
        }

        Write-Host "Pinging gateway $Gateway..." -ForegroundColor Cyan
        Test-Connection $Gateway -Count 4 -ErrorAction Stop
    }
    catch {
        Write-Host "⚠ Error in line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        return
    }
}


#################################################################################################################################
############                                                                                                         ############
############                                          Clipboard & Misc Utilities                                     ############
############                                                                                                         ############
#################################################################################################################################

# Generate A Random Password
function NewPassword {
    param(
        [int]$Length,
        [switch]$NoSpecial
    )

    # Prompt only if no length was passed in
    if (-not $PSBoundParameters.ContainsKey('Length')) {
        do {
            $answer = Read-Host "Password length (8-256, Enter for 30)"
            if ([string]::IsNullOrWhiteSpace($answer)) { $answer = '30' }
            $valid = [int]::TryParse($answer, [ref]$Length) -and $Length -ge 8 -and $Length -le 256
            if (-not $valid) { Write-Host "Enter a whole number between 8 and 256." -ForegroundColor Yellow }
        } until ($valid)
    }

    $digits  = '0123456789'
    $upper   = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    $lower   = 'abcdefghijklmnopqrstuvwxyz'
    $special = '!@#$%^&*()-_=+[]{};:,.?'

    $sets = @($digits, $upper, $lower)
    if (-not $NoSpecial) { $sets += $special }
    $chars = [char[]]($sets -join '')

    # Largest multiple of the set size that fits in a byte; values above it are discarded to avoid modulo bias
    $limit = 256 - (256 % $chars.Count)

    $rng  = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $byte = New-Object byte[] 1

    try {
        do {
            $sb = [System.Text.StringBuilder]::new()
            while ($sb.Length -lt $Length) {
                $rng.GetBytes($byte)
                if ($byte[0] -lt $limit) { [void]$sb.Append($chars[$byte[0] % $chars.Count]) }
            }
            $password = $sb.ToString()

            # Regenerate until every character set is represented at least once
            $hasAll = $true
            foreach ($set in $sets) {
                if ($password.IndexOfAny([char[]]$set) -lt 0) { $hasAll = $false; break }
            }
        } until ($hasAll)
    }
    finally {
        $rng.Dispose()
    }

    $password
}

# Quick File Hash
function Hash($path) {
    try {
        (Get-FileHash $path -Algorithm SHA256 -ErrorAction Stop).Hash
    }
    catch {
        Write-Host "⚠ Error in line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Clear Windows Temp Files
function ClearTemp {
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Temp Files Cleared !" -ForegroundColor Green
}

# Empty Recycle Bin
function EmptyBin {
    Clear-RecycleBin -Confirm:$false
    Write-Host "Recycle Bin Emptied !" -ForegroundColor Green
}

#################################################################################################################################
############                                                                                                         ############
############                                         Navigation & Filesystem                                         ############
############                                                                                                         ############
#################################################################################################################################

# Quick Jump To Common Folders
function proj { Set-Location "C:\Users\$env:USERNAME\Projects" }

function dc { Set-Location "$HOME\Documents" }

function dl { Set-Location "$HOME\Downloads" }

# ls With More Detail, sorted by last modified
function lt { Get-ChildItem | Sort-Object LastWriteTime -Descending }

# Quick "Go Up N Directories"
function up($n = 1) { for ($i = 0; $i -lt $n; $i++) { Set-Location .. } }

# Copy Current Directory Path To Clipboard
function cpwd { (Get-Location).Path | Set-Clipboard }


#################################################################################################################################
############                                                                                                         ############
############                                               Profile Management                                        ############
############                                                                                                         ############
#################################################################################################################################

# List All Custom Functions Currently Loaded From This Profile
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

