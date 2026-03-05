@echo off
setlocal

echo ================================
echo   MERGE BRANCH INTO MAIN
echo ================================
echo.

set /p BRANCH=Enter branch name to merge into main: 

if "%BRANCH%"=="" (
    echo Branch name is empty!
    pause
    exit /b 1
)

echo.
echo Switching to main...
git checkout main || goto :error

echo.
echo Pulling latest main...
git pull origin main || goto :error

echo.
echo Merging %BRANCH% into main...
git merge %BRANCH%

if errorlevel 1 (
    echo.
    echo Merge failed. Possible conflicts.
    echo Resolve conflicts, then run:
    echo   git add .
    echo   git commit
    pause
    exit /b 1
)

echo.
echo Merge completed successfully.

echo.
set /p PUSH=Push to origin/main now? (y/n): 

if /I "%PUSH%"=="y" (
    git push origin main || goto :error
)

echo.
echo Done.
pause
exit /b 0

:error
echo.
echo ERROR occurred!
pause
exit /b 1