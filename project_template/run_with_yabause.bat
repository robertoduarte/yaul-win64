@ECHO Off
call ..\..\setenv.bat

if exist %YAUL_ROOT%emulators/yabause/yabause.exe (
    SET YABAUSE=%YAUL_ROOT%emulators/yabause/yabause.exe
) else (
    SET YABAUSE=yabause.exe
)

if not exist *.cue (
    echo "CUE/ISO missing, please build first."
) else (
    @REM Finding first cue file and running it on yabause
    FOR %%F IN (*.cue) DO (
        %YABAUSE% -a -i %%F
        exit /b
    )
)
