#!/usr/bin/env python3
"""Generate branding images with WebFly text."""

from PIL import Image, ImageDraw, ImageFont
from pathlib import Path

def create_branding_image(text: str, output_path: Path, text_color: tuple, width: int = 300, height: int = 60):
    """Create a simple branding image with text."""
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Try to use a system font, fallback to default
    try:
        font = ImageFont.truetype("arial.ttf", 32)
    except:
        try:
            font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 32)
        except:
            font = ImageFont.load_default()
    
    # Get text size and center it
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    x = (width - text_width) // 2
    y = (height - text_height) // 2
    
    draw.text((x, y), text, fill=text_color, font=font)
    
    img.save(output_path)
    print(f"Created: {output_path}")

if __name__ == '__main__':
    output_dir = Path(__file__).parent.parent / 'assets' / 'gen'
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Light theme: dark text
    create_branding_image('WebFly', output_dir / 'webfly_branding_light.png', (50, 50, 50, 255))
    
    # Dark theme: light text
    create_branding_image('WebFly', output_dir / 'webfly_branding_dark.png', (220, 220, 220, 255))
