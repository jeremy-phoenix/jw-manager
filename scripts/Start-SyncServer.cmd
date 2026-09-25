@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-SyncServer.ps1" %*
set "serverExitCode=%ERRORLEVEL%"
pause
exit /b %serverExitCode%
