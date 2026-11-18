class_name RunaConflito extends Node2D
## As runas da Fase 5, desenhadas por código (visual provisório, para validar a mecânica).
##
##   minha       selo.runa na MAIN (a sua versão: dourado)
##   deles       selo.runa na branch `ajuste` (a versão da outra equipe: azul)
##   porta       porta.runa: só a outra equipe mexeu, o Git junta sozinho (acende no merge)
##   resultado   o selo.runa da main: "?" até o merge; dividido em dois (e vibrando) no
##               conflito; a cor escolhida depois; contorno verde quando o merge fecha

enum Papel { MINHA, DELES, PORTA, RESULTADO }

const TAM := 28.0
const COR_DOURADO := Color("E8B84A")
const COR_AZUL := Color("3D7BFF")
const COR_VERDE := Color("3DDB7B")
const COR_PRATA := Color("B8C0CC")
const COR_GLITCH := Color("FF2BD6")

@export var papel: Papel = Papel.RESULTADO
@export var rotulo: String = ""

var _modelo: ModeloConflito
var _tempo: float = 0.0


func _ready() -> void:
	_modelo = ModeloConflito.ativo()
	if _modelo == null:
		return
	_modelo.mudou.connect(queue_redraw)
	queue_redraw()


func _process(delta: float) -> void:
	# Só o resultado em conflito precisa animar (vibra para chamar atenção)
	if _modelo and papel == Papel.RESULTADO and _modelo.estado() == ModeloConflito.CONFLITO:
		_tempo += delta
		queue_redraw()


func _draw() -> void:
	if _modelo == null:
		return
	var caixa := Rect2(-TAM / 2.0, -TAM / 2.0, TAM, TAM)
	match papel:
		Papel.MINHA:
			_quadrado(caixa, COR_DOURADO)
		Papel.DELES:
			_quadrado(caixa, COR_AZUL)
		Papel.PORTA:
			var viva := _modelo.porta_mesclada()
			_quadrado(caixa, COR_VERDE if viva else COR_PRATA, 1.0 if viva else 0.4)
			if viva:
				draw_rect(caixa.grow(2.0), COR_VERDE, false, 2.0)
		Papel.RESULTADO:
			_desenhar_resultado(caixa)
	_rotular()


func _quadrado(caixa: Rect2, cor: Color, alfa: float = 1.0) -> void:
	draw_rect(caixa, Color(COR_PRATA.r, COR_PRATA.g, COR_PRATA.b, alfa))
	var cor_final := Color(cor.r, cor.g, cor.b, alfa)
	draw_rect(caixa.grow(-5.0), cor_final)


func _dividido(caixa: Rect2) -> void:
	var miolo := caixa.grow(-5.0)
	var a := miolo.position
	var b := miolo.position + Vector2(miolo.size.x, 0.0)
	var c := miolo.position + miolo.size
	var d := miolo.position + Vector2(0.0, miolo.size.y)
	draw_colored_polygon(PackedVector2Array([a, b, d]), COR_DOURADO)
	draw_colored_polygon(PackedVector2Array([b, c, d]), COR_AZUL)


func _desenhar_resultado(caixa: Rect2) -> void:
	draw_rect(caixa, COR_PRATA)
	var miolo := caixa.grow(-5.0)
	match _modelo.estado():
		ModeloConflito.PRE:
			draw_rect(miolo, Color(0.2, 0.2, 0.26))
		ModeloConflito.CONFLITO:
			var tremor := Vector2(sin(_tempo * 40.0), cos(_tempo * 33.0)) * 1.2
			draw_set_transform(tremor)
			_dividido(caixa)
			draw_rect(caixa.grow(2.0), COR_GLITCH, false, 2.0)
			draw_set_transform(Vector2.ZERO)
		_:
			match _modelo.escolha():
				ModeloConflito.LADO_MINHA:
					draw_rect(miolo, COR_DOURADO)
				ModeloConflito.LADO_DELES:
					draw_rect(miolo, COR_AZUL)
				_:
					_dividido(caixa)
			if _modelo.estado() == ModeloConflito.PREPARADO:
				draw_rect(caixa.grow(2.0), Color("3DA9FF"), false, 2.0)
			elif _modelo.estado() == ModeloConflito.CONCLUIDO:
				draw_rect(caixa.grow(2.0), COR_VERDE, false, 2.0)
			else:
				draw_rect(caixa.grow(2.0), Color("FF9A3D"), false, 2.0)


func _rotular() -> void:
	if rotulo.is_empty():
		return
	var fonte := ThemeDB.fallback_font
	var largura := fonte.get_string_size(rotulo, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
	draw_string(fonte, Vector2(-largura / 2.0, TAM / 2.0 + 10.0), rotulo,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.85, 0.9, 0.95))
