@echo off
:: Generate a unique filename with timestamp
set "filename=Note_%date:~-4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt"
set "filename=%filename: =0%"

:: Create blank file
echo. > "%filename%"

:: Open it in Notepad
start notepad "%filename%"
exit
