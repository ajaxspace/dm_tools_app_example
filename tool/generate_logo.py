#!/usr/bin/env python3
"""Generate the DM Tools app logo + all launcher icon sizes.

Draws a flat white gear on a vertical indigo gradient badge (matching the
app's `Colors.indigo` seed color) at 4x supersampling, then emits:
  - assets/images/app_logo.png           (1024x1024 master)
  - android mipmap ic_launcher.png        (48/72/96/144/192)
  - iOS AppIcon.appiconset PNGs           (all sizes in Contents.json)

Deterministic: no randomness, no network.
"""
from PIL import Image, ImageDraw
import math
import os

SS = 4                     # supersampling factor
MASTER = 1024
S = MASTER * SS            # working canvas size
CENTER = S / 2

INDIGO_TOP = (0x30, 0x3F, 0x9F)
INDIGO_BOTTOM = (0x79, 0x86, 0xCB)
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def make_gradient(size):
    col = Image.new('RGB', (1, size))
    for y in range(size):
        col.putpixel((0, y), lerp(INDIGO_TOP, INDIGO_BOTTOM, y / (size - 1)))
    return col.resize((size, size))


def make_glyph(size):
    """White gear glyph (with cut-outs) as an 'L' mode mask."""
    layer = Image.new('L', (size, size), 0)
    d = ImageDraw.Draw(layer)
    cx = cy = size / 2

    body_r = 0.300 * size      # gear body radius
    tooth_in = 0.265 * size    # teeth inner radius
    tooth_out = 0.360 * size   # teeth outer radius
    n_teeth = 8

    # Teeth: trapezoids with arc-rounded outer edge, sampled finely.
    for i in range(n_teeth):
        ang = 2 * math.pi * i / n_teeth
        half_w_in = math.pi / n_teeth * 0.62   # angular half-width at base
        half_w_out = math.pi / n_teeth * 0.38  # narrower at tip
        pts = []
        a0 = ang - half_w_in
        a1 = ang - half_w_out
        a2 = ang + half_w_out
        a3 = ang + half_w_in
        steps = 12
        for k in range(steps + 1):   # outer arc, tip side
            a = a1 + (a2 - a1) * k / steps
            pts.append((cx + tooth_out * math.cos(a),
                        cy + tooth_out * math.sin(a)))
        pts.append((cx + tooth_in * math.cos(a3), cy + tooth_in * math.sin(a3)))
        for k in range(steps + 1):   # base arc back
            a = a3 - (a3 - a0) * k / steps
            pts.append((cx + tooth_in * math.cos(a),
                        cy + tooth_in * math.sin(a)))
        d.polygon(pts, fill=255)

    # Gear body.
    d.ellipse([cx - body_r, cy - body_r, cx + body_r, cy + body_r], fill=255)

    # Center hole: punched through (classic gear silhouette).
    hole_r = 0.170 * size
    d.ellipse([cx - hole_r, cy - hole_r, cx + hole_r, cy + hole_r], fill=0)
    return layer


def resample(master, size, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    out = master.resize((size, size), Image.LANCZOS)
    out.save(path, 'PNG')
    print(f'wrote {path} ({size}x{size})')


def main():
    master = make_gradient(S).convert('RGB')
    glyph = make_glyph(S)
    white = Image.new('RGB', (S, S), (255, 255, 255))
    master.paste(white, (0, 0), glyph)
    master = master.resize((MASTER, MASTER), Image.LANCZOS)

    resample(master, MASTER, os.path.join(ROOT, 'assets/images/app_logo.png'))

    android = [
        ('mipmap-mdpi', 48), ('mipmap-hdpi', 72), ('mipmap-xhdpi', 96),
        ('mipmap-xxhdpi', 144), ('mipmap-xxxhdpi', 192),
    ]
    for density, size in android:
        resample(master, size, os.path.join(
            ROOT, f'android/app/src/main/res/{density}/ic_launcher.png'))

    ios_sizes = [
        ('Icon-App-20x20@1x', 20), ('Icon-App-20x20@2x', 40),
        ('Icon-App-20x20@3x', 60), ('Icon-App-29x29@1x', 29),
        ('Icon-App-29x29@2x', 58), ('Icon-App-29x29@3x', 87),
        ('Icon-App-40x40@1x', 40), ('Icon-App-40x40@2x', 80),
        ('Icon-App-40x40@3x', 120), ('Icon-App-60x60@2x', 120),
        ('Icon-App-60x60@3x', 180), ('Icon-App-76x76@1x', 76),
        ('Icon-App-76x76@2x', 152), ('Icon-App-83.5x83.5@2x', 167),
        ('Icon-App-1024x1024@1x', 1024),
    ]
    for name, size in ios_sizes:
        resample(master, size, os.path.join(
            ROOT, f'ios/Runner/Assets.xcassets/AppIcon.appiconset/{name}.png'))


if __name__ == '__main__':
    main()
