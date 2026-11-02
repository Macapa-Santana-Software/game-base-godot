extends Sprite2D

## Fragmento de pedra que paira no vazio (movimento lento, em pixels inteiros).

@export var amplitude: float = 3.0
@export var velocidade: float = 0.8

var _base_y: float
var _t: float = 0.0


func _ready() -> void:
	_base_y = position.y
	_t = randf() * TAU


func _process(delta: float) -> void:
	_t += delta * velocidade
	position.y = _base_y + roundf(sin(_t) * amplitude)
