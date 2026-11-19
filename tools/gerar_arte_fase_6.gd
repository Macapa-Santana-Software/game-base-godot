extends SceneTree
## Gerador da arte da Fase 6 (Ponto de Retorno), paleta "Concreto brutalista com sinalização" de docs/DESIGN_FASES.md.
## Não faz parte do jogo: desenha, pixel a pixel, os PNGs em res://fases/fase_6/arte/. Para regerar:
##   godot --headless --path . --script res://tools/gerar_arte_fase_6.gd
## O cenário é concreto cinza-quente com sinalização amarelo-preto. As cores de SIGNIFICADO ficam reservadas:
## ciano (o commit do revert e o Eidolon), magenta (o commit fantasma e o glitch) e vermelho (a emergência).

const SAIDA := "res://fases/fase_6/arte/"

var CONCRETO: Array[Color] = [Color("1D1C19"), Color("2E2C28"), Color("4A4741"), Color("6A665E"), Color("8B867C"), Color("A8A398"), Color("C4BFB2")]
const AMARELO := Color("F2C230")
const AMARELO_ESCURO := Color("B8901A")
const PRETO := Color("1B1A18")
const CIANO := Color("36D6E9")
const MAGENTA := Color("FF2BD6")
const VERMELHO := Color("D8423A")
const TINTA := Color("0F0E0D")


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAIDA))
	_piso()
	_parede()
	_faixa_alerta()
	_poco()
	_borda_poco()
	_ponte()
	_portoes()
	_prateleira()
	_cartucho()
	_glifos()
	_alavanca()
	_altar()
	_eco_eidolon()
	_pilar()
	_barreira_jersey()
	_caixas()
	_luz_emergencia()
	_estencil()
	_brilho("brilho_amarelo.png", AMARELO)
	_brilho("brilho_vermelho.png", VERMELHO)
	_brilho("brilho_ciano.png", CIANO)
	_recolorir("res://terminal/Sprites/obelisco_inativo.png", "obelisco_inativo_concreto.png", 1.0)
	_recolorir("res://terminal/Sprites/obelisco_ativo.png", "obelisco_ativo_concreto.png", 1.0)
	_recolorir("res://terminal/Sprites/plataforma_terminal.png", "plataforma_terminal_concreto.png", 1.2)
	_recolorir("res://GeneralNodes/ExitArea/portal_saida.png", "portal_saida_concreto.png", 1.0)
	print("[Arte Fase 6] pronto.")
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


func _c(i: int) -> Color:
	return CONCRETO[clampi(i, 0, CONCRETO.size() - 1)]


func _tingir(c: Color, k: float) -> Color:
	return Color(clampf(c.r + k, 0.0, 1.0), clampf(c.g + k * 0.97, 0.0, 1.0), clampf(c.b + k * 0.9, 0.0, 1.0), c.a)


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


## Listras diagonais amarelo-preto (sinalização de alerta) numa área.
func _alerta(im: Image, x0: int, y0: int, w: int, h: int, desloc: int = 0) -> void:
	for y in range(h):
		for x in range(w):
			var faixa := ((x + y + desloc) / 4) % 2
			im.set_pixel(x0 + x, y0 + y, AMARELO if faixa == 0 else PRETO)


