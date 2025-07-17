import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static SharedPreferences? _prefs;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Regular storage methods
  static Future<bool> setString(String key, String value) async {
    return await _prefs?.setString(key, value) ?? false;
  }

  static String? getString(String key) {
    return _prefs?.getString(key);
  }

  static Future<bool> setBool(String key, bool value) async {
    return await _prefs?.setBool(key, value) ?? false;
  }

  static bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  static Future<bool> setInt(String key, int value) async {
    return await _prefs?.setInt(key, value) ?? false;
  }

  static int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  static Future<bool> setDouble(String key, double value) async {
    return await _prefs?.setDouble(key, value) ?? false;
  }

  static double? getDouble(String key) {
    return _prefs?.getDouble(key);
  }

  static Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs?.setStringList(key, value) ?? false;
  }

  static List<String>? getStringList(String key) {
    return _prefs?.getStringList(key);
  }

  static Future<bool> remove(String key) async {
    return await _prefs?.remove(key) ?? false;
  }

  static Future<bool> clear() async {
    return await _prefs?.clear() ?? false;
  }

  static bool containsKey(String key) {
    return _prefs?.containsKey(key) ?? false;
  }

  // Secure storage methods
  static Future<void> setSecureString(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  static Future<String?> getSecureString(String key) async {
    return await _secureStorage.read(key: key);
  }

  static Future<void> deleteSecureString(String key) async {
    await _secureStorage.delete(key: key);
  }

  static Future<void> clearSecureStorage() async {
    await _secureStorage.deleteAll();
  }

  static Future<bool> containsSecureKey(String key) async {
    return await _secureStorage.containsKey(key: key);
  }

  // Convenience methods for common keys
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _firstLaunchKey = 'first_launch';
  static const String _languageKey = 'language';
  static const String _themeKey = 'theme';

  // Auth related methods
  static Future<void> saveAuthToken(String token) async {
    await setSecureString(_tokenKey, token);
  }

  static Future<String?> getAuthToken() async {
    return await getSecureString(_tokenKey);
  }

  static Future<void> saveRefreshToken(String token) async {
    await setSecureString(_refreshTokenKey, token);
  }

  static Future<String?> getRefreshToken() async {
    return await getSecureString(_refreshTokenKey);
  }

  static Future<void> saveUserId(String userId) async {
    await setSecureString(_userIdKey, userId);
  }

  static Future<String?> getUserId() async {
    return await getSecureString(_userIdKey);
  }

  static Future<void> saveUserEmail(String email) async {
    await setString(_userEmailKey, email);
  }

  static String? getUserEmail() {
    return getString(_userEmailKey);
  }

  static Future<void> setLoggedIn(bool isLoggedIn) async {
    await setBool(_isLoggedInKey, isLoggedIn);
  }

  static bool isLoggedIn() {
    return getBool(_isLoggedInKey) ?? false;
  }

  static Future<void> setFirstLaunch(bool isFirstLaunch) async {
    await setBool(_firstLaunchKey, isFirstLaunch);
  }

  static bool isFirstLaunch() {
    return getBool(_firstLaunchKey) ?? true;
  }

  static Future<void> saveLanguage(String language) async {
    await setString(_languageKey, language);
  }

  static String getLanguage() {
    return getString(_languageKey) ?? 'fr';
  }

  static Future<void> saveTheme(String theme) async {
    await setString(_themeKey, theme);
  }

  static String getTheme() {
    return getString(_themeKey) ?? 'light';
  }

  static Future<void> clearAuthData() async {
    await deleteSecureString(_tokenKey);
    await deleteSecureString(_refreshTokenKey);
    await deleteSecureString(_userIdKey);
    await remove(_userEmailKey);
    await setLoggedIn(false);
  }
}
