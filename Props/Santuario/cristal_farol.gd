class_name CristalFarol extends Node2D

## Cristal-farol do Santuário: marca o caminho com luz ciano (rota principal) ou violeta (ramais opcionais).

@export var violeta: bool = false
@export var aceso: bool = true
@export var energia: float = 0.8

const COR_CIANO := Color("36D6E9")
const COR_VIOLETA := Color("8964D8")

@onready var sprite: Sprite2D = $Sprite2D
@onready var luz: PointLight2D = $Luz
@onready var animador: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	luz.color = COR_VIOLETA if violeta else COR_CIANO
	luz.energy = energia if aceso else 0.0
	if not aceso:
		sprite.frame = 5 if violeta else 0
		return
	animador.play("brilhar_violeta" if violeta else "brilhar_ciano")
	animador.seek(randf() * 0.8)   # cristais vizinhos não pulsam em sincronia
