import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/services/hybrid_database_service.dart';
import '../../../core/services/database_migration_service.dart';

class DatabaseSettingsScreen extends StatefulWidget {
  const DatabaseSettingsScreen({super.key});

  @override
  State<DatabaseSettingsScreen> createState() => _DatabaseSettingsScreenState();
}

class _DatabaseSettingsScreenState extends State<DatabaseSettingsScreen> {
  final HybridDatabaseService _dbService = HybridDatabaseService();
  final AWSRDSManagementService _rdsService = AWSRDSManagementService();
  
  bool _isLoading = false;
  Map<String, dynamic>? _dbStats;
  Map<String, dynamic>? _rdsInfo;
  List<Map<String, dynamic>>? _migrationHistory;

  @override
  void initState() {
    super.initState();
    _loadDatabaseInfo();
  }

  Future<void> _loadDatabaseInfo() async {
    setState(() => _isLoading = true);

    try {
      final stats = await _dbService.getDatabaseStats();
      final rdsInfo = await _rdsService.getRDSInstanceInfo();
      
      setState(() {
        _dbStats = stats;
        _rdsInfo = rdsInfo;
      });

      // Load migration history if using PostgreSQL
      if (_dbService.isUsingPostgreSQL) {
        // Migration history would require database connection
        // This could be implemented when needed
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load database info: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _switchDatabase() async {
    setState(() => _isLoading = true);

    try {
      if (_dbService.isUsingPostgreSQL) {
        await _dbService.switchToSQLite();
        _showSuccessSnackBar('Switched to SQLite database');
      } else {
        await _dbService.switchToPostgreSQL();
        _showSuccessSnackBar('Switched to PostgreSQL database');
      }
      
      await _loadDatabaseInfo();
    } catch (e) {
      _showErrorSnackBar('Failed to switch database: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testConnection() async {
    setState(() => _isLoading = true);

    try {
      final isHealthy = await _dbService.isHealthy();
      
      if (isHealthy) {
        _showSuccessSnackBar('Database connection is healthy');
      } else {
        _showErrorSnackBar('Database connection failed');
      }

      // Test RDS connection if using PostgreSQL
      if (_dbService.isUsingPostgreSQL) {
        final rdsTestResult = await _rdsService.testConnection();
        if (rdsTestResult) {
          _showSuccessSnackBar('AWS RDS connection test passed');
        } else {
          _showErrorSnackBar('AWS RDS connection test failed');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Connection test failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportData() async {
    setState(() => _isLoading = true);

    try {
      final data = await _dbService.exportData();
      
      // In a real app, you would save this to a file
      final timestamp = DateTime.now().toIso8601String();
      _showSuccessSnackBar('Data exported successfully at $timestamp');
      
      // Show export info
      _showExportDialog(data);
    } catch (e) {
      _showErrorSnackBar('Export failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showExportDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Export completed at: ${data['export_timestamp']}'),
              const SizedBox(height: 16),
              if (data['users'] != null)
                Text('Users: ${(data['users'] as List).length} records'),
              if (data['sales'] != null)
                Text('Sales: ${(data['sales'] as List).length} records'),
              if (data['inventory'] != null)
                Text('Inventory: ${(data['inventory'] as List).length} records'),
              if (data['activities'] != null)
                Text('Activities: ${(data['activities'] as List).length} records'),
              if (data['settings'] != null)
                Text('Settings: ${(data['settings'] as List).length} records'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Settings'),
        backgroundColor: const Color(0xFFD4AF37),
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDatabaseStatusCard(),
                  const SizedBox(height: 16),
                  _buildDatabaseStatsCard(),
                  const SizedBox(height: 16),
                  _buildRDSInfoCard(),
                  const SizedBox(height: 16),
                  _buildActionsCard(),
                  if (_migrationHistory != null) ...[
                    const SizedBox(height: 16),
                    _buildMigrationHistoryCard(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildDatabaseStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _dbService.isUsingPostgreSQL
                      ? FontAwesomeIcons.database
                      : FontAwesomeIcons.hardDrive,
                  color: const Color(0xFFD4AF37),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Database Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _dbStats?['is_healthy'] == true
                        ? Colors.green
                        : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _dbService.isUsingPostgreSQL
                      ? 'PostgreSQL (AWS RDS)'
                      : 'SQLite (Local)',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${_dbStats?['is_healthy'] == true ? 'Healthy' : 'Unhealthy'}',
              style: TextStyle(
                color: _dbStats?['is_healthy'] == true
                    ? Colors.green
                    : Colors.red,
              ),
            ),
            if (_dbStats?['timestamp'] != null)
              Text(
                'Last checked: ${_dbStats!['timestamp']}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatabaseStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  FontAwesomeIcons.chartBar,
                  color: Color(0xFFD4AF37),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Database Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_dbStats != null) ...[
              _buildStatRow('Users', _dbStats!['users_count']),
              _buildStatRow('Sales', _dbStats!['sales_count']),
              _buildStatRow('Inventory Items', _dbStats!['inventory_count']),
              _buildStatRow('Activities', _dbStats!['activities_count']),
            ] else
              const Text('No statistics available'),
          ],
        ),
      ),
    );
  }

  Widget _buildRDSInfoCard() {
    if (!_dbService.isUsingPostgreSQL || _rdsInfo == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  FontAwesomeIcons.aws,
                  color: Color(0xFFD4AF37),
                ),
                const SizedBox(width: 8),
                const Text(
                  'AWS RDS Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow('Instance Class', _rdsInfo!['instance_class']),
            _buildStatRow('Engine', _rdsInfo!['engine']),
            _buildStatRow('Engine Version', _rdsInfo!['engine_version']),
            _buildStatRow('Storage', '${_rdsInfo!['allocated_storage']} GB'),
            _buildStatRow('Storage Type', _rdsInfo!['storage_type']),
            _buildStatRow('Encrypted', _rdsInfo!['storage_encrypted'] ? 'Yes' : 'No'),
            _buildStatRow('Backup Retention', '${_rdsInfo!['backup_retention_period']} days'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  FontAwesomeIcons.cog,
                  color: Color(0xFFD4AF37),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Database Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _testConnection,
                icon: const Icon(FontAwesomeIcons.networkWired),
                label: const Text('Test Connection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _switchDatabase,
                icon: Icon(_dbService.isUsingPostgreSQL
                    ? FontAwesomeIcons.hardDrive
                    : FontAwesomeIcons.database),
                label: Text(_dbService.isUsingPostgreSQL
                    ? 'Switch to SQLite'
                    : 'Switch to PostgreSQL'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _exportData,
                icon: const Icon(FontAwesomeIcons.download),
                label: const Text('Export Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loadDatabaseInfo,
                icon: const Icon(FontAwesomeIcons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMigrationHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  FontAwesomeIcons.history,
                  color: Color(0xFFD4AF37),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Migration History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_migrationHistory != null && _migrationHistory!.isNotEmpty)
              ...(_migrationHistory!.map((migration) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(migration['filename'] ?? 'Unknown'),
                        Text(
                          migration['executed_at'] ?? 'Unknown',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  )))
            else
              const Text('No migration history available'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value?.toString() ?? '0',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
