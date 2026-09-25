@echo off
setlocal
cd /d "%~dp0"
if defined GODOT_BIN (
    "%GODOT_BIN%" --path "%~dp0."
    exit /b
)
if exist "tools\godot\Godot_v4.7.2-stable_win64.exe" (
    "tools\godot\Godot_v4.7.2-stable_win64.exe" --path "%~dp0."
    exit /b
)
echo Abra project.godot no Godot 4.7.2 e pressione F5.
pause
