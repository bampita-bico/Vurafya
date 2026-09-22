import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../medical/providers/engine_provider.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stabilityAsync = ref.watch(stabilityProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // slate-900
      appBar: AppBar(
        title: const Text('Avatar Status',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // Animated Avatar Portrait
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  height: 160,
                  width: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade400, Colors.purple.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purpleAccent
                            .withValues(alpha: 0.5 * _pulseAnimation.value),
                        blurRadius: 30 * _pulseAnimation.value,
                        spreadRadius: 8 * _pulseAnimation.value,
                      ),
                    ],
                  ),
                  child:
                      const Icon(Icons.person, size: 90, color: Colors.white),
                );
              },
            ),
            const SizedBox(height: 24),

            const Text('Level 14',
                style: TextStyle(
                    color: Colors.amber,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0)),
            const SizedBox(height: 4),
            const Text('Cyber Knight',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('Class: Guardian • Guild: Vanguard',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ),

            const SizedBox(height: 40),

            // RPG stats linked to the CDFD Runtime summary.
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B), // slate-800
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.indigo.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.amber, size: 24),
                      SizedBox(width: 8),
                      Text('DYNAMIC STATS',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  stabilityAsync.when(
                    data: (data) {
                      bool isOffline = data['is_offline_cache'] == true;
                      final rawScore = data['clinical_stability_score'];
                      if (rawScore is! num) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                              'Add biometrics to unlock health-mapped avatar stats.'),
                        );
                      }

                      double rawHealth = rawScore.toDouble();
                      final sys = data['system_analysis'] ?? {};
                      double energyScore =
                          (sys['metabolic']?['score'] as num? ?? 0.0)
                              .toDouble();
                      double immunityScore =
                          (sys['cardiovascular']?['score'] as num? ?? 0.0)
                              .toDouble();

                      double hp = (rawHealth * 1000).clamp(0, 1000).toDouble();
                      double mp = (energyScore * 500).clamp(0, 500).toDouble();
                      double shield =
                          (immunityScore * 100).clamp(0, 100).toDouble();
                      double agility = 85.0;

                      return Column(
                        children: [
                          if (isOffline)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: Text('⚡ Offline Edge Engine Active',
                                  style: TextStyle(
                                      color: Colors.amber,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                          _AnimatedStatRow(
                              label: 'HP (Vitality)',
                              current: hp,
                              maxVal: 1000,
                              color: Colors.redAccent,
                              icon: Icons.favorite),
                          const SizedBox(height: 16),
                          _AnimatedStatRow(
                              label: 'MP (Energy)',
                              current: mp,
                              maxVal: 500,
                              color: Colors.blueAccent,
                              icon: Icons.bolt),
                          const SizedBox(height: 16),
                          _AnimatedStatRow(
                              label: 'Shield (Immunity)',
                              current: shield,
                              maxVal: 100,
                              color: Colors.indigoAccent,
                              icon: Icons.shield),
                          const SizedBox(height: 16),
                          _AnimatedStatRow(
                              label: 'Agility (Resilience)',
                              current: agility,
                              maxVal: 100,
                              color: Colors.tealAccent,
                              icon: Icons.directions_run),
                        ],
                      );
                    },
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: Colors.indigoAccent)),
                    error: (err, _) => const Text('Failed to load stats',
                        style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedStatRow extends StatefulWidget {
  final String label;
  final double current;
  final double maxVal;
  final Color color;
  final IconData icon;

  const _AnimatedStatRow({
    required this.label,
    required this.current,
    required this.maxVal,
    required this.color,
    required this.icon,
  });

  @override
  State<_AnimatedStatRow> createState() => _AnimatedStatRowState();
}

class _AnimatedStatRowState extends State<_AnimatedStatRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _animation = Tween<double>(begin: 0, end: widget.current / widget.maxVal)
        .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));
    _controller.forward();
  }

  @override
  void didUpdateWidget(_AnimatedStatRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current ||
        oldWidget.maxVal != widget.maxVal) {
      _animation = Tween<double>(
              begin: _animation.value, end: widget.current / widget.maxVal)
          .animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(widget.icon, color: widget.color, size: 20),
                      const SizedBox(width: 12),
                      Text(widget.label,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white70)),
                    ],
                  ),
                  Text(
                      '${(widget.maxVal * _animation.value).toInt()} / ${widget.maxVal.toInt()}',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: widget.color)),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(6)),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _animation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                            color: widget.color.withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 1)
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        });
  }
}
