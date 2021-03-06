@ECHO OFF
:: Creates a device using the computer hostname.
:: Path to SpiderOak. Replace "SpiderOakBlue" with "SpiderOak" if
:: necessary for the consumer product..
set _spideroak="C:\Program Files\SpiderOakBlue\SpiderOakBlue.exe"

set _ouruser=%1
set _ourpass=%2
set _fingerprint=%3

if defined 4 (
    set _userext=%4
)

if defined _userext (
    set _ouruser=%_ouruser%%_userext%
)

set _appout=%TEMP%\spiderout.txt
set _setupfile=%TEMP%\setupfile.json
:: First, let's try to install the device with the computer name.
:: The following creates the result variable %_result%.
call :installdev %COMPUTERNAME%

:: The cases where we don't do the rename dance
:: (successful device creation or non-name-collitypesion failure)
if NOT %_result% EQU 1 (
    ECHO Script complete.
    exit /B %_result%
)

ECHO Renaming devices to fit.
   
:: If we've gotten here, we need to do some renaming
call :olddevname %COMPUTERNAME%
call :installdev %COMPUTERNAME%-new
call :renamedev %COMPUTERNAME% %_newolddevname%
call :renamedev %COMPUTERNAME%-new %COMPUTERNAME%

ECHO Script complete.
GOTO:eof
:: This is the end of the main code! Subroutines follow.

:: Installs a device. Expects one paramater- the device name.
:installdev
SETLOCAL
SET _devname=%1
echo {"username":"%_ouruser%","password":"%_ourpass%","device_name":"%_devname%","fingerprint":%_fingerprint%,"reinstall":false} > %_setupfile%

echo Setting up SpiderOak as device %_devname% (this may take a while)...
%_spideroak% --setup=%_setupfile% > %_appout%

:: Check our output. Did we run OK?
find "batchmode run complete: shutting down" %_appout%
if %ERRORLEVEL% EQU 0 (
    ENDLOCAL & SET _result=0
    ECHO Device setup OK
    GOTO:eof
)

:: Check if we already exist.
find  "Device name already exists" %_appout%
if %ERRORLEVEL% EQU 0 (
    ENDLOCAL & SET _result=1
    ECHO Device already exists
    GOTO:eof
)

:: Didn't setup the device & didn't find device name already exists.
ENDLOCAL & SET _result=2
ECHO Error in setup
GOTO:eof

:: Gets the device ID from a device number.
:: Expects the name of the device as a parameter.
:: Sets %_devnum% as a variable after being run.
:devnumForName
SETLOCAL
SET _devname=%1
%_spideroak% --userinfo > %_appout%

echo %_devname%
echo %_appout%
for /f "tokens=2 delims=#" %%a in ('findstr /R "%_devname%[^-]" "%_appout%"') do set _devnum=%%a

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

ECHO Renaming %_olddev% to %_newdev%

%_spideroak% -d %_devnum% --rename-device=%_newdev%
ENDLOCAL
GOTO :eof
