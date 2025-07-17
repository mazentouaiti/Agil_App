import 'dart:async';
import 'package:flutter/services.dart';
import 'package:postgres/postgres.dart';
import '../config/database_config.dart';

class DatabaseMigrationService {
  static final DatabaseMigrationService _instance = DatabaseMigrationService._internal();
  factory DatabaseMigrationService() => _instance;
  DatabaseMigrationService._internal();

  Connection? _connection;

  Future<void> initialize(Connection connection) async {
    _connection = connection;
    await _createMigrationsTable();
  }

  Future<void> _createMigrationsTable() async {
    if (_connection == null) return;

    await _connection!.execute('''
      CREATE TABLE IF NOT EXISTS ${MigrationConfig.migrationsTableName} (
        id SERIAL PRIMARY KEY,
        version VARCHAR(255) UNIQUE NOT NULL,
        filename VARCHAR(255) NOT NULL,
        executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        checksum VARCHAR(255)
      )
    ''');
  }

  Future<List<String>> getExecutedMigrations() async {
    if (_connection == null) return [];

    final result = await _connection!.execute(
      'SELECT version FROM ${MigrationConfig.migrationsTableName} ORDER BY executed_at'
    );

    return result.map((row) => row[0] as String).toList();
  }

  Future<void> runMigrations() async {
    if (_connection == null) {
      throw Exception('Database connection not initialized');
    }

    print('🔄 Starting database migrations...');

    final executedMigrations = await getExecutedMigrations();
    final pendingMigrations = MigrationConfig.migrationFiles
        .where((file) => !executedMigrations.contains(_getVersionFromFilename(file)))
        .toList();

    if (pendingMigrations.isEmpty) {
      print('✅ No pending migrations');
      return;
    }

    print('📋 Found ${pendingMigrations.length} pending migrations');

    for (final migrationFile in pendingMigrations) {
      await _executeMigration(migrationFile);
    }

    print('✅ All migrations completed successfully');
  }

  Future<void> _executeMigration(String filename) async {
    if (_connection == null) return;

    try {
      print('🔄 Executing migration: $filename');

      // Load migration SQL from assets
      final sql = await _loadMigrationSql(filename);
      
      if (sql.isEmpty) {
        print('⚠️ Migration file $filename is empty, skipping');
        return;
      }

      // Calculate checksum for validation
      final checksum = _calculateChecksum(sql);

      // Execute migration in a transaction
      await _connection!.execute('BEGIN');
      
      try {
        // Split SQL into individual statements and execute
        final statements = _splitSqlStatements(sql);
        for (final statement in statements) {
          if (statement.trim().isNotEmpty) {
            await _connection!.execute(statement);
          }
        }

        // Record migration execution
        await _connection!.execute(
          Sql.named('''
            INSERT INTO ${MigrationConfig.migrationsTableName} 
            (version, filename, checksum) 
            VALUES (@version, @filename, @checksum)
          '''),
          parameters: {
            'version': _getVersionFromFilename(filename),
            'filename': filename,
            'checksum': checksum,
          },
        );

        await _connection!.execute('COMMIT');
        print('✅ Migration $filename completed successfully');
      } catch (e) {
        await _connection!.execute('ROLLBACK');
        rethrow;
      }
    } catch (e) {
      print('❌ Migration $filename failed: $e');
      rethrow;
    }
  }

  Future<String> _loadMigrationSql(String filename) async {
    try {
      final fullPath = '${MigrationConfig.migrationsPath}$filename';
      return await rootBundle.loadString(fullPath);
    } catch (e) {
      // If loading from assets fails, try to load from a default SQL
      print('⚠️ Could not load migration from assets: $filename');
      return _getDefaultMigrationSql(filename);
    }
  }

