import 'dart:async';
import 'dart:convert';
import 'package:postgres/postgres.dart';
import '../config/database_config.dart';

class PostgreSQLService {
  static final PostgreSQLService _instance = PostgreSQLService._internal();
  factory PostgreSQLService() => _instance;
  PostgreSQLService._internal();

  Connection? _connection;
  bool _isConnected = false;

  Future<Connection> get connection async {
    if (_connection != null && _isConnected) return _connection!;
    await _connect();
    return _connection!;
  }

  Future<void> _connect() async {
    try {
      final credentials = DatabaseCredentials.fromEnvironment();
      
      _connection = await Connection.open(
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
      _isConnected = true;
      print('✅ PostgreSQL connection established');
      
      // Initialize database schema if needed
      await _initializeSchema();
    } catch (e) {
      print('❌ PostgreSQL connection failed: $e');
      _isConnected = false;
      rethrow;
    }
  }

  Future<void> _initializeSchema() async {
    if (_connection == null) return;

    try {
      // Create users table
      await _connection!.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id SERIAL PRIMARY KEY,
          user_id VARCHAR(255) UNIQUE NOT NULL,
          name VARCHAR(255) NOT NULL,
          email VARCHAR(255) UNIQUE NOT NULL,
          phone VARCHAR(50),
          position VARCHAR(100),
          station VARCHAR(100),
          avatar TEXT,
          join_date TIMESTAMP,
          address TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // Create sales table
      await _connection!.execute('''
        CREATE TABLE IF NOT EXISTS sales (
          id SERIAL PRIMARY KEY,
          sale_id VARCHAR(255) UNIQUE NOT NULL,
          user_id VARCHAR(255) NOT NULL,
          customer_name VARCHAR(255),
          fuel_type VARCHAR(50) NOT NULL,
          quantity DECIMAL(10,2) NOT NULL,
          price_per_liter DECIMAL(10,2) NOT NULL,
          total_amount DECIMAL(10,2) NOT NULL,
          payment_method VARCHAR(50),
          sale_date TIMESTAMP NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          synced BOOLEAN DEFAULT FALSE,
          FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE
        )
      ''');

      // Create inventory table
      await _connection!.execute('''
        CREATE TABLE IF NOT EXISTS inventory (
          id SERIAL PRIMARY KEY,
          fuel_type VARCHAR(50) NOT NULL,
          current_stock DECIMAL(10,2) NOT NULL,
          minimum_stock DECIMAL(10,2) NOT NULL,
          maximum_capacity DECIMAL(10,2) NOT NULL,
          last_updated TIMESTAMP NOT NULL,
          station_id VARCHAR(100) NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          UNIQUE(fuel_type, station_id)
        )
      ''');

      // Create activities table
      await _connection!.execute('''
        CREATE TABLE IF NOT EXISTS activities (
          id SERIAL PRIMARY KEY,
          activity_id VARCHAR(255) UNIQUE NOT NULL,
          type VARCHAR(50) NOT NULL,
          title VARCHAR(255) NOT NULL,
          description TEXT,
          user_id VARCHAR(255),
          timestamp TIMESTAMP NOT NULL,
          metadata JSONB,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE SET NULL
        )
      ''');

      // Create settings table
      await _connection!.execute('''
        CREATE TABLE IF NOT EXISTS settings (
          id SERIAL PRIMARY KEY,
          key VARCHAR(100) UNIQUE NOT NULL,
          value TEXT NOT NULL,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // Create cached_data table
      await _connection!.execute('''
        CREATE TABLE IF NOT EXISTS cached_data (
          id SERIAL PRIMARY KEY,
          cache_key VARCHAR(255) UNIQUE NOT NULL,
          data JSONB NOT NULL,
          expires_at TIMESTAMP NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // Create indexes for better performance
      await _connection!.execute('CREATE INDEX IF NOT EXISTS idx_sales_user_id ON sales(user_id)');
      await _connection!.execute('CREATE INDEX IF NOT EXISTS idx_sales_date ON sales(sale_date)');
      await _connection!.execute('CREATE INDEX IF NOT EXISTS idx_activities_user_id ON activities(user_id)');
      await _connection!.execute('CREATE INDEX IF NOT EXISTS idx_activities_timestamp ON activities(timestamp)');
      await _connection!.execute('CREATE INDEX IF NOT EXISTS idx_inventory_station ON inventory(station_id)');

      print('✅ Database schema initialized successfully');
    } catch (e) {
      print('❌ Schema initialization failed: $e');
      rethrow;
    }
  }

  // User operations
  Future<void> insertUser(Map<String, dynamic> user) async {
    final conn = await connection;
    
    await conn.execute(
      Sql.named('''
        INSERT INTO users (user_id, name, email, phone, position, station, avatar, join_date, address)
        VALUES (@user_id, @name, @email, @phone, @position, @station, @avatar, @join_date, @address)
        ON CONFLICT (user_id) DO UPDATE SET
          name = EXCLUDED.name,
          email = EXCLUDED.email,
          phone = EXCLUDED.phone,
          position = EXCLUDED.position,
          station = EXCLUDED.station,
          avatar = EXCLUDED.avatar,
          join_date = EXCLUDED.join_date,
          address = EXCLUDED.address,
          updated_at = CURRENT_TIMESTAMP
      '''),
      parameters: {
        'user_id': user['user_id'],
        'name': user['name'],
        'email': user['email'],
        'phone': user['phone'],
        'position': user['position'],
        'station': user['station'],
        'avatar': user['avatar'],
        'join_date': user['join_date'] != null ? DateTime.parse(user['join_date']) : null,
        'address': user['address'],
      },
    );
  }

  Future<Map<String, dynamic>?> getUser(String userId) async {
    final conn = await connection;
    
    final result = await conn.execute(
      Sql.named('SELECT * FROM users WHERE user_id = @user_id'),
      parameters: {'user_id': userId},
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return {
      'id': row[0],
      'user_id': row[1],
      'name': row[2],
      'email': row[3],
      'phone': row[4],
      'position': row[5],
      'station': row[6],
      'avatar': row[7],
      'join_date': row[8]?.toString(),
      'address': row[9],
      'created_at': row[10]?.toString(),
      'updated_at': row[11]?.toString(),
    };
  }

  Future<void> updateUser(String userId, Map<String, dynamic> user) async {
    final conn = await connection;
    
    final setClause = user.keys.map((key) => '$key = @$key').join(', ');
    
    await conn.execute(
      Sql.named('''
        UPDATE users 
        SET $setClause, updated_at = CURRENT_TIMESTAMP
        WHERE user_id = @user_id
      '''),
      parameters: {...user, 'user_id': userId},
    );
  }

  // Sales operations
  Future<void> insertSale(Map<String, dynamic> sale) async {
    final conn = await connection;
    
    await conn.execute(
      Sql.named('''
        INSERT INTO sales (sale_id, user_id, customer_name, fuel_type, quantity, 
                          price_per_liter, total_amount, payment_method, sale_date)
        VALUES (@sale_id, @user_id, @customer_name, @fuel_type, @quantity,
                @price_per_liter, @total_amount, @payment_method, @sale_date)
        ON CONFLICT (sale_id) DO UPDATE SET
          customer_name = EXCLUDED.customer_name,
          fuel_type = EXCLUDED.fuel_type,
          quantity = EXCLUDED.quantity,
          price_per_liter = EXCLUDED.price_per_liter,
          total_amount = EXCLUDED.total_amount,
          payment_method = EXCLUDED.payment_method,
          sale_date = EXCLUDED.sale_date
      '''),
      parameters: {
        'sale_id': sale['sale_id'],
        'user_id': sale['user_id'],
        'customer_name': sale['customer_name'],
        'fuel_type': sale['fuel_type'],
        'quantity': sale['quantity'],
        'price_per_liter': sale['price_per_liter'],
        'total_amount': sale['total_amount'],
        'payment_method': sale['payment_method'],
        'sale_date': DateTime.parse(sale['sale_date']),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getSales({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final conn = await connection;
    
    String whereClause = '';
    Map<String, dynamic> parameters = {};
    
    if (userId != null) {
      whereClause += 'user_id = @user_id';
      parameters['user_id'] = userId;
    }
    
    if (startDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'sale_date >= @start_date';
      parameters['start_date'] = startDate;
    }
    
    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'sale_date <= @end_date';
      parameters['end_date'] = endDate;
    }

    String sql = '''
      SELECT * FROM sales
      ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
      ORDER BY sale_date DESC
      ${limit != null ? 'LIMIT $limit' : ''}
    ''';

    final result = await conn.execute(Sql.named(sql), parameters: parameters);

    return result.map((row) => {
      'id': row[0],
      'sale_id': row[1],
      'user_id': row[2],
      'customer_name': row[3],
      'fuel_type': row[4],
      'quantity': row[5],
      'price_per_liter': row[6],
      'total_amount': row[7],
      'payment_method': row[8],
      'sale_date': row[9]?.toString(),
      'created_at': row[10]?.toString(),
      'synced': row[11],
    }).toList();
  }

  Future<Map<String, dynamic>> getSalesStats({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final conn = await connection;
    
    String whereClause = '';
    Map<String, dynamic> parameters = {};
    
    if (userId != null) {
      whereClause += 'user_id = @user_id';
      parameters['user_id'] = userId;
    }
    
    if (startDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'sale_date >= @start_date';
      parameters['start_date'] = startDate;
    }
    
    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'sale_date <= @end_date';
      parameters['end_date'] = endDate;
    }

    String sql = '''
      SELECT 
        COUNT(*) as total_sales,
        COALESCE(SUM(total_amount), 0) as total_revenue,
        COALESCE(SUM(quantity), 0) as total_quantity,
        COALESCE(AVG(total_amount), 0) as average_sale
      FROM sales
      ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
    ''';

    final result = await conn.execute(Sql.named(sql), parameters: parameters);
    final row = result.first;

    return {
      'total_sales': row[0],
      'total_revenue': row[1],
      'total_quantity': row[2],
      'average_sale': row[3],
    };
  }

  // Inventory operations
  Future<void> insertOrUpdateInventory(Map<String, dynamic> inventory) async {
    final conn = await connection;
    
    await conn.execute(
      Sql.named('''
        INSERT INTO inventory (fuel_type, current_stock, minimum_stock, 
                              maximum_capacity, last_updated, station_id)
        VALUES (@fuel_type, @current_stock, @minimum_stock, 
                @maximum_capacity, @last_updated, @station_id)
        ON CONFLICT (fuel_type, station_id) DO UPDATE SET
          current_stock = EXCLUDED.current_stock,
          minimum_stock = EXCLUDED.minimum_stock,
          maximum_capacity = EXCLUDED.maximum_capacity,
          last_updated = EXCLUDED.last_updated
      '''),
      parameters: {
        'fuel_type': inventory['fuel_type'],
        'current_stock': inventory['current_stock'],
        'minimum_stock': inventory['minimum_stock'],
        'maximum_capacity': inventory['maximum_capacity'],
        'last_updated': DateTime.parse(inventory['last_updated']),
        'station_id': inventory['station_id'],
      },
    );
  }

  Future<List<Map<String, dynamic>>> getInventory({String? stationId}) async {
    final conn = await connection;
    
    String sql = '''
      SELECT * FROM inventory
      ${stationId != null ? 'WHERE station_id = @station_id' : ''}
      ORDER BY fuel_type ASC
    ''';

    final result = await conn.execute(
      Sql.named(sql),
      parameters: stationId != null ? {'station_id': stationId} : {},
    );

    return result.map((row) => {
      'id': row[0],
      'fuel_type': row[1],
      'current_stock': row[2],
      'minimum_stock': row[3],
      'maximum_capacity': row[4],
      'last_updated': row[5]?.toString(),
      'station_id': row[6],
      'created_at': row[7]?.toString(),
    }).toList();
  }

  // Activities operations
  Future<void> insertActivity(Map<String, dynamic> activity) async {
    final conn = await connection;
    
    await conn.execute(
      Sql.named('''
        INSERT INTO activities (activity_id, type, title, description, 
                               user_id, timestamp, metadata)
        VALUES (@activity_id, @type, @title, @description, 
                @user_id, @timestamp, @metadata)
        ON CONFLICT (activity_id) DO NOTHING
      '''),
      parameters: {
        'activity_id': activity['activity_id'],
        'type': activity['type'],
        'title': activity['title'],
        'description': activity['description'],
        'user_id': activity['user_id'],
        'timestamp': DateTime.parse(activity['timestamp']),
        'metadata': activity['metadata'] != null ? jsonEncode(activity['metadata']) : null,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getRecentActivities({
    String? userId,
    int limit = 10,
  }) async {
    final conn = await connection;
    
    String sql = '''
      SELECT * FROM activities
      ${userId != null ? 'WHERE user_id = @user_id' : ''}
      ORDER BY timestamp DESC
      LIMIT $limit
    ''';

    final result = await conn.execute(
      Sql.named(sql),
      parameters: userId != null ? {'user_id': userId} : {},
    );

    return result.map((row) => {
      'id': row[0],
      'activity_id': row[1],
      'type': row[2],
      'title': row[3],
      'description': row[4],
      'user_id': row[5],
      'timestamp': row[6]?.toString(),
      'metadata': row[7] != null ? jsonDecode(row[7] as String) : null,
      'created_at': row[8]?.toString(),
    }).toList();
  }

  // Settings operations
  Future<void> setSetting(String key, String value) async {
    final conn = await connection;
    
    await conn.execute(
      Sql.named('''
        INSERT INTO settings (key, value)
        VALUES (@key, @value)
        ON CONFLICT (key) DO UPDATE SET
          value = EXCLUDED.value,
          updated_at = CURRENT_TIMESTAMP
      '''),
      parameters: {'key': key, 'value': value},
    );
  }

  Future<String?> getSetting(String key) async {
    final conn = await connection;
    
    final result = await conn.execute(
      Sql.named('SELECT value FROM settings WHERE key = @key'),
      parameters: {'key': key},
    );

    return result.isNotEmpty ? result.first[0] as String? : null;
  }

  // Cache operations
  Future<void> setCachedData(String key, Map<String, dynamic> data, Duration expiry) async {
    final conn = await connection;
    final expiresAt = DateTime.now().add(expiry);
    
    await conn.execute(
      Sql.named('''
        INSERT INTO cached_data (cache_key, data, expires_at)
        VALUES (@cache_key, @data, @expires_at)
        ON CONFLICT (cache_key) DO UPDATE SET
          data = EXCLUDED.data,
          expires_at = EXCLUDED.expires_at,
          created_at = CURRENT_TIMESTAMP
      '''),
      parameters: {
        'cache_key': key,
        'data': jsonEncode(data),
        'expires_at': expiresAt,
      },
    );
  }

  Future<Map<String, dynamic>?> getCachedData(String key) async {
    final conn = await connection;
    
    final result = await conn.execute(
      Sql.named('''
        SELECT data FROM cached_data 
        WHERE cache_key = @cache_key AND expires_at > CURRENT_TIMESTAMP
      '''),
      parameters: {'cache_key': key},
    );
    
    if (result.isEmpty) return null;
    
    final jsonData = result.first[0] as String;
    return jsonDecode(jsonData) as Map<String, dynamic>;
  }

  Future<void> clearExpiredCache() async {
    final conn = await connection;
    
    await conn.execute(
      'DELETE FROM cached_data WHERE expires_at <= CURRENT_TIMESTAMP'
    );
  }

  // Sync operations
  Future<List<Map<String, dynamic>>> getUnsyncedSales() async {
    final conn = await connection;
    
    final result = await conn.execute(
      'SELECT * FROM sales WHERE synced = FALSE ORDER BY created_at ASC'
    );

    return result.map((row) => {
      'id': row[0],
      'sale_id': row[1],
      'user_id': row[2],
      'customer_name': row[3],
      'fuel_type': row[4],
      'quantity': row[5],
      'price_per_liter': row[6],
      'total_amount': row[7],
      'payment_method': row[8],
      'sale_date': row[9]?.toString(),
      'created_at': row[10]?.toString(),
      'synced': row[11],
    }).toList();
  }

  Future<void> markSaleAsSynced(String saleId) async {
    final conn = await connection;
    
    await conn.execute(
      Sql.named('UPDATE sales SET synced = TRUE WHERE sale_id = @sale_id'),
      parameters: {'sale_id': saleId},
    );
  }

  // Database maintenance
  Future<void> clearAllData() async {
    final conn = await connection;
    
    final tables = ['users', 'sales', 'inventory', 'activities', 'cached_data'];
    
    for (final table in tables) {
      await conn.execute('DELETE FROM $table');
    }
  }

  Future<void> closeConnection() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
      _isConnected = false;
    }
  }

  // Health check
  Future<bool> isHealthy() async {
    try {
      final conn = await connection;
      final result = await conn.execute('SELECT 1');
      return result.isNotEmpty;
    } catch (e) {
      print('❌ PostgreSQL health check failed: $e');
      return false;
    }
  }

  // Backup operations
  Future<Map<String, dynamic>> exportData() async {
    final conn = await connection;
    
    final users = await conn.execute('SELECT * FROM users');
    final sales = await conn.execute('SELECT * FROM sales');
    final inventory = await conn.execute('SELECT * FROM inventory');
    final activities = await conn.execute('SELECT * FROM activities');
    final settings = await conn.execute('SELECT * FROM settings');

    return {
      'users': users.map((row) => row.toList()).toList(),
      'sales': sales.map((row) => row.toList()).toList(),
      'inventory': inventory.map((row) => row.toList()).toList(),
      'activities': activities.map((row) => row.toList()).toList(),
      'settings': settings.map((row) => row.toList()).toList(),
      'export_timestamp': DateTime.now().toIso8601String(),
    };
  }
}
