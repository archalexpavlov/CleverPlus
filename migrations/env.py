# migrations/env.py
# This file connects Alembic (migration tool) to your actual database
# It's like a bridge between migration scripts and your PostgreSQL database

# Import Python's logging system to control what messages get printed
from logging.config import fileConfig

# Import SQLAlchemy tools for database connections
from sqlalchemy import engine_from_config
from sqlalchemy import pool

# Import Alembic's context - this gives us access to migration settings
from alembic import context

# Get Alembic's configuration object
# This contains all settings from alembic.ini file
config = context.config

# Import tools for loading environment variables (passwords, URLs, etc.)
import os
from dotenv import load_dotenv

# Load variables from .env file (like DATABASE_URL, passwords)
# This keeps secrets out of your code
load_dotenv()

# Set database URL from environment variables - using synchronized URL for Alembic
# Why two URLs? 
# - DATABASE_URL_SYNC: synchronous driver for migrations (postgresql://)
# - DATABASE_URL: asynchronous driver for the main app (postgresql+asyncpg://)
# Alembic needs synchronous connections, so we use the SYNC version
database_url = os.getenv("DATABASE_URL_SYNC") or os.getenv("DATABASE_URL", "").replace("postgresql+asyncpg://", "postgresql://")
if database_url:
    # Override the URL from alembic.ini with the one from environment variables
    config.set_main_option("sqlalchemy.url", database_url)
else:
    # If no database URL is found, stop with an error
    raise ValueError("DATABASE_URL environment variable is not set!")

# Setup Python logging based on alembic.ini configuration
# This controls what information gets printed during migrations
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Import your database models for auto-generation of migrations
from packages.core.models import Base
target_metadata = Base.metadata

# You can get other settings from alembic.ini if needed:
# my_important_option = config.get_main_option("my_important_option")


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode.
    
    Offline mode means:
    - No actual database connection is made
    - Migration commands are just printed as SQL text
    - Useful for generating SQL scripts to run manually
    - Faster for testing what changes would be made
    """
    # Get the database URL from our configuration
    url = config.get_main_option("sqlalchemy.url")
    
    # Configure the migration context with just the URL
    # No database engine is created - just generates SQL
    context.configure(
        url=url,
        target_metadata=target_metadata,  # Our models from packages/core/models.py
        literal_binds=True,              # Don't use parameter placeholders
        dialect_opts={"paramstyle": "named"},  # Use :parameter_name style
    )

    # Execute the migration within a transaction context
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Run migrations in 'online' mode.
    
    Online mode means:
    - Creates a real database connection
    - Actually executes SQL commands against the database
    - This is the normal mode when running migrations
    """
    # Create a database engine (connection manager) from our configuration
    # NullPool means don't keep connections open after use
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),  # Get database settings
        prefix="sqlalchemy.",  # Only use settings that start with "sqlalchemy."
        poolclass=pool.NullPool,  # Don't pool connections for migrations
    )

    # Use the database connection to run migrations
    with connectable.connect() as connection:
        # Configure migration context with the real database connection
        context.configure(
            connection=connection,           # Use this database connection
            target_metadata=target_metadata  # Our models from packages/core/models.py
        )

        # Execute migrations within a database transaction
        # If something goes wrong, changes get rolled back automatically
        with context.begin_transaction():
            context.run_migrations()


# Determine which mode to run in and execute
# Alembic automatically detects if it should run online or offline
if context.is_offline_mode():
    run_migrations_offline()   # Generate SQL only, don't connect to database
else:
    run_migrations_online()    # Connect to database and run migrations