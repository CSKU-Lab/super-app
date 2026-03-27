---
name: database-migrations
description: Atlas and database migration patterns for PostgreSQL and MongoDB
license: MIT
compatibility: opencode
metadata:
  audience: experienced-developers
  databases: postgresql,mongodb
  tools: atlas,sqlx
---

# Database Migrations

This skill covers Atlas and database migration patterns for PostgreSQL and MongoDB. Use this when managing schema changes, creating migrations, or working with database versioning.

## PostgreSQL Migrations (main-server)

### Directory Structure

```
main-server/
├── postgresql/
│   ├── migrations/
│   │   ├── 001_create_users_table.sql
│   │   ├── 002_create_submissions_table.sql
│   │   ├── 003_add_user_roles.sql
│   │   └── ...
│   └── schema.sql              # Reference schema (generated)
└── atlas/
    └── schema.hcl              # Atlas schema definition
```

### Migration Format

**Naming Convention: `{number}_{description}.sql`**

```sql
-- 001_create_users_table.sql
-- Timestamp: 2026-03-28T10:30:00Z
-- Author: team

BEGIN;

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    role VARCHAR(50) DEFAULT 'student',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at);

COMMIT;
```

### Migration Rules

**Must Follow:**

1. **Idempotent Migrations**: Can run multiple times safely
   ```sql
   -- Good: Use IF NOT EXISTS
   CREATE TABLE IF NOT EXISTS users (id UUID PRIMARY KEY);
   
   -- Bad: Will fail on re-run
   CREATE TABLE users (id UUID PRIMARY KEY);
   ```

2. **Backward Compatibility**: Old code must work with new schema
   ```sql
   -- Good: Add column with default
   ALTER TABLE users ADD COLUMN role VARCHAR(50) DEFAULT 'student';
   
   -- Bad: Required column breaks old code
   ALTER TABLE users ADD COLUMN role VARCHAR(50) NOT NULL;
   ```

3. **Explicit Transactions**: Wrap changes in BEGIN/COMMIT
   ```sql
   BEGIN;
   CREATE TABLE submissions (...);
   CREATE INDEX idx_submissions_user_id ON submissions(user_id);
   COMMIT;
   ```

4. **Meaningful Constraints**: Use proper constraints
   ```sql
   -- Good: Explicit constraints
   CREATE TABLE users (
       id UUID PRIMARY KEY,
       email VARCHAR(255) NOT NULL UNIQUE,
       CONSTRAINT uc_users_email UNIQUE (email)
   );
   
   -- Avoid: Generic constraints
   CREATE TABLE users (id UUID PRIMARY KEY);
   ```

5. **Document Changes**: Include comments
   ```sql
   -- Adds role-based access control support
   -- Supports roles: admin, instructor, student, grader
   ALTER TABLE users ADD COLUMN role VARCHAR(50) DEFAULT 'student';
   ```

### Running Migrations

**Using Migration Script:**
```bash
cd main-server

# Run all pending migrations
./scripts/migrate.sh up

# Rollback last migration
./scripts/migrate.sh down

# Show migration status
./scripts/migrate.sh status

# Migrate to specific version
./scripts/migrate.sh goto 5
```

**Using Atlas CLI:**
```bash
# First, install atlas
go install ariga.io/atlas/cmd/atlas@latest

# Verify migrations
atlas migrate validate -dir file://postgresql/migrations

# Apply migrations
atlas migrate apply \
  --dir file://postgresql/migrations \
  --url postgresql://user:pass@localhost:5432/csku

# Rollback last migration
atlas migrate down --dir file://postgresql/migrations
```

### Handling Rollbacks

**Up Migration (creates table):**
```sql
-- 001_create_users_table.sql
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) NOT NULL
);
```

**Down Migration (drops table):**
```sql
-- 001_create_users_table.rollback.sql
DROP TABLE IF EXISTS users;
```

### Common Migration Patterns

**Adding a Column with Data Migration:**
```sql
BEGIN;

-- Add new column
ALTER TABLE users ADD COLUMN status VARCHAR(50) DEFAULT 'active';

-- Migrate existing data
UPDATE users SET status = CASE 
    WHEN deleted_at IS NOT NULL THEN 'deleted'
    ELSE 'active' 
END WHERE status = 'active';

COMMIT;
```

**Renaming a Column (3-step process):**
```sql
-- Step 1: Add new column with data
BEGIN;
ALTER TABLE submissions ADD COLUMN code_content TEXT;
UPDATE submissions SET code_content = code_text;
COMMIT;

-- Step 2: Update app code to use new column
-- ... deploy change ...

-- Step 3: Drop old column
BEGIN;
ALTER TABLE submissions DROP COLUMN code_text;
COMMIT;
```

