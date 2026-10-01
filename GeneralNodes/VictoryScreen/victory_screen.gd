extends CanvasLayer

## Emitido quando o jogador clica em "PRÓXIMA FASE".
## Ouvido pela fase, que resolve a troca via FaseManager.
signal proxima_fase_pressed

const GRUPO := "victory_screen"

@onready var proxima_fase_button: Button = $Control/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ProximaFaseButton

func _ready() -> void:
	add_to_group(GRUPO)
	hide()
	proxima_fase_button.pressed.connect(_on_proxima_fase_pressed)

func mostrar() -> void:
	show()
	get_tree().paused = true

func _on_proxima_fase_pressed() -> void:
	proxima_fase_pressed.emit()
