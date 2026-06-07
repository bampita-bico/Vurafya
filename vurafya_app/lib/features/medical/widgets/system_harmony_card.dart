import 'package:flutter/material.dart';

class SystemHarmonyCard extends StatelessWidget {
  final List<Map<String, dynamic>> influencePaths;

  const SystemHarmonyCard({
    super.key,
    required this.influencePaths,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.hub_outlined, color: Colors.indigo, size: 18),
                SizedBox(width: 8),
                Text(
                  'System Harmony',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'How your organ systems are influencing each other:',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ...influencePaths.map((path) => _buildPath(path)),
          ],
        ),
      ),
    );
  }

  Widget _buildPath(Map<String, dynamic> path) {
    final double strength = (path['strength'] as num? ?? 0.0).toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(path['origin'] ?? 'System A',
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13)),
              const Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
              Text(path['target'] ?? 'System B',
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: strength,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(strength > 0.8
                ? Colors.green
                : (strength > 0.5 ? Colors.orange : Colors.blue)),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }
}
