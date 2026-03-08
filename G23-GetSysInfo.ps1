# ================================================================
#  Get-SystemSpecs.ps1
#  Raccoglie le specifiche del PC e le invia all'API.
#  - Nessun file salvato sul disco
#  - Nessun privilegio admin richiesto
#  - Esegui con: powershell -ExecutionPolicy Bypass -File Get-SystemSpecs.ps1
# ================================================================

$API_URL = "https://g23-getsysinfo.vercel.app/api/upload"   # <-- aggiorna dopo il deploy

# ── helpers ──────────────────────────────────────────────────
$lines = [System.Collections.Generic.List[string]]::new()

function S($block) { try { & $block } catch {} }
function AL($text) { $lines.Add($text) }
function SEC($title) {
    AL ""
    AL ("=" * 60)
    AL "  $title"
    AL ("=" * 60)
}

# ── HEADER ───────────────────────────────────────────────────
$pcName = $env:COMPUTERNAME
$date   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

AL "╔══════════════════════════════════════════════════════════╗"
AL "║              SYSTEM SPECS REPORT                        ║"
AL "╠══════════════════════════════════════════════════════════╣"
AL "║  PC Name : $($pcName.PadRight(46))║"
AL "║  Date    : $($date.PadRight(46))║"
AL "╚══════════════════════════════════════════════════════════╝"

# ── OS ───────────────────────────────────────────────────────
SEC "OPERATING SYSTEM"
S {
    $os = Get-CimInstance Win32_OperatingSystem
    AL "  Name         : $($os.Caption)"
    AL "  Version      : $($os.Version)"
    AL "  Build        : $($os.BuildNumber)"
    AL "  Architecture : $($os.OSArchitecture)"
    AL "  Install Date : $($os.InstallDate)"
    AL "  Last Boot    : $($os.LastBootUpTime)"
    AL "  Total RAM    : $([math]::Round($os.TotalVisibleMemorySize/1MB,2)) GB"
    AL "  Free RAM     : $([math]::Round($os.FreePhysicalMemory/1MB,2)) GB"
}

# ── CPU ──────────────────────────────────────────────────────
SEC "CPU"
S {
    foreach ($c in (Get-CimInstance Win32_Processor)) {
        AL "  Name              : $($c.Name.Trim())"
        AL "  Manufacturer      : $($c.Manufacturer)"
        AL "  Max Clock (MHz)   : $($c.MaxClockSpeed)"
        AL "  Cores             : $($c.NumberOfCores)"
        AL "  Logical Procs     : $($c.NumberOfLogicalProcessors)"
        AL "  L2 Cache (KB)     : $($c.L2CacheSize)"
        AL "  L3 Cache (KB)     : $($c.L3CacheSize)"
        AL "  Socket            : $($c.SocketDesignation)"
        AL ""
    }
}

# ── RAM ──────────────────────────────────────────────────────
SEC "RAM"
S {
    $i = 1
    foreach ($s in (Get-CimInstance Win32_PhysicalMemory)) {
        $type = if ($s.SMBIOSMemoryType -eq 26) { "DDR4" } else { "DDR4+" }
        AL "  [Slot $i]"
        AL "    Type        : $type"
        AL "    Capacity    : $($s.Capacity/1GB) GB"
        AL "    Speed       : $($s.Speed) MHz"
        AL "    PC Rating   : PC4-$($s.ConfiguredClockSpeed * 8)"
        AL "    Voltage     : $($s.ConfiguredVoltage/1000) V"
        AL "    Manufacturer: $($s.Manufacturer)"
        AL "    Part Number : $($s.PartNumber.Trim())"
        AL "    Bank/Device : $($s.BankLabel) / $($s.DeviceLocator)"
        AL ""
        $i++
    }
}

# ── GPU ──────────────────────────────────────────────────────
SEC "GPU"
S {
    foreach ($g in (Get-CimInstance Win32_VideoController)) {
        AL "  Name          : $($g.Name)"
        AL "  VRAM          : $([math]::Round($g.AdapterRAM/1GB,1)) GB"
        AL "  Driver Ver    : $($g.DriverVersion)"
        AL "  Driver Date   : $($g.DriverDate)"
        AL "  Video Proc    : $($g.VideoProcessor)"
        AL "  Resolution    : $($g.CurrentHorizontalResolution) x $($g.CurrentVerticalResolution)"
        AL "  Refresh Rate  : $($g.CurrentRefreshRate) Hz"
        AL ""
    }
}

# ── STORAGE ──────────────────────────────────────────────────
SEC "STORAGE - PHYSICAL DISKS"
S {
    foreach ($d in (Get-CimInstance Win32_DiskDrive)) {
        AL "  Model         : $($d.Model)"
        AL "  Size          : $([math]::Round($d.Size/1GB)) GB"
        AL "  Interface     : $($d.InterfaceType)"
        AL "  Media Type    : $($d.MediaType)"
        AL "  Serial        : $($d.SerialNumber.Trim())"
        AL "  Partitions    : $($d.Partitions)"
        AL ""
    }
}

