"""Aplica a arte das Areas 3 e 4 nas cenas da Fase 2 (somente visual: colisoes, logica e nomes de nos preservados).
Parte SEMPRE da versao commitada (git HEAD) das cenas, entao e idempotente.
Rodar na raiz do projeto, depois de tools/gen_arte_fase2_partes.py:  python tools/aplicar_visual_fase2_partes.py
"""
import os, re, random, subprocess

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
AREAS = 'fases/fase_2/areas/'
ARTE = 'res://fases/fase_2/arte/'


class Cena:
    def __init__(self, rel):
        self.rel = rel
        txt = subprocess.run(['git', 'show', 'HEAD:' + rel], cwd=RAIZ, capture_output=True, text=True,
                             encoding='utf-8', check=True).stdout.replace('\r\n', '\n')
        self.blocos = txt.strip('\n').split('\n\n')
        self.ext_idx = max(i for i, b in enumerate(self.blocos) if b.startswith('[ext_resource'))
        self.ext = {}      # path -> id
        self.ext_paths = {}  # id -> path
        for ln in self.blocos[self.ext_idx].split('\n'):
            m = re.search(r'path="([^"]+)" id="([^"]+)"', ln)
            if m:
                self.ext[m.group(1)] = m.group(2)
                self.ext_paths[m.group(2)] = m.group(1)
        self.subs = []     # novos sub_resources
        self.novos = []    # novos nos (texto)
        self.n = 0

    # ---- recursos
    def tex(self, rel):
        path = ARTE + rel
        if path not in self.ext:
            self.n += 1
            i = 'nv_%d' % self.n
            self.ext[path] = i
            self.ext_paths[i] = path
            self.blocos[self.ext_idx] += '\n[ext_resource type="Texture2D" path="%s" id="%s"]' % (path, i)
        return 'ExtResource("%s")' % self.ext[path]

    def sub(self, tipo, props, ident):
        self.subs.append('[sub_resource type="%s" id="%s"]\n%s' % (tipo, ident, '\n'.join(props)))
        return 'SubResource("%s")' % ident

    def glow_tex(self, nome, rgb):
        g = self.sub('Gradient', ['offsets = PackedFloat32Array(0, 0.45, 1)',
                                  'colors = PackedColorArray(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)' % (
                                      rgb[0], rgb[1], rgb[2], 0.55, rgb[0], rgb[1], rgb[2], 0.18, rgb[0], rgb[1], rgb[2], 0)],
                     'g_' + nome)
        return self.sub('GradientTexture2D', ['gradient = ' + g, 'width = 128', 'height = 128', 'fill = 1',
                                              'fill_from = Vector2(0.5, 0.5)', 'fill_to = Vector2(1, 0.5)'], 'gt_' + nome)

    def material_aditivo(self):
        if not hasattr(self, '_mat'):
            self._mat = self.sub('CanvasItemMaterial', ['blend_mode = 1'], 'mat_aditivo')
        return self._mat

    def script(self, path):
        if path not in self.ext:
            self.n += 1
            i = 'nv_%d' % self.n
            self.ext[path] = i
            self.blocos[self.ext_idx] += '\n[ext_resource type="Script" path="%s" id="%s"]' % (path, i)
        return 'ExtResource("%s")' % self.ext[path]

    # ---- blocos de no
    def idx(self, nome, pai=None):
        for i, b in enumerate(self.blocos):
            h = b.split('\n')[0]
            if h.startswith('[node ') and ('name="%s"' % nome) in h:
                if pai is None or ('parent="%s"' % pai) in h:
                    return i
        raise KeyError(nome)

    def existe(self, nome, pai=None):
        try:
            self.idx(nome, pai)
            return True
        except KeyError:
            return False

    def get(self, nome, chave, pai=None):
        b = self.blocos[self.idx(nome, pai)]
        m = re.search(r'^%s = (.+)$' % re.escape(chave), b, re.M)
        return m.group(1) if m else None

    def vec(self, nome, chave, pai=None):
        v = self.get(nome, chave, pai)
        m = re.match(r'Vector2\(([-\d.]+), ([-\d.]+)\)', v)
        return float(m.group(1)), float(m.group(2))

    def set(self, nome, chave, valor, pai=None):
        i = self.idx(nome, pai)
        linhas = self.blocos[i].split('\n')
        for k, ln in enumerate(linhas):
            if ln.startswith(chave + ' = '):
                linhas[k] = '%s = %s' % (chave, valor)
                break
        else:
            linhas.append('%s = %s' % (chave, valor))
        self.blocos[i] = '\n'.join(linhas)

    def remover_chave(self, nome, chave, pai=None):
        i = self.idx(nome, pai)
        self.blocos[i] = '\n'.join(l for l in self.blocos[i].split('\n') if not l.startswith(chave + ' = '))

    def remover(self, nome, pai=None):
        del self.blocos[self.idx(nome, pai)]

    def instancia(self, nome, pai):
        h = self.blocos[self.idx(nome, pai)].split('\n')[0]
        m = re.search(r'instance=ExtResource\("([^"]+)"\)', h)
        return self.ext_paths[m.group(1)] if m else None

    def virar_textura(self, nome, textura_rel, pai=None, tile=False):
        """ColorRect -> TextureRect (mesmos offsets)."""
        i = self.idx(nome, pai)
        linhas = self.blocos[i].split('\n')
        linhas[0] = linhas[0].replace('type="ColorRect"', 'type="TextureRect"')
        linhas = [l for l in linhas if not l.startswith('color = ') and not l.startswith('visible = ')]
        linhas += ['texture = ' + self.tex(textura_rel), 'expand_mode = 1', 'stretch_mode = %d' % (1 if tile else 0),
                   'texture_filter = 1']
        self.blocos[i] = '\n'.join(linhas)

    def texturizar(self, nome, textura_rel, pai=None):
        """Parede/Prop: preenche `textura`."""
        self.set(nome, 'textura', self.tex(textura_rel), pai)

    def no(self, nome, tipo, pai, props):
        linhas = ['[node name="%s" type="%s" parent="%s"]' % (nome, tipo, pai)]
        linhas += ['%s = %s' % (k, v) for k, v in props.items()]
        self.novos.append('\n'.join(linhas))

    def sprite(self, nome, pai, rel, x, y, **extra):
        p = {'texture_filter': 1, 'centered': 'false', 'position': 'Vector2(%g, %g)' % (x, y), 'texture': self.tex(rel)}
        p.update(extra)
        self.no(nome, 'Sprite2D', pai, p)

    def retangulo_tile(self, nome, pai, rel, x, y, w, h, tile=True, **extra):
        p = {'texture_filter': 1, 'mouse_filter': 2, 'offset_left': x, 'offset_top': y, 'offset_right': x + w,
             'offset_bottom': y + h, 'texture': self.tex(rel), 'expand_mode': 1, 'stretch_mode': 1 if tile else 0}
        p.update(extra)
        self.no(nome, 'TextureRect', pai, p)

    def brilho(self, nome, cena_glow, x, y, escala=0.6, alfa=1.0, intensidade=0.3, vel=1.2):
        s = self.script('res://fases/fase_2/componentes/brilho_ambiente.gd')
        self.no(nome, 'Sprite2D', 'Iluminacao', {
            'material': self.material_aditivo(), 'position': 'Vector2(%g, %g)' % (x, y), 'scale': 'Vector2(%g, %g)' % (escala, escala),
            'texture': cena_glow, 'modulate': 'Color(1, 1, 1, %g)' % alfa, 'script': s, 'intensidade': intensidade,
            'velocidade': vel})

    def salvar(self):
        blocos = list(self.blocos)
        if self.subs:
            primeiro_no = next(i for i, b in enumerate(blocos) if b.startswith('[node '))
            blocos[primeiro_no:primeiro_no] = self.subs
        txt = '\n\n'.join(blocos + self.novos) + '\n'
        with open(os.path.join(RAIZ, self.rel), 'w', encoding='utf-8', newline='\n') as f:
            f.write(txt)


