"""Gera a arte (pixel art procedural) das Areas 1, 2 e 5 da Fase 2 (realidade neutra) em arte/neutra/.
Nao toca nos PNGs das Areas 3/4. Rodar na raiz do projeto: python tools/gen_arte_fase2_areas125.py
"""
import os, sys, random, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pix import *
import gen_arte_fase2_partes as G

MAIN, VIOL, STONE, CYAN, CYAN_L, CYAN_D = G.MAIN, G.VIOL, G.STONE, G.CYAN, G.CYAN_L, G.CYAN_D
OUTL_V = G.OUTL_V
MAG = [H('#3a0a35'), H('#7a1470'), H('#c41fae'), H('#ff2bd6'), H('#ffb0f2')]


def ca(c, a):
    return (c[0], c[1], c[2], a)


def out(rel, img):
    img.save(os.path.join(G.ROOT, 'neutra', rel))


# ---------------------------------------------------------------- hologramas e neon
def holograma_tech(w=44, h=56, seed=5):
    """Projecao holografica de um mundo de metal e circuitos (visao da realidade 'tech'). Base = emissor."""
    r = random.Random(seed)
    im = Img(w, h)
    cx = w // 2
    # cone de luz do emissor ate a tela
    for y in range(38, 51):
        meio = 7 + (50 - y) * 0.9
        for x in range(int(cx - meio), int(cx + meio) + 1):
            borda = abs(x - cx) >= int(meio)
            im.put(x, y, ca(CYAN, 70 if borda else 22))
    # tela translucida
    for y in range(2, 38):
        for x in range(2, 42):
            im.put(x, y, ca(CYAN, 38 + (14 if y % 2 == 0 else 0)))
    for x in range(2, 42):
        im.put(x, 2, ca(CYAN, 150))
        im.put(x, 37, ca(CYAN, 110))
    for y in range(2, 38):
        im.put(2, y, ca(CYAN, 130))
        im.put(41, y, ca(CYAN, 130))
    for (bx, by, dx, dy) in ((2, 2, 1, 1), (41, 2, -1, 1), (2, 37, 1, -1), (41, 37, -1, -1)):  # cantos
        for k in range(5):
            im.put(bx + dx * k, by, CYAN_L)
            im.put(bx, by + dy * k, CYAN_L)
    # skyline de metal e circuitos
    x = 5
    while x < 38:
        bw = r.choice((3, 4, 5))
        bh = r.randint(8, 22)
        top = 34 - bh
        for yy in range(top, 35):
            for xx in range(x, min(x + bw, 39)):
                im.put(xx, yy, ca(CYAN, 70))
        for yy in range(top, 35):
            im.put(x, yy, ca(CYAN, 210))
        for xx in range(x, min(x + bw, 39)):
            im.put(xx, top, CYAN_L if bh > 18 else ca(CYAN, 230))
        for _ in range(bh // 5):  # janelas
            im.put(x + r.randint(1, max(1, bw - 1)), r.randint(top + 2, 32), CYAN_L)
        if bh > 19:  # antena com luz magenta
            im.put(x + bw // 2, top - 1, MAG[3])
            im.put(x + bw // 2, top - 2, MAG[3])
            im.put(x + bw // 2, top - 3, MAG[4])
        x += bw + r.randint(0, 1)
    for xx in range(4, 40):  # chao da cidade
        im.put(xx, 35, ca(CYAN_L, 200))
    # faixa neon magenta e circuitos
    for xx in range(6, 38):
        if xx % 7 != 0:
            im.put(xx, 12, ca(MAG[3], 190))
    for (x0, y0, x1, y1) in ((6, 6, 14, 6), (14, 6, 14, 9), (30, 5, 36, 5), (36, 5, 36, 8)):
        im.line(x0, y0, x1, y1, ca(CYAN_L, 190))
    for yy in (21, 22):  # linha de interferencia
        for xx in range(2, 42):
            if r.random() < .55:
                im.put(xx, yy, ca(CYAN, 15))
    # emissor de pedra
    for y in range(50, 56):
        for x in range(12, 32):
            t = (y - 50) / 5.0
            im.put(x, y, STONE[3] if y == 50 else (STONE[2] if t < .6 else STONE[1]))
    for x in range(12, 32):
        im.put(x, 55, OUTL_V)
    for y in range(50, 56):
        im.put(12, y, OUTL_V)
        im.put(31, y, OUTL_V)
    for x in range(13, 31):
        im.put(x, 49, OUTL_V if abs(x - cx) > 6 else ca(CYAN, 120))
    im.put(cx - 1, 50, CYAN_L)
    im.put(cx, 50, CYAN_L)
    im.put(15, 53, CYAN)
    im.put(28, 53, MAG[3])
    return im


def neon_magenta(w=6, h=56):
    """Tubo de neon magenta vertical com suportes de metal nas pontas."""
    im = Img(w, h)
    col = (MAG[2], MAG[3], MAG[4], MAG[4], MAG[3], MAG[2])
    alfa = (46, 150, 255, 255, 150, 46)
    for y in range(3, h - 3):
        fraco = (y % 19 == 9)  # leve falha de luz, sem exagero
        for x in range(w):
            c = col[x]
            if fraco and x in (2, 3):
                c = MAG[3]
            im.put(x, y, ca(c, alfa[x]))
    for y0 in (0, h - 3):  # suportes
        for y in range(y0, y0 + 3):
            for x in range(1, 5):
                im.put(x, y, STONE[2] if y == y0 else STONE[1])
            im.put(0, y, OUTL_V)
            im.put(5, y, OUTL_V)
    return im


def porta_tech(w=96, h=60, seed=6):
    """Porta de vidro selada: moldura de pedra Codex e, atras do vidro, maquinas e neon (visao tech)."""
    r = random.Random(seed)
    im = Img(w, h)
    # vidro
    for y in range(10, 54):
        t = (y - 10) / 43.0
        base = mix(H('#0c2d49'), H('#050f22'), t)
        for x in range(10, w - 10):
            im.put(x, y, base)
    # siluetas de maquinas ao fundo
    for (mx, mw, mh) in ((14, 10, 20), (28, 8, 14), (58, 9, 18), (70, 12, 24)):
        for y in range(53 - mh, 53):
            for x in range(mx, mx + mw):
                im.put(x, y, mix(H('#061a30'), H('#0a2845'), (y - (53 - mh)) / mh))
        for _ in range(mw // 3):
            im.put(mx + r.randint(1, mw - 2), 53 - r.randint(3, mh - 2), ca(CYAN, 160))
    # tiras de neon vistas atraves do vidro e linhas de circuito
    for y in range(12, 52):
        for x in (24, 72):
            im.put(x, y, ca(MAG[3], 105))
            im.put(x + 1, y, ca(MAG[2], 60))
    for (x0, y0, x1, y1) in ((14, 20, 30, 20), (30, 20, 30, 28), (62, 24, 80, 24), (62, 24, 62, 34)):
        im.line(x0, y0, x1, y1, ca(CYAN, 120))
    # reflexos diagonais do vidro
    for k in range(3):
        x0 = 16 + k * 22
        for i in range(30):
            im.put(x0 + i // 1, 12 + i, ca(CYAN_L, 26 - k * 5))
            im.put(x0 + i + 1, 12 + i, ca(CYAN_L, 14))
    # piso refletindo
    for x in range(10, w - 10):
        im.put(x, 52, ca(CYAN, 120))
        im.put(x, 53, ca(CYAN_D, 160))
    # juncao central e cadeado (selada)
    for y in range(10, 54):
        im.put(w // 2 - 1, y, H('#030a14'))
        im.put(w // 2, y, mix(H('#030a14'), STONE[1], .5))
    for (px, py) in ((w // 2 - 2, 26), (w // 2 + 1, 26)):
        im.put(px, py, MAG[2])
    for y in range(28, 35):  # cadeado hexagonal apagado
        for x in range(w // 2 - 3, w // 2 + 3):
            im.put(x, y, ca(MAG[1], 230))
    for x in range(w // 2 - 3, w // 2 + 3):
        im.put(x, 28, MAG[2])
    im.put(w // 2 - 1, 31, MAG[4])
    im.put(w // 2, 31, MAG[4])
    # moldura de pedra: batentes e verga
    for y in range(0, h):
        for x in list(range(0, 10)) + list(range(w - 10, w)):
            t = (x % 10) / 9.0 if x < 10 else ((w - 1 - x) % 10) / 9.0
            im.put(x, y, mix(STONE[1], STONE[3], t * .6) if y % 12 else mix(STONE[0], STONE[1], .5))
    for y in range(0, 10):
        for x in range(w):
            im.put(x, y, STONE[2] if y == 0 else (STONE[1] if y < 8 else STONE[0]))
    for x in range(w):
        im.put(x, 9, OUTL_V)
        im.put(x, 8, mix(STONE[0], OUTL_V, .5))
    for y in range(h):  # contorno e canal rúnico dos batentes
        im.put(0, y, OUTL_V)
        im.put(w - 1, y, OUTL_V)
        im.put(9, y, OUTL_V)
        im.put(w - 10, y, OUTL_V)
        if y > 10 and y % 8 == 3:
            im.put(5, y, VIOL[3])
            im.put(w - 6, y, VIOL[3])
    for x in range(w):
        im.put(x, 0, OUTL_V)
    for lx, cor in ((w // 2 - 18, MAG[3]), (w // 2, MAG[2]), (w // 2 + 18, MAG[3])):  # luzes da verga
        im.rect(lx - 1, 3, 3, 2, cor)
        im.put(lx, 3, MAG[4])
    # soleira
    for y in range(54, h):
        for x in range(0, w):
            im.put(x, y, STONE[3] if y == 54 else (STONE[2] if y < 57 else STONE[1]))
        im.put(0, y, OUTL_V)
        im.put(w - 1, y, OUTL_V)
    for x in range(w):
        im.put(x, h - 1, OUTL_V)
    return im


# ---------------------------------------------------------------- trilhas (Line2D em modo tile)
def trilha(w, h, rampa, glow, tracejado=True, escuro=True):
    """Faixa tileavel no comprimento (w) para Line2D: conduite com pulsos. rampa: escuro..claro (4 cores)."""
    im = Img(w, h)
    for y in range(h):
        d = abs(y - (h - 1) / 2.0) / ((h - 1) / 2.0)
        for x in range(w):
            if d > .85:
                c = ca(OUTL_V if escuro else glow, 190 if escuro else 70)
            elif d > .6:
                c = ca(rampa[0], 220)
            elif d > .3:
                c = ca(rampa[1], 235)
            else:
                pulso = (x % 16) < 9 if tracejado else True
                c = rampa[3] if pulso else rampa[2]
            im.put(x, y, c)
    return im


def anel_origem(s=128):
    """Anel runico em volta do No de Origem (substitui o quadrado violeta provisorio)."""
    im = Img(s, s)
    c = s / 2.0
    for y in range(s):
        for x in range(s):
            dx, dy = x + .5 - c, y + .5 - c
            rr = math.hypot(dx, dy)
            ang = math.degrees(math.atan2(dy, dx)) % 360
            if rr < 50:  # preenchimento suave
                im.put(x, y, ca(VIOL[2], int(38 * (rr / 50.0) ** 1.5)))
            if 58 <= rr < 60.5:
                im.put(x, y, ca(VIOL[3], 190))
            elif 60.5 <= rr < 62.5:
                im.put(x, y, ca(VIOL[2], 60))
            elif 49.5 <= rr < 51.3:
                im.put(x, y, ca(VIOL[2], 150))
            elif 41.5 <= rr < 43.3 and (ang % 12) < 7:
                im.put(x, y, ca(VIOL[4], 190))
            elif 52 <= rr < 57 and (ang % 15) < 2.2:
                im.put(x, y, ca(VIOL[3], 170))
    for k in range(8):  # marcas cardinais
        a = math.radians(k * 45 + 22.5)
        px, py = int(c + math.cos(a) * 46.5), int(c + math.sin(a) * 46.5)
        im.put(px, py, CYAN_L)
        im.put(px + 1, py, CYAN)
        im.put(px, py + 1, CYAN)
    return im


# ---------------------------------------------------------------- Area 5: plataforma do registro
def plataforma_registro(w=256, h=256, seed=71):
    r = random.Random(seed)
    im = G.floor_tex(MAIN, seed, w=w, h=h, cracks=5)
    for y in range(h):  # escurece levemente: o registro precisa ser o foco
        for x in range(w):
            im.p[y * w + x] = mix(im.p[y * w + x], MAIN['lo'], .22)
    # elipse de runas ao redor da base do registro (centro local 128,160)
    cx, cy = 128, 160
    for a in range(0, 360, 2):
        rad = math.radians(a)
        for (rx, ry, col) in ((72, 46, ca(VIOL[3], 235)), (62, 39, ca(VIOL[2], 235))):
            im.put(int(cx + math.cos(rad) * rx), int(cy + math.sin(rad) * ry), col)
    for k in range(12):
        rad = math.radians(k * 30 + 15)
        px, py = int(cx + math.cos(rad) * 67), int(cy + math.sin(rad) * 42.5)
        im.put(px, py, CYAN_L)
        im.put(px + 1, py, CYAN)
        im.put(px, py + 1, CYAN_D)
    # conduites de ciano ate as bordas (energia convergindo ao registro)
    for y in range(cy + 46, 242):
        if (y // 3) % 2:
            im.put(127, y, CYAN)
            im.put(128, y, CYAN_L)
    for x in list(range(10, cx - 72)) + list(range(cx + 73, w - 10)):
        if (x // 3) % 2:
            im.put(x, cy, CYAN_D)
            im.put(x, cy + 1, CYAN)
    # moldura rúnica
    for e in range(4):
        c = mix(MAIN['hi'], MAIN['glow'], .3) if e == 0 else mix(MAIN['hi'], MAIN['lo'], e * .25)
        for x in range(w):
            im.put(x, e, c)
        for y in range(h):
            im.put(e, y, c)
            im.put(w - 1 - e, y, c)
    for y in range(8, h - 18):  # canal interno
        im.put(8, y, mix(MAIN['lo'], MAIN['acc'], .8))
        im.put(w - 9, y, mix(MAIN['lo'], MAIN['acc'], .8))
        if y % 12 == 0:
            im.put(8, y, MAIN['glint'])
            im.put(w - 9, y, MAIN['glint'])
    for x in range(8, w - 8):
        im.put(x, 8, mix(MAIN['lo'], MAIN['acc'], .8))
    # face frontal (degrau): da a ideia de laje elevada
    for y in range(h - 16, h):
        t = (y - (h - 16)) / 15.0
        for x in range(w):
            c = mix(STONE[2], STONE[0], t)
            if (x + (8 if (y // 8) % 2 else 0)) % 24 == 0:
                c = mix(c, OUTL_V, .6)
            im.put(x, y, c)
    for x in range(w):
        im.put(x, h - 16, mix(MAIN['hi'], MAIN['glow'], .35))
        im.put(x, h - 1, OUTL_V)
    for y in range(h - 16, h):
        im.put(0, y, OUTL_V)
        im.put(w - 1, y, OUTL_V)
    for _ in range(6):  # rachaduras
        G.wander(im, r.randint(14, w - 14), r.randint(14, h - 30), r.randint(10, 22), MAIN['lo'], r, curl=.6)
    return im


def plataforma_friso(w=256, h=32, seed=72):
    """Friso do fundo da plataforma: gradiente translucido com relevos rúnicos (substitui a faixa lisa)."""
    im = Img(w, h)
    for y in range(h):
        a = int(max(0, 120 * (1 - y / float(h))))
        for x in range(w):
            im.put(x, y, ca(VIOL[2], a))
    for x in range(w):
        im.put(x, 0, ca(VIOL[4], 150))
        im.put(x, 1, ca(VIOL[3], 130))
    for bx in range(16, w - 8, 32):
        im.put(bx, 7, ca(VIOL[4], 200))
        im.put(bx - 1, 8, ca(VIOL[3], 200))
        im.put(bx + 1, 8, ca(VIOL[3], 200))
        im.put(bx, 9, ca(VIOL[4], 200))
        for k in (-6, -5, 5, 6):
            im.put(bx + k, 8, ca(CYAN, 150))
    return im


def main():
    out('props/holograma_tech.png', holograma_tech())
    out('props/neon_magenta.png', neon_magenta())
    out('props/porta_tech.png', porta_tech())
    out('decor/trilha_violeta.png', trilha(16, 10, [VIOL[0], VIOL[1], VIOL[2], VIOL[3]], VIOL[2]))
    out('decor/trilha_verde.png', trilha(16, 10, [G.EMER[0], G.EMER[1], G.EMER[2], G.EMER[3]], G.EMER[2]))
    out('decor/trilha_fina_ciano.png', trilha(16, 4, [CYAN_D, CYAN_D, CYAN, CYAN_L], CYAN, escuro=False))
    out('decor/trilha_fina_magenta.png', trilha(16, 4, [MAG[1], MAG[1], MAG[3], MAG[4]], MAG[3], escuro=False))
    out('decor/trilha_fina_violeta.png', trilha(16, 4, [VIOL[1], VIOL[1], VIOL[3], VIOL[4]], VIOL[3], escuro=False))
    out('decor/trilha_fina_verde.png', trilha(16, 4, [G.EMER[1], G.EMER[1], G.EMER[3], G.EMER[4]], G.EMER[3], escuro=False))
    out('decor/anel_origem.png', anel_origem())
    out('tiles/plataforma_registro.png', plataforma_registro())
    out('tiles/plataforma_friso.png', plataforma_friso())


if __name__ == '__main__':
    main()
    print('arte das areas 1, 2 e 5 gerada')
