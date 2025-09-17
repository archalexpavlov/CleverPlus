-- 01-init-rls-users.sql
-- Initialize Row Level Security users for AI Agent Platform
-- Uses passwords from /secrets

-- Create admin_user
DO $$
DECLARE
  admin_pwd text;
BEGIN
  admin_pwd := trim(pg_read_file('/secrets/db_admin_password', 0, 1024));
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'admin_user') THEN
    EXECUTE format('CREATE ROLE admin_user WITH LOGIN PASSWORD %L;', admin_pwd);
    RAISE NOTICE 'Created admin_user role';
  ELSE
    RAISE NOTICE 'admin_user role already exists';
  END IF;
END $$;

-- Create app_user
DO $$
DECLARE
  app_pwd text;
BEGIN
  app_pwd := trim(pg_read_file('/secrets/db_app_password', 0, 1024));
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_user') THEN
    EXECUTE format('CREATE ROLE app_user WITH LOGIN PASSWORD %L;', app_pwd);
    RAISE NOTICE 'Created app_user role';
  ELSE
    RAISE NOTICE 'app_user role already exists';
  END IF;
END $$;

-- Grant privileges to admin_user (can do everything, bypass RLS)
GRANT ALL PRIVILEGES ON DATABASE clever_db TO admin_user;
ALTER ROLE admin_user BYPASSRLS;
ALTER ROLE admin_user CREATEDB;
ALTER ROLE admin_user CREATEROLE;

-- Grant limited privileges to app_user (normal application operations)
GRANT CONNECT ON DATABASE clever_db TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;

-- Grant table permissions to app_user (for existing and future tables)
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;

-- Grant sequence permissions to app_user (for SERIAL columns)
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE ON SEQUENCES TO app_user;

-- Log the setup completion
SELECT 
  rolname as role_name,
  rolcanlogin as can_login,
  rolbypassrls as bypasses_rls,
  rolcreatedb as can_create_db
FROM pg_roles 
WHERE rolname IN ('admin_user', 'app_user')
ORDER BY rolname;