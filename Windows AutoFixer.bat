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
ECHO Checking internet connection (Google DNS).
ping 8.8.8.8
ECHO ============================
ECHO Checking C drive.
chkntfs c:
ECHO ============================
ECHO Network info.
ipconfig /all
ECHO ============================
ECHO Device IP(s).
ipconfig | findstr IPv4
ipconfig | findstr IPv6
ECHO ============================
ECHO Press 'Enter to restart computer...
pause
UsoClient RestartDevice
