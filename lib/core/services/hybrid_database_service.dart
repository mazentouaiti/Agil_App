import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import 'postgresql_service.dart';

enum DatabaseType { postgresql, sqlite }

class HybridDatabaseService {
  static final HybridDatabaseService _instance = HybridDatabaseService._internal();
  factory HybridDatabaseService() => _instance;
  HybridDatabaseService._internal();

  late DatabaseService _sqliteService;
  late PostgreSQLService _postgresService;
  DatabaseType _currentDatabase = DatabaseType.sqlite;
  bool _isInitialized = false;

  DatabaseType get currentDatabase => _currentDatabase;
  bool get isUsingPostgreSQL => _currentDatabase == DatabaseType.postgresql;
  bool get isUsingSQLite => _currentDatabase == DatabaseType.sqlite;

  Future<void> initialize({
    bool usePostgreSQL = true,
    bool fallbackToSQLite = true,
  }) async {
    if (_isInitialized) return;

    _sqliteService = DatabaseService();
    _postgresService = PostgreSQLService();

    // Try PostgreSQL first if requested
    if (usePostgreSQL) {
      try {
        await _postgresService.connection;
        final isHealthy = await _postgresService.isHealthy();
        
        if (isHealthy) {
          _currentDatabase = DatabaseType.postgresql;
          print('✅ Using PostgreSQL database');
        } else {
          throw Exception('PostgreSQL health check failed');
        }
      } catch (e) {
        print('⚠️ PostgreSQL connection failed: $e');
        
        if (fallbackToSQLite) {
          print('🔄 Falling back to SQLite database');
          _currentDatabase = DatabaseType.sqlite;
          await _sqliteService.database; // Initialize SQLite
        } else {
          rethrow;
        }
      }
    } else {
      _currentDatabase = DatabaseType.sqlite;
      await _sqliteService.database; // Initialize SQLite
      print('✅ Using SQLite database');
    }

    _isInitialized = true;
  }

  Future<void> switchToPostgreSQL() async {
    if (_currentDatabase == DatabaseType.postgresql) return;

    try {
      await _postgresService.connection;
      final isHealthy = await _postgresService.isHealthy();
      
      if (isHealthy) {
        _currentDatabase = DatabaseType.postgresql;
        print('✅ Switched to PostgreSQL database');
        
        // Optionally sync data from SQLite to PostgreSQL
        await _syncSQLiteToPostgreSQL();
      } else {
        throw Exception('PostgreSQL health check failed');
      }
    } catch (e) {
      print('❌ Failed to switch to PostgreSQL: $e');
      rethrow;
    }
  }

  Future<void> switchToSQLite() async {
    if (_currentDatabase == DatabaseType.sqlite) return;

    _currentDatabase = DatabaseType.sqlite;
    await _sqliteService.database; // Ensure SQLite is initialized
    print('✅ Switched to SQLite database');
  }

  Future<void> _syncSQLiteToPostgreSQL() async {
    try {
      print('🔄 Syncing data from SQLite to PostgreSQL...');

      // Sync users
      final sqliteDb = await _sqliteService.database;
      final users = await sqliteDb.query('users');
      for (final user in users) {
        await _postgresService.insertUser(user);
      }

      // Sync sales
      final sales = await sqliteDb.query('sales');
      for (final sale in sales) {
        await _postgresService.insertSale(sale);
      }

      // Sync inventory
      final inventory = await sqliteDb.query('inventory');
      for (final item in inventory) {
        await _postgresService.insertOrUpdateInventory(item);
      }

      // Sync activities
      final activities = await sqliteDb.query('activities');
      for (final activity in activities) {
        // Convert metadata string to Map if needed
        if (activity['metadata'] is String) {
          activity['metadata'] = jsonDecode(activity['metadata'] as String);
        }
        await _postgresService.insertActivity(activity);
      }

      // Sync settings
      final settings = await sqliteDb.query('settings');
      for (final setting in settings) {
        await _postgresService.setSetting(
          setting['key'] as String,
          setting['value'] as String,
        );
      }

      print('✅ Data sync completed successfully');
    } catch (e) {
      print('❌ Data sync failed: $e');
      rethrow;
    }
  }

  // User operations
  Future<void> insertUser(Map<String, dynamic> user) async {
    switch (_currentDatabase) {
      case DatabaseType.postgresql:
        await _postgresService.insertUser(user);
        break;
      case DatabaseType.sqlite:
        await _sqliteService.insertUser(user);
        break;
    }
  }

