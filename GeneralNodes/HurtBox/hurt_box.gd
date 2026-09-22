class_name HurtBox extends Area2D

@export var damage : int = 1
## Forca do empurrao que este ataque aplica em quem for atingido.
@export var knockback_force : float = 100.0
## Corpo de quem ataca, usado como origem da direcao do knockback (o alvo e
## empurrado para longe deste ponto). Se vazio, usa o proprio parent do HurtBox
## — o que ja funciona quando o HurtBox e filho direto do corpo do atacante.
@export var source : Node2D

var _hit_targets : Array[Area2D] = []
var _once_per_activation : bool = false

func _ready() -> void:
	area_entered.connect(AreaEntered)
	pass

func _process(_delta: float) -> void:
	pass

## Liga o HurtBox para UM ataque: cada HitBox leva dano no maximo uma vez
## ate deactivate(). Quem liga o monitoring direto (ataque do Player) nao e afetado.
## set_deferred porque pode ser chamado dentro de callbacks de fisica.
func activate() -> void:
	_hit_targets.clear()
	_once_per_activation = true
	set_deferred("monitoring", true)

func deactivate() -> void:
	_once_per_activation = false
	set_deferred("monitoring", false)

func AreaEntered(a : Area2D) -> void:
	print("[HurtBox] %s tocou em %s/%s" % [get_parent().name, a.get_parent().name, a.name])
	if _once_per_activation:
		if a in _hit_targets:
			print("[HurtBox] %s: %s ja foi atingido neste ataque, ignorado" % [get_parent().name, a.get_parent().name])
			return
		_hit_targets.append(a)
	if a is HitBox:
		var target : Node2D = a.get_parent() as Node2D
		var origin : Vector2 = source.global_position if source else (get_parent() as Node2D).global_position
		var direction : Vector2 = target.global_position - origin if target else Vector2.ZERO
		a.TakeDamage(damage, direction, knockback_force)
	pass
