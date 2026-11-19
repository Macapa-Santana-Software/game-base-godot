extends SceneTree
## Gerador da arte da Fase 5 (Linhas Cruzadas), paleta "Grafite neutro" de docs/DESIGN_FASES.md.
## Não faz parte do jogo: desenha, pixel a pixel, os PNGs em res://fases/fase_5/arte/. Para regerar:
##   godot --headless --path . --script res://tools/gerar_arte_fase_5.gd
## O cenário é neutro de propósito: dourado (a sua linha), azul (a outra equipe), magenta (marcadores do glitch)
## e verde-água (a resolução "ambas", a cor do Walker) são cores de SIGNIFICADO e só aparecem onde a história pede.

const SAIDA := "res://fases/fase_5/arte/"

var GRAFITE: Array[Color] = [Color("141517"), Color("1F2023"), Color("2E3033"), Color("3D4045"), Color("4A4D52"), Color("62666C"), Color("7C8087")]
var PRATA: Array[Color] = [Color("6E737B"), Color("8E939B"), Color("B8BCC4"), Color("DDE0E5"), Color("F4F6F8")]
const OURO := Color("E8B84A")
const AZUL := Color("3D7BFF")
const MAGENTA := Color("FF2BD6")
const VERDE_AGUA := Color("2EE6C5")
const TINTA := Color("0B0C0D")


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAIDA))
	_piso()
	_parede()
	_faixa("main", OURO)
	_faixa("ajuste", AZUL)
	_tablete()
	_glifos()
	_pedestal("minha", [OURO])
	_pedestal("deles", [AZUL])
	_pedestal("ambas", [OURO, AZUL])
	_barreira()
	_rachaduras()
	_rack()
	_colunas()
	_restos()
	_fenda()
	_brilho("brilho_prata.png", Color(0.85, 0.9, 1.0))
	_brilho("brilho_verde.png", VERDE_AGUA)
	_recolorir("res://terminal/Sprites/obelisco_inativo.png", "obelisco_inativo_grafite.png", 1.0)
	_recolorir("res://terminal/Sprites/obelisco_ativo.png", "obelisco_ativo_grafite.png", 1.0)
	_recolorir("res://terminal/Sprites/plataforma_terminal.png", "plataforma_terminal_grafite.png", 1.1)
	_recolorir("res://GeneralNodes/ExitArea/portal_saida.png", "portal_saida_grafite.png", 1.0)
	print("[Arte Fase 5] pronto.")
	quit()


