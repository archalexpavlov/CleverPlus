# Pool Model + Row Level Security

## Architecture Overview

Combines the operational efficiency of shared database infrastructure with enterprise-grade tenant isolation using PostgreSQL's Row Level Security.

## Pool Model Benefits

**Shared Resources:**
- Single PostgreSQL instance serves all tenants
- Reduced operational overhead and costs
- Simplified deployment and maintenance
- Efficient resource utilization across tenants

**Challenges Addressed by RLS:**
- Data isolation between tenants
- Accidental cross-tenant queries
- Security policy enforcement
- Regulatory compliance requirements

## RLS Implementation

### Session Context Management
```python
# Application sets tenant context per request
SET app.current_tenant = '123'

# All subsequent queries automatically filtered
SELECT * FROM conversations  -- Only tenant 123 data returned
```

### Policy Enforcement
```sql
-- Automatic filtering on every table access
CREATE POLICY tenant_isolation ON conversations
USING (tenant_id = current_setting('app.current_tenant')::integer);
```

## Application Integration

### Connection Strategy
```python
# Single connection pool for all tenants
pool = create_pool(DATABASE_URL_APP)

# Per-request tenant switching
async with pool.acquire() as conn:
    await conn.execute("SET app.current_tenant = $1", tenant_id)
    # All queries now tenant-isolated
```

### Development Workflow
1. **Write normal queries** - no tenant filtering in application code
2. **RLS handles isolation** - database enforces tenant boundaries
3. **Test with different tenants** - switch context, verify isolation

## Security Guarantees

**Database-Level Enforcement:**
- Impossible to bypass RLS in application code
- Works with ORMs, raw SQL, admin tools
- Consistent across all database access methods

**Zero Trust Architecture:**
- Even admin mistakes won't leak tenant data
- Security policies centralized in database
- Audit trail for all tenant context switches

## Performance Characteristics

**Index Strategy:**
- All tenant_id columns indexed for fast filtering
- Composite indexes for common query patterns
- Query planner optimizes with RLS policies

**Connection Efficiency:**
- Single connection pool shared across tenants
- No per-tenant connection overhead
- Session variable switching is lightweight

## Best Practices

**Policy Design:**
- Simple equality checks for best performance
- Use session variables instead of database users
- Test policies thoroughly in development

**Error Handling:**
- Graceful handling of missing tenant context
- Clear error messages for policy violations
- Monitoring for RLS policy performance