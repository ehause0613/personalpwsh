# CHECK FOR PERSONAL PROFILE UPDATES
function Update-PersonalProfile {
    $url      = "https://raw.githubusercontent.com/ehause0613/personalpwsh/main/profile.ps1"
    $target   = "$HOME/Documents/PowerShell/profile.ps1"   # C:\Users\<username>\Documents\PowerShell\profile.ps1
    $tempFile = "$env:TEMP/profile.ps1"

    try {
        # 5-second cap so an offline or slow network doesn't stall shell startup
        Invoke-RestMethod -Uri $url -OutFile $tempFile -TimeoutSec 5 -ErrorAction Stop

        # Refuse to install a downloaded profile that has syntax errors
        $tokens = $null; $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile($tempFile, [ref]$tokens, [ref]$errors)
        if ($errors.Count -gt 0) {
            Write-Host "⚠ GitHub Profile Has A Syntax Error (Line $($errors[0].Extent.StartLineNumber): $($errors[0].Message)). Keeping Current Version." -ForegroundColor Yellow
            return
        }

        # A missing local profile counts as out of date (first run on a new machine)
        $oldHash = if (Test-Path $target) { (Get-FileHash $target).Hash } else { $null }
        $newHash = (Get-FileHash $tempFile).Hash

        if ($newHash -ne $oldHash) {
            Copy-Item -Path $tempFile -Destination $target -Force
            Write-Host "Personal Profile Updated. Restart To Reflect Changes!" -ForegroundColor Magenta
        }
        #else {
        #    Write-Host "Personal Profile Up To Date." -ForegroundColor Green
        #}
    }
    catch {
        Write-Host "⚠ Personal Profile Update Check Skipped: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    finally {
        Remove-Item $tempFile -ErrorAction SilentlyContinue
    }
}

# ENABLE MY CHOICE OF OH MY POSH THEME
function Get-Theme_Override {
    $themeUrl  = 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/agnosterplus.omp.json'
    $themeFile = "$HOME/Documents/PowerShell/agnosterplus.omp.json"

    if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
        Write-Host "⚠ Oh-My-Posh Is Not Installed. Using The Default Prompt." -ForegroundColor Yellow
        return
    }

    # Refresh the local copy at most once a week; 5-second cap on the download
    $stale = -not (Test-Path $themeFile) -or
             ((Get-Date) - (Get-Item $themeFile).LastWriteTime).TotalDays -ge 7

    if ($stale) {
        try {
            Invoke-RestMethod -Uri $themeUrl -OutFile "$themeFile.tmp" -TimeoutSec 5 -ErrorAction Stop
            Move-Item -Path "$themeFile.tmp" -Destination $themeFile -Force
        }
        catch {
            Remove-Item "$themeFile.tmp" -ErrorAction SilentlyContinue
            if (-not (Test-Path $themeFile)) {
                Write-Host "⚠ Could Not Download The Oh My Posh Theme. Using The Default Prompt." -ForegroundColor Yellow
                return
            }
            # Download failed but a cached copy exists, so keep using it
        }
    }

    oh-my-posh init pwsh --config $themeFile | Invoke-Expression
}


#################################################################################################################################
############                                                                                                         ############
############                                           WEATHER FUNCTIONS                                             ############
############                                                                                                         ############
#################################################################################################################################

# CHECKS WEATHER AT YOUR LOCATION (OR A NAMED ONE)
function Wx {
    param(
        [string]$Location = '',
        [switch]$Short
    )

    try {
        # ?u = US units (Fahrenheit, mph); format=3 = one-line summary
        $query = if ($Short) { '?u&format=3' } else { '?u' }
        $uri   = "https://wttr.in/$([uri]::EscapeDataString($Location.Trim()))$query"
        Invoke-RestMethod -Uri $uri -TimeoutSec 10 -ErrorAction Stop
    }
    catch {
        Write-Host "⚠ Error In Line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        return
    }
}


