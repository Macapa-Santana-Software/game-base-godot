extends Node
## Teste manual do HealthComponent: rode a cena (F6) e veja o Output.

var _damaged_count : int = 0
var _died_count : int = 0
var _failures : int = 0

func _ready() -> void:
	var health : HealthComponent = HealthComponent.new()
	health.max_health = 10
	add_child(health)
	health.damaged.connect(func(_a: int, _c: int) -> void: _damaged_count += 1)
	health.died.connect(func() -> void: _died_count += 1)

	_check("começa cheio", health.current_health == 10)
	_check("não começa morto", not health.is_dead())

	_check("dano 3 aplica 3", health.take_damage(3) == 3)
	_check("vida 7", health.current_health == 7)

	_check("cura 100 recupera só 3", health.heal(100) == 3)
	_check("vida não passa do máximo", health.current_health == 10)

	_check("dano 999 aplica só 10", health.take_damage(999) == 10)
	_check("vida não fica abaixo de 0", health.current_health == 0)
	_check("está morto", health.is_dead())
	_check("died emitido 1 vez", _died_count == 1)

	_check("dano após morte é ignorado", health.take_damage(5) == 0)
	_check("cura após morte é ignorada", health.heal(5) == 0)
	_check("died não repete", _died_count == 1)
	_check("damaged emitido 2 vezes", _damaged_count == 2)

	var slime : HealthComponent = HealthComponent.new()
	slime.max_health = 3
	add_child(slime)
	_check("slime com 3 de vida", slime.current_health == 3)
	slime.max_health = 2
	_check("reduzir max_health ajusta a vida atual", slime.current_health == 2)

	print("RESULTADO: ", "OK" if _failures == 0 else "%d FALHA(S)" % _failures)

func _check(label : String, condition : bool) -> void:
	if not condition:
		_failures += 1
	print(("[OK]    " if condition else "[FALHOU] ") + label)
