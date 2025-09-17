# Tenant Isolation with PostgreSQL RLS

## RLS Policy Implementation

### Core Isolation Policies
```sql
-- Enable RLS on all tenant tables
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;  
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Create isolation policies
CREATE POLICY tenant_isolation ON users
USING (tenant_id = current_setting('app.current_tenant', true)::integer);

CREATE POLICY conversation_isolation ON conversations  
USING (tenant_id = current_setting('app.current_tenant', true)::integer);

CREATE POLICY message_isolation ON messages
USING (tenant_id = current_setting('app.current_tenant', true)::integer);
```

### Session Context Management
```python
# Application responsibility per request
async def set_tenant_context(conn, tenant_id: int):
    await conn.execute(
        "SET LOCAL app.current_tenant = $1", tenant_id
    )

# Usage in request handlers
@app.middleware("http")
async def tenant_middleware(request, call_next):
    tenant_id = extract_tenant_from_request(request)
    async with db.acquire() as conn:
        await set_tenant_context(conn, tenant_id)
        response = await call_next(request)
    return response
```

## Security Validation

### Testing Isolation
```python
# Test: Tenant A cannot see Tenant B data
async def test_tenant_isolation():
    # Create data for tenant 1
    await set_tenant_context(conn, 1)
    user_1 = await create_user("alice@tenant1.com")
    
    # Switch to tenant 2  
    await set_tenant_context(conn, 2)
    users = await get_all_users()
    
    # Verify tenant 1 user not visible
    assert user_1 not in users
```

### Policy Bypass Prevention
```sql
-- Ensure non-superusers cannot bypass RLS
REVOKE BYPASSRLS ON ALL TABLES FROM app_user;

-- Force RLS even for table owners (optional)
ALTER TABLE users FORCE ROW LEVEL SECURITY;
```

## Error Handling

### Missing Tenant Context
```python
# Graceful handling when tenant context missing
CREATE POLICY tenant_isolation_safe ON users
USING (
    CASE 
        WHEN current_setting('app.current_tenant', true) IS NULL 
        THEN false  -- Deny access if no tenant set
        ELSE tenant_id = current_setting('app.current_tenant', true)::integer
    END
);
```

### Policy Violations
```python
# Application error handling
try:
    result = await conn.fetchall("SELECT * FROM users")
except Exception as e:
    if "row security" in str(e).lower():
        raise TenantIsolationError("Access denied to tenant data")
```

## Monitoring and Auditing

### RLS Policy Performance
```sql
-- Monitor policy execution costs
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM conversations WHERE status = 'active';

-- Should show index usage on (tenant_id, status)
```

### Access Logging
```python
# Log all tenant context switches
logger.info(f"Tenant context set: {tenant_id}", extra={
    "tenant_id": tenant_id,
    "user_id": current_user_id,
    "request_id": request.headers.get("x-request-id")
})
```

## Development Guidelines

### Local Testing
```sql
-- Test RLS policies in development
SET app.current_tenant = '1';
SELECT count(*) FROM users;  -- Should only show tenant 1 users

SET app.current_tenant = '2';  
SELECT count(*) FROM users;  -- Should only show tenant 2 users
```

### Migration Safety
```sql
-- Always test RLS policies before production
-- Use separate staging environment with production data copy
-- Verify no cross-tenant data leakage after policy changes
```

## Common Pitfalls

**Policy Order:** PostgreSQL evaluates policies with OR logic - ensure restrictive policies
**Session Scope:** Use SET LOCAL for transaction-scoped tenant context
**Index Usage:** Ensure tenant_id is first column in composite indexes for RLS performance
**Testing:** Always test with multiple tenants to verify complete isolation