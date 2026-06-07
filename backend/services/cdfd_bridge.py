"""CDFD Runtime integration helpers for Vurafya.

The app uses the public runtime and decision surfaces directly. Neo4j graph
helpers remain optional because they live in the runtime's web visualization
layer.
"""
from __future__ import annotations

import os
import sys
from pathlib import Path
from typing import Any


DEFAULT_RUNTIME_PATH = Path(__file__).resolve().parents[3] / "CDFD-Runtime"
ENGINE_PATH = Path(os.getenv("ENGINE_PATH", str(DEFAULT_RUNTIME_PATH))).expanduser()

if ENGINE_PATH.exists() and str(ENGINE_PATH) not in sys.path:
    sys.path.append(str(ENGINE_PATH))


def _fallback_guidance(
    psi: float,
    meta: dict[str, Any] | None = None,
    domain: str = "generic",
) -> dict[str, Any]:
    meta = meta or {}
    if psi > 1.5:
        state = "critical_overload"
        actions = ["reduce_model_flux", "increase_constraint_capacity", "mark_for_review"]
        reason = f"Psi={psi:.3f} is far above the overload band (>1.5)."
    elif psi > 1.2:
        state = "overloaded"
        actions = ["reduce_model_flux", "inspect_constraint_capacity", "rerun_with_controls"]
        reason = f"Psi={psi:.3f} is above the overload threshold (1.2)."
    elif psi >= 0.8:
        state = "balanced"
        actions = ["keep_parameters", "continue_monitoring"]
        reason = f"Psi={psi:.3f} is inside the balanced band [0.8, 1.2]."
    elif psi >= 0.5:
        state = "constrained"
        actions = ["inspect_low_flux", "inspect_constraint_load", "rerun_with_controls"]
        reason = f"Psi={psi:.3f} is below the balanced band (<0.8)."
    else:
        state = "critical_constraint"
        actions = ["inspect_low_flux_state", "relax_excess_constraint", "mark_for_review"]
        reason = f"Psi={psi:.3f} is critically low (<0.5)."

    return {
        "psi": psi,
        "state": state,
        "actions": actions,
        "reason": reason,
        "domain": domain,
        "life_number": meta.get("life_number"),
    }


try:
    from runtime.decision import classify_operating_state
    from runtime.artifacts import create_run_bundle
    from runtime.diagnostics import clean_json, result_envelope
    from runtime.reporting import CLAIM_BOUNDARY, explanation_for_result
    from runtime.runner import doctor, list_domains, llm_provider_inventory, run_domain, runtime_info
    RUNTIME_SURFACES_AVAILABLE = True
    RUNTIME_SURFACES_ERROR = None
except ImportError as exc:
    clean_json = None
    create_run_bundle = None
    result_envelope = None
    CLAIM_BOUNDARY = (
        "CDFD Runtime output is deterministic modeling and review support, "
        "not clinical advice or a deployed medical decision system."
    )
    explanation_for_result = None
    doctor = None
    list_domains = None
    llm_provider_inventory = None
    run_domain = None
    runtime_info = None
    RUNTIME_SURFACES_AVAILABLE = False
    RUNTIME_SURFACES_ERROR = str(exc)

try:
    from runtime.decision import classify_operating_state
    RUNTIME_DECISION_AVAILABLE = True
except ImportError as exc:
    classify_operating_state = _fallback_guidance
    RUNTIME_DECISION_AVAILABLE = False
    RUNTIME_DECISION_ERROR = str(exc)
else:
    RUNTIME_DECISION_ERROR = None


try:
    from engine.kernel import Kernel
    from engine.state import State
    KERNEL_AVAILABLE = True
except ImportError as exc:
    Kernel = None
    State = None
    KERNEL_AVAILABLE = False
    KERNEL_ERROR = str(exc)
else:
    KERNEL_ERROR = None


try:
    from dsl.lexer import tokenize
    from dsl.parser import parse
    from dsl.executor import Executor
    DSL_AVAILABLE = True
except ImportError as exc:
    tokenize = None
    parse = None
    Executor = None
    DSL_AVAILABLE = False
    DSL_ERROR = str(exc)
else:
    DSL_ERROR = None


try:
    from ontology.actions.gateway import ActionGateway
    ACTION_GATEWAY_AVAILABLE = True
except ImportError as exc:
    ActionGateway = None
    ACTION_GATEWAY_AVAILABLE = False
    ACTION_GATEWAY_ERROR = str(exc)
else:
    ACTION_GATEWAY_ERROR = None


try:
    from webapp import neo4j_ontology as ontology
    ONTOLOGY_AVAILABLE = True
except ImportError as exc:
    ontology = None
    ONTOLOGY_AVAILABLE = False
    ONTOLOGY_ERROR = str(exc)
else:
    ONTOLOGY_ERROR = None


ENGINE_AVAILABLE = KERNEL_AVAILABLE and RUNTIME_DECISION_AVAILABLE


def runtime_status() -> dict[str, Any]:
    return {
        "engine_path": str(ENGINE_PATH),
        "kernel_available": KERNEL_AVAILABLE,
        "kernel_error": KERNEL_ERROR,
        "decision_available": RUNTIME_DECISION_AVAILABLE,
        "decision_error": RUNTIME_DECISION_ERROR,
        "runtime_surfaces_available": RUNTIME_SURFACES_AVAILABLE,
        "runtime_surfaces_error": RUNTIME_SURFACES_ERROR if not RUNTIME_SURFACES_AVAILABLE else None,
        "dsl_available": DSL_AVAILABLE,
        "dsl_error": DSL_ERROR,
        "action_gateway_available": ACTION_GATEWAY_AVAILABLE,
        "action_gateway_error": ACTION_GATEWAY_ERROR,
        "ontology_available": ONTOLOGY_AVAILABLE,
        "ontology_error": ONTOLOGY_ERROR,
    }
