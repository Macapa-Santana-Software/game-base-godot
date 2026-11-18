class_name ObjetoRetorno extends Node2D
## Um arquivo da Câmara do Reset (visual provisório, desenhado por código). A aparência mostra
## ONDE o arquivo está, lido do repositório real:
##
##   no histórico  quadrado cheio com contorno verde (está num commit)
##   na caixa      contorno azul (staging area: preparado para o próximo commit)
##   solto         contorno laranja (está na pasta, mas o Git não o acompanha)
##   destruído     só o tracejado e um X (um reset --hard o apagou)
##
## `aparece_apos` é a flag da fase que o torna visível (antes disso a câmara está vazia).

const TAM := 26.0
const COR_HISTORICO := Color("3DDB7B")
const COR_CAIXA := Color("3DA9FF")
const COR_SOLTO := Color("FF9A3D")
const COR_DESTRUIDO := Color("FF4D6D")

@export var arquivo: String = ""
@export var aparece_apos: String = ""
@export var cor: Color = Color.WHITE
@export var rotulo: String = ""


func _ready() -> void:
	EstadoRetorno.conectar_mudancas(queue_redraw)
	queue_redraw()


func _estado() -> String:
	if EstadoRetorno.versionado(arquivo):
		return "historico"
	if EstadoRetorno.na_caixa(arquivo):
		return "caixa"
	if arquivo in GameState.inventario_player:
		return "solto"
	return "destruido"


func _draw() -> void:
	if not aparece_apos.is_empty() and not EstadoRetorno.flag(aparece_apos):
		return
	var estado := _estado()
	var caixa := Rect2(-TAM / 2.0, -TAM / 2.0, TAM, TAM)
	var fonte := ThemeDB.fallback_font
	var legenda := ""
	match estado:
		"historico":
			draw_rect(caixa, cor)
			draw_rect(caixa.grow(2.0), COR_HISTORICO, false, 2.0)
			legenda = "no histórico"
		"caixa":
			draw_rect(caixa, cor)
			draw_rect(caixa.grow(2.0), COR_CAIXA, false, 2.0)
			legenda = "na caixa"
		"solto":
			draw_rect(caixa, cor)
			draw_rect(caixa.grow(2.0), COR_SOLTO, false, 2.0)
			legenda = "solto na pasta"
		_:
			var pontos := [caixa.position, caixa.position + Vector2(TAM, 0.0), caixa.end, caixa.position + Vector2(0.0, TAM)]
			for i in range(4):
				var a: Vector2 = pontos[i]
				var b: Vector2 = pontos[(i + 1) % 4]
				draw_dashed_line(a, b, COR_DESTRUIDO, 1.0, 3.0)
			draw_line(caixa.position, caixa.end, COR_DESTRUIDO, 1.5)
			draw_line(caixa.position + Vector2(TAM, 0.0), caixa.position + Vector2(0.0, TAM), COR_DESTRUIDO, 1.5)
			legenda = "destruído"
	var largura := fonte.get_string_size(rotulo, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
	draw_string(fonte, Vector2(-largura / 2.0, TAM / 2.0 + 10.0), rotulo,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.85, 0.9, 0.95))
	var largura_2 := fonte.get_string_size(legenda, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x
	draw_string(fonte, Vector2(-largura_2 / 2.0, TAM / 2.0 + 19.0), legenda,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.6, 0.68, 0.76))
