extends SceneTree
## Gerador da arte da Fase 3 (O Mural Corrompido), paleta "Pedra clara e ouro" de docs/DESIGN_FASES.md.
## Não faz parte do jogo: desenha, pixel a pixel, os PNGs em res://fases/fase_3/arte/. Para regerar:
##   godot --headless --path . --script res://tools/gerar_arte_fase_3.gd
## Luz de cima/esquerda. O MAGENTA fica reservado ao ruído da Corrupção; laranja = Oficina, azul = Palco, verde = Arquivo.

const SAIDA := "res://fases/fase_3/arte/"

# Rampas ------------------------------------------------------------------------------------------
var PEDRA: Array[Color] = [Color("4A463E"), Color("6E695C"), Color("8E897C"), Color("AAA597"), Color("C9C3B4"), Color("DAD5C6"), Color("ECE7D8")]
var OURO: Array[Color] = [Color("7A5A1E"), Color("B8913A"), Color("E8B84A"), Color("F7DB8A"), Color("FFF0BE")]
const TINTA := Color("2B2822")
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAIDA))
	_piso()
	_parede()
	_painel("oficina", Color("FF9A3D"))
	_painel("palco", Color("3DA9FF"))
	_painel("arquivo", Color("3DFF9B"))
	_tablete()
	_glifos()
	_barreira()
	_altar()
	_colunas()
	_candelabro()
	_pedras()
	_selo()
	_brilho()
	_recolorir("res://terminal/Sprites/obelisco_inativo.png", "obelisco_inativo_ouro.png", 1.0)
	_recolorir("res://terminal/Sprites/obelisco_ativo.png", "obelisco_ativo_ouro.png", 1.0)
	_recolorir("res://terminal/Sprites/plataforma_terminal.png", "plataforma_terminal_ouro.png", 1.5)
	_recolorir("res://GeneralNodes/ExitArea/portal_saida.png", "portal_saida_ouro.png", 1.0)
	print("[Arte Fase 3] pronto.")
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


func _tom(rampa: Array[Color], i: int) -> Color:
	return rampa[clampi(i, 0, rampa.size() - 1)]


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


func _tingir(c: Color, k: float) -> Color:
	return Color(clampf(c.r + k, 0.0, 1.0), clampf(c.g + k * 0.95, 0.0, 1.0), clampf(c.b + k * 0.85, 0.0, 1.0), c.a)


# Chão e paredão -----------------------------------------------------------------------------------
func _piso() -> void:
	# Lajes de calcário 32x16 em fiadas desencontradas (tileável 64x64)
	var im := _novo(64, 64)
	for y in range(64):
		var fila := y / 16
		var deslocamento := 16 if fila % 2 == 1 else 0
		var ly := y % 16
		for x in range(64):
			var gx := (x + deslocamento) % 64
			var lx := gx % 32
			var laje := gx / 32 + fila * 2
			var brilho := (_h(laje, 1, 1) - 0.5) * 0.05
			var i := 4
			var n := _h(x, y, 2)
			var ajuste := 0.0
			if n < 0.16:
				ajuste = -0.03
			elif n > 0.9:
				ajuste = 0.025
			if lx == 0 or ly == 0:
				i += 1
			if lx == 31 or ly == 15:
				i -= 3
			elif lx == 30 or ly == 14:
				i -= 1
			im.set_pixel(x, y, _tingir(_tom(PEDRA, i), brilho + ajuste))
	# Incrustações de ouro e rachaduras finas
	for fila in range(4):
		for c in range(2):
			var laje := c + fila * 2
			var deslocamento := 16 if fila % 2 == 1 else 0
			var cx := (c * 32 + 16 + deslocamento) % 64
			var cy := fila * 16 + 8
			if _h(laje, 2, 3) < 0.28:
				_p(im, cx, cy, OURO[2])
				_p(im, cx + 1, cy, OURO[3])
				_p(im, cx, cy + 1, OURO[1])
				for d in [Vector2i(-1, 0), Vector2i(2, 0), Vector2i(0, -1), Vector2i(1, 2)]:
					_p(im, (cx + d.x) % 64, cy + d.y, Color(PEDRA[1], 0.8))
			elif _h(laje, 3, 3) < 0.3:
				var px := cx - 6
				var py := cy - 3
				for k in range(9):
					_p(im, (px + k) % 64, py, PEDRA[1])
					py += 1 if _h(k, laje, 4) < 0.35 else 0
					py = clampi(py, fila * 16 + 3, fila * 16 + 12)
	_salvar(im, "piso_mural.png")


