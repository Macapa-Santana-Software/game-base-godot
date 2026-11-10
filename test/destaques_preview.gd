extends Node2D
## Pré-visualização de teste dos ecos e fragmentos (Fase 2, Áreas 3 Main e Vida): mostra os
## coletáveis REAIS das áreas, com a câmera passando por cada um (a cada `INTERVALO` segundos).
## Só para conferir o destaque visual; não faz parte do jogo.

const INTERVALO := 4.0
const AREA_VIDA := "res://fases/fase_2/areas/area_3_vida.tscn"
const AREA_MAIN := "res://fases/fase_2/areas/area_3_main.tscn"
const DESLOCAMENTO_MAIN := Vector2(2000, 0)

var _alvos: Array[Vector2] = []
var _indice: int = 0
var _tempo: float = 0.0
@onready var _camera: Camera2D = $Camera2D


func _ready() -> void:
	var vida := (load(AREA_VIDA) as PackedScene).instantiate() as Node2D
	add_child(vida)
	var main := (load(AREA_MAIN) as PackedScene).instantiate() as Node2D
	main.position = DESLOCAMENTO_MAIN
	add_child(main)
	# alvos: eco da vida, fragmento da vida, eco de main, fragmento de main (posições locais das áreas)
	_alvos = [
		Vector2(720, 610), Vector2(748, 520),
		DESLOCAMENTO_MAIN + Vector2(144, 580), DESLOCAMENTO_MAIN + Vector2(268, 580),
	]
	_camera.global_position = _alvos[0]
	_camera.reset_smoothing()


func _process(delta: float) -> void:
	_tempo += delta
	if _tempo >= INTERVALO:
		_tempo = 0.0
		_indice = (_indice + 1) % _alvos.size()
		_camera.global_position = _alvos[_indice]
		_camera.reset_smoothing()
