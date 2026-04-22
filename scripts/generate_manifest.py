#!/usr/bin/env python3
"""
Nyingmapa Calendar — Manifest Generator
Hashes all files in data/ and produces manifest.json for CDN cache invalidation.

Usage:
  python3 generate_manifest.py
  python3 generate_manifest.py --data-dir ./data --output manifest.json
  python3 generate_manifest.py --bump-version 2026.2.0
"""

import json
import hashlib
import argparse
import re
from pathlib import Path
from datetime import datetime, timezone


# ─────────────────────────────────────────────
# Hashing
# ─────────────────────────────────────────────

def sha256_short(path: Path) -> str:
    """Return first 8 chars of SHA-256 hex digest of a file."""
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()[:8]


# ─────────────────────────────────────────────
# Version helpers
# ─────────────────────────────────────────────

def load_existing_manifest(path: Path) -> dict:
    if path.exists():
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    return {}


def auto_bump_version(current: str) -> str:
    """
    Bump the patch number of a version string like '2026.1.3' → '2026.1.4'.
    If no current version, start at '2026.1.0'.
    """
    if not current:
        return f"{datetime.now().year}.1.0"
    parts = current.split(".")
    if len(parts) == 3:
        try:
            parts[2] = str(int(parts[2]) + 1)
            return ".".join(parts)
        except ValueError:
            pass
    return current


def detect_changes(old_files: dict, new_files: dict) -> list:
    """Return list of file keys that changed or are new."""
    changed = []
    for key, info in new_files.items():
        if key not in old_files or old_files[key]["hash"] != info["hash"]:
            changed.append(key)
    return changed


# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Generate manifest.json for Nyingmapa CDN")
    parser.add_argument("--data-dir",       default=None, help="Path to data/ directory")
    parser.add_argument("--output",         default=None, help="Output manifest.json path")
    parser.add_argument("--bump-version",   default=None, help="Override version string e.g. 2026.2.0")
    parser.add_argument("--min-app-version",default="1.0.0", help="Minimum app version required")
    args = parser.parse_args()

    script_dir = Path(__file__).parent
    data_dir   = Path(args.data_dir) if args.data_dir else script_dir / ".." / "assets" / "data"
    out_path   = Path(args.output)   if args.output   else script_dir / ".." / "b2_upload" / "manifest.json"

    if not data_dir.exists():
        print(f"❌ data directory not found: {data_dir}")
        print("   Run excel_to_json.py first.")
        raise SystemExit(1)

    # Load existing manifest for change detection
    existing = load_existing_manifest(out_path)
    old_version = existing.get("data_version", "")
    old_files   = existing.get("files", {})

    # Build file inventory
    print(f"\n🔍 Scanning {data_dir} ...")
    new_files = {}
    for path in sorted(data_dir.rglob("*.json")):
        rel_key = "data/" + path.relative_to(data_dir).as_posix()
        new_files[rel_key] = {
            "hash":       sha256_short(path),
            "size_bytes": path.stat().st_size,
            "updated_at": datetime.fromtimestamp(
                path.stat().st_mtime, tz=timezone.utc
            ).strftime("%Y-%m-%dT%H:%M:%SZ"),
        }

    # Detect changes
    changed = detect_changes(old_files, new_files)

    # Determine version
    if args.bump_version:
        version = args.bump_version
    elif changed:
        version = auto_bump_version(old_version)
    else:
        version = old_version or auto_bump_version("")

    # Build manifest
    manifest = {
        "schema_version":   1,
        "data_version":     version,
        "released_at":      datetime.now(tz=timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "min_app_version":  args.min_app_version,
        "stats": {
            "total_files":    len(new_files),
            "changed_files":  len(changed),
            "total_size_kb":  round(sum(v["size_bytes"] for v in new_files.values()) / 1024, 1),
        },
        "files": new_files,
    }

    # Write
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, separators=(",", ":"))

    # Report
    size_kb = out_path.stat().st_size / 1024
    print(f"\n{'─'*50}")
    print(f"✅ manifest.json written ({size_kb:.1f} KB)")
    print(f"   version:       {old_version or '(new)'} → {version}")
    print(f"   files tracked: {len(new_files)}")
    print(f"   changed:       {len(changed)}")
    if changed:
        print(f"\n   Changed files:")
        for f in sorted(changed):
            print(f"     • {f}")
    else:
        print(f"\n   ✅ No files changed since last manifest.")
    print(f"{'─'*50}\n")


if __name__ == "__main__":
    main()
