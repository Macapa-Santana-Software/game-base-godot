class_name EnemyStateWander extends EnemyState


@export var anim_name : String = "walk"
@export var wander_speed : float = 20.0

@export_category("AI")
@export var state_animation_duration : float = 0.5
@export var state_cycles_min : int = 1
@export var state_cycles_max : int = 3
@export var next_state : EnemyState

@export_category("Obstacle Avoidance")
@export var wall_avoid_distance : float = 24.0

var _time : float = 0.0
var _direction : Vector2

# What happens when we initialize this state?
func init() -> void:
	pass # Replace with function body.


## What happens when the player enters this State?
func enter() -> void:
	_time = randf_range(state_cycles_min, state_cycles_max) * state_animation_duration
	
	#var rand = randf_range(0, 3)
	#_direction = enemy.DIR_4[rand]
	
	var rand := randi_range(0, enemy.DIR_4.size() - 1)
	_direction = enemy.DIR_4[rand]
	
	enemy.velocity = _direction * wander_speed
	enemy.set_direction(_direction)
	enemy.update_animation(anim_name)
	#pass


## What happens when the player exits this State?
func exit() -> void:
	pass


## What happens during the _process update in this State?
func process(_delta : float ) -> EnemyState:
	_time -= _delta
	if _time < 0:
		return next_state
	return null


## What happens during the _physics_process update in this State?
func physics(_delta : float) -> EnemyState:
	if _is_blocked_ahead(_direction):
		_direction = -_direction
		enemy.velocity = _direction * wander_speed
		enemy.set_direction(_direction)
	return null


## Verifica com um raycast se ha um obstaculo (parede) a frente, dentro de
## wall_avoid_distance, antes que o inimigo realmente colida com ele.
func _is_blocked_ahead(_dir : Vector2) -> bool:
	if _dir == Vector2.ZERO:
		return false
	var space_state := enemy.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		enemy.global_position,
		enemy.global_position + _dir * wall_avoid_distance,
		enemy.collision_mask,
		[enemy.get_rid()]
	)
	return not space_state.intersect_ray(query).is_empty()
