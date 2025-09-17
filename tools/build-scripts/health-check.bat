@echo off
cd /d "%~dp0\..\..\"
setlocal enabledelayedexpansion

rem Create timestamp for log file
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YY=%dt:~2,2%" & set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%"
set "HH=%dt:~8,2%" & set "Min=%dt:~10,2%" & set "Sec=%dt:~12,2%"
set "timestamp=%YYYY%-%MM%-%DD%_%HH%-%Min%-%Sec%"

rem Set log file name
set "logfile=health-check-%timestamp%.log"

echo ================================================================
echo          AI AGENT PLATFORM - SYSTEM HEALTH CHECK
echo ================================================================
echo.
echo Log file: %logfile%
echo Results will be saved to: %CD%\%logfile%
echo.

rem Function to echo both to screen and log file
call :log "================================================================"
call :log "         AI AGENT PLATFORM - SYSTEM HEALTH CHECK"
call :log "         Started at: %date% %time%"
call :log "================================================================"
call :log ""

call :log "================================================"
call :log "1. SYSTEM PREREQUISITES CHECK"
call :log "================================================"

call :log "Docker version:"
docker --version >> "%logfile%" 2>&1
call :log ""

call :log "Docker Compose version:"
docker compose version >> "%logfile%" 2>&1
call :log ""

call :log "Poetry version:"
poetry --version >> "%logfile%" 2>&1
call :log ""

call :log "Python version:"
python --version >> "%logfile%" 2>&1
call :log ""

call :log "Docker system info:"
docker system df >> "%logfile%" 2>&1
call :log ""

call :log "================================================"
call :log "2. CONTAINER STATUS OVERVIEW"
call :log "================================================"

call :log "All containers in the project:"
docker compose ps >> "%logfile%" 2>&1
call :log ""

call :log "Container resource usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" >> "%logfile%" 2>&1
call :log ""

call :log "================================================"
call :log "3. INFRASTRUCTURE SERVICES HEALTH"
call :log "================================================"

call :log "--- PostgreSQL Database ---"
docker compose ps postgres >> "%logfile%" 2>&1
docker compose exec postgres pg_isready -U admin_user >> "%logfile%" 2>&1 && (
    call :log "✓ PostgreSQL connection OK"
) || (
    call :log "✗ PostgreSQL connection failed"
)

docker compose exec postgres psql -U admin_user -d clever_db -c "SELECT version();" >> "%logfile%" 2>&1 && (
    call :log "✓ PostgreSQL database accessible"
) || (
    call :log "✗ PostgreSQL database not accessible"
)
call :log ""

call :log "--- Redis Cache ---"
docker compose ps redis >> "%logfile%" 2>&1
docker compose exec redis redis-cli -a clever_redis_password_2025 ping >> "%logfile%" 2>&1 && (
    call :log "✓ Redis responding to ping"
) || (
    call :log "✗ Redis not responding"
)

docker compose exec redis redis-cli -a clever_redis_password_2025 info memory >> "%logfile%" 2>&1 && (
    call :log "✓ Redis memory info accessible"
) || (
    call :log "✗ Redis memory info failed"
)
call :log ""

call :log "--- Qdrant Vector Database ---"
docker compose ps qdrant >> "%logfile%" 2>&1
curl -s http://localhost:6333/health >> "%logfile%" 2>&1
curl -s http://localhost:6333/health | findstr "ok" >nul && (
    call :log "✓ Qdrant API healthy"
) || (
    call :log "✗ Qdrant API not healthy"
)

curl -s http://localhost:6333/collections >> "%logfile%" 2>&1 && (
    call :log "✓ Qdrant collections endpoint accessible"
) || (
    call :log "✗ Qdrant collections endpoint failed"
)
call :log ""

call :log "================================================"
call :log "4. APPLICATION HEALTH CHECK"
call :log "================================================"

call :log "Testing if application would start (dry run)..."
poetry check >> "%logfile%" 2>&1 && (
    call :log "✓ Poetry configuration valid"
) || (
    call :log "✗ Poetry configuration invalid"
)

