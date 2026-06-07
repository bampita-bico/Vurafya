import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

final aiRecommendationsProvider =
    AsyncNotifierProvider<AiRecommendationsNotifier, List<Map<String, dynamic>>>(
  AiRecommendationsNotifier.new,
);

class AiRecommendationsNotifier
    extends AsyncNotifier<List<Map<String, dynamic>>> {
  final _api = ApiClient();

  @override
  Future<List<Map<String, dynamic>>> build() => _fetch();

  Future<List<Map<String, dynamic>>> _fetch() async {
    try {
      final resp = await _api.dio.get('/ai-recommendations/');
      return List<Map<String, dynamic>>.from(resp.data as List);
    } catch (_) {
      return [];
    }
  }

  Future<void> dismiss(int id) async {
    try {
      await _api.dio.post('/ai-recommendations/$id/dismiss');
      state = AsyncValue.data(
        state.value?.where((r) => r['id'] != id).toList() ?? [],
      );
    } catch (_) {}
  }

  Future<void> generate() async {
    try {
      await _api.dio.post('/ai-recommendations/generate');
      state = AsyncValue.data(await _fetch());
    } catch (_) {}
  }
}
