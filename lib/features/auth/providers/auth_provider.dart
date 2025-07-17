import 'package:flutter/foundation.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _userEmail;
  String? _userId;
  Map<String, dynamic>? _currentUser;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _userEmail;
  String? get userId => _userId;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _isAuthenticated = await AuthService.isAuthenticated();
    _userEmail = StorageService.getUserEmail();
    _userId = await StorageService.getUserId();
    
    if (_isAuthenticated) {
      await loadCurrentUser();
    }
    
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await AuthService.login(
        email: email,
        password: password,
      );

      if (result.isSuccess) {
        _isAuthenticated = true;
        _userEmail = email;
        _userId = await StorageService.getUserId();
        await loadCurrentUser();
        _setLoading(false);
        return true;
      } else {
        _setError(result.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await AuthService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );

      _setLoading(false);

      if (result.isSuccess) {
        return true;
      } else {
        _setError(result.message);
        return false;
      }
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    
    try {
      await AuthService.logout();
      _isAuthenticated = false;
      _userEmail = null;
      _userId = null;
      _currentUser = null;
      _errorMessage = null;
    } catch (e) {
      _setError('Logout failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await AuthService.authenticateWithBiometrics();
      _setLoading(false);

      switch (result.status) {
        case BiometricStatus.success:
          // If biometric auth is successful and user was previously logged in
          if (await AuthService.isAuthenticated()) {
            _isAuthenticated = true;
            _userEmail = StorageService.getUserEmail();
            _userId = await StorageService.getUserId();
            await loadCurrentUser();
            return true;
          }
          return false;
        case BiometricStatus.failed:
          _setError(result.message);
          return false;
        case BiometricStatus.notAvailable:
          _setError(result.message);
          return false;
        case BiometricStatus.notEnrolled:
          _setError(result.message);
          return false;
        case BiometricStatus.error:
          _setError(result.message);
          return false;
      }
    } catch (e) {
      _setError('Biometric authentication failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetPassword({required String email}) async {
    _setLoading(true);
    _setError(null);

    try {
      final result = await AuthService.resetPassword(email: email);
      _setLoading(false);

      if (result.isSuccess) {
        return true;
      } else {
        _setError(result.message);
        return false;
      }
    } catch (e) {
      _setError('Password reset failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<void> loadCurrentUser() async {
    try {
      _currentUser = await AuthService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load user data: ${e.toString()}');
    }
  }

  Future<bool> refreshToken() async {
    try {
      final success = await AuthService.refreshToken();
      if (!success) {
        await logout();
      }
      return success;
    } catch (e) {
      await logout();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Check if current session is valid
  Future<bool> validateSession() async {
    if (!_isAuthenticated) return false;
    
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        await logout();
        return false;
      }
      return true;
    } catch (e) {
      // Try to refresh token
      final refreshed = await refreshToken();
      if (!refreshed) {
        await logout();
        return false;
      }
      return true;
    }
  }
}
