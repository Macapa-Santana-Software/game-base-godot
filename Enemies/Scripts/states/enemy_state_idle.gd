class_name EnemyStateIdle extends EnemyState


@export var anim_name : String = "idle"

@export_category("AI")
@export var state_durantion_min : float = 0.5
@export var state_durantion_max : float = 1.5
@export var after_idle_state : EnemyState

var _timer : float = 0.0


# What happens when we initialize this state?
func init() -> void:
	pass # Replace with function body.


## What happens when the player enters this State?
func enter() -> void:
	enemy.velocity = Vector2.ZERO
	_timer = randf_range(state_durantion_min, state_durantion_max)
	enemy.update_animation(anim_name)
	pass


## What happens when the player exits this State?
func exit() -> void:
	pass


## What happens during the _process update in this State?
func process(_delta : float ) -> EnemyState:
	_timer -= _delta
	if _timer <= 0:
		return after_idle_state
	return null


## What happens during the _physics_process update in this State?
func physics(_delta : float) -> EnemyState:
	return null
