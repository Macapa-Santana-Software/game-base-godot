extends Node2D

const DialogoFase1 = preload("res://Dialogo/Fase1/DialogoFase1.tscn")

@onready var exit_area: ExitArea = $ExitArea

var fase_concluida: bool = false

func _ready() -> void:
	var dialogo = DialogoFase1.instantiate()
	add_child(dialogo)

	GameState.commit_realizado.connect(_on_commit_realizado)
	exit_area.unlocked_entered.connect(_on_exit_area_unlocked_entered)

func _on_commit_realizado(_commit_info: Dictionary) -> void:
	exit_area.unlock()

func _on_exit_area_unlocked_entered() -> void:
	if fase_concluida:
		return
	fase_concluida = true
	print("[Fase 1] CONDIÇÃO DE VITÓRIA ATINGIDA!")