SEC "STORAGE - VOLUMES"
S {
    Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match '^[A-Z]:\\$' } | ForEach-Object {
        $used  = [math]::Round($_.Used/1GB,1)
        $free  = [math]::Round($_.Free/1GB,1)
        $total = [math]::Round(($_.Used+$_.Free)/1GB,1)
        AL "  Drive $($_.Name):  Used=$used GB  Free=$free GB  Total=$total GB"
    }
}

# ── MOTHERBOARD ──────────────────────────────────────────────
SEC "MOTHERBOARD"
S {
    $mb = Get-CimInstance Win32_BaseBoard
    AL "  Manufacturer : $($mb.Manufacturer)"
    AL "  Product      : $($mb.Product)"
    AL "  Version      : $($mb.Version)"
    AL "  Serial       : $($mb.SerialNumber)"
}

# ── BIOS ─────────────────────────────────────────────────────
SEC "BIOS"
S {
    $bios = Get-CimInstance Win32_BIOS
    AL "  Manufacturer : $($bios.Manufacturer)"
    AL "  Name         : $($bios.Name)"
    AL "  Version      : $($bios.SMBIOSBIOSVersion)"
    AL "  Release Date : $($bios.ReleaseDate)"
}

# ── NETWORK ──────────────────────────────────────────────────
SEC "NETWORK ADAPTERS (Physical)"
S {
    Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.PhysicalAdapter -eq $true } | ForEach-Object {
        $speed = if ($_.Speed) { "$([math]::Round($_.Speed/1MB)) Mbps" } else { "N/A" }
        AL "  $($_.Name)"
        AL "    MAC    : $($_.MACAddress)"
        AL "    Speed  : $speed"
        AL "    Status : $($_.NetConnectionStatus)"
        AL ""
    }
}

# ── AUDIO ────────────────────────────────────────────────────
SEC "AUDIO DEVICES"
S {
    Get-CimInstance Win32_SoundDevice | ForEach-Object {
        AL "  $($_.Name)  [$($_.Manufacturer)]  Status: $($_.Status)"
    }
}

# ── MONITOR ──────────────────────────────────────────────────
SEC "MONITORS"
S {
    Get-CimInstance Win32_DesktopMonitor | ForEach-Object {
        AL "  Name         : $($_.Name)"
        AL "  Manufacturer : $($_.MonitorManufacturer)"
        AL "  Resolution   : $($_.ScreenWidth) x $($_.ScreenHeight)"
        AL ""
    }
}

# ── BATTERY ──────────────────────────────────────────────────
SEC "BATTERY"
S {
    $bat = Get-CimInstance Win32_Battery
    if ($bat) {
        foreach ($b in $bat) {
            AL "  Name       : $($b.Name)"
            AL "  Status     : $($b.Status)"
            AL "  Charge (%) : $($b.EstimatedChargeRemaining)"
            AL "  Time Left  : $($b.EstimatedRunTime) min"
        }
    } else { AL "  No battery detected (desktop)" }
}

# ── SYSTEM ───────────────────────────────────────────────────
SEC "SYSTEM"
S {
    $cs = Get-CimInstance Win32_ComputerSystem
    AL "  Manufacturer  : $($cs.Manufacturer)"
    AL "  Model         : $($cs.Model)"
    AL "  System Type   : $($cs.SystemType)"
    AL "  Domain        : $($cs.Domain)"
    AL "  Username      : $($cs.UserName)"
    AL "  Total RAM     : $([math]::Round($cs.TotalPhysicalMemory/1GB,2)) GB"
}

# ── FOOTER ───────────────────────────────────────────────────
AL ""
AL ("=" * 60)
AL "  END OF REPORT  -  $date"
AL ("=" * 60)

# ── SHOW IN CONSOLE ──────────────────────────────────────────
$lines | ForEach-Object { Write-Host $_ }

# ── SEND TO API ──────────────────────────────────────────────
Write-Host "`n[...] Invio all'API..." -ForegroundColor Cyan

$body = [ordered]@{
    pcName  = $pcName
    content = ($lines -join "`n")
    date    = $date
} | ConvertTo-Json -Compress -Depth 3

try {
    $resp = Invoke-RestMethod `
        -Uri         $API_URL `
        -Method      POST `
        -ContentType "application/json; charset=utf-8" `
        -Body        ([System.Text.Encoding]::UTF8.GetBytes($body))
    Write-Host "[OK] Inviato! $($resp | ConvertTo-Json -Compress)" -ForegroundColor Green
} catch {
    Write-Host "[ERRORE] $_" -ForegroundColor Red
}
