import '../../../core/api/api_client.dart';

class FoodItem {
  final int id;
  final String name;
  final String? localName;
  final String? category;
  final double? glycemicIndex;

  FoodItem({
    required this.id,
    required this.name,
    this.localName,
    this.category,
    this.glycemicIndex,
  });

  factory FoodItem.fromJson(Map<String, dynamic> j) => FoodItem(
        id: j['id'] as int,
        name: j['name'] as String? ?? 'Food',
        localName: j['local_name'] as String?,
        category: j['category'] as String?,
        glycemicIndex: (j['glycemic_index'] as num?)?.toDouble(),
      );
}

class NutritionRepository {
  final _api = ApiClient();

  Future<List<FoodItem>> searchFoods(String query) async {
    if (query.trim().length < 2) return [];
    final resp = await _api.dio.get(
      '/nutrition/foods/search',
      queryParameters: {'q': query.trim(), 'limit': 25},
    );
    final items = resp.data['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> dailyDashboard({String? mealDate}) async {
    final resp = await _api.dio.get(
      '/nutrition/dashboard/daily',
      queryParameters: mealDate != null ? {'meal_date': mealDate} : null,
    );
    return Map<String, dynamic>.from(resp.data as Map);
  }

  Future<Map<String, dynamic>> logMeal({
    required String mealType,
    required int foodId,
    required double quantityGrams,
    String? notes,
  }) async {
    final resp = await _api.dio.post('/nutrition/meals', data: {
      'meal_type': mealType,
      'components': [
        {
          'food_id': foodId,
          'quantity_grams': quantityGrams,
          'meal_component_type': 'main',
        }
      ],
      if (notes != null) 'notes': notes,
    });
    return Map<String, dynamic>.from(resp.data as Map);
  }
}
