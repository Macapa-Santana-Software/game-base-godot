extends Control
## Menu inicial (simples): JOGAR abre o prólogo, SAIR fecha o jogo.

@export_file("*.tscn") var cena_jogar: String = "res://Dialogo/Prologo/CenaPrologo.tscn"

@onready var jogar_button: Button = %JogarButton
@onready var sair_button: Button = %SairButton


func _ready() -> void:
	jogar_button.pressed.connect(_on_jogar_pressed)
	sair_button.pressed.connect(_on_sair_pressed)
	jogar_button.grab_focus()


func _on_jogar_pressed() -> void:
	Diario.limpar()  # jogo novo: o Diário começa vazio
	get_tree().change_scene_to_file(cena_jogar)


func _on_sair_pressed() -> void:
	get_tree().quit()
