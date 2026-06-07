import 'package:flutter/foundation.dart';

import 'lib/core/engine/offline_edge_engine.dart';

void main() {
  debugPrint("--- Testing Vurafya Offline Edge Engine (Dart) ---");

  final engine = OfflineEdgeEngine();

  final healthyVitals = {
    "user_id": 1,
    "egfr_ml_min": 100.0,
    "creatinine_mg_dl": 0.8,
    "pulse_bpm": 65.0,
    "blood_pressure_systolic": 115.0,
    "glucose_mg_dl": 90.0
  };

  debugPrint("\n1. Calculating stability for healthy local cache:");
  final healthyStats = engine.calculateStability(healthyVitals);
  debugPrint("Overall Regime: ${healthyStats['clinical_regime']}");
  debugPrint("Mean Psi_s: ${healthyStats['clinical_stability_score']}");
  debugPrint("Is Offline Cache? ${healthyStats['is_offline_cache']}");

  final ckdVitals = {
    "user_id": 2,
    "egfr_ml_min": 15.0,
    "creatinine_mg_dl": 5.5,
    "pulse_bpm": 90.0,
    "blood_pressure_systolic": 150.0,
    "glucose_mg_dl": 110.0
  };

  debugPrint("\n2. Calculating stability for constrained (CKD) local cache:");
  final ckdStats = engine.calculateStability(ckdVitals);
  debugPrint("Overall Regime: ${ckdStats['clinical_regime']}");
  debugPrint("Mean Psi_s: ${ckdStats['clinical_stability_score']}");
  debugPrint("Renal Psi_s: ${ckdStats['system_analysis']['renal']['score']}");
  debugPrint(
      "Renal Regime: ${ckdStats['system_analysis']['renal']['semantic_regime']}");

  debugPrint("\n3. Generating Offline Trajectory (5 steps) from CKD state:");
  final trajectory =
      engine.generateOfflineTrajectory(ckdStats['clinical_stability_score'], 5);
  for (var step in trajectory) {
    debugPrint(
        "t=${step['t']} -> Psi_s: ${step['psi_s']}, Regime: ${step['regime']}");
  }
}
