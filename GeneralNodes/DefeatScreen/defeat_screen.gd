extends CanvasLayer

const GRUPO := "defeat_screen"

@onready var reiniciar_button: Button = $Control/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ReiniciarButton
@onready var sair_button: Button = $Control/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SairButton

func _ready() -> void:
	add_to_group(GRUPO)
	# Foto do jogo no início da fase (este _ready roda antes do script da fase): reiniciar volta a ela.
	GameState.guardar_checkpoint()
	hide()
	reiniciar_button.pressed.connect(_on_reiniciar_pressed)
	sair_button.pressed.connect(_on_sair_pressed)

func mostrar() -> void:
	show()
	get_tree().paused = true

func _on_reiniciar_pressed() -> void:
	hide()
	get_tree().paused = false
	# Recomeça a fase do zero: Git, inventário e progresso voltam ao que eram ao entrar nela.
	GameState.restaurar_checkpoint()
	Diario.descartar_tentativa()  # as notas lidas nesta tentativa voltam a aparecer não lidas no mapa
	get_tree().reload_current_scene()

func _on_sair_pressed() -> void:
	get_tree().quit()
