extends Node2D

@onready var terminal_ui = $CanvasLayer/TerminalUI
@onready var terminal_object = $ObjetoTerminal
@onready var player: Player = $Player
@onready var porta: StaticBody2D = $Porta

var _interpreter: TerminalCommandInterpreter


func _ready() -> void:
	_interpreter = TerminalCommandInterpreter.new()
	add_child(_interpreter)
	terminal_ui.set_interpreter(_interpreter)

	player.interaction_requested.connect(_on_player_interaction_requested)
	terminal_object.terminal_requested.connect(_on_terminal_requested)

	GameState.commit_created.connect(_on_commit_created)
	GameState.checkout_applied.connect(_on_checkout_applied)


func _on_player_interaction_requested(interactable: Node) -> void:
	if interactable.has_method("request_terminal_session"):
		interactable.request_terminal_session()


func _on_terminal_requested(_terminal_node: Node) -> void:
	terminal_ui.abrir()
	terminal_ui.escrever_no_terminal("Sessão iniciada. Branch atual: %s" % GameState.current_branch)


func _on_commit_created(_commit_data: Dictionary) -> void:
	if is_instance_valid(porta):
		porta.queue_free()
		terminal_ui.escrever_no_terminal("Commit válido detectado. O portal foi desbloqueado.")


func _on_checkout_applied(world_state: Dictionary) -> void:
	_apply_platform_state(world_state.get("platforms_enabled", []))
	_apply_enemy_state(world_state.get("enemy_positions", {}))
	terminal_ui.escrever_no_terminal("Versão do mundo aplicada: %s" % world_state.get("state_id", "desconhecida"))


func _apply_platform_state(platforms_enabled: Array) -> void:
	for node in get_tree().get_nodes_in_group("checkout_platform"):
		if node is Node2D:
			node.visible = platforms_enabled.has(node.name.to_lower())


func _apply_enemy_state(enemy_positions: Dictionary) -> void:
	for node in get_tree().get_nodes_in_group("checkout_enemy"):
		if enemy_positions.has(node.name.to_lower()) and node is Node2D:
			node.global_position = enemy_positions[node.name.to_lower()]
