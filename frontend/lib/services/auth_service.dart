import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/panel_profile.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthService extends ChangeNotifier {
  static const String baseUrl = 'http://localhost:8080/api';
  
  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  bool _isInitialized = false;
  late final Future<void> ready;

  /// Cliente HTTP que envia o token do usuário logado; em 401 encerra a sessão
  late final ApiClient apiClient = ApiClient(
    tokenProvider: () => _token,
    onUnauthorized: logout,
  );

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _token != null && _currentUser != null;

  /// Rota inicial de acordo com o perfil do usuário logado
  String get homeRoute {
    final user = _currentUser;
    if (user == null) return '/login';
    return PanelProfile.of(user).first.route;
  }

  AuthService() {
    ready = _loadStoredAuth();
  }

  Future<void> _loadStoredAuth() async {
    try {
      await _restoreSession();
    } catch (e) {
      // Sessão salva corrompida ou em formato antigo: descarta
      await logout();
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    
    if (_token != null) {
      final userJson = prefs.getString('user_data');
      if (userJson != null) {
        _currentUser = User.fromJson(json.decode(userJson));
        notifyListeners();
      }
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['accessToken'];
        _currentUser = User.fromJson(data['user']);

        // Salvar no SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_data', json.encode(_currentUser!.toJson()));

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    UserType? userType,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final body = {
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
      };

      // Só adicionar userType se foi fornecido
      if (userType != null) {
        body['userType'] = userType.toString().split('.').last;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      _isLoading = false;
      notifyListeners();
      return response.statusCode == 200;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');

    notifyListeners();
  }

  Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };
}
