@echo off
rem Installer for Help document viewer

rem Change this line to the correct serial port for your computer
set PORT=COM3

python fnxmgr.zip --port %PORT% --flash-bulk bulk.csv

echo Help Installed
pause