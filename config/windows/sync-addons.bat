@echo off
setlocal enabledelayedexpansion

:: Addon Sync Script for Windows (Batch Version)
:: Usage: sync-addons.bat [link|copy|status]

set "SCRIPT_DIR=%~dp0"
set "REPO_DIR=%SCRIPT_DIR%..\.."
set "REPO_ADDONS=%REPO_DIR%\addons"

:: Try to find WoW path
if defined WOW_PATH (
    set "WOW_DIR=%WOW_PATH%"
) else (
    if exist "C:\World of Warcraft" (
        set "WOW_DIR=C:\World of Warcraft"
    ) else if exist "D:\World of Warcraft" (
        set "WOW_DIR=D:\World of Warcraft"
    ) else if exist "C:\Games\World of Warcraft" (
        set "WOW_DIR=C:\Games\World of Warcraft"
    ) else (
        echo ERROR: WoW installation not found!
        echo Please set the WOW_PATH environment variable
        echo Example: set WOW_PATH=D:\Games\WoW
        exit /b 1
    )
)

set "WOW_ADDONS=%WOW_DIR%\Interface\AddOns"

:: Create AddOns folder if needed
if not exist "%WOW_ADDONS%" mkdir "%WOW_ADDONS%"

:: Parse command
if "%1"=="" goto :usage
if "%1"=="link" goto :link
if "%1"=="copy" goto :copy
if "%1"=="status" goto :status
goto :usage

:usage
echo.
echo Addon Sync Script for Windows
echo =============================
echo.
echo Usage: %~nx0 [command]
echo.
echo Commands:
echo   link   - Create symlinks (requires Admin)
echo   copy   - Copy addons (no Admin required)
echo   status - Show sync status
echo.
echo Paths:
echo   Repository: %REPO_ADDONS%
echo   WoW AddOns: %WOW_ADDONS%
echo.
exit /b 0

:status
echo.
echo Addon Sync Status
echo =================
echo.
echo Repository: %REPO_ADDONS%
echo WoW AddOns: %WOW_ADDONS%
echo.

set "count=0"
for /d %%A in ("%REPO_ADDONS%\*") do (
    set "name=%%~nxA"
    set /a count+=1

    if exist "%WOW_ADDONS%\!name!" (
        echo   [OK] !name!
    ) else (
        echo   [MISSING] !name!
    )
)
echo.
echo Total: %count% addons in repo
exit /b 0

:link
echo.
echo Creating symlinks (requires Administrator)...
echo.

:: Check for admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: This command requires Administrator privileges!
    echo Right-click and select "Run as administrator"
    echo Or use "copy" command instead.
    exit /b 1
)

set "linked=0"
for /d %%A in ("%REPO_ADDONS%\*") do (
    set "name=%%~nxA"
    set "source=%%A"
    set "target=%WOW_ADDONS%\!name!"

    if exist "!target!" (
        echo   [REPLACE] !name!
        rmdir /s /q "!target!" 2>nul
        del /q "!target!" 2>nul
    )

    mklink /d "!target!" "!source!" >nul 2>&1
    if !errorlevel! equ 0 (
        echo   [LINK] !name!
        set /a linked+=1
    ) else (
        echo   [ERROR] !name!
    )
)

echo.
echo Done! Linked: %linked% addons
exit /b 0

:copy
echo.
echo Copying addons to WoW...
echo.

set "copied=0"
for /d %%A in ("%REPO_ADDONS%\*") do (
    set "name=%%~nxA"
    set "source=%%A"
    set "target=%WOW_ADDONS%\!name!"

    echo   [COPY] !name!

    if exist "!target!" rmdir /s /q "!target!"
    xcopy "!source!" "!target!\" /e /i /q >nul
    set /a copied+=1
)

echo.
echo Done! Copied: %copied% addons
exit /b 0
