import 'package:flutter/material.dart';

class StabilityGauge extends StatelessWidget {
  final double psi;
  final String regime;

  const StabilityGauge({
    super.key,
    required this.psi,
    required this.regime,
  });

  Color _getRegimeColor() {
    switch (regime.toLowerCase()) {
      case 'stable':
        return Colors.green;
      case 'constrained':
        return Colors.blue;
      case 'overload':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'System Stability (Psi_s)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 150,
                  width: 150,
                  child: CircularProgressIndicator(
                    value: (psi / 2.0).clamp(0.0, 1.0),
                    strokeWidth: 12,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(_getRegimeColor()),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      psi.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      regime.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        color: _getRegimeColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Target Equilibrium: 1.00',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