func _glifo_friso(im: Image, x: int, y: int, variante: int) -> void:
	# Runazinha dourada 6x8 do friso
	var cor := OURO[2]
	match variante % 6:
		0:
			for k in range(8):
				_p(im, x + 2, y + k, cor)
			_p(im, x + 1, y + 1, cor)
			_p(im, x + 3, y + 1, cor)
		1:
			for k in range(5):
				_p(im, x + 1 + k, y + 1, cor)
				_p(im, x + 1 + k, y + 6, cor)
			_p(im, x + 1, y + 2, cor)
			_p(im, x + 5, y + 5, cor)
		2:
			for k in range(8):
				_p(im, x + 2 + (k % 2), y + k, cor)
			_p(im, x + 4, y + 3, cor)
		3:
			for k in range(6):
				_p(im, x + k, y + 3, cor)
			_p(im, x + 3, y, cor)
			_p(im, x + 3, y + 7, cor)
		4:
			_p(im, x + 1, y + 1, cor)
			_p(im, x + 4, y + 1, cor)
			for k in range(8):
				_p(im, x + 2, y + k, cor)
			_p(im, x + 3, y + 6, cor)
		_:
			for k in range(6):
				_p(im, x + k, y + k + 1, cor)
			_p(im, x + 5, y + 1, cor)


func _parede() -> void:
	# Paredão de cima: a borda que toca o chão fica embaixo; embaixo do jogo basta espelhar.
	var im := _novo(64, 64)
	for y in range(64):
		var fila := y / 16
		var deslocamento := 16 if fila % 2 == 1 else 0
		var ly := y % 16
		for x in range(64):
			var gx := (x + deslocamento) % 64
			var lx := gx % 32
			var bloco := gx / 32 + fila * 2
			var profundidade := 1.0 - float(y) / 63.0
			var i := 4 - int(profundidade * 3.2)
			var n := _h(x, y, 11)
			var ajuste := (_h(bloco, 5, 12) - 0.5) * 0.04
			if n < 0.14:
				ajuste -= 0.03
			if ly == 0:
				i += 1
			if lx == 31 or ly == 15:
				i -= 2
			im.set_pixel(x, y, _tingir(_tom(PEDRA, i), ajuste))
	# Friso: faixa escura com runas douradas, e a cornija de ouro junto ao chão
	_r(im, 0, 40, 64, 14, TINTA)
	_r(im, 0, 40, 64, 1, OURO[1])
	_r(im, 0, 53, 64, 1, OURO[1])
	for k in range(8):
		_glifo_friso(im, k * 8 + 1, 43, k + int(_h(k, 0, 13) * 6.0))
	_r(im, 0, 54, 64, 3, _tom(PEDRA, 5))
	_r(im, 0, 54, 64, 1, _tom(PEDRA, 6))
	_r(im, 0, 57, 64, 1, OURO[3])
	_r(im, 0, 58, 64, 1, OURO[1])
	_r(im, 0, 59, 64, 5, _tom(PEDRA, 3))
	_r(im, 0, 63, 64, 1, _tom(PEDRA, 1))
	_salvar(im, "parede_mural.png")


func _painel(nome: String, cor: Color) -> void:
	# Faixa do chão da zona 3: véu colorido, moldura de ouro e cantos (sobre o piso)
	var w := 120
	var h := 192
	var im := _novo(w, h)
	_r(im, 0, 0, w, h, Color(cor, 0.14))
	for k in range(2):
		for x in range(w):
			_p(im, x, k, Color(cor, 0.7 - k * 0.3))
			_p(im, x, h - 1 - k, Color(cor, 0.7 - k * 0.3))
		for y in range(h):
			_p(im, k, y, Color(cor, 0.7 - k * 0.3))
			_p(im, w - 1 - k, y, Color(cor, 0.7 - k * 0.3))
	for x in range(3, w - 3):
		_p(im, x, 3, Color(OURO[1], 0.8))
		_p(im, x, h - 4, Color(OURO[1], 0.8))
	for y in range(3, h - 3):
		_p(im, 3, y, Color(OURO[1], 0.8))
		_p(im, w - 4, y, Color(OURO[1], 0.8))
	# Cantos de ouro
	for cx in [3, w - 12]:
		for cy in [3, h - 12]:
			_r(im, cx, cy, 9, 2, OURO[2])
			_r(im, cx, cy, 2, 9, OURO[2])
	for cx in [w - 12 + 7, 3]:
		pass
	_salvar(im, "painel_%s.png" % nome)