  String _getDefaultMigrationSql(String filename) {
    // Provide default SQL for common migrations
    switch (filename) {
      case '001_initial_schema.sql':
        return '''
          -- Initial schema creation
          -- This is handled by PostgreSQLService._initializeSchema()
          SELECT 1; -- No-op migration
        ''';
      
      case '002_add_indexes.sql':
        return '''
          -- Performance indexes
          CREATE INDEX IF NOT EXISTS idx_sales_user_date ON sales(user_id, sale_date);
          CREATE INDEX IF NOT EXISTS idx_activities_type_timestamp ON activities(type, timestamp);
          CREATE INDEX IF NOT EXISTS idx_inventory_station_fuel ON inventory(station_id, fuel_type);
          CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
          CREATE INDEX IF NOT EXISTS idx_cached_data_expires ON cached_data(expires_at);
        ''';
      
      case '003_add_triggers.sql':
        return '''
          -- Auto-update triggers
          CREATE OR REPLACE FUNCTION update_updated_at_column()
          RETURNS TRIGGER AS \$\$
          BEGIN
              NEW.updated_at = CURRENT_TIMESTAMP;
              RETURN NEW;
          END;
          \$\$ language 'plpgsql';

          CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
              FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
          
          CREATE TRIGGER update_settings_updated_at BEFORE UPDATE ON settings
              FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
        ''';
      
      default:
        return '-- Empty migration';
    }
  }

  List<String> _splitSqlStatements(String sql) {
    // Simple SQL statement splitter
    // In production, you might want to use a more sophisticated parser
    return sql
        .split(';')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && !s.startsWith('--'))
        .toList();
  }

  String _getVersionFromFilename(String filename) {
    // Extract version from filename like "001_initial_schema.sql"
    final match = RegExp(r'^(\d+)_').firstMatch(filename);
    return match?.group(1) ?? filename;
  }

  String _calculateChecksum(String content) {
    // Simple checksum calculation
    // In production, you might want to use SHA-256 or similar
    return content.hashCode.toString();
  }

  Future<void> rollbackMigration(String version) async {
    if (_connection == null) {
      throw Exception('Database connection not initialized');
    }

    try {
      print('🔄 Rolling back migration: $version');

      // In a real implementation, you would need rollback scripts
      // For now, we'll just remove the migration record
      await _connection!.execute(
        Sql.named('''
          DELETE FROM ${MigrationConfig.migrationsTableName} 
          WHERE version = @version
        '''),
        parameters: {'version': version},
      );

      print('✅ Migration $version rolled back successfully');
      print('⚠️ Note: You may need to manually revert database changes');
    } catch (e) {
      print('❌ Migration rollback failed: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMigrationHistory() async {
    if (_connection == null) return [];

    final result = await _connection!.execute('''
      SELECT version, filename, executed_at, checksum 
      FROM ${MigrationConfig.migrationsTableName} 
      ORDER BY executed_at DESC
    ''');

    return result.map((row) => {
      'version': row[0],
      'filename': row[1],
      'executed_at': row[2]?.toString(),
      'checksum': row[3],
    }).toList();
  }

  Future<bool> validateMigrations() async {
    if (_connection == null) return false;

    try {
      final history = await getMigrationHistory();
      
      for (final migration in history) {
        final filename = migration['filename'] as String;
        final storedChecksum = migration['checksum'] as String;
        
        // Load current SQL and calculate checksum
        final currentSql = await _loadMigrationSql(filename);
        final currentChecksum = _calculateChecksum(currentSql);
        
        if (currentChecksum != storedChecksum) {
          print('❌ Migration validation failed for $filename');
          print('   Stored checksum: $storedChecksum');
          print('   Current checksum: $currentChecksum');
          return false;
        }
      }

      print('✅ All migrations validated successfully');
      return true;
    } catch (e) {
      print('❌ Migration validation error: $e');
      return false;
    }
  }

  Future<void> createMigrationFile(String name) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final version = timestamp.toString().padLeft(3, '0');
    final filename = '${version}_$name.sql';
    
    final template = '''
-- Migration: $name
-- Version: $version
-- Created: ${DateTime.now().toIso8601String()}

-- Add your SQL statements here
-- Example:
-- CREATE TABLE example (
--   id SERIAL PRIMARY KEY,
--   name VARCHAR(255) NOT NULL
-- );

-- Don't forget to add rollback instructions in comments:
-- ROLLBACK:
-- DROP TABLE example;
''';

    print('📝 Migration template for $filename:');
    print(template);
    print('💡 Add this file to ${MigrationConfig.migrationsPath}$filename');
    print('💡 Update MigrationConfig.migrationFiles to include "$filename"');
  }
}