# ---------------- utilitarios de colocacao ----------------
class Mascara:
    """Onde da para colocar decoracao: dentro do piso, fora de paredes/objetos."""

    def __init__(self, pisos, bloqueios, circulos):
        self.pisos, self.bloq, self.circ = pisos, bloqueios, circulos

    def livre(self, x, y, w, h, margem=3):
        for (px, py, pw, ph) in [self.pisos_de(x, y, w, h)] if False else []:
            pass
        cantos = [(x, y), (x + w, y), (x, y + h), (x + w, y + h), (x + w / 2, y + h / 2)]
        for (cx, cy) in cantos:
            if not any(px <= cx <= px + pw and py <= cy <= py + ph for (px, py, pw, ph) in self.pisos):
                return False
        for (bx, by, bw, bh) in self.bloq:
            if x - margem < bx + bw and x + w + margem > bx and y - margem < by + bh and y + h + margem > by:
                return False
        for (cx, cy, r) in self.circ:
            if (x - r < cx < x + w + r) and (y - r < cy < y + h + r):
                return False
        return True

    def sorteio(self, rng, w, h, tentativas=80, ocupados=None, dist_min=0):
        for _ in range(tentativas):
            (px, py, pw, ph) = rng.choice(self.pisos)
            if pw < w or ph < h:
                continue
            x = round(px + rng.random() * (pw - w))
            y = round(py + rng.random() * (ph - h))
            if self.livre(x, y, w, h):
                if ocupados is not None:
                    if any(abs(x - ox) < dist_min and abs(y - oy) < dist_min for (ox, oy) in ocupados):
                        continue
                    ocupados.append((x, y))
                return x, y
        return None


