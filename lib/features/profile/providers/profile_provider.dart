import 'package:flutter/foundation.dart';

class ProfileProvider extends ChangeNotifier {
  bool _isLoading = false;
  Map<String, dynamic>? _userProfile;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get userProfile => _userProfile;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<void> loadUserProfile() async {
    _setLoading(true);
    _setError(null);

    try {
      // Simulate API call - replace with actual API call
      await Future.delayed(const Duration(seconds: 1));
      
      _userProfile = {
        'name': 'Ahmed Ben Ali',
        'email': 'ahmed.benali@agil.tn',
        'phone': '+216 98 123 456',
        'position': 'Station Manager',
        'station': 'Agil Station Tunis Centre',
        'avatar': null,
        'joinDate': '2023-01-15',
        'address': '123 Avenue Habib Bourguiba, Tunis',
        'id': 'EMP-001',
      };
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to load profile: ${e.toString()}');
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String phone,
    required String address,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      // Simulate API call - replace with actual API call
      await Future.delayed(const Duration(seconds: 1));
      
      if (_userProfile != null) {
        _userProfile!['name'] = name;
        _userProfile!['phone'] = phone;
        _userProfile!['address'] = address;
      }
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update profile: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
