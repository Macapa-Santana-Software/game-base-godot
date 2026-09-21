class_name HitBox extends Area2D
## Area que RECEBE dano. Repassa o dano ao HealthComponent da entidade dona
## (se houver) e emite Damaged para quem quiser reagir (ex.: Plant).
## Nao conhece Player nem Enemy.

signal Damaged(damage : int)

@export var health_component : HealthComponent

var _disabled : bool = false

## Deixa de receber dano: fora das layers, nao detectavel e ignora TakeDamage.
## Usa set_deferred porque pode ser chamado durante um callback de fisica
## (ex.: o died() disparado por um golpe), quando o Godot bloqueia essas mudancas.
func disable() -> void:
	_disabled = true
	set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)

func TakeDamage(damage: int) -> void:
	if _disabled:
		return
	print("[HitBox] %s recebeu golpe de %d (HealthComponent ligado: %s)" % [get_parent().name, damage, health_component != null])
	if health_component:
		health_component.take_damage(damage)
	Damaged.emit(damage)