# Runas -------------------------------------------------------------------------------------------------------
func _tablete() -> void:
	# Tablete de pedra 32x32 com moldura de ouro; o miolo colorido é desenhado pelo jogo
	var im := _novo(32, 32)
	for y in range(32):
		for x in range(32):
			# cantos cortados
			var canto := (x < 2 and y < 2 - x) or (x > 29 and y < x - 29) or (x < 2 and y > 29 + x - 1) or (x > 29 and y > 29 + (31 - x))
			if canto:
				continue
			var i := 4
			if x < 2 or y < 2:
				i = 6
			elif x > 29 or y > 29:
				i = 2
			var n := _h(x, y, 21)
			var cor := _tom(PEDRA, i)
			if n < 0.15:
				cor = _tingir(cor, -0.04)
			im.set_pixel(x, y, cor)
	# Filete de ouro por dentro da borda
	for k in range(2, 30):
		_p(im, k, 2, OURO[2])
		_p(im, k, 29, OURO[1])
		_p(im, 2, k, OURO[2])
		_p(im, 29, k, OURO[1])
	_contorno(im, TINTA)
	_salvar_ext(im, 34, "tablete_runa.png")


func _salvar_ext(im: Image, tam: int, nome: String) -> void:
	# Centraliza num canvas maior (espaço para o contorno)
	var saida := _novo(tam, tam)
	saida.blit_rect(im, Rect2i(0, 0, im.get_width(), im.get_height()), Vector2i((tam - im.get_width()) / 2, (tam - im.get_height()) / 2))
	_salvar(saida, nome)


func _glifos() -> void:
	# Nove glifos 12x12 (sol, lua, estrela, terra, mar, fogo, vento, aurora, eclipse), em tinta
	var im := _novo(108, 12)
	var t := Color(TINTA, 0.7)
	for k in range(9):
		var ox := k * 12
		match k:
			0:  # sol
				for dy in range(-2, 3):
					for dx in range(-2, 3):
						if dx * dx + dy * dy <= 5:
							_p(im, ox + 6 + dx, 6 + dy, t)
				for p in [Vector2i(6, 1), Vector2i(6, 10), Vector2i(1, 6), Vector2i(10, 6), Vector2i(2, 2), Vector2i(9, 2), Vector2i(2, 9), Vector2i(9, 9)]:
					_p(im, ox + p.x, p.y, t)
			1:  # lua
				for dy in range(-4, 5):
					for dx in range(-4, 5):
						var d := dx * dx + dy * dy
						var d2 := (dx - 2) * (dx - 2) + dy * dy
						if d <= 17 and d2 > 14:
							_p(im, ox + 6 + dx, 6 + dy, t)
			2:  # estrela
				for k2 in range(1, 11):
					_p(im, ox + 6, k2, t)
					_p(im, ox + k2, 6, t)
				for k2 in range(3, 9):
					_p(im, ox + k2, k2, Color(t, 0.5))
					_p(im, ox + k2, 12 - k2, Color(t, 0.5))
			3:  # terra
				for x in range(2, 10):
					_p(im, ox + x, 9, t)
				for x in range(3, 9):
					_p(im, ox + x, 8, t)
				for x in range(4, 8):
					_p(im, ox + x, 6, t)
				_p(im, ox + 5, 4, t)
				_p(im, ox + 6, 4, t)
				_p(im, ox + 6, 3, t)
			4:  # mar
				for y in [3, 6, 9]:
					for x in range(1, 11):
						_p(im, ox + x, y + int(round(sin(float(x) * 1.2) * 1.0)), t)
			5:  # fogo
				for y in range(2, 11):
					var meia := int(round(3.0 * sin(float(y - 2) / 9.0 * PI) + 0.2))
					for x in range(-meia, meia + 1):
						_p(im, ox + 6 + x + int(sin(float(y)) * 0.0), y, t)
				_p(im, ox + 6, 1, t)
			6:  # vento
				for x in range(1, 10):
					_p(im, ox + x, 4, t)
				for x in range(3, 11):
					_p(im, ox + x, 8, t)
				_p(im, ox + 10, 5, t)
				_p(im, ox + 11, 6, t)
				_p(im, ox + 1, 9, t)
				_p(im, ox + 10, 3, t)
			7:  # aurora
				for dy in range(0, 6):
					for dx in range(-5, 6):
						var d := dx * dx + dy * dy
						if d <= 25 and d >= 14:
							_p(im, ox + 6 + dx, 8 - dy, t)
				for x in range(1, 11):
					_p(im, ox + x, 9, t)
			_:  # eclipse
				for dy in range(-4, 5):
					for dx in range(-4, 5):
						var d := dx * dx + dy * dy
						if d <= 17 and d >= 12:
							_p(im, ox + 6 + dx, 6 + dy, t)
						elif d <= 6:
							_p(im, ox + 6 + dx, 6 + dy, t)
	_salvar(im, "runas_glifos.png")


