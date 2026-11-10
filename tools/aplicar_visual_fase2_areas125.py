"""Aplica a arte das Areas 1, 2 e 5 da Fase 2 (somente visual: colisoes, logica, textos e nomes de nos preservados).
Parte da versao commitada (git HEAD) das cenas. NAO reaplica se a cena ja tiver sido atualizada e commitada.
Rodar na raiz do projeto, depois de tools/gen_arte_fase2_areas125.py:  python tools/aplicar_visual_fase2_areas125.py
"""
import os, sys, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from aplicar_visual_fase2_partes import Cena, Mascara, retangulos_paredes, posicoes_objetos, AREAS, _rect_piso

MARCADOR = 'name="Brilho_0"'


def abrir(rel):
    c = Cena(AREAS + rel)
    if any(MARCADOR in b for b in c.blocos):
        raise SystemExit('%s ja contem o acabamento visual no HEAD; nada a fazer (evita aplicar duas vezes).' % rel)
    return c


def espalhar(c, mask, rng, itens, prefixo, dist_min=44):
    ocup, k = [], 0
    for arq, w, h, qtd in itens:
        for _ in range(qtd):
            p = mask.sorteio(rng, w, h, ocupados=ocup, dist_min=dist_min)
            if p:
                k += 1
                c.sprite('%s_%02d' % (prefixo, k), 'Decor', arq, p[0], p[1])


# ======================= AREA 1 — ARQUIVO DAS MEMORIAS =======================
def area_1():
    c = abrir('area_1_arquivo.tscn')
    rng = random.Random(3101)
    # hologramas e neon (antes: retangulos coloridos)
    c.texturizar('Holograma_Tech', 'neutra/props/holograma_tech.png', 'Objetos')
    c.texturizar('Holograma_Neon', 'neutra/props/neon_magenta.png', 'Objetos')

    # decoracao do piso: poucas peças, o piso do Santuario ja tem runas e rachaduras proprias
    pisos = [(0, 0, 640, 544), (640, 448, 160, 96), (384, -64, 128, 64), (-64, 128, 64, 128)]
    bloq = retangulos_paredes(c) + [(352, 400, 120, 90)]
    mask = Mascara(pisos, bloq, posicoes_objetos(c))
    espalhar(c, mask, rng, [('main/decor/rachadura_main_a.png', 48, 16, 4), ('main/decor/rachadura_main_b.png', 40, 14, 3),
                            ('main/decor/entulho_main_a.png', 28, 14, 4), ('main/decor/entulho_main_b.png', 22, 12, 3),
                            ('main/decor/coluna_tombada_main.png', 48, 20, 1)], 'Detalhe')

    # luz: violeta nas colunas, ciano no Atlas e no holograma, magenta no neon
    gv = c.glow_tex('violeta', (0.55, 0.42, 1.0))
    gc = c.glow_tex('ciano', (0.1, 0.9, 1.0))
    gm = c.glow_tex('magenta', (1.0, 0.17, 0.84))
    c.brilho('Brilho_0', gc, 211.2 - 64 * .9, 280 - 64 * .9, .9, .55, .3, 1.0)      # Atlas
    c.brilho('Brilho_1', gc, 448 - 64 * 1.0, -38 - 64 * 1.0, 1.0, .5, .35, 1.3)     # holograma
    c.brilho('Brilho_2', gm, 489.6 - 64 * .55, -38 - 64 * .55, .55, .6, .35, 1.7)   # neon
    for i, (x, y) in enumerate(((64, 180), (64, 372), (576, 180), (576, 372))):
        c.brilho('Brilho_Coluna_%d' % i, gv, x - 64 * .55, y - 64 * .55, .55, .5, .3, .8 + i * .13)
    c.brilho('Brilho_Registros', gv, 320 - 64 * .9, 300 - 64 * .9, .9, .45, .3, .9)
    c.brilho('Brilho_Terminal', gc, 422.4 - 64 * .6, 320 - 64 * .6, .6, .4, .3, 1.1)
    c.brilho('Brilho_Passagem', gv, 704 - 64 * .8, 496 - 64 * .8, .8, .45, .3, .95)
    c.salvar()


