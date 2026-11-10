class_name MensagemHud extends CanvasLayer
## Faixa de texto temporária na base da tela. Canal das mensagens da Fase 2: dicas do
## cenário (barreiras, zonas) e falas do Eidolon em balão.
##
## PRIORIDADE: enquanto uma mensagem está na tela, uma de prioridade MENOR é descartada (não
## entra em fila). Sem prioridade informada vale 0, como antes. Assim uma fala do Eidolon
## (prioridade 2) não é atropelada por uma dica de barreira (0) e vice-versa só se for mais
## importante.

const GRUPO := &"mensagem_hud_fase2"
const FONTE := preload("res://Dialogo/MonospacePixel.ttf")
const DURACAO_MINIMA := 2.5
const CARACTERES_POR_SEGUNDO := 18.0
const COR_EIDOLON := Color("9be7ff")

@onready var painel: PanelContainer = $Painel
@onready var texto: Label = $Painel/Margem/Texto

var _tween: Tween
var _prioridade_atual: int = 0
var _fim_ms: int = 0


func _enter_tree() -> void:
	add_to_group(GRUPO)


func _ready() -> void:
	texto.add_theme_font_override("font", FONTE)
	texto.add_theme_font_size_override("font_size", 8)
	painel.modulate.a = 0.0
	painel.hide()


## Atalho estático: qualquer nó pode mostrar uma mensagem sem conhecer o HUD.
static func mostrar_em(no: Node, mensagem: String, prioridade: int = 0) -> void:
	var hud := _achar(no)
	if hud:
		hud.mostrar(mensagem, prioridade)
	else:
		print(mensagem)


## Fala de um personagem (ex.: Eidolon): "Quem: texto", com a cor dele. Devolve false se foi
## descartada por haver uma mensagem mais importante na tela (ou se não há HUD).
static func falar_em(no: Node, quem: String, mensagem: String, cor: Color = COR_EIDOLON, prioridade: int = 2) -> bool:
	var hud := _achar(no)
	if hud == null:
		return false
	return hud.mostrar("%s: %s" % [quem, mensagem], prioridade, cor)


static func _achar(no: Node) -> MensagemHud:
	if not no.is_inside_tree():
		return null
	return no.get_tree().get_first_node_in_group(GRUPO) as MensagemHud


## Devolve false se a mensagem foi descartada por prioridade.
func mostrar(mensagem: String, prioridade: int = 0, cor: Color = Color(-1, -1, -1)) -> bool:
	if Time.get_ticks_msec() < _fim_ms and prioridade < _prioridade_atual:
		return false
	if cor.r < 0.0:
		texto.remove_theme_color_override("font_color")
	else:
		texto.add_theme_color_override("font_color", cor)
	texto.text = mensagem
	painel.show()
	if _tween:
		_tween.kill()
	var duracao := maxf(DURACAO_MINIMA, mensagem.length() / CARACTERES_POR_SEGUNDO)
	_prioridade_atual = prioridade
	_fim_ms = Time.get_ticks_msec() + int(duracao * 1000.0)
	painel.modulate.a = 1.0
	_tween = create_tween()
	_tween.tween_interval(duracao)
	_tween.tween_property(painel, "modulate:a", 0.0, 0.4)
	_tween.tween_callback(painel.hide)
	return true
