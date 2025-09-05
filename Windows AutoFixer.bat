:: ============================
:: System File Check
:: ============================
ECHO Checking for Windows errors...
SFC /SCANNOW
ECHO ============================

:: ============================
:: Windows Update Check
:: ============================
ECHO Checking for Windows updates...
UsoClient StartScan
ECHO ============================

:: ============================
:: Disk Health
:: ============================
ECHO Checking C drive for errors...
chkdsk C: /f /r /x
ECHO ============================

:: ============================
:: RAM Info
:: ============================
ECHO Checking RAM...
wmic memorychip get devicelocator, capacity, speed
ECHO ============================

:: ============================
:: Temporary File Cleanup
:: ============================
ECHO Cleaning temporary files...
del /q/f/s %TEMP%\*
del /q/f/s C:\Windows\Temp\*
ECHO ============================

:: ============================
:: Network Refresh
:: ============================
ECHO Refreshing network settings...
ipconfig /release
ipconfig /renew
arp -d *
nbtstat -R
nbtstat -RR
ipconfig /flushdns
ipconfig /registerdns
ECHO Network settings updated.
ECHO ============================

:: ============================
:: Gateway & DNS Check
:: ============================
ECHO Checking Gateway connectivity...
for /f "tokens=2 delims=:" %%g in ('ipconfig ^| findstr /c:"Default Gateway"') do ping %%g
ECHO Checking DNS connectivity...
for /f "tokens=2 delims=:" %%g in ('ipconfig /all ^| findstr /c:"DNS Server"') do ping %%g
ECHO ============================

:: ============================
:: Network Info
:: ============================
ECHO Network configuration:
ipconfig /all
ECHO Device IP(s):
ipconfig | findstr IPv4
ipconfig | findstr IPv6
ECHO ============================

:: ============================
:: System Services Check
:: ============================
ECHO Checking key Windows services...
sc query "wuauserv"
sc query "bits"
sc query "Dnscache"
ECHO ============================

:: ============================
:: Startup Programs
:: ============================
ECHO Listing startup items...
wmic startup get caption, command
ECHO ============================

:: ============================
:: Event Logs
:: ============================
ECHO Checking recent critical system events...
wevtutil qe System /q:"*[System[(Level=1 or Level=2)]]" /c:10 /f:text
ECHO ============================

:: ============================
:: GPU / Driver Info
:: ============================
ECHO Listing display adapters...
wmic path win32_videocontroller get name, driverversion
ECHO ============================

:: ============================
:: Windows Defender Scan
:: ============================
ECHO Running quick Windows Defender scan...
"%ProgramFiles%\Windows Defender\MpCmdRun.exe" -Scan -ScanType 1
ECHO ============================

:: ============================
:: System Summary
:: ============================
ECHO System Information:
systeminfo | findstr /B /C:"OS Name" /C:"OS Version" /C:"System Type" /C:"Total Physical Memory"
ECHO ============================

:: ============================
:: Winget Updates
:: ============================
ECHO Attempting Winget upgrades...
winget upgrade --all
ECHO ============================

:: ============================
:: Restart Prompt
:: ============================
ECHO Press any key to restart your computer...
pause
UsoClient RestartDevice
