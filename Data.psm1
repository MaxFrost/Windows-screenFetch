#Add-Type -AssemblyName System.Windows.Forms

Function Get-SystemSpecifications() {

    [PSCustomObject]@{
        User        = Get-UserInformation
        OS          = Get-OS
        Kernel      = Get-Kernel
        Uptime      = Get-ScreenUptime
        Motherboard = Get-Mobo
        Shell       = Get-Shell
        Resolution  = Get-Displays -join ', '
        "Window Manager" = Get-WM
        Font        = Get-Font
        CPU         = Get-CPU
        GPU         = Get-GPU
        RAM         = Get-RAM
        Disks       = Get-Disks # Need to fix multi disk output
    }
}

Function Get-LineToTitleMappings() {
    # This controls display order, and should match the get-systemspeccifications names
    $TitleMappings = @{
        1  = "User"
        2  = "OS"
        3  = "Kernel"
        4  = "Uptime"
        5  = "Motherboard"
        6  = "Shell"
        7  = "Resolution"
        8  = "Window Manager"
        9  = "Font"
        10  = "CPU"
        11 = "GPU"
        12 = "RAM"
        13 = "Disks"
    }

    return $TitleMappings
}

Function Get-UserInformation() {
    return $env:USERNAME + "@" + $env:COMPUTERNAME
}

Function Get-OS() {
    return (Get-CimInstance -ClassName Win32_OperatingSystem).Caption + " " + $env:PROCESSOR_ARCHITECTURE
}

Function Get-Kernel() {
    return (Get-CimInstance -ClassName Win32_OperatingSystem).Version
}

Function Get-ScreenUptime() {
    #Todo: Fix this to work on powershell 5.1 AND 6+. Specifically Get-Uptime doesn't exist on older versions. Might have to regress this one and use the Cim Methods.
    $Uptime = (Get-Date (Get-CimInstance Win32_OperatingSystem).LocalDateTime) - (Get-Date (Get-CimInstance Win32_OperatingSystem).LastBootUpTime)

    $FormattedUptime = $Uptime.Days.ToString() + "d " + $Uptime.Hours.ToString() + "h " + $Uptime.Minutes.ToString() + "m " + $Uptime.Seconds.ToString() + "s "
    return $FormattedUptime
}

Function Get-Mobo() {
    $Motherboard = Get-CimInstance Win32_BaseBoard | Select-Object Manufacturer, Product
    return $Motherboard.Manufacturer + " " + $Motherboard.Product

}

Function Get-Shell() {
    return "PowerShell $($PSVersionTable.PSVersion.ToString())"
}

Function Get-Display() {
    # This gives the current resolution
    $videoMode = Get-CimInstance -ClassName Win32_VideoController
    $Display = $videoMode.CurrentHorizontalResolution.ToString() + " x " + $videoMode.CurrentVerticalResolution.ToString() + " (" + $videoMode.CurrentRefreshRate.ToString() + "Hz)"
    return $Display
}

Function Get-Displays() {
    $Displays = New-Object System.Collections.Generic.List[System.Object]

    # This gives the available resolutions
    try {
        $monitors = Get-CimInstance -Namespace "root\wmi" -ClassName WmiMonitorListedSupportedSourceModes -ErrorAction 'Stop'

        foreach ($monitor in $monitors) {
            # Sort the available modes by display area (width*height)
            $sortedResolutions = $monitor.MonitorSourceModes | Sort-Object -property { $_.HorizontalActivePixels * $_.VerticalActivePixels }
            $maxResolutions = $sortedResolutions | Select-Object @{
                N = "MaxRes"
                E = { "$($_.HorizontalActivePixels) x $($_.VerticalActivePixels)"}
            }

            $Displays.Add(($maxResolutions | Select-Object -last 1).MaxRes)
        }

        if ($Displays.Count -eq 1) {
            return Get-Display
        }

        return $Displays
    } catch {
        return 'Remote Terminal'
    }

}

Function Get-WM() {
    return "DWM"
}

Function Get-Font() {
    return "Segoe UI"
}

Function Get-CPU() {
    return (((Get-CimInstance Win32_Processor).Name) -replace '\s+', ' ')
}

Function Get-GPU() {
    return (Get-CimInstance Win32_DisplayConfiguration).DeviceName
}

Function Get-RAM() {
    $FreeRam = ([math]::Truncate((Get-CimInstance -ClassName Win32_OperatingSystem).FreePhysicalMemory / 1KB))
    $TotalRam = ([math]::Truncate((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1MB))
    $UsedRam = $TotalRam - $FreeRam
    $FreeRamPercent = ($FreeRam / $TotalRam) * 100
    $FreeRamPercent = "{0:N0}" -f $FreeRamPercent
    $UsedRamPercent = ($UsedRam / $TotalRam) * 100
    $UsedRamPercent = "{0:N0}" -f $UsedRamPercent

    return $UsedRam.ToString() + "MB / " + $TotalRam.ToString() + " MB " + "(" + $UsedRamPercent.ToString() + "%" + ")"
}

Function Get-Disks() {
    $FormattedDisks = New-Object System.Collections.Generic.List[System.Object]

    $AllDisks = Get-CimInstance Win32_LogicalDisk
    foreach ($Disk in $AllDisks) {
        $DiskID = $Disk.DeviceId

        $DiskSize = $Disk.Size

        if ($DiskSize -and $DiskSize -ne 0) {
            $FreeDiskSize = $Disk.FreeSpace
            $FreeDiskSizeGB = $FreeDiskSize / 1073741824
            $FreeDiskSizeGB = "{0:N0}" -f $FreeDiskSizeGB

            $DiskSizeGB = $DiskSize / 1073741824
            $DiskSizeGB = "{0:N0}" -f $DiskSizeGB

            $FreeDiskPercent = ($FreeDiskSizeGB / $DiskSizeGB) * 100
            $FreeDiskPercent = "{0:N0}" -f $FreeDiskPercent

            $UsedDiskSizeGB = $DiskSizeGB - $FreeDiskSizeGB
            $UsedDiskPercent = ($UsedDiskSizeGB / $DiskSizeGB) * 100
            $UsedDiskPercent = "{0:N0}" -f $UsedDiskPercent
        }
        else {
            $DiskSizeGB = 0
            $FreeDiskSizeGB = 0
            $FreeDiskPercent = 0
            $UsedDiskSizeGB = 0
            $UsedDiskPercent = 100
        }

        $FormattedDisk = "Disk " + $DiskID.ToString() + " " +
        $UsedDiskSizeGB.ToString() + "GB" + " / " + $DiskSizeGB.ToString() + "GB" +
        "(" + $UsedDiskPercent.ToString() + "%" + ")"
        $FormattedDisks.Add($FormattedDisk)
    }


    return $FormattedDisks
}
