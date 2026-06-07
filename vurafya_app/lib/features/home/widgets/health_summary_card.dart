import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

// Placeholder data until nutrition providers are wired
class _SummaryData {
  final double caloriePercent;
  final int calories;
  final int calorieTarget;
  final int water;

  const _SummaryData({
    required this.caloriePercent,
    required this.calories,
    required this.calorieTarget,
    required this.water,
  });
}

final _summaryProvider = Provider<_SummaryData>(
  (_) => const _SummaryData(
    caloriePercent: 0.0,
    calories: 0,
    calorieTarget: 2000,
    water: 0,
  ),
);

class HealthSummaryCard extends ConsumerWidget {
  const HealthSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_summaryProvider);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's Summary",
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Calories ring
                Column(
                  children: [
                    CircularPercentIndicator(
                      radius: 45,
                      lineWidth: 8,
                      percent: data.caloriePercent.clamp(0.0, 1.0),
                      center: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${data.calories}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const Text('kcal',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 10)),
                        ],
                      ),
                      progressColor: theme.colorScheme.primary,
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 8),
                    Text('Calories', style: theme.textTheme.bodySmall),
                  ],
                ),
                _MacroBar(
                    label: 'Protein', value: 0, target: 50, color: Colors.blue),
                _MacroBar(
                    label: 'Carbs',
                    value: 0,
                    target: 250,
                    color: Colors.orange),
                _MacroBar(
                    label: 'Fat', value: 0, target: 65, color: Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final int value;
  final int target;
  final Color color;

  const _MacroBar(
      {required this.label,
      required this.value,
      required this.target,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0;
    return Column(
      children: [
        SizedBox(
          height: 70,
          width: 20,
          child: RotatedBox(
            quarterTurns: 3,
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('${value}g', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}
