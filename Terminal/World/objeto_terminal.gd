extends Area2D

signal terminal_requested(terminal_node: Node)

var player_esta_perto: bool = false
var _player_ref: Player
@onready var label_aviso: Label = $Label

func _ready() -> void:
	label_aviso.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body is Player:
		player_esta_perto = true
		_player_ref = body
		label_aviso.text = "Aperte T"
		label_aviso.show()
		body.set_nearby_terminal(self)


func _on_body_exited(body: Node) -> void:
	if body is Player:
		player_esta_perto = false
		label_aviso.hide()
		if body == _player_ref:
			body.clear_nearby_terminal(self)
			_player_ref = null


func request_terminal_session() -> void:
	label_aviso.hide()
	terminal_requested.emit(self)
