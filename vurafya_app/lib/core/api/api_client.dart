import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Supply this at build time. Production builds must use an HTTPS endpoint.
// Example: --dart-define=VURAFYA_API_URL=https://api.vurafya.example/api/v1
// The emulator fallback is deliberately local-only and is permitted only by
// the Android debug manifest.
const _kBaseUrl = String.fromEnvironment(
  'VURAFYA_API_URL',
  defaultValue: 'http://10.0.2.2:8000/api/v1',
);

class ApiClient {
  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;

  late final Dio dio;
  final _storage = const FlutterSecureStorage();
  Future<bool>? _refreshInFlight;

  ApiClient._() {
    dio = Dio(BaseOptions(
      baseUrl: _kBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: _attachToken,
      onError: _handleError,
    ));
  }

  Future<void> _attachToken(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final path = options.path;
    if (path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/demo-login')) {
      return handler.next(options);
    }
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _handleError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final path = err.requestOptions.path;
      if (path.contains('/auth/login') ||
          path.contains('/auth/register') ||
          path.contains('/auth/demo-login') ||
          path.contains('/auth/refresh')) {
        return handler.next(err);
      }
      if (err.requestOptions.extra['token_refreshed'] == true) {
        return handler.next(err);
      }
      final refreshed = await _tryRefresh();
      if (refreshed) {
        // Retry original request with new token
        final token = await _storage.read(key: 'access_token');
        err.requestOptions.headers['Authorization'] = 'Bearer $token';
        err.requestOptions.extra['token_refreshed'] = true;
        final retry = await dio.fetch(err.requestOptions);
        return handler.resolve(retry);
      }
    }
    handler.next(err);
  }

  Future<bool> _tryRefresh() async {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;
    final refresh = _refreshTokens();
    _refreshInFlight = refresh;
    try {
      return await refresh;
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<bool> _refreshTokens() async {
    try {
      final refresh = await _storage.read(key: 'refresh_token');
      if (refresh == null) return false;
      final resp = await Dio().post(
        '$_kBaseUrl/auth/refresh',
        data: {'refresh_token': refresh},
      );
      await _storage.write(
          key: 'access_token', value: resp.data['access_token']);
      await _storage.write(
          key: 'refresh_token', value: resp.data['refresh_token']);
      return true;
    } catch (_) {
      await _storage.deleteAll();
      return false;
    }
  }

  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
  }

  Future<void> clearTokens() async => await _storage.deleteAll();

  Future<String?> get accessToken => _storage.read(key: 'access_token');
}
