echo on
pushd %~dp0
powershell.exe -File ListServersandstopSpooler.ps1
pause