// AWS RDS Management Service
class AWSRDSManagementService {
  static final AWSRDSManagementService _instance = AWSRDSManagementService._internal();
  factory AWSRDSManagementService() => _instance;
  AWSRDSManagementService._internal();

  Future<Map<String, dynamic>> getRDSInstanceInfo() async {
    // This would typically use AWS SDK to get RDS instance information
    // For now, return configuration information
    return {
      'instance_class': AWSRDSConfig.dbInstanceClass,
      'engine': AWSRDSConfig.engine,
      'engine_version': AWSRDSConfig.engineVersion,
      'allocated_storage': AWSRDSConfig.allocatedStorage,
      'storage_type': AWSRDSConfig.storageType,
      'storage_encrypted': AWSRDSConfig.storageEncrypted,
      'backup_retention_period': AWSRDSConfig.backupRetentionPeriod,
      'performance_insights_enabled': AWSRDSConfig.enablePerformanceInsights,
      'enhanced_monitoring_enabled': AWSRDSConfig.enableEnhancedMonitoring,
    };
  }

  Future<bool> testConnection() async {
    try {
      final credentials = DatabaseCredentials.fromEnvironment();
      
      final connection = await Connection.open(
        Endpoint(
          host: credentials.host,
          port: credentials.port,
          database: credentials.database,
          username: credentials.username,
          password: credentials.password,
        ),
        settings: ConnectionSettings(
          sslMode: credentials.useSSL ? SslMode.require : SslMode.disable,
          connectTimeout: DatabaseConfig.connectionTimeout,
          queryTimeout: DatabaseConfig.queryTimeout,
        ),
      );

      // Test with a simple query
      final result = await connection.execute('SELECT version()');
      await connection.close();

      return result.isNotEmpty;
    } catch (e) {
      print('❌ RDS connection test failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getConnectionStats() async {
    try {
      final credentials = DatabaseCredentials.fromEnvironment();
      
      final connection = await Connection.open(
        Endpoint(
          host: credentials.host,
          port: credentials.port,
          database: credentials.database,
          username: credentials.username,
          password: credentials.password,
        ),
        settings: ConnectionSettings(
          sslMode: credentials.useSSL ? SslMode.require : SslMode.disable,
          connectTimeout: DatabaseConfig.connectionTimeout,
          queryTimeout: DatabaseConfig.queryTimeout,
        ),
      );

      // Get database statistics
      final result = await connection.execute('''
        SELECT 
          pg_database_size(current_database()) as database_size,
          (SELECT count(*) FROM pg_stat_activity) as active_connections,
          version() as postgres_version
      ''');

      await connection.close();

      if (result.isNotEmpty) {
        final row = result.first;
        return {
          'database_size_bytes': row[0],
          'active_connections': row[1],
          'postgres_version': row[2],
          'test_timestamp': DateTime.now().toIso8601String(),
        };
      }

      return {};
    } catch (e) {
      print('❌ Failed to get connection stats: $e');
      return {'error': e.toString()};
    }
  }

  String generateConnectionString({bool hidePassword = true}) {
    final credentials = DatabaseCredentials.fromEnvironment();
    final password = hidePassword ? '***' : credentials.password;
    
    return 'postgresql://${credentials.username}:$password'
           '@${credentials.host}:${credentials.port}/${credentials.database}'
           '${credentials.useSSL ? '?sslmode=require' : ''}';
  }
}
