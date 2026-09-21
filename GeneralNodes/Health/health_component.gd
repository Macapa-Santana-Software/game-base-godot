class_name HealthComponent extends Node
## Componente genérico de vida. Não conhece Player nem Enemy:
## a entidade só define max_health e escuta os sinais.

signal damaged(amount : int, current_health : int)
signal healed(amount : int, current_health : int)
signal health_changed(current_health : int, max_health : int)
signal died()

@export var max_health : int = 1:
	set(value):
		max_health = maxi(value, 1)
		if is_node_ready():
			current_health = mini(current_health, max_health)
			health_changed.emit(current_health, max_health)

## Desligue para silenciar os logs de vida desta entidade.
@export var log_enabled : bool = true

var current_health : int = 0

func _ready() -> void:
	current_health = max_health

## Define a vida máxima e enche a vida atual. Usado pelo dono do componente
## (Player, Enemy...) para aplicar a sua própria configuração.
func initialize(new_max_health : int) -> void:
	max_health = new_max_health
	current_health = max_health
	health_changed.emit(current_health, max_health)
	_log("iniciado com %d/%d HP" % [current_health, max_health])

func _log(text : String) -> void:
	if log_enabled:
		print("[Vida] %s: %s" % [get_parent().name, text])

## Aplica dano. Retorna o dano realmente aplicado (0 se ignorado).
func take_damage(amount : int) -> int:
	if amount <= 0 or is_dead():
		_log("dano %d ignorado (%s)" % [amount, "ja esta morto" if is_dead() else "valor invalido"])
		return 0
	var previous : int = current_health
	current_health = maxi(current_health - amount, 0)
	var applied : int = previous - current_health
	_log("levou %d de dano: %d -> %d (max %d)" % [applied, previous, current_health, max_health])
	damaged.emit(applied, current_health)
	health_changed.emit(current_health, max_health)
	if is_dead():
		_log("MORREU (died emitido)")
		died.emit()
	return applied

## Recupera vida. Retorna o valor realmente recuperado (0 se ignorado).
## Não cura quem já morreu.
func heal(amount : int) -> int:
	if amount <= 0 or is_dead():
		return 0
	var previous : int = current_health
	current_health = mini(current_health + amount, max_health)
	var recovered : int = current_health - previous
	_log("curou %d: %d -> %d (max %d)" % [recovered, previous, current_health, max_health])
	if recovered > 0:
		healed.emit(recovered, current_health)
		health_changed.emit(current_health, max_health)
	return recovered

func is_dead() -> bool:
	return current_health <= 0
