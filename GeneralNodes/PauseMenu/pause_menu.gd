extends CanvasLayer

signal resumed
signal quit_requested

const GRUPO_SISTEMAS_PAUSAVEIS := "sistema_pausavel"

const DURACAO_FADE := 0.15

@onready var raiz: Control = %Control
@onready var continuar_button: Button = %ContinuarButton
@onready var sair_button: Button = %SairButton

var _pausado_por_outro_sistema: bool = false

func _ready() -> void:
	hide()
	continuar_button.pressed.connect(continuar)
	sair_button.pressed.connect(sair)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if visible:
			continuar()
		else:
			abrir()
		get_viewport().set_input_as_handled()

func abrir() -> void:
	# Se algo (ex.: um diálogo) já tinha pausado a árvore, o menu não deve
	# despausar tudo sozinho ao ser fechado depois.
	_pausado_por_outro_sistema = get_tree().paused
	_avisar_sistemas_pausaveis(true)
	show()
	get_tree().paused = true
	# Entrada suave e foco no primeiro botão (navegação por teclado/Enter)
	raiz.modulate.a = 0.0
	create_tween().tween_property(raiz, "modulate:a", 1.0, DURACAO_FADE)
	continuar_button.grab_focus()

func continuar() -> void:
	hide()
	_avisar_sistemas_pausaveis(false)
	if not _pausado_por_outro_sistema:
		get_tree().paused = false
	resumed.emit()

func _avisar_sistemas_pausaveis(pausar: bool) -> void:
	for sistema in get_tree().get_nodes_in_group(GRUPO_SISTEMAS_PAUSAVEIS):
		if sistema == self:
			continue
		if pausar and sistema.has_method("pausar"):
			sistema.pausar()
		elif not pausar and sistema.has_method("despausar"):
			sistema.despausar()

func sair() -> void:
	quit_requested.emit()
	get_tree().quit()
