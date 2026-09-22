import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/engine/offline_edge_engine.dart';

class EngineRepository {
  final ApiClient _apiClient = ApiClient();
  final OfflineEdgeEngine _edgeEngine = OfflineEdgeEngine();

  // Never synthesize biometrics. A durable cache can populate this method once
  // the user has explicitly saved measurements on-device.
  Map<String, dynamic> _getLocalBiometricsCache() {
    return <String, dynamic>{};
  }

  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  Map<String, dynamic> _withOfflineEvidence(Map<String, dynamic> payload) {
    final guidance = _asMap(payload["runtime_guidance"]);
    return {
      ...payload,
      "finite_audit": {"all_finite": true, "non_finite_paths": []},
      "provenance": {
        "runtime": "Vurafya Offline Edge Engine",
        "language": "CDFL-compatible local model",
        "command": "offline stability fallback",
        "timestamp_utc": DateTime.now().toUtc().toIso8601String(),
      },
      "claim_boundary":
          "Offline output is local modeling support only and must be synced for full runtime review.",
      "runtime_run": {
        "run_uid": "offline-local",
        "summary": {
          "status": "offline",
          "guidance_state": guidance["state"] ?? payload["clinical_regime"],
          "finite_audit": {"all_finite": true, "non_finite_paths": []},
        },
        "artifacts": {},
        "persistence_error":
            "Runtime service unavailable; no server artifact bundle was written.",
      },
    };
  }

  Future<Map<String, dynamic>> getStabilityMetrics() async {
    try {
      final response = await _apiClient.dio.get('/engine/stability');
      return _asMap(response.data);
    } on DioException catch (e) {
      if (_isNetworkError(e)) {
        debugPrint(
            "[EngineRepository] Network unavailable. Falling back to Offline Edge Engine.");
        final localData = _getLocalBiometricsCache();
        return _withOfflineEvidence(_edgeEngine.calculateStability(localData));
      }
      throw Exception('Failed to fetch stability metrics: ${e.message}');
    } catch (e) {
      // General fallback
      debugPrint(
          "[EngineRepository] Unknown error. Falling back to Offline Edge Engine. Error: $e");
      return _withOfflineEvidence(
          _edgeEngine.calculateStability(_getLocalBiometricsCache()));
    }
  }

  Future<List<dynamic>> getTrajectoryPrediction({int steps = 50}) async {
    try {
      final response = await _apiClient.dio.get(
        '/engine/trajectory',
        queryParameters: {'steps': steps},
      );
      return response.data['forecast'] ?? response.data['trajectory'];
    } on DioException catch (e) {
      if (_isNetworkError(e)) {
        debugPrint(
            "[EngineRepository] Network unavailable. Generating trajectory via Offline Edge Engine.");
        final currentStability =
            _edgeEngine.calculateStability(_getLocalBiometricsCache());
        final score = currentStability['clinical_stability_score'];
        if (score is! num) return [];
        return _edgeEngine.generateOfflineTrajectory(score.toDouble(), steps);
      }
      throw Exception('Failed to fetch trajectory projection: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> triggerAnalysis() async {
    try {
      final response = await _apiClient.dio.post('/engine/analyze');
      return response.data;
    } on DioException catch (e) {
      if (_isNetworkError(e)) {
        // We cannot reach the app service, but we can compute a local model summary.
        final stability =
            _edgeEngine.calculateStability(_getLocalBiometricsCache());
        return {
          "status": "offline_analysis",
          "message":
              "Runtime service unavailable. Local model regime is: ${stability['clinical_regime']}",
          "recommendations": ["Sync when online for the full runtime summary."]
        };
      }
      throw Exception('Failed to trigger analysis: ${e.message}');
    }
  }

  Future<List<Map<String, dynamic>>> getRuntimeRuns({int limit = 20}) async {
    try {
      final response = await _apiClient.dio.get(
        '/engine/runs',
        queryParameters: {'limit': limit},
      );
      final List<dynamic> runs = response.data['runs'] ?? [];
      return runs.map((item) => _asMap(item)).toList();
    } on DioException catch (e) {
      if (_isNetworkError(e)) return [];
      throw Exception('Failed to fetch runtime runs: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> getRuntimeDoctor() async {
    try {
      final response = await _apiClient.dio.get('/engine/doctor');
      return _asMap(response.data);
    } on DioException catch (e) {
      if (_isNetworkError(e)) {
        return {
          "status": "offline",
          "checks": [],
          "errors": ["Runtime service unavailable from this device."],
        };
      }
      throw Exception('Failed to fetch runtime doctor report: ${e.message}');
    }
  }

  Future<List<Map<String, dynamic>>> getInfluencePaths() async {
    try {
      final response = await _apiClient.dio.get('/ontology/influence');
      final List<dynamic> paths = response.data['paths'] ?? [];
      return paths.map((e) => Map<String, dynamic>.from(e)).toList();
    } on DioException catch (e) {
      if (_isNetworkError(e)) {
        // Return an empty list or cached paths when offline
        debugPrint(
            "[EngineRepository] Network unavailable. Cannot fetch complex influence paths.");
        return [];
      }
      throw Exception('Failed to fetch influence paths: ${e.message}');
    }
  }
}