# Chão e paredão -------------------------------------------------------------------------------------
func _piso() -> void:
	# Lajes de concreto 32x32 com juntas de dilatação, agregado, manchas e rachaduras finas (tileável 64x64)
	var im := _novo(64, 64)
	for y in range(64):
		for x in range(64):
			var lx := x % 32
			var ly := y % 32
			var laje := (x / 32) + (y / 32) * 2
			var i := 3
			var ajuste := (_h(laje, 1, 1) - 0.5) * 0.045
			var n := _h(x, y, 2)
			if n < 0.1:
				ajuste -= 0.035
			elif n > 0.93:
				ajuste += 0.035
			if lx == 0 or ly == 0:
				i -= 2
			elif lx == 1 or ly == 1:
				i += 1
			if lx == 31 or ly == 31:
				i -= 1
			im.set_pixel(x, y, _tingir(_c(i), ajuste))
	# Manchas de óleo/umidade e rachaduras
	for k in range(5):
		var cx := int(_h(k, 1, 3) * 56.0) + 4
		var cy := int(_h(k, 2, 3) * 56.0) + 4
		for dy in range(-4, 5):
			for dx in range(-5, 6):
				if dx * dx + dy * dy * 2 < 22 and _h(cx + dx, cy + dy, 4) < 0.7:
					_p(im, (cx + dx) % 64, (cy + dy) % 64, Color(0, 0, 0, 0.12))
	for k in range(4):
		var x := int(_h(k, 5, 5) * 40.0) + 8
		var y := int(_h(k, 6, 5) * 40.0) + 8
		for i in range(9):
			_p(im, x + i, y, _c(1))
			y += 1 if _h(i, k, 6) < 0.4 else 0
	_salvar(im, "piso_concreto.png")


func _parede() -> void:
	# Painéis de concreto moldado com furos de fôrma e uma faixa de alerta junto ao chão
	var im := _novo(64, 64)
	for y in range(64):
		for x in range(64):
			var lx := x % 32
			var profundidade := 1.0 - float(y) / 63.0
			var i := 3 - int(profundidade * 2.4)
			var ajuste := (_h(x / 32, y / 24, 11) - 0.5) * 0.04
			if _h(x, y, 12) < 0.1:
				ajuste -= 0.03
			if lx == 0:
				i -= 1
			elif lx == 1:
				i += 1
			im.set_pixel(x, y, _tingir(_c(i), ajuste))
	# Furos de fôrma (grade)
	for fx in [8, 24, 40, 56]:
		for fy in [10, 28]:
			_r(im, fx - 1, fy - 1, 3, 3, _c(0))
			_p(im, fx, fy, _c(1))
			_p(im, fx - 1, fy - 1, _c(5))
	# Junta horizontal e a faixa de alerta junto ao chão
	_r(im, 0, 36, 64, 1, _c(1))
	_r(im, 0, 37, 64, 1, _c(4))
	_alerta(im, 0, 52, 64, 5)
	_r(im, 0, 51, 64, 1, _c(0))
	_r(im, 0, 57, 64, 1, _c(0))
	_r(im, 0, 58, 64, 5, _c(2))
	_r(im, 0, 58, 64, 1, _c(5))
	_r(im, 0, 63, 64, 1, _c(0))
	_salvar(im, "parede_concreto.png")


func _faixa_alerta() -> void:
	var im := _novo(32, 8)
	_alerta(im, 0, 0, 32, 8)
	for x in range(32):
		_p(im, x, 0, _c(0))
		_p(im, x, 7, _c(0))
	_salvar(im, "faixa_alerta.png")


# Poço da Área 1 -------------------------------------------------------------------------------------------
func _poco() -> void:
	var w := 160
	var h := 256
	var im := _novo(w, h)
	var pal: Array[Color] = [Color("0A0A0B"), Color("101113"), Color("17181B"), Color("1F2125"), Color("2A2D32"), Color("383C42")]
	var bayer := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
	for y in range(h):
		for x in range(w):
			var v := pow(float(y) / float(h - 1), 1.3) * float(pal.size() - 1)
			var idx := clampi(int(floor(v + float(bayer[(y % 4) * 4 + (x % 4)]) / 16.0)), 0, pal.size() - 1)
			im.set_pixel(x, y, pal[idx])
	# Paredes do poço: faixas verticais de concreto bruto nas laterais
	for y in range(h):
		for x in range(10):
			var sombra := 1.0 - float(x) / 10.0
			var limite := float(bayer[(y % 4) * 4 + (x % 4)]) / 16.0
			if sombra > limite:
				_p(im, x, y, Color(0.02, 0.02, 0.02, 0.8))
				_p(im, w - 1 - x, y, Color(0.02, 0.02, 0.02, 0.8))
	# Canos e cabos descendo para o fundo, e luzinhas de serviço
	for k in range(4):
		var x := 22 + int(_h(k, 0, 21) * 110.0)
		for y in range(int(_h(k, 1, 21) * 60.0), h):
			_p(im, x, y, Color(_c(2), 0.55))
			_p(im, x + 1, y, Color(_c(1), 0.55))
	for k in range(6):
		var x := 16 + int(_h(k, 0, 22) * 128.0)
		var y := 90 + int(_h(k, 1, 22) * 150.0)
		_p(im, x, y, Color(AMARELO, 0.8))
	_salvar(im, "poco_abismo.png")


