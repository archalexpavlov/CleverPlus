# Pool Model + RLS - Multi-Tenant Data Architecture

## What is Pool Model + RLS?

**Pool Model** is a multi-tenant architecture where all tenants share the same database and tables, with tenant isolation achieved through **Row-Level Security (RLS)** - a PostgreSQL feature that automatically filters data at the database level.

## Role in the Project

Pool Model + RLS serves as the foundation of our multi-tenant AI Agent Platform, providing:

* **Tenant Isolation**: Ensures each tenant can only access their own data
* **Cost Efficiency**: Single database shared across all tenants
* **Security by Design**: Database-level enforcement prevents cross-tenant leaks
* **Operational Simplicity**: One database to manage, backup, and scale

## How It Works

1. **Shared Tables**: All tenants use the same tables with `tenant_id` columns
2. **RLS Policies**: PostgreSQL automatically filters rows based on tenant context
3. **Session Context**: Application sets tenant ID at connection time
4. **Automatic Filtering**: All queries automatically include tenant isolation

```sql
-- Enable RLS on table
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Create isolation policy
CREATE POLICY tenant_isolation ON orders 
FOR ALL TO app_user 
USING (tenant_id = current_setting('app.tenant_id')::uuid);
```

```python
# Set tenant context in application
def get_db_session(tenant_id: str):
    session = SessionLocal()
    session.execute(text(f"SET LOCAL app.tenant_id = '{tenant_id}'"))
    return session
```

## Architecture Models Comparison

| Model | Database Setup | Isolation | Cost | Complexity |
|-------|---------------|-----------|------|------------|
| **Silo** | One DB per tenant | Maximum | High | High |
| **Bridge** | Shared DB, separate schemas | Medium | Medium | Medium |
| **Pool + RLS** | Shared DB & tables | High | Low | Low |

## Key Components

* **`tenant_id`**: UUID column in all tenant-aware tables
* **RLS Policies**: Database rules defining row access
* **Session Variables**: Runtime tenant context (`app.tenant_id`)
* **Application Role**: Database user without `BYPASSRLS` privilege

## Benefits

* **Zero-Leak Guarantee**: Impossible to accidentally access other tenant's data
* **Performance**: Efficient indexing and query optimization
* **Scalability**: Single database scales horizontally
* **Development Speed**: No complex tenant routing logic
* **Compliance Ready**: Built-in audit trails and data isolation

## Integration with Alembic

```python
def upgrade():
    # Create table with tenant_id
    op.create_table('products',
        sa.Column('id', postgresql.UUID(), nullable=False),
        sa.Column('tenant_id', postgresql.UUID(), nullable=False),
        sa.Column('name', sa.String(255), nullable=False)
    )
    
    # Enable RLS
    op.execute("ALTER TABLE products ENABLE ROW LEVEL SECURITY")
    
    # Create tenant isolation policy
    op.execute("""
        CREATE POLICY tenant_isolation ON products 
        FOR ALL TO app_user 
        USING (tenant_id = current_setting('app.tenant_id')::uuid)
    """)
```

## In Our Architecture

**Project A (Customer Support)**: Simple tenant isolation for customer data
- Basic RLS policies for ticket management
- Shared knowledge base with tenant-specific content

**Project B (Internal Sales)**: Complex multi-level access control
- Tenant + role-based policies for CRM data  
- Advanced permissions for sales team hierarchy

Both projects benefit from centralized security enforcement and operational simplicity while maintaining strict data isolation.