@echo off

echo Choose the platform to build for:
echo 1. Windows (exe)
echo 2. Android (apk)

set /p choice="Choose 1 or 2: "

if not "%choice%"=="1" if not "%choice%"=="2" (
    echo Invalid choice.
    pause
    exit /b
)

set /p bump_version="Up version? (y/n): "

if "%bump_version%"=="y" (
    call cider bump build || exit /b
)

if "%choice%"=="1" (
    fastforge package --platform windows --targets exe
) else if "%choice%"=="2" (
    flutter build apk --flavor prod --release
)

pause