#################################################################################################################################
############                                                                                                         ############
############                                             TIME FUNCTIONS                                              ############
############                                                                                                         ############
#################################################################################################################################

# CHECKS TIME AT PRE-DEFINED LOCATIONS
function Time {
    param(
        [string[]]$Zones = @('America/New_York', 'Europe/Dublin')
    )

    $utc = [DateTime]::UtcNow

    foreach ($zone in $Zones) {
        try {
            $tz     = [TimeZoneInfo]::FindSystemTimeZoneById($zone)
            $local  = [TimeZoneInfo]::ConvertTimeFromUtc($utc, $tz)
            $offset = $tz.GetUtcOffset($utc)
            $sign   = if ($offset -lt [TimeSpan]::Zero) { '-' } else { '+' }

            [pscustomobject]@{
                Zone      = $zone
                Time      = $local.ToString('yyyy-MM-dd HH:mm:ss')
                Day       = $local.DayOfWeek
                UtcOffset = '{0}{1:hh\:mm}' -f $sign, $offset
                DST       = $tz.IsDaylightSavingTime($local)
            }
        }
        catch {
            Write-Host "⚠ Unknown Time Zone: $zone" -ForegroundColor Yellow
        }
    }
}


#################################################################################################################################
############                                                                                                         ############
############                                         SYSTEM INFO / DIAGNOSTICS                                       ############
############                                                                                                         ############
#################################################################################################################################

# TOP PROCESSES BY CURRENT CPU USAGE
function TopCPU {
    param(
        [ValidateRange(1,100)][int]$Top = 10
    )

    try {
        $cores   = [Environment]::ProcessorCount
        $samples = (Get-Counter '\Process(*)\% Processor Time' -ErrorAction SilentlyContinue).CounterSamples

        if (-not $samples) { throw "Could Not Read Process CPU Counters." }

        # Counter value is per core (can exceed 100), so divide by logical processor count
        $samples |
            Where-Object { $_.InstanceName -notin '_total', 'idle' } |
            Sort-Object CookedValue -Descending |
            Select-Object -First $Top |
            Select-Object @{N='Process'; E={$_.InstanceName}},
                          @{N='CPU%';    E={[math]::Round($_.CookedValue / $cores, 1)}}
    }
    catch {
        Write-Host "⚠ Error In Line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        return
    }
}

# TOP PROCESSES BY RAM
function TopRAM {
    param(
        [ValidateRange(1,100)][int]$Top = 10
    )

    Get-Process |
        Sort-Object WorkingSet64 -Descending |
        Select-Object -First $Top Name, Id,
            @{N='MemoryMB'; E={[math]::Round($_.WorkingSet64/1MB,1)}}
}

# DISK SPACE SUMMARY
function Disk {
    try {
        Get-Volume -ErrorAction Stop |
            Where-Object { $_.DriveLetter -and $_.DriveType -in 'Fixed', 'Removable' -and $_.Size -gt 0 } |
            Sort-Object DriveLetter |
            Select-Object @{N='Drive';   E={"$($_.DriveLetter):"}},
                          @{N='Label';   E={$_.FileSystemLabel}},
                          @{N='TotalGB'; E={[math]::Round($_.Size/1GB,2)}},
                          @{N='UsedGB';  E={[math]::Round(($_.Size - $_.SizeRemaining)/1GB,2)}},
                          @{N='FreeGB';  E={[math]::Round($_.SizeRemaining/1GB,2)}},
                          @{N='Free%';   E={[math]::Round($_.SizeRemaining / $_.Size * 100,1)}}
    }
    catch {
        Write-Host "⚠ Error In Line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        return
    }
}


#################################################################################################################################
############                                                                                                         ############
############                                            NETWORK FUNCTIONS                                            ############
############                                                                                                         ############
#################################################################################################################################