func _borda_poco() -> void:
	# Beira do poço (lado esquerdo; o direito é espelhado): lábio de concreto e faixa de alerta
	var w := 32
	var h := 256
	var im := _novo(w, h)
	for y in range(h):
		var borda := 22 + int(_h(y / 3, 0, 31) * 2.0)
		for x in range(14, borda):
			var i := 3 + (1 if x < 18 else 0)
			if _h(x, y, 32) < 0.14:
				i -= 1
			im.set_pixel(x, y, _c(i))
		# faixa de alerta de 3px na beira
		for k in range(3):
			var faixa := ((borda + k + y) / 4) % 2
			im.set_pixel(borda + k, y, AMARELO if faixa == 0 else PRETO)
		_p(im, borda + 3, y, Color(0, 0, 0, 0.55))
		_p(im, borda + 4, y, Color(0, 0, 0, 0.3))
	# Luzes de sinalização na beira
	for y0 in [20, 56, 190, 228]:
		_r(im, 25, y0, 2, 2, AMARELO)
		_p(im, 24, y0, Color(AMARELO, 0.4))
	_salvar(im, "borda_poco.png")


# Ponte (passarela de aço) --------------------------------------------------------------------------------------
func _passarela(im: Image, x0: int, w: int, apagada: bool) -> void:
	# Piso de grade de aço com trilhos de alerta em cima e embaixo
	for y in range(64):
		for x in range(w):
			var i := 3
			if (x + y) % 4 == 0:
				i = 2
			if y < 5 or y > 58:
				continue
			if _h(x, y, 71) < 0.08:
				i -= 1
			im.set_pixel(x0 + x, y, _c(i))
	_alerta(im, x0, 0, w, 5)
	_alerta(im, x0, 59, w, 5, 2)
	for x in range(w):
		_p(im, x0 + x, 5, _c(0))
		_p(im, x0 + x, 58, _c(0))
	for k in range(w / 16):
		var x := x0 + k * 16 + 8
		for y in [12, 31, 50]:
			_p(im, x, y, _c(5))
			_p(im, x + 1, y + 1, _c(0))


func _ponte() -> void:
	# Toco (as pontas da passarela, com o corte limpo)
	var toco := _novo(40, 64)
	_passarela(toco, 0, 40, false)
	for y in range(64):
		toco.set_pixel(39, y, _c(0))
		toco.set_pixel(38, y, _c(1))
	_salvar(toco, "ponte_toco.png")
	# Tábuas ruins (o commit sabotador): grade em glitch magenta
	var ruim := _novo(80, 64)
	for by in range(16):
		for bx in range(20):
			var r := _h(bx, by, 81)
			var cor := MAGENTA if r < 0.4 else (Color("12001A") if r < 0.8 else Color("B01E96"))
			if _h(bx, by, 82) < 0.07:
				cor = Color("FFB3F0")
			_r(ruim, bx * 4, by * 4, 4, 4, cor)
	for y in range(0, 64, 3):
		_r(ruim, 0, y, 80, 1, Color(0, 0, 0, 0.3))
	_salvar(ruim, "ponte_ruim.png")
	# Passarela inteira
	var solida := _novo(160, 64)
	_passarela(solida, 0, 160, false)
	_salvar(solida, "ponte_solida.png")


