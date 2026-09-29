#!/usr/bin/env python3
"""
Gera o favicon e os ícones do app web (frontend/web) com a sacola do logo do OpenBag.

A sacola é o ícone `shopping_bag_rounded` da fonte Material Icons (Apache 2.0), a mesma do `OpenBagLogo`,
branca sobre o verde da marca (`OpenBagLogo.brandGreen`).

Uso:
  python3 tools/brand/generate_web_icons.py [--font caminho/MaterialIcons-Regular.otf]

Sem --font, a fonte é procurada no cache do Flutter (bin/cache/artifacts/material_fonts).
Requer: pip install pillow
"""
import argparse
import json
import subprocess
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
WEB = ROOT / "frontend" / "web"
BRAND_GREEN = (0x2F, 0xB5, 0x4A, 255)
WHITE = (255, 255, 255, 255)
SHOPPING_BAG_ROUNDED = chr(0xF016F)


def find_font() -> Path:
    out = subprocess.run(["flutter", "--version", "--machine"], capture_output=True, text=True, check=True).stdout
    root = Path(json.loads(out)["flutterRoot"])
    return root / "bin" / "cache" / "artifacts" / "material_fonts" / "MaterialIcons-Regular.otf"


def icon(font_path: Path, size: int, *, maskable: bool) -> Image.Image:
    """Quadrado arredondado verde com a sacola branca; o maskable ocupa tudo e deixa a sacola na zona segura"""
    scale = 4  # desenha maior e reduz, para bordas suaves
    s = size * scale
    image = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    if maskable:
        draw.rectangle((0, 0, s, s), fill=BRAND_GREEN)
        glyph_size = int(s * 0.5)
    else:
        draw.rounded_rectangle((0, 0, s - 1, s - 1), radius=int(s * 0.22), fill=BRAND_GREEN)
        glyph_size = int(s * 0.7)

    font = ImageFont.truetype(str(font_path), glyph_size)
    left, top, right, bottom = draw.textbbox((0, 0), SHOPPING_BAG_ROUNDED, font=font)
    x = (s - (right - left)) / 2 - left
    y = (s - (bottom - top)) / 2 - top
    draw.text((x, y), SHOPPING_BAG_ROUNDED, font=font, fill=WHITE)
    return image.resize((size, size), Image.LANCZOS)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--font", type=Path)
    args = parser.parse_args()
    font = args.font or find_font()

    icons = WEB / "icons"
    icons.mkdir(parents=True, exist_ok=True)
    outputs = {
        WEB / "favicon.png": icon(font, 64, maskable=False),
        icons / "Icon-192.png": icon(font, 192, maskable=False),
        icons / "Icon-512.png": icon(font, 512, maskable=False),
        icons / "Icon-maskable-192.png": icon(font, 192, maskable=True),
        icons / "Icon-maskable-512.png": icon(font, 512, maskable=True),
    }
    for path, image in outputs.items():
        image.save(path, optimize=True)
        print(f"{path.relative_to(ROOT)} ({image.width}x{image.height})")


if __name__ == "__main__":
    main()
