"""Gera a arte (pixel art procedural) das Areas 3 e 4 da Fase 2.
Rodar na raiz do projeto: python tools/gen_arte_fase2_partes.py
"""
import os, sys, random, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pix import *

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'fases', 'fase_2', 'arte')


def out(rel, img):
    img.save(os.path.join(ROOT, rel))


# ---------- paletas ----------
MAIN = dict(base=[H('#17122b'), H('#1c1636'), H('#211a40'), H('#281f4d')], hi=H('#3d3070'), lo=H('#0e0a1e'),
            glint=H('#8a6bff'), glow=H('#cdb8ff'), acc=H('#4a3a8a'))
VIDA = dict(base=[H('#08170f'), H('#0b1f15'), H('#0e2a1c'), H('#123423')], hi=H('#1f5a3a'), lo=H('#040d08'),
            glint=H('#2fd6c0'), glow=H('#9bffd0'), acc=H('#2b7a4c'))
CONVM = dict(base=[H('#16112a'), H('#1b1535'), H('#201940'), H('#271e4a')], hi=H('#3f3274'), lo=H('#0c0919'),
             glint=H('#19e6ff'), glow=H('#7ff4ff'), acc=H('#4b3b8c'))
CONVV = dict(base=[H('#07161a'), H('#0a1f22'), H('#0d2a28'), H('#113530')], hi=H('#1c5a4c'), lo=H('#040d0e'),
             glint=H('#19e6ff'), glow=H('#7ff4ff'), acc=H('#2b7a5c'))
MOSS = [H('#0f4a2a'), H('#1a7a45'), H('#2fb366'), H('#6cf0a0')]
ROOT_C = [H('#1d1a0e'), H('#33301a'), H('#4e4725'), H('#6e6234')]
CYAN = H('#19e6ff'); CYAN_L = H('#a8fbff'); CYAN_D = H('#0b7f94')
VIOL = [H('#251a52'), H('#3b2b7a'), H('#5a43b0'), H('#8a6bff'), H('#cdb8ff')]
EMER = [H('#0a3320'), H('#136b3f'), H('#1fa862'), H('#53e08a'), H('#b8ffd8')]
TURQ = [H('#07454a'), H('#0e8a8a'), H('#2fd6c0'), H('#7dffe0'), H('#d6fff4')]
OUTL_V = H('#0a0618'); OUTL_G = H('#03120a')
# musgo do PISO: baixa luminosidade/saturacao para nao disputar com jogador e objetos interativos
MOSSF = [H('#0a2416'), H('#0e3220'), H('#134128'), H('#1a5434')]
STONE = [H('#1d1a2e'), H('#2d2848'), H('#403a66'), H('#5a5290'), H('#8a82c0')]
STONE_G = [H('#12201a'), H('#1f3328'), H('#2f4a3a'), H('#44695a'), H('#6f9a88')]


# ---------- pisos / paredes tileaveis ----------
def floor_tex(P, seed, w=96, h=96, moss=0.0, roots=0, runes=0, cyan=0, cracks=4):
    r = random.Random(seed)
    im = Img(w, h)
    nz = fbm(w, h, seed)
    for sy in range(0, h, 32):
        for sx in range(0, w, 32):
            sh = r.choice(P['base'])
            for y in range(32):
                for x in range(32):
                    n = nz[(sy + y) % h][(sx + x) % w]
                    c = sh
                    if n > 0.62:
                        c = mix(sh, P['hi'], 0.18)
                    elif n < 0.36:
                        c = mix(sh, P['lo'], 0.35)
                    if r.random() < 0.05:
                        c = mix(c, P['lo'], 0.4)
                    im.put(sx + x, sy + y, c, True)
            for i in range(32):
                im.put(sx + i, sy, mix(sh, P['hi'], 0.55), True)
                im.put(sx, sy + i, mix(sh, P['hi'], 0.4), True)
                im.put(sx + i, sy + 31, P['lo'], True)
                im.put(sx + 31, sy + i, P['lo'], True)
            for _ in range(r.randint(1, 3)):
                im.put(sx + r.randint(3, 28), sy + r.randint(3, 28), mix(sh, P['lo'], 0.6), True)
    for _ in range(cracks):
        wander(im, r.randint(0, w), r.randint(0, h), r.randint(10, 26), P['lo'], r, wrap=True,
               glow=P['glint'] if cyan else None, curl=0.7)
    if moss:
        mn = tnoise(w, h, 12, seed + 99)
        mn2 = tnoise(w, h, 5, seed + 5)
        for y in range(h):
            for x in range(w):
                v = mn[y][x] * 0.7 + mn2[y][x] * 0.3
                if v > 1 - moss:
                    d = (v - (1 - moss)) / moss
                    im.put(x, y, MOSSF[0] if d < .35 else MOSSF[1] if d < .75 else MOSSF[2], True)
                    if d > .9 and r.random() < .08:
                        im.put(x, y, MOSSF[3], True)
    for _ in range(roots):
        pts = wander(im, r.randint(0, w), r.randint(0, h), r.randint(22, 44), ROOT_C[1], r, w=2, wrap=True,
                     glow=H('#2fd6c0'), curl=0.35)
        for (x, y) in pts[::3]:
            im.put(round(x) - 1, round(y) - 1, ROOT_C[3], True)
    for _ in range(runes):
        gx, gy = r.randint(4, w - 12), r.randint(4, h - 12)
        for k in range(r.randint(2, 4)):
            if r.random() < .5:
                im.rect(gx, gy + k * 3, r.randint(3, 7), 1, P['acc'], True)
            else:
                im.rect(gx + k * 2, gy, 1, r.randint(3, 6), P['acc'], True)
        im.put(gx, gy, mix(P['acc'], P['glint'], .5), True)
    for _ in range(cyan):
        wander(im, r.randint(0, w), r.randint(0, h), r.randint(8, 18), mix(CYAN, P['lo'], 0.35), r, wrap=True,
               curl=0.25)
    return im


def wall_tex(P, seed, moss=False, roots=False, cyan=False):
    r = random.Random(seed)
    im = Img(32, 32)
    nz = fbm(32, 32, seed, (8, 4))
    for row in range(4):
        off = 0 if row % 2 == 0 else 8
        for bx in range(-1, 3):
            x0 = bx * 16 + off
            y0 = row * 8
            sh = mix(r.choice(P['base']), P['hi'], 0.30)
            for y in range(8):
                for x in range(16):
                    c = sh
                    n = nz[(y0 + y) % 32][(x0 + x) % 32]
                    if n > .6:
                        c = mix(sh, P['hi'], .25)
                    elif n < .35:
                        c = mix(sh, P['lo'], .3)
                    if y == 0:
                        c = mix(sh, P['hi'], .5)
                    if y == 7 or x == 15:
                        c = mix(sh, P['lo'], .75)
                    im.put(x0 + x, y0 + y, c, True)
    for x in range(32):
        im.put(x, 0, mix(P['hi'], P['glow'], .25), True)
        im.put(x, 1, P['hi'], True)
    if moss:
        for x in range(32):
            d = int(2 + nz[2][x] * 7)
            for y in range(d):
                im.put(x, y, MOSS[0] if y == d - 1 else MOSS[2 if (r.random() < .12) else 1], True)
            if r.random() < .25:
                for y in range(d, d + r.randint(2, 7)):
                    im.put(x, y, MOSS[0] if y % 3 else MOSS[1], True)
    if roots:
        for _ in range(2):
            wander(im, r.randint(0, 32), r.randint(0, 6), r.randint(16, 30), ROOT_C[1], r, w=2, ang=1.57,
                   wrap=True, glow=H('#2fd6c0'), curl=0.3)
    if cyan:
        for _ in range(2):
            wander(im, r.randint(0, 32), r.randint(0, 32), r.randint(8, 16), mix(CYAN, P['lo'], .3), r, wrap=True,
                   curl=.3)
        im.put(r.randint(2, 29), r.randint(2, 29), CYAN, True)
    return im


