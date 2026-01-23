@echo off
setlocal

REM ====== CONFIG ======
set KEYSTORE_NAME=upload-keystore.jks
set ALIAS_NAME=upload
set KEY_SIZE=2048
set VALIDITY_DAYS=10000
set KEY_ALG=RSA

REM ====== CHECK keytool ======
where keytool >nul 2>&1
if errorlevel 1 (
    echo ERROR: keytool not found. Make sure JDK is installed and added to PATH.
    pause
    exit /b 1
)

REM ====== GENERATE KEYSTORE ======
keytool -genkeypair -v ^
 -keystore %KEYSTORE_NAME% ^
 -alias %ALIAS_NAME% ^
 -keyalg %KEY_ALG% ^
 -keysize %KEY_SIZE% ^
 -validity %VALIDITY_DAYS%

REM ====== DONE ======
echo.
echo Keystore "%KEYSTORE_NAME%" successfully created.
echo IMPORTANT: Make a backup of this file!
pause
endlocal
