#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "pillow",
#     "pyyaml",
# ]
# ///
"""Generate light and dark theme logo variants for Flutter apps."""

import argparse
import logging
import shutil
import sys
from pathlib import Path
from typing import Any, cast

import yaml
from PIL import Image

logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)


def load_pubspec(pubspec_path: Path) -> dict:
    """Load and parse pubspec.yaml file."""
    try:
        with pubspec_path.open('r', encoding='utf-8') as f:
            return yaml.safe_load(f)
    except Exception as e:
        logger.error(f"Failed to read {pubspec_path}: {e}")
        sys.exit(1)


def calculate_average_brightness(img: Image.Image) -> float:
    """Calculate average perceived brightness of non-transparent pixels."""
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    total_brightness = 0.0
    pixel_count = 0

    pixels_raw = img.load()
    assert pixels_raw is not None
    pixels: Any = pixels_raw
    width, height = img.size

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            # Only consider non-transparent pixels
            if a > 0:
                # Rec. 709 coefficients for perceived brightness
                brightness = 0.2126 * r + 0.7152 * g + 0.0722 * b
                total_brightness += brightness
                pixel_count += 1

    if pixel_count > 0:
        return total_brightness / pixel_count
    else:
        return 128.0  # Default to mid-brightness


def invert_logo_colors(img: Image.Image) -> Image.Image:
    """Invert RGB colors while preserving alpha channel."""
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    inverted = Image.new('RGBA', img.size)
    pixels_raw = img.load()
    inverted_pixels_raw = inverted.load()
    assert pixels_raw is not None and inverted_pixels_raw is not None
    pixels: Any = pixels_raw
    inverted_pixels: Any = inverted_pixels_raw
    width, height = img.size

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            inverted_pixels[x, y] = (255 - r, 255 - g, 255 - b, a)

    return inverted


def run_flutter_command(command: list[str]) -> bool:
    """Run a flutter command and return success status."""
    import subprocess

    flutter_path = shutil.which('flutter')
    if not flutter_path:
        logger.error("flutter command not found. Make sure Flutter is installed and in PATH")
        return False

    try:
        result = subprocess.run([flutter_path] + command, check=True)
        return result.returncode == 0
    except subprocess.CalledProcessError as e:
        logger.error(f"Flutter command failed with exit code {e.returncode}")
        return False


def main():
    parser = argparse.ArgumentParser(
        description='Generate light and dark theme logo variants for Flutter apps'
    )
    parser.add_argument(
        '-p', '--pubspec',
        type=Path,
        default=Path('pubspec.yaml'),
        help='Path to pubspec.yaml (default: pubspec.yaml)'
    )
    parser.add_argument(
        '-i', '--input',
        type=Path,
        help='Input logo file path (overrides pubspec config)'
    )
    parser.add_argument(
        '-o', '--output-dir',
        type=Path,
        help='Output directory for generated variants (overrides pubspec config)'
    )
    parser.add_argument(
        '--light-name',
        help='Light theme output filename'
    )
    parser.add_argument(
        '--dark-name',
        help='Dark theme output filename'
    )
    parser.add_argument(
        '--no-apply',
        action='store_true',
        help='Only generate logo variants, skip running flutter commands'
    )
    parser.add_argument(
        '--skip-icons',
        action='store_true',
        help='Skip running flutter_launcher_icons'
    )
    parser.add_argument(
        '--skip-splash',
        action='store_true',
        help='Skip running flutter_native_splash'
    )
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='Enable verbose logging'
    )

    args = parser.parse_args()

    if args.verbose:
        logger.setLevel(logging.DEBUG)

    # Read pubspec.yaml for configuration
    pubspec = load_pubspec(args.pubspec)
    logo_config = pubspec.get('webfly', {}).get('logo', {})

    # Determine input and output paths
    input_path = args.input or Path(logo_config.get('source', 'assets/logo/webfly_logo.png'))

    if args.output_dir:
        light_output = args.output_dir / (args.light_name or 'webfly_logo_light.png')
        dark_output = args.output_dir / (args.dark_name or 'webfly_logo_dark.png')
    else:
        light_output = Path(logo_config.get('light_variant', 'assets/logo/webfly_logo_light.png'))
        dark_output = Path(logo_config.get('dark_variant', 'assets/logo/webfly_logo_dark.png'))

    logger.debug(f"Reading logo from: {input_path}")

    # Load input image
    try:
        img = Image.open(input_path)
    except Exception as e:
        logger.error(f"Failed to open {input_path}: {e}")
        sys.exit(1)

    # Analyze logo brightness
    avg_brightness = calculate_average_brightness(img)
    is_dark_logo = avg_brightness < 128.0

    logger.debug(f"Logo brightness: {avg_brightness:.1f} ({'dark logo' if is_dark_logo else 'light logo'})")

    # Generate variants
    # Create output directories if needed
    light_output.parent.mkdir(parents=True, exist_ok=True)
    dark_output.parent.mkdir(parents=True, exist_ok=True)

    try:
        if is_dark_logo:
            # Original is dark, use as-is for light theme
            img.save(light_output)
            # Invert for dark theme
            dark_img = invert_logo_colors(img)
            dark_img.save(dark_output)
        else:
            # Original is light, invert for light theme
            light_img = invert_logo_colors(img)
            light_img.save(light_output)
            # Use as-is for dark theme
            img.save(dark_output)

        logger.info("Generated logo variants: light and dark")
    except Exception as e:
        logger.error(f"Failed to save logo variants: {e}")
        sys.exit(1)

    if args.no_apply:
        logger.debug("Skipping flutter commands (--no-apply)")
        return

    # Run flutter commands
    if not args.skip_icons:
        logger.info("Running flutter_launcher_icons...")
        if not run_flutter_command(['pub', 'run', 'flutter_launcher_icons']):
            sys.exit(1)

    if not args.skip_splash:
        logger.info("Running flutter_native_splash...")
        if not run_flutter_command(['pub', 'run', 'flutter_native_splash:create']):
            sys.exit(1)

    logger.info("Done")


if __name__ == '__main__':
    main()
