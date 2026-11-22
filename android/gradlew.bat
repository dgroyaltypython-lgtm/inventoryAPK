@echo off
setlocal EnableExtensions
set "WRAPPER_DIR=%~dp0"
set "PROPS=%WRAPPER_DIR%gradle\wrapper\gradle-wrapper.properties"
for /f "tokens=2 delims==" %%A in ('findstr /b distributionUrl= "%PROPS%"') do set "DIST_URL=%%A"
set "DIST_URL=%DIST_URL:\:=:%"
for %%A in ("%DIST_URL%") do set "ZIP_NAME=%%~nxA"
set "VERSION=%ZIP_NAME:gradle-=%"
set "VERSION=%VERSION:-bin.zip=%"
if not defined GRADLE_USER_HOME set "GRADLE_USER_HOME=%USERPROFILE%\.gradle"
set "BASE=%GRADLE_USER_HOME%\wrapper\dists\coastal-gradle-%VERSION%"
if not exist "%BASE%\gradle-%VERSION%\bin\gradle.bat" (
  if not exist "%BASE%" mkdir "%BASE%"
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%DIST_URL%' -OutFile '%BASE%\gradle.zip'; Expand-Archive -Force '%BASE%\gradle.zip' '%BASE%'"
)
call "%BASE%\gradle-%VERSION%\bin\gradle.bat" %*
exit /b %ERRORLEVEL%
