# Role-Based Access Control (RBAC)

## Role Hierarchy

### Customer Support Roles
- **customer**: Basic read access
- **agent**: Ticket management
- **admin**: Full system access

### Internal Sales Roles  
- **sales_rep**: Own leads and opportunities
- **sales_manager**: Team data access
- **analyst**: Read-only analytics access
- **admin**: Full system control

## Implementation

### Database Level
- RLS policies per role
- Function-based access control

### Application Level  
- JWT-based authentication
- Role-based route protection
- API endpoint authorization

*TODO: Add role matrix and permission mappings*
