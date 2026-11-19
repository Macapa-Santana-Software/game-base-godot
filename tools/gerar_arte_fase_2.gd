extends SceneTree
## Gerador da arte da Fase 2 (Cânion de brasa). Não faz parte do jogo: desenha, pixel a pixel, os PNGs
## em res://fases/fase_2/arte/ na paleta de docs/DESIGN_FASES.md. Rode quando quiser regerar a arte:
##   godot --headless --path . --script res://tools/gerar_arte_fase_2.gd
## A luz vem sempre de cima e da esquerda; cada material tem uma rampa de tons (escuro -> claro).

const SAIDA := "res://fases/fase_2/arte/"

# Rampas de tons ---------------------------------------------------------------------------------
var ROCHA: Array[Color] = [Color("150A09"), Color("2A1512"), Color("3E2018"), Color("5C2E22"), Color("763B2B"), Color("8E4A34")]
var COBRE: Array[Color] = [Color("4A2014"), Color("7C3A22"), Color("B5532E"), Color("D2703F"), Color("E88C57")]
var BRASA: Array[Color] = [Color("7A2418"), Color("B83A27"), Color("FF5A3C"), Color("FF9A6B"), Color("FFD2B0")]
var CARVAO: Array[Color] = [Color("231E1E"), Color("342D2D"), Color("4A4343"), Color("665C5C"), Color("857A78")]
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAIDA))
	_piso()
	_parede()
	_abismo()
	_borda()
	_cristais()
	_pedras()
	_colunas()
	_bandeira()
	_ponte()
	_marcadores()
	_peca()
	_recolorir("res://terminal/Sprites/obelisco_inativo.png", "obelisco_inativo_brasa.png")
	_recolorir("res://terminal/Sprites/obelisco_ativo.png", "obelisco_ativo_brasa.png")
	_recolorir("res://terminal/Sprites/plataforma_terminal.png", "plataforma_terminal_brasa.png")
	_recolorir("res://GeneralNodes/ExitArea/portal_saida.png", "portal_saida_brasa.png")
	print("[Arte Fase 2] pronto.")
	quit()


