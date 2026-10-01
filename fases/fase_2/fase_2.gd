extends Node2D

@onready var exit_area: ExitArea = $ExitArea
@onready var victory_screen: CanvasLayer = $VictoryScreen

var fase_concluida: bool = false

func _ready() -> void:
	print("[FASE 2] Fase 2 carregada.")
	GameState.commit_realizado.connect(_on_commit_realizado)
	exit_area.unlocked_entered.connect(_on_exit_area_unlocked_entered)

func _on_commit_realizado(_commit_info: Dictionary) -> void:
	exit_area.unlock()

func _on_exit_area_unlocked_entered() -> void:
	if fase_concluida:
		return
	fase_concluida = true
	print("[FASE 2] CONDIÇÃO DE VITÓRIA ATINGIDA!")
	victory_screen.mostrar()
