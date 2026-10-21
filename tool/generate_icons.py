#!/usr/bin/env python3
"""Generate the DM Tools app logo + all launcher icon sizes.

Source artwork: the Android robot logo, provided by the ticket requester
(https://upload.wikimedia.org/wikipedia/commons/thumb/d/d7/Android_robot.svg/200px-Android_robot.svg.png
— same SVG rendered at 960px, the largest Wikimedia-served size; committed at
tool/logo_source/android_robot_960.png). The Android robot is reproduced from
work created and shared by Google, used according to the Creative Commons 3.0
Attribution License.

The robot is centered on an opaque white square badge (platform icon masks
require an opaque square; the badge keeps Android and iOS consistent), and
all sizes are emitted:

  - assets/images/app_logo.png           (1024x1024 master, in-app)
  - android mipmap ic_launcher.png        (48/72/96/144/192)
  - iOS AppIcon.appiconset PNGs           (all sizes in Contents.json)

Deterministic: no randomness, no network (uses the committed source).
"""
from PIL import Image
import os

MASTER = 1024
ROBOT_HEIGHT_RATIO = 0.68          # robot height as a fraction of the badge
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(ROOT, 'tool/logo_source/android_robot_960.png')


def build_master():
    robot = Image.open(SOURCE).convert('RGBA')
    h = round(MASTER * ROBOT_HEIGHT_RATIO)
    w = round(h * robot.width / robot.height)
    robot = robot.resize((w, h), Image.LANCZOS)

    badge = Image.new('RGB', (MASTER, MASTER), (255, 255, 255))
    offset = ((MASTER - w) // 2, (MASTER - h) // 2)
    badge.paste(robot, offset, robot)   # paste with alpha as mask
    return badge


def resample(master, size, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    out = master.resize((size, size), Image.LANCZOS)
    out.save(path, 'PNG')
    print(f'wrote {path} ({size}x{size})')


def main():
    master = build_master()

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
