#!/usr/bin/env python3
"""
Nyingmapa Calendar — Image Preparation Script
==============================================
Converts your source images (JPG/PNG/HEIC/WEBP) to .webp format
and places them in b2_upload/images/ ready for deployment.

Usage:
    python3 scripts/prepare_images.py --source source/images/header_images

Prerequisites:
    pip install Pillow
    (For HEIC support: pip install pillow-heif)

The script:
1. Reads all image files from --source directory
2. Normalizes filenames (lowercase, strips spaces/underscores)
3. Converts to .webp (quality 85, max 1200px wide)
4. Writes to b2_upload/images/{normalized_name}.webp

After running:
    ./scripts/deploy.sh --images    # uploads b2_upload/images/ to B2
"""

import argparse
import os
import sys
from pathlib import Path

SUPPORTED = {'.jpg', '.jpeg', '.png', '.webp', '.bmp', '.gif', '.tiff'}

try:
    from PIL import Image as PILImage
    PIL_AVAILABLE = True
except ImportError:
    PIL_AVAILABLE = False

try:
    from pillow_heif import register_heif_opener
    register_heif_opener()
    SUPPORTED.add('.heic')
    SUPPORTED.add('.heif')
except ImportError:
    pass


def normalize_name(filename: str) -> str:
    """Normalize filename: lowercase, strip spaces/underscores/hyphens, remove extension."""
    name = Path(filename).stem
    name = name.lower().strip()
    # Remove trailing underscores (common issue from previous export)
    name = name.rstrip('_')
    return name


def process_images(source_dir: Path, output_dir: Path, max_width: int = 900, quality: int = 72):
    if not PIL_AVAILABLE:
        print("❌ Pillow not installed. Run: pip install Pillow")
        sys.exit(1)

    output_dir.mkdir(parents=True, exist_ok=True)
    source_files = [f for f in source_dir.iterdir() if f.suffix.lower() in SUPPORTED]

    if not source_files:
        print(f"⚠ No supported image files found in {source_dir}")
        print(f"  Supported: {', '.join(sorted(SUPPORTED))}")
        return

    print(f"📸 Found {len(source_files)} images in {source_dir}")
    print(f"📁 Output: {output_dir}")
    print()

    skipped = []
    converted = []

    for src in sorted(source_files):
        name = normalize_name(src.name)
        dest = output_dir / f"{name}.webp"

        if dest.exists():
            skipped.append(name)
            continue

        try:
            img = PILImage.open(src)
            # Convert to RGB (webp doesn't support palette mode)
            if img.mode in ('RGBA', 'LA'):
                # Keep alpha
                img = img.convert('RGBA')
            elif img.mode != 'RGB':
                img = img.convert('RGB')

            # Resize if too wide
            if img.width > max_width:
                ratio = max_width / img.width
                new_h = int(img.height * ratio)
                img = img.resize((max_width, new_h), PILImage.LANCZOS)

            img.save(dest, 'WEBP', quality=quality, method=6)
            size_kb = dest.stat().st_size // 1024
            print(f"  ✅ {src.name} → {name}.webp ({size_kb} KB)")
            converted.append(name)
        except Exception as e:
            print(f"  ❌ {src.name}: {e}")

    print()
    print(f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print(f"  Converted: {len(converted)}")
    print(f"  Skipped (already exists): {len(skipped)}")
    print(f"  Total in output dir: {len(list(output_dir.glob('*.webp')))}")
    print(f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print()
    print("Next step: ./deploy.sh --images")


def main():
    parser = argparse.ArgumentParser(
        description='Prepare images for Nyingmapa Calendar B2 upload')
    parser.add_argument('--source', required=True,
                        help='Directory containing source images')
    parser.add_argument('--max-width', type=int, default=900,
                        help='Max image width in pixels (default: 900)')
    parser.add_argument('--quality', type=int, default=72,
                        help='WebP quality 1-100 (default: 72, ~40%% smaller than 85)')
    args = parser.parse_args()

    source = Path(args.source).expanduser().resolve()
    if not source.exists():
        print(f"❌ Source directory not found: {source}")
        sys.exit(1)

    script_dir = Path(__file__).parent
    output = script_dir / '..' / 'b2_upload' / 'images'

    process_images(source, output, args.max_width, args.quality)


if __name__ == '__main__':
    main()
