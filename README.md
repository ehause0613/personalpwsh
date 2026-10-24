# personalpwsh - Person PowerShell #

Description: Functions And Shortcuts To Add To My Powershell Profile, Using profile.ps1.

WEATHER FUNCTIONS

- Check Weather: function Wx. https://wttr.in (resolves to Germany, for Region filtering purposes).


TIME FUNCTIONS

- Check Time & Date: function Time. https://timeapi.io/api/Time/current/zone?timeZone=America/New_York and Europe/Dublin.


SYSTEM INFO / DIAGNOSTICS

- Top Processes By CPU: function TopCPU { Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 }

- Top Processes By RAM: function TopRAM { Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10 }

- Disk Space Summary: function Disk


NETWORK FUNCTIONS

- Ping A Specified IP To Confirm Reachability: function PingIP

- Flush DNS Cache: function FlushDNS { Clear-DnsClientCache }

- Quick Qort Check: function TestPort

- Show Active Listening Ports: function Ports { Get-NetTCPConnection -State Listen }

- What Is My Public IP: https://ifconfig.me/ip

- Find Info On Local NIC Configuration: Get-NetIPConfiguration

- Find Info On A IPv4/IPv6 Address Or Domain Name: function IPInfo. http://ip-api.com/json/$IPaddress

- Find Info On A MAC ADDRESS: https://api.macvendors.com/$MACaddress

- Test Connection Speed. function SPEED { SPEEDTEST }. (Must have Ookla Speedtest CLI Installed/Configured) !!!


PROCESS MANAGEMENT

- Kill A Process By Name: function KillProc($name) { Stop-Process -Force }

- Watch A Process's Resource Usage Live: function WatchProc($name)


VPN / CONNECTIVITY

- Check WireGuard/VPN Adapter Status: function VPNStatus

- Ping Home Gateway To Confirm Reachability: function PingHome


CLIPBOARD & MISC UTILITIES

- Generate A Random Password: function NewPassword($length = 30)

- Quick File Hash (SHA256): function Hash($path)

- Clear Windows Temp Files: function ClearTemp

- Empty Recycle Bin: function EmptyBin


NAVIGATION & FILESYSTEM

- Quick Jump To Common Folders: function proj, function dl

- List Files Sorted By Last Modified: function lt

- Go Up N Directories: function up($n = 1)

- Copy Current Directory Path To Clipboard: function cpwd


PROFILE MANAGEMENT

- List All Custom Functions Currently Loaded From This Profile: function MyFunctions


WINGET FUNCTIONS

- WinGet App Updates List: function WGL { winget upgrade }

- WinGet App Updates: function WGA { winget upgrade --all --accept-package-agreements --accept-source-agreements --silent --force }

- WinGet App Updates Including Unknown: function WGUN { winget upgrade --all --accept-package-agreements --accept-source-agreements --silent --force --include-unknown }

