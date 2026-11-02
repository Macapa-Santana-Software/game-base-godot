extends Node2D

const DialogoFase1 = preload("res://Dialogo/Fase1/DialogoFase1.tscn")

@onready var exit_area: ExitArea = $ExitArea
@onready var victory_screen: CanvasLayer = $VictoryScreen

var fase_concluida: bool = false

## Arquivos do mapa que precisam estar versionados para liberar a saída
## (lidos dos itens colocados na cena, a mesma fonte usada pela IA e pelos objetivos).
var _arquivos_requeridos: Array[String] = []

func _ready() -> void:
	for item in get_tree().get_nodes_in_group(ItemColetavel.GRUPO_ARQUIVOS):
		_arquivos_requeridos.append(item.nome_do_item)

	var dialogo = DialogoFase1.instantiate()
	add_child(dialogo)

	var tutora := TutoraFase1.new()
	tutora.arquivos_requeridos = _arquivos_requeridos
	add_child(tutora)

	GameState.commit_realizado.connect(_on_commit_realizado)
	exit_area.unlocked_entered.connect(_on_exit_area_unlocked_entered)
	victory_screen.proxima_fase_pressed.connect(_on_proxima_fase_pressed)

func _on_proxima_fase_pressed() -> void:
	if not FaseManager.has_next_phase():
		return
	GameState.reset_fase()
	FaseManager.advance_to_next_phase()

func _on_commit_realizado(_commit_info: Dictionary) -> void:
	# A saída só abre quando TODOS os arquivos da fase foram registrados (a IA avisa o que falta)
	if GameState.arquivos_pendentes(_arquivos_requeridos).is_empty():
		exit_area.unlock()

func _on_exit_area_unlocked_entered() -> void:
	if fase_concluida:
		return
	fase_concluida = true
	print("[Fase 1] CONDIÇÃO DE VITÓRIA ATINGIDA!")
	victory_screen.mostrar()
