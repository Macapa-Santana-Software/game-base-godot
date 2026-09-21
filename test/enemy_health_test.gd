extends Node
## Teste manual da integracao Enemy + HealthComponent: rode a cena (F6).
## O resultado vai para o Output e, se disponivel, para o debugger do Claudot.

const ENEMY_SCENE : PackedScene = preload("res://Enemies/Slime/slime.tscn")

var _failures : int = 0

func _ready() -> void:
	var enemy : Enemy = ENEMY_SCENE.instantiate()
	add_child(enemy)

	var health : HealthComponent = enemy.get_node_or_null("HealthComponent")
	_check("Enemy possui um no HealthComponent", health != null)
	if health == null:
		_finish()
		return
	_check("enemy.health_component aponta para o mesmo no", enemy.health_component == health)
	_check("Enemy tem max_health = 3 por padrao", enemy.max_health == 3)
	_check("HealthComponent.max_health == 3", health.max_health == 3)
	_check("current_health comeca em 3", health.current_health == 3)
	_check("Enemy nao esta morto ao iniciar", not health.is_dead())

	_check("dano direto de 1 aplica 1", health.take_damage(1) == 1)
	_check("vida = 2", health.current_health == 2)
	_check("cura de 1 recupera 1", health.heal(1) == 1)
	_check("vida = 3", health.current_health == 3)
	_check("cura de 100 nao recupera nada (ja esta cheio)", health.heal(100) == 0)
	_check("vida nao ultrapassa o maximo", health.current_health == 3)
	_check("dano de 999 aplica so 3", health.take_damage(999) == 3)
	_check("vida nao fica abaixo de 0", health.current_health == 0)
	_check("is_dead() verdadeiro", health.is_dead())
	_check("Enemy marcou is_dead ao zerar a vida (Parte 5)", enemy.is_dead)

	# A vida maxima e configuracao de cada entidade.
	var tough_enemy : Enemy = ENEMY_SCENE.instantiate()
	tough_enemy.max_health = 8
	add_child(tough_enemy)
	_check("segundo Enemy com max_health 8 comeca com 8", tough_enemy.health_component.current_health == 8)
	_check("primeiro Enemy nao foi afetado pelo segundo", health.max_health == 3)

	_finish()

func _finish() -> void:
	_log("RESULTADO: " + ("OK" if _failures == 0 else "%d FALHA(S)" % _failures))

func _check(label : String, condition : bool) -> void:
	if not condition:
		_failures += 1
	_log(("[OK]    " if condition else "[FALHOU] ") + label)

func _log(text : String) -> void:
	print(text)
	var capture : Node = get_node_or_null("/root/OutputCapture")
	if capture:
		capture.capture_print(text)
