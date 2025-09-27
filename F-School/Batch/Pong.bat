@echo off
setlocal EnableExtensions EnableDelayedExpansion

mode con: cols=70 lines=26 >nul 2>&1

rem Game settings
set "WIDTH=68"
set "HEIGHT=22"
set "PADDLE_SIZE=1"
set "LEFT_X=3"
set "RIGHT_X=66"
set "BALL_CHAR=O"
set "PADDLE_CHAR=|"
set "WALL_CHAR=#"
set "EMPTY_CHAR= "
set "INITIAL_DELAY_MS=15"
set "MIN_DELAY_MS=5"
set "SPEEDUP_HIT_INTERVAL=3"
set "SPEEDUP_STEP_MS=3"

set /a "TOP_HUD_ROW=2"
set /a "BOTTOM_BOUNCE=HEIGHT-1"
set /a "PADDLE_MAX_TOP=HEIGHT-PADDLE_SIZE-1"

rem Initialize
set /a "leftY=HEIGHT/2"
set /a "rightY=HEIGHT/2"
set /a "ballX=WIDTH/2", "ballY=HEIGHT/2"
set /a "dx=1", "dy=1"
set /a "leftScore=0", "rightScore=0"
set /a "delayMs=INITIAL_DELAY_MS"
set /a "hitCount=0"

cls
echo ################ ASCII PONG ################
echo(
echo Controls: Left=W/S, Right=Up/Down, Q quits anytime
echo(
<nul set /p "=Press any key to play (Q to quit)... "
for /f "usebackq delims=" %%K in (`powershell -NoProfile -Command "[Console]::ReadKey($true).Key"`) do set "KEY=%%K"
if /i "!KEY!"=="Q" goto game_over
cls

:game_loop
for /f "usebackq delims=" %%K in (`powershell -NoProfile -Command "$k=$null; if([Console]::KeyAvailable){$k=[Console]::ReadKey($true).Key}; if($k){$k}else{'NONE'}"`) do set "KEY=%%K"

if /i "!KEY!"=="Q" goto game_over

rem Left paddle: W/S
if /i "!KEY!"=="W" if !leftY! gtr 1 set /a "leftY-=1"
if /i "!KEY!"=="S" if !leftY! lss !PADDLE_MAX_TOP! set /a "leftY+=1"

rem Right paddle: Up/Down
if /i "!KEY!"=="UpArrow" if !rightY! gtr 1 set /a "rightY-=1"
if /i "!KEY!"=="DownArrow" if !rightY! lss !PADDLE_MAX_TOP! set /a "rightY+=1"

rem Ball physics
set /a "nextX=ballX+dx", "nextY=ballY+dy"

if !nextY! leq !TOP_HUD_ROW! set /a "dy=1", "nextY=ballY+dy"
if !nextY! geq !BOTTOM_BOUNCE! set /a "dy=-1", "nextY=ballY+dy"

rem Left paddle collision (single cell)
if !dx! lss 0 if !nextX! leq !LEFT_X! (
  if !ballY! equ !leftY! (
    set /a "dx=1", "nextX=ballX+dx", "hitCount+=1"
    set /a "offset=ballY-leftY"
    if !offset! lss 0 set /a "dy=-1"
    if !offset! gtr 0 set /a "dy=1"
  ) else (
    if !nextX! lss 1 (
      set /a "rightScore+=1"
      call :reset_round -1
      goto draw
    )
  )
)

rem Right paddle collision (single cell)
if !dx! gtr 0 if !nextX! geq !RIGHT_X! (
  if !ballY! equ !rightY! (
    set /a "dx=-1", "nextX=ballX+dx", "hitCount+=1"
    set /a "offset=ballY-rightY"
    if !offset! lss 0 set /a "dy=-1"
    if !offset! gtr 0 set /a "dy=1"
  ) else (
    if !nextX! gtr !WIDTH! (
      set /a "leftScore+=1"
      call :reset_round 1
      goto draw
    )
  )
)

if !nextX! lss 1 (
  set /a "rightScore+=1"
  call :reset_round -1
  goto draw
)
if !nextX! gtr !WIDTH! (
  set /a "leftScore+=1"
  call :reset_round 1
  goto draw
)

if !hitCount! geq !SPEEDUP_HIT_INTERVAL! (
  set /a "hitCount=0", "delayMs-=SPEEDUP_STEP_MS"
  if !delayMs! lss !MIN_DELAY_MS! set /a "delayMs=MIN_DELAY_MS"
)

set /a "ballX=nextX", "ballY=nextY"

:draw
cls

rem Top border
set "line="
for /l %%X in (1,1,!WIDTH!) do set "line=!line!!WALL_CHAR!"
echo(!line!

rem HUD
set "scoreLine=  L:!leftScore!   R:!rightScore!    W/S & Up/Down, Q quits"
echo(!scoreLine!

for /l %%Y in (3,1,!HEIGHT!-1) do (
  set "line="
  for /l %%X in (1,1,!WIDTH!) do (
    set "ch=!EMPTY_CHAR!"
    if %%X==1 set "ch=!WALL_CHAR!"
    if %%X==!WIDTH! set "ch=!WALL_CHAR!"

    rem Left paddle (1 high)
    if %%X==!LEFT_X! if %%Y equ !leftY! set "ch=!PADDLE_CHAR!"

    rem Right paddle (1 high)
    if %%X==!RIGHT_X! if %%Y equ !rightY! set "ch=!PADDLE_CHAR!"

    if %%X==!ballX! if %%Y==!ballY! set "ch=!BALL_CHAR!"
    set "line=!line!!ch!"
  )
  echo(!line!
)

rem Bottom border
set "line="
for /l %%X in (1,1,!WIDTH!) do set "line=!line!!WALL_CHAR!"
echo(!line!

powershell -NoProfile -Command "Start-Sleep -Milliseconds !delayMs!" >nul
goto game_loop

:reset_round
set /a "ballX=WIDTH/2", "ballY=HEIGHT/2", "dx=%~1", "dy=(%RANDOM%&1)*2-1"
set /a "delayMs=INITIAL_DELAY_MS", "hitCount=0"
exit /b

:game_over
cls
echo ################ ASCII PONG ################
echo(
echo Final Score: Left !leftScore!  -  Right !rightScore!
echo(
echo Thanks for playing!
echo(
endlocal
exit /b