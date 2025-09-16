@echo off
cd /d "%~dp0\..\..\"
echo ================================================================
echo     AI AGENT PLATFORM - STOPPING ALL SERVICES
echo ================================================================

echo.
echo Current service status:
echo ================================================================
docker compose ps

echo.
echo Stopping all services...
echo ================================================================
docker compose down

if errorlevel 1 (
    echo.
    echo WARNING: Some services may not have stopped cleanly
    echo Attempting force stop...
    docker compose down --remove-orphans
    
    if errorlevel 1 (
        echo.
        echo ERROR: Force stop also failed
        echo Manual cleanup may be required
        echo.
        echo Try these commands manually:
        echo   docker stop clever_postgres clever_redis clever_qdrant
        echo   docker rm clever_postgres clever_redis clever_qdrant
        pause
        exit /b 1
    )
)

echo.
echo Verifying services are stopped...
echo ================================================================
timeout /t 3 /nobreak >nul

docker compose ps 2>nul | findstr "clever" >nul
if not errorlevel 1 (
    echo.
    echo WARNING: Some containers are still running:
    docker compose ps
    echo.
    echo Would you like to force remove them? (Y/N)
    set /p choice=
    if /i "%choice%"=="Y" (
        echo Force removing containers...
        docker compose down --remove-orphans --volumes
        echo Done.
    )
) else (
    echo ✓ All services stopped successfully
)

echo.
echo ================================================================
echo SERVICE SHUTDOWN COMPLETE
echo ================================================================
echo.
echo All AI Agent Platform services have been stopped:
echo - PostgreSQL Database
echo - Redis Cache  
echo - Qdrant Vector Database
echo.
echo Data Persistence:
echo - PostgreSQL data: Preserved in Docker volume 'clever_postgres_data'
echo - Redis data: Preserved in Docker volume 'clever_redis_data'
echo - Qdrant data: Preserved in Docker volume 'clever_qdrant_data'
echo.
echo To restart services:
echo - Run 'start-services.bat' for infrastructure only
echo - Run 'start-dev.bat' for full development environment
echo - Run 'setup-project.bat' for complete setup
echo.
echo To completely remove all data (DESTRUCTIVE):
echo   docker volume rm clever_postgres_data clever_redis_data clever_qdrant_data
echo.
echo To view Docker resource usage:
echo   docker system df
echo.
echo ================================================================
pause