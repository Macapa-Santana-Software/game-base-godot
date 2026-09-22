class_name HitBox extends Area2D
## Area que RECEBE dano. Repassa o dano ao HealthComponent da entidade dona
## (se houver) e emite Damaged para quem quiser reagir (ex.: Plant).
## Nao conhece Player nem Enemy.

signal Damaged(damage : int)

@export var health_component : HealthComponent
## Opcional: se a entidade dona tiver um KnockbackComponent, o golpe tambem
## empurra. Sem sistema de knockback, TakeDamage continua funcionando so com dano.
@export var knockback_component : KnockbackComponent

var _disabled : bool = false

## Deixa de receber dano: fora das layers, nao detectavel e ignora TakeDamage.
## Usa set_deferred porque pode ser chamado durante um callback de fisica
## (ex.: o died() disparado por um golpe), quando o Godot bloqueia essas mudancas.
func disable() -> void:
	_disabled = true
	set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)

func TakeDamage(damage: int, knockback_direction: Vector2 = Vector2.ZERO, knockback_force: float = 0.0) -> void:
	if _disabled:
		return
	print("[HitBox] %s recebeu golpe de %d (HealthComponent ligado: %s)" % [get_parent().name, damage, health_component != null])
	if health_component:
		health_component.take_damage(damage)
	# Golpe fatal: quem morreu ja se desligou (died()) e zerou a propria
	# velocity — nao aplica knockback por cima disso.
	var just_died : bool = health_component != null and health_component.is_dead()
	if knockback_component and not just_died:
		knockback_component.apply(knockback_direction, knockback_force)
	Damaged.emit(damage)
