class_name ObjetoRetorno extends Node2D
## Um arquivo da Câmara do Reset: um cartucho de aço (arte em fases/fase_6/arte/) com a cor do arquivo.
## O contorno mostra ONDE o arquivo está, lido do repositório real:
##
##   no histórico  contorno verde (está num commit)
##   na caixa      contorno azul (staging area: preparado para o próximo commit)
##   solto         contorno laranja (está na pasta, mas o Git não o acompanha)
##   destruído     só o tracejado e um X (um reset --hard o apagou): vira POEIRA
##
## `aparece_apos` é a flag da fase que o torna visível (antes disso a câmara está vazia).

const TAM := 26.0
const COR_HISTORICO := Color("3DDB7B")
const COR_CAIXA := Color("3DA9FF")
const COR_SOLTO := Color("FF9A3D")
const COR_DESTRUIDO := Color("FF4D6D")
const COR_TINTA := Color("0F0E0D")
const COR_CONTORNO := Color(0.93, 0.9, 0.82)
const CARTUCHO: Texture2D = preload("res://fases/fase_6/arte/cartucho_arquivo.png")
const GLIFOS: Texture2D = preload("res://fases/fase_6/arte/glifos_arquivo.png")
const MOLDURA := Rect2(-18.0, -18.0, 36.0, 36.0)

@export var arquivo: String = ""
@export var aparece_apos: String = ""
@export var cor: Color = Color.WHITE
@export var rotulo: String = ""
## Glifo do cartucho: 0 = mapa (planta), 1 = faísca (experimento).
@export var glifo: int = 0

var _estado_anterior: String = ""
var _poeira: CPUParticles2D


func _ready() -> void:
	_criar_poeira()
	_estado_anterior = _estado()
	EstadoRetorno.conectar_mudancas(_ao_mudar)
	queue_redraw()


## Poeira que sobe quando o arquivo é destruído por um `reset --hard`.
func _criar_poeira() -> void:
	_poeira = CPUParticles2D.new()
	_poeira.emitting = false
	_poeira.one_shot = true
	_poeira.amount = 44
	_poeira.lifetime = 1.5
	_poeira.explosiveness = 0.95
	_poeira.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_poeira.emission_sphere_radius = 8.0
	_poeira.direction = Vector2(0, -1)
	_poeira.spread = 180.0
	_poeira.gravity = Vector2(0, 14)
	_poeira.initial_velocity_min = 16.0
	_poeira.initial_velocity_max = 46.0
	_poeira.scale_amount_min = 1.5
	_poeira.scale_amount_max = 3.2
	var gradiente := Gradient.new()
	gradiente.set_color(0, Color(0.77, 0.75, 0.7, 0.95))
	gradiente.set_color(1, Color(0.55, 0.52, 0.47, 0.0))
	_poeira.color_ramp = gradiente
	_poeira.z_index = 4
	add_child(_poeira)


func _ao_mudar() -> void:
	var estado := _estado()
	var visivel := aparece_apos.is_empty() or EstadoRetorno.flag(aparece_apos)
	if visivel and estado == "destruido" and _estado_anterior != "destruido":
		_poeira.restart()
	_estado_anterior = estado
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
	var janela := Rect2(-TAM / 2.0, -TAM / 2.0, TAM, TAM)
	var legenda := ""
	if estado != "destruido":
		draw_set_transform(Vector2(0, TAM / 2.0 + 3.0), 0.0, Vector2(1.0, 0.3))
		draw_circle(Vector2.ZERO, TAM / 2.0 + 5.0, Color(0, 0, 0, 0.3))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_texture(CARTUCHO, Vector2(-17.0, -17.0))
		draw_rect(janela, Color(0.12, 0.11, 0.1))
		draw_rect(janela.grow(-4.0), cor)
		draw_texture_rect_region(GLIFOS, Rect2(-7.0, -7.0, 14.0, 14.0), Rect2(glifo * 14.0, 0.0, 14.0, 14.0))
	match estado:
		"historico":
			draw_rect(MOLDURA, COR_HISTORICO, false, 2.0)
			legenda = "no histórico"
		"caixa":
			draw_rect(MOLDURA, COR_CAIXA, false, 2.0)
			legenda = "na caixa"
		"solto":
			draw_rect(MOLDURA, COR_SOLTO, false, 2.0)
			legenda = "solto na pasta"
		_:
			var pontos := [MOLDURA.position, MOLDURA.position + Vector2(MOLDURA.size.x, 0.0), MOLDURA.end, MOLDURA.position + Vector2(0.0, MOLDURA.size.y)]
			for i in range(4):
				var a: Vector2 = pontos[i]
				var b: Vector2 = pontos[(i + 1) % 4]
				draw_dashed_line(a, b, COR_DESTRUIDO, 1.0, 3.0)
			draw_line(MOLDURA.position, MOLDURA.end, COR_DESTRUIDO, 1.5)
			draw_line(MOLDURA.position + Vector2(MOLDURA.size.x, 0.0), MOLDURA.position + Vector2(0.0, MOLDURA.size.y), COR_DESTRUIDO, 1.5)
			legenda = "destruído"
	_texto(rotulo, 7, TAM / 2.0 + 15.0, COR_TINTA)
	_texto(legenda, 6, TAM / 2.0 + 24.0, Color(0.2, 0.19, 0.17))


func _texto(texto: String, tamanho: int, y: float, cor_texto: Color) -> void:
	var fonte := ThemeDB.fallback_font
	var largura := fonte.get_string_size(texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho).x
	var pos := Vector2(-largura / 2.0, y)
	draw_string_outline(fonte, pos, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, 3, COR_CONTORNO)
	draw_string(fonte, pos, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, cor_texto)
