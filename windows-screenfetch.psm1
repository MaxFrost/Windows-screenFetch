#### Screenfetch for powershell
#### Author Julian Chow


Function Get-ScreenFetch {
    [CmdletBinding()]
    param(
        $Distro
    )
    $AsciiArt = "";

    if (-not $Distro) {
        $AsciiArt = Get-WindowsArt
    }

    if (([string]::Compare($Distro, "mac", $true) -eq 0) -or
        ([string]::Compare($Distro, "macOS", $true) -eq 0) -or
        ([string]::Compare($Distro, "osx", $true) -eq 0)) {

        $AsciiArt = Get-MacArt
    }
    else {
        $AsciiArt = Get-WindowsArt
    }

    $SystemInfoCollection = Get-SystemSpecifications
    $LineToTitleMappings = Get-LineToTitleMappings

    if ($SystemInfoCollection.Count -gt $AsciiArt.Count) {
        Write-Error "System Specs occupies more lines than the Ascii Art resource selected"
    }

    # Need to make this agnostic of the art, but still retain the art. Needs to keep going if fields keep pushing it past art.
    for ($line = 0; $line -lt $AsciiArt.Count; $line++) {
        Write-Host $AsciiArt[$line] -f Cyan -NoNewline
        if ($LineToTitleMappings[$line + 1]) {
            Write-Host "$($LineToTitleMappings[$line + 1]): " -f Red -NoNewline
            Write-Host $SystemInfoCollection.$($LineToTitleMappings[$line + 1]) -NoNewline
        }
        Write-Host ""
    }
}

