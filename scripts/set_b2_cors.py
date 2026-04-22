#!/usr/bin/env python3
"""
set_b2_cors.py — Apply CORS rules to the nyingma-assets2 B2 bucket.

Run this ONCE to allow the web app (nyingmapa-real.web.app) to fetch
JSON data and images from Backblaze B2.

Usage:
    python3 scripts/set_b2_cors.py

You will be prompted for your B2 keyID and applicationKey.
These can be found in your Backblaze account → App Keys.

Requirements:
    pip install requests
"""

import json
import sys

try:
    import requests
except ImportError:
    sys.exit("requests not installed — run: pip install requests")

BUCKET_NAME = "nyingma-assets2"

CORS_RULES = [
    {
        "corsRuleName": "allow-web",
        # "*" allows any origin — safe for a public read-only CDN.
        # Replace with specific origins if you want stricter access control:
        #   "https://nyingmapa-real.web.app",
        #   "https://nyingmapa-real.firebaseapp.com"
        "allowedOrigins": ["*"],
        "allowedHeaders": ["*"],
        "allowedOperations": [
            "b2_download_file_by_name",
            "b2_download_file_by_id",
        ],
        "maxAgeSeconds": 86400,
    }
]


def main():
    print("=" * 50)
    print("  Backblaze B2 — CORS Setup")
    print(f"  Bucket: {BUCKET_NAME}")
    print("=" * 50)
    print()
    print("Paste your B2 credentials (from Backblaze → App Keys).")
    print()

    key_id  = input("keyID (starts with numbers):  ").strip()
    app_key = input("applicationKey (long string): ").strip()

    if not key_id or not app_key:
        sys.exit("❌  Both keyID and applicationKey are required.")

    # ── Step 1: Authorize ──────────────────────────────────────────────────
    print("\n🔐 Authorizing with B2 API...")
    auth_resp = requests.get(
        "https://api.backblazeb2.com/b2api/v2/b2_authorize_account",
        auth=(key_id, app_key),
    )
    if auth_resp.status_code != 200:
        print(f"❌  Authorization failed (HTTP {auth_resp.status_code}):")
        print(auth_resp.text)
        sys.exit(1)

    auth = auth_resp.json()
    api_url    = auth["apiUrl"]
    auth_token = auth["authorizationToken"]
    account_id = auth["accountId"]
    print("✅  Authorized")

    # ── Step 2: Get bucket ID ──────────────────────────────────────────────
    print(f"\n🔍 Looking up bucket '{BUCKET_NAME}'...")
    buckets_resp = requests.post(
        f"{api_url}/b2api/v2/b2_list_buckets",
        headers={"Authorization": auth_token},
        json={"accountId": account_id, "bucketName": BUCKET_NAME},
    )
    if buckets_resp.status_code != 200:
        print(f"❌  b2_list_buckets failed (HTTP {buckets_resp.status_code}):")
        print(buckets_resp.text)
        sys.exit(1)

    buckets = buckets_resp.json().get("buckets", [])
    if not buckets:
        sys.exit(f"❌  Bucket '{BUCKET_NAME}' not found. Check the name and credentials.")

    bucket_id = buckets[0]["bucketId"]
    print(f"✅  Found bucket: {bucket_id}")

    # ── Step 3: Apply CORS rules ───────────────────────────────────────────
    print("\n🌐 Applying CORS rules...")
    update_resp = requests.post(
        f"{api_url}/b2api/v2/b2_update_bucket",
        headers={"Authorization": auth_token},
        json={
            "accountId": account_id,
            "bucketId":  bucket_id,
            "corsRules": CORS_RULES,
        },
    )
    if update_resp.status_code != 200:
        print(f"❌  b2_update_bucket failed (HTTP {update_resp.status_code}):")
        print(update_resp.text)
        sys.exit(1)

    result = update_resp.json()
    applied = result.get("corsRules", [])
    print(f"✅  CORS rules applied ({len(applied)} rule(s))")
    print()
    print("Applied rules:")
    print(json.dumps(applied, indent=2))

    print()
    print("=" * 50)
    print("  Done! CORS is now configured.")
    print()
    print("  The web app at nyingmapa-real.web.app")
    print("  can now fetch JSON + images from B2.")
    print()
    print("  If the app was already deployed, just reload")
    print("  the page — no rebuild needed.")
    print("=" * 50)


if __name__ == "__main__":
    main()
