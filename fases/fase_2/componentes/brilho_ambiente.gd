class_name BrilhoAmbiente extends Sprite2D
## Pulso suave e discreto de um brilho ambiente (halo aditivo). Só visual; sem lógica de jogo.

@export var intensidade: float = 0.25
@export var velocidade: float = 1.2

var _fase: float = 0.0
var _base: float = 1.0


func _ready() -> void:
	_fase = randf() * TAU
	_base = modulate.a


func _process(delta: float) -> void:
	_fase += delta * velocidade
	modulate.a = _base * (1.0 - intensidade + intensidade * (0.5 + 0.5 * sin(_fase)))