# PING A SPECIFIED IP OR HOSTNAME TO CONFIRM REACHABILITY
function PingIP {
    param(
        [string]$Target,
        [ValidateRange(1,100)][int]$Count = 4
    )

    # Prompt if no target was passed in
    if (-not $Target) {
        do {
            $Target = (Read-Host "Enter IP Address Or Hostname To Ping").Trim()
            $valid  = [uri]::CheckHostName($Target) -ne 'Unknown'
            if (-not $valid) { Write-Host "That Is Not A Valid IP Address Or Hostname." -ForegroundColor Yellow }
        } until ($valid)
    }

    try {
        Test-Connection $Target -Count $Count -ErrorAction Stop
    }
    catch {
        Write-Host "⚠ Error In Line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        return
    }
}

<#
# FLUSH DNS CACHE
function FlushDNS {
    try {
        Clear-DnsClientCache -ErrorAction Stop
        Write-Host "DNS Cache Cleared!" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠ Error in line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  This Usually Requires Running PowerShell As Administrator." -ForegroundColor Yellow
        return
    }
}
#>

# QUICK PORT CHECK
function TestPort {
    param(
        [string]$Target,
        [int]$Port,
        [ValidateRange(1,60)][int]$TimeoutSeconds = 3
    )

    # Prompt if no target was passed in
    if (-not $Target) {
        do {
            $Target = (Read-Host "Enter Hostname Or IP").Trim()
            $valid  = [uri]::CheckHostName($Target) -ne 'Unknown'
            if (-not $valid) { Write-Host "That Is Not A Valid IP Address Or Hostname." -ForegroundColor Yellow }
        } until ($valid)
    }

    # Prompt if no port (or an invalid one) was passed in
    if ($Port -lt 1 -or $Port -gt 65535) {
        if ($PSBoundParameters.ContainsKey('Port')) { Write-Host "Port $Port Is Out Of Range." -ForegroundColor Yellow }
        do {
            $answer = Read-Host "Enter Port (1-65535)"
            $valid  = [int]::TryParse($answer, [ref]$Port) -and $Port -ge 1 -and $Port -le 65535
            if (-not $valid) { Write-Host "Enter A Whole Number Between 1 And 65535." -ForegroundColor Yellow }
        } until ($valid)
    }

    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $task = $client.ConnectAsync($Target, $Port)
        if ($task.Wait($TimeoutSeconds * 1000)) {
            $open   = $client.Connected
            $detail = 'Connected'
        }
        else {
            $open   = $false
            $detail = "Timed Out After $TimeoutSeconds s"
        }
    }
    catch {
        $open   = $false
        $detail = $_.Exception.GetBaseException().Message
    }
    finally {
        $client.Dispose()
    }

    [pscustomobject]@{
        Target = $Target
        Port   = $Port
        Open   = $open
        Detail = $detail
    }
}

# SHOW ACTIVE LISTENING PORTS WITH OWNING PROCESS NAMES
function Ports {
    param(
        [switch]$IncludeUdp
    )

    # PID -> process name lookup
    $names = @{}
    Get-Process | ForEach-Object { $names[$_.Id] = $_.ProcessName }

    $rows = @(Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
        Select-Object @{N='Protocol'; E={'TCP'}}, LocalAddress, LocalPort,
                      @{N='PID';      E={$_.OwningProcess}},
                      @{N='Process';  E={$names[[int]$_.OwningProcess]}})

    if ($IncludeUdp) {
        $rows += @(Get-NetUDPEndpoint -ErrorAction SilentlyContinue |
            Select-Object @{N='Protocol'; E={'UDP'}}, LocalAddress, LocalPort,
                          @{N='PID';      E={$_.OwningProcess}},
                          @{N='Process';  E={$names[[int]$_.OwningProcess]}})
    }

    $rows | Sort-Object Protocol, LocalPort, LocalAddress
}

