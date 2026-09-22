"""CDFD Runtime integration helpers for Vurafya.

Aligned with the slim CDFD Runtime (v1.1.1+): kernel, decision, CDFL, doctor,
info, gallery, and optional LLM surfaces. Domain adapters and the Streamlit
webapp were removed from the public Runtime and are not imported here.
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

# Retired with the slim Runtime; kept as explicit None so API layers can 410.
list_domains = None
run_domain = None
DOMAIN_SURFACES_RETIRED = True
DOMAIN_SURFACES_MESSAGE = (
    "CDFD Runtime v1.1.1+ no longer ships domain adapters. "
    "Use CDFL validate/run, gallery, doctor, and info instead."
)


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


CLAIM_BOUNDARY = (
    "CDFD Runtime output is deterministic modeling and review support, "
    "not clinical advice or a deployed medical decision system."
)

try:
    from runtime.artifacts import create_run_bundle
    from runtime.diagnostics import clean_json, result_envelope
    from runtime.reporting import CLAIM_BOUNDARY as _RUNTIME_CLAIM_BOUNDARY
    from runtime.reporting import explanation_for_result
    from runtime.runner import doctor, gallery, llm_provider_inventory, runtime_info

    CLAIM_BOUNDARY = _RUNTIME_CLAIM_BOUNDARY
    RUNTIME_SURFACES_AVAILABLE = True
    RUNTIME_SURFACES_ERROR = None
except ImportError as exc:
    clean_json = None
    create_run_bundle = None
    result_envelope = None
    explanation_for_result = None
    doctor = None
    gallery = None
    llm_provider_inventory = None
    runtime_info = None
    RUNTIME_SURFACES_AVAILABLE = False
    RUNTIME_SURFACES_ERROR = str(exc)

try:
    from runtime.decision import classify_operating_state
    RUNTIME_DECISION_AVAILABLE = True
    RUNTIME_DECISION_ERROR = None
except ImportError as exc:
    classify_operating_state = _fallback_guidance
    RUNTIME_DECISION_AVAILABLE = False
    RUNTIME_DECISION_ERROR = str(exc)


try:
    from engine.kernel import Kernel
    from engine.state import State
    KERNEL_AVAILABLE = True
    KERNEL_ERROR = None
except ImportError as exc:
    Kernel = None
    State = None
    KERNEL_AVAILABLE = False
    KERNEL_ERROR = str(exc)


try:
    from dsl.lexer import tokenize
    from dsl.parser import parse
    from dsl.executor import Executor
    DSL_AVAILABLE = True
    DSL_ERROR = None
except ImportError as exc:
    tokenize = None
    parse = None
    Executor = None
    DSL_AVAILABLE = False
    DSL_ERROR = str(exc)


try:
    from ontology.actions.gateway import ActionGateway
    ACTION_GATEWAY_AVAILABLE = True
    ACTION_GATEWAY_ERROR = None
except ImportError as exc:
    ActionGateway = None
    ACTION_GATEWAY_AVAILABLE = False
    ACTION_GATEWAY_ERROR = str(exc)


# Neo4j helpers lived in the removed Runtime webapp; keep optional and off.
ontology = None
ONTOLOGY_AVAILABLE = False
ONTOLOGY_ERROR = "webapp/neo4j ontology surface removed from slim CDFD Runtime"


ENGINE_AVAILABLE = KERNEL_AVAILABLE and RUNTIME_DECISION_AVAILABLE


def runtime_status() -> dict[str, Any]:
    return {
        "engine_path": str(ENGINE_PATH),
        "runtime_profile": "slim_cdfl",
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
        "domain_surfaces_retired": DOMAIN_SURFACES_RETIRED,
        "domain_surfaces_message": DOMAIN_SURFACES_MESSAGE,
        "gallery_available": gallery is not None,
    }
