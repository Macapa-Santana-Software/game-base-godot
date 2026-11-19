class_name RunaMural extends Node2D
## Uma runa do mural, desenhada por código (visual provisório, só para validar a mecânica).
##
##   miolo      cor ATUAL (o que está na Oficina); "ruído" = corrupção (xadrez magenta)
##   moldura    cor BASE (a versão do último commit)
##   contorno   laranja = mudança na Oficina · azul = mudança no Palco (staging)
##   brilho     pisca em amarelo quando um `git diff` mostra a diferença dessa runa
##
## Na zona 3 (`slots` com 3 posições: Oficina, Palco, Arquivo) a runa ANDA entre as três áreas
## do chão conforme o estado dela, para o jogador ver o caminho add / restore --staged.

const TAM := 26.0
const PALETA := {
	"dourado": Color("E8B84A"),
	"prata": Color("B8C0CC"),
	"azul": Color("3D7BFF"),
	"verde": Color("3DDB7B"),
	"roxo": Color("9A5BD8"),
	"vermelho": Color("E0505A"),
}
const COR_RUIDO_A := Color("FF2BD6")
const COR_RUIDO_B := Color("12001A")
const COR_OFICINA := Color("FF9A3D")
const COR_PALCO := Color("3DA9FF")
const COR_TINTA := Color("2B2822")
const TABLETE: Texture2D = preload("res://fases/fase_3/arte/tablete_runa.png")
const GLIFOS: Texture2D = preload("res://fases/fase_3/arte/runas_glifos.png")
## Glifo (quadro do sprite sheet) de cada runa.
const GLIFO_DE := {"sol": 0, "lua": 1, "estrela": 2, "terra": 3, "mar": 4, "fogo": 5, "vento": 6, "aurora": 7, "eclipse": 8}

@export var nome_arquivo: String = ""
## Posições [Oficina, Palco, Arquivo]. Vazio = a runa fica parada onde foi colocada.
@export var slots: PackedVector2Array = PackedVector2Array()

var _modelo: ModeloMural
var _brilho: float = 0.0
var _tween_pos: Tween
var _tween_brilho: Tween


func _ready() -> void:
	_modelo = ModeloMural.ativo()
	if _modelo == null:
		return
	_modelo.mudou.connect(_atualizar)
	_modelo.diff_executado.connect(_on_diff)
	_atualizar(true)


func _slot_atual() -> int:
	if _modelo.preparada(nome_arquivo):
		return 1
	if _modelo.modificada(nome_arquivo):
		return 0
	return 2


func _atualizar(instantaneo: bool = false) -> void:
	if slots.size() == 3:
		var destino := slots[_slot_atual()]
		if instantaneo is bool and instantaneo:
			position = destino
		elif position != destino:
			if _tween_pos:
				_tween_pos.kill()
			_tween_pos = create_tween()
			_tween_pos.tween_property(self, "position", destino, 0.35)
	queue_redraw()


func _on_diff(nomes: Array) -> void:
	if nome_arquivo not in nomes:
		return
	if _tween_brilho:
		_tween_brilho.kill()
	_tween_brilho = create_tween()
	_tween_brilho.tween_method(_definir_brilho, 1.0, 0.0, 1.6)


func _definir_brilho(valor: float) -> void:
	_brilho = valor
	queue_redraw()


func _cor(valor: String) -> Color:
	return PALETA.get(valor, Color.WHITE)


func _draw() -> void:
	if _modelo == null:
		return
	var d := _modelo.dados(nome_arquivo)
	if d.is_empty():
		return
	var caixa := Rect2(-TAM / 2.0, -TAM / 2.0, TAM, TAM)
	var miolo := caixa.grow(-5.0)

	# Sombra no chão e o tablete de pedra; por dentro, a moldura (cor BASE) e o miolo (cor ATUAL)
	draw_set_transform(Vector2(0, TAM / 2.0 + 3.0), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, TAM / 2.0 + 3.0, Color(0, 0, 0, 0.22))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_texture(TABLETE, Vector2(-17.0, -17.0))
	draw_rect(caixa, _cor(str(d["base"])))
	if d["atual"] == ModeloMural.RUIDO:
		draw_rect(miolo, COR_RUIDO_B)
		var meio := miolo.size / 2.0
		draw_rect(Rect2(miolo.position, meio), COR_RUIDO_A)
		draw_rect(Rect2(miolo.position + meio, meio), COR_RUIDO_A)
	else:
		draw_rect(miolo, _cor(str(d["atual"])))

	# Glifo da runa gravado no miolo
	var indice: int = GLIFO_DE.get(nome_arquivo.get_basename(), 0)
	draw_texture_rect_region(GLIFOS, Rect2(-6.0, -6.0, 12.0, 12.0), Rect2(indice * 12.0, 0.0, 12.0, 12.0))

	if _modelo.preparada(nome_arquivo):
		draw_rect(Rect2(-18.0, -18.0, 36.0, 36.0), COR_PALCO, false, 2.0)
	elif _modelo.modificada(nome_arquivo):
		draw_rect(Rect2(-18.0, -18.0, 36.0, 36.0), COR_OFICINA, false, 2.0)
	if _brilho > 0.0:
		draw_rect(caixa.grow(5.0), Color(1.0, 0.95, 0.4, _brilho), false, 2.0)

	var fonte := ThemeDB.fallback_font
	var rotulo := nome_arquivo.get_basename()
	var largura := fonte.get_string_size(rotulo, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
	draw_string(fonte, Vector2(-largura / 2.0, TAM / 2.0 + 14.0), rotulo,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 7, COR_TINTA)
