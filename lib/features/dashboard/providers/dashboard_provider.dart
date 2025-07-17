import 'package:flutter/foundation.dart';

class DashboardProvider extends ChangeNotifier {
  bool _isLoading = false;
  List<Map<String, dynamic>> _dashboardData = [];
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get dashboardData => _dashboardData;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<void> loadDashboardData() async {
    _setLoading(true);
    _setError(null);

    try {
      // Simulate API call - replace with actual API call
      await Future.delayed(const Duration(seconds: 1));
      
      _dashboardData = [
        {
          'title': 'Total Sales',
          'value': '45,230 TND',
          'change': '+12.5%',
          'isPositive': true,
        },
        {
          'title': 'Orders Today',
          'value': '127',
          'change': '+5.2%',
          'isPositive': true,
        },
        {
          'title': 'Inventory',
          'value': '89%',
          'change': '-2.1%',
          'isPositive': false,
        },
        {
          'title': 'Revenue',
          'value': '156,780 TND',
          'change': '+18.7%',
          'isPositive': true,
        },
      ];
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load dashboard data: ${e.toString()}');
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