def wall_wide(P, seed, moss=False, roots_em=(), cyan=False, n=4):
    """parede 32*n x 32: n segmentos diferentes (quebra a repeticao das raizes/musgo)."""
    im = Img(32 * n, 32)
    for i in range(n):
        seg = wall_tex(P, seed + i * 17, moss=moss, roots=(i in roots_em), cyan=cyan and i % 2 == 0)
        im.paste(seg, 32 * i, 0)
    return im


def abismo_tex(P, seed, specks, col):
    r = random.Random(seed)
    w = h = 64
    im = Img(w, h)
    n1 = fbm(w, h, seed, (32, 16, 8))
    n2 = tnoise(w, h, 8, seed + 3)
    for y in range(h):
        for x in range(w):
            v = n1[y][x]
            c = mix(P['lo'], P['base'][0], 0.35 + v * 0.65)
            if n2[y][x] > .72 and (y % 4 < 2):
                c = mix(c, P['base'][2], .35)
            im.put(x, y, c)
    for _ in range(specks):
        x, y = r.randint(0, w - 1), r.randint(0, h - 1)
        im.put(x, y, mix(col, P['lo'], r.uniform(.2, .7)))
        if r.random() < .25:
            im.put(x, y - 1, mix(col, P['lo'], .8))
    return im


def abismo_grande(P, seed, col, w=768, h=128):
    """abismo continuo 768x128 (Main): escuro no centro, ruinas distantes, nevoa e pouquissimos pontos."""
    r = random.Random(seed)
    im = Img(w, h)
    n1 = fbm(w, h, seed, (64, 32, 16))
    for y in range(h):
        t = 1 - abs(y - (h - 1) / 2.0) / (h / 2.0)
        base = mix(mix(P['base'][1], P['hi'], .12), P['lo'], min(1.0, t ** 0.7))
        for x in range(w):
            im.put(x, y, mix(base, P['base'][0], n1[y][x] * .35))
    for _ in range(16):  # ruinas profundas, bem tenues
        x = r.randint(0, w - 12)
        wd = r.randint(8, 18)
        top = r.randint(48, 96)
        cor = mix(P['base'][1], P['hi'], r.uniform(.10, .22))
        for yy in range(top, h):
            f = 1 - (yy - top) / float(h - top) * .55
            for xx in range(x, x + wd):
                im.put(xx, yy, mix(im.get(xx, yy), cor, .75 * f))
        for xx in range(x, x + wd):
            im.put(xx, top + (xx - x) % 3, mix(P['hi'], P['glow'], .12))
        for yy in range(top, h, 9):
            im.rect(x, yy, wd, 1, mix(P['lo'], cor, .3))
    for _ in range(44):  # nevoa em faixas largas e baixa opacidade
        x = r.randint(-20, w - 40)
        y = r.randint(24, h - 24)
        L = r.randint(40, 140)
        a = r.randint(14, 30)
        for xx in range(x, x + L):
            fade = 1 - abs((xx - x) - L / 2.0) / (L / 2.0)
            im.put(xx, y, (P['glint'][0], P['glint'][1], P['glint'][2], int(a * fade)))
            if r.random() < .5:
                im.put(xx, y + 1, (P['glint'][0], P['glint'][1], P['glint'][2], int(a * fade * .5)))
    for _ in range(14):  # poucos pontos, fracos
        x, y = r.randint(4, w - 4), r.randint(20, h - 20)
        im.put(x, y, mix(col, P['lo'], .55))
        if r.random() < .5:
            for k in range(1, 4):
                im.put(x, y - k, (col[0], col[1], col[2], 60 - k * 15))
    return im


