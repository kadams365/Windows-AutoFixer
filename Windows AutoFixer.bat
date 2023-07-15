@ECHO OFF
ECHO ============================
ECHO Oh shit someone broke something. Let me see if I can fix it.
ECHO ============================
ECHO Checking for Windows errors.
SFC /SCANNOW
ECHO ============================
ECHO Checking for Windows updates.
UsoClient StartScan
ECHO ============================
ECHO Checking C drive.
chkntfs c:
ECHO ============================
ECHO Checking RAM.
wmic memorychip get devicelocator, capacity, speed
ECHO ============================
ECHO Refreshing network settings.
ipconfig /release
ipconfig /renew
arp -d *
nbtstat -R
nbtstat -RR
ipconfig /flushdns
ipconfig /registerdns
ECHO Settings have been updated.
ECHO ============================
ECHO Checking Gateway.
for /f "tokens=2 delims=:" %%g in ('ipconfig ^| findstr /c:"Default Gateway"') do ping %%g
ECHO ============================
ECHO Checking DNS. (Internet Connection)
for /f "tokens=2 delims=:" %%g in ('ipconfig /all ^| findstr /c:"DNS Server"') do ping %%g
ECHO ============================
ECHO Network info.
ipconfig /all
ECHO ============================
ECHO Device IP(s).
ipconfig | findstr IPv4
ipconfig | findstr IPv6
ECHO ============================
ECHO Attempting Winget upgrades.
winget upgrade --all
ECHO ============================
ECHO Press any key to restart computer...
pause
UsoClient RestartDevice