# Portões ---------------------------------------------------------------------------------------------------------
func _portao(nome: String, cor_luz: Color, tem_alerta: bool) -> void:
	var w := 16
	var h := 256
	var im := _novo(w, h)
	for y in range(h):
		for x in range(w):
			var i := 3
			if x < 2:
				i = 5
			elif x > 13:
				i = 1
			if _h(x, y, 91) < 0.1:
				i -= 1
			im.set_pixel(x, y, _c(i))
	# Chapas horizontais e rebites
	for y in range(0, h, 32):
		_r(im, 0, y, w, 1, _c(1))
		_r(im, 0, y + 1, w, 1, _c(5))
		_p(im, 3, y + 5, _c(5))
		_p(im, 12, y + 5, _c(5))
	if tem_alerta:
		for k in range(0, h, 64):
			_alerta(im, 2, k + 24, 12, 12, k)
	# Luz de status no meio
	_r(im, 6, 124, 4, 8, _c(0))
	_r(im, 7, 126, 2, 4, cor_luz)
	# Pilares de aço nas pontas
	for tampa in [0, h - 14]:
		_r(im, 0, tampa, w, 14, _c(4))
		_r(im, 0, tampa, w, 1, _c(6))
		_r(im, 0, tampa + 13, w, 1, _c(0))
		_alerta(im, 0, tampa + 5, w, 3)
	_salvar(im, nome)


func _portoes() -> void:
	_portao("portao_inspecao.png", AMARELO, true)
	_portao("portao_camara.png", VERMELHO, false)


# Props ---------------------------------------------------------------------------------------------------------------
func _prateleira() -> void:
	var im := _novo(64, 28)
	# Estrutura: duas pernas e duas prateleiras de aço
	_r(im, 2, 2, 3, 24, _c(4))
	_r(im, 59, 2, 3, 24, _c(4))
	for y in [10, 22]:
		_r(im, 2, y, 60, 3, _c(3))
		_r(im, 2, y, 60, 1, _c(6))
		_r(im, 2, y + 2, 60, 1, _c(1))
	_alerta(im, 2, 0, 60, 2)
	_contorno(im, TINTA)
	_salvar(im, "prateleira_stash.png")
	# Caixote do stash (12x12)
	var caixa := _novo(12, 12)
	_r(caixa, 0, 0, 12, 12, Color("C99A2E"))
	_r(caixa, 0, 0, 12, 2, Color("F2C230"))
	_r(caixa, 0, 10, 12, 2, Color("8A6A1E"))
	_r(caixa, 5, 0, 2, 12, Color("8A6A1E"))
	_contorno(caixa, TINTA)
	_salvar(caixa, "caixa_stash.png")


func _cartucho() -> void:
	# Moldura de aço 34x34 de um arquivo da Câmara; a janela 26x26 é pintada pelo jogo
	var im := _novo(34, 34)
	for y in range(34):
		for x in range(34):
			var canto := (x < 2 and y < 2 - x) or (x > 31 and y < x - 31) or (x < 2 and y > 31 + x - 1) or (x > 31 and y > 31 + (33 - x))
			if canto:
				continue
			var i := 3
			if x < 2 or y < 2:
				i = 5
			elif x > 31 or y > 31:
				i = 1
			im.set_pixel(x, y, _c(i))
	_alerta(im, 4, 1, 26, 2)
	_alerta(im, 4, 31, 26, 2, 3)
	_contorno(im, TINTA)
	_salvar(im, "cartucho_arquivo.png")


func _glifos() -> void:
	# Dois glifos 14x14: mapa (planta) e faísca (experimento)
	var im := _novo(28, 14)
	var t := Color(TINTA, 0.8)
	# Mapa dobrado
	for k in range(2, 12):
		_p(im, k, 3, t)
		_p(im, k, 11, t)
	for k in range(3, 12):
		_p(im, 2, k, t)
		_p(im, 11, k, t)
	for k in range(3, 11):
		_p(im, 5, k, Color(t, 0.6))
		_p(im, 8, k, Color(t, 0.6))
	# Faísca
	var ox := 14
	var pts := [Vector2i(8, 2), Vector2i(5, 7), Vector2i(7, 7), Vector2i(5, 12)]
	for i in range(3):
		var a: Vector2i = pts[i]
		var b: Vector2i = pts[i + 1]
		var n := maxi(absi(b.x - a.x), absi(b.y - a.y))
		for j in range(n + 1):
			var f := float(j) / float(maxi(n, 1))
			_p(im, ox + int(round(lerpf(a.x, b.x, f))), int(round(lerpf(a.y, b.y, f))), t)
			_p(im, ox + int(round(lerpf(a.x, b.x, f))) + 1, int(round(lerpf(a.y, b.y, f))), t)
	_salvar(im, "glifos_arquivo.png")


