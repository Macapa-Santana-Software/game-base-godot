extends Area2D

var player_esta_perto = false
@onready var label_aviso = $Label # Certifique-se que o nome do nó é Label

func _ready():
	label_aviso.hide() # Garante que comece escondido

func _on_body_entered(body):
	if body is Player:
		player_esta_perto = true
		label_aviso.show() # Mostra o texto "Aperte T"

func _on_body_exited(body):
	if body is Player:
		player_esta_perto = false
		label_aviso.hide() # Esconde o texto

func _process(_delta):
	if player_esta_perto and Input.is_action_just_pressed("interagir"):
		var terminal = get_tree().current_scene.find_child("TerminalUI")
		if terminal:
			terminal.abrir()
			label_aviso.hide() # Esconde o aviso enquanto o terminal está aberto
