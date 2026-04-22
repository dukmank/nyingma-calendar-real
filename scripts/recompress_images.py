#!/usr/bin/env python3
"""
recompress_images.py — Re-compress all source images to new quality settings.

Deletes b2_upload/images/ and re-runs prepare_images.py with the new
lower-quality settings (quality=72, max_width=900).  Results in ~35-40%
smaller WebP files vs the old quality=85/1200px defaults.

Usage:
    python3 scripts/recompress_images.py --source source/images/header_images

Then upload:
    ./scripts/deploy.sh --images

Requirements:
    pip install Pillow
"""

import argparse
import shutil
import subprocess
import sys
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description='Re-compress images with optimised settings')
    parser.add_argument('--source', required=True, help='Source image directory (same as prepare_images.py --source)')
    parser.add_argument('--quality', type=int, default=72, help='WebP quality (default: 72)')
    parser.add_argument('--max-width', type=int, default=900, help='Max width px (default: 900)')
    parser.add_argument('--dry-run', action='store_true', help='Preview only — do not delete or convert')
    args = parser.parse_args()

    script_dir   = Path(__file__).parent
    project_dir  = script_dir.parent
    images_dir   = project_dir / 'b2_upload' / 'images'
    prepare_py   = script_dir / 'prepare_images.py'

    source = Path(args.source).expanduser().resolve()
    if not source.exists():
        sys.exit(f'❌  Source not found: {source}')

    # Count existing output images
    existing = list(images_dir.glob('*.webp')) if images_dir.exists() else []

    print('=' * 55)
    print('  Re-compress B2 images')
    print(f'  Source:    {source}')
    print(f'  Output:    {images_dir}')
    print(f'  Quality:   {args.quality}  (was 85)')
    print(f'  Max width: {args.max_width}px  (was 1200px)')
    print(f'  Existing:  {len(existing)} webp files will be deleted')
    print('=' * 55)

    if args.dry_run:
        print('\n  DRY RUN — nothing changed.\n')
        return

    # Delete existing output to force re-conversion
    if images_dir.exists():
        shutil.rmtree(images_dir)
        print(f'\n🗑  Deleted {images_dir}')

    # Re-run prepare_images.py with new settings
    cmd = [
        sys.executable, str(prepare_py),
        '--source', str(source),
        '--quality', str(args.quality),
        '--max-width', str(args.max_width),
    ]
    print(f'\n🔄  Running: {" ".join(cmd)}\n')
    result = subprocess.run(cmd)

    if result.returncode == 0:
        new_images = list(images_dir.glob('*.webp'))
        total_kb   = sum(f.stat().st_size for f in new_images) / 1024
        print(f'\n✅  Done — {len(new_images)} images, {total_kb:.0f} KB total')
        print('\nNext step:')
        print('  ./scripts/deploy.sh --images')
    else:
        sys.exit('\n❌  prepare_images.py failed — see output above.')


if __name__ == '__main__':
    main()
