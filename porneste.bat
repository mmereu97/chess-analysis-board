@echo off
setlocal EnableExtensions
title Tabla de Analiza
cd /d "%~dp0"

rem ---- 1. Gaseste Python (venv-ul din PyCharm are prioritate) ----
set "PY="
if exist ".venv\Scripts\python.exe" set "PY=.venv\Scripts\python.exe"
if not defined PY if exist "venv\Scripts\python.exe" set "PY=venv\Scripts\python.exe"
if not defined PY (
  py -3 -c "import sys" >nul 2>nul && set "PY=py -3"
)
if not defined PY (
  python -c "import sys" >nul 2>nul && set "PY=python"
)
if not defined PY (
  echo.
  echo  Nu am gasit Python pe acest calculator.
  echo  Instaleaza-l de pe https://www.python.org/downloads/
  echo  si bifeaza "Add python.exe to PATH" la instalare.
  echo.
  pause
  exit /b 1
)

set "HAVECURL=1"
where curl >nul 2>nul || set "HAVECURL="

rem ---- 2. Alege portul: 8000 daca e liber sau e chiar Tabla de Analiza, altfel urmatorul liber ----
set "PORT="
set "START="
for %%P in (8000 8001 8002 8003 8004 8005 8006 8007 8008 8009) do (
  if not defined PORT call :tryport %%P
)
if not defined PORT (
  echo.
  echo  Nu am gasit niciun port liber intre 8000 si 8009.
  echo.
  pause
  exit /b 1
)
set "URL=http://localhost:%PORT%/"

if "%START%"=="1" (
  if not "%PORT%"=="8000" echo  Portul 8000 e ocupat de alt program, folosesc portul %PORT%.
  echo  Pornesc serverul pe portul %PORT%...
  start "Tabla de Analiza - server (inchide fereastra ca sa opresti)" /min %PY% -m http.server %PORT% --bind 127.0.0.1
) else (
  echo  Tabla de Analiza ruleaza deja pe portul %PORT%.
)

rem ---- 3. Asteapta pana raspunde serverul ----
if not defined HAVECURL (
  timeout /t 2 /nobreak >nul
  goto open
)
set /a TRIES=0
:wait
curl -s -o nul "http://127.0.0.1:%PORT%/stockfish.js" && goto open
set /a TRIES+=1
if %TRIES% geq 15 (
  echo.
  echo  Serverul nu a pornit. Verifica fereastra minimizata a serverului.
  echo.
  pause
  exit /b 1
)
timeout /t 1 /nobreak >nul
goto wait

rem ---- 4. Deschide aplicatia in Chrome ----
:open
set "CHROME="
if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%LocalAppData%\Google\Chrome\Application\chrome.exe" set "CHROME=%LocalAppData%\Google\Chrome\Application\chrome.exe"

if defined CHROME (
  start "" "%CHROME%" --new-window "%URL%"
) else (
  echo  Nu am gasit Chrome, deschid browserul implicit.
  start "" "%URL%"
)

echo.
echo  Tabla de Analiza e deschisa la %URL%
echo  Serverul ruleaza intr-o fereastra minimizata in bara de jos.
echo  Ca sa il opresti, inchide fereastra aceea.
timeout /t 5 >nul
exit /b 0

rem ---- verifica un port: liber = il folosim; ocupat de Tabla de Analiza = il refolosim ----
:tryport
set "P=%~1"
netstat -ano | findstr /r /c:":%P% .*LISTENING" >nul
if errorlevel 1 (
  set "PORT=%P%"
  set "START=1"
  goto :eof
)
if not defined HAVECURL goto :eof
set "CODE="
for /f %%C in ('curl -s -o nul -w "%%{http_code}" "http://127.0.0.1:%P%/stockfish.js" 2^>nul') do set "CODE=%%C"
if "%CODE%"=="200" (
  set "PORT=%P%"
  set "START=0"
)
goto :eof
