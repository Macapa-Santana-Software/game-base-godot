extends Area2D

@export var nome_item = "fragmento1"  # Nome único do item

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body is Player:
		var mensagem := GameState.collect_fragment(nome_item)
		var terminal_ui := get_tree().current_scene.find_child("TerminalUI", true, false)
		if terminal_ui and terminal_ui.has_method("escrever_no_terminal"):
			terminal_ui.escrever_no_terminal(mensagem)
		body._on_item_coletado(nome_item)
		queue_free()


func get_nome_item() -> String:
	return nome_item
