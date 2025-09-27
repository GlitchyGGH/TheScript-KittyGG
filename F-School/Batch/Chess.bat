@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: Check if script was double-clicked, if so relaunch with cmd /k to keep window open
if /i "%~1" neq "keep_open" (
    start "Batch Chess" cmd /k ""%~f0" keep_open"
    exit /b
)

title Batch chess — stable
color 0F
cls

:: Create rules file on desktop
set "desktopPath=%USERPROFILE%\Desktop"
set "rulesFile=%desktopPath%\Batch Chess Rules.txt"

echo Creating chess rules file on desktop...
(
echo :Batch Chess Rules:
echo.
echo CHESS RULES OVERVIEW:
echo.
echo OBJECTIVE: Checkmate the opponent's king
echo.
echo PIECE MOVEMENTS:
echo - King: One square in any direction
echo - Queen: Any number of squares in any direction
echo - Rook: Any number of squares horizontally or vertically  
echo - Bishop: Any number of squares diagonally
echo - Knight: L-shaped move ^(2 squares in one direction, 1 in perpendicular^)
echo - Pawn: ONE SQUARE FORWARD ONLY ^(cannot move 2 squares from start^)
echo         Captures diagonally forward one square
echo.
echo SPECIAL MOVES:
echo - Castling: King and rook move simultaneously ^(king moves 2 squares toward rook^)
echo   Requirements: Neither piece has moved, no pieces between them, king not in check
echo - En Passant: Capture pawn that just moved 2 squares as if it moved 1
echo - Promotion: Pawn reaching opposite end promotes to queen, rook, bishop, or knight
echo.
echo GAME RULES:
echo - Cannot move into check
echo - Must get out of check if in check
echo - Checkmate = game over
echo - Stalemate = draw ^(no legal moves but not in check^)
echo.
echo INPUT FORMAT: Use algebraic notation
echo Examples: e2e3, a7a6, e1g1 ^(castling^), e7e8q ^(promotion to queen^)
) > "%rulesFile%"

echo Chess game initialized successfully.
timeout /t 2 >nul

:: 1-6  = white: 1K 2Q 3R 4B 5N 6P
:: 7-12 = black: 7K 8Q 9R 10B 11N 12P
set "currentPlayer=white"
set "moveCount=0"

:: Castling rights (1=allowed)
set "wK=1" & set "wQ=1" & set "bK=1" & set "bQ=1"
:: En passant target (-1,-1 = none)
set "enPassantR=-1" & set "enPassantC=-1"

:: ===== Initial board =====
:: Black
set "pos_0_0=9" & set "pos_0_1=11" & set "pos_0_2=10" & set "pos_0_3=8" & set "pos_0_4=7" & set "pos_0_5=10" & set "pos_0_6=11" & set "pos_0_7=9"
set "pos_1_0=12" & set "pos_1_1=12" & set "pos_1_2=12" & set "pos_1_3=12" & set "pos_1_4=12" & set "pos_1_5=12" & set "pos_1_6=12" & set "pos_1_7=12"

:: Empty
for /L %%r in (2,1,5) do for /L %%c in (0,1,7) do set "pos_%%r_%%c=0"

:: White
set "pos_6_0=6" & set "pos_6_1=6" & set "pos_6_2=6" & set "pos_6_3=6" & set "pos_6_4=6" & set "pos_6_5=6" & set "pos_6_6=6" & set "pos_6_7=6"
set "pos_7_0=3" & set "pos_7_1=5" & set "pos_7_2=4" & set "pos_7_3=2" & set "pos_7_4=1" & set "pos_7_5=4" & set "pos_7_6=5" & set "pos_7_7=3"

:: ===== Symbols =====
set "symbolMap_0=.."
set "symbolMap_1=wK"
set "symbolMap_2=wQ"
set "symbolMap_3=wR"
set "symbolMap_4=wB"
set "symbolMap_5=wN"
set "symbolMap_6=wP"
set "symbolMap_7=bK"
set "symbolMap_8=bQ"
set "symbolMap_9=bR"
set "symbolMap_10=bB"
set "symbolMap_11=bN"
set "symbolMap_12=bP"

:gameLoop
cls
echo.
echo     +--------------------------+
echo     ^|        Batch chess       ^|
echo     +--------------------------+
echo.

call :displayBoard