# ======================= AREA 2 — CAMARA DA RAMIFICACAO =======================
def trilha_textura(c, nome, rel):
    """Line2D com a faixa de pixel art em modo tile (mesmos pontos, largura e nome)."""
    c.set(nome, 'texture', c.tex(rel), 'Decor')
    c.set(nome, 'texture_mode', '1', 'Decor')
    c.set(nome, 'texture_repeat', '2', 'Decor')
    c.set(nome, 'texture_filter', '1', 'Decor')
    c.set(nome, 'default_color', 'Color(1, 1, 1, 0.92)', 'Decor')


def area_2():
    c = abrir('area_2_ramificacao.tscn')
    rng = random.Random(3102)
    # trilhas de energia
    trilha_textura(c, 'Trilha_Main', 'neutra/decor/trilha_violeta.png')
    trilha_textura(c, 'Trilha_Vida', 'neutra/decor/trilha_verde.png')
    trilha_textura(c, 'Trilha_Tech_Ciano', 'neutra/decor/trilha_fina_ciano.png')
    trilha_textura(c, 'Trilha_Tech_Magenta', 'neutra/decor/trilha_fina_magenta.png')
    trilha_textura(c, 'Trilha_Convergencia_Main', 'neutra/decor/trilha_fina_violeta.png')
    trilha_textura(c, 'Trilha_Convergencia_Vida', 'neutra/decor/trilha_fina_verde.png')
    c.virar_textura('Anel_Origem', 'neutra/decor/anel_origem.png', 'Decor')
    # porta de vidro (tech) e neon
    c.texturizar('Porta_Tech', 'neutra/props/porta_tech.png', 'Objetos')
    c.texturizar('Neon_Porta_Esq', 'neutra/props/neon_magenta.png', 'Objetos')
    c.texturizar('Neon_Porta_Dir', 'neutra/props/neon_magenta.png', 'Objetos')

    # decoracao do piso, longe das trilhas, do anel e das portas (sem runas soltas: parecem pontos de interacao)
    pisos = [(0, 0, 576, 640)]
    bloq = retangulos_paredes(c) + [(236, 258, 136, 136), (232, 60, 80, 270)]
    circ = list(posicoes_objetos(c))
    for (x0, y0, x1, y1) in ((304, 320, 16, 560), (304, 320, 560, 560), (291, 320, 291, 624), (316, 320, 316, 624)):
        n = int(max(abs(x1 - x0), abs(y1 - y0)) / 12)
        for k in range(n + 1):
            circ.append((x0 + (x1 - x0) * k / max(n, 1), y0 + (y1 - y0) * k / max(n, 1) + 16, 24))
    mask = Mascara(pisos, bloq, circ)
    espalhar(c, mask, rng, [('main/decor/rachadura_main_a.png', 48, 16, 3), ('main/decor/rachadura_main_b.png', 40, 14, 3),
                            ('main/decor/entulho_main_a.png', 28, 14, 3), ('main/decor/entulho_main_b.png', 22, 12, 3)], 'Detalhe', dist_min=52)

    # luz
    gv = c.glow_tex('violeta', (0.55, 0.42, 1.0))
    gc = c.glow_tex('ciano', (0.1, 0.9, 1.0))
    gm = c.glow_tex('magenta', (1.0, 0.17, 0.84))
    gg = c.glow_tex('verde', (0.3, 0.9, 0.55))
    c.brilho('Brilho_0', gv, 304 - 64 * 1.3, 326 - 64 * 1.3, 1.3, .6, .3, 0.9)      # no de origem
    c.brilho('Brilho_1', gc, 304 - 64 * 1.1, 40 - 64 * 1.1, 1.1, .5, .3, 1.2)       # porta tech
    c.brilho('Brilho_2', gm, 256 - 64 * .6, 32 - 64 * .6, .6, .6, .35, 1.6)
    c.brilho('Brilho_3', gm, 352 - 64 * .6, 32 - 64 * .6, .6, .6, .35, 1.9)
    c.brilho('Brilho_Main', gv, 38 - 64 * .9, 560 - 64 * .9, .9, .5, .3, 1.0)       # porta Main
    c.brilho('Brilho_Vida', gg, 538 - 64 * .9, 560 - 64 * .9, .9, .5, .3, 1.1)      # porta Vida
    c.brilho('Brilho_Conv', gc, 304 - 64 * .9, 624 - 64 * .9, .9, .45, .3, .8)      # porta Convergencia
    c.brilho('Brilho_Arquivo', gv, 38 - 64 * .8, 80 - 64 * .8, .8, .45, .3, 1.3)
    c.brilho('Brilho_Registro', gv, 538 - 64 * .8, 80 - 64 * .8, .8, .45, .3, 1.4)
    c.salvar()