def retangulos_paredes(c, prefixos_instancia=('parede.tscn', 'barreira.tscn')):
    r = []
    for b in c.blocos:
        h = b.split('\n')[0]
        m = re.search(r'instance=ExtResource\("([^"]+)"\)', h)
        if not (h.startswith('[node ') and m):
            continue
        if not c.ext_paths[m.group(1)].endswith(prefixos_instancia):
            continue
        pos = re.search(r'^position = Vector2\(([-\d.]+), ([-\d.]+)\)', b, re.M)
        tam = re.search(r'^tamanho = Vector2\(([-\d.]+), ([-\d.]+)\)', b, re.M)
        if pos and tam:
            r.append((float(pos.group(1)), float(pos.group(2)), float(tam.group(1)), float(tam.group(2))))
    return r


def posicoes_objetos(c, pais=('Objetos', 'Interacoes'), raio=26, raio_fissura=60):
    circ = []
    for b in c.blocos:
        h = b.split('\n')[0]
        if h.startswith('[node ') and any(('parent="%s"' % p) in h for p in pais):
            pos = re.search(r'^position = Vector2\(([-\d.]+), ([-\d.]+)\)', b, re.M)
            if pos:
                nome = re.search(r'name="([^"]+)"', h).group(1)
                rr = raio_fissura if ('Fissura' in nome or 'Terminal' in nome or 'Coleta' in nome or 'Atlas' in nome) else raio
                circ.append((float(pos.group(1)), float(pos.group(2)) - 16, rr))
    return circ


# ======================= AREA 3 — MAIN =======================
def destacar(c, prop, tipo, cor):
    """Anexa o DestaqueColetavel (halo/feixe/faiscas) a um prop coletavel. So visual."""
    c.no('Destaque', 'Node2D', 'Objetos/' + prop, {
        'script': c.script('res://fases/fase_2/componentes/destaque_coletavel.gd'), 'tipo': tipo, 'cor': cor})


