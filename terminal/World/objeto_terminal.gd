extends Area2D

@onready var balao_aviso: Label = $LabelBalao
var player_perto: bool = false

func _ready() -> void:
	balao_aviso.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if player_perto and Input.is_action_just_pressed("interagir_terminal"):
		var ui = get_tree().get_first_node_in_group("terminal_ui")
		if ui:
			ui.abrir()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		balao_aviso.visible = true
		player_perto = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		balao_aviso.visible = false
		player_perto = false
