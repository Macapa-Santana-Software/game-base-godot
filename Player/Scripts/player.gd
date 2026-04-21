class_name Player extends CharacterBody2D

var cardinal_direction : Vector2 = Vector2.DOWN
var direction : Vector2 = Vector2.ZERO

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var state_machine: PlayerStateMachine = $StateMachine

signal DirectionChanged(new_direction : Vector2)
signal interaction_requested(interactable: Node)

var _nearby_terminal: Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state_machine.Initialize(self)
	$AreaColetora.body_entered.connect(_on_area_coletora_body_entered)
	pass # Replace with function body.

 
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Definindo a direção em que o player está olhando
	#direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	#direction.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	direction = Vector2(
		Input.get_axis("left", "right"),
		Input.get_axis("up", "down")
	).normalized()
	
	pass

func _physics_process(_delta: float) -> void:
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interagir") and _nearby_terminal != null:
		interaction_requested.emit(_nearby_terminal)
		get_viewport().set_input_as_handled()
	

func SetDirection() -> bool:
	var new_dir : Vector2 = cardinal_direction
	if direction == Vector2.ZERO:
		return false
		
	if direction.y == 0:
		new_dir = Vector2.LEFT if direction.x < 0 else Vector2.RIGHT
	elif direction.x == 0:
		new_dir = Vector2.UP if direction.y < 0 else Vector2.DOWN
		
	if new_dir == cardinal_direction:
		return false
		
	cardinal_direction = new_dir
	DirectionChanged.emit(new_dir)
	sprite.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	return true


func UpdateAnimation(state : String) -> void:
	animation_player.play(state + "_" + AnimDirection())
	pass

func AnimDirection() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "down"
	elif cardinal_direction == Vector2.UP:
		return "up"
	else:
		return "side"

# Função para coletar itens (chamada quando colide com item)
func _on_item_coletado(nome_item):
	if get_parent().has_method("_coletar_item"):
		get_parent()._coletar_item(nome_item)

func _on_area_coletora_body_entered(body):
	if body is Area2D and body.has_method("get_nome_item"):
		_on_item_coletado(body.nome_item)
		body.queue_free()  # Chama no playground.gd


func set_nearby_terminal(terminal_node: Node) -> void:
	_nearby_terminal = terminal_node


func clear_nearby_terminal(terminal_node: Node) -> void:
	if _nearby_terminal == terminal_node:
		_nearby_terminal = null
