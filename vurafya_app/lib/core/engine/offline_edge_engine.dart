import 'dart:math';

/// Offline Edge Engine
/// Local Dart predictive scoring for Vurafya (same operating-band idea as the
/// backend local adapter). Does not require CDFD Runtime connectivity.
class OfflineEdgeEngine {
  /// Evaluates a semantic node using the core physics formula: \Psi_s = (\Phi / C) * S * M_s
  Map<String, dynamic> evaluateSemanticNode(
      String domain, String nodeName, double phi, double c,
      {double s = 1.0, double ms = 1.0}) {
    // Prevent division by zero
    double safeC = max(c, 0.000001);

    double psiS = (phi / safeC) * s * ms;
    String regime;

    if (psiS < 0.8) {
      regime = "constrained";
    } else if (psiS > 1.2) {
      regime = "overload";
    } else {
      regime = "stable";
    }

    return {"node": nodeName, "domain": domain, "psi": psiS, "regime": regime};
  }

  /// Generates the full stability metrics payload matching the backend API structure.
  /// Uses cached local biometric data to calculate the real-time offline state.
  Map<String, dynamic> calculateStability(Map<String, dynamic>? localVitals) {
    if (localVitals == null || localVitals.isEmpty) {
      return {
        "clinical_stability_score": null,
        "clinical_regime": "insufficient_data",
        "system_analysis": const {},
        "data_completeness": 0.0,
        "is_offline_cache": true,
      };
    }
    final vitals = localVitals ?? {};

    final analysis = <String, dynamic>{};
    final scores = <double>[];
    final egfr = (vitals['egfr_ml_min'] as num?)?.toDouble();
    final creat = (vitals['creatinine_mg_dl'] as num?)?.toDouble();
    if (egfr != null && creat != null && egfr > 0 && creat > 0) {
      final renal =
          evaluateSemanticNode("metabolism", "renal", egfr / 100.0, creat);
      analysis['renal'] = {
        'score': renal['psi'],
        'semantic_regime': renal['regime']
      };
      scores.add(renal['psi'] as double);
    }

    final pulse = (vitals['pulse_bpm'] as num?)?.toDouble();
    final sbp = (vitals['blood_pressure_systolic'] as num?)?.toDouble();
    if (pulse != null && sbp != null && pulse > 0 && sbp > 0) {
      final cardio = evaluateSemanticNode(
        "metabolism",
        "cardio",
        pulse > 40 ? 70.0 / pulse : 0.5,
        sbp / 120.0,
      );
      analysis['cardiovascular'] = {
        'score': cardio['psi'],
        'semantic_regime': cardio['regime']
      };
      scores.add(cardio['psi'] as double);
    }

    final glucose = (vitals['glucose_mg_dl'] as num?)?.toDouble();
    if (glucose != null && glucose > 0) {
      final metabolic = evaluateSemanticNode(
        "metabolism",
        "metabolic",
        glucose / 100.0,
        max(glucose / 100.0, 0.8),
      );
      analysis['metabolic'] = {
        'score': metabolic['psi'],
        'semantic_regime': metabolic['regime']
      };
      scores.add(metabolic['psi'] as double);
    }

    final double? meanPsi = scores.isEmpty
        ? null
        : scores.reduce((left, right) => left + right) / scores.length;
    final overallRegime = meanPsi == null
        ? 'insufficient_data'
        : meanPsi > 1.2
            ? 'overload'
            : meanPsi < 0.8
                ? 'constrained'
                : 'stable';

    return {
      "user_id": vitals['user_id'] ?? 0,
      "clinical_stability_score": meanPsi,
      "clinical_regime": overallRegime,
      "system_analysis": analysis,
      "data_completeness": scores.length / 3.0,
      "timestamp": DateTime.now().toIso8601String(),
      "is_offline_cache":
          true // Flag to tell UI we are running on the Edge Engine
    };
  }

  /// Generates a quick offline trajectory using simple drift mechanics
  List<dynamic> generateOfflineTrajectory(double currentPsi, int steps) {
    List<dynamic> trajectory = [];
    double psi = currentPsi;

    for (int i = 0; i < steps; i++) {
      // Deterministic variation keeps an offline forecast reproducible for the
      // same input; it is a review aid, not a stochastic clinical simulation.
      double drift = sin((i + 1) * 1.618 + currentPsi) * 0.025;
      if (psi > 1.2) drift += 0.01;
      if (psi < 0.8) drift -= 0.01;

      // Soft pull toward the reference band, matching the backend local path.
      drift += 0.02 * (1.0 - psi);

      psi = max(0.1, psi + drift);

      trajectory.add({
        "t": i,
        "psi_s": psi,
        "renal_psi": psi * 0.95,
        "cardio_psi": psi * 1.05,
        "metabolic_psi": psi,
        "regime":
            psi > 1.2 ? "overload" : (psi < 0.8 ? "constrained" : "stable")
      });
    }

    return trajectory;
  }
}
