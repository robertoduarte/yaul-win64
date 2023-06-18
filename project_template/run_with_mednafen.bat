@ECHO Off
call ..\..\setenv.bat

if exist %YAUL_ROOT%emulators/mednafen/mednafen.exe (
    SET MEDNAFEN=%YAUL_ROOT%emulators/mednafen/mednafen.exe
) else (
    SET MEDNAFEN=mednafen.exe
)

if not exist *.cue (
    echo "CUE/ISO missing, please build first."
) else (
    @REM Finding first cue file and running it on mednafen
    FOR %%F IN (*.cue) DO (
        %MEDNAFEN% %%F
        exit /b
    )
)
