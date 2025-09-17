# Deployment Strategy

🔑 Secrets

Сreate a secrets/ folder in the project root with the following files (no extensions):

-db_admin_password - PostgreSQL admin user
-db_app_password - PostgreSQL app user
-grafana_admin_password - Grafana admin
-redis_password - Redis authentication

These files are mounted into containers at /secrets and referenced via *_FILE environment variables.

*TODO: Add detailed deployment procedures and rollback strategies*
