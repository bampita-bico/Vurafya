"""The health release must not expose unimplemented economy features."""

from backend.main import app


def test_economy_routes_are_not_shipped():
    # Some supported FastAPI/Starlette versions retain included-router
    # bookkeeping entries alongside concrete routes. Only concrete routes have
    # a path and are part of the externally reachable release surface.
    paths = {route.path for route in app.routes if hasattr(route, "path")}
    for prefix in ("/api/v1/barter", "/api/v1/labor", "/api/v1/payments", "/api/v1/flutterwave"):
        assert not any(path.startswith(prefix) for path in paths)