<#
# WHAT IS MY PUBLIC IP
function PubIP {
    param(
        [switch]$IPv6
    )

    # Primary service first, fallback second
    $services = if ($IPv6) { @('https://api6.ipify.org', 'https://ipv6.icanhazip.com') }
                else       { @('https://api.ipify.org',  'https://ipv4.icanhazip.com') }

    foreach ($uri in $services) {
        try {
            $ip = "$(Invoke-RestMethod -Uri $uri -TimeoutSec 5 -ErrorAction Stop)".Trim()
            if ($ip) { return $ip }
        }
        catch {
            continue
        }
    }

    if ($IPv6) { Write-Host "⚠ Could Not Get A Public IPv6 address. This Network May Not Have IPv6." -ForegroundColor Yellow }
    else       { Write-Host "⚠ Could Not Reach Any Public IP Service." -ForegroundColor Yellow }
    return $null
}
#>

# SHOW IP CONFIGURATION (CONNECTED ADAPTERS ONLY UNLESS -All)
function NetIP {
    param(
        [switch]$All
    )

    $config = Get-NetIPConfiguration
    if (-not $All) { $config = $config | Where-Object { $_.NetAdapter.Status -eq 'Up' } }
    $config
}

# FIND INFO ON A PUBLIC IP
function IPInfo {
    param(
        [string]$Address
    )

    # Prompt if nothing was passed in; blank input looks up your own public IP
    if (-not $PSBoundParameters.ContainsKey('Address')) {
        $Address = Read-Host "Enter IPv4/IPv6 Address Or Domain To Locate (Enter For Your Own IP)"
    }

    try {
        # ip-api.com free tier is HTTP only, so this query is not encrypted
        $result = Invoke-RestMethod -Method Get -Uri "http://ip-api.com/json/$($Address.Trim())" -TimeoutSec 5 -ErrorAction Stop

        if ($result.status -ne 'success') {
            Write-Host "⚠ Lookup Failed: $($result.message)" -ForegroundColor Yellow
            return
        }

        $result
    }
    catch {
        Write-Host "⚠️ Error In Line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        return
    }
}

# FIND INFO ON A MAC ADDRESS
function MAC {
    param(
        [string]$Address
    )

    # Prompt if nothing was passed in; at least the first 6 hex digits (vendor prefix) are needed
    $hex = $Address -replace '[^0-9A-Fa-f]', ''
    while ($hex.Length -lt 6) {
        if ($Address) { Write-Host "Enter At Least The First 3 Segments / Bytes, e.g. 00:1A:2B." -ForegroundColor Yellow }
        $Address = Read-Host "Enter MAC Address To Look Up"
        $hex     = $Address -replace '[^0-9A-Fa-f]', ''
    }

    try {
        Invoke-RestMethod -Method Get -Uri "https://api.macvendors.com/$hex" -TimeoutSec 10 -ErrorAction Stop
    }
    catch {
        $status = [int]$_.Exception.Response.StatusCode

        if ($status -eq 404) {
            # Second bit of the first byte = locally administered (randomized/private) address
            if (([Convert]::ToInt32($hex.Substring(0,2), 16) -band 2) -ne 0) {
                Write-Host "No Vendor For $Address. It Is A Randomized (Locally Administered) MAC." -ForegroundColor Yellow
            }
            else {
                Write-Host "Vendor Not Found For $Address." -ForegroundColor Yellow
            }
        }
        elseif ($status -eq 429) {
            Write-Host "⚠ Rate Limited By macvendors.com (About 1 Request Per Second). Wait A Moment And Retry." -ForegroundColor Yellow
        }
        else {
            Write-Host "⚠️ Error In Line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        }
        return
    }
}

# SPEEDTEST (MUST HAVE OOKLA SPEEDTEST CLI INSTALLED)
function SPEED {
    if (-not (Get-Command speedtest -CommandType Application -ErrorAction SilentlyContinue)) {
        Write-Host "⚠️ Ookla Speedtest CLI Not Found. Install With: winget install Ookla.Speedtest.CLI" -ForegroundColor Red
        return
    }

    speedtest
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️ Speedtest Exited With Code $LASTEXITCODE." -ForegroundColor Red
    }
}