# Utilidades -------------------------------------------------------------------------------------
func _novo(w: int, h: int) -> Image:
	var im := Image.create(w, h, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	return im


func _salvar(im: Image, nome: String) -> void:
	im.save_png(ProjectSettings.globalize_path(SAIDA + nome))


func _h(x: int, y: int, s: int = 0) -> float:
	var n: int = (x * 374761393 + y * 668265263 + s * 2147483629) & 0x7fffffff
	n = ((n ^ (n >> 13)) * 1274126177) & 0x7fffffff
	return float((n ^ (n >> 16)) & 0xffff) / 65535.0


func _p(im: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= im.get_width() or y >= im.get_height():
		return
	if c.a >= 1.0:
		im.set_pixel(x, y, c)
	else:
		im.set_pixel(x, y, im.get_pixel(x, y).blend(c))


func _r(im: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for j in range(h):
		for i in range(w):
			_p(im, x + i, y + j, c)


func _g(i: int) -> Color:
	return GRAFITE[clampi(i, 0, GRAFITE.size() - 1)]


func _s(i: int) -> Color:
	return PRATA[clampi(i, 0, PRATA.size() - 1)]


func _tingir(c: Color, k: float) -> Color:
	return Color(clampf(c.r + k, 0.0, 1.0), clampf(c.g + k, 0.0, 1.0), clampf(c.b + k, 0.0, 1.0), c.a)


func _contorno(im: Image, cor: Color) -> void:
	var w := im.get_width()
	var h := im.get_height()
	var marcar: Array[Vector2i] = []
	for y in range(h):
		for x in range(w):
			if im.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and im.get_pixel(q.x, q.y).a >= 1.0:
					marcar.append(Vector2i(x, y))
					break
	for m in marcar:
		im.set_pixel(m.x, m.y, cor)


# Chão e paredão -------------------------------------------------------------------------------------
func _piso() -> void:
	# Placas de grafite 32x32 com biselado, veios de metal escovado e rebites de prata (tileável 64x64)
	var im := _novo(64, 64)
	for y in range(64):
		for x in range(64):
			var lx := x % 32
			var ly := y % 32
			var placa := (x / 32) + (y / 32) * 2
			var i := 3
			var ajuste := (_h(placa, 1, 1) - 0.5) * 0.03
			# veios horizontais (metal escovado)
			var veio := _h(x / 7, y, 2)
			if veio < 0.18:
				ajuste -= 0.018
			elif veio > 0.86:
				ajuste += 0.016
			if lx == 0 or ly == 0:
				i += 1
			if lx == 31 or ly == 31:
				i -= 2
			elif lx == 30 or ly == 30:
				i -= 1
			im.set_pixel(x, y, _tingir(_g(i), ajuste))
	# Rebites de prata nos cantos de cada placa
	for py in range(2):
		for px in range(2):
			for c: Vector2i in [Vector2i(4, 4), Vector2i(27, 4), Vector2i(4, 27), Vector2i(27, 27)]:
				var x: int = px * 32 + c.x
				var y: int = py * 32 + c.y
				_p(im, x, y, _s(2))
				_p(im, x + 1, y + 1, _g(1))
	# Marcas de corte finas (como emendas de um diff)
	for k in range(4):
		var x := int(_h(k, 3, 5) * 20.0) + 6
		var y := int(_h(k, 4, 5) * 20.0) + 6
		var base := Vector2i((k % 2) * 32, (k / 2) * 32)
		for i in range(8):
			_p(im, base.x + x + i, base.y + y, Color(_s(1), 0.35))
	_salvar(im, "piso_grafite.png")


func _parede() -> void:
	# Painéis verticais com frestas, luzes de status e uma cornija de prata junto ao chão
	var im := _novo(64, 64)
	for y in range(64):
		for x in range(64):
			var lx := x % 16
			var profundidade := 1.0 - float(y) / 63.0
			var i := 3 - int(profundidade * 2.6)
			var ajuste := (_h(x / 16, 0, 11) - 0.5) * 0.03
			if _h(x, y / 2, 12) < 0.12:
				ajuste -= 0.02
			if lx == 0:
				i += 1
			if lx == 15:
				i -= 2
			im.set_pixel(x, y, _tingir(_g(i), ajuste))
	# Luzes de status (pontinhos) e frestas de ventilação
	for k in range(4):
		var x := k * 16 + 8
		for j in range(4):
			_r(im, x - 2, 14 + j * 5, 4, 1, _g(0))
		var cor := _s(1) if k % 2 == 0 else _g(5)
		_p(im, x, 40, cor)
		_p(im, x + 1, 40, cor)
	# Cornija junto ao chão (borda de baixo)
	_r(im, 0, 54, 64, 2, _g(5))
	_r(im, 0, 54, 64, 1, _s(2))
	_r(im, 0, 56, 64, 1, _s(0))
	_r(im, 0, 57, 64, 6, _g(4))
	_r(im, 0, 57, 64, 1, _g(6))
	_r(im, 0, 63, 64, 1, _g(1))
	_salvar(im, "parede_grafite.png")


func _faixa(nome: String, cor: Color) -> void:
	# Faixa de chão de cada linha (véu colorido, filete e cantos de prata)
	var w := 290
	var h := 56
	var im := _novo(w, h)
	_r(im, 0, 0, w, h, Color(cor, 0.1))
	for x in range(w):
		_p(im, x, 0, Color(cor, 0.85))
		_p(im, x, h - 1, Color(cor, 0.85))
		_p(im, x, 1, Color(cor, 0.35))
		_p(im, x, h - 2, Color(cor, 0.35))
	for y in range(h):
		_p(im, 0, y, Color(cor, 0.85))
		_p(im, w - 1, y, Color(cor, 0.85))
	for cx in [3, w - 11]:
		for cy in [3, h - 5]:
			_r(im, cx, cy, 8, 2, Color(_s(2), 0.9))
	_salvar(im, "faixa_%s.png" % nome)


# Runas, pedestais ------------------------------------------------------------------------------------
func _tablete() -> void:
	# Tablete de grafite 36x36 com moldura de prata; a janela de 28x28 é pintada pelo jogo
	var im := _novo(36, 36)
	for y in range(36):
		for x in range(36):
			var canto := (x < 2 and y < 2 - x) or (x > 33 and y < x - 33) or (x < 2 and y > 33 + x - 1) or (x > 33 and y > 33 + (35 - x))
			if canto:
				continue
			var i := 4
			if x < 2 or y < 2:
				i = 6
			elif x > 33 or y > 33:
				i = 2
			var cor := _g(i)
			if _h(x, y, 21) < 0.15:
				cor = _tingir(cor, -0.03)
			im.set_pixel(x, y, cor)
	for k in range(2, 34):
		_p(im, k, 3, _s(2))
		_p(im, k, 32, _s(0))
		_p(im, 3, k, _s(2))
		_p(im, 32, k, _s(0))
	for c in [Vector2i(1, 1), Vector2i(34, 1), Vector2i(1, 34), Vector2i(34, 34)]:
		_p(im, c.x, c.y, _s(3))
	_contorno(im, TINTA)
	_salvar(im, "tablete_conflito.png")


func _glifos() -> void:
	# 3 glifos 14x14 (selo, porta, interrogação) em tinta escura
	var im := _novo(42, 14)
	var t := Color(TINTA, 0.8)
	# Selo: anel com cruz
	for dy in range(-5, 6):
		for dx in range(-5, 6):
			var d := dx * dx + dy * dy
			if d >= 17 and d <= 26:
				_p(im, 7 + dx, 7 + dy, t)
	for k in range(3, 12):
		_p(im, 7, k, t)
		_p(im, k, 7, t)
	# Porta: arco
	var ox := 14
	for y in range(4, 13):
		_p(im, ox + 4, y, t)
		_p(im, ox + 9, y, t)
	for x in range(5, 9):
		_p(im, ox + x, 3, t)
	_p(im, ox + 4, 4, t)
	_p(im, ox + 9, 4, t)
	for y in range(8, 12):
		_p(im, ox + 7, y, Color(t, 0.6))
	for x in range(3, 11):
		_p(im, ox + x, 12, t)
	# Interrogação
	ox = 28
	for x in range(4, 9):
		_p(im, ox + x, 3, t)
	_p(im, ox + 3, 4, t)
	_p(im, ox + 9, 4, t)
	_p(im, ox + 9, 5, t)
	_p(im, ox + 8, 6, t)
	_p(im, ox + 7, 7, t)
	_p(im, ox + 6, 8, t)
	_p(im, ox + 6, 9, t)
	_p(im, ox + 6, 11, t)
	_p(im, ox + 6, 12, t)
	_salvar(im, "glifos_conflito.png")


func _pedestal(nome: String, cores: Array) -> void:
	var im := _novo(24, 32)
	# Base e coluna de grafite
	_r(im, 2, 26, 20, 5, _g(4))
	_r(im, 2, 26, 20, 1, _g(6))
	_r(im, 2, 30, 20, 1, _g(1))
	_r(im, 6, 12, 12, 14, _g(3))
	_r(im, 6, 12, 3, 14, _g(5))
	_r(im, 15, 12, 3, 14, _g(2))
	# Taça de prata no topo e a gema da cor da escolha
	_r(im, 3, 8, 18, 4, _s(1))
	_r(im, 3, 8, 18, 1, _s(3))
	_r(im, 4, 11, 16, 1, _s(0))
	var centro := Vector2(12, 5)
	for y in range(0, 9):
		for x in range(0, 24):
			var d := Vector2(x + 0.5, y + 0.5) - centro
			if absf(d.x) * 0.8 + absf(d.y) * 1.3 <= 5.0:
				var cor: Color = cores[0] if (cores.size() == 1 or x < 12) else cores[1]
				if d.y < -1.0:
					cor = cor.lightened(0.35)
				_p(im, x, y, cor)
	_contorno(im, TINTA)
	_salvar(im, "pedestal_%s.png" % nome)


# Barreira de glitch (a parede) e rachaduras -------------------------------------------------------
func _barreira() -> void:
	var w := 16
	var h := 256
	var im := _novo(w, h)
	var cores: Array[Color] = [MAGENTA, Color("12001A"), Color("12001A"), Color("B01E96"), Color("050008")]
	for by in range(h / 4):
		var desloc := 0
		if _h(by, 0, 31) < 0.2:
			desloc = int(_h(by, 1, 31) * 4.0) * 4
		for bx in range(4):
			var cor := cores[int(_h(bx + desloc, by, 32) * 5.0) % 5]
			if _h(bx, by, 33) < 0.06:
				cor = Color("FFB3F0")
			_r(im, bx * 4, by * 4, 4, 4, cor)
	for y in range(0, h, 3):
		_r(im, 0, y, w, 1, Color(0, 0, 0, 0.28))
	for y in range(h):
		_p(im, 0, y, Color(MAGENTA, 0.9))
		_p(im, w - 1, y, Color(MAGENTA, 0.9))
	# Pilares de grafite e prata nas pontas
	for tampa in [0, h - 14]:
		_r(im, 0, tampa, w, 14, _g(4))
		_r(im, 0, tampa, w, 1, _g(6))
		_r(im, 0, tampa + 13, w, 1, _g(1))
		_r(im, 0, tampa + 5, w, 2, _s(1))
		_r(im, 0, tampa + 5, w, 1, _s(3))
	_salvar(im, "barreira_conflito.png")


func _rachaduras() -> void:
	# Fendas de luz verde-água que saem do centro (y = 128) para as pontas; a luz vaza pelas frestas
	var w := 16
	var h := 256
	var im := _novo(w, h)
	var nucleo := Color(VERDE_AGUA.lightened(0.55), 0.95)
	for ramo in range(5):
		var x := 8 + int(_h(ramo, 0, 51) * 4.0) - 2
		for sentido: int in [-1, 1]:
			var xx := x
			for passo in range(0, 126):
				var y := 128 + sentido * passo
				var r := _h(passo, ramo * 2 + (1 if sentido > 0 else 0), 52)
				xx += (1 if r < 0.28 else (-1 if r > 0.72 else 0))
				xx = clampi(xx, 1, w - 2)
				var intensidade := 1.0 - float(passo) / 140.0
				_p(im, xx, y, Color(VERDE_AGUA, 0.9 * intensidade))
				_p(im, xx - 1, y, Color(VERDE_AGUA, 0.35 * intensidade))
				_p(im, xx + 1, y, Color(VERDE_AGUA, 0.35 * intensidade))
				if passo % 3 == 0:
					_p(im, xx, y, Color(nucleo, intensidade))
	_salvar(im, "rachaduras_verde.png")


# Decoração ----------------------------------------------------------------------------------------------------
func _rack() -> void:
	# Rack de servidor 24x40 com luzes que piscam (4 quadros de 24x40)
	var im := _novo(96, 40)
	for q in range(4):
		var ox := q * 24
		_r(im, ox + 2, 2, 20, 36, _g(3))
		_r(im, ox + 2, 2, 20, 1, _g(6))
		_r(im, ox + 2, 37, 20, 1, _g(1))
		_r(im, ox + 2, 2, 2, 36, _g(5))
		for baia in range(5):
			var y := 5 + baia * 6
			_r(im, ox + 5, y, 15, 4, _g(1))
			_r(im, ox + 5, y, 15, 1, _g(2))
			# luzes: cada baia tem uma luz que muda por quadro
			var acesa := (baia + q) % 3 == 0
			var cor := _s(3) if acesa else _g(4)
			if baia == 2 and q % 2 == 1:
				cor = OURO
			_p(im, ox + 17, y + 2, cor)
			_p(im, ox + 18, y + 2, cor)
			for k in range(3):
				_p(im, ox + 7 + k * 2, y + 2, _g(4))
	_contorno(im, TINTA)
	_salvar(im, "rack_servidor.png")


func _coluna(quebrada: bool, nome: String) -> void:
	var w := 20
	var h := 52 if not quebrada else 34
	var im := _novo(w, h)
	var topo := 6 if not quebrada else 2
	for y in range(topo, h - 6):
		for x in range(4, 16):
			var i := 5 if x < 7 else (4 if x < 11 else (3 if x < 14 else 2))
			if (x - 4) % 4 == 3:
				i -= 1
			if _h(x, y, 81) < 0.1:
				i -= 1
			im.set_pixel(x, y, _g(i))
	if quebrada:
		for x in range(4, 16):
			var corte := 2 + int(_h(x, 0, 82) * 7.0)
			for y in range(0, corte):
				im.set_pixel(x, y, Color(0, 0, 0, 0))
			_p(im, x, corte, _g(6))
	else:
		_r(im, 2, 2, 16, 5, _g(5))
		_r(im, 2, 2, 16, 1, _g(6))
		_r(im, 2, 6, 16, 1, _s(1))
		_r(im, 2, 7, 16, 1, _s(0))
	_r(im, 2, h - 6, 16, 6, _g(4))
	_r(im, 2, h - 6, 16, 1, _s(1))
	_r(im, 2, h - 1, 16, 1, _g(1))
	var fy := (h * 5) / 9
	_r(im, 4, fy, 12, 6, _s(0))
	_r(im, 4, fy, 12, 1, _s(2))
	_r(im, 4, fy + 5, 12, 1, _g(2))
	_r(im, 8, fy + 1, 4, 4, _g(1))
	_p(im, 9, fy + 2, MAGENTA if quebrada else _s(3))
	_contorno(im, TINTA)
	_salvar(im, nome)


func _colunas() -> void:
	_coluna(false, "coluna_grafite.png")
	_coluna(true, "coluna_quebrada_grafite.png")


func _resto(im: Image, cx: int, cy: int, rw: int, rh: int, semente: int) -> void:
	# Placa de metal quebrada (lasca de grafite com borda de prata)
	for y in range(cy - rh, cy + rh + 1):
		for x in range(cx - rw, cx + rw + 1):
			var dx := float(x - cx) / float(rw)
			var dy := float(y - cy) / float(rh)
			if dx * dx + dy * dy > 1.0 + (_h(x, y, semente) - 0.5) * 0.4:
				continue
			var luz := -dx * 0.6 - dy * 0.9
			var i := 3 + int(round(luz * 1.3))
			if _h(x, y, semente + 1) < 0.12:
				i -= 1
			im.set_pixel(x, y, _g(i))
	for x in range(cx - rw, cx + rw):
		var y: int = cy - rh + 1
		if im.get_pixel(x, y).a > 0.0:
			_p(im, x, y, _s(0))


func _restos() -> void:
	for k in range(3):
		var im := _novo(24, 16)
		_resto(im, 8, 10, 6, 4, 40 + k)
		_resto(im, 16, 9, 4 + k % 2, 3 + k % 2, 50 + k)
		if k > 0:
			_resto(im, 12, 6, 3, 3, 60 + k)
		_contorno(im, TINTA)
		_salvar(im, "restos_%d.png" % (k + 1))


func _fenda() -> void:
	# Emenda no chão (como a linha de um diff), com pontinhas de prata
	var im := _novo(32, 8)
	for x in range(2, 30):
		_p(im, x, 4, Color(_s(0), 0.55))
		_p(im, x, 5, Color(TINTA, 0.5))
	for x in range(2, 30, 6):
		_p(im, x, 3, Color(_s(2), 0.7))
	_salvar(im, "emenda_chao.png")


func _brilho(nome: String, cor: Color) -> void:
	var im := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	for y in range(48):
		for x in range(48):
			var d := Vector2(x - 23.5, y - 23.5).length() / 24.0
			im.set_pixel(x, y, Color(cor, pow(maxf(1.0 - d, 0.0), 2.0) * 0.65))
	_salvar(im, nome)


# Recolorir arte existente para grafite/prata ---------------------------------------------------------------------
func _recolorir(origem: String, destino: String, claridade: float) -> void:
	var im := Image.load_from_file(ProjectSettings.globalize_path(origem))
	if im == null:
		push_warning("sem origem: " + origem)
		return
	im.convert(Image.FORMAT_RGBA8)
	for y in range(im.get_height()):
		for x in range(im.get_width()):
			var c := im.get_pixel(x, y)
			if c.a == 0.0:
				continue
			var v := clampf(c.v * claridade, 0.0, 1.0)
			# Quase sem cor: grafite/prata com um sopro frio
			var novo := Color.from_hsv(0.6, clampf(c.s * 0.08, 0.0, 0.12), v, c.a)
			im.set_pixel(x, y, novo)
	_salvar(im, destino)
