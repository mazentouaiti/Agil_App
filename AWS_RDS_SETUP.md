# Agil App - AWS RDS PostgreSQL Integration

This document explains how to set up and configure AWS RDS PostgreSQL for the Agil Distribution Tunisia Flutter application.

## Overview

The Agil App now supports both PostgreSQL (via AWS RDS) and SQLite databases with automatic fallback functionality. The app will attempt to connect to PostgreSQL first and fall back to SQLite if the connection fails.

## Features

- **Hybrid Database System**: Supports both PostgreSQL and SQLite
- **Automatic Fallback**: Falls back to SQLite if PostgreSQL is unavailable
- **Database Migration System**: Manages schema changes and updates
- **Connection Health Monitoring**: Real-time database status monitoring
- **Data Export/Import**: Backup and restore functionality
- **Database Switching**: Switch between PostgreSQL and SQLite on-the-fly

## AWS RDS Setup

### 1. Create RDS Instance

1. **Login to AWS Console**
   - Go to [AWS RDS Console](https://console.aws.amazon.com/rds/)

2. **Create Database**
   - Click "Create database"
   - Choose "Standard create"
   - Engine type: PostgreSQL
   - Version: PostgreSQL 15.4 (or latest)

3. **Instance Configuration**
   - DB instance class: `db.t3.micro` (for development) or `db.t3.small` (for production)
   - Storage: 20 GB General Purpose SSD (gp2)
   - Enable storage autoscaling: Yes
   - Maximum storage threshold: 100 GB

4. **Settings**
   - DB instance identifier: `agil-database`
   - Master username: `agil_admin`
   - Master password: Create a strong password

5. **Connectivity**
   - VPC: Default VPC (or create custom)
   - Public access: Yes (for development) or No (for production with VPN)
   - VPC security group: Create new or use existing
   - Database port: 5432

6. **Additional Configuration**
   - Initial database name: `agil_database`
   - Backup retention period: 7 days
   - Enable Enhanced monitoring: Yes
   - Enable Performance Insights: Yes

### 2. Configure Security Group

1. **Edit Security Group**
   - Go to EC2 → Security Groups
   - Find the RDS security group
   - Add inbound rule:
     - Type: PostgreSQL
     - Protocol: TCP
     - Port Range: 5432
     - Source: Your IP address or 0.0.0.0/0 (for development only)

### 3. Update Application Configuration

1. **Update Database Configuration**
   
   Edit `lib/core/config/database_config.dart`:
   
   ```dart
   class DatabaseConfig {
     // Update these with your RDS details
     static const String awsRdsHost = 'agil-database.xxxxx.us-east-1.rds.amazonaws.com';
     static const String awsRdsDatabase = 'agil_database';
     static const String awsRdsUsername = 'agil_admin';
     static const String awsRdsPassword = 'your-password';
     // ... rest of configuration
   }
   ```

2. **Update PostgreSQL Service**
   
   The PostgreSQL service will automatically use the configuration from `DatabaseConfig`.

## Environment Setup

### Development Environment

For development, you can use a local PostgreSQL instance:

```bash
# Install PostgreSQL locally
# Windows: Download from https://www.postgresql.org/download/windows/
# macOS: brew install postgresql
# Linux: sudo apt-get install postgresql

# Create local database
psql -U postgres
CREATE DATABASE agil_dev;
CREATE USER agil_dev_user WITH PASSWORD 'dev_password';
GRANT ALL PRIVILEGES ON DATABASE agil_dev TO agil_dev_user;
```

Update `database_config.dart` for development:

```dart
static Map<String, String> getConnectionConfig(DatabaseEnvironment env) {
  switch (env) {
    case DatabaseEnvironment.development:
      return {
        'host': 'localhost',
        'port': '5432',
        'database': 'agil_dev',
        'username': 'agil_dev_user',
        'password': 'dev_password',
      };
    // ... other environments
  }
}
```

### Production Environment

For production, use environment variables or AWS Secrets Manager:

```dart
// Example using environment variables
static String get awsRdsHost => 
    Platform.environment['RDS_HOST'] ?? 'default-host';
static String get awsRdsPassword => 
    Platform.environment['RDS_PASSWORD'] ?? 'default-password';
```

## Database Schema

The application automatically creates the following tables:

- `users` - User information and authentication
- `sales` - Sales transactions and records
- `inventory` - Fuel inventory management
- `activities` - User activity logs
- `settings` - Application settings
- `cached_data` - Temporary cache storage
- `schema_migrations` - Database migration tracking

## Migration System

### Running Migrations

Migrations are automatically run when the app starts if `autoMigrate` is enabled:

```dart
// In main.dart
await HybridDatabaseService().initialize(
  usePostgreSQL: true,
  fallbackToSQLite: true,
);
```

### Creating New Migrations

```dart
// Create a new migration
final migrationService = DatabaseMigrationService();
await migrationService.createMigrationFile('add_new_table');
```

### Manual Migration Management

```dart
// Run pending migrations
await migrationService.runMigrations();

// Get migration history
final history = await migrationService.getMigrationHistory();

// Rollback a migration
await migrationService.rollbackMigration('001');
```

## Usage Examples

### Initializing Database

```dart
// Initialize with PostgreSQL preference
await HybridDatabaseService().initialize(
  usePostgreSQL: true,
  fallbackToSQLite: true,
);

// Check current database type
final dbService = HybridDatabaseService();
if (dbService.isUsingPostgreSQL) {
  print('Using PostgreSQL');
} else {
  print('Using SQLite');
}
```

### Switching Databases

```dart
final dbService = HybridDatabaseService();

// Switch to PostgreSQL
try {
  await dbService.switchToPostgreSQL();
  print('Switched to PostgreSQL');
} catch (e) {
  print('Failed to switch: $e');
}

// Switch to SQLite
await dbService.switchToSQLite();
print('Switched to SQLite');
```

### Database Operations

```dart
final dbService = HybridDatabaseService();

// Insert user
await dbService.insertUser({
  'user_id': 'user123',
  'name': 'John Doe',
  'email': 'john@example.com',
});

// Get user
final user = await dbService.getUser('user123');

// Get sales statistics
final stats = await dbService.getSalesStats(
  userId: 'user123',
  startDate: DateTime.now().subtract(Duration(days: 30)),
  endDate: DateTime.now(),
);
```

## Monitoring and Maintenance

### Health Checks

```dart
// Check database health
final isHealthy = await dbService.isHealthy();

// Get database statistics
final stats = await dbService.getDatabaseStats();
```

### Data Export/Backup

```dart
// Export all data
final exportData = await dbService.exportData();

// Clear expired cache
await dbService.clearExpiredCache();
```

### Performance Monitoring

The app includes built-in performance monitoring:

- Connection health checks
- Query performance tracking
- Error logging and reporting
- Database statistics collection

## Security Considerations

### Production Security

1. **Network Security**
   - Use VPC with private subnets
   - Restrict security group access
   - Enable SSL/TLS encryption

2. **Authentication**
   - Use strong passwords
   - Consider IAM database authentication
   - Rotate credentials regularly

3. **Data Encryption**
   - Enable encryption at rest
   - Enable encryption in transit
   - Use AWS KMS for key management

4. **Access Control**
   - Follow principle of least privilege
   - Use separate credentials for different environments
   - Monitor database access logs

### SSL Configuration

```dart
// SSL is enabled by default for production
static const ConnectionSettings connectionSettings = ConnectionSettings(
  sslMode: SslMode.require,
  connectTimeout: Duration(seconds: 30),
  queryTimeout: Duration(seconds: 30),
);
```

## Troubleshooting

### Common Issues

1. **Connection Timeout**
   - Check security group rules
   - Verify VPC configuration
   - Check if RDS instance is running

2. **Authentication Failed**
   - Verify username and password
   - Check if user has necessary permissions
   - Ensure database exists

3. **SSL Errors**
   - Verify SSL certificate
   - Check SSL mode configuration
   - Update PostgreSQL drivers

### Debug Mode

Enable debug logging for troubleshooting:

```dart
class DatabaseConfig {
  static const bool enableQueryLogging = true;
  static const bool enableConnectionPooling = true;
}
```

### Health Check Endpoint

Use the database settings screen in the app to:
- Test connections
- View database statistics
- Switch between databases
- Export data
- Monitor health status

## Cost Optimization

### AWS RDS Cost Tips

1. **Instance Sizing**
   - Start with `db.t3.micro` for development
   - Monitor CPU and memory usage
   - Scale up only when needed

2. **Storage**
   - Use General Purpose SSD (gp2) for most workloads
   - Enable storage autoscaling
   - Monitor storage growth

3. **Backup and Monitoring**
   - Adjust backup retention period based on needs
   - Use Performance Insights free tier
   - Monitor enhanced monitoring costs

4. **Reserved Instances**
   - Consider reserved instances for production
   - 1-year or 3-year terms for cost savings

## Support

For additional support:

1. Check AWS RDS documentation
2. Review PostgreSQL documentation
3. Monitor application logs
4. Use the built-in database settings screen
5. Contact the development team

## Version History

- **v1.0.0** - Initial PostgreSQL integration
- **v1.1.0** - Added hybrid database support
- **v1.2.0** - Added migration system
- **v1.3.0** - Added monitoring and health checks
