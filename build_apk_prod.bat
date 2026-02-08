@echo on

call cider bump build || exit /b

flutter build apk --flavor prod --release

pause