call :log "Checking Python dependencies..."
poetry show --tree >> "%logfile%" 2>&1 && (
    call :log "✓ All Python dependencies resolved"
) || (
    call :log "✗ Python dependency issues found"
)
call :log ""

call :log "================================================"
call :log "5. NETWORK CONNECTIVITY TESTS"
call :log "================================================"

call :log "Testing service connectivity..."
curl -s --connect-timeout 5 http://localhost:5432 >nul 2>&1 && (
    call :log "✓ PostgreSQL port accessible"
) || (
    call :log "- PostgreSQL port test (expected to fail)"
)

curl -s --connect-timeout 5 http://localhost:6379 >nul 2>&1 && (
    call :log "✓ Redis port accessible"
) || (
    call :log "- Redis port test (expected to fail)"
)

curl -s --connect-timeout 5 http://localhost:6333/health >nul 2>&1 && (
    call :log "✓ Qdrant HTTP API accessible"
) || (
    call :log "✗ Qdrant HTTP API not accessible"
)
call :log ""

call :log "================================================"
call :log "6. ENVIRONMENT CONFIGURATION CHECK"
call :log "================================================"

if exist ".env" (
    call :log "✓ .env file exists"
    findstr "DATABASE_URL" .env >nul && call :log "✓ DATABASE_URL configured" || call :log "✗ DATABASE_URL missing"
    findstr "REDIS_URL" .env >nul && call :log "✓ REDIS_URL configured" || call :log "✗ REDIS_URL missing"
    findstr "QDRANT_URL" .env >nul && call :log "✓ QDRANT_URL configured" || call :log "✗ QDRANT_URL missing"
    findstr "SECRET_KEY" .env >nul && call :log "✓ SECRET_KEY configured" || call :log "✗ SECRET_KEY missing"
    findstr "OPENAI_API_KEY" .env >nul && call :log "✓ OPENAI_API_KEY configured" || call :log "- OPENAI_API_KEY not set (optional)"
) else (
    call :log "✗ .env file missing"
)
call :log ""

call :log "================================================"
call :log "7. RECENT LOGS ANALYSIS"
call :log "================================================"

call :log "Recent container logs (last 10 lines per service):"
call :log ""

call :log "--- PostgreSQL Recent Logs ---"
docker compose logs --tail=10 postgres >> "%logfile%" 2>&1
call :log ""

call :log "--- Redis Recent Logs ---"
docker compose logs --tail=10 redis >> "%logfile%" 2>&1
call :log ""

call :log "--- Qdrant Recent Logs ---"
docker compose logs --tail=10 qdrant >> "%logfile%" 2>&1
call :log ""

call :log "================================================"
call :log "8. STORAGE AND PERFORMANCE CHECK"
call :log "================================================"

call :log "Docker volumes:"
docker volume ls | findstr clever >> "%logfile%" 2>&1
call :log ""

call :log "Disk usage by Docker:"
docker system df >> "%logfile%" 2>&1
call :log ""

call :log "================================================"
call :log "HEALTH CHECK SUMMARY"
call :log "================================================"
call :log "Health check completed at: %date% %time%"
call :log ""
call :log "Service URLs:"
call :log "- PostgreSQL: localhost:5432 (Database)"
call :log "- Redis: localhost:6379 (Cache)" 
call :log "- Qdrant: http://localhost:6333 (Vector DB)"
call :log "- API Docs: http://localhost:8000/docs (when app running)"
call :log ""
call :log "Development Commands:"
call :log "- setup-project.bat  - First-time setup"
call :log "- start-dev.bat      - Start development server"
call :log "- start-services.bat - Start only infrastructure"
call :log "- stop-services.bat  - Stop all services"
call :log "================================================"

echo.
echo ================================================================
echo HEALTH CHECK COMPLETE!
echo ================================================================
echo.
echo Results have been saved to: %logfile%
echo.
echo Summary of key findings:
type "%logfile%" | findstr "✓\|✗"
echo.
echo To view the full log:
echo   type %logfile%
echo.
echo To open log in notepad:
echo   notepad %logfile%
echo.
echo ================================================================
pause
goto :eof

:log
echo %~1
echo %~1 >> "%logfile%"
goto :eof