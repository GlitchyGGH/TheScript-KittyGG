@echo off
setlocal EnableExtensions
title ASCII Mad Libs Adventure
color 0B
mode con: cols=100 lines=35

set "LOGDIR=%~dp0logs"
if not exist "%LOGDIR%" md "%LOGDIR%" >nul 2>&1
set "LOG=%LOGDIR%\madlibs.log"

call :log "START"

:MAIN_MENU
cls
call :BANNER
echo(
echo Choose your adventure:
echo(
echo   [1] The Mysterious Journey
echo   [2] Superhero Academy
echo   [3] Cooking Disaster
echo   [4] Space Explorer
echo   [5] Medieval Quest
echo   [6] Random Story
echo(
echo   [Q] Quit Game
echo(
set "choice="
set /p "choice=Enter your choice (1-6 or Q): " || goto MAIN_MENU
if /i "%choice%"=="Q" goto EXIT_GAME
if "%choice%"=="1" set "story_id=1" & goto STORY_1
if "%choice%"=="2" set "story_id=2" & goto STORY_2
if "%choice%"=="3" set "story_id=3" & goto STORY_3
if "%choice%"=="4" set "story_id=4" & goto STORY_4
if "%choice%"=="5" set "story_id=5" & goto STORY_5
if "%choice%"=="6" set "story_id=R" & goto RANDOM_STORY
goto MAIN_MENU

:STORY_1
set "story_title=The Mysterious Journey"
call :GET_WORD "Enter your name" name
call :GET_WORD "Enter a place (like Paris or the moon)" place
call :GET_WORD "Enter an adjective (like spooky or bright)" adj1
call :GET_WORD "Enter a noun (like book or sandwich)" noun1
call :GET_WORD "Enter a verb ending in -ing (like running)" verb1
call :GET_WORD "Enter an animal" animal
call :GET_WORD "Enter another adjective" adj2
call :GET_WORD "Enter a color" color
set "story=Once upon a time, %name% was walking through %place% when they discovered a %adj1% %noun1%. Suddenly, it started %verb1% all by itself! A wild %animal% appeared and said 'This is absolutely %adj2%!' The whole world turned %color% and everyone lived happily ever after."
goto SHOW_STORY

:STORY_2
set "story_title=Superhero Academy"
call :GET_WORD "Enter a superhero name" hero
call :GET_WORD "Enter a superpower (like flying or invisibility)" power
call :GET_WORD "Enter a number" number
call :GET_WORD "Enter a food" food
call :GET_WORD "Enter an adjective (like awesome or terrible)" adj1
call :GET_WORD "Enter a villain name" villain
call :GET_WORD "Enter a weapon or tool" weapon
set "story=Welcome to Superhero Academy, %hero%! Your amazing power is %power%, which you discovered after eating %number% bowls of %food%. Your first mission was %adj1% - you had to stop the evil %villain% from stealing all the %weapon%s in the city. With great power comes great responsibility!"
goto SHOW_STORY

:STORY_3
set "story_title=Cooking Disaster"
call :GET_WORD "Enter a chef's name" chef
call :GET_WORD "Enter an ingredient" ingredient1
call :GET_WORD "Enter another ingredient" ingredient2
call :GET_WORD "Enter a cooking method (like baking or frying)" method
call :GET_WORD "Enter a number" time
call :GET_WORD "Enter an emotion (like excited or worried)" emotion
call :GET_WORD "Enter an adjective describing taste" taste
set "story=Chef %chef% decided to make a special dish using %ingredient1% and %ingredient2%. The recipe said to use the %method% technique for %time% minutes. %chef% was feeling %emotion% about the whole thing. When it was done, it tasted absolutely %taste%! Everyone in the restaurant couldn't stop talking about it."
goto SHOW_STORY

:STORY_4
set "story_title=Space Explorer"
call :GET_WORD "Enter an astronaut name" astronaut
call :GET_WORD "Enter a planet name" planet
call :GET_WORD "Enter an alien creature" alien
call :GET_WORD "Enter a futuristic gadget" gadget
call :GET_WORD "Enter an adjective (like shiny or slimy)" adj1
call :GET_WORD "Enter a verb (like dance or jump)" verb1
call :GET_WORD "Enter a space food" spacefood
set "story=Captain %astronaut% landed on the mysterious planet %planet% where they met a friendly %alien%. Using their trusty %gadget%, they discovered the planet was covered in %adj1% crystals. The aliens loved to %verb1% while eating their favorite food: %spacefood%. It was the most amazing discovery in the galaxy!"
goto SHOW_STORY

:STORY_5
set "story_title=Medieval Quest"
call :GET_WORD "Enter a knight's name" knight
call :GET_WORD "Enter a magical creature" creature
call :GET_WORD "Enter a treasure" treasure
call :GET_WORD "Enter a castle location" castle
call :GET_WORD "Enter an adjective (like brave or silly)" adj1
call :GET_WORD "Enter a medieval weapon" weapon
call :GET_WORD "Enter a number" number
set "story=Sir %knight% embarked on a quest to find the legendary %creature% who guarded the precious %treasure%. The journey led to %castle% castle, where %knight% had to be very %adj1%. Armed with only a %weapon% and %number% pieces of bread, our hero saved the kingdom and became famous throughout the land!"
goto SHOW_STORY

:RANDOM_STORY
set /a "rand=%RANDOM% %% 5 + 1"
if "%rand%"=="1" goto STORY_1
if "%rand%"=="2" goto STORY_2
if "%rand%"=="3" goto STORY_3
if "%rand%"=="4" goto STORY_4
goto STORY_5

:GET_WORD
set "prompt=%~1"
set "varname=%~2"
:ASK_AGAIN
set "temp_input="
set /p "temp_input=%prompt%: " || goto ASK_AGAIN
if "%temp_input%"=="" (
  echo Please enter something!
  goto ASK_AGAIN
)
set "%varname%=%temp_input%"
echo(
goto :eof

:SHOW_STORY
cls
call :BANNER
echo(
echo "%story_title%"
echo(
echo %story%
echo(
echo Press any key to return to the main menu...
pause >nul
call :log "STORY %story_title%"
goto MAIN_MENU

:EXIT_GAME
cls
call :BANNER
echo(
echo Thanks for playing ASCII Mad Libs!
echo(
echo Press any key to exit...
pause >nul
call :log "END OK"
endlocal & exit /b 0

:BANNER
set /p ="  ____        _       _           __  __           _ _ _          "<nul & echo(
set /p =" |  _ \      | |     | |         |  \/  |         | (_) |        "<nul & echo(
set /p =" | |_) | __ _| |_ ___| |__ ______| \  / | __ _  __| |_| |__  ___ "<nul & echo(
set /p =" |  _ < / _` | __/ __| '_ \______| |\/| |/ _` |/ _` | | '_ \/ __|"<nul & echo(
set /p =" | |_) | (_| | || (__| | | |     | |  | | (_| | (_| | | |_) \__ \ "<nul & echo(
set /p =" |____/ \__,_|\__\___|_| |_|     |_|  |_|\__,_|\__,_|_|_.__/|___/ "<nul & echo(
set /p ="                                                                  "<nul & echo(
set /p ="                                                                  "<nul & echo(
goto :eof

:log
if not exist "%LOGDIR%" md "%LOGDIR%" >nul 2>&1
>>"%LOG%" echo [%date% %time%] %~1
goto :eof
