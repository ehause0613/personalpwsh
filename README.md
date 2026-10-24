# personalpwsh - Personal PowerShell #

Description: Functions And Shortcuts For My PowerShell Profile, Using profile.ps1.


REQUIREMENTS

- PowerShell 7 (profile lives at Documents\PowerShell\profile.ps1, the "Current User, All Hosts" profile).

- Chris Titus Tech's PowerShell profile. Install with: irm "https://github.com/ChrisTitusTech/powershell-profile/raw/main/setup.ps1" | iex

- Oh My Posh (for the prompt theme). Gets installed as a part of the CTT command above.

- Ookla Speedtest CLI (optional, for SPEED): Install with: winget install Ookla.Speedtest.CLI


STARTUP BEHAVIOR

- Personal Profile Auto-Update: function Update-PersonalProfile. Runs on every interactive shell launch. Downloads profile.ps1 from this repo (5-second timeout), refuses it if it has syntax errors, and replaces the local copy if it changed. Always push changes to GitHub before opening a new shell, or local edits are overwritten.

- Oh My Posh Theme: function Get-Theme_Override. Called automatically by the Chris Titus profile in place of its own theme. Uses agnosterplus, cached locally and refreshed weekly (5-second timeout). Uses the cached copy when offline.


WEATHER FUNCTIONS

- Check Weather: function Wx. https://wttr.in (resolves to Germany, for Region filtering purposes). US units.
  - Wx                Weather for your current location
  - Wx London         Weather for a named location
  - Wx -Short         One-line summary


TIME FUNCTIONS

- Check Time & Date: function Time. Calculated locally (no web call). Shows time, day, UTC offset and DST.
  - Time              America/New_York and Europe/Dublin
  - Time -Zones       'Asia/Tokyo','America/Denver'


SYSTEM INFO / DIAGNOSTICS

- Top Processes By Current CPU Usage: function TopCPU. Live CPU % (about 1 second to sample). TopCPU -Top 20

- Top Processes By RAM: function TopRAM. Memory in MB. TopRAM -Top 20

- Disk Space Summary: function Disk. Total, used, free and % free for local and removable drives.


NETWORK FUNCTIONS

- Ping An IP Or Hostname To Confirm Reachability: function PingIP. Prompts if no target is given.
  - PingIP 1.1.1.1 -Count 10

- Quick Port Check: function TestPort. Prompts for anything missing. 3-second default timeout.
  - TestPort github.com 443 -TimeoutSeconds 5

- Show Active Listening Ports With Process Names: function Ports. Ports -IncludeUdp

- Show Local NIC Configuration: function NetIP. Connected adapters only. NetIP -All shows every adapter.

- Find Info On An IPv4/IPv6 Address Or Domain Name: function IPInfo. http://ip-api.com/json/ (HTTP only, not encrypted). Prompts if no address is given; blank input looks up your own public IP.
  - IPInfo 8.8.8.8

- Find The Vendor Of A MAC Address: function MAC. https://api.macvendors.com/ Accepts any separator format; needs at least the first 3 bytes. Identifies randomized (locally administered) MACs. Limited to about 1 request per second.
  - MAC 00:1A:2B:3C:4D:5E

- Test Connection Speed: function SPEED. Requires Ookla Speedtest CLI.

- Public IP / Flush DNS: provided by the Chris Titus profile (pubip, flushdns).


PROCESS MANAGEMENT

- Kill A Process By Name: function KillProc. Lists matches and asks for confirmation.
  - KillProc notepad                Confirm before killing
  - KillProc notepad -Force         No confirmation
  - KillProc notepad -WhatIf        Preview only

- Watch A Process's Resource Usage Live: function WatchProc. Shows CPU %, memory and threads. Ctrl+C to stop.
  - WatchProc chrome -Interval 5


VPN / CONNECTIVITY

- Check VPN Adapter Status: function VPNStatus. Detects WireGuard, NordLynx, NordVPN, Tailscale, OpenVPN, AnyConnect and Fortinet. Shows public IP when connected.
  - VPNStatus -Pattern 'ZeroTier'   Search for other adapters

- Ping Gateway To Confirm Reachability: function PingHome. Auto-detects the current gateway; prompts if it can't.
  - PingHome -Gateway 10.0.1.1      Ping the home gateway specifically


CLIPBOARD & MISC UTILITIES

- Generate A Random Password: function NewPassword. Cryptographic RNG. Includes digits, upper, lower and special characters (at least one of each). Prompts for length (8-256, default 30) if not given.
  - NewPassword -Length 24
  - NewPassword -NoSpecial          Letters and digits only
  - NewPassword -Copy               Copy to clipboard instead of displaying

- Quick File Hash: function Hash. SHA256 by default.
  - Hash .\file.iso
  - Hash .\file.iso -Algorithm SHA512
  - Hash .\file.iso -Expected <checksum>   Reports MATCH or MISMATCH

- Clear Windows Temp Files: function ClearTemp. Reports files removed, space freed and files skipped (in use).

- Empty Recycle Bin: function EmptyBin


NAVIGATION & FILESYSTEM

- Quick Jump To Common Folders: function proj ($HOME\Projects), function dl (Downloads). Documents: docs (Chris Titus profile).

- List Files Sorted By Last Modified: function lt
  - lt C:\Logs -First 10

- Go Up N Directories: function up. up 3

- Copy Current Directory Path To Clipboard: function cpwd


PROFILE MANAGEMENT

- List All Custom Functions Currently Loaded From This Profile: function MyFunctions


WINGET FUNCTIONS

- WinGet App Updates List: function WGL { winget upgrade }

- WinGet App Updates: function WGA { winget upgrade --all --accept-package-agreements --accept-source-agreements --silent --force }

- WinGet App Updates Including Unknown: function WGUN { winget upgrade --all --accept-package-agreements --accept-source-agreements --silent --force --include-unknown }