# Utilidades -------------------------------------------------------------------------------------
func _novo(w: int, h: int) -> Image:
	var im := Image.create(w, h, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	return im


func _salvar(im: Image, nome: String) -> void:
	im.save_png(ProjectSettings.globalize_path(SAIDA + nome))


## Ruído determinístico 0..1 por posição.
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


func _tom(rampa: Array[Color], i: int) -> Color:
	return rampa[clampi(i, 0, rampa.size() - 1)]


## Contorno escuro de 1px ao redor da parte opaca.
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


# Chão ---------------------------------------------------------------------------------------------
func _piso() -> void:
	var im := _novo(64, 64)
	for sy in range(4):
		for sx in range(4):
			# Cada laje muda só um pouco de brilho (sem "xadrez"); o relevo vem do biselado e do grão.
			var brilho := (_h(sx, sy, 1) - 0.5) * 0.05
			for ly in range(16):
				for lx in range(16):
					var x := sx * 16 + lx
					var y := sy * 16 + ly
					var i := 3
					var n := _h(x, y, 2)
					var ajuste := 0.0
					if n < 0.18:
						ajuste = -0.03
					elif n > 0.88:
						ajuste = 0.03
					# Biselado: luz de cima/esquerda, sombra embaixo/direita (a junta)
					if lx == 0 or ly == 0:
						i += 1
					if lx == 15 or ly == 15:
						i -= 2
					elif lx == 14 or ly == 14:
						i -= 1
					var cor := _tom(ROCHA, i)
					cor = Color(cor.r + brilho + ajuste, cor.g + (brilho + ajuste) * 0.7, cor.b + (brilho + ajuste) * 0.6)
					im.set_pixel(x, y, cor)
			var base := 3
			# Rachaduras: caminhada aleatória dentro da laje
			if _h(sx, sy, 3) < 0.45:
				var px := 3 + int(_h(sx, sy, 4) * 9.0)
				var py := 3 + int(_h(sx, sy, 5) * 5.0)
				var brasa := _h(sx, sy, 6) < 0.3
				for passo in range(8):
					var gx := sx * 16 + clampi(px, 2, 13)
					var gy := sy * 16 + clampi(py, 2, 13)
					var cor := _tom(ROCHA, 1)
					if brasa and passo % 2 == 0:
						cor = Color(BRASA[1], 0.9)
					im.set_pixel(gx, gy, cor)
					if not brasa:
						im.set_pixel(mini(gx + 1, 63), gy, _tom(ROCHA, base + 1))
					var r := _h(gx, gy, 7)
					px += (1 if r < 0.4 else (-1 if r < 0.6 else 0))
					py += 1 if r > 0.35 else 0
	_salvar(im, "piso_canion.png")


func _parede() -> void:
	# Paredão de cima: a borda que toca o chão fica embaixo (y = 63); embaixo do jogo basta espelhar.
	var im := _novo(64, 64)
	var linhas := [[20, 14, 18, 12], [10, 24, 16, 14], [16, 12, 22, 14], [24, 10, 12, 18], [8, 20, 18, 18]]
	var alturas := [14, 12, 16, 10, 12]
	var y0 := 0
	for fila in range(5):
		var x0 := 0
		for ci in range(4):
			var larg: int = linhas[fila][ci]
			var variacao := int(_h(fila, ci, 11) * 3.0) - 1
			for ly in range(alturas[fila]):
				for lx in range(larg):
					var x := x0 + lx
					var y := y0 + ly
					var profundidade := 1.0 - float(y) / 63.0  # 1 = longe do chão
					var i := 4 - int(profundidade * 4.4) + variacao
					var n := _h(x, y, 12)
					if n < 0.13:
						i -= 1
					elif n > 0.92:
						i += 1
					if ly == 0:
						i += 1
					if ly == alturas[fila] - 1 or lx == larg - 1:
						i -= 2
					im.set_pixel(x % 64, y, _tom(ROCHA, i))
			x0 += larg
		y0 += alturas[fila]
	# Borda irregular (periódica, para emendar): o que passa dela fica transparente
	for x in range(64):
		var corte := 59 + int(2.0 * sin(float(x) / 64.0 * TAU * 2.0) + 1.5 * sin(float(x) / 64.0 * TAU * 5.0) + _h(x, 0, 13) * 1.5)
		for y in range(corte + 1, 64):
			im.set_pixel(x, y, Color(0, 0, 0, 0))
		im.set_pixel(x, corte, COBRE[1])
		if corte - 1 >= 0:
			im.set_pixel(x, corte - 1, COBRE[0])
	_salvar(im, "parede_canion.png")


func _abismo() -> void:
	var w := 160
	var h := 256
	var im := _novo(w, h)
	var pal: Array[Color] = [Color("090404"), Color("120707"), Color("1E0C0B"), Color("2E100D"), Color("4A1710"), Color("70231A"), Color("A03323"), Color("D44B2D")]
	for y in range(h):
		for x in range(w):
			var v := pow(float(y) / float(h - 1), 1.7) * float(pal.size() - 1)
			var idx := clampi(int(floor(v + float(BAYER[(y % 4) * 4 + (x % 4)]) / 16.0)), 0, pal.size() - 1)
			im.set_pixel(x, y, pal[idx])
	# Silhuetas de pedras que sobem do fundo (duas camadas, a da frente mais escura)
	var camadas := [[26, Color("230E0C"), 3], [14, Color("120706"), 7]]
	for camada in camadas:
		var altura_max: int = camada[0]
		var cor: Color = camada[1]
		var semente: int = camada[2]
		for x in range(w):
			var topo := h - int(altura_max * (0.35 + 0.65 * _h(x / 6, 0, semente)) + 3.0 * sin(float(x) * 0.21 + semente))
			for y in range(topo, h):
				im.set_pixel(x, y, cor)
	# Sombra nas paredes laterais do abismo (pontilhada)
	for y in range(h):
		for x in range(14):
			var sombra := 1.0 - float(x) / 14.0
			var limite := float(BAYER[(y % 4) * 4 + (x % 4)]) / 16.0
			if sombra > limite:
				_p(im, x, y, Color(0.03, 0.01, 0.01, 0.85))
				_p(im, w - 1 - x, y, Color(0.03, 0.01, 0.01, 0.85))
	# Fios de calor
	for k in range(9):
		var yy := 120 + int(_h(k, 1, 21) * 120.0)
		var xx := int(_h(k, 2, 21) * 100.0) + 20
		for i in range(18 + int(_h(k, 3, 21) * 20.0)):
			_p(im, xx + i, yy, Color(BRASA[3], 0.18))
	_salvar(im, "abismo_canion.png")


func _borda() -> void:
	# Beira do abismo (lado esquerdo; o direito é espelhado): lábio de rocha, faixa de cobre,
	# sombra sobre o abismo e cristais apontando para dentro dele. O corredor da ponte fica limpo.
	var w := 32
	var h := 256
	var im := _novo(w, h)
	for y in range(h):
		var jag := int(_h(y / 2, 0, 31) * 2.0)
		var borda := 22 + jag
		for x in range(14, borda):
			var i := 3 + (1 if x < 18 else 0)
			if _h(x, y, 32) < 0.15:
				i -= 1
			if y % 16 == 0:
				i += 1
			im.set_pixel(x, y, _tom(ROCHA, i))
		im.set_pixel(borda, y, COBRE[3])
		im.set_pixel(borda + 1, y, COBRE[2])
		im.set_pixel(borda + 2, y, COBRE[0])
		_p(im, borda + 3, y, Color(0.03, 0.01, 0.01, 0.6))
		_p(im, borda + 4, y, Color(0.03, 0.01, 0.01, 0.3))
	for y0 in [14, 38, 66, 90, 172, 196, 222, 244]:
		var tamanho := 6 + int(_h(y0, 0, 33) * 5.0)
		_cristal_lateral(im, 24, y0, tamanho)
	_salvar(im, "borda_canion.png")


func _cristal_lateral(im: Image, base_x: int, cy: int, comprimento: int) -> void:
	var meia := 3
	for i in range(comprimento):
		var largura := int(round(float(meia) * (1.0 - float(i) / float(comprimento))))
		for dy in range(-largura, largura + 1):
			var cor := BRASA[2] if dy < 0 else BRASA[1]
			if dy == -largura and largura > 0:
				cor = BRASA[3]
			if dy == 0:
				cor = BRASA[3]
			_p(im, base_x + i, cy + dy, cor)
	_p(im, base_x + comprimento - 1, cy, BRASA[4])


# Cristais, pedras, colunas -----------------------------------------------------------------------
func _cristal(im: Image, cx: int, base_y: int, h: int, w: int) -> void:
	var topo := base_y - h
	for y in range(topo, base_y + 1):
		var t := float(y - topo) / float(maxi(h, 1))
		var meia := int(round(float(w) / 2.0 * minf(1.0, t / 0.4))) if t < 0.4 else int(round(float(w) / 2.0))
		for x in range(cx - meia, cx + meia + 1):
			var cor := BRASA[3] if x < cx else BRASA[1]
			if x == cx:
				cor = BRASA[4] if y < base_y - 2 else BRASA[2]
			elif x == cx - 1 and t > 0.3:
				cor = BRASA[2]
			if y == base_y:
				cor = BRASA[0]
			_p(im, x, y, cor)


func _cristais() -> void:
	# a: cacho de três; b: um cristal alto; c: dois pequenos
	var a := _novo(28, 28)
	_cristal(a, 8, 25, 13, 6)
	_cristal(a, 15, 26, 22, 8)
	_cristal(a, 22, 25, 11, 5)
	_contorno(a, ROCHA[0])
	_sombra_base(a, 14, 26, 11)
	_salvar(a, "cristal_a.png")
	var b := _novo(16, 32)
	_cristal(b, 8, 29, 26, 8)
	_contorno(b, ROCHA[0])
	_sombra_base(b, 8, 30, 6)
	_salvar(b, "cristal_b.png")
	var c := _novo(20, 16)
	_cristal(c, 6, 13, 9, 5)
	_cristal(c, 13, 13, 12, 6)
	_contorno(c, ROCHA[0])
	_sombra_base(c, 10, 14, 8)
	_salvar(c, "cristal_c.png")


func _sombra_base(im: Image, cx: int, y: int, meia: int) -> void:
	for x in range(cx - meia, cx + meia + 1):
		for dy in range(0, 2):
			if im.get_pixel(clampi(x, 0, im.get_width() - 1), clampi(y + dy, 0, im.get_height() - 1)).a == 0.0:
				_p(im, x, y + dy, Color(0, 0, 0, 0.35 - dy * 0.15))


func _pedra(im: Image, cx: int, cy: int, rw: int, rh: int, semente: int) -> void:
	for y in range(cy - rh, cy + rh + 1):
		for x in range(cx - rw, cx + rw + 1):
			var dx := float(x - cx) / float(rw)
			var dy := float(y - cy) / float(rh)
			if dx * dx + dy * dy > 1.0 + (_h(x, y, semente) - 0.5) * 0.3:
				continue
			var luz := -dx * 0.6 - dy * 0.9
			var i := 3 + int(round(luz * 1.4))
			if _h(x, y, semente + 1) < 0.12:
				i -= 1
			im.set_pixel(x, y, _tom(ROCHA, i))


func _pedras() -> void:
	for k in range(3):
		var im := _novo(24, 16)
		_pedra(im, 8, 10, 6, 4, 40 + k)
		_pedra(im, 16, 9, 4 + k % 2, 3 + k % 2, 50 + k)
		if k > 0:
			_pedra(im, 12, 6, 3, 3, 60 + k)
		_contorno(im, ROCHA[0])
		_salvar(im, "pedras_%d.png" % (k + 1))
	# Pedaço de piso com brasa: decalque de rachadura brilhante
	var d := _novo(32, 16)
	var px := 2
	var py := 8
	for i in range(28):
		var cor := Color(BRASA[2], 0.9) if i % 3 != 1 else Color(BRASA[3], 0.95)
		_p(d, px, py, cor)
		_p(d, px, py + 1, Color(BRASA[0], 0.5))
		var r := _h(i, 1, 70)
		px += 1
		py += (1 if r < 0.3 else (-1 if r < 0.6 else 0))
		py = clampi(py, 2, 13)
	_salvar(d, "rachadura_brasa.png")


func _coluna(quebrada: bool, nome: String) -> void:
	var w := 20
	var h := 52 if not quebrada else 36
	var im := _novo(w, h)
	var topo := 6 if not quebrada else 2
	# Fuste com caneluras (esquerda clara, direita escura)
	for y in range(topo, h - 6):
		var quebra := 0
		if quebrada:
			quebra = int(_h(y, 0, 80) * 0.0)
		for x in range(4, 16):
			var i := 4 if x < 7 else (3 if x < 11 else (2 if x < 14 else 1))
			if (x - 4) % 4 == 3:
				i -= 1
			if _h(x, y, 81) < 0.1:
				i -= 1
			im.set_pixel(x, y + quebra, _tom(ROCHA, i))
	if quebrada:
		# Topo irregular e lascado
		for x in range(4, 16):
			var corte := 2 + int(_h(x, 0, 82) * 7.0)
			for y in range(0, corte):
				im.set_pixel(x, y, Color(0, 0, 0, 0))
			_p(im, x, corte, ROCHA[5])
	else:
		_r(im, 2, 2, 16, 5, _tom(ROCHA, 4))
		_r(im, 2, 6, 16, 1, _tom(ROCHA, 1))
		_r(im, 2, 2, 16, 1, _tom(ROCHA, 5))
	# Base
	_r(im, 2, h - 6, 16, 6, _tom(ROCHA, 3))
	_r(im, 2, h - 6, 16, 1, _tom(ROCHA, 5))
	_r(im, 2, h - 1, 16, 1, _tom(ROCHA, 0))
	# Faixa de cobre com o losango do Conselho
	var fy := (h * 5) / 9
	_r(im, 4, fy, 12, 6, COBRE[2])
	_r(im, 4, fy, 12, 1, COBRE[3])
	_r(im, 4, fy + 5, 12, 1, COBRE[0])
	_r(im, 9, fy + 1, 2, 4, ROCHA[1])
	_p(im, 8, fy + 2, ROCHA[1])
	_p(im, 11, fy + 2, ROCHA[1])
	_p(im, 9, fy + 2, BRASA[2])
	# Rachadura
	var cx := 8
	for y in range(fy + 8, h - 8):
		_p(im, cx, y, ROCHA[0])
		cx += (1 if _h(y, 1, 83) < 0.3 else (-1 if _h(y, 1, 83) > 0.75 else 0))
		cx = clampi(cx, 5, 14)
	_contorno(im, ROCHA[0])
	_salvar(im, nome)


func _colunas() -> void:
	_coluna(false, "coluna_canion.png")
	_coluna(true, "coluna_quebrada_canion.png")


# Bandeira do Conselho: 4 quadros (ondulando) ---------------------------------------------------
func _bandeira() -> void:
	var im := _novo(64, 32)
	for q in range(4):
		var ox := q * 16
		# Mastro de carvão com brilho
		_r(im, ox + 2, 2, 2, 30, CARVAO[2])
		_r(im, ox + 2, 2, 1, 30, CARVAO[4])
		_r(im, ox + 1, 1, 4, 2, CARVAO[3])
		var fase := float(q) / 4.0 * TAU
		for y in range(4, 24):
			var onda := int(round(sin(fase + float(y) * 0.45) * 1.5))
			var largura := 11 - (y - 4) / 8
			# Rasgado embaixo: franjas irregulares
			if y > 17 and _h(y, q, 90) < 0.35:
				largura -= 3
			for x in range(largura):
				var xx := ox + 4 + x + (onda if x > 1 else 0)
				var i := 2 + (1 if x < 3 else 0) - (1 if x > largura - 3 else 0)
				if int((x + y) / 3) % 4 == 0:
					i -= 1
				_p(im, xx, y, _tom(COBRE, i))
		# Losango do Conselho
		var cx := ox + 9 + int(round(sin(fase + 4.0) * 1.0))
		for dy in range(-3, 4):
			var meia := 3 - absi(dy)
			for dx in range(-meia, meia + 1):
				_p(im, cx + dx, 12 + dy, ROCHA[1])
		_p(im, cx, 12, BRASA[2])
	_contorno(im, ROCHA[0])
	_salvar(im, "bandeira_conselho.png")


# Ponte ------------------------------------------------------------------------------------------------
func _ponte() -> void:
	_toco()
	_placa(false, "ponte_placa_fantasma.png")
	_placa(true, "ponte_placa_acesa.png")
	# Trilhos (tileáveis em x): apagado e aceso
	for aceso in [false, true]:
		var im := _novo(16, 4)
		for x in range(16):
			var a := COBRE[1] if not aceso else COBRE[3]
			var b := COBRE[0] if not aceso else COBRE[2]
			if not aceso:
				a = CARVAO[2]
				b = CARVAO[1]
			im.set_pixel(x, 0, a)
			im.set_pixel(x, 1, a)
			im.set_pixel(x, 2, b)
			im.set_pixel(x, 3, ROCHA[0])
			if x % 8 == 3:
				im.set_pixel(x, 1, BRASA[3] if aceso else CARVAO[4])
		_salvar(im, "ponte_trilho_aceso.png" if aceso else "ponte_trilho_apagado.png")


func _toco() -> void:
	var w := 40
	var h := 64
	var im := _novo(w, h)
	for y in range(h):
		for x in range(w):
			var i := 1
			var n := _h(x, y, 100)
			var ajuste := 0.0
			if n < 0.12:
				ajuste = -0.025
			elif n > 0.93:
				ajuste = 0.025
			# Placas de 13px com junta escura
			var junta := 0.0
			if x % 13 == 0:
				junta = -0.04
			var cor := _tom(CARVAO, i + (1 if y < 6 else 0))
			cor = Color(cor.r + ajuste + junta + 0.03, cor.g + ajuste + junta, cor.b + ajuste + junta - 0.01)
			im.set_pixel(x, y, cor)
	# Trilhos de cobre sem brilho em cima e embaixo
	for x in range(w):
		for y in range(0, 4):
			im.set_pixel(x, y, _tom(COBRE, 1 if y < 2 else 0))
		for y in range(h - 4, h):
			im.set_pixel(x, y, _tom(COBRE, 0 if y > h - 3 else 1))
	# Parafusos
	for px in [5, 18, 31]:
		for py in [9, h - 11]:
			_p(im, px, py, CARVAO[4])
			_p(im, px + 1, py + 1, CARVAO[0])
	# Corte liso na ponta (direita) e o soquete do cristal apagado
	for y in range(h):
		im.set_pixel(w - 1, y, ROCHA[0])
		im.set_pixel(w - 2, y, ROCHA[1])
	var cy := h / 2
	for dy in range(-6, 7):
		var meia := 3 - absi(dy) / 2
		for dx in range(-meia, meia + 1):
			var cor := CARVAO[1] if dx < 0 else CARVAO[0]
			_p(im, w - 9 + dx, cy + dy, cor)
	for dy in range(-6, 7):
		_p(im, w - 9, cy + dy, CARVAO[3] if dy < 0 else CARVAO[2])
	_salvar(im, "ponte_toco.png")


func _placa(acesa: bool, nome: String) -> void:
	var w := 26
	var h := 56
	var im := _novo(w, h)
	var poligono := PackedVector2Array([Vector2(5, 2), Vector2(21, 2), Vector2(25, 28), Vector2(21, 54), Vector2(5, 54), Vector2(1, 28)])
	var miolo := PackedVector2Array()
	for p in poligono:
		miolo.append(Vector2(13, 28).lerp(p, 0.62))
	for y in range(h):
		for x in range(w):
			var ponto := Vector2(x + 0.5, y + 0.5)
			if not Geometry2D.is_point_in_polygon(ponto, poligono):
				continue
			var d := (ponto - Vector2(13, 28)).length() / 30.0
			var dentro := Geometry2D.is_point_in_polygon(ponto, miolo)
			var cor: Color
			if acesa:
				var i := 1 + int((1.0 - d) * 3.2)
				if dentro:
					i += 1
				cor = _tom(BRASA, i)
				if _h(x, y, 110) < 0.08:
					cor = _tom(BRASA, i + 1)
			else:
				cor = Color(BRASA[3], 0.16 + (0.1 if dentro else 0.0))
			im.set_pixel(x, y, cor)
	# Contorno do hexágono e linhas de circuito
	for k in range(poligono.size()):
		_linha(im, poligono[k], poligono[(k + 1) % poligono.size()], BRASA[4] if acesa else Color(BRASA[3], 0.75))
	var circuito := Color(BRASA[0], 0.9) if acesa else Color(BRASA[3], 0.35)
	for yy in [16, 40]:
		for xx in range(7, 19):
			_p(im, xx, yy, circuito)
	for yy in range(16, 41):
		_p(im, 13, yy, circuito)
	_salvar(im, nome)


func _linha(im: Image, a: Vector2, b: Vector2, c: Color) -> void:
	var passos := int(maxf(absf(b.x - a.x), absf(b.y - a.y))) + 1
	for i in range(passos + 1):
		var p := a.lerp(b, float(i) / float(passos))
		_p(im, int(round(p.x)), int(round(p.y)), c)


# Marcadores de luz (brilho suave, para somar sobre o cenário) ------------------------------------
func _marcadores() -> void:
	var im := _novo(48, 48)
	for y in range(48):
		for x in range(48):
			var d := Vector2(x - 23.5, y - 23.5).length() / 24.0
			if d < 1.0:
				var a := pow(1.0 - d, 2.0) * 0.55
				im.set_pixel(x, y, Color(1.0, 0.45, 0.25, a))
	_salvar(im, "brilho_brasa.png")


# Ícone da peça ponte.tile (também usado no inventário) --------------------------------------------
func _peca() -> void:
	var im := _novo(16, 16)
	var poligono := PackedVector2Array([Vector2(4, 2), Vector2(12, 2), Vector2(15, 8), Vector2(12, 14), Vector2(4, 14), Vector2(1, 8)])
	for y in range(16):
		for x in range(16):
			var ponto := Vector2(x + 0.5, y + 0.5)
			if Geometry2D.is_point_in_polygon(ponto, poligono):
				var d := (ponto - Vector2(8, 8)).length() / 8.0
				im.set_pixel(x, y, _tom(BRASA, 1 + int((1.0 - d) * 3.4)))
	for k in range(poligono.size()):
		_linha(im, poligono[k], poligono[(k + 1) % poligono.size()], BRASA[4])
	for xx in range(5, 11):
		_p(im, xx, 8, BRASA[0])
	_contorno(im, ROCHA[0])
	_salvar(im, "peca_ponte.png")


# Recolorir arte existente (obelisco, plataforma, portal) -----------------------------------------
func _recolorir(origem: String, destino: String) -> void:
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
			var h := c.h
			var s := c.s
			if s < 0.08:
				im.set_pixel(x, y, Color(c.v * 1.0, c.v * 0.86, c.v * 0.82, c.a))
				continue
			var t := clampf((h - 0.45) / 0.5, 0.0, 1.0)
			var novo_h := 0.012 + t * 0.07
			var novo := Color.from_hsv(novo_h, clampf(s * 0.9 + 0.08, 0.0, 1.0), clampf(c.v * 1.02, 0.0, 1.0), c.a)
			im.set_pixel(x, y, novo)
	_salvar(im, destino)
