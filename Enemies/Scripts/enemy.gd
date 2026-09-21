class_name Enemy extends CharacterBody2D

signal direction_changed(new_direction : Vector2)
signal enemy_damaged()

const DIR_4 = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]

@export var max_health : int = 3

var cardinal_direction : Vector2 = Vector2.DOWN
var direction : Vector2 = Vector2.ZERO
var player : Player
var invulnerable : bool = false
var player_detected: bool = false
var is_dead : bool = false

@onready var detection_area: Area2D = $DetectionArea
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var hit_box : HitBox = $HitBox
@onready var attack_hurt_box : HurtBox = $AttackHurtBox
@onready var state_machine : EnemyStateMachine = $EnemyStateMachine
@onready var chase_state: EnemyStateChase = $EnemyStateMachine/EnemyStateChase
@onready var wander_state: EnemyStateWander = $EnemyStateMachine/EnemyStateWander
@onready var health_component: HealthComponent = $HealthComponent

func _ready() -> void:
	health_component.initialize(max_health)
	health_component.died.connect(_on_died)
	state_machine.initialize(self)
	player = PlayerManager.player
	pass

func _process(_delta: float) -> void:
	pass

func _physics_process(_delta: float) -> void:
	move_and_slide()

func set_direction(_new_direction : Vector2) -> bool:
	direction = _new_direction
	if direction == Vector2.ZERO:
		return false
		
	var direction_id : int = int(round(direction + cardinal_direction * 0.1 ).angle() / TAU * DIR_4.size())
	var new_dir = DIR_4[direction_id]
		
	if new_dir == cardinal_direction:
		return false
		
	cardinal_direction = new_dir
	direction_changed.emit(new_dir)
	sprite.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	return true

func update_animation(state : String) -> void:
	animation_player.play(state + "_" + anim_direction())
	pass

func anim_direction() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "down"
	elif cardinal_direction == Vector2.UP:
		return "up"
	else:
		return "side"

## Reacao ao died() do HealthComponent. A ordem importa: primeiro o Enemy se
## desliga por completo e so no fim se remove da cena.
func _on_died() -> void:
	if is_dead:
		return
	print("[Enemy] %s morreu: desligando IA, deteccao e HitBox, depois queue_free()" % name)
	is_dead = true                                           # 1. marca como morto
	state_machine.process_mode = Node.PROCESS_MODE_DISABLED  # 2. para a IA
	velocity = Vector2.ZERO                                  # 3. para o movimento
	set_physics_process(false)
	# 4-5. Este callback pode rodar dentro da fisica (golpe do Player), entao as
	# areas sao desligadas com set_deferred / disable().
	detection_area.set_deferred("monitoring", false)
	attack_hurt_box.deactivate()
	hit_box.disable()
	queue_free()                                             # 6. so agora remove

func _on_detection_area_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	if body is Player:
		print("PLAYER DETECTADO!")
		print("CHASE STATE: ", chase_state)
		print("CURRENT STATE ANTES: ", state_machine.current_state)
		
		player_detected = true
		state_machine.change_state(chase_state)
		print("CURRENT STATE DEPOIS: ", state_machine.current_state)

func _on_detection_area_body_exited(body: Node2D) -> void:
	if is_dead:
		return
	if body is Player:
		print("PLAYER PERDEU!")
		print("CHASE STATE: ", wander_state)
		print("CURRENT STATE ANTES: ", state_machine.current_state)
		
		player_detected = false
		state_machine.change_state(wander_state)
		print("CURRENT STATE DEPOIS: ", state_machine.current_state)
