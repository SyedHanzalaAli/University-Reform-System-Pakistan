@echo off
REM Wrapper that runs the portable SWI-Prolog 11.0.0 installed in the workspace
REM (or falls back to system swipl if moved elsewhere).
if exist "%~dp0..\swipl\bin\swipl.exe" (
    "%~dp0..\swipl\bin\swipl.exe" %*
) else if exist "C:\Program Files\swipl\bin\swipl.exe" (
    "C:\Program Files\swipl\bin\swipl.exe" %*
) else (
    swipl %*
)