:: Banner for side to move
call :isKingInCheck "%currentPlayer%" __chk__
set "statusMsg="
if "!__chk__!"=="true" set "statusMsg=   ** IN CHECK **"
echo.
echo Side: %currentPlayer%   Moves: %moveCount%   Note: Pawns can only move 1 space instead of 2 at start!statusMsg!
echo.
echo Make a move: Example, ("e2e3")
set "move="
set /p "move=> "

if /i "%move%"=="quit" goto :end
if /i "%move%"=="exit" goto :end

call :processMove "%move%"
goto :gameLoop

:: ============================ DISPLAY ============================
:displayBoard
echo    a  b  c  d  e  f  g  h
echo   +------------------------+
for /L %%r in (0,1,7) do (
  set /a "rank=8-%%r"
  set "line=!rank! ^|"
  for /L %%c in (0,1,7) do (
    call :getPieceSymbol !pos_%%r_%%c! symbol
    set "line=!line!!symbol! "
  )
  set "line=!line!^| !rank!"
  echo !line!
)
echo   +------------------------+
echo    a  b  c  d  e  f  g  h
goto :eof

:getPieceSymbol
set "piece=%~1"
call set "%2=%%symbolMap_!piece!%%"
goto :eof

:: ============================ INPUT ============================
:processMove
set "moveStr=%~1"
set "from=!moveStr:~0,2!"
set "to=!moveStr:~2,2!"
set "promoChar=!moveStr:~4,1!"
if defined promoChar set "promoChar=!promoChar:~0,1!"
if not defined promoChar set "promoChar=q"

call :algebraicToCoords "%from%" fromRow fromCol
call :algebraicToCoords "%to%"   toRow   toCol

if !fromRow!==-1 (echo Invalid from; pause & goto :eof)
if !toRow!==-1   (echo Invalid to;   pause & goto :eof)

call set "piece=%%pos_!fromRow!_!fromCol!%%"
if !piece!==0 (echo No piece at %from%! & pause & goto :eof)

