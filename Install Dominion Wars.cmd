@echo off
title Dominion Wars Modernizer
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0DominionWarsModernizer.ps1" Install
set "DW_EXIT=%ERRORLEVEL%"
echo.
if not "%DW_EXIT%"=="0" (
    echo Installation did not complete. No staged destination should have been committed.
) else (
    echo Installation completed successfully.
)
pause
exit /b %DW_EXIT%
