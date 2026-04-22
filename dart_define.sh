#!/bin/bash
# ── Nyingmapa Calendar — Local env (KHÔNG commit file này lên git) ────────────
# Cách dùng:
#   source dart_define.sh
#   flutter_run -d chrome        ← chạy trên Chrome
#   flutter_run -d macos         ← chạy trên macOS
#   flutter_build_apk --release  ← build Android

_SUPABASE_URL="https://lpijnxliqmnocleemcqh.supabase.co"
_SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxwaWpueGxpcW1ub2NsZWVtY3FoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3ODg2MTUsImV4cCI6MjA5MjM2NDYxNX0.OKotaYAlAPfEMrqbmpvmDyoPF1e5a2Tq9QE7InMPejI"

flutter_run() {
  flutter run \
    --dart-define=SUPABASE_URL="$_SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$_SUPABASE_ANON_KEY" \
    "$@"
}

flutter_build_apk() {
  flutter build apk \
    --dart-define=SUPABASE_URL="$_SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$_SUPABASE_ANON_KEY" \
    "$@"
}

flutter_build_bundle() {
  flutter build appbundle \
    --dart-define=SUPABASE_URL="$_SUPABASE_URL" \
    --dart-define=SUPABASE_ANON_KEY="$_SUPABASE_ANON_KEY" \
    "$@"
}

echo "✅ Loaded. Dùng: flutter_run -d chrome"
