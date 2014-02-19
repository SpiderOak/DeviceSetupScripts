
set _appout=%TEMP%/spiderout.txt
set _setupfile=%TEMP%/setupfile.json

set _domain=@foo.com

set _spideroak="C:\Program Files\SpiderOak\SpiderOak.exe"

:: First, let's try to install the device with the computer name.
:: The following creates the result variable %_result%.
call :installdev %COMPUTERNAME%

:: The cases where we don't do the rename dance
:: (successful device creation or non-name-collision failure)
if NOT %_result% EQU 1 (
    exit /B %_result%
)
   
:: If we've gotten here, we need to do some renaming
call :olddevname %COMPUTERNAME%
call :installdev %COMPUTERNAME%-new
call :renamedev %COMPUTERNAME% %_newolddevname%
call :renamedev %COMPUTERNAME%-new %COMPUTERNAME%


GOTO:eof
:: This is the end of the main code! Subroutines follow.

:: Installs a device. Expects one paramater- the device name.
:installdev
SETLOCAL
SET _devname=%1
echo {"username":"matttest","password":"matttest","device_name":"%_devname%","reinstall":false} > %_setupfile%

echo Setting up SpiderOak as device %_devname%...
%_spideroak% --setup=%_setupfile% > %_appout%

:: Check our output. Did we run OK?
find "batchmode run complete: shutting down" %_appout%
if %ERRORLEVEL% EQU 0 (
    ENDLOCAL & SET _result=0
    GOTO:eof
)

:: Check if we already exist.
find  "Device name already exists" %_appout%
if %ERRORLEVEL% EQU 0 (
    ENDLOCAL & SET _result=1
    GOTO:eof
)

:: Didn't setup the device & didn't find device name already exists.
ENDLOCAL & SET_result=2
GOTO:eof

:: Gets the device ID from a device number.
:: Expects the name of the device as a parameter.
:: Sets %_devnum% as a variable after being run.
:devnumForName
%_spideroak% --userinfo > %_appout%
SETLOCAL
SET _devname=%1
for /f "tokens=1,2 delims=#" %a in ('findstr /r "%_devname%" %_appout%') do set _=%a&set _devnum=%b

ENDLOCAL & SET _devnum=%_devnum:)=%
GOTO:eof

:: Builds up an old device name
:: Expects the name of the old device as a parameter.
:: Produces a string with of DEVNAME-old-DATE-TIME
:olddevname
SETLOCAL
SET _olddev=%1

set _time=%time:~0,8%
set _time=%_time::=%

ENDLOCAL & SET _newolddevname=%_olddev%-old-%date:~10,4%%date:~4,2%%date:~7,2%-%_time%
GOTO :eof

:: Renames a device.
:: Expects two parameters- old device name and new device name.
:renamedev
SETLOCAL
SET _olddev=%1
SET _newdev=%2
:: Get the device ID we want to use.
CALL :devnumForName %_olddev%

%_spideroak% -D %_devnum% --rename-device=%_newdev%
ENDLOCAL
GOTO :eof