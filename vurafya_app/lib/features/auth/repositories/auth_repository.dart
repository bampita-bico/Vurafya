import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/auth_models.dart';

class AuthRepository {
  final _api = ApiClient();

  Future<AuthTokens> register({
    required String email,
    required String username,
    required String password,
  }) async {
    final resp = await _api.dio.post('/auth/register', data: {
      'email': email,
      'username': username,
      'password': password,
    });
    final tokens = AuthTokens.fromJson(resp.data);
    await _api.saveTokens(tokens.accessToken, tokens.refreshToken);
    return tokens;
  }

  Future<AuthTokens> demoLogin() async {
    final resp = await _api.dio.post('/auth/demo-login');
    final tokens = AuthTokens.fromJson(resp.data);
    await _api.saveTokens(tokens.accessToken, tokens.refreshToken);
    return tokens;
  }

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final resp = await _api.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final tokens = AuthTokens.fromJson(resp.data);
    await _api.saveTokens(tokens.accessToken, tokens.refreshToken);
    return tokens;
  }

  Future<UserProfile> getProfile() async {
    final resp = await _api.dio.get('/users/me');
    return UserProfile.fromJson(resp.data);
  }

  Future<void> logout() async {
    try {
      await _api.dio.post('/auth/logout');
    } on DioException catch (_) {
      // Best-effort logout; clear tokens regardless
    }
    await _api.clearTokens();
  }

  Future<void> clearSession() async {
    await _api.clearTokens();
  }

  Future<bool> get isLoggedIn async {
    final token = await _api.accessToken;
    return token != null;
  }
}
