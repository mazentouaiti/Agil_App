import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';
import 'storage_service.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:8000'; // Change this to your backend URL
  static final LocalAuthentication _localAuth = LocalAuthentication();

  // Login with email and password
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final token = responseData['access']?.toString();
        final refreshToken = responseData['refresh']?.toString();
        final userId = responseData['user_id']?.toString();
        
        if (token != null) {
          await StorageService.saveAuthToken(token);
          if (refreshToken != null) {
            await StorageService.saveRefreshToken(refreshToken);
          }
          if (userId != null) {
            await StorageService.saveUserId(userId);
          }
          await StorageService.saveUserEmail(email);
          await StorageService.setLoggedIn(true);
          
          return AuthResult.success(
            message: responseData['message'] ?? 'Login successful',
            data: responseData,
          );
        } else {
          return AuthResult.failure(
            message: 'Invalid response format',
          );
        }
      } else {
        return AuthResult.failure(
          message: responseData['message'] ?? 'Login failed',
        );
      }
    } catch (e) {
      return AuthResult.failure(
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Register new user
  static Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResult.success(
          message: responseData['message'] ?? 'Registration successful',
          data: responseData,
        );
      } else {
        return AuthResult.failure(
          message: responseData['message'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      return AuthResult.failure(
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Logout
  static Future<void> logout() async {
    try {
      final token = await StorageService.getAuthToken();
      if (token != null) {
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
    } catch (e) {
      // Continue with logout even if server request fails
    } finally {
      await StorageService.clearAuthData();
    }
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await StorageService.getAuthToken();
    return token != null && StorageService.isLoggedIn();
  }

  // Get current user info
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final token = await StorageService.getAuthToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Refresh token
  static Future<bool> refreshToken() async {
    try {
      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final newToken = responseData['access']?.toString();
        
        if (newToken != null) {
          await StorageService.saveAuthToken(newToken);
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Biometric authentication
  static Future<BiometricResult> authenticateWithBiometrics() async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        return BiometricResult.notAvailable(
          'Biometric authentication is not available on this device',
        );
      }

      final List<BiometricType> availableBiometrics = 
          await _localAuth.getAvailableBiometrics();

      if (availableBiometrics.isEmpty) {
        return BiometricResult.notEnrolled(
          'No biometric methods are enrolled on this device',
        );
      }

      final bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Authentifiez-vous pour accéder à votre compte',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        return BiometricResult.success('Authentication successful');
      } else {
        return BiometricResult.failed('Authentication failed');
      }
    } catch (e) {
      return BiometricResult.error('Error: ${e.toString()}');
    }
  }

  // Reset password
  static Future<AuthResult> resetPassword({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return AuthResult.success(
          message: responseData['message'] ?? 'Reset email sent',
          data: responseData,
        );
      } else {
        return AuthResult.failure(
          message: responseData['message'] ?? 'Reset failed',
        );
      }
    } catch (e) {
      return AuthResult.failure(
        message: 'Network error: ${e.toString()}',
      );
    }
  }
}

// Auth Result Classes
class AuthResult {
  final bool isSuccess;
  final String message;
  final Map<String, dynamic>? data;

  AuthResult._({
    required this.isSuccess,
    required this.message,
    this.data,
  });

  factory AuthResult.success({
    required String message,
    Map<String, dynamic>? data,
  }) {
    return AuthResult._(
      isSuccess: true,
      message: message,
      data: data,
    );
  }

  factory AuthResult.failure({
    required String message,
  }) {
    return AuthResult._(
      isSuccess: false,
      message: message,
    );
  }
}

class BiometricResult {
  final BiometricStatus status;
  final String message;

  BiometricResult._({
    required this.status,
    required this.message,
  });

  factory BiometricResult.success(String message) {
    return BiometricResult._(
      status: BiometricStatus.success,
      message: message,
    );
  }

  factory BiometricResult.failed(String message) {
    return BiometricResult._(
      status: BiometricStatus.failed,
      message: message,
    );
  }

  factory BiometricResult.notAvailable(String message) {
    return BiometricResult._(
      status: BiometricStatus.notAvailable,
      message: message,
    );
  }

  factory BiometricResult.notEnrolled(String message) {
    return BiometricResult._(
      status: BiometricStatus.notEnrolled,
      message: message,
    );
  }

  factory BiometricResult.error(String message) {
    return BiometricResult._(
      status: BiometricStatus.error,
      message: message,
    );
  }
}

enum BiometricStatus {
  success,
  failed,
  notAvailable,
  notEnrolled,
  error,
}
