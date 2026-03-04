@echo off
setlocal enabledelayedexpansion

REM === Configuration ===
set "REGISTRY=ghcr.io/kellphy"
set "GH_USER=kellphy"
set "IMAGE_NAME=minecraft-cloudflare"
set "PLATFORMS=linux/arm64"
set "IMAGE_URL=%REGISTRY%/%IMAGE_NAME%"

REM === Load token from environment or .env file (searches up) ===
if not defined NUGET_TOKEN (
    set "_dir=%~dp0"
    :findenv_dep
    if exist "!_dir!.env" (
        for /f "usebackq tokens=1,* delims==" %%a in ("!_dir!.env") do (
            if "%%a"=="NUGET_TOKEN" set "NUGET_TOKEN=%%b"
        )
    )
    if not defined NUGET_TOKEN (
        set "_parent=!_dir!..\"
        for %%i in ("!_parent!") do set "_parent=%%~fi\"
        if "!_parent!"=="!_dir!" goto :noenv_dep
        set "_dir=!_parent!"
        goto :findenv_dep
    )
)
goto :doneenv_dep
:noenv_dep
echo ERROR: NUGET_TOKEN not set. Set it as an environment variable or in a .env file.
echo Example .env file:
echo   NUGET_TOKEN=ghp_your_token_here
pause
exit /b 1
:doneenv_dep

REM === Check Docker ===
docker --version >nul 2>&1 || (
    echo ERROR: Docker is not installed or not in PATH.
    pause
    exit /b 1
)
docker info >nul 2>&1 || (
    echo ERROR: Docker daemon is not running. Please start Docker Desktop and try again.
    pause
    exit /b 1
)

REM === Login to GHCR ===
echo Logging in to %REGISTRY%...
echo !NUGET_TOKEN! | docker login ghcr.io -u %GH_USER% --password-stdin || (
    echo ERROR: Docker login failed.
    pause
    exit /b 1
)

REM === Build and push ===
echo Building and pushing %IMAGE_URL%:latest...
docker buildx build --platform %PLATFORMS% -f "Dockerfile" -t "%IMAGE_URL%:latest" --push . || (
    echo ERROR: Build/push failed.
    pause
    exit /b 1
)

echo.
echo Successfully deployed %IMAGE_URL%:latest
pause
