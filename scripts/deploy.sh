#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# Nyingmapa Calendar — Deploy to Backblaze B2
#
# Uploads assets/data/ + manifest.json to B2 bucket via rclone.
# Images in b2_upload/images/ are synced separately (optional).
#
# Prerequisites:
#   brew install rclone         (macOS)
#   rclone config               (run once to set up B2 remote)
#
# Usage (run from scripts/ or project root):
#   ./scripts/deploy.sh                         # data only
#   ./scripts/deploy.sh --images                # data + images
#   ./scripts/deploy.sh --dry-run               # preview only, no upload
#   ./scripts/deploy.sh --bump-version 2026.2.0 # set specific version
# ─────────────────────────────────────────────────────────────

set -euo pipefail

# ── Config — edit these ──────────────────────────────────────
RCLONE_REMOTE="b2"                     # rclone remote name (from rclone config)
B2_BUCKET="nyingma-assets2"            # B2 bucket (must match cdnBaseUrl in app_constants.dart)
B2_ACCOUNT_ID="K005+QMZNaGN6WcBCBkIkilfvIQIJU0"                       # Backblaze keyID  — leave blank to skip CORS update
B2_APP_KEY="0057796b6ab98bc0000000003"                          # Backblaze applicationKey — leave blank to skip CORS update
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/.."
DATA_DIR="$PROJECT_DIR/assets/data"       # Flutter-bundled data — single source of truth
IMAGES_DIR="$PROJECT_DIR/b2_upload/images"  # processed .webp images (run prepare_images.py first)
MANIFEST="$PROJECT_DIR/b2_upload/manifest.json"
# ─────────────────────────────────────────────────────────────

# Parse args
DRY_RUN=""
INCLUDE_IMAGES=false
BUMP_VERSION=""

for arg in "$@"; do
  case $arg in
    --dry-run)          DRY_RUN="--dry-run" ;;
    --images)           INCLUDE_IMAGES=true ;;
    --bump-version=*)   BUMP_VERSION="${arg#*=}" ;;
    --bump-version)     shift; BUMP_VERSION="$1" ;;
  esac
done

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Nyingmapa Calendar — Deploy"
echo "  Target: ${RCLONE_REMOTE}:${B2_BUCKET}"
[[ -n "$DRY_RUN" ]] && echo -e "  ${YELLOW}⚠ DRY RUN — no files will be uploaded${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Step 1: Check dependencies ──────────────────────────────
if ! command -v rclone &>/dev/null; then
  echo -e "${RED}❌ rclone not found. Install: brew install rclone${NC}"
  exit 1
fi

if ! command -v python3 &>/dev/null; then
  echo -e "${RED}❌ python3 not found.${NC}"
  exit 1
fi

# ── Step 2: Set B2 CORS rules ────────────────────────────────
# Allows the web app (Firebase Hosting) to fetch JSON + images from B2.
# Idempotent — safe to run on every deploy.
# Skip if credentials are not set in config above.
if [[ -n "$B2_ACCOUNT_ID" && -n "$B2_APP_KEY" ]]; then
  echo "🌐 Updating B2 CORS rules..."
  # "*" allows any origin — safe for a public read-only CDN.
  # This is the simplest setting and avoids localhost port-matching issues.
  CORS_RULES='[{"corsRuleName":"allow-web","allowedOrigins":["*"],"allowedHeaders":["*"],"allowedOperations":["b2_download_file_by_name","b2_download_file_by_id"],"maxAgeSeconds":86400}]'

  # Use B2 CLI if available, otherwise fall back to curl + B2 API
  # Note: some b2 CLI versions fail on macOS (missing clang++) — catch error and fall through to curl.
  if command -v b2 &>/dev/null && b2 update-bucket --corsRules "$CORS_RULES" "$B2_BUCKET" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ CORS rules updated via b2 CLI${NC}"
  else
    # Authenticate via B2 API
    AUTH=$(curl -s -u "${B2_ACCOUNT_ID}:${B2_APP_KEY}" \
      "https://api.backblazeb2.com/b2api/v2/b2_authorize_account")
    API_URL=$(echo "$AUTH" | python3 -c "import sys,json; print(json.load(sys.stdin)['apiUrl'])")
    AUTH_TOKEN=$(echo "$AUTH" | python3 -c "import sys,json; print(json.load(sys.stdin)['authorizationToken'])")
    ACCOUNT_ID=$(echo "$AUTH" | python3 -c "import sys,json; print(json.load(sys.stdin)['accountId'])")

    # Get bucket ID
    BUCKET_ID=$(curl -s -H "Authorization: $AUTH_TOKEN" \
      "${API_URL}/b2api/v2/b2_list_buckets" \
      --data-urlencode "accountId=${ACCOUNT_ID}" \
      --data-urlencode "bucketName=${B2_BUCKET}" \
      -G \
      | python3 -c "import sys,json; print(json.load(sys.stdin)['buckets'][0]['bucketId'])")

    # Update CORS — quote "$CORS_RULES" to preserve JSON string correctly
    curl -s -X POST \
      -H "Authorization: $AUTH_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"accountId\":\"${ACCOUNT_ID}\",\"bucketId\":\"${BUCKET_ID}\",\"corsRules\":${CORS_RULES}}" \
      "${API_URL}/b2api/v2/b2_update_bucket" > /dev/null
    echo -e "${GREEN}✅ CORS rules updated via B2 API${NC}"
  fi
