extends Area2D

@onready var balao_aviso: Label = $LabelBalao
@onready var sprite: Sprite2D = $Sprite2D

## Obelisco de Dados: adormecido de longe, desperto (núcleo aceso) quando o jogador está perto.
@export var textura_inativa: Texture2D
@export var textura_ativa: Texture2D

var player_perto: bool = false

func _ready() -> void:
	balao_aviso.visible = false
	_atualizar_visual()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if player_perto and Input.is_action_just_pressed("interagir_terminal"):
		GameState.sincronizar_inventario_com_git()
		
		var ui = get_tree().get_first_node_in_group("terminal_ui")
		if ui:
			ui.abrir()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		balao_aviso.visible = true
		player_perto = true
		_atualizar_visual()

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		balao_aviso.visible = false
		player_perto = false
		_atualizar_visual()

func _atualizar_visual() -> void:
	var textura := textura_ativa if player_perto else textura_inativa
	if textura:
		sprite.texture = textura
