import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ai_recommendations_provider.dart';

class AiRecommendationsCard extends ConsumerWidget {
  const AiRecommendationsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(aiRecommendationsProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, size: 18, color: Colors.amber),
            const SizedBox(width: 6),
            Text('AI Recommendations',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        async.when(
          loading: () => const _SkeletonCard(),
          error: (e, _) => _ErrorCard(message: e.toString()),
          data: (recs) {
            if (recs.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      const Expanded(
                          child: Text(
                              'All good! No alerts today. Keep it up!')),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: recs
                  .take(3)
                  .map((r) => _RecCard(rec: r, ref: ref))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _RecCard extends StatelessWidget {
  final Map<String, dynamic> rec;
  final WidgetRef ref;
  const _RecCard({required this.rec, required this.ref});

  @override
  Widget build(BuildContext context) {
    final title = rec['title']?.toString() ?? rec['action_type']?.toString().replaceAll('_', ' ').toUpperCase() ?? '';
    final message = rec['message']?.toString() ?? _parseMessage(rec['action_data']);
    final severity = rec['severity']?.toString() ?? 'info';

    final color = severity == 'critical'
        ? Colors.red
        : (severity == 'warning' ? Colors.orange : Colors.blue);

    final icon = severity == 'critical'
        ? Icons.report_problem
        : (severity == 'warning' ? Icons.warning_amber : Icons.info_outline);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  Text(message,
                      style: const TextStyle(color: Colors.black87, fontSize: 12, height: 1.4)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: () => ref
                  .read(aiRecommendationsProvider.notifier)
                  .dismiss(rec['id'] as int),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  String _parseMessage(dynamic data) {
    if (data == null) return '';
    if (data is Map) return data['message']?.toString() ?? '';
    return data.toString();
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(width: 20, height: 20, color: Colors.grey.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, color: Colors.grey.shade700),
                  const SizedBox(height: 6),
                  Container(
                      height: 10,
                      width: 200,
                      color: Colors.grey.shade700),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Could not load recommendations',
            style: TextStyle(color: Colors.grey.shade500)),
      ),
    );
  }
}
