# Clever+ AI Agent Platform

Universal platform for creating enterprise AI agents with hybrid architecture and smart routing strategy.

## Getting Started

1. Install prerequisites: Docker, Python 3.13+, Poetry
2. In the project root, create a folder secrets and add 4 files (no extensions): 
- db_admin_password
- db_app_password
- grafana_admin_password
- redis_password
3. Run setup from \tools\build-scripts: `setup-project.bat`
4. Start development: `start-dev.bat`

## Architecture

- **FastAPI** - Web framework
- **LiteLLM** - Universal AI gateway
- **PostgreSQL** - Primary database
- **Redis** - Caching layer
- **Qdrant** - Vector database

For detailed documentation, see the project wiki at https://www.notion.so/Clever-Wiki-26f2f9743cb7804ea22dc74ef11c5f3c?source=copy_link