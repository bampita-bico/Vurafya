import React, { useCallback, useEffect, useMemo, useState } from 'react';
import axios from 'axios';
import {
  Area,
  AreaChart,
  CartesianGrid,
  Line,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import {
  Activity,
  AlertCircle,
  CheckCircle2,
  Database,
  Flame,
  Gamepad2,
  GaugeCircle,
  HeartPulse,
  Home,
  KeyRound,
  Loader2,
  LogOut,
  Moon,
  Network,
  Pill,
  RefreshCw,
  Save,
  Shield,
  Stethoscope,
  Sun,
  UserCircle,
  Waves,
  Zap,
} from 'lucide-react';
import './App.css';

const API_BASE = process.env.REACT_APP_API_URL || '/api/v1';
const HEALTH_URL = API_BASE.replace(/\/api\/v1\/?$/, '/health');
const DEMO_LOGIN_ENABLED = process.env.REACT_APP_DEMO_LOGIN_ENABLED === 'true';

const sampleStability = {
  user_id: 'demo',
  clinical_stability_score: 1.04,
  clinical_regime: 'stable',
  runtime_guidance: {
    state: 'balanced',
    reason: 'Psi=1.040 is inside the balanced band [0.8, 1.2].',
    actions: ['keep_parameters', 'continue_monitoring'],
  },
  finite_audit: { all_finite: true, non_finite_paths: [] },
  provenance: {
    runtime: 'Vurafya demo data',
    language: 'demo',
    command: 'local demo stability',
    timestamp_utc: new Date().toISOString(),
  },
  claim_boundary: 'Demo data only. Vurafya scores are review support, not clinical advice.',
  runtime_run: {
    run_uid: 'local-demo',
    summary: {
      status: 'demo',
      finite_audit: { all_finite: true, non_finite_paths: [] },
      guidance_state: 'balanced',
    },
    artifacts: {},
    persistence_error: null,
  },
  system_analysis: {
    renal: {
      score: 0.96,
      semantic_regime: 'stable',
      runtime_guidance: {
        state: 'balanced',
        actions: ['continue_monitoring'],
      },
    },
    cardiovascular: {
      score: 1.11,
      semantic_regime: 'stable',
      runtime_guidance: {
        state: 'balanced',
        actions: ['continue_monitoring'],
      },
    },
    metabolic: {
      score: 1.05,
      semantic_regime: 'stable',
      runtime_guidance: {
        state: 'balanced',
        actions: ['continue_monitoring'],
      },
    },
  },
  timestamp: new Date().toISOString(),
};

const sampleTrajectory = Array.from({ length: 50 }, (_, index) => {
  const wave = Math.sin(index / 6) * 0.055;
  return {
    t: index,
    psi_s: 1.02 + wave,
    renal_psi: 0.97 + Math.sin(index / 7) * 0.035,
    cardio_psi: 1.07 + Math.cos(index / 9) * 0.03,
    metabolic_psi: 1.03 + Math.sin(index / 5) * 0.025,
  };
});

const sampleAvatar = {
  metaverse_id: 'vurafya_export_demo',
  source_engine: 'Vurafya demo data',
  consent_granted: true,
  avatar_data: {
    character_class: 'Guardian',
    level: 14,
    biological_regime: 'STABLE',
    combat_stats: {
      hp_vitality: 940,
      mp_energy: 430,
      shield_immunity: 88,
      agility_resilience: 72,
    },
  },
};

const unavailableStability = {
  clinical_stability_score: null,
  clinical_regime: 'insufficient_data',
  runtime_guidance: {
    state: 'insufficient_data',
    reason: 'Enter a usable current measurement to generate an in-app review score.',
    actions: ['record_measurement'],
  },
  finite_audit: null,
  provenance: {},
  runtime_run: null,
  system_analysis: {},
};

const systems = [
  {
    id: 'renal',
    label: 'Renal',
    Icon: Waves,
    accent: '#0f766e',
    description: 'Filtration and constraint balance',
  },
  {
    id: 'cardiovascular',
    label: 'Cardio',
    Icon: HeartPulse,
    accent: '#be123c',
    description: 'Pulse and pressure coupling',
  },
  {
    id: 'metabolic',
    label: 'Metabolic',
    Icon: Zap,
    accent: '#b45309',
    description: 'Glucose-linked flux signal',
  },
  {
    id: 'immune',
    label: 'Immune',
    Icon: Shield,
    accent: '#4338ca',
    description: 'Avatar-linked reserve signal',
  },
];

const quickEntryDefaults = {
  glucose_mg_dl: '102',
  blood_pressure_systolic: '122',
  blood_pressure_diastolic: '78',
  pulse_bpm: '72',
  creatinine_mg_dl: '1.0',
  egfr_ml_min: '92',
};

const portalModules = [
  { id: 'wellness', label: 'Wellness', Icon: Home },
  { id: 'fuel', label: 'Fuel', Icon: Flame },
  { id: 'avatar', label: 'Avatar', Icon: Gamepad2 },
  { id: 'doctor', label: 'Doctor', Icon: Stethoscope },
  { id: 'pharmacy', label: 'Pharmacy', Icon: Pill },
  { id: 'profile', label: 'Profile', Icon: UserCircle },
];

function clampPercent(value) {
  const numeric = Number.isFinite(value) ? value : 0;
  return Math.max(0, Math.min(100, Math.round(numeric * 100)));
}

function formatScore(value, digits = 3) {
  const numeric = Number(value);
  return Number.isFinite(numeric) ? numeric.toFixed(digits) : '—';
}

function humanize(value) {
  if (!value) return 'Not available';
  return String(value).replace(/_/g, ' ');
}

function artifactLabel(value) {
  if (!value) return 'Not written';
  const parts = String(value).split('/');
  return parts[parts.length - 1] || value;
}

function getScoreTone(score) {
  if (score > 1.2) return 'overload';
  if (score < 0.8) return 'constrained';
  return 'stable';
}

function getScoreColor(score) {
  const tone = getScoreTone(score);
  if (tone === 'overload') return '#be123c';
  if (tone === 'constrained') return '#2563eb';
  return '#047857';
}

function makeAuthHeader(token) {
  return token ? { Authorization: `Bearer ${token}` } : {};
}

function normalizeTrajectory(items, stability) {
  const source = Array.isArray(items) ? items : [];
  const systemScores = stability?.system_analysis || {};

  return source.map((row, index) => ({
    t: row.t ?? row.step ?? index,
    psi_s: Number(row.psi_s ?? row.mean_psi ?? row.psi ?? stability?.clinical_stability_score),
    renal_psi: Number(row.renal_psi ?? systemScores.renal?.score),
    cardio_psi: Number(row.cardio_psi ?? systemScores.cardiovascular?.score ?? systemScores.cardio?.score),
    metabolic_psi: Number(row.metabolic_psi ?? systemScores.metabolic?.score),
  }));
}

function normalizeStability(payload) {
  if (!payload || typeof payload !== 'object') return unavailableStability;
  const envelope = payload.runtime_envelope || {};
  const score = Number(payload.clinical_stability_score ?? payload.mean_psi);
  return {
    ...payload,
    clinical_stability_score: Number.isFinite(score) ? score : null,
    clinical_regime: payload.clinical_regime || payload.overall_regime || 'insufficient_data',
    runtime_guidance: payload.runtime_guidance || unavailableStability.runtime_guidance,
    finite_audit: payload.finite_audit || envelope.finite_audit || null,
    provenance: payload.provenance || envelope.provenance || {},
    claim_boundary: payload.claim_boundary || envelope.payload?.claim_boundary,
    runtime_run: payload.runtime_run || null,
    system_analysis: payload.system_analysis || {},
  };
}

function getSystemScore(analysis, systemId) {
  if (systemId === 'cardiovascular') {
    return Number(analysis.cardiovascular?.score ?? analysis.cardio?.score);
  }
  return Number(analysis[systemId]?.score);
}

function HealthBadge({ status }) {
  const ok = status?.status === 'ok';
  const Icon = status?.loading ? Loader2 : ok ? CheckCircle2 : AlertCircle;
  return (
    <div className={`health-badge ${ok ? 'online' : 'offline'}`}>
      <Icon size={16} className={status?.loading ? 'spin' : ''} />
      <span>{status?.loading ? 'Checking API' : ok ? 'API online' : 'Demo mode'}</span>
    </div>
  );
}

function MetricCard({ icon: Icon, label, value, detail, tone = 'neutral' }) {
  return (
    <section className={`metric-card ${tone}`}>
      <div className="metric-icon">
        <Icon size={20} />
      </div>
      <div>
        <p>{label}</p>
        <strong>{value}</strong>
        {detail && <span>{detail}</span>}
      </div>
    </section>
  );
}

function AuthPanel({ token, authMode, setAuthMode, authForm, setAuthForm, onSubmit, onLogout, onDemoLogin, busy, message }) {
  const authenticated = Boolean(token);

  return (
    <section className="auth-panel" aria-label="Account access">
      <div className="panel-heading">
        <div>
          <p className="eyebrow">Account</p>
          <h2>{authenticated ? 'Session active' : authMode === 'login' ? 'Sign in' : 'Create account'}</h2>
        </div>
        <KeyRound size={20} />
      </div>

      {authenticated ? (
        <div className="session-box">
          <span>Local token saved for this browser.</span>
          <button className="text-button" type="button" onClick={onLogout}>
            <LogOut size={16} />
            Sign out
          </button>
        </div>
      ) : (
        <form className="auth-form" onSubmit={onSubmit}>
          <label>
            Email
            <input
              type="email"
              value={authForm.email}
              autoComplete="email"
              onChange={(event) => setAuthForm((current) => ({ ...current, email: event.target.value }))}
              required
            />
          </label>
          {authMode === 'register' && (
            <label>
              Username
              <input
                type="text"
                value={authForm.username}
                autoComplete="username"
                onChange={(event) => setAuthForm((current) => ({ ...current, username: event.target.value }))}
                required
              />
            </label>
          )}
          <label>
            Password
            <input
              type="password"
              value={authForm.password}
              autoComplete={authMode === 'login' ? 'current-password' : 'new-password'}
              minLength={6}
              onChange={(event) => setAuthForm((current) => ({ ...current, password: event.target.value }))}
              required
            />
          </label>
          <div className="auth-actions">
            <button className="primary-button" type="submit" disabled={busy}>
              {busy ? <Loader2 size={16} className="spin" /> : <KeyRound size={16} />}
              {authMode === 'login' ? 'Sign in' : 'Create'}
            </button>
            <button
              className="text-button"
              type="button"
              onClick={() => setAuthMode(authMode === 'login' ? 'register' : 'login')}
            >
              {authMode === 'login' ? 'Register' : 'Use sign in'}
            </button>
            {authMode === 'login' && DEMO_LOGIN_ENABLED && (
              <button className="text-button" type="button" onClick={onDemoLogin} disabled={busy}>
                Instant demo access
              </button>
            )}
          </div>
        </form>
      )}
      {message && <p className="form-message">{message}</p>}
    </section>
  );
}

function RuntimeChart({ trajectory }) {
  return (
    <section className="panel chart-panel">
      <div className="panel-heading">
        <div>
          <p className="eyebrow">Runtime</p>
          <h2>Trajectory Review</h2>
        </div>
        <Activity size={20} />
      </div>
      <div className="chart-frame">
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart data={trajectory} margin={{ top: 8, right: 16, bottom: 0, left: -18 }}>
            <defs>
              <linearGradient id="psiFill" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#2563eb" stopOpacity={0.22} />
                <stop offset="95%" stopColor="#2563eb" stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" stroke="#d7dee8" vertical={false} />
            <XAxis dataKey="t" tickLine={false} axisLine={false} tick={{ fontSize: 11 }} />
            <YAxis domain={[0.5, 1.5]} tickLine={false} axisLine={false} tick={{ fontSize: 11 }} />
            <Tooltip
              formatter={(value, name) => [formatScore(value), humanize(name)]}
              contentStyle={{ borderRadius: 8, border: '1px solid #d7dee8' }}
            />
            <Area type="monotone" dataKey="psi_s" stroke="#2563eb" strokeWidth={3} fill="url(#psiFill)" />
            <Line type="monotone" dataKey="renal_psi" stroke="#0f766e" strokeWidth={2} dot={false} />
            <Line type="monotone" dataKey="cardio_psi" stroke="#be123c" strokeWidth={2} dot={false} />
            <Line type="monotone" dataKey="metabolic_psi" stroke="#b45309" strokeWidth={2} dot={false} />
          </AreaChart>
        </ResponsiveContainer>
      </div>
    </section>
  );
}

function SystemMap({ stability }) {
  const analysis = stability.system_analysis || {};

  return (
    <section className="panel system-panel">
      <div className="panel-heading">
        <div>
          <p className="eyebrow">Systems</p>
          <h2>Coupling Map</h2>
        </div>
        <Network size={20} />
      </div>
      <div className="system-map">
        <svg viewBox="0 0 520 260" role="img" aria-label="System coupling map">
          <line x1="112" y1="130" x2="260" y2="64" />
          <line x1="112" y1="130" x2="260" y2="196" />
          <line x1="260" y1="64" x2="408" y2="130" />
          <line x1="260" y1="196" x2="408" y2="130" />
        </svg>
        {systems.map((system, index) => {
          const score = getSystemScore(analysis, system.id);
          const tone = getScoreTone(score);
          const Icon = system.Icon;
          return (
            <div key={system.id} className={`system-node node-${index} ${tone}`} style={{ '--accent': system.accent }}>
              <Icon size={20} />
              <strong>{system.label}</strong>
              <span>{formatScore(score, 2)}</span>
            </div>
          );
        })}
      </div>
    </section>
  );
}

function GuidancePanel({ stability }) {
  const guidance = stability.runtime_guidance || {};
  const actions = Array.isArray(guidance.actions) ? guidance.actions : [];

  return (
    <section className="panel guidance-panel">
      <div className="panel-heading">
        <div>
          <p className="eyebrow">Guidance</p>
          <h2>{humanize(guidance.state || stability.clinical_regime)}</h2>
        </div>
        <GaugeCircle size={20} />
      </div>
      <p className="guidance-reason">{guidance.reason || 'Runtime state available for review.'}</p>
      <div className="tag-row">
        {actions.length > 0 ? (
          actions.map((action) => <span key={action}>{humanize(action)}</span>)
        ) : (
          <span>Review current model state</span>
        )}
      </div>
    </section>
  );
}

function RuntimeEvidencePanel({ stability }) {
  const run = stability.runtime_run || {};
  const summary = run.summary || {};
  const artifacts = run.artifacts || {};
  const finiteAudit = stability.finite_audit || summary.finite_audit || {};
  const provenance = stability.provenance || {};
  const artifactRows = [
    ['Result', artifacts.result_json],
    ['Manifest', artifacts.manifest_json],
    ['Markdown', artifacts.report_markdown],
    ['HTML', artifacts.report_html],
  ];

  return (
    <section className="panel evidence-panel">
      <div className="panel-heading">
        <div>
          <p className="eyebrow">Evidence</p>
          <h2>{finiteAudit.all_finite === false ? 'Audit Review' : 'Run Bundle'}</h2>
        </div>
        <Database size={20} />
      </div>
      <div className="evidence-grid">
        <div>
          <span>Run ID</span>
          <strong title={run.run_uid || 'Not written'}>{run.run_uid || 'Not written'}</strong>
        </div>
        <div>
          <span>Finite Audit</span>
          <strong>{finiteAudit.all_finite === false ? 'Review' : 'Passed'}</strong>
        </div>
        <div>
          <span>Command</span>
          <strong title={provenance.command || summary.command || 'Local sample'}>
            {provenance.command || summary.command || 'Local sample'}
          </strong>
        </div>
      </div>
      <div className="artifact-list">
        {artifactRows.map(([label, value]) => (
          <div key={label} className="artifact-row">
            <span>{label}</span>
            <strong title={value || ''}>{artifactLabel(value)}</strong>
          </div>
        ))}
      </div>
      {run.persistence_error && <p className="evidence-warning">{run.persistence_error}</p>}
      {stability.claim_boundary && <p className="claim-boundary">{stability.claim_boundary}</p>}
    </section>
  );
}

function PatientView({ stability, trajectory }) {
  const score = Number(stability.clinical_stability_score);
  const percent = clampPercent(score);
  const hasScore = Number.isFinite(score);

  return (
    <div className="view-grid">
      <MetricCard
        icon={HeartPulse}
        label="Runtime Balance"
        value={hasScore ? `${percent}%` : '—'}
        detail={hasScore ? humanize(stability.clinical_regime) : 'Measurements needed'}
        tone={getScoreTone(score)}
      />
      <MetricCard
        icon={Shield}
        label="Model Band"
        value={hasScore ? (score >= 0.8 && score <= 1.2 ? 'Balanced' : 'Review') : 'Unavailable'}
        detail={hasScore ? `Psi_s ${formatScore(score)}` : 'No usable score'}
      />
      <MetricCard
        icon={Database}
        label="Runtime Source"
        value="Vurafya local"
        detail={stability.timestamp ? new Date(stability.timestamp).toLocaleString() : 'Runtime optional'}
      />
      <RuntimeChart trajectory={trajectory} />
      <GuidancePanel stability={stability} />
      <RuntimeEvidencePanel stability={stability} />
      <SystemMap stability={stability} />
    </div>
  );
}

function ClinicianView({ stability, trajectory, avatar, onExportAvatar, busy }) {
  const analysis = stability.system_analysis || {};
  const avatarStats = avatar?.avatar_data?.combat_stats || sampleAvatar.avatar_data.combat_stats;

  return (
    <div className="clinician-grid">
      <RuntimeChart trajectory={trajectory} />
      <section className="panel">
        <div className="panel-heading">
          <div>
            <p className="eyebrow">Review</p>
            <h2>System Scores</h2>
          </div>
          <Stethoscope size={20} />
        </div>
        <div className="score-list">
          {systems.slice(0, 3).map((system) => {
            const item = analysis[system.id] || {};
            const score = Number(item.score ?? 1);
            return (
              <div key={system.id} className="score-row">
                <span>{system.label}</span>
                <strong style={{ color: getScoreColor(score) }}>{formatScore(score)}</strong>
                <em>{humanize(item.semantic_regime || getScoreTone(score))}</em>
              </div>
            );
          })}
        </div>
      </section>
      <RuntimeEvidencePanel stability={stability} />
      <SystemMap stability={stability} />
      <section className="panel avatar-panel">
        <div className="panel-heading">
          <div>
            <p className="eyebrow">Vuralis</p>
            <h2>Avatar Export</h2>
          </div>
          <UserCircle size={20} />
        </div>
        <div className="avatar-grid">
          {[
            ['Vitality', avatarStats.hp_vitality ?? 0, HeartPulse],
            ['Energy', avatarStats.mp_energy ?? 0, Zap],
            ['Immunity', avatarStats.shield_immunity ?? 0, Shield],
            ['Resilience', avatarStats.agility_resilience ?? 0, Activity],
          ].map(([label, value, Icon]) => (
            <div className="avatar-stat" key={label}>
              <Icon size={18} />
              <span>{label}</span>
              <strong>{value}</strong>
            </div>
          ))}
        </div>
        <button className="primary-button full-width" type="button" onClick={onExportAvatar} disabled={busy}>
          {busy ? <Loader2 size={16} className="spin" /> : <RefreshCw size={16} />}
          Refresh export
        </button>
      </section>
    </div>
  );
}

function QuickEntry({ token, values, setValues, onSubmit, busy, message }) {
  return (
    <section className="panel quick-entry">
      <div className="panel-heading">
        <div>
          <p className="eyebrow">Biometrics</p>
          <h2>Quick Entry</h2>
        </div>
        <Save size={20} />
      </div>
      <form onSubmit={onSubmit}>
        <label>
          Glucose mg/dL
          <input
            type="number"
            step="0.1"
            value={values.glucose_mg_dl}
            onChange={(event) => setValues((current) => ({ ...current, glucose_mg_dl: event.target.value }))}
          />
        </label>
        <label>
          Systolic
          <input
            type="number"
            value={values.blood_pressure_systolic}
            onChange={(event) => setValues((current) => ({ ...current, blood_pressure_systolic: event.target.value }))}
          />
        </label>
        <label>
          Diastolic
          <input
            type="number"
            value={values.blood_pressure_diastolic}
            onChange={(event) => setValues((current) => ({ ...current, blood_pressure_diastolic: event.target.value }))}
          />
        </label>
        <label>
          Pulse
          <input
            type="number"
            value={values.pulse_bpm}
            onChange={(event) => setValues((current) => ({ ...current, pulse_bpm: event.target.value }))}
          />
        </label>
        <label>
          Creatinine
          <input
            type="number"
            step="0.1"
            value={values.creatinine_mg_dl}
            onChange={(event) => setValues((current) => ({ ...current, creatinine_mg_dl: event.target.value }))}
          />
        </label>
        <label>
          eGFR
          <input
            type="number"
            step="0.1"
            value={values.egfr_ml_min}
            onChange={(event) => setValues((current) => ({ ...current, egfr_ml_min: event.target.value }))}
          />
        </label>
        <button className="primary-button full-width" type="submit" disabled={!token || busy}>
          {busy ? <Loader2 size={16} className="spin" /> : <Save size={16} />}
          Save readings
        </button>
      </form>
      <p className="form-message">{token ? message || 'Saved records refresh the runtime panels.' : 'Sign in to save records.'}</p>
    </section>
  );
}

function WellnessView({ stability, recommendations, onNavigate }) {
  const score = Number(stability.clinical_stability_score ?? 1);
  const system = stability.system_analysis || {};
  const rings = [
    { label: 'Health', value: clampPercent(score), color: '#be185d' },
    { label: 'Energy', value: clampPercent(Number(system.metabolic?.score ?? 1)), color: '#b45309' },
    { label: 'Immunity', value: clampPercent(Number(system.cardiovascular?.score ?? 1)), color: '#4338ca' },
  ];

  const actions = [
    ['Log Meal', 'fuel'],
    ['Consult Doctor', 'doctor'],
    ['Pharmacy', 'pharmacy'],
    ['Avatar', 'avatar'],
  ];

  return (
    <div className="module-stack">
      <section className="panel">
        <div className="panel-heading">
          <div>
            <p className="eyebrow">Wellness</p>
            <h2>Your current state</h2>
          </div>
          <HeartPulse size={20} />
        </div>
        <div className="ring-row">
          {rings.map((ring) => (
            <div key={ring.label} className="ring-card">
              <div className="ring" style={{ '--ring-color': ring.color, '--ring-value': `${ring.value}` }}>
                <strong>{ring.value}%</strong>
              </div>
              <span>{ring.label}</span>
            </div>
          ))}
        </div>
      </section>

      <section className="panel">
        <div className="panel-heading">
          <div>
            <p className="eyebrow">Quick Actions</p>
            <h2>Mobile-aligned shortcuts</h2>
          </div>
          <Zap size={20} />
        </div>
        <div className="quick-actions-grid">
          {actions.map(([label, target]) => (
            <button key={label} type="button" className="quick-action-card" onClick={() => onNavigate(target)}>
              {label}
            </button>
          ))}
        </div>
      </section>

      <section className="panel">
        <div className="panel-heading">
          <div>
            <p className="eyebrow">AI Insights</p>
            <h2>Recommendations</h2>
          </div>
          <Activity size={20} />
        </div>
        <div className="score-list">
          {(recommendations || []).slice(0, 3).map((item, index) => (
            <div key={item.id || index} className="score-row">
              <span>{item.title || humanize(item.action_type) || `Insight ${index + 1}`}</span>
              <em>{item.message || humanize(item.severity) || 'Review suggested action'}</em>
            </div>
          ))}
          {(!recommendations || recommendations.length === 0) && (
            <div className="score-row">
              <span>No active alerts</span>
              <em>System is in monitoring mode.</em>
            </div>
          )}
        </div>
      </section>
    </div>
  );
}

function FuelView({ values }) {
  const metrics = [
    ['Protein', Number(values.creatinine_mg_dl) * 45, 60, 'g'],
    ['Potassium', Number(values.egfr_ml_min) * 13, 2000, 'mg'],
    ['Phosphorus', Number(values.glucose_mg_dl) * 6, 800, 'mg'],
  ];
  return (
    <div className="module-stack">
      <section className="panel">
        <div className="panel-heading">
          <div>
            <p className="eyebrow">Metabolic Fuel</p>
            <h2>Energy throughput</h2>
          </div>
          <Flame size={20} />
        </div>
        <p className="guidance-reason">Your fuel-resistance panel mirrors the phone app with 3Ps and acid-base balance snapshots.</p>
        <div className="score-list">
          {metrics.map(([label, current, max, unit]) => (
            <div key={label} className="score-row">
              <span>{label}</span>
              <strong>{Math.round(current)} / {max} {unit}</strong>
              <em>{Math.round((current / max) * 100)}%</em>
            </div>
          ))}
          <div className="score-row">
            <span>PRAL Score</span>
            <strong>-12.4</strong>
            <em>Alkaline and renal-protective</em>
          </div>
        </div>
      </section>
    </div>
  );
}

function SimpleListModule({ title, eyebrow, icon: Icon, items, emptyMessage }) {
  return (
    <div className="module-stack">
      <section className="panel">
        <div className="panel-heading">
          <div>
            <p className="eyebrow">{eyebrow}</p>
            <h2>{title}</h2>
          </div>
          <Icon size={20} />
        </div>
        <div className="score-list">
          {items.length > 0 ? (
            items.map((item, index) => (
              <div key={index} className="score-row">
                <span>{item.primary}</span>
                <strong>{item.secondary}</strong>
                <em>{item.tertiary}</em>
              </div>
            ))
          ) : (
            <div className="score-row">
              <span>{emptyMessage}</span>
              <em>No live records yet.</em>
            </div>
          )}
        </div>
      </section>
    </div>
  );
}

function App() {
  const [theme, setTheme] = useState(() => localStorage.getItem('vurafya-theme') || 'light');
  const [view, setView] = useState('patient');
  const [activeModule, setActiveModule] = useState('wellness');
  const [token, setToken] = useState(() => localStorage.getItem('vurafya-token') || '');
  const [authMode, setAuthMode] = useState('login');
  const [authForm, setAuthForm] = useState({ email: '', username: '', password: '' });
  const [authMessage, setAuthMessage] = useState('');
  const [status, setStatus] = useState({ loading: true });
  const [stability, setStability] = useState(DEMO_LOGIN_ENABLED ? sampleStability : unavailableStability);
  const [trajectory, setTrajectory] = useState(DEMO_LOGIN_ENABLED ? sampleTrajectory : []);
  const [avatar, setAvatar] = useState(sampleAvatar);
  const [profile, setProfile] = useState(null);
  const [recommendations, setRecommendations] = useState([]);
  const [pharmacyData, setPharmacyData] = useState({ schedules: [], orders: [] });
  const [quickEntry, setQuickEntry] = useState(quickEntryDefaults);
  const [quickEntryMessage, setQuickEntryMessage] = useState('');
  const [busy, setBusy] = useState({ auth: false, refresh: false, avatar: false, quickEntry: false });

  const api = useMemo(() => axios.create({ baseURL: API_BASE, timeout: 12000 }), []);

  useEffect(() => {
    document.documentElement.dataset.theme = theme;
    localStorage.setItem('vurafya-theme', theme);
  }, [theme]);

  const refreshHealth = useCallback(async () => {
    setStatus({ loading: true });
    try {
      const response = await axios.get(HEALTH_URL, { timeout: 5000 });
      setStatus({ status: response.data?.status || 'ok', details: response.data });
    } catch (error) {
      setStatus({ status: 'offline', error: error.message });
    }
  }, []);

  const refreshRuntime = useCallback(async () => {
    setBusy((current) => ({ ...current, refresh: true }));
    try {
      const headers = makeAuthHeader(token);
      const [stabilityResponse, trajectoryResponse] = await Promise.all([
        token
          ? api.get('/engine/stability', { headers })
          : Promise.resolve({ data: DEMO_LOGIN_ENABLED ? sampleStability : unavailableStability }),
        token
          ? api.get('/engine/trajectory?steps=50', { headers })
          : Promise.resolve({ data: { forecast: DEMO_LOGIN_ENABLED ? sampleTrajectory : [] } }),
      ]);
      const nextStability = normalizeStability(stabilityResponse.data);
      setStability(nextStability);
      setTrajectory(normalizeTrajectory(trajectoryResponse.data?.forecast, nextStability));
    } catch (error) {
      setAuthMessage(error.response?.status === 401 ? 'Session expired or token rejected.' : 'Health API unavailable; no score is shown.');
      setStability(unavailableStability);
      setTrajectory([]);
    } finally {
      setBusy((current) => ({ ...current, refresh: false }));
    }
  }, [api, token]);

  const refreshAvatar = useCallback(async () => {
    setBusy((current) => ({ ...current, avatar: true }));
    try {
      if (!token) {
        setAvatar(sampleAvatar);
        return;
      }
      const response = await api.get('/vuralis/export-avatar', { headers: makeAuthHeader(token) });
      setAvatar(response.data || sampleAvatar);
    } catch (error) {
      setAvatar(sampleAvatar);
    } finally {
      setBusy((current) => ({ ...current, avatar: false }));
    }
  }, [api, token]);

  const refreshPortalData = useCallback(async () => {
    if (!token) {
      setProfile(null);
      setRecommendations([]);
      setPharmacyData({ schedules: [], orders: [] });
      return;
    }
    const headers = makeAuthHeader(token);
    try {
      const [profileRes, recsRes, schedulesRes, ordersRes] = await Promise.all([
        api.get('/users/me', { headers }),
        api.get('/recommendations', { headers }),
        api.get('/pharmacy/schedules', { headers }),
        api.get('/pharmacy/orders', { headers }),
      ]);
      setProfile(profileRes.data || null);
      setRecommendations(recsRes.data?.recommendations || []);
      setPharmacyData({
        schedules: schedulesRes.data?.schedules || [],
        orders: ordersRes.data?.orders || [],
      });
    } catch (error) {
      if (error.response?.status === 401) {
        setAuthMessage('Session expired. Sign in again.');
      }
    }
  }, [api, token]);

  useEffect(() => {
    refreshHealth();
  }, [refreshHealth]);

  useEffect(() => {
    refreshRuntime();
    refreshAvatar();
    refreshPortalData();
  }, [refreshRuntime, refreshAvatar, refreshPortalData]);

  async function handleAuthSubmit(event) {
    event.preventDefault();
    setBusy((current) => ({ ...current, auth: true }));
    setAuthMessage('');
    try {
      const path = authMode === 'login' ? '/auth/login' : '/auth/register';
      const payload =
        authMode === 'login'
          ? { email: authForm.email, password: authForm.password }
          : { email: authForm.email, username: authForm.username, password: authForm.password };
      const response = await api.post(path, payload);
      const nextToken = response.data?.access_token;
      if (!nextToken) throw new Error('No access token returned.');
      localStorage.setItem('vurafya-token', nextToken);
      setToken(nextToken);
      setAuthMessage('Signed in.');
      setActiveModule('wellness');
      await Promise.all([refreshRuntime(), refreshAvatar(), refreshPortalData()]);
    } catch (error) {
      setAuthMessage(error.response?.data?.detail || error.message || 'Account request failed.');
    } finally {
      setBusy((current) => ({ ...current, auth: false }));
    }
  }

  async function handleDemoLogin() {
    setBusy((current) => ({ ...current, auth: true }));
    setAuthMessage('');
    try {
      const response = await api.post('/auth/demo-login');
      const nextToken = response.data?.access_token;
      if (!nextToken) throw new Error('No access token returned.');
      localStorage.setItem('vurafya-token', nextToken);
      setToken(nextToken);
      setAuthMessage('Demo session ready.');
      setActiveModule('wellness');
      await Promise.all([refreshRuntime(), refreshAvatar(), refreshPortalData()]);
    } catch (error) {
      setAuthMessage(error.response?.data?.detail || error.message || 'Demo login failed.');
    } finally {
      setBusy((current) => ({ ...current, auth: false }));
    }
  }

  async function handleLogout() {
    const headers = makeAuthHeader(token);
    try {
      if (token) await api.post('/auth/logout', {}, { headers });
    } catch (_error) {
      // Local credential clearing is still required if the network is unavailable.
    }
    localStorage.removeItem('vurafya-token');
    setToken('');
    setAuthMessage('Signed out.');
    setStability(DEMO_LOGIN_ENABLED ? sampleStability : unavailableStability);
    setTrajectory(DEMO_LOGIN_ENABLED ? sampleTrajectory : []);
    setAvatar(sampleAvatar);
    setProfile(null);
    setRecommendations([]);
  }

  async function handleQuickEntrySubmit(event) {
    event.preventDefault();
    if (!token) return;
    setBusy((current) => ({ ...current, quickEntry: true }));
    setQuickEntryMessage('');
    const headers = makeAuthHeader(token);
    try {
      await Promise.all([
        api.post(
          '/biometrics/glucose',
          { glucose_mg_dl: Number(quickEntry.glucose_mg_dl), measurement_context: 'routine' },
          { headers },
        ),
        api.post(
          '/biometrics/vitals',
          {
            blood_pressure_systolic: Number(quickEntry.blood_pressure_systolic),
            blood_pressure_diastolic: Number(quickEntry.blood_pressure_diastolic),
            pulse_bpm: Number(quickEntry.pulse_bpm),
            measured_by: 'self',
          },
          { headers },
        ),
        api.post(
          '/biometrics/ckd/creatinine',
          {
            creatinine_mg_dl: Number(quickEntry.creatinine_mg_dl),
            egfr_ml_min: Number(quickEntry.egfr_ml_min),
            measurement_context: 'routine',
          },
          { headers },
        ),
      ]);
      setQuickEntryMessage('Readings saved.');
      await Promise.all([refreshRuntime(), refreshPortalData()]);
    } catch (error) {
      setQuickEntryMessage(error.response?.data?.detail || 'Readings were not saved.');
    } finally {
      setBusy((current) => ({ ...current, quickEntry: false }));
    }
  }

  const overallScore = Number(stability.clinical_stability_score);
  const hasOverallScore = Number.isFinite(overallScore);

  return (
    <div className="app-shell">
      <aside className="sidebar">
        <div className="brand">
          <HeartPulse size={28} />
          <div>
            <strong>Vurafya</strong>
            <span>Health review portal</span>
          </div>
        </div>

        <nav className="view-switcher" aria-label="Modules">
          {portalModules.map((module) => {
            const Icon = module.Icon;
            return (
              <button
                key={module.id}
                className={activeModule === module.id ? 'active' : ''}
                type="button"
                onClick={() => setActiveModule(module.id)}
              >
                <Icon size={18} />
                {module.label}
              </button>
            );
          })}
        </nav>

        <AuthPanel
          token={token}
          authMode={authMode}
          setAuthMode={setAuthMode}
          authForm={authForm}
          setAuthForm={setAuthForm}
          onSubmit={handleAuthSubmit}
          onLogout={handleLogout}
          onDemoLogin={handleDemoLogin}
          busy={busy.auth}
          message={authMessage}
        />

        <QuickEntry
          token={token}
          values={quickEntry}
          setValues={setQuickEntry}
          onSubmit={handleQuickEntrySubmit}
          busy={busy.quickEntry}
          message={quickEntryMessage}
        />
      </aside>

      <main className="main">
        <header className="topbar">
          <div>
            <p className="eyebrow">Runtime Surface</p>
            <h1>{portalModules.find((item) => item.id === activeModule)?.label || 'Health Dashboard'}</h1>
            <span className="clinical-note">Modeling surface only. Clinical decisions stay with licensed care teams.</span>
          </div>
          <div className="topbar-actions">
            <HealthBadge status={status} />
            <button className="icon-button" type="button" onClick={refreshRuntime} aria-label="Refresh runtime">
              {busy.refresh ? <Loader2 size={18} className="spin" /> : <RefreshCw size={18} />}
            </button>
            <button
              className="icon-button"
              type="button"
              onClick={() => setTheme(theme === 'light' ? 'dark' : 'light')}
              aria-label="Toggle theme"
            >
              {theme === 'light' ? <Moon size={18} /> : <Sun size={18} />}
            </button>
          </div>
        </header>

        {(activeModule === 'doctor' || activeModule === 'wellness') && (
          <section className="metric-strip">
            <MetricCard
              icon={GaugeCircle}
              label="Psi_s"
              value={formatScore(overallScore)}
              detail={hasOverallScore ? humanize(stability.clinical_regime) : 'Measurements needed'}
              tone={getScoreTone(overallScore)}
            />
            <MetricCard
              icon={Activity}
              label="Band"
              value={hasOverallScore ? (overallScore >= 0.8 && overallScore <= 1.2 ? 'Balanced' : 'Review') : 'Unavailable'}
              detail="0.8 to 1.2 reference"
            />
            <MetricCard
              icon={Network}
              label="Systems"
              value={`${stability.available_domains?.length || 0} live`}
              detail="renal, cardio, metabolic"
            />
          </section>
        )}

        {activeModule === 'wellness' && (
          <WellnessView stability={stability} recommendations={recommendations} onNavigate={setActiveModule} />
        )}

        {activeModule === 'fuel' && <FuelView values={quickEntry} />}

        {activeModule === 'avatar' && (
          <ClinicianView
            stability={stability}
            trajectory={trajectory}
            avatar={avatar}
            onExportAvatar={refreshAvatar}
            busy={busy.avatar}
          />
        )}

        {activeModule === 'doctor' && (
          <>
            <section className="sub-switcher">
              <button className={view === 'patient' ? 'active' : ''} type="button" onClick={() => setView('patient')}>
                <UserCircle size={16} /> Patient
              </button>
              <button className={view === 'clinician' ? 'active' : ''} type="button" onClick={() => setView('clinician')}>
                <Stethoscope size={16} /> Clinician
              </button>
            </section>
            {view === 'patient' ? (
              <PatientView stability={stability} trajectory={trajectory} />
            ) : (
              <ClinicianView
                stability={stability}
                trajectory={trajectory}
                avatar={avatar}
                onExportAvatar={refreshAvatar}
                busy={busy.avatar}
              />
            )}
          </>
        )}

        {activeModule === 'pharmacy' && (
          <SimpleListModule
            eyebrow="Pharmacy"
            title="Schedules and orders"
            icon={Pill}
            items={[
              ...pharmacyData.schedules.slice(0, 3).map((row) => ({
                primary: row.medication_name || `Medication #${row.medication_id || 'N/A'}`,
                secondary: row.status || 'active',
                tertiary: (row.scheduled_times || []).join(', ') || 'No schedule time',
              })),
              ...pharmacyData.orders.slice(0, 2).map((row) => ({
                primary: row.order_number || `Order #${row.id || 'N/A'}`,
                secondary: row.order_status || 'pending',
                tertiary: row.created_at ? new Date(row.created_at).toLocaleDateString() : 'Recent order',
              })),
            ]}
            emptyMessage="No pharmacy entries yet"
          />
        )}

        {activeModule === 'profile' && (
          <SimpleListModule
            eyebrow="Profile"
            title={profile?.username ? `${profile.username} account` : 'Account overview'}
            icon={UserCircle}
            items={[
              { primary: 'Email', secondary: profile?.email || 'Not available', tertiary: 'Primary login identity' },
              {
                primary: 'Subscription',
                secondary: profile?.subscription_tier || 'free',
                tertiary: profile?.subscription_status || 'active',
              },
              {
                primary: 'Last login',
                secondary: profile?.last_login ? new Date(profile.last_login).toLocaleString() : 'Not available',
                tertiary: 'Session history',
              },
            ]}
            emptyMessage="Sign in to see profile data"
          />
        )}
      </main>
    </div>
  );
}

export default App;
