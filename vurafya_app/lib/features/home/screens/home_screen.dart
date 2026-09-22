import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/ai_recommendations_card.dart';
import '../../medical/providers/engine_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final stabilityAsync = ref.watch(stabilityProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // slate-50
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => context.go('/login'));
            return const SizedBox.shrink();
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 100,
                floating: true,
                snap: true,
                backgroundColor: Colors.white,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.indigo.shade100,
                            child: Text(
                              profile.username[0].toUpperCase(),
                              style: TextStyle(
                                  color: Colors.indigo.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Good ${_greeting()},',
                                    style: const TextStyle(
                                        color: Colors.black54, fontSize: 14)),
                                Text(profile.username,
                                    style: const TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 20)),
                              ],
                            ),
                          ),
                          const Icon(Icons.notifications_outlined,
                              color: Colors.black54, size: 28),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const Text('Your Wellness',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const SizedBox(height: 16),
                    stabilityAsync.when(
                      data: (data) {
                        bool isOffline = data['is_offline_cache'] == true;
                        final score = data['clinical_stability_score'];
                        if (score is! num) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Add current biometrics to see an operating-band summary. No health score is shown when data is unavailable.',
                            ),
                          );
                        }

                        double rawHealth = score.toDouble();
                        double healthPercent =
                            (rawHealth * 100).clamp(0, 100).toDouble();

                        final sys = data['system_analysis'] ?? {};
                        double energyPercent =
                            (((sys['metabolic']?['score'] as num?) ?? 0.0) *
                                    100)
                                .clamp(0, 100)
                                .toDouble();
                        double immunityPercent =
                            (((sys['cardiovascular']?['score'] as num?) ??
                                        0.0) *
                                    100)
                                .clamp(0, 100)
                                .toDouble();

                        return Column(
                          children: [
                            if (isOffline)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border:
                                      Border.all(color: Colors.amber.shade200),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.offline_bolt,
                                        color: Colors.amber.shade700, size: 16),
                                    const SizedBox(width: 8),
                                    Text('Offline Edge Engine',
                                        style: TextStyle(
                                            color: Colors.amber.shade800,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildProgressRing('Health', healthPercent,
                                    Colors.pink.shade400),
                                _buildProgressRing('Energy', energyPercent,
                                    Colors.amber.shade500),
                                _buildProgressRing('Immunity', immunityPercent,
                                    Colors.indigo.shade400),
                              ],
                            ),
                          ],
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, _) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 32),
                    const Text('Quick Actions',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const SizedBox(height: 16),
                    const QuickActionsGrid(),
                    const SizedBox(height: 32),
                    const Text('AI Insights',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const SizedBox(height: 16),
                    const AiRecommendationsCard(),
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressRing(String label, double percent, Color color) {
    return Column(
      children: [
        SizedBox(
          height: 80,
          width: 80,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: percent / 100,
                strokeWidth: 8,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Center(
                child: Text(
                  '${percent.toInt()}%',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 18, color: color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.black54)),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}
