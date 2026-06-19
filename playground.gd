extends Node2D

const DialogoFase1 = preload("res://Dialogo/Fase1/DialogoFase1.tscn")

func _ready() -> void:
	var dialogo = DialogoFase1.instantiate()
	add_child(dialogo)
