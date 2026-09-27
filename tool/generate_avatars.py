#!/usr/bin/env python3
"""مولّد الصور الرمزية المضمّنة — لا يحتاج أي مكتبة خارجية.

يُنشئ أقراصًا ملوّنة بتدرّج ناعم بألوان هوية «لمّتنا».
استبدلها بأي رسومات احترافية لاحقًا بنفس الأسماء.

Usage: python3 tool/generate_avatars.py
"""
import math
import os
import struct
import zlib

SIZE = 256
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "avatars")

# key -> (inner colour, outer colour)
PALETTE = {
    "coffee":   ((0xA5, 0x7A, 0x5A), (0x6F, 0x4E, 0x37)),
    "lion":     ((0xF0, 0xC0, 0x64), (0xC8, 0x8A, 0x22)),
    "falcon":   ((0x7E, 0x93, 0xA8), (0x3D, 0x52, 0x6B)),
    "camel":    ((0xE2, 0xC2, 0x96), (0xB2, 0x8A, 0x54)),
    "star":     ((0xF3, 0xD7, 0x7E), (0xD9, 0xA4, 0x41)),
    "moon":     ((0xC9, 0xD6, 0xE8), (0x5A, 0x6C, 0x8C)),
    "palm":     ((0x6F, 0xB8, 0x8C), (0x1F, 0x6F, 0x5B)),
    "jambiya":  ((0xD6, 0xA3, 0x6B), (0x8A, 0x5A, 0x2B)),
    "lantern":  ((0xF2, 0x9E, 0x6B), (0xB5, 0x4A, 0x2A)),
    "mountain": ((0x9A, 0xAE, 0xBB), (0x4E, 0x62, 0x70)),
    "sea":      ((0x6E, 0xC6, 0xD6), (0x1F, 0x6F, 0x8C)),
    "book":     ((0xC9, 0xA8, 0xE0), (0x6A, 0x4A, 0x8C)),
}


def blend(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def make_png(path, inner, outer):
    radius = SIZE / 2 - 2
    centre = SIZE / 2
    rows = []
    for y in range(SIZE):
        row = bytearray()
        for x in range(SIZE):
            dx, dy = x - centre + 0.5, y - centre + 0.5
            dist = math.hypot(dx, dy)
            if dist > radius:
                row += bytes((0, 0, 0, 0))          # transparent outside
                continue
            t = min(1.0, dist / radius)
            r, g, b = blend(inner, outer, t ** 1.4)
            # soft ring near the edge
            if radius - dist < 6:
                r, g, b = blend((r, g, b), (255, 255, 255), 0.25)
            alpha = 255 if radius - dist > 1 else int(255 * max(0.0, radius - dist))
            row += bytes((r, g, b, alpha))
        rows.append(bytes(row))

    raw = b"".join(b"\x00" + r for r in rows)

    def chunk(tag, data):
        return (struct.pack(">I", len(data)) + tag + data
                + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF))

    png = (b"\x89PNG\r\n\x1a\n"
           + chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 6, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(raw, 9))
           + chunk(b"IEND", b""))
    with open(path, "wb") as fh:
        fh.write(png)


def main():
    os.makedirs(OUT, exist_ok=True)
    for key, (inner, outer) in PALETTE.items():
        make_png(os.path.join(OUT, f"{key}.png"), inner, outer)
        print("wrote", key + ".png")


if __name__ == "__main__":
    main()