#################################################################################################################################
############                                                                                                         ############
############                                            PROCESS MANAGEMENT                                           ############
############                                                                                                         ############
#################################################################################################################################

# KILL A PROCESS BY NAME (SHOWS MATCHES AND CONFIRMS FIRST; -Force SKIPS, -WhatIf PREVIEWS)
function KillProc {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$Name,
        [switch]$Force
    )

    $Name  = $Name -replace '\.exe$', ''
    $procs = @(Get-Process -Name $Name -ErrorAction SilentlyContinue)

    if ($procs.Count -eq 0) {
        Write-Host "No Process Matching '$Name' Is Running." -ForegroundColor Yellow
        return
    }

    $procs |
        Select-Object Name, Id, @{N='MemoryMB'; E={[math]::Round($_.WorkingSet64/1MB,1)}} |
        Format-Table -AutoSize | Out-Host

    if (-not $Force -and -not $WhatIfPreference) {
        $answer = Read-Host "Kill $($procs.Count) Process(es)? (y/N)"
        if ($answer -notmatch '^(y|yes)$') {
            Write-Host "Cancelled." -ForegroundColor Yellow
            return
        }
    }

    $stopped = 0
    foreach ($p in $procs) {
        if ($PSCmdlet.ShouldProcess("$($p.Name) (PID $($p.Id))", 'Stop Process')) {
            try {
                Stop-Process -Id $p.Id -Force -ErrorAction Stop
                $stopped++
            }
            catch {
                Write-Host "⚠ Could Not Stop $($p.Name) (PID $($p.Id)): $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }

    if (-not $WhatIfPreference) {
        Write-Host "Stopped $stopped of $($procs.Count) Process(es)." -ForegroundColor Green
    }
}

# WATCH A PROCESS'S RESOURCE USAGE LIVE
function WatchProc {
    param(
        [Parameter(Mandatory)][string]$Name,
        [ValidateRange(1,60)][int]$Interval = 2
    )

    $Name  = $Name -replace '\.exe$', ''
    $cores = [Environment]::ProcessorCount
    $prev  = @{}
    $sw    = [System.Diagnostics.Stopwatch]::StartNew()

    while ($true) {
        $procs   = @(Get-Process -Name $Name -ErrorAction SilentlyContinue)
        $elapsed = $sw.Elapsed.TotalSeconds
        $sw.Restart()

        # CPU% = CPU seconds used since last refresh / wall-clock seconds / cores
        $rows = foreach ($p in $procs) {
            $cpuPct = $null
            if ($null -ne $p.CPU -and $prev.ContainsKey($p.Id) -and $elapsed -gt 0) {
                $cpuPct = [math]::Round(($p.CPU - $prev[$p.Id]) / $elapsed / $cores * 100, 1)
            }
            [pscustomobject]@{
                Name     = $p.Name
                Id       = $p.Id
                'CPU%'   = $cpuPct
                MemoryMB = [math]::Round($p.WorkingSet64/1MB,1)
                Threads  = $p.Threads.Count
            }
        }

        $prev = @{}
        foreach ($p in $procs) { if ($null -ne $p.CPU) { $prev[$p.Id] = $p.CPU } }

        Clear-Host
        Write-Host "Watching '$Name' Every $Interval s  |  $(Get-Date -Format 'HH:mm:ss')  |  Ctrl+C To Stop" -ForegroundColor Cyan

        if ($procs.Count -gt 0) { $rows | Format-Table -AutoSize | Out-Host }
        else { Write-Host "Not Running." -ForegroundColor Yellow }

        Start-Sleep -Seconds $Interval
    }
}


#################################################################################################################################
############                                                                                                         ############
############                                         VPN / CONNECTIVITY                                              ############
############                                                                                                         ############
#################################################################################################################################

# QUICK CHECK: AM I ON A VPN RIGHT NOW?
function VPNStatus {
    param(
        [string[]]$Pattern = @('WireGuard', 'NordLynx', 'NordVPN', 'Tailscale', 'OpenVPN', 'TAP-Windows', 'AnyConnect', 'Fortinet')
    )

    try {
        # Escape each term so special characters are treated literally, then join with |
        $regex = ($Pattern | ForEach-Object { [regex]::Escape($_) }) -join '|'

        $adapters = @(Get-NetAdapter |
            Where-Object { $_.InterfaceDescription -match $regex -or $_.Name -match $regex })

        $connected = @($adapters | Where-Object { $_.Status -eq 'Up' })

        if ($connected.Count -gt 0) {
            Write-Host "VPN Connected" -ForegroundColor Green

            # Public IP confirms traffic is actually leaving through the tunnel
            $publicIP = PubIP
            if ($publicIP) { Write-Host "Public IP: $publicIP" -ForegroundColor Green }

            $connected | Select-Object Name, InterfaceDescription, Status, LinkSpeed
        }
        else {
            Write-Host "No VPN Detected" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "⚠ Error In Line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        return
    }
}

# PING YOUR GATEWAY/ROUTER TO CONFIRM NETWORK REACHABILITY
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
                $answer = Read-Host "Could Not Detect A Gateway. Enter Its IP Address"
                $ip = $null
                $valid = [ipaddress]::TryParse($answer, [ref]$ip)
                if (-not $valid) { Write-Host "That Is Not A Valid IP Address." -ForegroundColor Yellow }
            } until ($valid)
            $Gateway = $answer
        }

        Write-Host "Pinging Gateway $Gateway..." -ForegroundColor Cyan
        Test-Connection $Gateway -Count 4 -ErrorAction Stop
    }
    catch {
        Write-Host "⚠ Error In Line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        return
    }
}


