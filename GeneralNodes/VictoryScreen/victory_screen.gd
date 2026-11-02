extends CanvasLayer

## Emitido quando o jogador clica em "PRÓXIMA FASE".
## Ouvido pela fase, que resolve a troca via FaseManager.
signal proxima_fase_pressed

const GRUPO := "victory_screen"
const DURACAO_FADE := 0.25

## Texto por número de fase. Fases sem entrada usam a mensagem genérica (e escondem o resumo).
const RESUMOS := {
	1: {
		"mensagem": "Você registrou o primeiro estado desta realidade.",
		"comandos": "git init   git status\ngit add   git commit",
	},
}
const MENSAGEM_GENERICA := "Objetivo cumprido. A realidade avança."

@onready var raiz: Control = %Control
@onready var titulo_label: Label = %TituloLabel
@onready var mensagem_label: Label = %MensagemLabel
@onready var separador: HSeparator = %Separador
@onready var comandos_titulo: Label = %ComandosTitulo
@onready var comandos_label: Label = %ComandosLabel
@onready var proxima_fase_button: Button = %ProximaFaseButton

func _ready() -> void:
	add_to_group(GRUPO)
	hide()
	proxima_fase_button.pressed.connect(_on_proxima_fase_pressed)

func mostrar() -> void:
	_preencher_textos()
	show()
	get_tree().paused = true
	raiz.modulate.a = 0.0
	create_tween().tween_property(raiz, "modulate:a", 1.0, DURACAO_FADE)
	if proxima_fase_button.visible:
		proxima_fase_button.grab_focus()

func _preencher_textos() -> void:
	var numero: int = FaseManager.get_current_phase_number()
	var resumo: Dictionary = RESUMOS.get(numero, {})
	titulo_label.text = "FASE %d CONCLUÍDA" % numero
	mensagem_label.text = resumo.get("mensagem", MENSAGEM_GENERICA)

	var tem_comandos := resumo.has("comandos")
	separador.visible = tem_comandos
	comandos_titulo.visible = tem_comandos
	comandos_label.visible = tem_comandos
	comandos_label.text = resumo.get("comandos", "")

	# Sem fase seguinte o botão não teria efeito: some, e a mensagem explica.
	if FaseManager.has_next_phase():
		proxima_fase_button.show()
	else:
		proxima_fase_button.hide()
		mensagem_label.text += "\nPor enquanto, é só. Volte em breve!"

func _on_proxima_fase_pressed() -> void:
	proxima_fase_pressed.emit()
