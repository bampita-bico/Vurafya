#!/usr/bin/env python3
"""
E2E auth test: register → login → access protected route → refresh token.
Run with the server running: python scripts/test_auth.py
"""
import httpx
import sys
import random
import string

BASE = "http://localhost:8000/api/v1"


def rand_str(n=8):
    return "".join(random.choices(string.ascii_lowercase, k=n))


def check(label: str, condition: bool, detail: str = ""):
    mark = "✓" if condition else "✗"
    print(f"  {mark} {label}" + (f" — {detail}" if detail else ""))
    if not condition:
        sys.exit(1)


def run():
    email = f"{rand_str()}@test.com"
    username = rand_str(10)
    password = "testpass123"

    print(f"\nVurafya E2E Auth Test")
    print(f"User: {email}\n")

    # 1. Register
    print("1. Register")
    r = httpx.post(f"{BASE}/auth/register", json={"email": email, "username": username, "password": password})
    check("Status 200", r.status_code == 200, str(r.status_code))
    tokens = r.json()
    check("access_token present", "access_token" in tokens)
    check("refresh_token present", "refresh_token" in tokens)
    access = tokens["access_token"]
    refresh = tokens["refresh_token"]

    # 2. Login
    print("\n2. Login")
    r = httpx.post(f"{BASE}/auth/login", json={"email": email, "password": password})
    check("Status 200", r.status_code == 200, str(r.status_code))
    access = r.json()["access_token"]
    refresh = r.json()["refresh_token"]

    # 3. Wrong password
    print("\n3. Wrong password")
    r = httpx.post(f"{BASE}/auth/login", json={"email": email, "password": "wrongpass"})
    check("Status 401", r.status_code == 401, str(r.status_code))

    # 4. Protected route — get profile
    print("\n4. Protected route (GET /users/me)")
    r = httpx.get(f"{BASE}/users/me", headers={"Authorization": f"Bearer {access}"})
    check("Status 200", r.status_code == 200, str(r.status_code))
    profile = r.json()
    check("Username matches", profile.get("username") == username)
    check("subscription_tier present", "subscription_tier" in profile, str(profile.keys()))

    # 5. Unauthenticated request
    print("\n5. No token → 401")
    r = httpx.get(f"{BASE}/users/me")
    check("Status 401", r.status_code == 401, str(r.status_code))

    # 6. Refresh token
    print("\n6. Refresh token")
    r = httpx.post(f"{BASE}/auth/refresh", json={"refresh_token": refresh})
    check("Status 200", r.status_code == 200, str(r.status_code))
    new_access = r.json().get("access_token")
    check("New access_token issued", bool(new_access))

    # 7. New token works
    print("\n7. New token works")
    r = httpx.get(f"{BASE}/users/me", headers={"Authorization": f"Bearer {new_access}"})
    check("Status 200", r.status_code == 200, str(r.status_code))

    # 8. Health check
    print("\n8. Health endpoint")
    r = httpx.get("http://localhost:8000/health")
    check("Status 200", r.status_code == 200)
    health = r.json()
    check("DB connected", health.get("database", {}).get("connected") is True)

    print(f"\n✓ All checks passed. Backend is ready.\n")


if __name__ == "__main__":
    run()