  Future<Map<String, dynamic>?> getUser(String userId) async {
    switch (_currentDatabase) {
      case DatabaseType.postgresql:
        return await _postgresService.getUser(userId);
      case DatabaseType.sqlite:
        return await _sqliteService.getUser(userId);
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> user) async {
    switch (_currentDatabase) {
      case DatabaseType.postgresql:
        await _postgresService.updateUser(userId, user);
        break;
      case DatabaseType.sqlite:
        await _sqliteService.updateUser(userId, user);
        break;
    }
  }

  // Sales operations
  Future<void> insertSale(Map<String, dynamic> sale) async {
    switch (_currentDatabase) {
      case DatabaseType.postgresql:
        await _postgresService.insertSale(sale);
        break;
      case DatabaseType.sqlite:
        await _sqliteService.insertSale(sale);
        break;
    }
  }

  Future<List<Map<String, dynamic>>> getSales({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    switch (_currentDatabase) {
      case DatabaseType.postgresql:
        return await _postgresService.getSales(
          userId: userId,
          startDate: startDate,
          endDate: endDate,
          limit: limit,
        );
      case DatabaseType.sqlite:
        return await _sqliteService.getSales(
          userId: userId,
          startDate: startDate,
          endDate: endDate,
          limit: limit,
        );
    }
  }

  Future<Map<String, dynamic>> getSalesStats({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    switch (_currentDatabase) {
      case DatabaseType.postgresql:
        return await _postgresService.getSalesStats(
          userId: userId,
          startDate: startDate,
          endDate: endDate,
        );
      case DatabaseType.sqlite:
        return await _sqliteService.getSalesStats(
          userId: userId,
          startDate: startDate,
          endDate: endDate,
        );
    }
  }

  // Inventory operations
  Future<void> insertOrUpdateInventory(Map<String, dynamic> inventory) async {
    switch (_currentDatabase) {
      case DatabaseType.postgresql:
        await _postgresService.insertOrUpdateInventory(inventory);
        break;
      case DatabaseType.sqlite:
        await _sqliteService.insertOrUpdateInventory(inventory);
        break;
    }
  }

  Future<List<Map<String, dynamic>>> getInventory({String? stationId}) async {
    switch (_currentDatabase) {
      case DatabaseType.postgresql:
        return await _postgresService.getInventory(stationId: stationId);
      case DatabaseType.sqlite:
        return await _sqliteService.getInventory(stationId: stationId);
    }
  }

  // Activities operations
  Future<void> insertActivity(Map<String, dynamic> activity) async {
    switch (_currentDatabase) {
      case DatabaseType.postgresql:
        await _postgresService.insertActivity(activity);
        break;
      case DatabaseType.sqlite:
        await _sqliteService.insertActivity(activity);
        break;
    }
  }

  Future<List<Map<String, dynamic>>> getRecentActivities({
    String? userId,
    int limit = 10,
  }) async {
    switch (_currentDatabase) {
      case DatabaseType.postgresql:
        return await _postgresService.getRecentActivities(
          userId: userId,
          limit: limit,
        );
      case DatabaseType.sqlite:
        return await _sqliteService.getRecentActivities(
          userId: userId,
          limit: limit,
        );
    }
  }

  // Settings operations
  Future<void> setSetting(String key, String value) async {
    switch (_currentDatabase) {
      case DatabaseType.postgresql:
        await _postgresService.setSetting(key, value);
        break;
      case DatabaseType.sqlite:
        await _sqliteService.setSetting(key, value);
        break;
    }
  }

  Future<String?> getSetting(String key) async {
    switch (_currentDatabase) {
      case DatabaseType.postgresql:
        return await _postgresService.getSetting(key);
      case DatabaseType.sqlite:
        return await _sqliteService.getSetting(key);
    }
  }

  // Cache operations
  Future<void> setCachedData(String key, dynamic data, Duration expiry) async {
    switch (_currentDatabase) {
      case DatabaseType.postgresql:
        if (data is Map<String, dynamic>) {
          await _postgresService.setCachedData(key, data, expiry);
        } else {
          await _postgresService.setCachedData(key, {'data': data}, expiry);
        }
        break;
      case DatabaseType.sqlite:
        final jsonData = data is String ? data : jsonEncode(data);
        await _sqliteService.setCachedData(key, jsonData, expiry);
        break;
    }
  }

  Future<dynamic> getCachedData(String key) async {
    switch (_currentDatabase) {
      case DatabaseType.postgresql:
        final result = await _postgresService.getCachedData(key);
        return result?['data'] ?? result;
      case DatabaseType.sqlite:
        return await _sqliteService.getCachedData(key);
    }
  }

  Future<void> clearExpiredCache() async {
    switch (_currentDatabase) {
      case DatabaseType.postgresql:
        await _postgresService.clearExpiredCache();
        break;
      case DatabaseType.sqlite:
        await _sqliteService.clearExpiredCache();
        break;
    }
  }

  // Sync operations
  Future<List<Map<String, dynamic>>> getUnsyncedSales() async {
    switch (_currentDatabase) {
      case DatabaseType.postgresql:
        return await _postgresService.getUnsyncedSales();
      case DatabaseType.sqlite:
        return await _sqliteService.getUnsyncedSales();
    }
  }

  Future<void> markSaleAsSynced(String saleId) async {
    switch (_currentDatabase) {
      case DatabaseType.postgresql:
        await _postgresService.markSaleAsSynced(saleId);
        break;
      case DatabaseType.sqlite:
        await _sqliteService.markSaleAsSynced(saleId);
        break;
    }
  }

  // Database maintenance
  Future<void> clearAllData() async {
    switch (_currentDatabase) {
      case DatabaseType.postgresql:
        await _postgresService.clearAllData();
        break;
      case DatabaseType.sqlite:
        await _sqliteService.clearAllData();
        break;
    }
  }

  Future<void> closeConnections() async {
    await _postgresService.closeConnection();
    await _sqliteService.closeDatabase();
  }

  // Health check
  Future<bool> isHealthy() async {
    switch (_currentDatabase) {
      case DatabaseType.postgresql:
        return await _postgresService.isHealthy();
      case DatabaseType.sqlite:
        try {
          final db = await _sqliteService.database;
          await db.rawQuery('SELECT 1');
          return true;
        } catch (e) {
          return false;
        }
    }
  }

  // Backup and export
  Future<Map<String, dynamic>> exportData() async {
    switch (_currentDatabase) {
      case DatabaseType.postgresql:
        return await _postgresService.exportData();
      case DatabaseType.sqlite:
        final db = await _sqliteService.database;
        
        final users = await db.query('users');
        final sales = await db.query('sales');
        final inventory = await db.query('inventory');
        final activities = await db.query('activities');
        final settings = await db.query('settings');

        return {
          'users': users,
          'sales': sales,
          'inventory': inventory,
          'activities': activities,
          'settings': settings,
          'export_timestamp': DateTime.now().toIso8601String(),
          'database_type': 'sqlite',
        };
    }
  }

  // Configuration
  Future<void> updatePostgreSQLConfig({
    required String host,
    required int port,
    required String database,
    required String username,
    required String password,
  }) async {
    // This would typically be handled through environment variables
    // or a configuration service in a production app
    if (kDebugMode) {
      print('PostgreSQL config updated:');
      print('Host: $host');
      print('Port: $port');
      print('Database: $database');
      print('Username: $username');
    }
  }

  // Statistics and monitoring
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final stats = <String, dynamic>{
      'database_type': _currentDatabase.toString(),
      'is_healthy': await isHealthy(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      switch (_currentDatabase) {
        case DatabaseType.postgresql:
          final conn = await _postgresService.connection;
          final result = await conn.execute('''
            SELECT 
              (SELECT COUNT(*) FROM users) as users_count,
              (SELECT COUNT(*) FROM sales) as sales_count,
              (SELECT COUNT(*) FROM inventory) as inventory_count,
              (SELECT COUNT(*) FROM activities) as activities_count
          ''');
          
          if (result.isNotEmpty) {
            final row = result.first;
            stats.addAll({
              'users_count': row[0],
              'sales_count': row[1],
              'inventory_count': row[2],
              'activities_count': row[3],
            });
          }
          break;
          
        case DatabaseType.sqlite:
          final db = await _sqliteService.database;
          
          final usersCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM users')
          ) ?? 0;
          final salesCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM sales')
          ) ?? 0;
          final inventoryCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM inventory')
          ) ?? 0;
          final activitiesCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM activities')
          ) ?? 0;
          
          stats.addAll({
            'users_count': usersCount,
            'sales_count': salesCount,
            'inventory_count': inventoryCount,
            'activities_count': activitiesCount,
          });
          break;
      }
    } catch (e) {
      stats['error'] = e.toString();
    }

    return stats;
  }
}
