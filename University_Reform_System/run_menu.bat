@echo off
cd /d "%~dp0"
call "%~dp0swipl.bat" -g start -t halt main.pl
