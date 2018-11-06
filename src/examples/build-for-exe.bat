@ECHO OFF
REM
REM Sample script used to distribute obfuscated python scripts with py2exe
REM
REM Before run it, all TODO variables need to set correctly.
REM

SETLOCAL

REM TODO:
SET ZIP=D:\cygwin\bin\zip.exe
SET PYTHON=C:\Python34\python.exe

REM TODO: Where to find pyarmor.py
SET PYARMOR_PATH=C:\Python34\Lib\site-packages\pyarmor

REM TODO: Absolute path in which all python scripts will be obfuscated
SET SOURCE=C:\Python34\Lib\site-packages\pyarmor\examples\py2exe

REM TODO: Entry script filename, must be relative to %SOURCE%
SET ENTRY_NAME=hello
SET ENTRY_SCRIPT=%ENTRY_NAME%.py
SET ENTRY_EXE=%ENTRY_NAME%.exe

REM TODO: Output path of py2exe
REM       An executable binary file and library.zip generated by py2exe should be here
SET OUTPUT=C:\Python34\Lib\site-packages\pyarmor\examples\py2exe\dist

REM TODO: output path for saving project config file, and obfuscated scripts
SET PROJECT=C:\Python34\Lib\site-packages\pyarmor\build-for-py2exe

REM TODO: Comment netx line if not to test obfuscated scripts
SET TEST_OBFUSCATED_SCRIPTS=1

REM Check Python
%PYTHON% --version 
IF NOT ERRORLEVEL 0 (
  ECHO.
  ECHO Python doesn't work, check value of variable PYTHON
  ECHO.
  GOTO END
)

REM Check Zip
%ZIP% --version > NUL
IF NOT ERRORLEVEL 0 (
  ECHO.
  ECHO Zip doesn't work, check value of variable ZIP
  ECHO.
  GOTO END
)

REM Check Pyarmor
IF NOT EXIST "%PYARMOR_PATH%\pyarmor.py" (
  ECHO.
  ECHO No pyarmor found, check value of variable PYARMOR_PATH
  ECHO. 
  GOTO END
)

REM Check Source
IF NOT EXIST "%SOURCE%" (
  ECHO.
  ECHO No %SOURCE% found, check value of variable SOURCE
  ECHO. 
  GOTO END
)

REM Check entry script
IF NOT EXIST "%SOURCE%\%ENTRY_SCRIPT%" (
  ECHO.
  ECHO No %ENTRY_SCRIPT% found, check value of variable ENTRY_SCRIPT
  ECHO. 
  GOTO END
)

REM Create a project
ECHO.
CD /D %PYARMOR_PATH%
%PYTHON% pyarmor.py init --type=app --src=%SOURCE% --entry=%ENTRY_SCRIPT% %PROJECT%
IF NOT ERRORLEVEL 0 GOTO END
ECHO.

REM Change to project path, there is a convenient script pyarmor.bat
cd /D %PROJECT%

REM This is the key, change default runtime path, otherwise dynamic library _pytransform could not be found
CALL pyarmor.bat config --runtime-path="" --disable-restrict-mode=1 --manifest "include queens.py, exclude setup.py"

REM Obfuscate scripts without runtime files, only obfuscated scripts are generated
ECHO.
CALL pyarmor.bat build --no-runtime
IF NOT ERRORLEVEL 0 GOTO END
ECHO.

REM Copy pytransform.py and obfuscated entry script to source
ECHO.
ECHO Copy pytransform.py to %SOURCE%
COPY %PYARMOR_PATH%\pytransform.py %SOURCE%

ECHO Backup original %ENTRY_SCRIPT%
COPY %SOURCE%\%ENTRY_SCRIPT% %ENTRY_SCRIPT%.bak

ECHO Copy obfuscated script %ENTRY_SCRIPT% to %SOURCE%
COPY dist\%ENTRY_SCRIPT% %SOURCE%
ECHO.

REM Run py2exe
SETLOCAL
  ECHO.
  CD /D %SOURCE%
  %PYTHON% setup.py py2exe
  IF NOT ERRORLEVEL 0 GOTO END
  ECHO.
ENDLOCAL

ECHO Restore entry script
MOVE %ENTRY_SCRIPT%.bak %SOURCE%\%ENTRY_SCRIPT%

ECHO.
ECHO Compile obfuscated script .py to .pyc
%PYTHON% -m compileall dist
IF NOT ERRORLEVEL 0 GOTO END
ECHO.

REM Replace the original python scripts with obfuscated scripts in zip file
SETLOCAL
  ECHO.
  CD dist
  %ZIP% -r %OUTPUT%\library.zip *.pyc
  IF NOT ERRORLEVEL 0 GOTO END
  ECHO.
ENDLOCAL  

REM Generate runtime files only
ECHO.
CALL pyarmor.bat build --only-runtime --output %PROJECT%\runtime-files
IF NOT ERRORLEVEL 0 GOTO END
ECHO.

ECHO Copy runtime files to %OUTPUT%
COPY %PROJECT%\runtime-files\* %OUTPUT%

ECHO.
ECHO All the python scripts have been obfuscated in the output path %OUTPUT% successfully.
ECHO.

REM Test obfuscated scripts
IF "%TEST_OBFUSCATED_SCRIPTS%" == "1" (
  ECHO Prepare to run %ENTRY_EXE% with obfuscated scripts
  PAUSE
  
  CD /D %OUTPUT%
  %ENTRY_EXE%  
)

:END

ENDLOCAL
PAUSE