def area_3_main():
    c = Cena(AREAS + 'area_3_main.tscn')
    rng = random.Random(3001)
    # coletaveis em destaque (o eco de main e o item de progresso; os fragmentos sao opcionais)
    c.texturizar('Eco_Main', 'main/props/eco_main_destaque.png', 'Objetos')
    destacar(c, 'Eco_Main', 0, 'Color(0.62, 0.48, 1, 1)')
    for n in (1, 2, 3):
        destacar(c, 'Frag_M%d_Brilho' % n, 1, 'Color(0.62, 0.48, 1, 1)')
    c.set('Barreira_Limiar', 'texto_bloqueada',
          '"Esta realidade está adormecida. No terminal, use \'git switch main\' para atravessar."', 'Paredes')

    # abismos e vao
    # Um unico visual continuo para os tres blocos de colisao (Abismo_Oeste/Leste e vao): sem emendas
    # nem fase de tile diferente (a "caixa" mais escura no vao). As colisoes seguem nos blocos originais.
    c.no('Abismo_Visual', 'TextureRect', 'Paredes', {
        'texture_filter': 1, 'mouse_filter': 2, 'offset_left': 0, 'offset_top': 288, 'offset_right': 768,
        'offset_bottom': 416, 'texture': c.tex('main/tiles/abismo_main_grande.png'), 'expand_mode': 1,
        'stretch_mode': 0})
    # pontas da ponte partida
    c.virar_textura('Ponte_Ponta_Norte', 'main/tiles/ponte_ponta_norte.png', 'Decor')
    c.virar_textura('Ponte_Ponta_Sul', 'main/tiles/ponte_ponta_sul.png', 'Decor')
    c.sprite('Ponte_Vao_Detalhes', 'Decor', 'main/props/ponte_vao_detalhes.png', 320, 320)
    # bordas dos abismos integradas ao piso
    for nome, x, w in (('Oeste', 0, 320), ('Leste', 448, 320)):
        c.retangulo_tile('Borda_%s_Norte' % nome, 'Decor', 'main/tiles/borda_abismo_main_sup.png', x, 288, w, 16)
        c.retangulo_tile('Borda_%s_Sul' % nome, 'Decor', 'main/tiles/borda_abismo_main_inf.png', x, 400, w, 16)
    for y in (288, 384):
        c.retangulo_tile('Borda_Ponta_Oeste_%d' % y, 'Decor', 'main/tiles/borda_abismo_main_dir.png', 304, y, 16, 32)
        c.retangulo_tile('Borda_Ponta_Leste_%d' % y, 'Decor', 'main/tiles/borda_abismo_main_esq.png', 448, y, 16, 32)
    # faixa de transicao (corredor da ramificacao): degrade em vez de retangulo chapado
    g = c.sub('Gradient', ['offsets = PackedFloat32Array(0, 0.5, 1)',
                           'colors = PackedColorArray(0.4784, 0.3451, 0.8392, 0, 0.4784, 0.3451, 0.8392, 0.32, 0.4784, 0.3451, 0.8392, 0)'], 'g_faixa')
    gt = c.sub('GradientTexture2D', ['gradient = ' + g, 'width = 32', 'height = 64', 'fill_from = Vector2(0, 0)',
                                     'fill_to = Vector2(0, 1)'], 'gt_faixa')
    i = c.idx('Faixa_Transicao', 'Decor')
    ln = [l for l in c.blocos[i].split('\n') if not l.startswith('color = ')]
    ln[0] = ln[0].replace('type="ColorRect"', 'type="TextureRect"')
    c.blocos[i] = '\n'.join(ln + ['texture = ' + gt, 'expand_mode = 1', 'stretch_mode = 0'])

    # decoracao
    pisos = [(0, 0, 768, 704), (640, -192, 192, 192), (768, 544, 128, 96)]
    bloq = retangulos_paredes(c) + [(0, 288, 768, 128)]
    mask = Mascara(pisos, bloq, posicoes_objetos(c))
    ocup = []
    decor = [('rachadura_main_a.png', 48, 16, 8), ('rachadura_main_b.png', 40, 14, 6), ('runa_chao_main.png', 32, 32, 4),
             ('entulho_main_a.png', 28, 14, 7), ('entulho_main_b.png', 22, 12, 6), ('coluna_tombada_main.png', 48, 20, 2)]
    k = 0
    for arq, w, h, qtd in decor:
        for _ in range(qtd):
            p = mask.sorteio(rng, w, h, ocupados=ocup, dist_min=40)
            if p:
                k += 1
                c.sprite('Detalhe_%02d' % k, 'Decor', 'main/decor/' + arq, p[0], p[1])
    # entulho caido nas bordas dos abismos (ruinas junto aos vaos)
    for i, (x, y) in enumerate(((60, 262), (210, 266), (540, 262), (690, 268), (90, 420), (250, 424), (500, 420), (700, 424), (350, 282), (402, 418))):
        c.sprite('Borda_Entulho_%d' % i, 'Decor', 'main/decor/entulho_main_%s.png' % ('a' if i % 2 else 'b'), x, y)

    # brilho discreto
    glow = c.glow_tex('main', (0.55, 0.42, 1.0))
    pts = [(400, 300, .9), (400, 380, .9), (656, 500, .7), (144, 590, .6), (624, 52, .5), (384, 240, .5), (268, 586, .5),
           (748, 544, .6), (748, 640, .6), (688, 0, 1.0)]
    for i, (x, y, e) in enumerate(pts):
        c.brilho('Brilho_%d' % i, glow, x - 64 * e, y - 64 * e, e, .55, .35, 0.8 + 0.15 * i)
    c.salvar()


