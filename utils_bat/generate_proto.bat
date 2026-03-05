@echo off

REM Paths
set PROTO_DIR=D:\Projects\hoplixi\assets
set OUT_DIR=D:\Projects\hoplixi\lib\generated\migration_otp

echo ===============================
echo Generating Dart protobuf files
echo ===============================

protoc ^
  -I=%PROTO_DIR% ^
  --dart_out=%OUT_DIR% ^
  %PROTO_DIR%\migration-payload-otp.proto

IF %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ Protobuf generation failed.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ✅ Done!
pause
