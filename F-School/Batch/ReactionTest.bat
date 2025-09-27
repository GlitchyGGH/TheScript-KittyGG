@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Reaction Test - Ready then Go
color 0A
mode con: cols=120 lines=40

:: ============================================================================
:: Reaction Test Game - Always "X.XXX seconds" + Close-on-key
:: - PowerShell stopwatch for timing (ms precision) with double buffer flush
:: - Pure CMD fallback timing if PS blocked (handles midnight rollover)
:: - Seconds formatting done in pure Batch (no PS required) -> X.XXX
:: ============================================================================

:: Relaunch with /c so the window will close after final pause when double-clicked
if not defined __WRAPPED (
  echo %CMDCMDLINE% | find /I " /c " >nul
  if not errorlevel 1 (
    set "__WRAPPED=1"
    "%ComSpec%" /v:on /c ""%~f0" %*"
    exit /b
  )
)

:: ---------- Splash ----------
cls
echo(
echo  ===============================================================
echo                 REACTION TEST (Press any key)
echo  ===============================================================
echo(
pause >nul

:: ---------- READY ----------
set "LM=   "
cls
call :BANNER_READY "%LM%"

:: Random wait = 2.500..6.450 sec (ms as integer)
for /f %%G in ('
  powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "Get-Random -Minimum 2500 -Maximum 6451"
') do set "DELAY_MS=%%G"
if not defined DELAY_MS set "DELAY_MS=3000"

:: Proactively flush keyboard buffer (best effort)
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command ^
  "try{$Host.UI.RawUI.FlushInputBuffer()}catch{}" 1>nul 2>nul

:: Sleep the randomized delay
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "Start-Sleep -Milliseconds %DELAY_MS%" 2>nul

:: ---------- GO ----------
cls
call :BANNER_GO "%LM%"

:: ---------- Stopwatch (PowerShell first) ----------
set "ELAPSE_MS="
for /f "usebackq delims=" %%M in (`powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='SilentlyContinue';" ^
  "try{" ^
  "  $Host.UI.RawUI.FlushInputBuffer();" ^
  "  [Console]::TreatControlCAsInput=$true;" ^
  "  $sw=[Diagnostics.Stopwatch]::StartNew();" ^
  "  while(-not $Host.UI.RawUI.KeyAvailable){Start-Sleep -Milliseconds 1}" ^
  "  $null=$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');" ^
  "  $sw.Stop();" ^
  "  [math]::Round($sw.Elapsed.TotalMilliseconds,0)" ^
  "}catch{''}"`) do set "ELAPSE_MS=%%M"

:: Sanitize ELAPSE_MS (trim spaces)
for /f "tokens=* delims= " %%A in ("%ELAPSE_MS%") do set "ELAPSE_MS=%%~A"

if not defined ELAPSE_MS (
  goto :FALLBACK_CMD
)

:: ---------- Format seconds in pure Batch (X.XXX) ----------
call :FORMAT_SECONDS "%ELAPSE_MS%" ELAPSE_SEC

echo(
echo   Your reaction time: %ELAPSE_SEC% seconds  (%ELAPSE_MS% ms)
echo(
echo   Press any key to close...
pause >nul
endlocal & exit /b 0

:: ---------- Fallback (pure CMD timing) ----------
:FALLBACK_CMD
setlocal EnableDelayedExpansion
set "TSTART=%TIME%"
pause >nul
set "TEND=%TIME%"
call :TIMEDIFF_MS "%TSTART%" "%TEND%" MS
endlocal & set "ELAPSE_MS=%MS%"

call :FORMAT_SECONDS "%ELAPSE_MS%" ELAPSE_SEC

echo(
echo   Your reaction time: %ELAPSE_SEC% seconds  (%ELAPSE_MS% ms)
echo(
echo   Press any key to close...
pause >nul
endlocal & exit /b 0

:: ============================================================================
:: Helpers
:: ============================================================================

:FORMAT_SECONDS
:: %1=milliseconds integer, %2=out var formatted as X.XXX
setlocal
set /a __ms=%~1
if %__ms% LSS 0 set /a __ms=0
set /a __sec=%__ms%/1000, __rem=%__ms%%%1000
set "__rem=00%__rem%"
set "__rem=%__rem:~-3%"
endlocal & set "%~2=%__sec%.%__rem%"
goto :eof

:TIMEDIFF_MS
:: %1=start time (HH:MM:SS.cc), %2=end time (HH:MM:SS.cc), %3=out var (ms)
setlocal
set "S=%~1"
set "E=%~2"
set "SH=%S:~,2%" & set "SM=%S:~3,2%" & set "SS=%S:~6,2%" & set "SC=%S:~9,2%"
set "EH=%E:~,2%" & set "EM=%E:~3,2%" & set "ES=%E:~6,2%" & set "EC=%E:~9,2%"
set /a S_MS=((1%SH% -100)*3600000) + ((1%SM% -100)*60000) + ((1%SS% -100)*1000) + ((1%SC% -100)*10)
set /a E_MS=((1%EH% -100)*3600000) + ((1%EM% -100)*60000) + ((1%ES% -100)*1000) + ((1%EC% -100)*10)
if %E_MS% LSS %S_MS% set /a E_MS+=24*3600000
set /a D_MS=E_MS - S_MS
endlocal & set "%~3=%D_MS%"
goto :eof

:PRINT
setlocal EnableDelayedExpansion
set "L=%~1"
set /p ="!L!" <nul & echo(
endlocal & goto :eof

:: ============================================================================
:: Banners
:: ============================================================================
:BANNER_READY
set "LM=%~1"
call :PRINT "%LM%########  ########    ###    ########  ##    ##  #######   #######   #######  "
call :PRINT "%LM%##     ## ##         ## ##   ##     ##  ##  ##  ##     ## ##     ## ##     ## "
call :PRINT "%LM%##     ## ##        ##   ##  ##     ##   ####         ##        ##        ##  "
call :PRINT "%LM%########  ######   ##     ## ##     ##    ##        ###       ###       ###   "
call :PRINT "%LM%##   ##   ##       ######### ##     ##    ##       ##        ##        ##     "
call :PRINT "%LM%##    ##  ##       ##     ## ##     ##    ##                                  "
call :PRINT "%LM%##     ## ######## ##     ## ########     ##       ##        ##        ##     "
echo(
goto :eof

:BANNER_GO
set "LM=%~1"
call :PRINT "%LM%_______  _______                   "
call :PRINT "%LM%|       ||       |                  "
call :PRINT "%LM%|    ___||   _   |                  "
call :PRINT "%LM%|   | __ |  | |  |                  "
call :PRINT "%LM%|   ||  ||  |_|  | ___   ___   ___  "
call :PRINT "%LM%|   |_| ||       ||   | |   | |   | "
call :PRINT "%LM%|_______||_______||___| |___| |___| "
echo(
goto :eof

