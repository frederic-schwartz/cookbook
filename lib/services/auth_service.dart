import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const String baseUrl = 'https://api-cookbook-9fd56e.online404.com';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _expiresAtKey = 'expires_at';
  static const String _userDataKey = 'user_data';

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiresAt;
  User? _currentUser;

  // Getters
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _accessToken != null && _expiresAt != null && _expiresAt!.isAfter(DateTime.now());

  Future<void> initialize() async {
    await _loadTokensFromStorage();
    if (_accessToken != null && _expiresAt != null) {
      if (_expiresAt!.isBefore(DateTime.now())) {
        await _refreshTokenIfNeeded();
      }
      if (isAuthenticated) {
        await _loadUserData();
      }
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        
        _accessToken = authResponse.accessToken;
        _refreshToken = authResponse.refreshToken;
        _expiresAt = DateTime.now().add(Duration(seconds: authResponse.expires));

        await _saveTokensToStorage();
        await _loadUserData();
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _expiresAt = null;
    _currentUser = null;
    await _clearStorage();
  }

  Future<bool> _refreshTokenIfNeeded() async {
    if (_refreshToken == null) {
      // Clear invalid tokens
      await logout();
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refresh_token': _refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        
        _accessToken = authResponse.accessToken;
        _refreshToken = authResponse.refreshToken;
        _expiresAt = DateTime.now().add(Duration(seconds: authResponse.expires));

        await _saveTokensToStorage();
        await _loadUserData(); // Reload user data after refresh
        return true;
      } else {
        // Token refresh failed, logout user
        await logout();
        return false;
      }
    } catch (e) {
      // Token refresh failed, logout user
      await logout();
      return false;
    }
  }

  Future<void> _loadUserData() async {
    if (_accessToken == null) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body)['data'];
        _currentUser = User.fromJson(userData);
        await _saveUserDataToStorage();
      }
    } catch (e) {
      print('Load user data error: $e');
    }
  }

  Future<http.Response> authenticatedRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    if (!isAuthenticated) {
      await _refreshTokenIfNeeded();
    }

    if (!isAuthenticated) {
      throw Exception('Not authenticated');
    }

    final uri = Uri.parse('$baseUrl$endpoint');
    final requestHeaders = {
      'Authorization': 'Bearer $_accessToken',
      'Content-Type': 'application/json',
      ...?headers,
    };

    http.Response response;
    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(uri, headers: requestHeaders);
        break;
      case 'POST':
        response = await http.post(
          uri,
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'PUT':
        response = await http.put(
          uri,
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        );
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: requestHeaders);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    if (response.statusCode == 401) {
      if (await _refreshTokenIfNeeded()) {
        requestHeaders['Authorization'] = 'Bearer $_accessToken';
        switch (method.toUpperCase()) {
          case 'GET':
            response = await http.get(uri, headers: requestHeaders);
            break;
          case 'POST':
            response = await http.post(
              uri,
              headers: requestHeaders,
              body: body != null ? jsonEncode(body) : null,
            );
            break;
          case 'PUT':
            response = await http.put(
              uri,
              headers: requestHeaders,
              body: body != null ? jsonEncode(body) : null,
            );
            break;
          case 'DELETE':
            response = await http.delete(uri, headers: requestHeaders);
            break;
        }
      }
    }

    return response;
  }

  Future<void> _saveTokensToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) await prefs.setString(_accessTokenKey, _accessToken!);
    if (_refreshToken != null) await prefs.setString(_refreshTokenKey, _refreshToken!);
    if (_expiresAt != null) await prefs.setString(_expiresAtKey, _expiresAt!.toIso8601String());
  }

  Future<void> _saveUserDataToStorage() async {
    if (_currentUser != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDataKey, jsonEncode(_currentUser!.toJson()));
    }
  }

  Future<void> _loadTokensFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_accessTokenKey);
    _refreshToken = prefs.getString(_refreshTokenKey);
    final expiresAtString = prefs.getString(_expiresAtKey);
    if (expiresAtString != null) {
      _expiresAt = DateTime.parse(expiresAtString);
    }

    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      _currentUser = User.fromJson(jsonDecode(userDataString));
    }
  }

  Future<void> _clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_expiresAtKey);
    await prefs.remove(_userDataKey);
  }
}