@echo off
setlocal
rem Builds the Godot project into a Windows exe: export\Aetherbound Idle.exe
rem Double-click it, or run "build-exe.bat debug" for a debug build (prints errors to a console window).
rem Uses the "Windows Desktop" preset in export_presets.cfg.
rem To use a different Godot, set GODOT to its *_console.exe before running.

if not defined GODOT set "GODOT=D:\GameDev\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe"
set "TEMPLATES=%APPDATA%\Godot\export_templates\4.7.2.stable.mono"
set "PROJECT=%~dp0."
set "OUT=%~dp0export\Aetherbound Idle.exe"
set "MODE=--export-release"
if /i "%~1"=="debug" set "MODE=--export-debug"

if not exist "%GODOT%" (
    echo Godot not found at:
    echo   %GODOT%
    echo Edit the GODOT line at the top of this file, or set GODOT first.
    goto :fail
)
if not exist "%TEMPLATES%\windows_release_x86_64.exe" (
    echo The Godot export templates are not installed. One-time setup:
    echo   1. Open the project in the Godot editor.
    echo   2. Editor menu ^> Manage Export Templates ^> Download and Install.
    echo   3. Run this file again.
    goto :fail
)

if not exist "%~dp0export" mkdir "%~dp0export"
if exist "%OUT%" del "%OUT%"

echo Importing assets...
"%GODOT%" --headless --path "%PROJECT%" --import
if errorlevel 1 (
    echo Import failed, see the messages above.
    goto :fail
)

echo Exporting (%MODE:~9%)...
"%GODOT%" --headless --path "%PROJECT%" %MODE% "Windows Desktop" "%OUT%"
if errorlevel 1 goto :exportfail
if not exist "%OUT%" goto :exportfail

echo.
echo Built: %OUT%
explorer /select,"%OUT%"
pause
exit /b 0

:exportfail
echo Export failed, see the messages above.
:fail
echo.
pause
exit /b 1
