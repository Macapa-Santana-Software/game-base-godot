extends Node
## Teste manual da integracao Player + HealthComponent: rode a cena (F6).
## O resultado vai para o Output e, se disponivel, para o debugger do Claudot.

const PLAYER_SCENE : PackedScene = preload("res://Player/player.tscn")

var _failures : int = 0

func _ready() -> void:
	var player : Player = PLAYER_SCENE.instantiate()
	add_child(player)

	var health : HealthComponent = player.get_node_or_null("HealthComponent")
	_check("Player possui um no HealthComponent", health != null)
	if health == null:
		_finish()
		return
	_check("player.health_component aponta para o mesmo no", player.health_component == health)
	_check("max_health do componente = max_health do Player (10)", health.max_health == player.max_health and health.max_health == 10)
	_check("current_health comeca igual a max_health", health.current_health == health.max_health)

	_check("dano direto de 4 aplica 4", health.take_damage(4) == 4)
	_check("vida = 6", health.current_health == 6)
	_check("cura de 2 recupera 2", health.heal(2) == 2)
	_check("vida = 8", health.current_health == 8)
	_check("cura de 100 recupera so 2", health.heal(100) == 2)
	_check("vida nao ultrapassa o maximo", health.current_health == 10)
	_check("dano de 999 aplica so 10", health.take_damage(999) == 10)
	_check("vida nao fica abaixo de 0", health.current_health == 0)
	_check("is_dead() verdadeiro", health.is_dead())

	# A vida máxima é configuracao do Player, nao do componente.
	var tough_player : Player = PLAYER_SCENE.instantiate()
	tough_player.max_health = 25
	add_child(tough_player)
	_check("Player com max_health 25 comeca com 25", tough_player.health_component.current_health == 25)

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
