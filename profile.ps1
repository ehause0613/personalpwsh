# Check for Personal Profile Updates
function Update-Profile {
    try {
        $url = "https://raw.githubusercontent.com/ChrisTitusTech/powershell-profile/main/profile.ps1"
        $oldhash = Get-FileHash $PROFILE
        Invoke-RestMethod $url -OutFile "$env:temp/profile.ps1"
        $newhash = Get-FileHash "$env:temp/profile.ps1"
        if ($newhash.Hash -ne $oldhash.Hash) {
            Copy-Item -Path "$env:temp/profile.ps1" -Destination $PROFILE -Force
            Write-Host "Personal Profile has been updated. Please restart your shell to reflect changes" -ForegroundColor Magenta
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

# Weather
function Get-Wx { (Invoke-WebRequest https://wttr.in).Content }

# Network Utilities
function Get-PubIP { (Invoke-WebRequest https://ifconfig.me/ip).Content }
