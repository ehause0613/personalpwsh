# personalpwsh
Functions and shortcuts to add to my Powershell profile, using profile.ps1.

WEATHER FUNCTIONS

- https://wttr.in (resolves to Germany for Region filtering purposes).


TIME FUNCTIONS

- https://timeapi.io/api/Time/current/coordinate


NETWORK FUNCTIONS

- What is My Public IP: https://ifconfig.me/ip

- Find Info On a Public IP: Get-NetIPConfiguration

- Find Info On a Public IP: https://ip-api.com/json/$IPaddress

- Find Info On a MAC ADDRESS: https://api.macvendors.com/$MACaddress

- Sppedtest (Must have Ookla Speedtest CLI Installed): function speed { SPEEDTEST }


WINGET FUNCTIONS

- WinGet App Updates List: function WGL { winget upgrade }

- WinGet App Updates: function WGA { winget upgrade --all --accept-package-agreements --accept-source-agreements --silent --force }

- WinGet App Updates Including Unknown: function WGUN { winget upgrade --all --accept-package-agreements --accept-source-agreements --silent --force --include-unknown }

