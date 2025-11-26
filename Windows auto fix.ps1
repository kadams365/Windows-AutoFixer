# ============================
# AUTO-ELEVATE TO ADMIN
# ============================

# Relaunch as Admin if not elevated
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltinRole] "Administrator"))
{
    Write-Output "Restarting script as Administrator..."
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# ============================
# START LOGGING
# ============================
$TimeStamp = (Get-Date -Format "yyyy-MM-dd_HH-mm-ss")
$Log = "$env:USERPROFILE\Desktop\SystemHealthLog_$TimeStamp.txt"
Start-Transcript -Path $Log -Append

Write-Output "===== SYSTEM HEALTH & REPAIR SCRIPT STARTED: $((Get-Date).ToString()) ====="

# ============================
# CREATE RESTORE POINT
# ============================
Write-Output "`nCreating System Restore Point..."
Checkpoint-Computer -Description "SystemHealthPro Script" -RestorePointType MODIFY_SETTINGS

# ============================
# 1. SFC SCAN
# ============================
Write-Output "`nRunning SFC Scan..."
sfc /scannow

# ============================
# 2. DISM CHECKS
# ============================
Write-Output "`nRunning DISM Health Checks..."
DISM /Online /Cleanup-Image /CheckHealth
DISM /Online /Cleanup-Image /ScanHealth
DISM /Online /Cleanup-Image /RestoreHealth

# ============================
# 3. WINDOWS DEFENDER QUICK SCAN
# ============================
Write-Output "`nRunning Windows Defender Quick Scan..."
Start-Process "$env:ProgramFiles\Windows Defender\MpCmdRun.exe" -ArgumentList "-Scan -ScanType 1" -Wait

# ============================
# 4. WMI HEALTH CHECK & REPAIR
# ============================
Write-Output "`nChecking WMI Repository..."

$wmiStatus = winmgmt /verifyrepository
Write-Output "WMI Status: $wmiStatus"

if ($wmiStatus -match "inconsistent") {
    Write-Output "WMI repository inconsistent — repairing..."
    winmgmt /salvagerepository
}

# ============================
# 5. REGISTRY INTEGRITY CHECK
# ============================
Write-Output "`nChecking Registry Hives..."

$hives = @(
    "HKLM:\SYSTEM",
    "HKLM:\SOFTWARE",
    "HKU:\.DEFAULT",
    "HKCU:\"
)

foreach ($hive in $hives) {
    try {
        Get-ChildItem $hive | Out-Null
        Write-Output "Registry hive OK: $hive"
    } catch {
        Write-Output "ERROR accessing hive: $hive"
    }
}

Write-Output "`nSearching CBS logs for registry errors..."
Select-String -Path "C:\Windows\Logs\CBS\CBS.log" `
    -Pattern "registry","hive","corrupt" -ErrorAction SilentlyContinue |
    Select-Object LineNumber, Line

# ============================
# 6. DISK SMART HEALTH
# ============================
Write-Output "`nChecking SMART Disk Health..."
Get-PhysicalDisk | Select-Object FriendlyName, HealthStatus, OperationalStatus, Usage, Size

# ============================
# 7. CHKDSK QUICK SCAN
# ============================
Write-Output "`nRunning CHKDSK scan..."
chkdsk C: /scan

# ============================
# 8. RAM INFORMATION
# ============================
Write-Output "`nRAM Information:"
Get-CimInstance Win32_PhysicalMemory |
    Select-Object DeviceLocator, Capacity, Speed | Format-Table

# ============================
# 9. CLEAN TEMP FILES
# ============================
Write-Output "`nCleaning Temporary Files..."

$TempPaths = @(
    "$env:TEMP\*",
    "C:\Windows\Temp\*"
)

foreach ($path in $TempPaths) {
    Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Output "Temporary files cleaned."

# ============================
# 10. NETWORK REPAIR
# ============================
Write-Output "`nRefreshing Network Stack..."

ipconfig /flushdns
ipconfig /registerdns
ipconfig /release
ipconfig /renew

Clear-DnsClientCache

# Gateway Test
Write-Output "`nTesting Gateway Connectivity..."
$gateway = (Get-NetIPConfiguration | Where-Object {$_.IPv4DefaultGateway}).IPv4DefaultGateway.NextHop
if ($gateway) { Test-Connection $gateway -Count 4 }

# DNS Test
Write-Output "`nTesting DNS Servers..."
$dnsServers = (Get-DnsClientServerAddress -AddressFamily IPv4).ServerAddresses
foreach ($dns in $dnsServers) { Test-Connection $dns -Count 4 }

# ============================
# 11. WINDOWS UPDATE REPAIR
# ============================
Write-Output "`nResetting Windows Update System..."

Stop-Service wuauserv -Force
Stop-Service bits -Force
Stop-Service cryptsvc -Force

Rename-Item "C:\Windows\SoftwareDistribution" "SoftwareDistribution.old" -Force -ErrorAction SilentlyContinue
Rename-Item "C:\Windows\System32\catroot2" "catroot2.old" -Force -ErrorAction SilentlyContinue

Start-Service wuauserv
Start-Service bits
Start-Service cryptsvc

Write-Output "Windows Update components reset."

# ============================
# 12. RELIABILITY MONITOR EVENTS
# ============================
Write-Output "`nRecent Reliability Monitor Errors:"
Get-WinEvent -FilterHashtable @{
    LogName="Application"
    Level=2
    StartTime=(Get-Date).AddDays(-7)
} | Select-Object TimeCreated, Id, Message

# ============================
# 13. GPU / DRIVER INFO
# ============================
Write-Output "`nGPU Information:"
Get-CimInstance Win32_VideoController |
    Select-Object Name, DriverVersion

# ============================
# 14. POWER / BATTERY REPORT
# ============================
Write-Output "`nGenerating Power Reports..."
powercfg /energy /output "$env:USERPROFILE\Desktop\energy-report.html"
powercfg /batteryreport /output "$env:USERPROFILE\Desktop\battery-report.html"

# ============================
# 15. WINGET UPDATE CHECK
# ============================
Write-Output "`nChecking for app updates..."
winget upgrade --all

# ============================
# END & RESTART PROMPT
# ============================
Stop-Transcript

Write-Output "`n===== SYSTEM HEALTH & REPAIR COMPLETE ====="
Write-Output "Log saved to: $Log"
Write-Output "`nRestart recommended. Restart now? (Y/N)"

$choice = Read-Host
if ($choice -eq "Y") { Restart-Computer -Force }
