class_name EnemyStateChase extends EnemyState

@export var anim_name: String = "walk"
@export var chase_speed: float = 40.0
@export var stop_distance: float = 16.0

func init() -> void:
	pass

func enter() -> void:
	enemy.update_animation(anim_name)

func exit() -> void:
	enemy.velocity = Vector2.ZERO

func process(_delta: float) -> EnemyState:
	return null

func physics(_delta: float) -> EnemyState:
	if enemy.player == null:
		return null
	
	var distance := enemy.global_position.distance_to(enemy.player.global_position)
	
	if distance <= stop_distance:
		enemy.velocity = Vector2.ZERO
		return null
	
	var direction := enemy.global_position.direction_to(enemy.player.global_position)
	
	enemy.velocity = direction * chase_speed
	enemy.set_direction(direction)
	
	return null
