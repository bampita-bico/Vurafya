"""The health release must not expose unimplemented economy features."""

from backend.main import app


def test_economy_routes_are_not_shipped():
    paths = {route.path for route in app.routes}
    for prefix in ("/api/v1/barter", "/api/v1/labor", "/api/v1/payments", "/api/v1/flutterwave"):
        assert not any(path.startswith(prefix) for path in paths)