func _alavanca() -> void:
	# Dois quadros 16x24: alavanca para cima (esperando) e para baixo (puxada)
	var im := _novo(32, 24)
	for q in range(2):
		var ox := q * 16
		_r(im, ox + 2, 17, 12, 6, _c(4))
		_r(im, ox + 2, 17, 12, 1, _c(6))
		_r(im, ox + 2, 22, 12, 1, _c(1))
		_alerta(im, ox + 3, 19, 10, 2)
		_r(im, ox + 6, 14, 4, 4, _c(2))
		# Haste e manopla
		if q == 0:
			for y in range(3, 15):
				_p(im, ox + 7, y, _c(5))
				_p(im, ox + 8, y, _c(3))
			_r(im, ox + 5, 1, 6, 4, VERMELHO)
			_r(im, ox + 5, 1, 6, 1, Color("F08A84"))
		else:
			for k in range(10):
				_p(im, ox + 8 + k / 2, 14 - k / 3, _c(5))
				_p(im, ox + 9 + k / 2, 14 - k / 3, _c(3))
			_r(im, ox + 11, 9, 4, 4, Color("3DDB7B"))
	_contorno(im, TINTA)
	_salvar(im, "alavanca.png")


func _altar() -> void:
	var im := _novo(24, 32)
	_r(im, 2, 26, 20, 5, _c(4))
	_r(im, 2, 26, 20, 1, _c(6))
	_r(im, 2, 30, 20, 1, _c(1))
	_r(im, 6, 12, 12, 14, _c(3))
	_r(im, 6, 12, 3, 14, _c(5))
	_r(im, 15, 12, 3, 14, _c(2))
	_r(im, 3, 7, 18, 5, _c(4))
	_r(im, 3, 7, 18, 1, _c(6))
	_alerta(im, 4, 10, 16, 2)
	# Relógio de retorno (seta anti-horária) em ciano
	for dy in range(-4, 5):
		for dx in range(-4, 5):
			var d := dx * dx + dy * dy
			if d >= 9 and d <= 16 and not (dx > 0 and dy < 0):
				_p(im, 12 + dx, 3 + dy, CIANO)
	_p(im, 12, 0, CIANO)
	_p(im, 13, 1, CIANO)
	_p(im, 11, 1, CIANO)
	_contorno(im, TINTA)
	_salvar(im, "altar_retorno.png")


func _eco_eidolon() -> void:
	# Um vulto de capuz, em ciano translúcido (o Eidolon, só um eco)
	var im := _novo(24, 32)
	for y in range(30):
		var largura := 4 + int(float(y) * 0.28)
		if y < 8:
			largura = 3 + int(sin(float(y) / 8.0 * PI) * 4.0)
		for x in range(-largura, largura + 1):
			var cor := Color(CIANO, 0.35 + 0.35 * (1.0 - float(y) / 30.0))
			if absi(x) >= largura - 1:
				cor = Color(Color("9BE7FF"), 0.8)
			_p(im, 12 + x, 1 + y, cor)
	# Rosto vazio e olhos
	_r(im, 9, 7, 6, 6, Color(0.02, 0.05, 0.08, 0.85))
	_p(im, 10, 9, Color("CFF6FF"))
	_p(im, 13, 9, Color("CFF6FF"))
	# Borda que desfaz embaixo (partículas)
	for k in range(10):
		_p(im, 4 + int(_h(k, 0, 61) * 16.0), 26 + int(_h(k, 1, 61) * 5.0), Color("9BE7FF", 0.5))
	_salvar(im, "eidolon_eco.png")


