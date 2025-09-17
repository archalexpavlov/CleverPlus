# Database Design Architecture

## Overview

Multi-tenant database architecture using PostgreSQL Row Level Security (RLS) with shared schema approach for AI agent platform supporting customer support and sales use cases.

## Core Principles

### Tenant Isolation Strategy
- **Shared Schema**: Single database with all tenant data in same tables
- **Logical Separation**: `tenant_id` column on every table for data isolation
- **RLS Enforcement**: Database-level security policies prevent cross-tenant access
- **Performance Optimized**: Composite indexes on `(tenant_id, *)` for fast queries

### Database Users Architecture
```sql
-- Admin user: schema changes, migrations, bypasses RLS
admin_user (SUPERUSER, CREATEDB, CREATEROLE)

-- Application user: runtime queries, subject to RLS policies  
app_user (LOGIN, limited privileges)
```

## Table Structure

### Core Tables
1. **tenants** - Root isolation boundary (organizations)
2. **users** - People within tenants (roles, permissions)  
3. **conversations** - Chat sessions (support/sales context)
4. **messages** - Individual chat messages (AI/human/system)

### Key Design Decisions

**tenant_id as INTEGER:**
- Faster joins and indexes vs UUID
- Sequential allocation for better performance
- Sufficient scale for target use case

**Enum-based Field Values:**
- Centralized in `packages/core/enums.py`
- Stored as strings for readability
- Type safety via Python enums

**Composite Indexes:**
```sql
-- Performance-critical patterns
(tenant_id, status)        -- Active conversations per tenant
(tenant_id, user_id)       -- User's conversations  
(tenant_id, created_at)    -- Recent activity analytics
(conversation_id, created_at) -- Message ordering
```

## Migration Strategy

**Alembic Integration:**
- Auto-generated migrations from model changes
- Version-controlled schema evolution
- Production-safe rollback capability

**RLS Application Process:**
1. Create tables via Alembic migrations
2. Enable RLS via SQL scripts  
3. Apply tenant isolation policies
4. Grant appropriate permissions

## Performance Considerations

**Index Strategy:**
- Primary indexes on all `tenant_id` columns
- Composite indexes for common query patterns
- Avoid over-indexing to maintain write performance

**Query Optimization:**
- RLS policies use simple equality checks
- Session variables for tenant context
- Connection pooling with tenant switching

## Security Model

**Defense in Depth:**
- Application-level tenant validation
- Database RLS as final security layer
- Audit logging for compliance

**Access Control:**
- Role-based permissions via `users.role` enum
- Tenant-scoped data access only
- No cross-tenant queries possible