:: Ownership
if "%currentPlayer%"=="white" (
  if !piece! gtr 6 (echo That's not your piece! & pause & goto :eof)
) else (
  if !piece! leq 6 (echo That's not your piece! & pause & goto :eof)
)

:: Destination occupancy
call set "targetPiece=%%pos_!toRow!_!toCol!%%"
if "%currentPlayer%"=="white" (
  if !targetPiece! geq 1 if !targetPiece! leq 6 (echo Cannot capture your own piece! & pause & goto :eof)
) else (
  if !targetPiece! geq 7 if !targetPiece! leq 12 (echo Cannot capture your own piece! & pause & goto :eof)
)

:: Pseudo-legal validation
set "moveType=normal"
call :validateMove !piece! !fromRow! !fromCol! !toRow! !toCol! "!promoChar!" isValid
if "!isValid!" neq "true" (echo Invalid move! & pause & goto :eof)

:: Snapshot for undo (why: self-check filter)
set "undo_fromR=!fromRow!" & set "undo_fromC=!fromCol!" & set "undo_toR=!toRow!" & set "undo_toC=!toCol!"
set "undo_piece=!piece!" & set "undo_captured=!targetPiece!" & set "undo_moveType=!moveType!"
set "undo_enR=!enPassantR!" & set "undo_enC=!enPassantC!"
set "undo_wK=!wK!" & set "undo_wQ=!wQ!" & set "undo_bK=!bK!" & set "undo_bQ=!bQ!"
set "undo_extra=none"

:: Apply temporarily, then verify king safety
call :applyMove !piece! !fromRow! !fromCol! !toRow! !toCol! "!moveType!" "!promoChar!" !targetPiece!

call :isKingInCheck "%currentPlayer%" inCheckAfter
if "!inCheckAfter!"=="true" (
  call :undoMove
  echo Illegal: leaves king in check!
  pause
  goto :eof
)

:: Did we give check?
call :otherSide "%currentPlayer%" opp
call :isKingInCheck "!opp!" oppCheck

:: Commit (already applied)
if "%currentPlayer%"=="white" (set "currentPlayer=black") else (set "currentPlayer=white")
set /a "moveCount+=1"

if "!oppCheck!"=="true" (
  echo Move: %moveStr%  --  CHECK!
) else (
  echo Move: %moveStr%
)
timeout /t 1 >nul
goto :eof

:: ============================ VALIDATION ============================
:validateMove
set "piece=%~1" & set "fromR=%~2" & set "fromC=%~3" & set "toR=%~4" & set "toC=%~5" & set "promo=%~6" & set "out=%~7"
set /a "deltaR=toR-fromR", "deltaC=toC-fromC"
set /a "absR=deltaR", "absC=deltaC"
if !absR! lss 0 set /a "absR=-absR"
if !absC! lss 0 set /a "absC=-absC"

set /a "ptype=piece"
if !ptype! gtr 6 set /a "ptype-=6"
set "%out%=false"

if !ptype!==1 goto :vKing
if !ptype!==2 goto :vQueen
if !ptype!==3 goto :vRook
if !ptype!==4 goto :vBishop
if !ptype!==5 goto :vKnight
if !ptype!==6 goto :vPawn
goto :eof

:vKing
if !absR! leq 1 if !absC! leq 1 if not !absR!==0 if not !absC!==0 (set "%out%=true" & set "moveType=normal" & goto :eof)
if !absR!==0 if !absC!==1 (set "%out%=true" & set "moveType=normal" & goto :eof)
if !absR!==1 if !absC!==0 (set "%out%=true" & set "moveType=normal" & goto :eof)
:: Castling
if !absR!==0 if !absC!==2 (
  set "side=white"
  if !piece! gtr 6 set "side=black"
  set "dir=1"
  if !deltaC! lss 0 set "dir=-1"
  set /a "midC=fromC+dir", "endC=fromC+(2*dir)"

  if "!side!"=="white" ( if !dir!==1 (set "right=!wK!") else (set "right=!wQ!") ) else ( if !dir!==1 (set "right=!bK!") else (set "right=!bQ!") )
  if "!right!"=="1" (
    call :checkPath !fromR! !fromC! !toR! !toC! pathClear
    if "!pathClear!"=="true" (
      call :otherSide "%currentPlayer%" opp
      call :isSquareAttacked !fromR! !fromC! "!opp!" a1
      call :isSquareAttacked !fromR! !midC!   "!opp!" a2
      call :isSquareAttacked !toR!   !toC!    "!opp!" a3
      if "!a1!!a2!!a3!"=="falsefalsefalse" (
        set "%out%=true"
        if !dir!==1 (set "moveType=castleK") else (set "moveType=castleQ")
        goto :eof
      )
    )
  )
)
set "%out%=false"
goto :eof

:vQueen
call :vRook  %piece% %fromR% %fromC% %toR% %toC% %out%
if "!%out%!"=="true" (set "moveType=normal" & goto :eof)
call :vBishop %piece% %fromR% %fromC% %toR% %toC% %out%
if "!%out%!"=="true" (set "moveType=normal" & goto :eof)
set "%out%=false"
goto :eof

:vRook
if !deltaR!==0 if not !deltaC!==0 (
  call :checkPath %fromR% %fromC% %toR% %toC% ok
  if "!ok!"=="true" (set "%out%=true" & set "moveType=normal") else (set "%out%=false")
  goto :eof
) else if !deltaC!==0 if not !deltaR!==0 (
  call :checkPath %fromR% %fromC% %toR% %toC% ok
  if "!ok!"=="true" (set "%out%=true" & set "moveType=normal") else (set "%out%=false")
  goto :eof
)
set "%out%=false"
goto :eof

:vBishop
if !absR!==!absC! if not !deltaR!==0 (
  call :checkPath %fromR% %fromC% %toR% %toC% ok
  if "!ok!"=="true" (set "%out%=true" & set "moveType=normal") else (set "%out%=false")
) else set "%out%=false"
goto :eof

:vKnight
if !absR!==2 if !absC!==1 (set "%out%=true" & set "moveType=normal" & goto :eof)
if !absR!==1 if !absC!==2 (set "%out%=true" & set "moveType=normal" & goto :eof)
set "%out%=false"
goto :eof

:vPawn
set "side=white"
set "step=-1"
set /a "home=6", "promoRank=0"
if !piece! gtr 6 (set "side=black" & set "step=1" & set /a "home=1","promoRank=7")

:: Forward one ONLY (no two-square pawn moves)
if !deltaC!==0 if !deltaR!==!step! (
  call set "t=%%pos_!toR!_!toC!%%"
  if !t!==0 (
    if !toR!==!promoRank! (set "%out%=true" & set "moveType=promotion") else (set "%out%=true" & set "moveType=normal")
    goto :eof
  )
)

:: Diagonal capture or en-passant
if !absC!==1 if !deltaR!==!step! (
  call set "t=%%pos_!toR!_!toC!%%"
  if "!side!"=="white" (
    if !t! geq 7 if !t! leq 12 (
      if !toR!==!promoRank! (set "%out%=true" & set "moveType=promotion") else (set "%out%=true" & set "moveType=normal")
      goto :eof
    )
  ) else (
    if !t! geq 1 if !t! leq 6 (
      if !toR!==!promoRank! (set "%out%=true" & set "moveType=promotion") else (set "%out%=true" & set "moveType=normal")
      goto :eof
    )
  )
  if !t!==0 if !toR!==!enPassantR! if !toC!==!enPassantC! (
    set "%out%=true" & set "moveType=enpassant"
    goto :eof
  )
)
set "%out%=false"
goto :eof

:: ============================ PATH ============================
:checkPath
set "startR=%~1" & set "startC=%~2" & set "endR=%~3" & set "endC=%~4" & set "out=%~5"
set /a "dR=endR-startR", "dC=endC-startC"
set "sR=0" & set "sC=0"
if !dR! gtr 0 set "sR=1"
if !dR! lss 0 set "sR=-1"
if !dC! gtr 0 set "sC=1"
if !dC! lss 0 set "sC=-1"
set /a "r=startR+sR", "c=startC+sC"
:__cp_loop
if !r!==!endR! if !c!==!endC! (set "%out%=true" & goto :eof)
if !r! lss 0 (set "%out%=false" & goto :eof)
if !r! gtr 7 (set "%out%=false" & goto :eof)
if !c! lss 0 (set "%out%=false" & goto :eof)
if !c! gtr 7 (set "%out%=false" & goto :eof)
call set "sq=%%pos_!r!_!c!%%"
if !sq! neq 0 (set "%out%=false" & goto :eof)
set /a "r+=sR", "c+=sC"
goto :__cp_loop

:: ============================ APPLY / UNDO ============================
:applyMove
set "piece=%~1" & set "fromR=%~2" & set "fromC=%~3" & set "toR=%~4" & set "toC=%~5" & set "mtype=%~6" & set "promo=%~7" & set "cap=%~8"
set "side=white"
if !piece! gtr 6 set "side=black"

:: reset EP each move
set "enPassantR=-1" & set "enPassantC=-1"

:: Castling rook move
if /i "!mtype!"=="castleK" (
  if "!side!"=="white" (set "rookFromR=7" & set "rookFromC=7" & set "rookToR=7" & set "rookToC=5") else (set "rookFromR=0" & set "rookFromC=7" & set "rookToR=0" & set "rookToC=5")
  call set "rf=%%pos_!rookFromR!_!rookFromC!%%"
  set "undo_extra=castle"
  set "undo_rookFromR=!rookFromR!" & set "undo_rookFromC=!rookFromC!" & set "undo_rookToR=!rookToR!" & set "undo_rookToC=!rookToC!" & set "undo_rookPiece=!rf!"
  set "pos_!rookToR!_!rookToC!=!rf!"
  set "pos_!rookFromR!_!rookFromC!=0"
)
if /i "!mtype!"=="castleQ" (
  if "!side!"=="white" (set "rookFromR=7" & set "rookFromC=0" & set "rookToR=7" & set "rookToC=3") else (set "rookFromR=0" & set "rookFromC=0" & set "rookToR=0" & set "rookToC=3")
  call set "rf=%%pos_!rookFromR!_!rookFromC!%%"
  set "undo_extra=castle"
  set "undo_rookFromR=!rookFromR!" & set "undo_rookFromC=!rookFromC!" & set "undo_rookToR=!rookToR!" & set "undo_rookToC=!rookToC!" & set "undo_rookPiece=!rf!"
  set "pos_!rookToR!_!rookToC!=!rf!"
  set "pos_!rookFromR!_!rookFromC!=0"
)

:: En-passant capture removal
if /i "!mtype!"=="enpassant" (
  set "undo_extra=enpassant"
  if "!side!"=="white" (set /a "capR=toR+1") else (set /a "capR=toR-1")
  set /a "capC=toC"
  call set "capPawn=%%pos_!capR!_!capC!%%"
  set "undo_epCapR=!capR!" & set "undo_epCapC=!capC!" & set "undo_epCapPiece=!capPawn!"
  set "pos_!capR!_!capC!=0"
)

:: Promotion
set "finalPiece=!piece!"
if /i "!mtype!"=="promotion" call :promotionPiece !piece! "!promo!" finalPiece

:: Move the piece
set "pos_!toR!_!toC!=!finalPiece!"
set "pos_!fromR!_!fromC!=0"

:: Update castling rights
if "!side!"=="white" (
  if !piece!==1 (set "wK=0" & set "wQ=0")
  if !piece!==3 (
    if !fromR!==7 if !fromC!==0 set "wQ=0"
    if !fromR!==7 if !fromC!==7 set "wK=0"
  )
  if !cap!==9  if !toR!==0 if !toC!==0 set "bQ=0"
  if !cap!==9  if !toR!==0 if !toC!==7 set "bK=0"
) else (
  if !piece!==7 (set "bK=0" & set "bQ=0")
  if !piece!==9 (
    if !fromR!==0 if !fromC!==0 set "bQ=0"
    if !fromR!==0 if !fromC!==7 set "bK=0"
  )
  if !cap!==3  if !toR!==7 if !toC!==0 set "wQ=0"
  if !cap!==3  if !toR!==7 if !toC!==7 set "wK=0"
)

:: No more 2-square pawn moves, so no EP targets set
goto :eof

:undoMove
set "pos_!undo_fromR!_!undo_fromC!=!undo_piece!"
set "pos_!undo_toR!_!undo_toC!=!undo_captured!"
if /i "!undo_extra!"=="castle" (
  set "pos_!undo_rookFromR!_!undo_rookFromC!=!undo_rookPiece!"
  set "pos_!undo_rookToR!_!undo_rookToC!=0"
)
if /i "!undo_extra!"=="enpassant" (
  set "pos_!undo_epCapR!_!undo_epCapC!=!undo_epCapPiece!"
)
set "wK=!undo_wK!" & set "wQ=!undo_wQ!" & set "bK=!undo_bK!" & set "bQ=!undo_bQ!"
set "enPassantR=!undo_enR!" & set "enPassantC=!undo_enC!"
goto :eof

:promotionPiece
:: why: default to queen if invalid/omitted
set "mover=%~1" & set "ch=%~2" & set "out=%~3"
set "ch=!ch:~0,1!"
if not defined ch set "ch=q"
if /i "%ch%" neq "q" if /i "%ch%" neq "r" if /i "%ch%" neq "b" if /i "%ch%" neq "n" set "ch=q"
if %mover% leq 6 (
  if /i "%ch%"=="q" set "np=2"
  if /i "%ch%"=="r" set "np=3"
  if /i "%ch%"=="b" set "np=4"
  if /i "%ch%"=="n" set "np=5"
) else (
  if /i "%ch%"=="q" set "np=8"
  if /i "%ch%"=="r" set "np=9"
  if /i "%ch%"=="b" set "np=10"
  if /i "%ch%"=="n" set "np=11"
)
set "%out%=%np%"
goto :eof

:: ============================ CHECK / ATTACK ============================
:isKingInCheck
set "side=%~1" & set "out=%~2"
call :findKing "!side!" kR kC
if !kR!==-1 (set "%out%=false" & goto :eof)
call :otherSide "!side!" opp
call :isSquareAttacked !kR! !kC! "!opp!" attacked
set "%out%=!attacked!"
goto :eof

:findKing
set "side=%~1" & set "rowVar=%~2" & set "colVar=%~3"
set "kp=1"
if /i "!side!"=="black" set "kp=7"
for /L %%r in (0,1,7) do for /L %%c in (0,1,7) do (
  call set "p=%%pos_%%r_%%c%%"
  if !p!==!kp! (set "%rowVar%=%%r" & set "%colVar%=%%c" & goto :eof)
)
set "%rowVar%=-1" & set "%colVar%=-1"
goto :eof

:isSquareAttacked
set "r=%~1" & set "c=%~2" & set "by=%~3" & set "out=%~4"
set "%out%=false"

:: Knights
for %%A in (2 -2) do for %%B in (1 -1) do (
  set /a "rr=r+%%A", "cc=c+%%B"
  call :__attack_is_piece !rr! !cc! "!by!" knight hit
  if "!hit!"=="true" (set "%out%=true" & goto :eof)
)
for %%A in (1 -1) do for %%B in (2 -2) do (
  set /a "rr=r+%%A", "cc=c+%%B"
  call :__attack_is_piece !rr! !cc! "!by!" knight hit
  if "!hit!"=="true" (set "%out%=true" & goto :eof)
)

:: King adjacency (explicit checks for all 8 squares)
set /a "rr=r-1", "cc=c-1"
call :__attack_is_piece !rr! !cc! "!by!" king kHit
if "!kHit!"=="true" (set "%out%=true" & goto :eof)

set /a "rr=r-1", "cc=c"
call :__attack_is_piece !rr! !cc! "!by!" king kHit
if "!kHit!"=="true" (set "%out%=true" & goto :eof)

set /a "rr=r-1", "cc=c+1"
call :__attack_is_piece !rr! !cc! "!by!" king kHit
if "!kHit!"=="true" (set "%out%=true" & goto :eof)

set /a "rr=r", "cc=c-1"
call :__attack_is_piece !rr! !cc! "!by!" king kHit
if "!kHit!"=="true" (set "%out%=true" & goto :eof)

set /a "rr=r", "cc=c+1"
call :__attack_is_piece !rr! !cc! "!by!" king kHit
if "!kHit!"=="true" (set "%out%=true" & goto :eof)

set /a "rr=r+1", "cc=c-1"
call :__attack_is_piece !rr! !cc! "!by!" king kHit
if "!kHit!"=="true" (set "%out%=true" & goto :eof)

set /a "rr=r+1", "cc=c"
call :__attack_is_piece !rr! !cc! "!by!" king kHit
if "!kHit!"=="true" (set "%out%=true" & goto :eof)

set /a "rr=r+1", "cc=c+1"
call :__attack_is_piece !rr! !cc! "!by!" king kHit
if "!kHit!"=="true" (set "%out%=true" & goto :eof)

:: Pawns
if /i "!by!"=="white" (
  set /a "rr=r+1", "cc=c-1"
  call :__attack_is_piece !rr! !cc! "!by!" pawn pHit
  if "!pHit!"=="true" (set "%out%=true" & goto :eof)
  set /a "rr=r+1", "cc=c+1"
  call :__attack_is_piece !rr! !cc! "!by!" pawn pHit
  if "!pHit!"=="true" (set "%out%=true" & goto :eof)
) else (
  set /a "rr=r-1", "cc=c-1"
  call :__attack_is_piece !rr! !cc! "!by!" pawn pHit
  if "!pHit!"=="true" (set "%out%=true" & goto :eof)
  set /a "rr=r-1", "cc=c+1"
  call :__attack_is_piece !rr! !cc! "!by!" pawn pHit
  if "!pHit!"=="true" (set "%out%=true" & goto :eof)
)

:: Sliding: rook/queen orthogonals (use static ray helper)
call :rayAttack !r! !c!  1  0 "!by!" rookOrQueen hit
if "!hit!"=="true" (set "%out%=true" & goto :eof)
call :rayAttack !r! !c! -1  0 "!by!" rookOrQueen hit
if "!hit!"=="true" (set "%out%=true" & goto :eof)
call :rayAttack !r! !c!  0  1 "!by!" rookOrQueen hit
if "!hit!"=="true" (set "%out%=true" & goto :eof)
call :rayAttack !r! !c!  0 -1 "!by!" rookOrQueen hit
if "!hit!"=="true" (set "%out%=true" & goto :eof)

:: Sliding: bishop/queen diagonals
call :rayAttack !r! !c!  1  1 "!by!" bishopOrQueen hit
if "!hit!"=="true" (set "%out%=true" & goto :eof)
call :rayAttack !r! !c!  1 -1 "!by!" bishopOrQueen hit
if "!hit!"=="true" (set "%out%=true" & goto :eof)
call :rayAttack !r! !c! -1  1 "!by!" bishopOrQueen hit
if "!hit!"=="true" (set "%out%=true" & goto :eof)
call :rayAttack !r! !c! -1 -1 "!by!" bishopOrQueen hit
if "!hit!"=="true" (set "%out%=true" & goto :eof)

set "%out%=false"
goto :eof

:rayAttack
:: Args: r c dr dc by mode outVar
set "rr=%~1" & set "cc=%~2" & set "dr=%~3" & set "dc=%~4" & set "by=%~5" & set "mode=%~6" & set "out=%~7"
:__ray_loop
set /a "rr+=dr", "cc+=dc"
if !rr! lss 0 (set "%out%=false" & goto :eof)
if !rr! gtr 7 (set "%out%=false" & goto :eof)
if !cc! lss 0 (set "%out%=false" & goto :eof)
if !cc! gtr 7 (set "%out%=false" & goto :eof)
call set "sq=%%pos_!rr!_!cc!%%"
if !sq!==0 goto :__ray_loop
call :__attack_piece_match !sq! "!by!" "!mode!" hit
set "%out%=!hit!"
goto :eof

:__attack_is_piece
set "r=%~1" & set "c=%~2" & set "by=%~3" & set "kind=%~4" & set "out=%~5"
if %r% lss 0 (set "%out%=false" & goto :eof)
if %r% gtr 7 (set "%out%=false" & goto :eof)
if %c% lss 0 (set "%out%=false" & goto :eof)
if %c% gtr 7 (set "%out%=false" & goto :eof)
call set "p=%%pos_%r%_%c%%%"
if /i "%by%"=="white" (
  if /i "%kind%"=="knight" (if !p!==5 (set "%out%=true" & goto :eof))
  if /i "%kind%"=="king"   (if !p!==1 (set "%out%=true" & goto :eof))
  if /i "%kind%"=="pawn"   (if !p!==6 (set "%out%=true" & goto :eof))
) else (
  if /i "%kind%"=="knight" (if !p!==11 (set "%out%=true" & goto :eof))
  if /i "%kind%"=="king"   (if !p!==7  (set "%out%=true" & goto :eof))
  if /i "%kind%"=="pawn"   (if !p!==12 (set "%out%=true" & goto :eof))
)
set "%out%=false"
goto :eof

:__attack_piece_match
set "p=%~1" & set "by=%~2" & set "mode=%~3" & set "out=%~4"
set "%out%=false"
if /i "%by%"=="white" (
  if /i "%mode%"=="rookOrQueen"   (if !p!==3  (set "%out%=true" & goto :eof) & if !p!==2  (set "%out%=true" & goto :eof))
  if /i "%mode%"=="bishopOrQueen" (if !p!==4  (set "%out%=true" & goto :eof) & if !p!==2  (set "%out%=true" & goto :eof))
) else (
  if /i "%mode%"=="rookOrQueen"   (if !p!==9  (set "%out%=true" & goto :eof) & if !p!==8  (set "%out%=true" & goto :eof))
  if /i "%mode%"=="bishopOrQueen" (if !p!==10 (set "%out%=true" & goto :eof) & if !p!==8  (set "%out%=true" & goto :eof))
)
goto :eof

:otherSide
if /i "%~1"=="white" (set "%~2=black") else (set "%~2=white")
goto :eof

:: ============================ COORDS ============================
:algebraicToCoords
set "pos=%~1" & set "rowVar=%~2" & set "colVar=%~3"
set "file=!pos:~0,1!" & set "rank=!pos:~1,1!"
set "colNum=-1"
if /i "!file!"=="a" set "colNum=0"
if /i "!file!"=="b" set "colNum=1"
if /i "!file!"=="c" set "colNum=2"
if /i "!file!"=="d" set "colNum=3"
if /i "!file!"=="e" set "colNum=4"
if /i "!file!"=="f" set "colNum=5"
if /i "!file!"=="g" set "colNum=6"
if /i "!file!"=="h" set "colNum=7"
set "rowNum=-1"
if "%rank%"=="1" (set "rowNum=7") else if "%rank%"=="2" (set "rowNum=6") else if "%rank%"=="3" (set "rowNum=5") else if "%rank%"=="4" (set "rowNum=4") else if "%rank%"=="5" (set "rowNum=3") else if "%rank%"=="6" (set "rowNum=2") else if "%rank%"=="7" (set "rowNum=1") else if "%rank%"=="8" (set "rowNum=0")
set "%rowVar%=!rowNum!"
set "%colVar%=!colNum!"
goto :eof

:end
echo.
echo Thanks for playing Batch chess!
echo Press any key to exit...
pause >nul
exit /b 0
