import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/nutrition_repository.dart';

final nutritionRepositoryProvider =
    Provider<NutritionRepository>((_) => NutritionRepository());

final dailyNutritionProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(nutritionRepositoryProvider).dailyDashboard();
});

final foodSearchProvider = FutureProvider.autoDispose
    .family<List<FoodItem>, String>((ref, query) async {
  if (query.trim().length < 2) return [];
  return ref.read(nutritionRepositoryProvider).searchFoods(query);
});
