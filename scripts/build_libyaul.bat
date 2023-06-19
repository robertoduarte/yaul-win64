@ECHO off

echo Building libyaul!
call setenv.bat
cd ..\libyaul
make clean
make install
