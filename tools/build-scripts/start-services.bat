@echo off
cd /d "%~dp0\..\..\"
echo ================================================================
echo     AI AGENT PLATFORM - INFRASTRUCTURE SERVICES STARTUP
echo ================================================================

echo.
echo Starting infrastructure services only (no application server)...
echo This includes: PostgreSQL, Redis, Qdrant
echo.

echo Step 1: Starting core services...
echo ================================================================
docker compose up -d postgres redis qdrant

echo.
echo Step 2: Waiting for services to be healthy...
echo ================================================================

echo Waiting for PostgreSQL...
:wait_postgres
docker compose ps postgres | findstr "healthy" >nul 2>&1
if errorlevel 1 (
    echo PostgreSQL not healthy yet, waiting 5 seconds...
    timeout /t 5 /nobreak >nul
    goto wait_postgres
)
echo ✓ PostgreSQL is healthy

echo Waiting for Redis...
:wait_redis
docker compose ps redis | findstr "healthy" >nul 2>&1
if errorlevel 1 (
    echo Redis not healthy yet, waiting 5 seconds...
    timeout /t 5 /nobreak >nul
    goto wait_redis
)
echo ✓ Redis is healthy

echo Waiting for Qdrant...
:wait_qdrant
curl -s http://localhost:6333/health >nul 2>&1
if errorlevel 1 (
    echo Qdrant not ready yet, waiting 5 seconds...
    timeout /t 5 /nobreak >nul
    goto wait_qdrant
)
echo ✓ Qdrant is ready

echo.
echo Step 3: Service verification...
echo ================================================================
echo Checking service status...
docker compose ps

echo.
echo Testing service connectivity...
docker compose exec postgres pg_isready -U clever_user >nul 2>&1 && echo "✓ PostgreSQL responding" || echo "✗ PostgreSQL not responding"
docker compose exec redis redis-cli -a clever_redis_password_2025 ping >nul 2>&1 && echo "✓ Redis responding" || echo "✗ Redis not responding"
curl -s http://localhost:6333/health >nul 2>&1 && echo "✓ Qdrant API responding" || echo "✗ Qdrant not responding"

echo.
echo ================================================================
echo INFRASTRUCTURE SERVICES STARTED SUCCESSFULLY!
echo ================================================================
echo.
echo Available Services:
echo - PostgreSQL Database: localhost:5432
echo   Username: clever_user
echo   Database: clever_db
echo.
echo - Redis Cache: localhost:6379
echo   Password: clever_redis_password_2025
echo.
echo - Qdrant Vector DB: http://localhost:6333
echo   API Key: clever_qdrant_api_key_2025
echo.
echo Service Health Endpoints:
echo - Qdrant Health: http://localhost:6333/health
echo - Qdrant Collections: http://localhost:6333/collections
echo.
echo Next Steps:
echo - Run 'start-dev.bat' to start the application server
echo - Run 'health-check.bat' to verify all services
echo - Run 'stop-services.bat' to stop all services
echo.
echo To view service logs:
echo - docker compose logs postgres
echo - docker compose logs redis  
echo - docker compose logs qdrant
echo.
echo To monitor resource usage:
echo - docker stats
echo.
echo ================================================================
pause