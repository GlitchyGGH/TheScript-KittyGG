@echo off
setlocal EnableDelayedExpansion
title Blackjack (Batch)
:menu
cls
echo ===========================
echo        BLACKJACK
echo ===========================
echo   [P] Play  [Q] Quit
choice /c PQ /n >nul
if errorlevel 2 exit /b
goto :play

:play
set scoreP=0
set scoreD=0
set flags=
call :dealCard P
call :dealCard P
call :dealCard D
call :dealCard D

:turn
cls
echo Your hand: !handP!  (^=!scoreP!^)
echo Dealer shows: !firstD! and [?]
if !scoreP! gtr 21 echo You bust! Dealer wins.& goto :again
echo.
echo [H]it  [S]tand
choice /c HS /n >nul
if errorlevel 2 goto :dealer
call :dealCard P
goto :turn

:dealer
rem Dealer hits to 17+
for /l %%# in (1,1,10) do (
  if !scoreD! lss 17 call :dealCard D
)

cls
echo Your hand:   !handP!  (^=!scoreP!^)
echo Dealer hand: !handD!  (^=!scoreD!^)
echo.

if !scoreD! gtr 21 echo Dealer busts! You win!& goto :again
if !scoreP! gtr !scoreD! echo You win!& goto :again
if !scoreP! lss !scoreD! echo Dealer wins!& goto :again
echo Push (tie).
goto :again

:again
echo.
echo [P]lay again  [Q]uit
choice /c PQ /n >nul
if errorlevel 2 exit /b
set handP=
set handD=
set firstD=
goto :play

:: ---------- Helpers ----------
:dealCard
rem %1 = P or D
set who=%1
call :randCard rank suit
call :cardValue !rank! val
if "!who!"=="P" (
  if not defined handP (set handP=!rank!!suit!) else set handP=!handP!, !rank!!suit!
  call :addScore scoreP !val! !rank!
) else (
  if not defined handD (set handD=!rank!!suit!) else set handD=!handD!, !rank!!suit!
  if not defined firstD set firstD=!rank!!suit!
  call :addScore scoreD !val! !rank!
)
exit /b

:randCard
rem Outputs: rank (A,2..10,J,Q,K) and suit (♠♥♦♣ approximated as S,H,D,C)
set /a r=%random% %% 13
set /a s=%random% %% 4
for %%A in (A 2 3 4 5 6 7 8 9 10 J Q K) do (
  if !r!==0 (set rank=%%A& set r=99)
  set /a r-=1
)
for %%S in (S H D C) do (
  if !s!==0 (set suit=%%S& set s=99)
  set /a s-=1
)
exit /b

:cardValue
rem %1=rank -> %2=val
set r=%1
if "%r%"=="A" (set %2=11& exit /b)
if "%r%"=="K" (set %2=10& exit /b)
if "%r%"=="Q" (set %2=10& exit /b)
if "%r%"=="J" (set %2=10& exit /b)
if "%r%"=="10" (set %2=10& exit /b)
if "%r%"=="9" (set %2=9& exit /b)
if "%r%"=="8" (set %2=8& exit /b)
if "%r%"=="7" (set %2=7& exit /b)
if "%r%"=="6" (set %2=6& exit /b)
if "%r%"=="5" (set %2=5& exit /b)
if "%r%"=="4" (set %2=4& exit /b)
if "%r%"=="3" (set %2=3& exit /b)
if "%r%"=="2" (set %2=2& exit /b)
exit /b

:addScore
rem %1=scoreVar  %2=val  %3=rank
set v=!%1!
set /a v+=%2%
rem Handle Aces high->low
if "%3%"=="A" (
  set /a aces=!%1!Aces+1
  set %1Aces=!aces!
)
set %1=%v%
:reduce
if !%1! gtr 21 if defined %1Aces (
  set /a %1-=%1Aces>nul
)
if !%1! gtr 21 if defined %1Aces (
  set /a %1-=10
  set /a %1Aces-=1
  goto :reduce
)
exit /b