else
  echo -e "${YELLOW}⚠ CORS update skipped (B2_ACCOUNT_ID/B2_APP_KEY not set in deploy.sh)${NC}"
fi

# ── Step 3: Check data directory ────────────────────────────
if [[ ! -d "$DATA_DIR" ]]; then
  echo -e "${RED}❌ assets/data/ not found. Run excel_to_json.py first.${NC}"
  exit 1
fi

# ── Step 4: Generate manifest ────────────────────────────────
echo ""
echo "📋 Generating manifest..."
VERSION_FLAG=""
[[ -n "$BUMP_VERSION" ]] && VERSION_FLAG="--bump-version $BUMP_VERSION"

mkdir -p "$(dirname "$MANIFEST")"
python3 "$SCRIPT_DIR/generate_manifest.py" \
  --data-dir "$DATA_DIR" \
  --output "$MANIFEST" \
  $VERSION_FLAG

# ── Step 5: Upload data/ ─────────────────────────────────────
echo "📤 Uploading data/..."
rclone sync "$DATA_DIR" "${RCLONE_REMOTE}:${B2_BUCKET}/data" \
  --checksum \
  --transfers 8 \
  --b2-chunk-size 96M \
  --stats 5s \
  --stats-one-line \
  $DRY_RUN

echo -e "${GREEN}✅ data/ synced${NC}"

# ── Step 6: Upload manifest.json ─────────────────────────────
echo "📤 Uploading manifest.json..."
rclone copy "$MANIFEST" "${RCLONE_REMOTE}:${B2_BUCKET}/data" \
  --no-check-dest \
  $DRY_RUN

echo -e "${GREEN}✅ manifest.json uploaded${NC}"

# ── Step 7: Upload images/ (optional) ───────────────────────
if [[ "$INCLUDE_IMAGES" == true ]]; then
  if [[ ! -d "$IMAGES_DIR" ]]; then
    echo -e "${YELLOW}⚠ b2_upload/images/ not found. Run: python3 scripts/prepare_images.py --source source/images/...${NC}"
  else
    echo "🖼  Uploading images/..."
    # Images are uploaded FLAT to bucket root (no subfolder) to match:
    # AppConstants.imageUrl(key) → https://...bucket/{key}.webp
    rclone sync "$IMAGES_DIR" "${RCLONE_REMOTE}:${B2_BUCKET}" \
      --checksum \
      --transfers 8 \
      --b2-chunk-size 96M \
      --exclude "*.DS_Store" \
      --exclude "Thumbs.db" \
      --stats 5s \
      --stats-one-line \
      $DRY_RUN
    echo -e "${GREEN}✅ images/ synced${NC}"
  fi
fi

# ── Done ─────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ -n "$DRY_RUN" ]]; then
  echo -e "  ${YELLOW}DRY RUN complete — nothing was uploaded${NC}"
else
  echo -e "  ${GREEN}✅ Deploy complete!${NC}"
  DATA_VERSION=$(python3 -c "import json; print(json.load(open('$MANIFEST'))['data_version'])")
  echo "  data_version: $DATA_VERSION"
  echo "  CDN: https://f005.backblazeb2.com/file/nyingma-assets2"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