**Creating an Index Safely:**
```sql
BEGIN;
-- CONCURRENTLY prevents table locks during index creation
CREATE INDEX CONCURRENTLY idx_submissions_status ON submissions(status);
COMMIT;
```

## Atlas Schema Management

### Atlas Configuration

**atlas/schema.hcl (PostgreSQL):**
```hcl
variable "db_url" {
  type = string
}

data "sql" "migrate_dir" {
  url = var.db_url
}

env "local" {
  url = "postgresql://csku:dev_password@localhost:5432/csku"
  dev = "docker://postgres/15"
}

env "production" {
  url = var.db_url
  dev = "docker://postgres/15"
  
  # Prevent destructive changes
  protection {
    drop_column = true
    drop_table = true
  }
}
```

### Using Atlas

**Validate Current Schema:**
```bash
atlas schema validate \
  --url "postgresql://user:pass@localhost:5432/csku" \
  --dev-url "docker://postgres/15"
```

**Generate Migration from Schema:**
```bash
# Inspect current schema
atlas schema inspect \
  --url "postgresql://user:pass@localhost:5432/csku"

# Generate missing migrations
atlas migrate diff create_users \
  --env local
```

**Apply Migrations:**
```bash
atlas migrate apply \
  --env local
```

## MongoDB Schema Management

### Document Structure

MongoDB doesn't enforce schemas like PostgreSQL, but we should document structure:

```go
// domain/models.go - Document structure definition
type Config struct {
    ID        string    `bson:"_id"`
    Key       string    `bson:"key"`
    Value     string    `bson:"value"`
    CreatedAt time.Time `bson:"created_at"`
    UpdatedAt time.Time `bson:"updated_at"`
}
```

### Schema Validation (Optional)

Enable JSON Schema validation in MongoDB:

```javascript
// In mongosh or Atlas
db.createCollection("configs", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["key", "value"],
      properties: {
        _id: { bsonType: "objectId" },
        key: { bsonType: "string" },
        value: { bsonType: "string" },
        created_at: { bsonType: "date" }
      }
    }
  }
})
```

### Indexing Strategy

**Create indexes for query performance:**

```go
// In service initialization
indexModel := mongo.IndexModel{
    Keys: bson.D{
        {Key: "key", Value: 1},
    },
    Options: options.Index().SetUnique(true),
}

collection.Indexes().CreateOne(context.Background(), indexModel)
```

### Data Migration in Go

**Migrate all documents:**

```go
func migrateConfigStatus(ctx context.Context, collection *mongo.Collection) error {
    filter := bson.M{"status": bson.M{"$exists": false}}
    
    update := bson.M{
        "$set": bson.M{"status": "active"},
    }
    
    result, err := collection.UpdateMany(ctx, filter, update)
    if err != nil {
        return err
    }
    
    fmt.Printf("Updated %d documents\n", result.ModifiedCount)
    return nil
}
```

## Best Practices

### Before Running Migrations

1. **Back up database** in production
2. **Test locally** first
3. **Review changes** with team
4. **Plan downtime** if needed
5. **Have rollback plan**

### Migration Checklist

- [ ] Migration is idempotent
- [ ] New constraints are explicit
- [ ] Backward compatible with current code
- [ ] Performance impact considered (large table changes)
- [ ] Indexes added for foreign keys
- [ ] Comments document the purpose
- [ ] Tested in local environment
- [ ] Code changes deployed with migration

### Troubleshooting Migrations

**Migration Failed Midway:**
```bash
# Check current state
./scripts/migrate.sh status

# Fix the schema manually if needed
psql -h localhost -U csku -d csku_lab

# Reset migrations (development only!)
./scripts/migrate.sh reset
```

**Migration Causes Timeout:**
```sql
-- Large table? Use CONCURRENTLY
CREATE INDEX CONCURRENTLY idx_large_table ON submissions(status);

-- Or batch the update
UPDATE submissions SET status = 'active' 
WHERE id IN (
  SELECT id FROM submissions LIMIT 10000
);
```

**Data Consistency Issues:**
```bash
# Compare schemas
atlas schema inspect --url "postgres://..." > current.sql
atlas schema inspect --url "postgres://..." > expected.sql
diff current.sql expected.sql
```

## Development Workflow

### Creating a New Migration

1. **Identify the change needed**
2. **Write migration file** with clear naming
3. **Test locally** with `./scripts/migrate.sh up`
4. **Verify backward compatibility**
5. **Commit to git** (migrations are part of code)
6. **Test in staging** before production

### Collaboration

- **One migration per feature branch**
- **Never edit migrations after merge** (breaks versioning)
- **Coordinate large schema changes** with team
- **Use descriptive names** for clarity

---

**When to use this skill:** Use this when managing database schema changes, running migrations, working with Atlas, or troubleshooting database versioning issues.
