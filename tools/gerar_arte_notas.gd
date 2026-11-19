extends SceneTree
## Gerador dos ícones das NOTAS da história (carta, placa, ata, diário, registro). Não faz parte do jogo.
## Rode para regerar: godot --headless --path . --script res://tools/gerar_arte_notas.gd
## Saída: res://GeneralNodes/Nota/arte/nota_<tipo>.png (16x16, com contorno escuro para destacar em qualquer fase).

const SAIDA := "res://GeneralNodes/Nota/arte/"
const TAM := 16
const CONTORNO := Color("1A1210")
const PAPEL := Color("F4E7C4")
const PAPEL_SOMBRA := Color("D2BC8A")
const TINTA := Color("5A4630")


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAIDA))
	_carta()
	_placa()
	_ata()
	_diario()
	_registro()
	_brilho()
	print("[Arte Notas] pronto.")
	quit()


func _novo() -> Image:
	var im := Image.create(TAM, TAM, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	return im


func _p(im: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < TAM and y < TAM:
		im.set_pixel(x, y, c)


func _r(im: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for j in range(h):
		for i in range(w):
			_p(im, x + i, y + j, c)


func _l(im: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	var n := maxi(absi(x1 - x0), absi(y1 - y0))
	for i in range(n + 1):
		var t := float(i) / float(maxi(n, 1))
		_p(im, int(round(lerpf(x0, x1, t))), int(round(lerpf(y0, y1, t))), c)


func _contorno(im: Image) -> void:
	var marcar: Array[Vector2i] = []
	for y in range(TAM):
		for x in range(TAM):
			if im.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < TAM and q.y < TAM and im.get_pixel(q.x, q.y).a >= 1.0:
					marcar.append(Vector2i(x, y))
					break
	for m in marcar:
		im.set_pixel(m.x, m.y, CONTORNO)


func _salvar(im: Image, tipo: String) -> void:
	_contorno(im)
	im.save_png(ProjectSettings.globalize_path(SAIDA + "nota_%s.png" % tipo))


func _carta() -> void:
	var im := _novo()
	_r(im, 2, 4, 12, 9, PAPEL)
	_r(im, 2, 12, 12, 1, PAPEL_SOMBRA)
	_l(im, 2, 4, 7, 8, TINTA)
	_l(im, 13, 4, 8, 8, TINTA)
	# Lacre dourado
	_r(im, 7, 8, 3, 3, Color("FFD23F"))
	_p(im, 7, 8, Color("FFF2A8"))
	_p(im, 9, 10, Color("B8860B"))
	_salvar(im, "carta")


func _placa() -> void:
	var im := _novo()
	_r(im, 2, 4, 12, 9, Color("9AA7B8"))
	_r(im, 2, 4, 12, 1, Color("C9D3E0"))
	_r(im, 2, 12, 12, 1, Color("6E7A8A"))
	for p in [Vector2i(3, 5), Vector2i(12, 5), Vector2i(3, 11), Vector2i(12, 11)]:
		_p(im, p.x, p.y, Color("3C4552"))
	_r(im, 5, 7, 6, 1, Color("3C4552"))
	_r(im, 5, 9, 4, 1, Color("3C4552"))
	_salvar(im, "placa")


func _ata() -> void:
	var im := _novo()
	_r(im, 4, 2, 8, 12, PAPEL)
	_r(im, 4, 13, 8, 1, PAPEL_SOMBRA)
	_r(im, 5, 4, 6, 1, TINTA)
	_r(im, 5, 6, 5, 1, TINTA)
	# Selo do Conselho (rosa)
	_r(im, 6, 9, 4, 3, Color("D94C91"))
	_p(im, 6, 9, Color("F58AC0"))
	_p(im, 8, 10, Color("7A1F4D"))
	_salvar(im, "ata")


func _diario() -> void:
	var im := _novo()
	_r(im, 3, 2, 10, 12, Color("53D69A"))
	_r(im, 3, 2, 10, 1, Color("8BEBC0"))
	_r(im, 3, 13, 10, 1, Color("2E8A63"))
	_r(im, 3, 2, 2, 12, Color("2E8A63"))
	_r(im, 6, 5, 5, 4, PAPEL)
	_r(im, 7, 6, 3, 1, TINTA)
	_r(im, 12, 11, 1, 4, Color("D94C91"))
	_salvar(im, "diario")


func _registro() -> void:
	# Cristal de registro (losango ciano com um glifo), nada de "computador"
	var im := _novo()
	var poligono := PackedVector2Array([Vector2(8, 1), Vector2(13, 7), Vector2(8, 14), Vector2(3, 7)])
	for y in range(TAM):
		for x in range(TAM):
			var ponto := Vector2(x + 0.5, y + 0.5)
			if Geometry2D.is_point_in_polygon(ponto, poligono):
				var t := float(y - 1) / 13.0
				var cor := Color("8CF0FA").lerp(Color("1F8FA0"), t)
				if x < 8:
					cor = cor.lightened(0.12)
				_p(im, x, y, cor)
	_r(im, 7, 5, 2, 1, Color("0E2A33"))
	_r(im, 7, 7, 2, 4, Color("0E2A33"))
	_salvar(im, "registro")


## Brilho suave branco (é tingido na hora de desenhar): realça a nota não lida em qualquer fase.
func _brilho() -> void:
	var im := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	for y in range(48):
		for x in range(48):
			var d := Vector2(x - 23.5, y - 23.5).length() / 24.0
			im.set_pixel(x, y, Color(1, 1, 1, pow(maxf(1.0 - d, 0.0), 1.8) * 0.9))
	im.save_png(ProjectSettings.globalize_path(SAIDA + "nota_brilho.png"))
