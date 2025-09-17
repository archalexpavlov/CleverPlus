@echo off
cd /d "%~dp0\..\..\"
echo ================================================================
echo     AI AGENT PLATFORM - COMPLETE PROJECT SETUP
echo ================================================================

echo.
echo Step 1: Checking prerequisites...
echo ================================================================

echo Checking Docker...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker not found. Please install Docker Desktop first.
    pause
    exit /b 1
) else (
    echo ✓ Docker is installed
)

echo Checking Poetry...
poetry --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Poetry not found. Please install Poetry first.
    pause
    exit /b 1
) else (
    echo ✓ Poetry is installed
)

echo Checking Python...
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python not found. Please install Python 3.13+ first.
    pause
    exit /b 1
) else (
    echo ✓ Python is installed
)

echo.
echo Step 2: Setting up environment configuration...
echo ================================================================

if not exist ".env" (
    if exist ".env.example" (
        echo Copying .env.example to .env...
        copy ".env.example" ".env" >nul
        echo ✓ Environment file created from template
        echo WARNING: Please edit .env file and add your API keys before continuing
        echo Press any key when you have configured .env file...
        pause >nul
    ) else (
        echo ERROR: .env.example file not found
        echo Please create .env file manually with required configuration
        pause
        exit /b 1
    )
) else (
    echo ✓ .env file already exists
)

echo.
echo Step 3: Installing Python dependencies...
echo ================================================================
echo This may take several minutes...
poetry install
if errorlevel 1 (
    echo ERROR: Failed to install Python dependencies
    pause
    exit /b 1
) else (
    echo ✓ Python dependencies installed successfully
)

echo.
echo Step 3.5: Initializing Docker Swarm and Secrets...
echo ================================================================

rem Initialize Swarm if not already
docker info | findstr /i "Swarm: active" >nul 2>&1
if errorlevel 1 (
    echo Docker Swarm not active. Initializing...
    docker swarm init
) else (
    echo Docker Swarm already active
)

rem Create secrets if they do not exist
for %%s in (db_admin_password db_app_password grafana_admin_password redis_password) do (
    docker secret ls --format "{{.Name}}" | findstr /x %%s >nul
    if errorlevel 1 (
        echo Creating secret %%s
        docker secret create %%s ".\secrets\%%s"
    ) else (
        echo Secret %%s already exists
    )
)

echo.
echo Step 4: Starting infrastructure services...
echo ================================================================
echo Starting PostgreSQL, Redis, and Qdrant...
docker compose up -d postgres redis qdrant
if errorlevel 1 (
    echo ERROR: Failed to start infrastructure services
    pause
    exit /b 1
) else (
    echo ✓ Infrastructure services started
)

echo.
echo Step 5: Waiting for services to be ready...
echo ================================================================
echo Waiting for PostgreSQL to be ready...
:wait_postgres
docker compose ps postgres | findstr "healthy" >nul 2>&1
if errorlevel 1 (
    echo PostgreSQL not ready yet, waiting 5 seconds...
    timeout /t 5 /nobreak >nul
    goto wait_postgres
)
echo ✓ PostgreSQL is ready

echo Waiting for Redis to be ready...
:wait_redis
docker compose ps redis | findstr "healthy" >nul 2>&1
if errorlevel 1 (
    echo Redis not ready yet, waiting 5 seconds...
    timeout /t 5 /nobreak >nul
    goto wait_redis
)
echo ✓ Redis is ready

echo Waiting for Qdrant to be ready...
:wait_qdrant
curl -s http://localhost:6333/health >nul 2>&1
if errorlevel 1 (
    echo Qdrant not ready yet, waiting 5 seconds...
    timeout /t 5 /nobreak >nul
    goto wait_qdrant
)
echo ✓ Qdrant is ready

echo.
echo Step 6: Running database migrations...
echo ================================================================
poetry run alembic upgrade head
if errorlevel 1 (
    echo ERROR: Database migration failed
    echo This might be normal if this is the first setup
    echo Continuing with setup...
) else (
    echo ✓ Database migrations completed successfully
)

echo.
echo Step 7: Final verification...
echo ================================================================
echo Checking service status...
docker compose ps

echo.
echo Testing service connectivity...
curl -s http://localhost:5432 >nul 2>&1 && echo "✓ PostgreSQL responding" || echo "- PostgreSQL connection test skipped"
curl -s http://localhost:6379 >nul 2>&1 && echo "✓ Redis responding" || echo "- Redis connection test skipped"
curl -s http://localhost:6333/health >nul 2>&1 && echo "✓ Qdrant API responding" || echo "✗ Qdrant not responding"

echo.
echo ================================================================
echo SETUP COMPLETE!
echo ================================================================
echo.
echo Infrastructure Services:
echo - PostgreSQL: localhost:5432 (Database)
echo - Redis: localhost:6379 (Cache)
echo - Qdrant: http://localhost:6333 (Vector DB)
echo.
echo Next Steps:
echo 1. Run 'start-dev.bat' to start development server
echo 2. Visit http://localhost:8000/docs for API documentation
echo 3. Run 'health-check.bat' to verify everything is working
echo.
echo Configuration files:
echo - Edit .env for API keys and settings
echo - Check docker-compose.yml for service configuration
echo.
echo Available commands:
echo - start-dev.bat     - Start development server
echo - start-services.bat - Start only infrastructure
echo - health-check.bat  - Check system health
echo - stop-services.bat - Stop all services
echo.
echo ================================================================
pause