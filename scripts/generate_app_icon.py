#!/usr/bin/env python3
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "Inflamend/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
SIZE = 1024
SCALE = 3
CANVAS = SIZE * SCALE


def scaled(points):
    return [(int(x * SCALE), int(y * SCALE)) for x, y in points]


def color(hex_value):
    hex_value = hex_value.lstrip("#")
    return tuple(int(hex_value[i:i + 2], 16) for i in (0, 2, 4))


def lerp(a, b, t):
    return int(a + (b - a) * t)


def vertical_gradient(draw):
    top = color("#1d2f2a")
    bottom = color("#5e6f57")
    for y in range(CANVAS):
        t = y / max(1, CANVAS - 1)
        draw.line(
            [(0, y), (CANVAS, y)],
            fill=tuple(lerp(top[i], bottom[i], t) for i in range(3)),
        )


def rounded_rect_shadow(base, box, radius, shadow_color, blur, offset):
    shadow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shifted = (
        box[0] + offset[0],
        box[1] + offset[1],
        box[2] + offset[0],
        box[3] + offset[1],
    )
    shadow_draw.rounded_rectangle(shifted, radius=radius, fill=shadow_color)
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
    base.alpha_composite(shadow)


def draw_round_line(draw, points, fill, width):
    points = scaled(points)
    draw.line(points, fill=fill, width=width * SCALE, joint="curve")
    radius = width * SCALE // 2
    for x, y in points:
        draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=fill)


def cubic(p0, p1, p2, p3, steps=42):
    result = []
    for idx in range(steps + 1):
        t = idx / steps
        x = (
            ((1 - t) ** 3) * p0[0]
            + 3 * ((1 - t) ** 2) * t * p1[0]
            + 3 * (1 - t) * (t ** 2) * p2[0]
            + (t ** 3) * p3[0]
        )
        y = (
            ((1 - t) ** 3) * p0[1]
            + 3 * ((1 - t) ** 2) * t * p1[1]
            + 3 * (1 - t) * (t ** 2) * p2[1]
            + (t ** 3) * p3[1]
        )
        result.append((x, y))
    return result


def main():
    image = Image.new("RGBA", (CANVAS, CANVAS), color("#1d2f2a") + (255,))
    draw = ImageDraw.Draw(image)
    vertical_gradient(draw)

    # App Store icons are masked by iOS. Keep the artwork full-bleed and opaque.
    draw.ellipse(
        (int(604 * SCALE), int(-72 * SCALE), int(1118 * SCALE), int(410 * SCALE)),
        fill=color("#d8b071") + (72,),
    )
    draw.ellipse(
        (int(-112 * SCALE), int(660 * SCALE), int(366 * SCALE), int(1130 * SCALE)),
        fill=color("#a76552") + (70,),
    )

    panel = tuple(int(v * SCALE) for v in (118, 126, 906, 904))
    rounded_rect_shadow(
        image,
        panel,
        radius=176 * SCALE,
        shadow_color=(8, 20, 17, 100),
        blur=38 * SCALE,
        offset=(0, 24 * SCALE),
    )
    draw.rounded_rectangle(panel, radius=176 * SCALE, fill=color("#a8b89a") + (255,))

    inner = tuple(int(v * SCALE) for v in (172, 184, 852, 842))
    draw.rounded_rectangle(
        inner,
        radius=136 * SCALE,
        outline=color("#f2ebdd") + (120,),
        width=8 * SCALE,
    )

    shield = scaled([
        (512, 235),
        (694, 306),
        (660, 590),
        (512, 742),
        (364, 590),
        (330, 306),
    ])
    draw.polygon(shield, fill=color("#f7f0e4") + (255,))

    shield_highlight = scaled([(512, 262), (638, 316), (512, 700), (386, 316)])
    draw.polygon(shield_highlight, fill=color("#ffffff") + (72,))

    gut_left = cubic((450, 382), (342, 444), (372, 598), (505, 650))
    gut_right = cubic((558, 382), (686, 444), (656, 598), (505, 650))
    draw_round_line(draw, gut_left, color("#1f342e") + (255,), 38)
    draw_round_line(draw, gut_right, color("#1f342e") + (255,), 38)

    pulse = [(374, 535), (446, 535), (480, 488), (522, 608), (558, 535), (632, 535)]
    draw_round_line(draw, pulse, color("#a76552") + (255,), 24)

    draw.ellipse(
        tuple(int(v * SCALE) for v in (486, 338, 540, 392)),
        fill=color("#d8b071") + (255,),
    )

    final = image.resize((SIZE, SIZE), Image.Resampling.LANCZOS).convert("RGB")
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    final.save(OUTPUT, "PNG", optimize=True)
    print(f"Wrote {OUTPUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
