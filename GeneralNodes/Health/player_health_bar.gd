class_name PlayerHealthBar
extends CanvasLayer
## HUD de coracoes do Player. Um coracao por ponto de vida; ao levar dano os
## coracoes viram cinza da direita para a esquerda ate zerar.

const HEART_ICON_SCENE : PackedScene = preload("res://GeneralNodes/Health/HeartIcon.tscn")

@onready var hearts_container : HBoxContainer = $Hearts

var _hearts : Array[HeartIcon] = []

func _ready() -> void:
	var player : Player = PlayerManager.player
	if player == null:
		return
	player.health_component.health_changed.connect(_on_health_changed)
	_on_health_changed(player.health_component.current_health, player.health_component.max_health)

func _on_health_changed(current_health : int, max_health : int) -> void:
	_rebuild_if_needed(max_health)
	for i in _hearts.size():
		_hearts[i].set_filled(i < current_health)

func _rebuild_if_needed(max_health : int) -> void:
	if _hearts.size() == max_health:
		return
	for heart in _hearts:
		heart.queue_free()
	_hearts.clear()
	for i in max_health:
		var heart : HeartIcon = HEART_ICON_SCENE.instantiate()
		hearts_container.add_child(heart)
		_hearts.append(heart)