#################################################################################################################################
############                                                                                                         ############
############                                          CLIPBOARD & MISC UTILITIES                                     ############
############                                                                                                         ############
#################################################################################################################################

# GENERATE A RANDOM PASSWORD
function NewPassword {
    param(
        [int]$Length,
        [switch]$NoSpecial,
        [switch]$Copy
    )

    # Prompt only if no length was passed in
    if (-not $PSBoundParameters.ContainsKey('Length')) {
        do {
            $answer = Read-Host "Password Length (8-256, Enter For 30)"
            if ([string]::IsNullOrWhiteSpace($answer)) { $answer = '30' }
            $valid = [int]::TryParse($answer, [ref]$Length) -and $Length -ge 8 -and $Length -le 256
            if (-not $valid) { Write-Host "Enter A Whole Number Between 8 And 256." -ForegroundColor Yellow }
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

    # -Copy keeps the password off the screen and out of scrollback
    if ($Copy) {
        $password | Set-Clipboard
        Write-Host "Password Copied To Clipboard ($Length Characters)." -ForegroundColor Green
    }
    else {
        $password
    }
}

# QUICK FILE HASH (OPTIONALLY COMPARE TO AN EXPECTED VALUE)
function Hash {
    param(
        [Parameter(Mandatory)][string]$Path,
        [ValidateSet('SHA256','SHA384','SHA512','SHA1','MD5')][string]$Algorithm = 'SHA256',
        [string]$Expected
    )

    try {
        $hash = (Get-FileHash -LiteralPath $Path -Algorithm $Algorithm -ErrorAction Stop).Hash

        if ($Expected) {
            $clean = $Expected -replace '\s', ''
            if ($hash -eq $clean) {
                Write-Host "MATCH ($Algorithm)" -ForegroundColor Green
            }
            else {
                Write-Host "MISMATCH ($Algorithm)" -ForegroundColor Red
                Write-Host "  Expected: $clean"
                Write-Host "  Actual:   $hash"
            }
        }
        else {
            $hash
        }
    }
    catch {
        Write-Host "⚠ Error In Line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        return
    }
}

# CLEAR WINDOWS TEMP FILES
function ClearTemp {
    $measure = {
        Get-ChildItem -LiteralPath $env:TEMP -Recurse -File -Force -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum
    }

    $before = & $measure
    Get-ChildItem -LiteralPath $env:TEMP -Force -ErrorAction SilentlyContinue |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    $after = & $measure

    $removed = $before.Count - $after.Count
    $freedMB = [math]::Round(($before.Sum - $after.Sum) / 1MB, 1)

    Write-Host "Temp Files Cleared: $removed File(s) Removed, $freedMB MB Freed." -ForegroundColor Green
    if ($after.Count -gt 0) {
        Write-Host "$($after.Count) File(s) Skipped Because They Are In Use." -ForegroundColor Yellow
    }
}

# EMPTY RECYCLE BIN
function EmptyBin {
    try {
        Clear-RecycleBin -Confirm:$false -ErrorAction Stop
        Write-Host "Recycle Bin Emptied !" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠ Error In Line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        return
    }
}


#################################################################################################################################
############                                                                                                         ############
############                                         NAVIGATION & FILESYSTEM                                         ############
############                                                                                                         ############
#################################################################################################################################

# QUICK JUMP TO COMMON FOLDERS
function proj {
    $path = Join-Path $HOME 'Projects'
    if (Test-Path -LiteralPath $path) { Set-Location -LiteralPath $path }
    else { Write-Host "⚠ Folder Not Found: $path" -ForegroundColor Yellow }
}

# function dc { Set-Location "$HOME\Documents" }

function dl { Set-Location "$HOME\Downloads" }

# LS WITH MORE DETAIL, SORTED BY LAST MODIFIED
function lt {
    param(
        [string]$Path = '.',
        [int]$First = 0
    )

    try {
        $items = Get-ChildItem -Path $Path -ErrorAction Stop | Sort-Object LastWriteTime -Descending
        if ($First -gt 0) { $items | Select-Object -First $First } else { $items }
    }
    catch {
        Write-Host "⚠ Error In Line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor Red
        return
    }
}

# QUICK "GO UP N DIRECTORIES"
function up {
    param(
        [ValidateRange(1,50)][int]$n = 1
    )

    Set-Location -Path ((@('..') * $n) -join [IO.Path]::DirectorySeparatorChar)
}

# COPY CURRENT DIRECTORY PATH TO CLIPBOARD
function cpwd {
    $path = (Get-Location).Path
    $path | Set-Clipboard
    Write-Host "Copied: $path" -ForegroundColor Green
}


#################################################################################################################################
############                                                                                                         ############
############                                               PROFILE MANAGEMENT                                        ############
############                                                                                                         ############
#################################################################################################################################

# LIST ALL CUSTOM FUNCTIONS CURRENTLY LOADED FROM THIS PROFILE
function MyFunctions {
    # The file this function was defined in, i.e. this profile, wherever it lives
    $profileFile = $MyInvocation.MyCommand.ScriptBlock.File

    Get-Command -CommandType Function |
        Where-Object { $_.ScriptBlock.File -eq $profileFile } |
        Sort-Object Name |
        Select-Object Name
}


#################################################################################################################################
############                                                                                                         ############
############                                                WINGET FUNCTIONS                                         ############
############                                                                                                         ############
#################################################################################################################################

# WINGET APP UPDATES
function WGA { winget upgrade --all --accept-package-agreements --accept-source-agreements --silent --force }

# WINGET APP UPDATES LIST
function WGL { winget upgrade }

# WINGET APP UPDATES INCLUDING UNKNOWN
function WGUN { winget upgrade --all --accept-package-agreements --accept-source-agreements --silent --force --include-unknown }


# CHECK FOR PERSONAL PROFILE UPDATES ON EVERY INTERACTIVE SESSION
if ($Host.Name -eq 'ConsoleHost') {
    Update-PersonalProfile
}
