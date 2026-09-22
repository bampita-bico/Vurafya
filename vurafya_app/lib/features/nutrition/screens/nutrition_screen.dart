import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/nutrition_provider.dart';
import '../repositories/nutrition_repository.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  Future<void> _openLogMeal() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _LogMealSheet(),
    );
    if (result == true && mounted) {
      ref.invalidate(dailyNutritionProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal logged')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyAsync = ref.watch(dailyNutritionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Metabolic Fuel',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: dailyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load nutrition data.\n$e',
                textAlign: TextAlign.center),
          ),
        ),
        data: (data) {
          final totals =
              Map<String, dynamic>.from((data['totals'] as Map?) ?? const {});
          final protein = (totals['total_protein_g'] as num?)?.toDouble() ?? 0;
          final potassium =
              (totals['total_potassium_mg'] as num?)?.toDouble() ?? 0;
          final phosphorus =
              (totals['total_phosphorus_mg'] as num?)?.toDouble() ?? 0;
          final pral = (totals['total_pral'] as num?)?.toDouble() ?? 0;
          final mealCount = (totals['meal_count'] as num?)?.toInt() ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.shade400,
                        Colors.deepOrange.shade600
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.local_fire_department,
                              color: Colors.white, size: 28),
                          SizedBox(width: 12),
                          Text('Today',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('$mealCount meals logged',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text(
                        mealCount == 0
                            ? 'Search foods from the Vurafya database and log your first meal.'
                            : 'Totals update from your logged meals.',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Daily totals (3Ps)',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                const SizedBox(height: 16),
                _buildTargetRow('Protein', protein, 60, 'g', Colors.blue),
                const SizedBox(height: 16),
                _buildTargetRow(
                    'Potassium', potassium, 2000, 'mg', Colors.purple),
                const SizedBox(height: 16),
                _buildTargetRow(
                    'Phosphorus', phosphorus, 800, 'mg', Colors.teal),
                const SizedBox(height: 32),
                const Text('Acid-Base Balance',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('PRAL Score',
                                style: TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(pral.toStringAsFixed(1),
                                style: TextStyle(
                                    color: pral <= 0
                                        ? Colors.green
                                        : Colors.orange,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Icon(Icons.eco,
                          color: pral <= 0
                              ? Colors.green.shade500
                              : Colors.orange.shade500,
                          size: 30),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _openLogMeal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade600,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Log a Meal',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTargetRow(String label, double current, double max, String unit,
      MaterialColor color) {
    final progress = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.black87)),
            Text('${current.toStringAsFixed(0)} / ${max.toInt()} $unit',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.black54)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.shade50,
          valueColor: AlwaysStoppedAnimation<Color>(color.shade400),
          minHeight: 10,
          borderRadius: BorderRadius.circular(5),
        ),
      ],
    );
  }
}

class _LogMealSheet extends ConsumerStatefulWidget {
  const _LogMealSheet();

  @override
  ConsumerState<_LogMealSheet> createState() => _LogMealSheetState();
}

class _LogMealSheetState extends ConsumerState<_LogMealSheet> {
  final _searchCtrl = TextEditingController();
  final _gramsCtrl = TextEditingController(text: '100');
  String _mealType = 'lunch';
  String _portion = 'grams';
  FoodItem? _selected;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _gramsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selected == null) {
      setState(() => _error = 'Pick a food first');
      return;
    }
    final grams = double.tryParse(_gramsCtrl.text.trim());
    if (grams == null || grams <= 0) {
      setState(() => _error = 'Enter a valid portion in grams');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(nutritionRepositoryProvider).logMeal(
            mealType: _mealType,
            foodId: _selected!.id,
            quantityGrams: grams,
          );
      if (mounted) Navigator.pop(context, true);
    } on DioException catch (e) {
      setState(() => _error =
          e.response?.data?['detail']?.toString() ?? 'Failed to log meal');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _selectPortion(String portion) {
    setState(() {
      _portion = portion;
      if (portion == 'cup') {
        _gramsCtrl.text = _selected?.category == 'Beverages' ? '250' : '150';
      } else if (portion == 'plate') {
        _gramsCtrl.text = '350';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text;
    final results = ref.watch(foodSearchProvider(query));

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Log a meal',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              labelText: 'Search foods',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _mealType,
            items: const [
              DropdownMenuItem(value: 'breakfast', child: Text('Breakfast')),
              DropdownMenuItem(value: 'lunch', child: Text('Lunch')),
              DropdownMenuItem(value: 'dinner', child: Text('Dinner')),
              DropdownMenuItem(value: 'snack', child: Text('Snack')),
            ],
            onChanged: (v) => setState(() => _mealType = v ?? 'lunch'),
            decoration: const InputDecoration(labelText: 'Meal type'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: results.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (foods) => foods.isEmpty
                  ? const Center(
                      child: Text('Type at least 2 characters to search'))
                  : ListView.builder(
                      itemCount: foods.length,
                      itemBuilder: (_, i) {
                        final food = foods[i];
                        final selected = _selected?.id == food.id;
                        return ListTile(
                          selected: selected,
                          title: Text(food.name),
                          subtitle: food.localName != null
                              ? Text(food.localName!)
                              : (food.category != null
                                  ? Text(food.category!)
                                  : null),
                          onTap: () => setState(() {
                            _selected = food;
                            _portion = 'grams';
                            _gramsCtrl.text = '100';
                          }),
                        );
                      },
                    ),
            ),
          ),
          DropdownButtonFormField<String>(
            key: ValueKey(_portion),
            initialValue: _portion,
            decoration: const InputDecoration(labelText: 'Household measure'),
            items: [
              const DropdownMenuItem(
                  value: 'grams', child: Text('Grams (exact)')),
              const DropdownMenuItem(
                  value: 'cup', child: Text('1 cup (estimate)')),
              if (_selected?.category != 'Beverages')
                const DropdownMenuItem(
                    value: 'plate', child: Text('1 plate (estimate)')),
            ],
            onChanged: _selected == null
                ? null
                : (value) => _selectPortion(value ?? 'grams'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _gramsCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Portion (grams)',
              suffixText: 'g',
            ),
          ),
          if (_portion != 'grams')
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                  'Household measures are editable estimates; confirm grams when possible.'),
            ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save meal'),
          ),
        ],
      ),
    );
  }
}
