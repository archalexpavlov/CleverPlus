# Migration Workflows

## Alembic Integration

### Development Process
1. Modify SQLAlchemy models
2. Generate migration: lembic revision --autogenerate
3. Review and edit migration script
4. Test migration: lembic upgrade head

### RLS Policy Migrations
`python
def upgrade():
    # Create table
    op.create_table(...)
    
    # Enable RLS
    op.execute("ALTER TABLE table_name ENABLE ROW LEVEL SECURITY")
    
    # Create policies
    op.execute("CREATE POLICY ...")
`

### Best Practices
- Always review auto-generated migrations
- Include RLS policies in migrations
- Test rollback scenarios

*TODO: Add migration templates and testing procedures*