# Barreira de ruído (as portas) e altar ----------------------------------------------------------------------
func _barreira() -> void:
	var w := 16
	var h := 256
	var im := _novo(w, h)
	var cores: Array[Color] = [Color("FF2BD6"), Color("12001A"), Color("12001A"), Color("B01E96"), Color("050008")]
	for by in range(h / 4):
		var desloc := 0
		if _h(by, 0, 31) < 0.2:
			desloc = int(_h(by, 1, 31) * 4.0) * 4
		for bx in range(4):
			var r := _h(bx + desloc, by, 32)
			var cor := cores[int(r * 5.0) % 5]
			if _h(bx, by, 33) < 0.06:
				cor = Color("FFB3F0")
			_r(im, bx * 4, by * 4, 4, 4, cor)
	# Linhas de varredura
	for y in range(0, h, 3):
		_r(im, 0, y, w, 1, Color(0, 0, 0, 0.28))
	# Bordas vivas
	for y in range(h):
		_p(im, 0, y, Color("FF2BD6", 0.9))
		_p(im, w - 1, y, Color("FF2BD6", 0.9))
	# Pilares de pedra e ouro nas pontas
	for tampa in [0, h - 14]:
		_r(im, 0, tampa, w, 14, _tom(PEDRA, 4))
		_r(im, 0, tampa, w, 1, _tom(PEDRA, 6))
		_r(im, 0, tampa + 13, w, 1, _tom(PEDRA, 1))
		_r(im, 0, tampa + 5, w, 2, OURO[2])
		_r(im, 0, tampa + 5, w, 1, OURO[3])
	_salvar(im, "barreira_ruido.png")


func _altar() -> void:
	var im := _novo(24, 32)
	# Base e coluna
	_r(im, 2, 26, 20, 5, _tom(PEDRA, 3))
	_r(im, 2, 26, 20, 1, _tom(PEDRA, 6))
	_r(im, 2, 30, 20, 1, _tom(PEDRA, 1))
	_r(im, 7, 12, 10, 14, _tom(PEDRA, 4))
	_r(im, 7, 12, 3, 14, _tom(PEDRA, 5))
	_r(im, 14, 12, 3, 14, _tom(PEDRA, 2))
	# Bacia dourada no topo, com a "pena" (glifo de reescrever)
	_r(im, 3, 8, 18, 4, OURO[1])
	_r(im, 3, 8, 18, 1, OURO[3])
	_r(im, 5, 6, 14, 2, OURO[2])
	_r(im, 6, 5, 12, 1, OURO[3])
	for k in range(7):
		_p(im, 9 + k, 4 - k / 3, OURO[4])
	_p(im, 8, 4, OURO[3])
	_p(im, 8, 3, OURO[2])
	_contorno(im, TINTA)
	_salvar(im, "altar_reescrita.png")


# Decoração ------------------------------------------------------------------------------------------------------
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
			im.set_pixel(x, y, _tom(PEDRA, i))
	if quebrada:
		for x in range(4, 16):
			var corte := 2 + int(_h(x, 0, 82) * 7.0)
			for y in range(0, corte):
				im.set_pixel(x, y, Color(0, 0, 0, 0))
			_p(im, x, corte, _tom(PEDRA, 6))
	else:
		_r(im, 2, 2, 16, 5, _tom(PEDRA, 5))
		_r(im, 2, 2, 16, 1, _tom(PEDRA, 6))
		_r(im, 2, 6, 16, 1, OURO[2])
		_r(im, 2, 7, 16, 1, OURO[0])
	_r(im, 2, h - 6, 16, 6, _tom(PEDRA, 4))
	_r(im, 2, h - 6, 16, 1, _tom(PEDRA, 6))
	_r(im, 2, h - 6, 16, 1, OURO[2])
	_r(im, 2, h - 1, 16, 1, _tom(PEDRA, 1))
	# Faixa de ouro com uma runa
	var fy := (h * 5) / 9
	_r(im, 4, fy, 12, 6, OURO[1])
	_r(im, 4, fy, 12, 1, OURO[3])
	_r(im, 4, fy + 5, 12, 1, OURO[0])
	_r(im, 9, fy + 1, 2, 4, TINTA)
	_p(im, 8, fy + 2, TINTA)
	_p(im, 11, fy + 2, TINTA)
	var cx := 8
	for y in range(fy + 8, h - 8):
		_p(im, cx, y, _tom(PEDRA, 1))
		cx += (1 if _h(y, 1, 83) < 0.3 else (-1 if _h(y, 1, 83) > 0.75 else 0))
		cx = clampi(cx, 5, 14)
	_contorno(im, TINTA)
	_salvar(im, nome)


