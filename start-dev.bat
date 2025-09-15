@echo off
echo ================================================================
echo     AI AGENT PLATFORM - DEVELOPMENT SERVER STARTUP
echo ================================================================

echo.
echo Step 1: Checking infrastructure services...
echo ================================================================

echo Checking if services are running...
docker compose ps postgres | findstr "healthy\|running" >nul 2>&1
if errorlevel 1 (
    echo PostgreSQL not running, starting infrastructure services...
    docker compose up -d postgres redis qdrant
    echo Waiting for services to be ready...
    timeout /t 15 /nobreak >nul
) else (
    echo ✓ Infrastructure services are running
)

echo.
echo Step 2: Verifying service health...
echo ================================================================

echo Checking PostgreSQL...
:wait_postgres
docker compose ps postgres | findstr "healthy" >nul 2>&1
if errorlevel 1 (
    echo PostgreSQL not healthy yet, waiting 5 seconds...
    timeout /t 5 /nobreak >nul
    goto wait_postgres
)
echo ✓ PostgreSQL is healthy

echo Checking Redis...
:wait_redis
docker compose ps redis | findstr "healthy" >nul 2>&1
if errorlevel 1 (
    echo Redis not healthy yet, waiting 5 seconds...
    timeout /t 5 /nobreak >nul
    goto wait_redis
)
echo ✓ Redis is healthy

echo Checking Qdrant...
:wait_qdrant
curl -s http://localhost:6333/health >nul 2>&1
if errorlevel 1 (
    echo Qdrant not responding yet, waiting 5 seconds...
    timeout /t 5 /nobreak >nul
    goto wait_qdrant
)
echo ✓ Qdrant is responding

echo.
echo Step 3: Running any pending migrations...
echo ================================================================
poetry run alembic upgrade head
if errorlevel 1 (
    echo WARNING: Migration check failed
    echo This might be normal if database schema is already up to date
) else (
    echo ✓ Database schema is up to date
)

echo.
echo Step 4: Starting development server...
echo ================================================================
echo.
echo Server Information:
echo - API Server: http://localhost:8000
echo - API Documentation: http://localhost:8000/docs
echo - Alternative Docs: http://localhost:8000/redoc
echo.
echo Infrastructure URLs:
echo - PostgreSQL: localhost:5432
echo - Redis: localhost:6379  
echo - Qdrant: http://localhost:6333
echo.
echo Press Ctrl+C to stop the development server
echo ================================================================
echo.

rem Start the development server with auto-reload
poetry run uvicorn apps.customer_support.main:app --reload --host 0.0.0.0 --port 8000

echo.
echo ================================================================
echo Development server stopped
echo ================================================================
echo.
echo To restart: run start-dev.bat
echo To stop all services: run stop-services.bat
echo To check system health: run health-check.bat
echo.
pause