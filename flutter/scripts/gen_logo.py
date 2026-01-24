#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.8,<3.10"
# dependencies = [
#     "pillow",
#     "pyyaml",
#     "rembg",
#     "onnxruntime",
# ]
# ///
"""Generate light and dark theme logo variants for Flutter apps with auto background removal."""

import argparse
import logging
import shutil
import sys
from pathlib import Path
from typing import Any, cast

import yaml
from PIL import Image
from rembg import remove

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


def detect_edge_color(img: Image.Image, sample_size: int = 5) -> tuple:
    """Detect the dominant color at the edges of the image.

    Samples pixels from the four edges and returns the most common color.
    """
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    width, height = img.size
    pixels = img.load()
    edge_colors = []

    # Sample from top and bottom edges
    for x in range(0, width, max(1, width // sample_size)):
        edge_colors.append(pixels[x, 0][:3])  # Top edge
        edge_colors.append(pixels[x, height - 1][:3])  # Bottom edge

    # Sample from left and right edges
    for y in range(0, height, max(1, height // sample_size)):
        edge_colors.append(pixels[0, y][:3])  # Left edge
        edge_colors.append(pixels[width - 1, y][:3])  # Right edge

    # Find most common color
    from collections import Counter
    color_counts = Counter(edge_colors)
    return color_counts.most_common(1)[0][0]


def apply_alpha_matting(img: Image.Image) -> Image.Image:
    """Apply alpha matting to smooth edges and improve transparency quality.

    Uses a simple erosion-dilation technique to smooth alpha channel edges.
    """
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    from PIL import ImageFilter

    # Extract alpha channel
    r, g, b, a = img.split()

    # Apply slight blur to alpha channel for smoother edges
    a_smooth = a.filter(ImageFilter.GaussianBlur(radius=1))

    # Create a mask for edge detection
    # Erode then dilate to smooth edges
    a_eroded = a_smooth.filter(ImageFilter.MinFilter(3))
    a_dilated = a_eroded.filter(ImageFilter.MaxFilter(3))

    # Blend between original and smoothed alpha based on edge proximity
    pixels_orig = a.load()
    pixels_smooth = a_dilated.load()
    result_alpha = a.copy()
    result_pixels = result_alpha.load()

    width, height = a.size

    for y in range(height):
        for x in range(width):
            orig_val = pixels_orig[x, y]
            smooth_val = pixels_smooth[x, y]

            # For semi-transparent pixels (edges), use smoothed version
            if 10 < orig_val < 245:
                result_pixels[x, y] = smooth_val
            else:
                result_pixels[x, y] = orig_val

    # Recombine channels
    return Image.merge('RGBA', (r, g, b, result_alpha))


def remove_background_by_color(img: Image.Image, bg_color: tuple = None, tolerance: int = 30) -> Image.Image:
    """Remove background by detecting edge color and making similar pixels transparent."""
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    # Auto-detect background color from edges if not provided
    if bg_color is None:
        bg_color = detect_edge_color(img)
        logger.info(f"Detected edge color: RGB{bg_color}")

    pixels = img.load()
    width, height = img.size

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            # Check if pixel is similar to background color
            if (abs(r - bg_color[0]) <= tolerance and
                abs(g - bg_color[1]) <= tolerance and
                abs(b - bg_color[2]) <= tolerance):
                pixels[x, y] = (r, g, b, 0)  # Make transparent

    return img


def remove_background_hybrid(img: Image.Image, tolerance: int = 30) -> Image.Image:
    """Hybrid background removal: use rembg for region detection, color detection for cleanup.

    Steps:
    1. Use rembg to identify the logo region (subject mask)
    2. Detect background color from image edges
    3. Remove background color pixels that are outside the logo region
    """
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    # Step 1: Get logo region from rembg
    logger.info("Using AI model to detect logo region...")
    rembg_result = remove(img)

    # Step 2: Detect background color
    bg_color = detect_edge_color(img)
    logger.info(f"Detected background color: RGB{bg_color}")

    # Step 3: Combine both approaches
    # Use rembg's alpha as a guide, but also remove background color
    original_pixels = img.load()
    rembg_pixels = rembg_result.load()
    result = img.copy()
    result_pixels = result.load()

    width, height = img.size

    for y in range(height):
        for x in range(width):
            r, g, b, a = original_pixels[x, y]
            rembg_alpha = rembg_pixels[x, y][3]

            # If rembg marked as transparent, definitely make it transparent
            if rembg_alpha < 10:
                result_pixels[x, y] = (r, g, b, 0)
            # If rembg marked as opaque, check if it's background color
            elif rembg_alpha > 245:
                # Check if it's similar to background color
                if (abs(r - bg_color[0]) <= tolerance and
                    abs(g - bg_color[1]) <= tolerance and
                    abs(b - bg_color[2]) <= tolerance):
                    result_pixels[x, y] = (r, g, b, 0)
                else:
                    result_pixels[x, y] = (r, g, b, 255)
            # For semi-transparent pixels, keep rembg's alpha
            else:
                result_pixels[x, y] = (r, g, b, rembg_alpha)

    return result


def remove_background_rembg(img: Image.Image) -> Image.Image:
    """Remove background from image using rembg AI model."""
    logger.info("Removing background with AI model (rembg)...")
    return remove(img)


def adjust_brightness(img: Image.Image, factor: float) -> Image.Image:
    """Adjust brightness of non-transparent pixels.

    Args:
        img: Input image with alpha channel
        factor: Brightness adjustment factor
                > 1.0: brighten (e.g., 1.2 = 20% brighter)
                < 1.0: darken (e.g., 0.8 = 20% darker)
                = 1.0: no change
    """
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    pixels = img.load()
    width, height = img.size

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            # Only adjust visible pixels
            if a > 0:
                r = int(min(255, max(0, r * factor)))
                g = int(min(255, max(0, g * factor)))
                b = int(min(255, max(0, b * factor)))
                pixels[x, y] = (r, g, b, a)

    return img


def trim_transparent_borders(img: Image.Image, threshold: int = 10) -> Image.Image:
    """Trim transparent borders from image."""
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    # Get the alpha channel
    alpha = img.split()[-1]

    # Get bounding box of non-transparent pixels
    bbox = alpha.getbbox()

    if bbox:
        return img.crop(bbox)
    return img


def resize_image(img: Image.Image, target_size: int, padding_ratio: float = 0.15) -> Image.Image:
    """Resize image to target size while maintaining aspect ratio with padding.

    Args:
        img: Input image
        target_size: Target canvas size (e.g., 512)
        padding_ratio: Ratio of padding to target size (default: 0.15 = 15% padding)
    """
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    width, height = img.size

    # Calculate effective size after reserving padding
    padding_pixels = int(target_size * padding_ratio)
    effective_size = target_size - (padding_pixels * 2)

    # Calculate scaling to fit within effective size
    scale = min(effective_size / width, effective_size / height)
    new_width = int(width * scale)
    new_height = int(height * scale)

    # Resize with high-quality resampling
    resized = img.resize((new_width, new_height), Image.Resampling.LANCZOS)

    # Create a transparent canvas of target size
    canvas = Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))

    # Center the resized image on canvas
    x_offset = (target_size - new_width) // 2
    y_offset = (target_size - new_height) // 2
    canvas.paste(resized, (x_offset, y_offset), resized)

    return canvas


def add_background_for_theme(img: Image.Image, theme: str) -> Image.Image:
    """Add appropriate background color for light or dark theme."""
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    width, height = img.size

    # Create background with color
    if theme == 'light':
        # Light theme: white background
        bg_color = (255, 255, 255, 255)
    else:
        # Dark theme: dark background
        bg_color = (18, 18, 18, 255)

    background = Image.new('RGBA', (width, height), bg_color)
    background.paste(img, (0, 0), img)

    return background


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
        description='Generate light and dark theme logo variants for Flutter apps with auto background removal'
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
        help='Output directory for generated variants (default: assets/gen)'
    )
    parser.add_argument(
        '--target-size',
        type=int,
        default=512,
        help='Target size for logo (default: 512)'
    )
    parser.add_argument(
        '--padding',
        type=int,
        default=20,
        help='Padding around logo in pixels (default: 20)'
    )
    parser.add_argument(
        '--brightness-light',
        type=float,
        default=0.9,
        help='Brightness adjustment for light theme (default: 0.9 = slightly darker)'
    )
    parser.add_argument(
        '--brightness-dark',
        type=float,
        default=1.1,
        help='Brightness adjustment for dark theme (default: 1.1 = slightly brighter)'
    )
    parser.add_argument(
        '--use-rembg',
        action='store_true',
        help='Use rembg AI model only for background removal'
    )
    parser.add_argument(
        '--use-color-only',
        action='store_true',
        help='Use color detection only (no AI model)'
    )
    parser.add_argument(
        '--no-remove-bg',
        action='store_true',
        help='Skip background removal entirely'
    )
    parser.add_argument(
        '--bg-tolerance',
        type=int,
        default=30,
        help='Color tolerance for edge-based background removal (0-255, default: 30)'
    )
    parser.add_argument(
        '--no-trim',
        action='store_true',
        help='Skip trimming transparent borders'
    )
    parser.add_argument(
        '--no-alpha-matting',
        action='store_true',
        help='Skip alpha matting (edge smoothing)'
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
    output_dir = args.output_dir or Path(logo_config.get('output_dir', 'assets/gen'))

    # Get target size and padding from config or args
    target_size = args.target_size or logo_config.get('target_size', 512)
    padding = args.padding if args.padding is not None else logo_config.get('padding', 20)

    logger.info(f"Reading logo from: {input_path}")
    logger.info(f"Output directory: {output_dir}")
    logger.info(f"Target size: {target_size}x{target_size}")
    logger.info(f"Padding: {padding}px")

    # Load input image
    try:
        img = Image.open(input_path)
    except Exception as e:
        logger.error(f"Failed to open {input_path}: {e}")
        sys.exit(1)

    # Remove background unless skipped
    if not args.no_remove_bg:
        try:
            if args.use_rembg:
                # Use only AI model
                img = remove_background_rembg(img)
                logger.info("Background removed using AI model only")
            elif args.use_color_only:
                # Use only color detection
                img = remove_background_by_color(img, tolerance=args.bg_tolerance)
                logger.info(f"Background removed using edge detection only (tolerance: {args.bg_tolerance})")
            else:
                # Default: hybrid approach (AI region + color cleanup)
                img = remove_background_hybrid(img, tolerance=args.bg_tolerance)
                logger.info(f"Background removed using hybrid approach (AI + color, tolerance: {args.bg_tolerance})")
        except Exception as e:
            logger.warning(f"Failed to remove background: {e}")
            logger.info("Continuing with original image...")
    else:
        logger.info("Skipping background removal")

    # Trim transparent borders unless skipped
    if not args.no_trim:
        try:
            img = trim_transparent_borders(img)
            logger.info("Trimmed transparent borders")
        except Exception as e:
            logger.warning(f"Failed to trim borders: {e}")

    # Apply alpha matting unless skipped
    if not args.no_alpha_matting:
        try:
            img = apply_alpha_matting(img)
            logger.info("Applied alpha matting for smoother edges")
        except Exception as e:
            logger.warning(f"Failed to apply alpha matting: {e}")

    # Resize to target size
    try:
        img = resize_image(img, target_size, padding_ratio=padding / target_size if padding else 0.15)
        logger.info(f"Resized to {target_size}x{target_size} with padding")
    except Exception as e:
        logger.error(f"Failed to resize image: {e}")
        sys.exit(1)

    # Create output directory
    output_dir.mkdir(parents=True, exist_ok=True)

    # Generate variants
    transparent_output = output_dir / 'webfly_logo.png'
    light_output = output_dir / 'webfly_logo_light.png'
    dark_output = output_dir / 'webfly_logo_dark.png'

    try:
        # Save transparent version (neutral base)
        img.save(transparent_output)
        logger.info(f"Saved neutral transparent logo: {transparent_output}")

        # Generate light theme variant (darken for contrast on white)
        light_img = img.copy()
        if args.brightness_light != 1.0:
            light_img = adjust_brightness(light_img, args.brightness_light)
            logger.info(f"Adjusted brightness for light theme: {args.brightness_light}x")
        light_img = add_background_for_theme(light_img, 'light')
        light_img.save(light_output)
        logger.info(f"Saved light theme logo: {light_output}")

        # Generate dark theme variant (brighten for contrast on dark)
        dark_img = img.copy()
        if args.brightness_dark != 1.0:
            dark_img = adjust_brightness(dark_img, args.brightness_dark)
            logger.info(f"Adjusted brightness for dark theme: {args.brightness_dark}x")
        dark_img = add_background_for_theme(dark_img, 'dark')
        dark_img.save(dark_output)
        logger.info(f"Saved dark theme logo: {dark_output}")

    except Exception as e:
        logger.error(f"Failed to save logo variants: {e}")
        sys.exit(1)

    if args.no_apply:
        logger.info("Skipping flutter commands (--no-apply)")
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

    logger.info("Done! Generated logos in assets/gen/")


if __name__ == '__main__':
    main()
