@echo off
setlocal
cd /d "%~dp0"
if defined GODOT_BIN (
    "%GODOT_BIN%" --path "%~dp0." res://scenes/ren_animation_lab.tscn
    exit /b
)
"tools\godot\Godot_v4.7.2-stable_win64.exe" --path "%~dp0." res://scenes/ren_animation_lab.tscn
