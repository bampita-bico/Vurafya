import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/engine_repository.dart';

final engineRepositoryProvider = Provider((ref) => EngineRepository());

final stabilityProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(engineRepositoryProvider);
  return repo.getStabilityMetrics();
});

final trajectoryProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(engineRepositoryProvider);
  return repo.getTrajectoryPrediction();
});

final runtimeRunsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(engineRepositoryProvider);
  return repo.getRuntimeRuns();
});

final runtimeDoctorProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(engineRepositoryProvider);
  return repo.getRuntimeDoctor();
});

final influencePathsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(engineRepositoryProvider);
  return repo.getInfluencePaths();
});
