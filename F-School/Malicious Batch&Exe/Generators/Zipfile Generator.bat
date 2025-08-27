@echo off
setlocal

set ZIPNAME=myArchive.zip
set SRCDIR=files\

:: Create the zip
tar -a -c -f "%ZIPNAME%" "%SRCDIR%"

echo Done! %ZIPNAME% created.
pause
