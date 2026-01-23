@echo off
setlocal

REM Переход в папку android проекта
cd /d %~dp0android

REM Проверка наличия keytool
where keytool >nul 2>nul
if errorlevel 1 (
    echo [ERROR] keytool not found. Install JDK and add it to PATH.
    pause
    exit /b 1
)

REM Создание debug.keystore
keytool -genkey -v ^
 -keystore app\debug.keystore ^
 -storepass android ^
 -alias androiddebugkey ^
 -keypass android ^
 -keyalg RSA ^
 -keysize 2048 ^
 -validity 10000 ^
 -dname "CN=Android Debug,O=Android,C=US"

echo.
echo [OK] debug.keystore created at android\app\debug.keystore
pause
endlocal