func _pilar() -> void:
	var im := _novo(20, 52)
	for y in range(52):
		for x in range(2, 18):
			var i := 5 if x < 6 else (4 if x < 11 else (3 if x < 15 else 2))
			if _h(x, y, 81) < 0.1:
				i -= 1
			im.set_pixel(x, y, _c(i))
	_alerta(im, 2, 36, 16, 8)
	_r(im, 0, 0, 20, 4, _c(5))
	_r(im, 0, 0, 20, 1, _c(6))
	_r(im, 0, 48, 20, 4, _c(4))
	_contorno(im, TINTA)
	_salvar(im, "pilar_concreto.png")


func _barreira_jersey() -> void:
	var im := _novo(36, 18)
	for y in range(18):
		var inset := maxi(0, (y - 6) / 3 - 0)
		for x in range(2 + (18 - y) / 6 * 0, 34):
			var i := 4 if y < 4 else 3
			if y > 12:
				i = 2
			if _h(x, y, 71) < 0.1:
				i -= 1
			var xx := x
			if xx >= 2 + inset and xx < 34 - inset:
				im.set_pixel(xx, y, _c(i))
	_alerta(im, 6, 5, 24, 4)
	_contorno(im, TINTA)
	_salvar(im, "barreira_jersey.png")


func _caixas() -> void:
	for k in range(2):
		var im := _novo(18, 16)
		_r(im, 1, 1, 16, 14, Color("7A5A32") if k == 0 else _c(3))
		_r(im, 1, 1, 16, 2, Color("A07A48") if k == 0 else _c(5))
		_r(im, 1, 13, 16, 2, Color("503A1E") if k == 0 else _c(1))
		_r(im, 8, 1, 2, 14, Color("503A1E") if k == 0 else _c(1))
		if k == 1:
			_alerta(im, 2, 6, 14, 3)
		_contorno(im, TINTA)
		_salvar(im, "caixa_%d.png" % (k + 1))


func _luz_emergencia() -> void:
	# 4 quadros 12x12: giroflex vermelho (a lâmpada gira)
	var im := _novo(48, 12)
	for q in range(4):
		var ox := q * 12
		_r(im, ox + 2, 8, 8, 3, _c(2))
		_r(im, ox + 2, 8, 8, 1, _c(5))
		for dy in range(-4, 1):
			for dx in range(-4, 5):
				if dx * dx + dy * dy * 2 <= 14:
					var cor := VERMELHO
					if (dx + q * 2) % 4 == 0:
						cor = Color("FF9A90")
					_p(im, ox + 6 + dx, 7 + dy, cor)
	_contorno(im, TINTA)
	_salvar(im, "luz_emergencia.png")


func _estencil() -> void:
	# Números pintados no chão (1, 2, 3), em amarelo gasto
	var digitos := {
		1: ["..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###."],
		2: [".###.", "#...#", "....#", "..##.", ".#...", "#....", "#####"],
		3: [".###.", "#...#", "....#", "..##.", "....#", "#...#", ".###."],
	}
	for n in digitos.keys():
		var im := _novo(20, 28)
		var linhas: Array = digitos[n]
		for y in range(linhas.size()):
			for x in range(5):
				if str(linhas[y])[x] == "#":
					_r(im, 2 + x * 3, 2 + y * 3, 3, 3, Color(AMARELO, 0.45))
		_salvar(im, "estencil_%d.png" % n)


func _brilho(nome: String, cor: Color) -> void:
	var im := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	for y in range(48):
		for x in range(48):
			var d := Vector2(x - 23.5, y - 23.5).length() / 24.0
			im.set_pixel(x, y, Color(cor, pow(maxf(1.0 - d, 0.0), 2.0) * 0.6))
	_salvar(im, nome)


# Recolorir arte existente para concreto/âmbar ------------------------------------------------------------------------
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
			# Cinza-quente de concreto, com um sopro de amarelo nas partes mais saturadas
			var sat := clampf(c.s * 0.18, 0.0, 0.2)
			im.set_pixel(x, y, Color.from_hsv(0.11, sat, v, c.a))
	_salvar(im, destino)
