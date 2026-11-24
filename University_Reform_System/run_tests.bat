@echo off
cd /d "%~dp0"
call "%~dp0swipl.bat" -g run_all_tests -t halt tests.pl
if "%1"=="" pause
