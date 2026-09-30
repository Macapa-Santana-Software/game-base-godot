extends CanvasLayer

const GRUPO := "defeat_screen"

@onready var reiniciar_button: Button = $Control/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ReiniciarButton
@onready var sair_button: Button = $Control/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SairButton

func _ready() -> void:
	add_to_group(GRUPO)
	hide()
	reiniciar_button.pressed.connect(_on_reiniciar_pressed)
	sair_button.pressed.connect(_on_sair_pressed)

func mostrar() -> void:
	show()
	get_tree().paused = true

func _on_reiniciar_pressed() -> void:
	hide()
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_sair_pressed() -> void:
	get_tree().quit()
