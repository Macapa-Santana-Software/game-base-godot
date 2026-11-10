"""Mini biblioteca de pixel art (so stdlib) usada pelos geradores de arte da Fase 2."""
import zlib, struct, random, math

def H(h, a=255):
    h = h.lstrip('#')
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)

def mix(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(4))

class Img:
    def __init__(s, w, h, fill=(0, 0, 0, 0)):
        s.w, s.h = w, h
        s.p = [fill] * (w * h)

    def get(s, x, y, wrap=False):
        if wrap:
            x %= s.w; y %= s.h
        elif not (0 <= x < s.w and 0 <= y < s.h):
            return (0, 0, 0, 0)
        return s.p[y * s.w + x]

    def put(s, x, y, c, wrap=False):
        x = int(x); y = int(y)
        if wrap:
            x %= s.w; y %= s.h
        elif not (0 <= x < s.w and 0 <= y < s.h):
            return
        a = c[3]
        if a == 255:
            s.p[y * s.w + x] = c
        elif a > 0:
            d = s.p[y * s.w + x]
            if d[3] == 0:
                s.p[y * s.w + x] = c
            else:
                t = a / 255.0
                oa = min(255, int(d[3] + a * (1 - d[3] / 255.0)))
                s.p[y * s.w + x] = (int(d[0] + (c[0] - d[0]) * t), int(d[1] + (c[1] - d[1]) * t),
                                    int(d[2] + (c[2] - d[2]) * t), oa)

    def rect(s, x, y, w, h, c, wrap=False):
        for j in range(h):
            for i in range(w):
                s.put(x + i, y + j, c, wrap)

    def line(s, x0, y0, x1, y1, c, w=1, wrap=False):
        n = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
        for k in range(n + 1):
            t = k / max(n, 1)
            x = x0 + (x1 - x0) * t; y = y0 + (y1 - y0) * t
            if w == 1:
                s.put(round(x), round(y), c, wrap)
            else:
                for j in range(w):
                    for i in range(w):
                        s.put(round(x) - w // 2 + i, round(y) - w // 2 + j, c, wrap)

    def disc(s, cx, cy, r, c):
        s.ell(cx, cy, r, r, c)

    def ell(s, cx, cy, rx, ry, c):
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
                if ((x + .5 - cx) / max(rx, .5)) ** 2 + ((y + .5 - cy) / max(ry, .5)) ** 2 <= 1:
                    s.put(x, y, c)

    def shade_ell(s, cx, cy, rx, ry, cols, rng, jit=0.12):
        """elipse sombreada (luz no canto superior esquerdo). cols: escuro..claro"""
        n = len(cols)
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
                dx = (x + .5 - cx) / max(rx, .5); dy = (y + .5 - cy) / max(ry, .5)
                if dx * dx + dy * dy <= 1:
                    l = 0.5 + (-dx * 0.45 - dy * 0.55) * 0.5 + rng.uniform(-jit, jit)
                    s.put(x, y, cols[max(0, min(n - 1, int(l * n)))])

    def outline(s, c, inner=False):
        src = list(s.p)
        for y in range(s.h):
            for x in range(s.w):
                if src[y * s.w + x][3] == 0:
                    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        xx, yy = x + dx, y + dy
                        if 0 <= xx < s.w and 0 <= yy < s.h and src[yy * s.w + xx][3] > 128:
                            s.p[y * s.w + x] = c
                            break

    def paste(s, o, x, y):
        for j in range(o.h):
            for i in range(o.w):
                s.put(x + i, y + j, o.p[j * o.w + i])

    def flipx(s):
        o = Img(s.w, s.h)
        for y in range(s.h):
            for x in range(s.w):
                o.p[y * s.w + x] = s.p[y * s.w + (s.w - 1 - x)]
        return o

    def flipy(s):
        o = Img(s.w, s.h)
        for y in range(s.h):
            for x in range(s.w):
                o.p[y * s.w + x] = s.p[(s.h - 1 - y) * s.w + x]
        return o

    def save(s, path):
        raw = bytearray()
        for y in range(s.h):
            raw.append(0)
            for x in range(s.w):
                raw.extend(s.p[y * s.w + x])
        def ch(t, d):
            c = struct.pack('>I', len(d)) + t + d
            return c + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
        png = b'\x89PNG\r\n\x1a\n' + ch(b'IHDR', struct.pack('>IIBBBBB', s.w, s.h, 8, 6, 0, 0, 0)) + \
              ch(b'IDAT', zlib.compress(bytes(raw), 9)) + ch(b'IEND', b'')
        import os
        os.makedirs(os.path.dirname(path), exist_ok=True)
        open(path, 'wb').write(png)


def tnoise(w, h, cell, seed):
    """ruido de valor TILEAVEL (0..1)"""
    r = random.Random(seed)
    gw, gh = max(1, w // cell), max(1, h // cell)
    g = [[r.random() for _ in range(gw)] for _ in range(gh)]
    out = [[0.0] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            fx = x / cell; fy = y / cell
            x0 = int(fx) % gw; y0 = int(fy) % gh
            x1 = (x0 + 1) % gw; y1 = (y0 + 1) % gh
            tx = fx - int(fx); ty = fy - int(fy)
            tx = tx * tx * (3 - 2 * tx); ty = ty * ty * (3 - 2 * ty)
            a = g[y0][x0] + (g[y0][x1] - g[y0][x0]) * tx
            b = g[y1][x0] + (g[y1][x1] - g[y1][x0]) * tx
            out[y][x] = a + (b - a) * ty
    return out

def fbm(w, h, seed, cells=(16, 8, 4)):
    ns = [tnoise(w, h, c, seed + i * 7) for i, c in enumerate(cells)]
    ws = [1.0 / (2 ** i) for i in range(len(cells))]
    tot = sum(ws)
    return [[sum(n[y][x] * k for n, k in zip(ns, ws)) / tot for x in range(w)] for y in range(h)]

def wander(img, x, y, steps, col, rng, w=1, ang=None, wrap=False, glow=None, curl=0.5):
    """caminhada aleatoria (raiz/rachadura)"""
    a = rng.uniform(0, 6.28) if ang is None else ang
    pts = []
    for _ in range(steps):
        a += rng.uniform(-curl, curl)
        x += math.cos(a); y += math.sin(a)
        pts.append((x, y))
        img.put(round(x), round(y), col, wrap)
        if w > 1:
            img.put(round(x) + 1, round(y), col, wrap)
        if glow and rng.random() < 0.08:
            img.put(round(x), round(y), glow, wrap)
    return pts