# ======================= AREA 3 — VIDA =======================
def area_3_vida():
    c = Cena(AREAS + 'area_3_vida.tscn')
    rng = random.Random(3002)
    # pisos
    for i in range(1, 11):
        c.virar_textura('Piso_%d' % i, 'vida/tiles/piso_vida.png', 'Piso', tile=True)
    # paredes
    for b in list(c.blocos):
        h = b.split('\n')[0]
        m = re.search(r'name="(Muro_\d+)" parent="Paredes"', h)
        if m:
            c.texturizar(m.group(1), 'vida/tiles/muro_vida.png', 'Paredes')
    c.texturizar('Espinheiro', 'vida/tiles/espinheiro.png', 'Paredes')
    c.texturizar('Abismo_Oeste', 'vida/tiles/abismo_vida.png', 'Paredes')
    c.texturizar('Abismo_Leste', 'vida/tiles/abismo_vida.png', 'Paredes')
    # ponte de raizes
    c.virar_textura('Ponte_Raizes', 'vida/tiles/ponte_raizes.png', 'Decor')
    c.remover('Ponte_Raizes_Veio', 'Decor')
    # bordas dos abismos
    for nome, x, w in (('Oeste', 0, 320), ('Leste', 448, 320)):
        c.retangulo_tile('Borda_%s_Norte' % nome, 'Decor', 'vida/tiles/borda_abismo_vida_sup.png', x, 288, w, 16)
        c.retangulo_tile('Borda_%s_Sul' % nome, 'Decor', 'vida/tiles/borda_abismo_vida_inf.png', x, 400, w, 16)
    c.retangulo_tile('Borda_Ponte_Oeste', 'Decor', 'vida/tiles/borda_abismo_vida_dir.png', 304, 288, 16, 128)
    c.retangulo_tile('Borda_Ponte_Leste', 'Decor', 'vida/tiles/borda_abismo_vida_esq.png', 448, 288, 16, 128)
    # faixa de transicao
    g = c.sub('Gradient', ['offsets = PackedFloat32Array(0, 0.5, 1)',
                           'colors = PackedColorArray(0.3216, 0.8784, 0.5412, 0, 0.3216, 0.8784, 0.5412, 0.11, 0.3216, 0.8784, 0.5412, 0)'], 'g_faixa')
    gt = c.sub('GradientTexture2D', ['gradient = ' + g, 'width = 32', 'height = 64', 'fill_from = Vector2(0, 0)',
                                     'fill_to = Vector2(0, 1)'], 'gt_faixa')
    i = c.idx('Faixa_Transicao', 'Decor')
    ln = [l for l in c.blocos[i].split('\n') if not l.startswith('color = ')]
    ln[0] = ln[0].replace('type="ColorRect"', 'type="TextureRect"')
    c.blocos[i] = '\n'.join(ln + ['texture = ' + gt, 'expand_mode = 1', 'stretch_mode = 0'])

    # props
    for n in range(1, 18):
        c.texturizar('Arvore_%d' % n, 'vida/props/arvore_vida_%d.png' % (n % 3), 'Objetos')
        c.set('Arvore_%d' % n, 'tamanho_visual', 'Vector2(44, 84)', 'Objetos')
    for n in range(1, 10):
        c.texturizar('Arbusto_%d' % n, 'vida/props/arbusto_vida_%d.png' % (n % 2), 'Objetos')
    for n in range(1, 5):
        c.texturizar('Cristal_%d' % n, 'vida/props/cristal_vida_%d.png' % (n % 2), 'Objetos')
    c.texturizar('Cristal_Pedestal_Eco_Vida', 'vida/props/pedestal_vida.png', 'Objetos')
    c.texturizar('Eco_Vida', 'vida/props/eco_vida_destaque.png', 'Objetos')
    destacar(c, 'Eco_Vida', 0, 'Color(0.2, 1, 0.8, 1)')
    for n in (1, 2, 3):
        destacar(c, 'Frag_V%d_Brilho' % n, 1, 'Color(0.3, 1, 0.65, 1)')
    c.set('Barreira_Limiar', 'texto_bloqueada',
          '"Esta realidade está adormecida. No terminal, use \'git switch vida-alternativa\' para atravessar."', 'Paredes')
    for n in (1, 2, 3):
        c.texturizar('Frag_V%d_Brilho' % n, 'vida/props/fragmento_vida.png', 'Objetos')
    for n in (1, 2):
        c.texturizar('Cristal_Saida_%d' % n, 'vida/props/pilar_vida.png', 'Objetos')

    # barreira da Vida: mesma estrutura de arte da Main (fechada | aberta)
    c.set('Barreira_Limiar', 'cor', 'Color(0.3216, 0.8784, 0.5412, 0)', 'Paredes')
    t = c.tex('vida/barreiras/barreira_passagem_vida.png')
    af = c.sub('AtlasTexture', ['atlas = ' + t, 'region = Rect2(0, 0, 64, 96)'], 'at_barreira_vida_fechada')
    aa = c.sub('AtlasTexture', ['atlas = ' + t, 'region = Rect2(64, 0, 64, 96)'], 'at_barreira_vida_aberta')
    c.novos.append('[node name="ArteAberta" type="Sprite2D" parent="Paredes/Barreira_Limiar" index="0"]\ncentered = false\ntexture = ' + aa)
    c.novos.append('[node name="Arte" type="Sprite2D" parent="Paredes/Barreira_Limiar/Visual"]\ncentered = false\ntexture = ' + af)

    # decoracao no piso
    pisos = [tuple(float(v) for v in (c.vec('Piso_%d' % i, 'offset_left') if False else _rect_piso(c, 'Piso_%d' % i))) for i in range(1, 11)]
    bloq = retangulos_paredes(c) + [(320, 288, 128, 128)]
    mask = Mascara(pisos, bloq, posicoes_objetos(c))
    ocup = []
    k = 0
    decor = [('musgo_%d.png', 3, 40, 24, 9), ('raiz_%d.png', 3, 48, 24, 8), ('cogumelos_%s.png', 'ab', 18, 14, 8),
             ('cristais_%s.png', 'ab', 26, 20, 5), ('entulho_vida_%s.png', 'ab', 28, 14, 7),
             ('coluna_tombada_vida.png', 0, 48, 20, 3)]
    for arq, var, w, h, qtd in decor:
        for j in range(qtd):
            p = mask.sorteio(rng, w, h, ocupados=ocup, dist_min=36)
            if not p:
                continue
            k += 1
            nome = arq if var == 0 else (arq % (rng.randrange(var) if isinstance(var, int) else rng.choice(var)))
            c.sprite('Detalhe_%02d' % k, 'Decor', 'vida/decor/' + nome, p[0], p[1])
    # hera/raizes caindo sobre os muros que encostam num piso livre
    h = 0
    for (x, y, w, hh) in [r for r in retangulos_paredes(c) if r[3] == 32 and r[2] >= 64]:
        for _ in range(max(1, int(w // 96))):
            px = round(x + rng.random() * max(1, w - 24))
            py = round(y + 20)
            if mask.livre(px, y + hh, 24, 14, 0) and h < 16:
                h += 1
                c.sprite('Hera_%02d' % h, 'Decor', 'vida/decor/hera_%d.png' % rng.randrange(3), px, py)

    # bioluminescencia
    glow = c.glow_tex('vida', (0.18, 1.0, 0.75))
    pts = []
    for n in range(1, 5):
        x, y = c.vec('Cristal_%d' % n, 'position', 'Objetos')
        pts.append((x, y - 11, .55))
    for nome in ('Eco_Vida', 'Frag_V1_Brilho', 'Frag_V2_Brilho', 'Frag_V3_Brilho'):
        x, y = c.vec(nome, 'position', 'Objetos')
        pts.append((x, y - 10, .7))
    for nome in ('Cristal_Saida_1', 'Cristal_Saida_2'):
        x, y = c.vec(nome, 'position', 'Objetos')
        pts.append((x, y - 40, .9))
    pts += [(384, 352, 1.3), (356, 330, .8), (412, 380, .8), (560, 560, 1.0), (140, 90, 1.0), (590, 380, .8)]
    for i, (x, y, e) in enumerate(pts):
        c.brilho('Brilho_%d' % i, glow, x - 64 * e, y - 64 * e, e, .6, .35, 0.7 + 0.11 * i)
    c.salvar()


def _rect_piso(c, nome):
    g = lambda k: float(c.get(nome, k, 'Piso'))
    return g('offset_left'), g('offset_top'), g('offset_right') - g('offset_left'), g('offset_bottom') - g('offset_top')


# ======================= AREA 4 — CONVERGENCIA =======================
def area_4():
    c = Cena(AREAS + 'area_4_convergencia.tscn')
    rng = random.Random(3003)
    # as portas dizem o que falta e qual comando usar no terminal
    c.set('Barreira_Oeste', 'texto_bloqueada',
          '"Selada. Para abrir: colha os dois ecos (Vida e main) e esteja em \'main\' (terminal: git switch main)."', 'Paredes')
    c.set('Barreira_Leste', 'texto_bloqueada',
          '"Selada. Para abrir: colha os dois ecos (Vida e main) e esteja em \'vida-alternativa\' (terminal: git switch vida-alternativa)."', 'Paredes')
    c.set('Barreira_Norte', 'texto_bloqueada', '"Selada. Para abrir: colha os dois ecos (Vida e main)."', 'Paredes')
    # pisos: metade main (violeta) | metade vida (verde), corredor norte idem
    c.virar_textura('Piso_1', 'convergencia/tiles/piso_conv_main.png', 'Piso', tile=True)
    c.set('Piso_1', 'offset_right', '224', 'Piso')
    c.novos.append('[node name="Piso_1_Vida" type="TextureRect" parent="Piso"]\ntexture_filter = 1\nmouse_filter = 2\noffset_left = 224\noffset_top = 0\noffset_right = 448\noffset_bottom = 576\ntexture = %s\nexpand_mode = 1\nstretch_mode = 1' % c.tex('convergencia/tiles/piso_conv_vida.png'))
    c.virar_textura('Piso_2', 'convergencia/tiles/piso_conv_main.png', 'Piso', tile=True)
    c.set('Piso_2', 'offset_right', '240', 'Piso')
    c.novos.append('[node name="Piso_2_Vida" type="TextureRect" parent="Piso"]\ntexture_filter = 1\nmouse_filter = 2\noffset_left = 240\noffset_top = -192\noffset_right = 288\noffset_bottom = 0\ntexture = %s\nexpand_mode = 1\nstretch_mode = 1' % c.tex('convergencia/tiles/piso_conv_vida.png'))
    # paredes: lado main (violeta) / lado vida (verde)
    lado = {1: 'main', 2: 'vida', 3: 'main', 4: 'vida', 5: 'main', 6: 'vida', 7: 'main', 8: 'vida', 9: 'main'}
    for n, l in lado.items():
        c.texturizar('Muro_%d' % n, 'convergencia/tiles/muro_conv_%s.png' % l, 'Paredes')
    c.retangulo_tile('Muro_9_Vida', 'Decor', 'convergencia/tiles/muro_conv_vida.png', 224, 576, 256, 32)
    # plataformas, fenda e fusao
    c.virar_textura('Metade_Main', 'convergencia/tiles/plataforma_main.png', 'Decor')
    c.virar_textura('Metade_Vida', 'convergencia/tiles/plataforma_vida.png', 'Decor')
    c.virar_textura('Fusao_Resultado', 'convergencia/tiles/fusao_resultado.png', 'Decor', tile=True)
    c.virar_textura('Fenda_Divisoria', 'convergencia/tiles/fenda_divisoria.png', 'Decor', tile=True)
    for lado_, n in (('main', 'Main'), ('vida', 'Vida')):
        for k in (1, 2, 3):
            c.virar_textura('Moldura_%s_%d' % (n, k), 'convergencia/props/moldura_%s.png' % lado_, 'Decor')
    mapa = {('Itens_Main', 'Main_Coluna'): 'main_coluna', ('Itens_Main', 'Main_Coluna_Topo'): 'main_capitel',
            ('Itens_Main', 'Main_Ponte_A'): 'main_laje_a', ('Itens_Main', 'Main_Ponte_B'): 'main_laje_b',
            ('Itens_Main', 'Main_Eco'): 'main_eco', ('Itens_Vida', 'Vida_Copa'): 'vida_copa',
            ('Itens_Vida', 'Vida_Tronco'): 'vida_tronco', ('Itens_Vida', 'Vida_Raizes'): 'vida_raizes',
            ('Itens_Vida', 'Vida_Raizes_Veio'): 'vida_raizes_veio', ('Itens_Vida', 'Vida_Eco'): 'vida_eco',
            ('Coexistencia', 'Coex_Coluna_Pedra'): 'coex_coluna_pedra', ('Coexistencia', 'Coex_Coluna_Copa'): 'coex_coluna_raizes',
            ('Coexistencia', 'Coex_Ponte_Pedra'): 'coex_ponte_pedra', ('Coexistencia', 'Coex_Ponte_Raizes'): 'coex_ponte_raizes',
            ('Coexistencia', 'Coex_Eco_Main'): 'coex_eco_main', ('Coexistencia', 'Coex_Eco_Vida'): 'coex_eco_vida'}
    for (grupo, nome), arq in mapa.items():
        c.virar_textura(nome, 'convergencia/props/%s.png' % arq, 'Decor/' + grupo)
    # props
    for n in (1, 3):
        c.texturizar('Pilar_%d' % n, 'main/props/pilar_fino.png', 'Objetos')
    for n in (2, 4):
        c.texturizar('Pilar_%d' % n, 'vida/props/pilar_vida.png', 'Objetos')
    c.texturizar('Atlas_Placeholder_Convergencia', 'convergencia/props/atlas_convergencia.png', 'Objetos')

    # energia: fios soltos antes da fusao (filhos da Fenda) e fios plenos depois (filhos da Coexistencia)
    fx, fy = 219.2, 128.0
    for k, cy in enumerate((179.2, 275.2, 371.2), 1):
        c.sprite('Fio_Solto_%d' % k, 'Decor/Fenda_Divisoria', 'convergencia/decor/energia_h_partida.png', 160 - fx, cy - 4 - fy,
                 modulate='Color(1, 1, 1, 0.55)')
        c.sprite('Fio_Pleno_%d' % k, 'Decor/Coexistencia', 'convergencia/decor/energia_h.png', 160, cy - 4)
    # conduitos de energia ligando as barreiras ao centro
    cond = [('Conduto_Oeste', 'energia_h_96.png', 0, 460), ('Conduto_Leste', 'energia_h_96.png', 352, 460),
            ('Conduto_Norte', 'energia_v.png', 220, 24)]
    c.no('Energia', 'Node2D', 'Decor', {})
    for nome, arq, x, y in cond:
        c.sprite(nome, 'Decor/Energia', 'convergencia/decor/' + arq, x, y, modulate='Color(1, 1, 1, 0.8)')
    for k, (x, y) in enumerate(((10, 440), (10, 484), (426, 440), (426, 484), (200, 20), (240, 20))):
        c.sprite('Glifo_%d' % k, 'Decor/Energia', 'convergencia/decor/glifo_conv.png', x - 9, y - 9)

    # decoracao
    pisos = [(0, 0, 448, 576), (192, -192, 96, 192)]
    bloq = retangulos_paredes(c) + [(96, 128, 256, 320), (0, 440, 100, 40), (348, 440, 100, 40), (196, 0, 56, 130)]
    mask = Mascara(pisos, bloq, posicoes_objetos(c))
    ocup = []
    k = 0
    # lado: 'main' (x<224), 'vida' (x>=224) ou None (neutro: rachaduras e cristais ciano, ligados a convergencia)
    for arq, w, h, qtd, lado_ in (('rachadura_conv.png', 48, 16, 6, None), ('entulho_conv.png', 28, 14, 3, 'main'),
                                  ('entulho_conv_vida.png', 28, 14, 3, 'vida'), ('raiz_conv.png', 48, 24, 5, 'vida'),
                                  ('cristais_conv.png', 26, 20, 5, None)):
        for _ in range(qtd):
            p = None
            for _t in range(40):
                q = mask.sorteio(rng, w, h, ocupados=None)
                if q is None:
                    continue
                if lado_ == 'main' and q[0] + w > 224 - 6:
                    continue
                if lado_ == 'vida' and q[0] < 224 + 6:
                    continue
                if any(abs(q[0] - ox) < 44 and abs(q[1] - oy) < 44 for (ox, oy) in ocup):
                    continue
                p = q
                ocup.append(q)
                break
            if p:
                k += 1
                c.sprite('Detalhe_%02d' % k, 'Decor', 'convergencia/decor/' + arq, p[0], p[1])
    # raizes e ciano descendo pelas paredes
    h = 0
    for (x, y, w, hh) in [r for r in retangulos_paredes(c) if r[3] == 32 and r[2] >= 64 and r[1] < 600]:
        for _ in range(max(1, int(w // 96))):
            px = round(x + rng.random() * max(1, w - 22))
            py = round(y + 20)
            if mask.livre(px, y + hh, 22, 14, 0) and h < 10:
                h += 1
                c.sprite('Hera_%02d' % h, 'Decor', 'convergencia/decor/hera_conv_%d.png' % rng.randrange(3), px, py)

    # iluminacao
    gc = c.glow_tex('conv', (0.1, 0.9, 1.0))
    gv = c.glow_tex('conv_vida', (0.18, 1.0, 0.7))
    gm = c.glow_tex('conv_main', (0.55, 0.42, 1.0))
    c.brilho('Brilho_Atlas', gc, 224 - 70, 90 - 70, 1.1, .8, .3, .9)
    c.brilho('Brilho_Fenda', gc, 224 - 64, 288 - 64, 1.0, .5, .25, 1.1)
    c.brilho('Brilho_Fenda_N', gc, 224 - 64, 170 - 64, .8, .45, .25, .8)
    c.brilho('Brilho_Fenda_S', gc, 224 - 64, 410 - 64, .8, .45, .25, 1.0)
    for i, (x, y) in enumerate(((48, 40), (48, 504))):
        c.brilho('Brilho_Pilar_M%d' % i, gm, x - 40, y - 40, .6, .6, .3, .8 + i * .2)
    for i, (x, y) in enumerate(((400, 40), (400, 504))):
        c.brilho('Brilho_Pilar_V%d' % i, gv, x - 40, y - 40, .6, .6, .3, .9 + i * .2)
    for i, (x, y) in enumerate(((147, 179), (147, 275), (147, 371))):
        c.brilho('Brilho_Moldura_M%d' % i, gm, x - 40, y - 40, .6, .5, .3, 1 + i * .1)
    for i, (x, y) in enumerate(((301, 179), (301, 275), (301, 371))):
        c.brilho('Brilho_Moldura_V%d' % i, gv, x - 40, y - 40, .6, .5, .3, 1.1 + i * .1)
    for i, (x, y) in enumerate(((20, 464), (428, 464), (224, 20))):
        c.brilho('Brilho_Barreira_%d' % i, gc, x - 56, y - 56, .9, .45, .3, .9 + i * .15)
    c.salvar()


if __name__ == '__main__':
    area_3_main()
    area_3_vida()
    area_4()
    print('cenas atualizadas')
