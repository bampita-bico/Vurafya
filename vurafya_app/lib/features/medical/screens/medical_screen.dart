import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/engine_provider.dart';

class MedicalScreen extends ConsumerWidget {
  const MedicalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stabilityAsync = ref.watch(stabilityProvider);
    final runtimeRunsAsync = ref.watch(runtimeRunsProvider);
    final runtimeDoctorAsync = ref.watch(runtimeDoctorProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Doctor Portal (Mobile)',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
              icon:
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              onPressed: () {}),
        ],
      ),
      body: stabilityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Engine Error: $e')),
        data: (data) {
          final score = (data['clinical_stability_score'] as num?)?.toDouble();
          String regime = data['clinical_regime'] ?? 'insufficient_data';
          if (score == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                    'No current biomarker data is available for a model summary.'),
              ),
            );
          }
          bool isCritical = score > 1.2 || score < 0.8;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isCritical)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.dangerous,
                            color: Colors.red, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Runtime Review',
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                  score > 1.2
                                      ? 'Overload state detected'
                                      : 'Constrained state detected',
                                  style: TextStyle(color: Colors.red.shade900)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const Text('Runtime Trajectory',
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
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Current Score',
                              style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600)),
                          Text(score.toStringAsFixed(2),
                              style: TextStyle(
                                  color: _getColor(score),
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Regime',
                              style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600)),
                          Text(regime.toUpperCase(),
                              style: TextStyle(
                                  color: _getColor(score),
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Dummy visualization for graph
                      Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                            child: Icon(Icons.show_chart,
                                color: Colors.blue, size: 40)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildEvidenceCard(data, runtimeRunsAsync, runtimeDoctorAsync),
                const SizedBox(height: 32),
                const Text('System Analysis (JGF Map)',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                const SizedBox(height: 16),
                _buildSystemCard(
                    'Renal System',
                    data['system_analysis']?['renal']?['score'] ?? 1.0,
                    data['system_analysis']?['renal']?['semantic_regime'] ??
                        'Stable',
                    Icons.water_drop),
                const SizedBox(height: 12),
                _buildSystemCard(
                    'Cardiovascular',
                    data['system_analysis']?['cardiovascular']?['score'] ?? 1.0,
                    data['system_analysis']?['cardiovascular']
                            ?['semantic_regime'] ??
                        'Stable',
                    Icons.favorite),
                const SizedBox(height: 12),
                _buildSystemCard(
                    'Metabolic',
                    data['system_analysis']?['metabolic']?['score'] ?? 1.0,
                    data['system_analysis']?['metabolic']?['semantic_regime'] ??
                        'Stable',
                    Icons.bolt),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getColor(double val) {
    if (val > 1.2) return Colors.red;
    if (val < 0.8) return Colors.blue;
    return Colors.green;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  String _artifactLabel(dynamic value) {
    if (value == null || value.toString().isEmpty) return 'Not written';
    final parts = value.toString().split('/');
    return parts.isNotEmpty ? parts.last : value.toString();
  }

  String _humanize(dynamic value) {
    if (value == null || value.toString().isEmpty) return 'Not available';
    return value.toString().replaceAll('_', ' ');
  }

  Widget _buildEvidenceCard(
    Map<String, dynamic> data,
    AsyncValue<List<Map<String, dynamic>>> runsAsync,
    AsyncValue<Map<String, dynamic>> doctorAsync,
  ) {
    final run = _asMap(data['runtime_run']);
    final summary = _asMap(run['summary']);
    final finiteAudit = _asMap(data['finite_audit'] ?? summary['finite_audit']);
    final provenance = _asMap(data['provenance']);
    final artifacts = _asMap(run['artifacts']);
    final auditPassed = finiteAudit['all_finite'] != false;
    final runUid = run['run_uid']?.toString() ?? 'Not written';
    final command = provenance['command']?.toString() ??
        summary['command']?.toString() ??
        'Local runtime';
    final persistenceError = run['persistence_error']?.toString();
    final runCount = runsAsync.when(
      data: (runs) => '${runs.length} saved',
      loading: () => 'Loading',
      error: (_, __) => 'Unavailable',
    );
    final doctorStatus = doctorAsync.when(
      data: (report) {
        final errors = report['errors'];
        final errorCount = errors is List ? errors.length : 0;
        return errorCount == 0
            ? 'Healthy'
            : '$errorCount issue${errorCount == 1 ? '' : 's'}';
      },
      loading: () => 'Checking',
      error: (_, __) => 'Unavailable',
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color:
                auditPassed ? Colors.green.shade100 : Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined,
                  color: auditPassed ? Colors.green : Colors.orange),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Runtime Evidence Bundle',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Text(
                auditPassed ? 'Finite' : 'Review',
                style: TextStyle(
                    color: auditPassed ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildEvidenceRow('Run ID', runUid),
          _buildEvidenceRow('Command', command),
          _buildEvidenceRow('Runtime doctor', doctorStatus),
          _buildEvidenceRow('Recent runs', runCount),
          const SizedBox(height: 10),
          _buildEvidenceRow('Result', _artifactLabel(artifacts['result_json'])),
          _buildEvidenceRow(
              'Manifest', _artifactLabel(artifacts['manifest_json'])),
          _buildEvidenceRow(
              'Report',
              _artifactLabel(
                  artifacts['report_markdown'] ?? artifacts['report_html'])),
          if (persistenceError != null && persistenceError.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(persistenceError,
                style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
          ],
          if (data['claim_boundary'] != null) ...[
            const SizedBox(height: 10),
            Text(_humanize(data['claim_boundary']),
                style: const TextStyle(
                    color: Colors.black54, fontSize: 12, height: 1.35)),
          ],
        ],
      ),
    );
  }

  Widget _buildEvidenceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.black54, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: const TextStyle(
                  color: Colors.black87, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemCard(
      String name, double score, String regime, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getColor(score).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _getColor(score)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text(regime, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          Text(score.toStringAsFixed(2),
              style: TextStyle(
                  color: _getColor(score),
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
        ],
      ),
    );
  }
}
