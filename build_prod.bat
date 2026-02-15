@echo off

echo Choose the platform to build for:
echo 1. Windows (exe)
echo 2. Android (apk)

set /p choice="Choose 1 or 2: "

if "%choice%"=="1" (
    fastforge package --platform windows --targets exe
) else if "%choice%"=="2" (
    call cider bump build || exit /b
    flutter build apk --flavor prod --release
) else (
    echo Invalid choice.
)

pause
