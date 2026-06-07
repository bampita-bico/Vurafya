import 'dart:math';

/// Offline Edge Engine
/// A lightweight Dart port of the CDFD Universal Ontology Engine's physics.
/// Allows Vurafya to calculate clinical stability (\Psi_s) and semantic regimes
/// entirely offline when the user is in a low-connectivity environment.
class OfflineEdgeEngine {
  
  /// Evaluates a semantic node using the core physics formula: \Psi_s = (\Phi / C) * S * M_s
  Map<String, dynamic> evaluateSemanticNode(String domain, String nodeName, double phi, double c, {double s = 1.0, double ms = 1.0}) {
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
    
    return {
      "node": nodeName,
      "domain": domain,
      "psi": psiS,
      "regime": regime
    };
  }

  /// Generates the full stability metrics payload matching the backend API structure.
  /// Uses cached local biometric data to calculate the real-time offline state.
  Map<String, dynamic> calculateStability(Map<String, dynamic>? localVitals) {
    // Provide sensible defaults if local cache is empty
    final vitals = localVitals ?? {};
    
    // Renal metrics
    double egfr = (vitals['egfr_ml_min'] as num?)?.toDouble() ?? 90.0;
    double creat = (vitals['creatinine_mg_dl'] as num?)?.toDouble() ?? 1.0;
    double phiRenal = min(egfr / 100.0, 1.2);
    double cRenal = max(creat / 1.0, 0.000001);
    
    // Cardio metrics
    double pulse = (vitals['pulse_bpm'] as num?)?.toDouble() ?? 70.0;
    double sbp = (vitals['blood_pressure_systolic'] as num?)?.toDouble() ?? 120.0;
    double phiCardio = pulse > 40 ? 1.0 / (pulse / 70.0) : 0.5;
    double cCardio = sbp / 120.0;
    
    // Metabolic metrics
    double glucose = (vitals['glucose_mg_dl'] as num?)?.toDouble() ?? 100.0;
    double phiMetabolic = glucose / 100.0;
    double cMetabolic = max(glucose / 100.0, 0.8);
    
    // Evaluate nodes
    final renalEval = evaluateSemanticNode("metabolism", "renal", phiRenal, cRenal);
    final cardioEval = evaluateSemanticNode("metabolism", "cardio", phiCardio, cCardio);
    final metabolicEval = evaluateSemanticNode("metabolism", "metabolic", phiMetabolic, cMetabolic);
    
    double meanPsi = (renalEval['psi'] + cardioEval['psi'] + metabolicEval['psi']) / 3.0;
    
    String overallRegime = "stable";
    if (meanPsi > 1.2) overallRegime = "overload";
    if (meanPsi < 0.8) overallRegime = "constrained";
    
    return {
      "user_id": vitals['user_id'] ?? 0,
      "clinical_stability_score": meanPsi,
      "clinical_regime": overallRegime,
      "system_analysis": {
        "renal": {
          "score": renalEval['psi'],
          "semantic_regime": renalEval['regime']
        },
        "cardiovascular": {
          "score": cardioEval['psi'],
          "semantic_regime": cardioEval['regime']
        },
        "metabolic": {
          "score": metabolicEval['psi'],
          "semantic_regime": metabolicEval['regime']
        }
      },
      "timestamp": DateTime.now().toIso8601String(),
      "is_offline_cache": true // Flag to tell UI we are running on the Edge Engine
    };
  }

  /// Generates a quick offline trajectory using simple drift mechanics
  List<dynamic> generateOfflineTrajectory(double currentPsi, int steps) {
    List<dynamic> trajectory = [];
    double psi = currentPsi;
    
    for (int i = 0; i < steps; i++) {
      // Simulate random walk with reversion to mean if stable, or divergence if critical
      double drift = (Random().nextDouble() - 0.5) * 0.05;
      if (psi > 1.2) drift += 0.01;
      if (psi < 0.8) drift -= 0.01;
      
      psi = max(0.1, psi + drift);
      
      trajectory.add({
        "t": i,
        "psi_s": psi,
        "renal_psi": psi * 0.95,
        "cardio_psi": psi * 1.05,
        "metabolic_psi": psi,
        "regime": psi > 1.2 ? "overload" : (psi < 0.8 ? "constrained" : "stable")
      });
    }
    
    return trajectory;
  }
}
