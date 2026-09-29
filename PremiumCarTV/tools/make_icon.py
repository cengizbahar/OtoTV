"""OtoTV marka görsellerini üretir: uygulama ikonu, Android uyarlanır ikon
ön planı ve açılış ekranı işareti.

Tasarım: gece siyahı zemin üzerinde şampanya altını bir direksiyon simidi;
göbeği oynat (▶) üçgeni. Kenar yumuşatma için 4x çizilip küçültülür.

Kullanım:  python tools/make_icon.py
"""
import math
import os

from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "branding")
SS = 4  # süper örnekleme katsayısı
SIZE = 1024

GOLD_LIGHT = (243, 221, 174)
GOLD = (217, 178, 111)
GOLD_DEEP = (156, 117, 53)
BG_CENTER = (40, 31, 16)
BG_EDGE = (9, 9, 11)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def gold_gradient(size):
    """Sol üstten sağ alta üç duraklı altın degrade."""
    small = 256
    img = Image.new("RGB", (small, small))
    px = img.load()
    for y in range(small):
        for x in range(small):
            t = (x + y) / (2 * (small - 1))
            px[x, y] = lerp(GOLD_LIGHT, GOLD, t / 0.5) if t < 0.5 else lerp(GOLD, GOLD_DEEP, (t - 0.5) / 0.5)
    return img.resize((size, size), Image.BICUBIC)


def radial_background(size):
    small = 256
    img = Image.new("RGB", (small, small))
    px = img.load()
    c = small / 2
    for y in range(small):
        for x in range(small):
            d = math.hypot(x - c, (y - c * 0.8)) / (small * 0.72)
            px[x, y] = lerp(BG_CENTER, BG_EDGE, min(1.0, d))
    return img.resize((size, size), Image.BICUBIC)


def mark_mask(size, scale):
    """Direksiyon + oynat işaretinin maskesi. scale: işaretin tuvale oranı."""
    m = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(m)
    c = size / 2
    r_out = size * scale / 2
    ring = r_out * 0.16

    # Simit
    d.ellipse([c - r_out, c - r_out, c + r_out, c + r_out], fill=255)
    r_in = r_out - ring
    d.ellipse([c - r_in, c - r_in, c + r_in, c + r_in], fill=0)

    # Göbek boşluğu için daire; üç kol simitten göbeğe iner.
    hub = r_out * 0.40
    spoke = ring * 0.85
    for angle in (180, 0, 90):  # sol, sağ, alt
        a = math.radians(angle)
        x1, y1 = c + math.cos(a) * (r_in + ring * 0.2), c + math.sin(a) * (r_in + ring * 0.2)
        x0, y0 = c + math.cos(a) * hub * 0.9, c + math.sin(a) * hub * 0.9
        d.line([(x0, y0), (x1, y1)], fill=255, width=int(spoke))

    # Göbek: altın disk, içinde oyulmuş oynat üçgeni.
    d.ellipse([c - hub, c - hub, c + hub, c + hub], fill=255)
    t = hub * 0.62
    # Üçgenin görsel merkezi için hafif sağa kaydır.
    ox = t * 0.18
    tri = [(c - t * 0.62 + ox, c - t), (c - t * 0.62 + ox, c + t), (c + t * 0.95 + ox, c)]
    d.polygon(tri, fill=0)
    return m


def render(scale, with_background, glow=True):
    big = SIZE * SS
    canvas = radial_background(big).convert("RGBA") if with_background else Image.new("RGBA", (big, big), (0, 0, 0, 0))
    mask = mark_mask(big, scale)

    if glow:
        halo = mask.filter(ImageFilter.GaussianBlur(big * 0.035))
        glow_layer = Image.new("RGBA", (big, big), GOLD + (0,))
        glow_layer.putalpha(halo.point(lambda v: int(v * 0.45)))
        canvas = Image.alpha_composite(canvas, glow_layer)

    gold = gold_gradient(big).convert("RGBA")
    gold.putalpha(mask)
    canvas = Image.alpha_composite(canvas, gold)
    return canvas.resize((SIZE, SIZE), Image.LANCZOS)


def main():
    os.makedirs(OUT, exist_ok=True)
    # iOS / genel ikon: saydamlık yok, işaret tuvalin %62'si.
    render(0.62, with_background=True).convert("RGB").save(os.path.join(OUT, "icon.png"))
    # Android uyarlanır ikon ön planı: güvenli bölge (%66) içinde kalmalı.
    render(0.54, with_background=False).save(os.path.join(OUT, "icon_foreground.png"))
    # Açılış ekranı işareti (Android 12 dairesel maske dahil).
    render(0.50, with_background=False, glow=False).save(os.path.join(OUT, "splash.png"))
    # Android bildirim (durum çubuğu) ikonu: beyaz silüet, saydam zemin.
    res = os.path.join(os.path.dirname(__file__), "..", "android", "app", "src", "main", "res")
    for density, px in {"mdpi": 24, "hdpi": 36, "xhdpi": 48, "xxhdpi": 72, "xxxhdpi": 96}.items():
        big = px * 8
        mask = mark_mask(big, 0.92).resize((px, px), Image.LANCZOS)
        icon = Image.new("RGBA", (px, px), (255, 255, 255, 0))
        icon.putalpha(mask)
        folder = os.path.join(res, f"drawable-{density}")
        os.makedirs(folder, exist_ok=True)
        icon.save(os.path.join(folder, "ic_stat_ototv.png"))
    print("OK ->", os.path.abspath(OUT))


if __name__ == "__main__":
    main()