# ======================= AREA 5 — REGISTRO FINAL =======================
def area_5():
    c = abrir('area_5_registro.tscn')
    rng = random.Random(3105)
    c.virar_textura('Plataforma', 'neutra/tiles/plataforma_registro.png', 'Decor')
    c.virar_textura('Plataforma_Borda', 'neutra/tiles/plataforma_friso.png', 'Decor')
    # portal de saida: o mesmo componente de pedra da Fase 1 (apagado ate a saida liberar). So o recurso muda.
    if 'res://GeneralNodes/ExitArea/exit_area.tscn' not in c.ext:
        raise SystemExit('area_5: exit_area.tscn nao encontrado no HEAD')
    c.blocos[c.ext_idx] = c.blocos[c.ext_idx].replace('res://GeneralNodes/ExitArea/exit_area.tscn',
                                                      'res://GeneralNodes/ExitArea/portal_saida.tscn')

    pisos = [(0, 0, 640, 544), (-160, 448, 160, 96)]
    bloq = retangulos_paredes(c) + [(184, 88, 272, 272), (-160, 440, 170, 110)]
    mask = Mascara(pisos, bloq, posicoes_objetos(c))
    espalhar(c, mask, rng, [('main/decor/rachadura_main_a.png', 48, 16, 4), ('main/decor/rachadura_main_b.png', 40, 14, 3),
                            ('main/decor/entulho_main_a.png', 28, 14, 3), ('main/decor/entulho_main_b.png', 22, 12, 3),
                            ('main/decor/coluna_tombada_main.png', 48, 20, 1)],
             'Detalhe', dist_min=50)

    gv = c.glow_tex('violeta', (0.55, 0.42, 1.0))
    gc = c.glow_tex('ciano', (0.1, 0.9, 1.0))
    c.brilho('Brilho_0', gv, 320 - 64 * 1.5, 215 - 64 * 1.5, 1.5, .55, .3, 0.8)     # registro final
    c.brilho('Brilho_1', gc, 320 - 64 * .8, 215 - 64 * .8, .8, .35, .3, 1.1)
    c.brilho('Brilho_Portal', gv, 560 - 64 * 1.0, 272 - 64 * 1.0, 1.0, .5, .3, 1.2)
    for i, (x, y) in enumerate(((64, 70), (64, 390), (576, 70), (576, 390))):
        c.brilho('Brilho_Pilar_%d' % i, gv, x - 64 * .55, y - 64 * .55, .55, .5, .3, .8 + i * .12)
    c.brilho('Brilho_Selo', gv, -64 - 64 * .8, 496 - 64 * .8, .8, .45, .3, 1.0)
    c.salvar()


if __name__ == '__main__':
    for f in (area_1, area_2, area_5):
        f()
    print('cenas das areas 1, 2 e 5 atualizadas')
