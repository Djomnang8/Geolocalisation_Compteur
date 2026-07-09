@echo off
REM ============================================================================
REM  SOCADEL Geoloc - Demarrage automatique des deux API du backend
REM  ---------------------------------------------------------------------------
REM  - API Backend  (microservices metier)  : port 8081
REM  - API Frontend (passerelle BFF mobile) : port 8080
REM
REM  Ce script fonctionne meme si le projet est deplace : il se base sur
REM  son propre emplacement (%%~dp0 = dossier ou se trouve ce fichier .bat).
REM  Double-cliquez simplement dessus, ou lancez-le depuis un terminal.
REM
REM  Prerequis : Java 21+ et Maven installes (mvn accessible), MySQL demarre
REM  dans XAMPP (base socadel_geoloc importee).
REM ============================================================================

REM Dossier du projet backend_java = dossier ou se trouve ce script
set "DOSSIER_BACKEND=%~dp0"

echo.
echo  ============================================
echo   SOCADEL Geoloc - Demarrage des deux API
echo  ============================================
echo   Dossier du projet : %DOSSIER_BACKEND%
echo.

REM --- Verification : Maven est-il installe ? ---
where mvn >nul 2>&1
if errorlevel 1 (
    echo  [ERREUR] Maven ^(mvn^) est introuvable.
    echo  Installez Maven et ajoutez-le au PATH, puis relancez ce script.
    pause
    exit /b 1
)

REM --- Fenetre 1 : API Backend (port 8081), demarree en premier ---
echo  [1/2] Demarrage de l'API Backend  (microservices metier, port 8081)...
start "API Backend - port 8081" cmd /k "cd /d "%DOSSIER_BACKEND%" && mvn -pl api-backend spring-boot:run"

REM Petite pause pour laisser le backend s'initialiser avant la passerelle
timeout /t 8 /nobreak >nul

REM --- Fenetre 2 : API Frontend / BFF (port 8080) ---
echo  [2/2] Demarrage de l'API Frontend (passerelle BFF, port 8080)...
start "API Frontend - port 8080" cmd /k "cd /d "%DOSSIER_BACKEND%" && mvn -pl api-frontend spring-boot:run"

echo.
echo  Les deux API demarrent dans leurs propres fenetres.
echo  Patientez ~30 secondes puis testez : http://localhost:8080/api/auth/ping
echo  Pour tout arreter : fermez les deux fenetres (ou Ctrl+C dans chacune).
echo.
pause
