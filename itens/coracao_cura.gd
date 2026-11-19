class_name CoracaoCura extends Area2D
## Coração de cura: ao ser tocado pelo Player recupera vida e some.
## Se a vida já está cheia ele é coletado do mesmo jeito (sem efeito).

signal coletado(curou: int)

@export var cura: int = 1
@export var cor: Color = Color(0.95, 0.25, 0.4)
## Altura do balanço (pixels) e velocidade do flutuar.
@export var amplitude: float = 1.5
@export var velocidade: float = 3.0

var _tempo: float = 0.0
var _usado: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_tempo += delta
	queue_redraw()


func _draw() -> void:
	var y := sin(_tempo * velocidade) * amplitude
	var c := cor
	# Coração em "pixel art": dois lóbulos e uma ponta.
	draw_rect(Rect2(-5, -4 + y, 4, 4), c)
	draw_rect(Rect2(1, -4 + y, 4, 4), c)
	draw_rect(Rect2(-6, -2 + y, 12, 3), c)
	draw_rect(Rect2(-4, 1 + y, 8, 2), c)
	draw_rect(Rect2(-2, 3 + y, 4, 2), c)
	draw_rect(Rect2(-4, -3 + y, 2, 2), Color(1, 1, 1, 0.6))


func _on_body_entered(body: Node) -> void:
	if _usado or not (body is Player):
		return
	_usado = true
	var recuperado: int = (body as Player).health_component.heal(cura)
	coletado.emit(recuperado)
	queue_free()
