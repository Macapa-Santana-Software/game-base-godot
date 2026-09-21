class_name EnemyStateAttack extends EnemyState

@export var anim_name: String = "attack"
## Duracao do ataque; o AttackHurtBox so fica ligado na janela dentro dele.
@export var attack_duration: float = 1.0
## Espera depois do ataque, ainda no estado, antes de poder atacar de novo.
@export var attack_cooldown: float = 1.0
@export_category("Attack Window")
## Segundos depois de entrar no estado em que o AttackHurtBox liga.
@export var hit_start: float = 0.3
## Por quantos segundos o AttackHurtBox fica ligado.
@export var hit_window: float = 0.2

var _elapsed: float = 0.0
var _window_open: bool = false

func init() -> void:
	pass

#func enter() -> void:
#	enemy.velocity = Vector2.ZERO
#	_timer = attack_duration
#	print("atacando")
	#enemy.update_animation(anim_name)
	
func enter() -> void:
	enemy.velocity = Vector2.ZERO
	_elapsed = 0.0
	_window_open = false
	print("ATACANDO")
	print("[EnemyAttack] %s atacou" % enemy.name)

func exit() -> void:
	enemy.velocity = Vector2.ZERO
	_close_window()

func process(_delta: float) -> EnemyState:
	return null

func physics(_delta: float) -> EnemyState:
	_elapsed += _delta

	if not _window_open and _elapsed >= hit_start and _elapsed < hit_start + hit_window:
		_window_open = true
		enemy.attack_hurt_box.activate()
		print("[EnemyAttack] %s: janela de ataque ABERTA (t=%.2f)" % [enemy.name, _elapsed])
	elif _window_open and _elapsed >= hit_start + hit_window:
		_close_window()

	if _elapsed >= attack_duration + attack_cooldown:
		return state_machine.prev_state

	return null

func _close_window() -> void:
	if not _window_open:
		return
	_window_open = false
	enemy.attack_hurt_box.deactivate()
	print("[EnemyAttack] %s: janela de ataque FECHADA (t=%.2f)" % [enemy.name, _elapsed])
