@echo off
setlocal EnableDelayedExpansion
title Helios Theme Generator — Release Builder
color 0A

echo.
echo  ================================================================
echo   Helios II QSS Theme Generator — Release Builder
echo  ================================================================
echo.

:: ── Step 1: Find Python ───────────────────────────────────────────────────
echo  [1/5]  Locating Python...

set PYTHON=
for %%P in (python python3 py) do (
    if not defined PYTHON (
        %%P --version >nul 2>&1 && set "PYTHON=%%P"
    )
)

if not defined PYTHON (
    echo.
    echo  [ERROR] Python not found.
    echo.
    echo  Install Python 3.8+ from:
    echo    https://www.python.org/downloads/
    echo.
    echo  During install: tick "Add Python to PATH"
    echo.
    pause & exit /b 1
)

for /f "tokens=*" %%V in ('%PYTHON% --version 2^>^&1') do set PYVER=%%V
echo  [OK] Found: %PYVER%
echo.

:: ── Step 2: Install dependencies silently ────────────────────────────────
echo  [2/5]  Installing dependencies (PyQt5 + PyInstaller)...

%PYTHON% -m pip install --upgrade pip -q
%PYTHON% -m pip install PyQt5 pyinstaller --upgrade -q

if errorlevel 1 (
    echo.
    echo  [ERROR] Failed to install dependencies.
    echo  Check your internet connection and try again.
    echo.
    pause & exit /b 1
)
echo  [OK] Dependencies ready
echo.

:: ── Step 3: Clean previous build output ──────────────────────────────────
echo  [3/5]  Cleaning previous build...

if exist "build"                         rmdir /s /q "build"
if exist "dist"                          rmdir /s /q "dist"
if exist "Helios Theme Generator.spec"   del /q "Helios Theme Generator.spec"
if exist "Helios_Theme_Generator.zip"    del /q "Helios_Theme_Generator.zip"

echo  [OK] Clean
echo.

:: ── Step 4: Compile with PyInstaller ─────────────────────────────────────
echo  [4/5]  Compiling executable...
echo         (This takes 60-120 seconds, please wait)
echo.

%PYTHON% -m PyInstaller ^
    --noconfirm ^
    --onefile ^
    --windowed ^
    --name "Helios Theme Generator" ^
    --clean ^
    helios_theme_builder.py

echo.

if errorlevel 1 (
    echo  [ERROR] PyInstaller failed. See the output above for details.
    echo.
    echo  Common fixes:
    echo    1. Run this script as Administrator
    echo    2. Temporarily disable your antivirus
    echo    3. Delete build\ and dist\ and try again
    echo.
    pause & exit /b 1
)

:: Verify the exe was actually produced
if not exist "dist\Helios Theme Generator.exe" (
    echo  [ERROR] Build appeared to succeed but the .exe was not found.
    echo  Check the build\ folder for error details.
    echo.
    pause & exit /b 1
)

echo  [OK] dist\Helios Theme Generator.exe created
echo.

:: ── Step 5: Create the user release ZIP ──────────────────────────────────
echo  [5/5]  Creating user release ZIP...

:: Use PowerShell Compress-Archive — available on Windows 8.1+ (PowerShell 5+)
powershell -NoProfile -NonInteractive -Command ^
    "Compress-Archive -Path 'dist\Helios Theme Generator.exe','INSTALL.txt' -DestinationPath 'Helios_Theme_Generator.zip' -Force"

if errorlevel 1 (
    echo  [ERROR] ZIP creation failed.
    echo.
    echo  Fallback: the compiled exe is at:
    echo    dist\Helios Theme Generator.exe
    echo  Manually zip it with INSTALL.txt and distribute.
    echo.
    pause & exit /b 1
)

if not exist "Helios_Theme_Generator.zip" (
    echo  [ERROR] ZIP file was not created.
    pause & exit /b 1
)

:: ── Done ─────────────────────────────────────────────────────────────────
echo  [OK] Helios_Theme_Generator.zip created
echo.
echo  ================================================================
echo   BUILD COMPLETE
echo  ================================================================
echo.
echo   Release file:  %CD%\Helios_Theme_Generator.zip
echo.
echo   ZIP contains:
echo     Helios Theme Generator.exe
echo     INSTALL.txt
echo.
echo   Distribute Helios_Theme_Generator.zip to your users.
echo   They only need to extract it and double-click the .exe.
echo.

:: Clean up build artefacts — keep dist\ in case developer wants the raw exe
:: but remove the PyInstaller work folder and spec file
if exist "build"                         rmdir /s /q "build"
if exist "Helios Theme Generator.spec"   del /q "Helios Theme Generator.spec"

:: Open the folder so the release file is immediately visible
explorer "%CD%"
pause
exit /b 0
