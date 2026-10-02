# personalpwsh
Functions and shortcuts to add to my Powershell profile, using profile.ps1.

WEATHER FUNCTIONS

- Wx: https://wttr.in (resolves to Germany for Region filtering purposes).


TIME FUNCTIONS

- Time: https://timeapi.io/api/Time/current/zone?timeZone=America/New_York and Europe/Dublin


SYSTEM INFO / DIAGNOSTICS

- Top processes by CPU: function TopCPU { Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 }

- Top processes by RAM: function TopRAM { Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10 }

- Disk space summary: function Disk


NETWORK FUNCTIONS

- Ping a specified IP to confirm reachability: function PingIP

- Flush DNS cache: function FlushDNS { Clear-DnsClientCache }

- Quick port check: function TestPort

- Show active listening ports: function Ports { Get-NetTCPConnection -State Listen }

- What is My Public IP: https://ifconfig.me/ip

- Find Info On Local NIC Configuration: Get-NetIPConfiguration

- Find Info On a Public IP: https://ip-api.com/json/$IPaddress

- Find Info On a MAC ADDRESS: https://api.macvendors.com/$MACaddress


PROCESS MANAGEMENT

- Kill a process by name: function KillProc($name) { Stop-Process -Force }

- Watch a process's resource usage live: function WatchProc($name)


VPN / CONNECTIVITY

- Check WireGuard adapter status: function VPNStatus

- Ping home gateway to confirm reachability: function PingHome


CLIPBOARD & MISC UTILITIES

- Generate a random password: function NewPassword($length = 20)

- Quick file hash (SHA256): function Hash($path)

- Clear Windows temp files: function ClearTemp

- Empty recycle bin: function EmptyBin


NAVIGATION & FILESYSTEM

- Quick jump to common folders: function proj, function dl

- List files sorted by last modified: function lt

- Go up N directories: function up($n = 1)

- Copy current directory path to clipboard: function cpwd


PROFILE MANAGEMENT

- List all custom functions currently loaded from this profile: function MyFunctions


WINGET FUNCTIONS

- WinGet App Updates List: function WGL { winget upgrade }

- WinGet App Updates: function WGA { winget upgrade --all --accept-package-agreements --accept-source-agreements --silent --force }

- WinGet App Updates Including Unknown: function WGUN { winget upgrade --all --accept-package-agreements --accept-source-agreements --silent --force --include-unknown }

- Sppedtest (Must have Ookla Speedtest CLI Installed): function SPEED { SPEEDTEST }

- Restore Windows Health - DISM (currently commented out): function dism { DISM /ONLINE /CLEANUP-IMAGE /RESTOREHEALTH }
