@echo off
cd /d "%~dp0"
call "%~dp0swipl.bat" -g demo_all -t halt main.pl
if "%1"=="" pause