func _colunas() -> void:
	_coluna(false, "coluna_mural.png")
	_coluna(true, "coluna_quebrada_mural.png")


func _candelabro() -> void:
	# Quatro quadros da chama (12x24 cada)
	var im := _novo(48, 24)
	for q in range(4):
		var ox := q * 12
		# Haste e taça de ouro
		_r(im, ox + 5, 12, 2, 9, OURO[1])
		_r(im, ox + 3, 20, 6, 3, OURO[1])
		_r(im, ox + 3, 20, 6, 1, OURO[3])
		_r(im, ox + 2, 10, 8, 2, OURO[2])
		_r(im, ox + 2, 10, 8, 1, OURO[3])
		# Chama que dança
		var altura := 6 + (q % 2) + (1 if q == 2 else 0)
		var inclina: int = [0, 1, 0, -1][q]
		for y in range(altura):
			var meia := 2 if y > altura - 3 else (1 if y > 1 else 0)
			for x in range(-meia, meia + 1):
				var cor := Color("FF9A3D") if y < altura - 2 else Color("FFE08A")
				if abs(x) == 0 and y > 1 and y < altura - 1:
					cor = Color("FFF6D0")
				_p(im, ox + 6 + x + (inclina if y < 3 else 0), 9 - y, cor)
	_contorno(im, TINTA)
	_salvar(im, "candelabro_ouro.png")


func _pedra(im: Image, cx: int, cy: int, rw: int, rh: int, semente: int) -> void:
	for y in range(cy - rh, cy + rh + 1):
		for x in range(cx - rw, cx + rw + 1):
			var dx := float(x - cx) / float(rw)
			var dy := float(y - cy) / float(rh)
			if dx * dx + dy * dy > 1.0 + (_h(x, y, semente) - 0.5) * 0.3:
				continue
			var luz := -dx * 0.6 - dy * 0.9
			var i := 4 + int(round(luz * 1.3))
			if _h(x, y, semente + 1) < 0.12:
				i -= 1
			im.set_pixel(x, y, _tom(PEDRA, i))


func _pedras() -> void:
	for k in range(3):
		var im := _novo(24, 16)
		_pedra(im, 8, 10, 6, 4, 40 + k)
		_pedra(im, 16, 9, 4 + k % 2, 3 + k % 2, 50 + k)
		if k > 0:
			_pedra(im, 12, 6, 3, 3, 60 + k)
		_contorno(im, TINTA)
		_salvar(im, "pedras_claras_%d.png" % (k + 1))


func _selo() -> void:
	# Selo dourado gravado no chão (sob cada Obelisco)
	var im := _novo(48, 48)
	for y in range(48):
		for x in range(48):
			var d := Vector2(x - 23.5, y - 23.5).length()
			var a := 0.0
			if d > 21.0 and d < 22.6:
				a = 0.55
			elif d > 17.5 and d < 18.5:
				a = 0.35
			elif d > 12.0 and d < 12.8:
				a = 0.3
			if a > 0.0:
				im.set_pixel(x, y, Color(OURO[2], a))
	for k in range(16):
		var ang := float(k) / 16.0 * TAU
		for r in range(18, 22):
			var p := Vector2(23.5, 23.5) + Vector2(cos(ang), sin(ang)) * float(r)
			_p(im, int(p.x), int(p.y), Color(OURO[2], 0.35))
	_salvar(im, "selo_dourado.png")


func _brilho() -> void:
	var im := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	for y in range(48):
		for x in range(48):
			var d := Vector2(x - 23.5, y - 23.5).length() / 24.0
			im.set_pixel(x, y, Color(1.0, 0.82, 0.4, pow(maxf(1.0 - d, 0.0), 2.0) * 0.6))
	im.save_png(ProjectSettings.globalize_path(SAIDA + "brilho_ouro.png"))


# Recolorir arte existente para pedra clara e ouro -----------------------------------------------------------------
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
			if c.s < 0.1:
				im.set_pixel(x, y, Color(v, v * 0.96, v * 0.86, c.a))
				continue
			var t := clampf((c.h - 0.45) / 0.5, 0.0, 1.0)
			var novo := Color.from_hsv(0.105 + t * 0.03, clampf(c.s * 0.5 + 0.1, 0.0, 0.75), v, c.a)
			im.set_pixel(x, y, novo)
	_salvar(im, destino)
