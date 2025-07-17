class DatabaseConfig {
  // AWS RDS PostgreSQL Configuration
  static const String awsRdsHost = 'your-rds-instance.region.rds.amazonaws.com';
  static const int awsRdsPort = 5432;
  static const String awsRdsDatabase = 'agil_database';
  static const String awsRdsUsername = 'your-username';
  static const String awsRdsPassword = 'your-password';
  
  // SSL Configuration for AWS RDS
  static const bool useSSL = true;
  static const String sslMode = 'require';
  
  // Connection Pool Settings
  static const int maxConnections = 10;
  static const int minConnections = 2;
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration queryTimeout = Duration(seconds: 30);
  static const Duration idleTimeout = Duration(minutes: 10);
  
  // Database Settings
  static const bool enableAutoMigration = true;
  static const bool enableQueryLogging = false; // Set to true for debugging
  static const bool enableConnectionPooling = true;
  
  // Fallback Settings
  static const bool useSQLiteFallback = true;
  static const bool autoSyncToPostgreSQL = true;
  
  // Environment-specific configurations
  static DatabaseEnvironment getCurrentEnvironment() {
    // In a real app, this would check environment variables
    // For now, we'll default to development
    return DatabaseEnvironment.development;
  }
  
  static Map<String, String> getConnectionConfig(DatabaseEnvironment env) {
    switch (env) {
      case DatabaseEnvironment.development:
        return {
          'host': 'localhost', // Use local PostgreSQL for development
          'port': '5432',
          'database': 'agil_dev',
          'username': 'postgres',
          'password': 'password',
        };
      
      case DatabaseEnvironment.staging:
        return {
          'host': 'agil-staging.region.rds.amazonaws.com',
          'port': '5432',
          'database': 'agil_staging',
          'username': 'agil_staging_user',
          'password': 'staging_password',
        };
      
      case DatabaseEnvironment.production:
        return {
          'host': awsRdsHost,
          'port': awsRdsPort.toString(),
          'database': awsRdsDatabase,
          'username': awsRdsUsername,
          'password': awsRdsPassword,
        };
    }
  }
  
  // Security configurations
  static const bool encryptSensitiveData = true;
  static const String encryptionKey = 'your-encryption-key'; // Should be from secure storage
  
  // Monitoring and Logging
  static const bool enablePerformanceMonitoring = true;
  static const bool enableErrorReporting = true;
  static const Duration logRetentionPeriod = Duration(days: 30);
  
  // Backup configurations
  static const bool enableAutoBackup = true;
  static const Duration backupInterval = Duration(hours: 6);
  static const int maxBackupFiles = 10;
  
  // Cache configurations
  static const Duration defaultCacheExpiry = Duration(hours: 1);
  static const int maxCacheSize = 100; // Number of cached items
  
  // Validation
  static bool isValidConfiguration() {
    final config = getConnectionConfig(getCurrentEnvironment());
    return config['host']?.isNotEmpty == true &&
           config['database']?.isNotEmpty == true &&
           config['username']?.isNotEmpty == true;
  }
}

enum DatabaseEnvironment {
  development,
  staging,
  production,
}

class DatabaseCredentials {
  final String host;
  final int port;
  final String database;
  final String username;
  final String password;
  final bool useSSL;
  
  const DatabaseCredentials({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
    this.useSSL = true,
  });
  
  factory DatabaseCredentials.fromEnvironment() {
    final env = DatabaseConfig.getCurrentEnvironment();
    final config = DatabaseConfig.getConnectionConfig(env);
    
    return DatabaseCredentials(
      host: config['host']!,
      port: int.parse(config['port']!),
      database: config['database']!,
      username: config['username']!,
      password: config['password']!,
      useSSL: env != DatabaseEnvironment.development,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'host': host,
      'port': port,
      'database': database,
      'username': username,
      'password': password,
      'useSSL': useSSL,
    };
  }
  
  @override
  String toString() {
    return 'DatabaseCredentials(host: $host, port: $port, database: $database, username: $username, useSSL: $useSSL)';
  }
}

// AWS RDS specific configurations
class AWSRDSConfig {
  // RDS Instance Configuration
  static const String region = 'us-east-1'; // Change to your AWS region
  static const String dbInstanceClass = 'db.t3.micro'; // Change based on your needs
  static const String engine = 'postgres';
  static const String engineVersion = '15.4';
  
  // Security Group and VPC
  static const String vpcSecurityGroupId = 'sg-xxxxxxxxx';
  static const String dbSubnetGroupName = 'agil-db-subnet-group';
  
  // Storage Configuration
  static const int allocatedStorage = 20; // GB
  static const int maxAllocatedStorage = 100; // GB
  static const String storageType = 'gp2';
  static const bool storageEncrypted = true;
  
  // Backup and Maintenance
  static const int backupRetentionPeriod = 7; // days
  static const String preferredBackupWindow = '03:00-04:00'; // UTC
  static const String preferredMaintenanceWindow = 'sun:04:00-sun:05:00'; // UTC
  
  // Monitoring
  static const bool enablePerformanceInsights = true;
  static const int performanceInsightsRetentionPeriod = 7; // days
  static const bool enableEnhancedMonitoring = true;
  static const int monitoringInterval = 60; // seconds
  
  // Connection Settings
  static const String parameterGroupName = 'agil-postgres-params';
  static const String optionGroupName = 'agil-postgres-options';
  
  // Tags
  static const Map<String, String> tags = {
    'Environment': 'production',
    'Application': 'AgilApp',
    'Owner': 'AgilDistribution',
    'CostCenter': 'IT',
  };
  
  // Get connection string for different environments
  static String getConnectionString(DatabaseEnvironment env) {
    final credentials = DatabaseCredentials.fromEnvironment();
    
    return 'postgresql://${credentials.username}:${credentials.password}'
           '@${credentials.host}:${credentials.port}/${credentials.database}'
           '${credentials.useSSL ? '?sslmode=require' : ''}';
  }
}

// Database migration configuration
class MigrationConfig {
  static const String migrationsTableName = 'schema_migrations';
  static const String migrationsPath = 'assets/migrations/';
  
  // Migration scripts (in order)
  static const List<String> migrationFiles = [
    '001_initial_schema.sql',
    '002_add_indexes.sql',
    '003_add_triggers.sql',
    // Add more migration files as needed
  ];
  
  static const bool enableMigrationLogging = true;
  static const bool autoMigrate = false; // Set to true for auto-migration
}