def borda_sup(P, seed, vida=False, w=32, h=16):
    """face do penhasco que pende da margem norte do abismo (transparente embaixo)."""
    r = random.Random(seed)
    im = Img(w, h)
    nz = tnoise(w, h, 8, seed)
    for x in range(w):
        d = int(5 + nz[3][x] * 7)
        for y in range(d):
            t = y / max(d - 1, 1)
            c = mix(mix(P['hi'], P['base'][3], .5), P['lo'], t * .85)
            if (x + y // 3) % 7 == 0:
                c = mix(c, P['lo'], .35)
            im.put(x, y, c, True)
        im.put(x, 0, mix(P['hi'], P['glow'], .2), True)
        im.put(x, d - 1, P['lo'], True)
        if vida and r.random() < .35:
            L = r.randint(3, 9)
            for y in range(d, min(h, d + L)):
                im.put(x, y, ROOT_C[1] if y % 2 else ROOT_C[0], True)
            if r.random() < .5:
                im.put(x, min(h - 1, d + L), TURQ[2], True)
        if vida and nz[1][x] > .45:
            for y in range(0, 2):
                im.put(x, y, MOSS[1 + y], True)
    return im


def borda_inf(P, seed, vida=False, w=32, h=16):
    """margem sul do abismo: piso esfarelando para o vazio (transparente em cima)."""
    r = random.Random(seed)
    im = Img(w, h)
    nz = tnoise(w, h, 8, seed)
    for x in range(w):
        d = int(5 + nz[5][x] * 7)
        for y in range(h - d, h):
            t = (y - (h - d)) / max(d - 1, 1)
            c = mix(mix(P['base'][3], P['hi'], .3), P['base'][0], t * .5)
            im.put(x, y, c, True)
        im.put(x, h - d, mix(P['hi'], P['glow'], .22), True)
        im.put(x, h - d + 1, P['hi'], True)
        if r.random() < .14:
            im.put(x, h - d - 1, P['base'][1], True)
        if vida and nz[2][x] > .5:
            im.put(x, h - d, MOSS[2], True)
    for _ in range(3):
        im.rect(r.randint(0, w - 3), r.randint(0, 3), 2, 1, P['hi'])
    return im


def borda_lado(P, seed, lado_esq, vida=False, w=16, h=32):
    """margem lateral do abismo. lado_esq=True: a face fica na ESQUERDA do retangulo."""
    r = random.Random(seed)
    im = Img(w, h)
    nz = tnoise(w, h, 8, seed)
    for y in range(h):
        d = int(4 + nz[y][5] * 6)
        for k in range(d):
            x = k if lado_esq else w - 1 - k
            t = k / max(d - 1, 1)
            im.put(x, y, mix(mix(P['base'][3], P['hi'], .4), P['lo'], t * .8))
        xe = 0 if lado_esq else w - 1
        im.put(xe, y, mix(P['hi'], P['glow'], .15))
        if vida and r.random() < .3:
            for k in range(d, d + r.randint(2, 5)):
                im.put(k if lado_esq else w - 1 - k, y, ROOT_C[1])
    return im


# ---------- pontes ----------
def ponte_main_ponta(norte, seed=11):
    """128x32. norte=True: a ponta partida fica embaixo; False: em cima. Pedra antiga em blocos
    quebrados (degraus largos), com vigas de metal expostas e fragmentos soltos."""
    r = random.Random(seed + (0 if norte else 5))
    w, h = 128, 32
    im = Img(w, h)
    nz = tnoise(w, h, 8, seed)
    for y in range(h):
        for x in range(w):
            im.put(x, y, mix(STONE[2], STONE[1], .5 + .4 * nz[y][x]))
    for y in range(0, h, 8):
        for x in range(w):
            im.put(x, y, STONE[3])
            im.put(x, y + 7, STONE[0])
        for k in range(0, w, 32 + r.randint(0, 6)):
            im.rect(k, y, 1, 8, STONE[0])
    for y in range(h):
        for x in range(0, 8):
            im.put(x, y, mix(STONE[3], STONE[1], x / 8.0))
            im.put(w - 1 - x, y, mix(STONE[3], STONE[1], x / 8.0))
        im.put(8, y, STONE[0])
        im.put(w - 9, y, STONE[0])
    for y in range(h):
        for x in (62, 63, 64, 65):
            im.put(x, y, VIOL[1] if x in (62, 65) else VIOL[3])
    prof = []
    while len(prof) < w:
        seg = r.choice((9, 11, 14, 17))
        d = r.randint(5, 13)
        prof += [d] * seg
    prof = prof[:w]
    for x in range(w):
        for k in range(prof[x]):
            y = h - 1 - k if norte else k
            im.p[y * w + x] = (0, 0, 0, 0)
    passo = [x for x in range(1, w) if prof[x] != prof[x - 1]]
    for x in passo:
        d = max(prof[x], prof[x - 1])
        yb = h - 1 - d if norte else d
        for k in range(r.randint(4, 8)):
            y = yb - k if norte else yb + k
            im.put(x, y, STONE[0])
    for x in range(w):
        d = prof[x]
        yb = h - 1 - d if norte else d
        sgn = -1 if norte else 1
        im.put(x, yb + sgn, mix(STONE[1], STONE[0], .55))
        im.put(x, yb + 2 * sgn, mix(STONE[2], STONE[0], .25))
    im.outline(STONE[0])
    for bx in (21, 99):  # vigas expostas
        d = prof[bx]
        L = min(9, d - 1)
        yb = h - 1 - d if norte else d
        for k in range(L):
            y = yb + 1 + k if norte else yb - 1 - k
            for xx in range(bx, bx + 4):
                c = VIOL[3] if xx == bx else VIOL[1] if xx < bx + 3 else VIOL[0]
                im.put(xx, y, c)
        yend = yb + 1 + L if norte else yb - 1 - L
        im.rect(bx, yend, 4, 1, OUTL_V)
        im.put(bx + 1, yend + (1 if not norte else -1), VIOL[4])
    for _ in range(3):  # fragmentos soltos
        x = r.randint(14, 108)
        d = prof[x]
        if d < 8:
            continue
        yb = h - 1 - d if norte else d
        y = yb + 3 if norte else yb - 5
        wd = r.randint(4, 6)
        hh = 3
        im.rect(x, y, wd, hh, STONE[2])
        im.rect(x, y, wd, 1, STONE[4])
        im.rect(x, y + hh - 1, wd, 1, STONE[0])
        im.rect(x + wd - 1, y, 1, hh, STONE[0])
    yb = (h - 1 - prof[63]) if norte else prof[63]
    im.put(63, yb, CYAN_L)
    im.put(64, yb + (1 if norte else -1), CYAN)
    return im


def ponte_vao_det(seed=21):
    """128x64 transparente: fragmentos de pedra e vigas flutuando no vao (poucos, volumosos)."""
    r = random.Random(seed)
    im = Img(128, 64)
    usados = []
    for _ in range(7):
        for _t in range(20):
            x, y = r.randint(10, 112), r.randint(10, 48)
            if all(abs(x - ux) > 14 or abs(y - uy) > 9 for (ux, uy) in usados):
                break
        usados.append((x, y))
        w, h = r.randint(4, 9), r.randint(3, 5)
        im.rect(x, y, w, h, STONE[2])
        im.rect(x, y, w, 1, STONE[4])
        im.rect(x + w - 2, y + 1, 2, h - 1, STONE[1])
        im.rect(x, y + h - 1, w, 1, STONE[0])
        if r.random() < .35:
            im.put(x + 1, y - 1, VIOL[3])
    for (x, y) in ((30, 22), (88, 36)):
        for k in range(10):
            im.put(x + k, y + k // 5, VIOL[1])
            im.put(x + k, y + 1 + k // 5, VIOL[0])
        im.put(x, y, VIOL[3])
    im.outline(OUTL_V)
    for y in range(14, 52, 6):
        im.put(63, y, VIOL[2])
    return im


def ponte_raizes(seed=31):
    """128x128 opaca: ponte de raizes trancadas com lajes antigas."""
    r = random.Random(seed)
    w = h = 128
    im = Img(w, h)
    nz = fbm(w, h, seed, (32, 16, 8))
    for y in range(h):
        for x in range(w):
            im.put(x, y, mix(VIDA['base'][1], VIDA['base'][3], nz[y][x]))
    # lajes antigas atravessadas
    for k in range(0, h, 24):
        y = k + r.randint(0, 6)
        wd = r.randint(70, 112)
        x0 = (w - wd) // 2 + r.randint(-6, 6)
        im.rect(x0, y, wd, 11, STONE_G[2])
        im.rect(x0, y, wd, 2, STONE_G[4])
        im.rect(x0, y + 10, wd, 1, STONE_G[0])
        for _ in range(3):
            im.put(x0 + r.randint(2, wd - 3), y + r.randint(3, 8), STONE_G[0])
    # raizes grossas longitudinais
    for i in range(11):
        x = 6 + i * 11.5 + r.uniform(-3, 3)
        th = r.randint(3, 5)
        ph = r.uniform(0, 6.28)
        for y in range(h):
            cx = x + math.sin(y / 14.0 + ph) * 3
            for t in range(th):
                shade = ROOT_C[3] if t == 0 else ROOT_C[2] if t < th - 1 else ROOT_C[0]
                im.put(round(cx) + t, y, shade)
            if r.random() < .03:
                im.put(round(cx) + 1, y, TURQ[2])
    # veias luminosas
    for _ in range(7):
        wander(im, r.randint(8, 120), r.randint(0, 127), r.randint(14, 30), TURQ[1], r, ang=1.57, curl=.25)
    for _ in range(26):
        x, y = r.randint(2, 125), r.randint(2, 125)
        im.put(x, y, TURQ[3])
    # musgo
    mn = tnoise(w, h, 10, seed + 4)
    for y in range(h):
        for x in range(w):
            if mn[y][x] > .70:
                im.put(x, y, MOSS[0] if mn[y][x] < .76 else MOSS[1])
    # trilhos de raiz nas laterais
    for y in range(h):
        for k in range(6):
            amp = int(2 + 2 * math.sin(y / 5.0 + k))
            im.put(k + (amp // 2), y, ROOT_C[2 - (k > 3)] if k < 5 else ROOT_C[0])
            im.put(w - 1 - k - (amp // 2), y, ROOT_C[2 - (k > 3)] if k < 5 else ROOT_C[0])
    return im


def espinheiro_tex(seed=41):
    r = random.Random(seed)
    im = Img(32, 32)
    for y in range(32):
        for x in range(32):
            im.put(x, y, mix(VIDA['lo'], VIDA['base'][1], .6 + r.random() * .3))
    for _ in range(7):
        pts = wander(im, r.randint(0, 31), r.randint(0, 31), r.randint(18, 34), ROOT_C[2], r, w=2, wrap=True, curl=.6)
        for (x, y) in pts[::4]:  # espinhos
            a = r.uniform(0, 6.28)
            for k in range(1, 4):
                im.put(round(x + math.cos(a) * k), round(y + math.sin(a) * k),
                       TURQ[3] if k == 3 and r.random() < .5 else MOSS[1 + (k > 1)], True)
    for _ in range(6):
        x, y = r.randint(0, 31), r.randint(0, 31)
        im.put(x, y, TURQ[4], True)
        im.put(x + 1, y, TURQ[2], True)
    return im


# ---------- props ----------
def arvore_vida(seed, variante):
    r = random.Random(seed)
    w, h = 44, 84
    im = Img(w, h)
    cx = 22
    if variante == 1:  # coluna antiga com a arvore enrolada
        top = 46 + r.randint(0, 6)
        for y in range(top, 83):
            for x in range(cx - 7, cx + 7):
                t = (x - (cx - 7)) / 13.0
                im.put(x, y, mix(STONE_G[3], STONE_G[0], t))
        for x in range(cx - 7, cx + 7):
            im.put(x, top, STONE_G[4])
        for y in range(top, 83, 7):
            im.rect(cx - 7, y, 14, 1, STONE_G[0])
    if variante != 1:  # blocos de ruina engolidos pela arvore
        bx = cx - 15 if variante == 0 else cx + 4
        for (ox, oy, ww, hh) in ((0, 70, 11, 13), (6, 64, 7, 9)):
            xx = bx + ox
            im.rect(xx, oy, ww, hh, STONE_G[2])
            im.rect(xx, oy, ww, 2, STONE_G[4])
            im.rect(xx + ww - 3, oy + 2, 3, hh - 2, STONE_G[1])
            im.rect(xx, oy + hh - 1, ww, 1, STONE_G[0])
            for k in range(ww):
                if k % 3 == 0:
                    im.put(xx + k, oy - 1, MOSS[1])
    # tronco torcido
    pts = []
    for i in range(0, 50):
        t = i / 49.0
        y = 82 - i
        x = cx + math.sin(t * 5 + seed) * (5 if variante == 1 else 3)
        wd = int(9 - 4 * t) + (2 if i < 6 else 0)
        pts.append((x, y, wd))
        for k in range(wd):
            c = ROOT_C[3] if k == 0 else ROOT_C[2] if k < wd - 2 else ROOT_C[0] if k == wd - 1 else ROOT_C[1]
            im.put(round(x - wd / 2) + k, y, c)
        if r.random() < .12:
            im.put(round(x), y, TURQ[2])
    # raizes aflorando na base
    for s in (-1, 1):
        for k in range(8):
            im.put(cx + s * (5 + k), 82 - k // 3, ROOT_C[2])
            im.put(cx + s * (5 + k), 83 - k // 3, ROOT_C[0])
    # copa
    cy = 30
    for i in range(8):
        ang = r.uniform(0, 6.28)
        dist = r.uniform(2, 13)
        rx = cx + math.cos(ang) * dist
        ry = cy + math.sin(ang) * dist * .75
        rad = r.uniform(7, 11)
        im.shade_ell(rx, ry, rad, rad * .85, [H('#04201a'), H('#06281f'), H('#0a3a2a'), H('#0f5a3c'), H('#168a58')], r)
    for _ in range(18):  # folhas luminosas
        a = r.uniform(0, 6.28)
        d = r.uniform(3, 17)
        im.put(round(cx + math.cos(a) * d), round(cy + math.sin(a) * d * .75), TURQ[3] if r.random() < .6 else TURQ[4])
    for _ in range(7):  # cipos pendurados
        x = r.randint(cx - 14, cx + 14)
        y0 = cy + int(abs(x - cx) * .1) + 8
        L = r.randint(5, 14)
        for y in range(y0, y0 + L):
            im.put(x, y, EMER[1] if y % 2 else EMER[0])
        im.put(x, y0 + L, TURQ[3])
    im.outline(OUTL_G)
    return im


def arbusto_vida(seed, variante):
    r = random.Random(seed)
    im = Img(28, 18)
    if variante == 0:  # samambaia luminosa
        for i in range(9):
            a = -math.pi / 2 + (i - 4) * .33
            L = r.randint(9, 15)
            x, y = 14, 17
            for k in range(L):
                x += math.cos(a) * 1
                y += math.sin(a) * 1
                a += .03 * (1 if i > 4 else -1)
                im.put(round(x), round(y), EMER[1 + (k > L // 2)])
                if k % 2 == 0 and k > 3:
                    im.put(round(x) - 1, round(y), EMER[2])
                    im.put(round(x) + 1, round(y), EMER[2])
            im.put(round(x), round(y), TURQ[3])
    else:  # cogumelos / bulbos luminosos
        for (x, y, rr) in ((8, 14, 5), (17, 12, 6), (23, 15, 3), (13, 16, 3)):
            im.rect(x - 1, y, 2, 17 - y + 1, ROOT_C[2])
            im.shade_ell(x, y - 1, rr, rr * .6, [TURQ[0], TURQ[1], TURQ[2], TURQ[3]], r, .05)
            im.put(x - 1, y - 2, TURQ[4])
        for _ in range(8):
            im.put(r.randint(0, 27), r.randint(0, 14), TURQ[4] if r.random() < .5 else TURQ[3])
    im.outline(OUTL_G)
    return im


def cristal_vida(seed):
    r = random.Random(seed)
    im = Img(10, 22)
    for (bx, hh, wd) in ((4, 20, 3), (7, 13, 2), (1, 9, 2)):
        for y in range(21 - hh, 22):
            t = (y - (21 - hh)) / float(hh)
            ww = max(1, int(wd * (0.4 + t)))
            for x in range(bx - ww // 2, bx - ww // 2 + ww + 1):
                c = TURQ[3] if x == bx - ww // 2 else TURQ[2] if t < .6 else TURQ[1]
                if x == bx - ww // 2 + ww:
                    c = TURQ[0]
                im.put(x, y, c)
        im.put(bx, 21 - hh, TURQ[4])
    im.outline(OUTL_G)
    return im


def pilar_vida(seed=51):
    """14x52: pilar antigo com cristal e raizes (par do pilar_fino da Main)."""
    r = random.Random(seed)
    im = Img(14, 52)
    for y in range(14, 52):
        for x in range(2, 12):
            t = (x - 2) / 9.0
            im.put(x, y, mix(STONE_G[3], STONE_G[0], t))
    for y in range(14, 52, 6):
        im.rect(2, y, 10, 1, STONE_G[0])
    for y in range(0, 16):  # cristal no topo
        ww = 2 + min(y, 6) // 2
        for x in range(7 - ww, 7 + ww):
            im.put(x, 14 - y // 1 + 2 if False else y, TURQ[1])
    im = Img(14, 52)
    for y in range(18, 52):
        for x in range(2, 12):
            t = (x - 2) / 9.0
            im.put(x, y, mix(STONE_G[3], STONE_G[0], t))
    for y in range(18, 52, 6):
        im.rect(2, y, 10, 1, STONE_G[0])
    for y in range(1, 20):  # cristal
        hw = max(1, int(4 * (1 - abs(y - 10) / 11.0)) + 1)
        for x in range(7 - hw, 7 + hw):
            im.put(x, y, TURQ[3] if x < 7 - hw + 1 else TURQ[2] if x < 7 else TURQ[1])
    im.put(6, 4, TURQ[4])
    im.put(6, 5, TURQ[4])
    for k in range(34):  # raiz enrolando
        x = 7 + int(math.sin(k / 3.0) * 5)
        im.put(x, 50 - k, ROOT_C[2])
        im.put(x + 1, 50 - k, ROOT_C[0])
    im.outline(OUTL_G)
    return im


def pedestal_vida():
    r = random.Random(3)
    im = Img(22, 18)
    im.shade_ell(11, 14, 10, 4, STONE_G[:4], r, .05)
    im.rect(4, 6, 14, 8, STONE_G[2])
    im.rect(4, 6, 14, 1, STONE_G[4])
    im.rect(15, 7, 3, 7, STONE_G[1])
    for k in range(7):
        im.put(3 + k * 2, 13 - (k % 3), ROOT_C[2])
        im.put(4 + k * 2, 13 - (k % 3), ROOT_C[0])
    im.shade_ell(11, 5, 7, 2, STONE_G[1:], r, .05)
    im.outline(OUTL_G)
    return im


def cacos_luz(cor, w=22, h=22, seed=4):
    r = random.Random(seed)
    im = Img(w, h)
    for (x, y, s) in ((w // 2, 6, 4), (5, 13, 3), (w - 6, 14, 3)):
        for k in range(s + 2):
            im.put(x, y - k + s // 2, cor[2])
            im.put(x - 1, y - k + s // 2 + 1, cor[1])
            im.put(x + 1, y - k + s // 2 + 1, cor[3])
        im.put(x, y - s // 2 - 1, cor[4])
        im.put(x, y - s // 2, cor[3])
    for _ in range(7):
        im.put(r.randint(1, w - 2), r.randint(1, h - 2), cor[4] if r.random() < .5 else cor[3])
    im.outline(OUTL_G if cor is TURQ or cor is EMER else OUTL_V)
    return im


# ---------- decals de chao ----------
def d_raiz(seed, w=48, h=24):
    r = random.Random(seed)
    im = Img(w, h)
    for _ in range(3):
        pts = wander(im, r.randint(2, 8), r.randint(6, h - 6), r.randint(28, 50), ROOT_C[2], r, w=2, ang=0, curl=.28,
                     glow=TURQ[2])
        for (x, y) in pts[::5]:
            im.put(round(x) - 1, round(y) - 1, ROOT_C[3])
    im.outline(ROOT_C[0])
    return im


def d_musgo(seed, w=40, h=24):
    r = random.Random(seed)
    im = Img(w, h)
    nz = tnoise(w, h, 6, seed)
    for y in range(h):
        for x in range(w):
            dx = (x - w / 2) / (w / 2)
            dy = (y - h / 2) / (h / 2)
            v = nz[y][x] - (dx * dx + dy * dy) * .55
            if v > .18:
                im.put(x, y, MOSSF[0] if v < .3 else MOSSF[1] if v < .42 else MOSSF[2])
                if v > .5 and r.random() < .1:
                    im.put(x, y, MOSSF[3])
    for _ in range(2):
        im.put(r.randint(4, w - 4), r.randint(4, h - 4), TURQ[2])
    return im


def d_cogumelos(seed):
    r = random.Random(seed)
    im = Img(18, 14)
    for (x, y, rr) in ((5, 10, 3), (11, 8, 4), (15, 11, 2)):
        im.rect(x, y, 1, 13 - y, ROOT_C[2])
        im.shade_ell(x, y - 1, rr, rr * .6, [TURQ[1], TURQ[2], TURQ[3]], r, .05)
        im.put(x - 1, y - 2, TURQ[4])
    return im


def d_hera(seed, w=24, h=28):
    r = random.Random(seed)
    im = Img(w, h)
    for _ in range(5):
        x = r.randint(2, w - 3)
        L = r.randint(8, h - 3)
        for y in range(L):
            x += r.choice((0, 0, 0, 1, -1)) if y % 3 == 0 else 0
            im.put(x, y, ROOT_C[2] if y % 2 else ROOT_C[1])
            if y % 4 == 3:
                im.put(x - 1, y, MOSS[2])
                im.put(x + 1, y, MOSS[1])
        im.put(x, L, TURQ[3])
    return im


def d_rachadura(P, seed, w=48, h=16, cyan=False):
    r = random.Random(seed)
    im = Img(w, h)
    pts = wander(im, 2, h // 2, 44, P['lo'], r, w=2, ang=0, curl=.6, glow=P['glint'])
    for _ in range(2):
        s = r.choice(pts)
        wander(im, s[0], s[1], r.randint(6, 12), P['lo'], r, curl=.8)
    if cyan:
        for (x, y) in pts[::7]:
            im.put(round(x), round(y), CYAN)
    return im


def d_runa(P, seed, s=32):
    r = random.Random(seed)
    im = Img(s, s)
    c = P['acc']
    g = P['glint']
    for rad in (13, 9):
        for a in range(0, 360, 3):
            im.put(s // 2 + round(math.cos(math.radians(a)) * rad), s // 2 + round(math.sin(math.radians(a)) * rad),
                   c if a % 30 else g)
    for k in range(-4, 5):
        im.put(s // 2 + k, s // 2, c)
        im.put(s // 2, s // 2 + k, c)
    im.put(s // 2, s // 2, g)
    return im


def d_entulho(P, seed, w=28, h=14, moss=False):
    r = random.Random(seed)
    im = Img(w, h)
    for _ in range(r.randint(4, 6)):
        x = r.randint(2, w - 8)
        y = r.randint(3, h - 6)
        ww, hh = r.randint(4, 8), r.randint(3, 5)
        im.rect(x, y, ww, hh, mix(P['base'][3], P['hi'], .5))
        im.rect(x, y, ww, 1, mix(P['hi'], P['glow'], .3))
        im.rect(x, y + hh - 1, ww, 1, P['lo'])
        im.rect(x + ww - 1, y, 1, hh, P['lo'])
        if moss and r.random() < .6:
            im.rect(x, y - 1, ww // 2 + 1, 1, MOSS[1])
            im.put(x + 1, y - 1, MOSS[2])
    im.outline(P['lo'])
    return im


def d_coluna_tombada(P, seed, moss=False, w=48, h=20):
    r = random.Random(seed)
    im = Img(w, h)
    for x in range(4, w - 4):
        for y in range(5, 15):
            t = (y - 5) / 9.0
            c = mix(mix(P['hi'], P['base'][3], .6), P['lo'], t * .8)
            im.put(x, y, c)
    for x in range(8, w - 6, 8):
        im.rect(x, 5, 1, 10, P['lo'])
    for y in range(6, 14, 1):  # ponta quebrada denteada
        im.put(4 + (y % 3), y, (0, 0, 0, 0))
    im.rect(4, 5, w - 8, 1, mix(P['hi'], P['glow'], .3))
    if moss:
        for x in range(10, 36):
            im.put(x, 5, MOSS[1])
            if r.random() < .5:
                im.put(x, 6, MOSS[0])
        for x in range(8, 30, 4):
            wander(im, x, 6, r.randint(3, 6), ROOT_C[2], r, ang=1.57, curl=.3)
    im.outline(P['lo'])
    return im


def d_cristais(seed, n=3):
    r = random.Random(seed)
    im = Img(26, 20)
    for i in range(n):
        bx = 5 + i * 8 + r.randint(-1, 1)
        hh = r.randint(9, 17)
        for y in range(19 - hh, 20):
            t = (y - (19 - hh)) / float(hh)
            ww = max(1, int(3 * (.3 + t)))
            for x in range(bx - ww // 2, bx - ww // 2 + ww + 1):
                im.put(x, y, TURQ[3] if x == bx - ww // 2 else TURQ[2] if t < .6 else TURQ[1])
        im.put(bx, 19 - hh, TURQ[4])
    im.outline(OUTL_G)
    return im


# ---------- barreira da Vida (mesmo formato 128x96: fechada | aberta) ----------
def barreira_vida():
    r = random.Random(61)
    im = Img(128, 96)
    # quadro 0: fechada -- arco de raizes selando a passagem, nucleo turquesa
    for fr in (0, 1):
        ox = fr * 64
        for y in range(96):
            for x in range(64):
                im.put(ox + x, y, mix(VIDA['lo'], VIDA['base'][2], .4 + r.random() * .3))
        for y in range(96):  # pilares de pedra nas laterais, tomados por raiz
            for x in range(0, 10):
                im.put(ox + x, y, mix(STONE_G[3], STONE_G[0], x / 10.0))
                im.put(ox + 63 - x, y, mix(STONE_G[3], STONE_G[0], x / 10.0))
            if y % 12 == 0:
                im.rect(ox, y, 10, 1, STONE_G[0])
                im.rect(ox + 54, y, 10, 1, STONE_G[0])
        for y in range(0, 96):
            for k in (10, 53):
                wander_x = k + int(math.sin(y / 5.0) * 2)
                im.put(ox + wander_x, y, ROOT_C[2])
                im.put(ox + wander_x + 1, y, ROOT_C[0])
        for x in range(64):  # lintel
            im.rect(ox + x, 0, 1, 6, STONE_G[2])
            im.put(ox + x, 0, STONE_G[4])
            im.put(ox + x, 5, STONE_G[0])
        if fr == 0:
            for i in range(6):  # raizes cruzadas bloqueando
                wander(im, ox + 11, 12 + i * 14, 36, ROOT_C[2], r, w=3, ang=r.uniform(-.3, .3), curl=.25,
                       glow=TURQ[2])
                wander(im, ox + 52, 12 + i * 14, 36, ROOT_C[1], r, w=3, ang=3.14 + r.uniform(-.3, .3), curl=.25)
            im.shade_ell(32, 48, 9, 12, [TURQ[0], TURQ[1], TURQ[2], TURQ[3], TURQ[4]], r, .05)
            im.disc(32, 48, 3, TURQ[4])
        else:
            for i in range(0, 96, 6):  # raizes recolhidas, trilha de luz no chao
                im.put(ox + 12, i, ROOT_C[2])
                im.put(ox + 51, i, ROOT_C[2])
            for y in range(40, 96):
                for x in range(14, 50):
                    im.put(ox + x, y, mix(VIDA['base'][2], TURQ[1], (1 - abs(x - 32) / 18.0) * .35))
            im.disc(ox + 32, 48, 3, TURQ[3])
            for _ in range(10):
                im.put(ox + r.randint(14, 50), r.randint(10, 90), TURQ[3])
        for x in range(64):
            for t in range(4):
                im.put(ox + x, 6 + t, mix(MOSS[1], VIDA['base'][1], t / 4.0)) if r.random() < .5 else None
    return im


# ---------- convergencia ----------
def moldura(P, vida):
    r = random.Random(71 + vida)
    im = Img(26, 26)
    for y in range(26):
        for x in range(26):
            e = min(x, y, 25 - x, 25 - y)
            if e < 3:
                im.put(x, y, mix(STONE[3] if not vida else STONE_G[3], STONE[0] if not vida else STONE_G[0], e / 3.0))
            else:
                im.put(x, y, mix(P['lo'], P['base'][1], .6))
    for x in range(26):
        im.put(x, 0, VIOL[4] if not vida else EMER[4])
    im.rect(5, 5, 16, 16, mix(P['lo'], CYAN_D, .25))
    im.rect(6, 6, 14, 14, mix(P['lo'], P['base'][0], .5))
    im.disc(13, 13, 2, CYAN_D)
    im.put(13, 13, CYAN_L)
    if vida:
        for k in range(18):
            im.put(1 + k, 24 - (k % 4), ROOT_C[2])
            im.put(24 - (k % 3), 3 + k, ROOT_C[1])
        for (x, y) in ((2, 3), (22, 21), (21, 3)):
            im.put(x, y, TURQ[3])
    else:
        for (x, y) in ((2, 2), (23, 2), (2, 23), (23, 23)):
            im.put(x, y, VIOL[4])
        for k in range(4, 22, 4):
            im.put(k, 4, VIOL[2])
            im.put(k, 21, VIOL[2])
    return im


def plataforma(P, seed, vida, w=128, h=320):
    """plataforma de cada metade da convergencia: laje com moldura rúnica."""
    r = random.Random(seed)
    im = floor_tex(P, seed + 2, w=w, h=h, moss=.22 if vida else 0, roots=3 if vida else 0, runes=2, cyan=5,
                   cracks=6)
    for e in range(4):  # moldura
        c = mix(P['hi'], P['glow'], .3 - e * .06) if e == 0 else mix(P['hi'], P['lo'], e * .25)
        for x in range(w):
            im.put(x, e, c)
            im.put(x, h - 1 - e, c)
        for y in range(h):
            im.put(e, y, c)
            im.put(w - 1 - e, y, c)
    for y in range(8, h - 8):  # canal de runas interno
        im.put(8, y, mix(P['lo'], P['acc'], .8))
        im.put(w - 9, y, mix(P['lo'], P['acc'], .8))
        if y % 10 == 0:
            im.put(8, y, P['glint'])
            im.put(w - 9, y, P['glint'])
    for x in range(8, w - 8):
        im.put(x, 8, mix(P['lo'], P['acc'], .8))
        im.put(x, h - 9, mix(P['lo'], P['acc'], .8))
    # vegetacao invadindo a borda (vida) ou rachaduras luminosas (main)
    if vida:
        for _ in range(26):
            x = r.choice((r.randint(0, 5), r.randint(w - 6, w - 1)))
            wander(im, x, r.randint(0, h), r.randint(10, 24), ROOT_C[2], r, w=2, ang=0 if x < 5 else 3.14,
                   curl=.5, glow=TURQ[2])
    else:
        for _ in range(8):
            wander(im, r.randint(10, w - 10), r.randint(10, h - 10), r.randint(12, 24), P['lo'], r, curl=.6,
                   glow=CYAN)
    return im


def fenda(seed=81):
    """10x64 tileavel na vertical: fenda escura com faiscas ciano."""
    r = random.Random(seed)
    im = Img(10, 64)
    for y in range(64):
        c = 4 + int(math.sin(y / 5.0) * 1.5)
        for x in range(10):
            d = abs(x - 5)
            if d < c / 2.0:
                im.put(x, y, H('#05030c'))
            elif d < c / 2.0 + 1:
                im.put(x, y, mix(H('#05030c'), VIOL[2] if x < 5 else EMER[2], .55))
    for _ in range(6):
        im.put(r.choice((3, 4, 5, 6)), r.randint(0, 63), CYAN_L if r.random() < .5 else CYAN)
    return im


def fusao(seed=82):
    """26x64 tileavel: costura de energia (violeta + verde trancados em ciano)."""
    r = random.Random(seed)
    im = Img(26, 64)
    for y in range(64):
        for x in range(26):
            d = abs(x - 12.5)
            a = max(0, 1 - d / 13.0) ** 2
            base = mix(VIOL[2], EMER[2], x / 25.0)
            im.put(x, y, (base[0], base[1], base[2], int(a * 190)))
    for k in range(3):
        ph = k * 2.1
        for y in range(64):
            x = 12 + round(math.sin(y / 5.0 + ph) * 5)
            im.put(x, y, CYAN)
            im.put(x + 1, y, CYAN_L if (y + k) % 7 == 0 else CYAN_D)
    return im


def energia_h(w=128, h=8, partido=False, seed=83):
    r = random.Random(seed)
    im = Img(w, h)
    cy = h // 2
    for x in range(w):
        if partido and 20 < x < 44 or partido and 84 < x < 108:
            continue
        im.put(x, cy - 1, (CYAN[0], CYAN[1], CYAN[2], 70))
        im.put(x, cy + 1, (CYAN[0], CYAN[1], CYAN[2], 70))
        im.put(x, cy, CYAN if (x // 6) % 2 else CYAN_L)
    for _ in range(4):
        im.put(r.randint(0, w - 1), cy + r.choice((-2, 2)), CYAN_L)
    return im


def energia_v(h=128, w=8):
    return energia_h(h, w).__class__ and _rot(energia_h(h, w))


def _rot(i):
    o = Img(i.h, i.w)
    for y in range(i.h):
        for x in range(i.w):
            o.p[x * o.w + y] = i.p[y * i.w + x]
    return o


def glifo_conv(s=18):
    im = Img(s, s)
    im.disc(s // 2, s // 2, s // 2 - 1, mix(CONVM['lo'], CYAN_D, .5))
    im.disc(s // 2, s // 2, s // 2 - 4, CONVM['lo'])
    im.disc(s // 2, s // 2, 2, CYAN_L)
    for k in range(-s // 2 + 1, s // 2):
        im.put(s // 2 + k, s // 2, CYAN_D)
    return im


def mini(nome, w, h, cor, vida=False, tipo='coluna'):
    r = random.Random(sum(map(ord, nome)))
    im = Img(w, h)
    if tipo == 'coluna':
        for y in range(h):
            for x in range(w):
                im.put(x, y, mix(STONE[3], STONE[0], x / float(w)))
        im.rect(0, 0, w, 1, STONE[4])
        for y in range(4, h, 6):
            im.rect(0, y, w, 1, STONE[0])
    elif tipo == 'capitel':
        im.rect(0, 0, w, h, STONE[3])
        im.rect(0, 0, w, 1, STONE[4])
        im.rect(0, h - 1, w, 1, STONE[0])
        im.put(w // 2, h // 2, VIOL[4])
    elif tipo == 'laje':
        im.rect(0, 0, w, h, STONE[2])
        im.rect(0, 0, w, 1, STONE[4])
        im.rect(0, h - 1, w, 1, STONE[0])
        im.put(w // 2, 2, VIOL[3])
    elif tipo == 'eco':
        pal = EMER if False else (TURQ if vida else VIOL)
        for (x, y, s) in ((w // 2, h // 2, h // 2 - 1),):
            for k in range(h - 2):
                ww = max(1, (w // 2) - abs(k - h // 2) * (w // 2) // (h // 2))
                for xx in range(w // 2 - ww // 2, w // 2 + ww // 2 + 1):
                    im.put(xx, 1 + k, pal[3] if xx < w // 2 else pal[2])
            im.put(w // 2, 2, pal[4])
    elif tipo == 'copa':
        im.shade_ell(w / 2, h / 2, w / 2 - 1, h / 2 - 1, [EMER[0], EMER[1], EMER[2], EMER[3]], r)
        for _ in range(w // 2):
            im.put(r.randint(2, w - 3), r.randint(2, h - 3), TURQ[4])
    elif tipo == 'tronco':
        for y in range(h):
            im.rect(0, y, w, 1, ROOT_C[2] if y % 2 else ROOT_C[1])
    elif tipo == 'raizes':
        for k in range(w):
            im.put(k, h // 2 + int(math.sin(k / 2.0) * 2), ROOT_C[3])
            im.put(k, h // 2 + 1 + int(math.sin(k / 2.0) * 2), ROOT_C[1])
        for k in range(2, w, 6):
            im.put(k, h // 2 + 1, TURQ[3])
    elif tipo == 'veio':
        for y in range(h):
            im.put(0, y, TURQ[3])
    im.outline(OUTL_V if not vida else OUTL_G) if tipo not in ('veio', 'raizes') else None
    return im


def coex_coluna(lado):
    """metade pedra | metade raizes de uma mesma coluna; cada lado e cortado na linha da fusao."""
    w, h = 16 if lado == 'pedra' else 18, 46 if lado == 'pedra' else 48
    r = random.Random(91 + (lado == 'pedra'))
    im = Img(w, h)
    if lado == 'pedra':
        for y in range(h):
            for x in range(w):
                im.put(x, y, mix(STONE[3], STONE[1], x / float(w)))
        for y in range(3, h, 7):
            im.rect(0, y, w, 1, STONE[0])
        im.rect(0, 0, w, 3, STONE[4])
        for y in range(h):
            im.put(w - 1, y, CYAN if y % 3 else CYAN_L)
    else:
        for y in range(h):
            for x in range(w):
                im.put(x, y, mix(STONE_G[2], STONE_G[0], x / float(w)))
        for k in range(h):
            im.put(2 + int(math.sin(k / 3.0) * 3) + 4, k, ROOT_C[2])
            im.put(3 + int(math.sin(k / 3.0) * 3) + 4, k, ROOT_C[0])
        im.shade_ell(8, 4, 8, 4, [EMER[0], EMER[1], EMER[2], EMER[3]], r)
        for _ in range(6):
            im.put(r.randint(1, 16), r.randint(1, 6), TURQ[4])
        for y in range(h):
            im.put(0, y, CYAN if y % 3 else CYAN_L)
    im.outline(OUTL_V if lado == 'pedra' else OUTL_G)
    return im


def coex_ponte(lado):
    w, h = 29, 16
    im = Img(w, h)
    if lado == 'pedra':
        for y in range(h):
            for x in range(w):
                im.put(x, y, mix(STONE[3], STONE[1], y / float(h)))
        for x in range(0, w, 7):
            im.rect(x, 0, 1, h, STONE[0])
        im.rect(0, 0, w, 1, STONE[4])
        for y in range(h):
            im.put(w - 1, y, CYAN)
    else:
        for y in range(h):
            for x in range(w):
                im.put(x, y, mix(VIDA['base'][3], VIDA['base'][1], y / float(h)))
        for k in range(w):
            im.put(k, 4 + int(math.sin(k / 3.0) * 2), ROOT_C[3])
            im.put(k, 5 + int(math.sin(k / 3.0) * 2), ROOT_C[1])
            im.put(k, 10 + int(math.sin(k / 3.0 + 2) * 2), ROOT_C[2])
        for k in range(1, w, 5):
            im.put(k, 7, TURQ[3])
        for y in range(h):
            im.put(0, y, CYAN)
    im.outline(OUTL_V if lado == 'pedra' else OUTL_G)
    return im


def coex_eco(vida):
    w, h = 17, 26
    pal = TURQ if vida else VIOL
    im = Img(w, h)
    for k in range(h - 2):
        ww = max(1, 7 - abs(k - 12) * 7 // 12)
        for xx in range(8 - ww, 8 + ww):
            im.put(xx, 1 + k, pal[3] if xx < 8 else pal[2])
    im.put(8, 3, pal[4])
    im.put(7, 4, pal[4])
    for y in range(h):
        im.put(w - 1 if not vida else 0, y, CYAN if y % 3 else CYAN_L)
    im.outline(OUTL_G if vida else OUTL_V)
    return im


def atlas_conv():
    """30x40: nucleo do Atlas na Convergencia (pedestal violeta + cristal ciano com raizes)."""
    r = random.Random(95)
    im = Img(30, 40)
    im.shade_ell(15, 34, 14, 5, [STONE[0], STONE[1], STONE[2], STONE[3]], r, .05)
    im.rect(6, 22, 18, 12, STONE[2])
    im.rect(6, 22, 18, 1, STONE[4])
    im.rect(18, 23, 6, 11, STONE[1])
    for k in range(10):
        im.put(5 + k * 2, 33 - (k % 3), ROOT_C[2])
    for y in range(1, 24):
        hw = max(1, int(7 * (1 - abs(y - 12) / 13.0)))
        for x in range(15 - hw, 15 + hw):
            im.put(x, y, CYAN_L if x < 15 - hw + 1 else CYAN if x < 15 else CYAN_D)
    im.put(13, 8, H('#ffffff'))
    im.put(13, 9, H('#ffffff'))
    im.outline(OUTL_V)
    return im


def hera_conv(seed, w=22, h=24):
    r = random.Random(seed)
    im = Img(w, h)
    for _ in range(4):
        x = r.randint(2, w - 3)
        L = r.randint(8, h - 2)
        for y in range(L):
            im.put(x, y, ROOT_C[2] if y % 2 else ROOT_C[1])
            if y % 4 == 3:
                im.put(x - 1, y, MOSS[2])
        im.put(x, L, CYAN)
    return im


def eco_destaque(pal, cor_borda):
    """28x34: ECO principal (item de progresso). Orbe luminoso com nucleo branco, anel e estilhacos."""
    r = random.Random(7)
    im = Img(28, 34)
    cx, cy = 14, 17
    # anel (parte de tras)
    for a in range(180, 360, 4):
        im.put(cx + round(math.cos(math.radians(a)) * 12), cy + round(math.sin(math.radians(a)) * 4) + 3, pal[2])
    # orbe
    im.shade_ell(cx, cy, 8, 8, [pal[0], pal[1], pal[2], pal[3], pal[4]], r, .03)
    im.disc(cx - 2, cy - 3, 2, H('#ffffff'))
    im.put(cx + 2, cy + 2, pal[4])
    # anel (parte da frente)
    for a in range(0, 180, 4):
        im.put(cx + round(math.cos(math.radians(a)) * 12), cy + round(math.sin(math.radians(a)) * 4) + 3, pal[3])
    # estilhacos orbitando
    for (x, y) in ((3, 8), (24, 10), (5, 27), (23, 26)):
        im.put(x, y, pal[4])
        im.put(x, y - 1, pal[3])
        im.put(x - 1, y, pal[2])
        im.put(x + 1, y, pal[2])
    im.outline(cor_borda)
    return im


# ---------- geracao ----------
def main():
    # --- MAIN
    out('main/tiles/abismo_main_grande.png', abismo_grande(MAIN, 1, VIOL[3]))
    out('main/tiles/borda_abismo_main_sup.png', borda_sup(MAIN, 2))
    out('main/tiles/borda_abismo_main_inf.png', borda_inf(MAIN, 3))
    out('main/tiles/borda_abismo_main_esq.png', borda_lado(MAIN, 4, True))
    out('main/tiles/borda_abismo_main_dir.png', borda_lado(MAIN, 5, False))
    out('main/tiles/ponte_ponta_norte.png', ponte_main_ponta(True))
    out('main/tiles/ponte_ponta_sul.png', ponte_main_ponta(False))
    out('main/props/ponte_vao_detalhes.png', ponte_vao_det())
    out('main/decor/rachadura_main_a.png', d_rachadura(MAIN, 1))
    out('main/decor/rachadura_main_b.png', d_rachadura(MAIN, 2, 40, 14))
    out('main/decor/runa_chao_main.png', d_runa(MAIN, 1))
    out('main/decor/entulho_main_a.png', d_entulho(MAIN, 1))
    out('main/decor/entulho_main_b.png', d_entulho(MAIN, 2, 22, 12))
    out('main/decor/coluna_tombada_main.png', d_coluna_tombada(MAIN, 1))
    # --- VIDA
    out('vida/tiles/piso_vida.png', floor_tex(VIDA, 101, w=192, h=192, moss=.2, roots=6, runes=2, cracks=10))
    out('vida/tiles/muro_vida.png', wall_wide(VIDA, 102, moss=True, roots_em=(1, 3)))
    out('vida/tiles/abismo_vida.png', abismo_tex(VIDA, 103, 80, TURQ[2]))
    out('vida/tiles/borda_abismo_vida_sup.png', borda_sup(VIDA, 104, True))
    out('vida/tiles/borda_abismo_vida_inf.png', borda_inf(VIDA, 105, True))
    out('vida/tiles/borda_abismo_vida_esq.png', borda_lado(VIDA, 106, True, True))
    out('vida/tiles/borda_abismo_vida_dir.png', borda_lado(VIDA, 107, False, True))
    out('vida/tiles/ponte_raizes.png', ponte_raizes())
    out('vida/tiles/espinheiro.png', espinheiro_tex())
    for i in range(3):
        out('vida/props/arvore_vida_%d.png' % i, arvore_vida(200 + i * 13, i % 2))
    for i in range(2):
        out('vida/props/arbusto_vida_%d.png' % i, arbusto_vida(300 + i, i))
    for i in range(2):
        out('vida/props/cristal_vida_%d.png' % i, cristal_vida(400 + i))
    out('vida/props/pilar_vida.png', pilar_vida())
    out('vida/props/pedestal_vida.png', pedestal_vida())
    out('vida/props/eco_vida.png', cacos_luz(TURQ, 22, 22))
    out('vida/props/eco_vida_destaque.png', eco_destaque(TURQ, OUTL_G))
    out('main/props/eco_main_destaque.png', eco_destaque(VIOL, OUTL_V))
    out('vida/props/fragmento_vida.png', cacos_luz(EMER, 22, 22, 9))
    out('vida/barreiras/barreira_passagem_vida.png', barreira_vida())
    for i in range(3):
        out('vida/decor/raiz_%d.png' % i, d_raiz(500 + i))
    for i in range(3):
        out('vida/decor/musgo_%d.png' % i, d_musgo(510 + i))
    out('vida/decor/cogumelos_a.png', d_cogumelos(1))
    out('vida/decor/cogumelos_b.png', d_cogumelos(2))
    for i in range(3):
        out('vida/decor/hera_%d.png' % i, d_hera(520 + i))
    out('vida/decor/entulho_vida_a.png', d_entulho(VIDA, 7, moss=True))
    out('vida/decor/entulho_vida_b.png', d_entulho(VIDA, 8, 22, 12, moss=True))
    out('vida/decor/coluna_tombada_vida.png', d_coluna_tombada(VIDA, 2, moss=True))
    out('vida/decor/cristais_a.png', d_cristais(1, 3))
    out('vida/decor/cristais_b.png', d_cristais(2, 2))
    # --- CONVERGENCIA
    out('convergencia/tiles/piso_conv_main.png', floor_tex(CONVM, 601, w=192, h=192, runes=2, cyan=6, cracks=8))
    out('convergencia/tiles/piso_conv_vida.png', floor_tex(CONVV, 602, w=192, h=192, moss=.16, roots=4, cyan=6, cracks=8))
    out('convergencia/tiles/muro_conv_main.png', wall_tex(CONVM, 603, cyan=True))
    out('convergencia/tiles/muro_conv_vida.png', wall_wide(CONVV, 604, moss=True, roots_em=(1, 3), cyan=True))
    out('convergencia/tiles/plataforma_main.png', plataforma(CONVM, 611, False))
    out('convergencia/tiles/plataforma_vida.png', plataforma(CONVV, 612, True))
    out('convergencia/tiles/fenda_divisoria.png', fenda())
    out('convergencia/tiles/fusao_resultado.png', fusao())
    out('convergencia/decor/energia_h.png', energia_h())
    out('convergencia/decor/energia_h_96.png', energia_h(96))
    out('convergencia/decor/energia_h_partida.png', energia_h(partido=True))
    out('convergencia/decor/energia_v.png', _rot(energia_h(96, 8)))
    out('convergencia/decor/glifo_conv.png', glifo_conv())
    out('convergencia/props/moldura_main.png', moldura(CONVM, False))
    out('convergencia/props/moldura_vida.png', moldura(CONVV, True))
    out('convergencia/props/main_coluna.png', mini('mc', 10, 24, None, False, 'coluna'))
    out('convergencia/props/main_capitel.png', mini('mt', 16, 5, None, False, 'capitel'))
    out('convergencia/props/main_laje_a.png', mini('la', 12, 6, None, False, 'laje'))
    out('convergencia/props/main_laje_b.png', mini('lb', 11, 6, None, False, 'laje'))
    out('convergencia/props/main_eco.png', mini('me', 10, 13, None, False, 'eco'))
    out('convergencia/props/vida_copa.png', mini('vc', 19, 19, None, True, 'copa'))
    out('convergencia/props/vida_tronco.png', mini('vt', 5, 10, None, True, 'tronco'))
    out('convergencia/props/vida_raizes.png', mini('vr', 26, 6, None, True, 'raizes'))
    out('convergencia/props/vida_raizes_veio.png', mini('vv', 2, 6, None, True, 'veio'))
    out('convergencia/props/vida_eco.png', mini('ve', 10, 13, None, True, 'eco'))
    out('convergencia/props/coex_coluna_pedra.png', coex_coluna('pedra'))
    out('convergencia/props/coex_coluna_raizes.png', coex_coluna('raizes'))
    out('convergencia/props/coex_ponte_pedra.png', coex_ponte('pedra'))
    out('convergencia/props/coex_ponte_raizes.png', coex_ponte('raizes'))
    out('convergencia/props/coex_eco_main.png', coex_eco(False))
    out('convergencia/props/coex_eco_vida.png', coex_eco(True))
    out('convergencia/props/atlas_convergencia.png', atlas_conv())
    for i in range(3):
        out('convergencia/decor/hera_conv_%d.png' % i, hera_conv(700 + i))
    out('convergencia/decor/raiz_conv.png', d_raiz(710))
    out('convergencia/decor/rachadura_conv.png', d_rachadura(CONVM, 3, cyan=True))
    out('convergencia/decor/cristais_conv.png', recolor_cyan(d_cristais(5, 3)))
    out('convergencia/decor/entulho_conv.png', d_entulho(CONVM, 9))
    out('convergencia/decor/entulho_conv_vida.png', d_entulho(CONVV, 10))


def recolor_cyan(im):
    ramp = [CYAN_D, CYAN, CYAN_L, H('#e8ffff')]
    for i, c in enumerate(im.p):
        if c[3] and c != OUTL_G:
            lum = (c[1] + c[2]) / 2.0
            k = min(3, int(lum / 70))
            im.p[i] = (ramp[k][0], ramp[k][1], ramp[k][2], c[3])
    return im


if __name__ == '__main__':
    main()
    print('arte gerada')
