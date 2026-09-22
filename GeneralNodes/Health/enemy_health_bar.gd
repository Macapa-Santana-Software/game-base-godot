class_name EnemyHealthBar
extends Node2D
## Barra fina acima do inimigo: verde quando cheia, vai para vermelho conforme
## a vida esvazia e some quando a vida chega a zero.

@export var width : float = 20.0
@export var height : float = 3.0
@export var offset_y : float = -30.0
@export var full_color : Color = Color(0.3, 0.82, 0.3)
@export var empty_color : Color = Color(0.82, 0.22, 0.22)

@onready var _health_component : HealthComponent = get_parent().get_node("HealthComponent")

var _ratio : float = 1.0

func _ready() -> void:
	_health_component.health_changed.connect(_on_health_changed)

func _on_health_changed(current_health : int, max_health : int) -> void:
	_ratio = 0.0 if max_health <= 0 else clampf(float(current_health) / max_health, 0.0, 1.0)
	visible = _ratio > 0.0
	queue_redraw()

func _draw() -> void:
	var origin : Vector2 = Vector2(-width / 2.0, offset_y)
	draw_rect(Rect2(origin, Vector2(width, height)), Color(0, 0, 0, 0.55))
	var inner_size : Vector2 = Vector2(width - 2.0, height - 2.0)
	var fill_width : float = inner_size.x * _ratio
	if fill_width > 0.0:
		var color : Color = full_color.lerp(empty_color, 1.0 - _ratio)
		draw_rect(Rect2(origin + Vector2(1.0, 1.0), Vector2(fill_width, inner_size.y)), color)
