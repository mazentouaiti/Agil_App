import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'agil_database.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        phone TEXT,
        position TEXT,
        station TEXT,
        avatar TEXT,
        join_date TEXT,
        address TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Sales table
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id TEXT UNIQUE NOT NULL,
        user_id TEXT NOT NULL,
        customer_name TEXT,
        fuel_type TEXT NOT NULL,
        quantity REAL NOT NULL,
        price_per_liter REAL NOT NULL,
        total_amount REAL NOT NULL,
        payment_method TEXT,
        sale_date TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (user_id)
      )
    ''');

    // Inventory table
    await db.execute('''
      CREATE TABLE inventory (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fuel_type TEXT NOT NULL,
        current_stock REAL NOT NULL,
        minimum_stock REAL NOT NULL,
        maximum_capacity REAL NOT NULL,
        last_updated TEXT NOT NULL,
        station_id TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Activities table (for recent activities)
    await db.execute('''
      CREATE TABLE activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        activity_id TEXT UNIQUE NOT NULL,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        user_id TEXT,
        timestamp TEXT NOT NULL,
        metadata TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (user_id)
      )
    ''');

    // Settings table
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        value TEXT NOT NULL,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Cached data table (for dashboard metrics)
    await db.execute('''
      CREATE TABLE cached_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cache_key TEXT UNIQUE NOT NULL,
        data TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Insert default settings
    await _insertDefaultSettings(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    if (oldVersion < 2) {
      // Add new columns or tables for version 2
    }
  }

  Future<void> _insertDefaultSettings(Database db) async {
    final defaultSettings = [
      {'key': 'language', 'value': 'fr'},
      {'key': 'theme', 'value': 'light'},
      {'key': 'notifications_enabled', 'value': 'true'},
      {'key': 'biometric_enabled', 'value': 'false'},
      {'key': 'currency', 'value': 'TND'},
    ];

    for (final setting in defaultSettings) {
      await db.insert('settings', {
        ...setting,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // User operations
  Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.insert(
      'users',
      {
        ...user,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getUser(String userId) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> updateUser(String userId, Map<String, dynamic> user) async {
    final db = await database;
    await db.update(
      'users',
      {
        ...user,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // Sales operations
  Future<void> insertSale(Map<String, dynamic> sale) async {
    final db = await database;
    await db.insert(
      'sales',
      {
        ...sale,
        'created_at': DateTime.now().toIso8601String(),
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getSales({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final db = await database;
    String where = '';
    List<dynamic> whereArgs = [];

    if (userId != null) {
      where += 'user_id = ?';
      whereArgs.add(userId);
    }

    if (startDate != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'sale_date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'sale_date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    return await db.query(
      'sales',
      where: where.isNotEmpty ? where : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'sale_date DESC',
      limit: limit,
    );
  }

  Future<Map<String, dynamic>> getSalesStats({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String where = '';
    List<dynamic> whereArgs = [];

    if (userId != null) {
      where += 'user_id = ?';
      whereArgs.add(userId);
    }

    if (startDate != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'sale_date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'sale_date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_sales,
        SUM(total_amount) as total_revenue,
        SUM(quantity) as total_quantity,
        AVG(total_amount) as average_sale
      FROM sales
      ${where.isNotEmpty ? 'WHERE $where' : ''}
    ''', whereArgs);

    return result.first;
  }

  // Inventory operations
  Future<void> insertOrUpdateInventory(Map<String, dynamic> inventory) async {
    final db = await database;
    await db.insert(
      'inventory',
      {
        ...inventory,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getInventory({String? stationId}) async {
    final db = await database;
    return await db.query(
      'inventory',
      where: stationId != null ? 'station_id = ?' : null,
      whereArgs: stationId != null ? [stationId] : null,
      orderBy: 'fuel_type ASC',
    );
  }

  // Activities operations
  Future<void> insertActivity(Map<String, dynamic> activity) async {
    final db = await database;
    await db.insert(
      'activities',
      {
        ...activity,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getRecentActivities({
    String? userId,
    int limit = 10,
  }) async {
    final db = await database;
    return await db.query(
      'activities',
      where: userId != null ? 'user_id = ?' : null,
      whereArgs: userId != null ? [userId] : null,
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  // Settings operations
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final results = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    return results.isNotEmpty ? results.first['value'] as String? : null;
  }

  // Cache operations
  Future<void> setCachedData(String key, String data, Duration expiry) async {
    final db = await database;
    final expiresAt = DateTime.now().add(expiry);
    
    await db.insert(
      'cached_data',
      {
        'cache_key': key,
        'data': data,
        'expires_at': expiresAt.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getCachedData(String key) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final results = await db.query(
      'cached_data',
      where: 'cache_key = ? AND expires_at > ?',
      whereArgs: [key, now],
    );
    
    return results.isNotEmpty ? results.first['data'] as String? : null;
  }

  Future<void> clearExpiredCache() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    await db.delete(
      'cached_data',
      where: 'expires_at <= ?',
      whereArgs: [now],
    );
  }

  // Sync operations
  Future<List<Map<String, dynamic>>> getUnsyncedSales() async {
    final db = await database;
    return await db.query(
      'sales',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'created_at ASC',
    );
  }

  Future<void> markSaleAsSynced(String saleId) async {
    final db = await database;
    await db.update(
      'sales',
      {'synced': 1},
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
  }

  // Database maintenance
  Future<void> clearAllData() async {
    final db = await database;
    final tables = ['users', 'sales', 'inventory', 'activities', 'cached_data'];
    
    for (final table in tables) {
      await db.delete(table);
    }
  }

  Future<void> closeDatabase() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
