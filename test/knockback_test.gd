extends Node
## Teste da Parte 7 (Knockback). Cobre:
##  - Direcao do empurrao nas 4 direcoes cardeais (Enemy recebendo)
##  - Player recebendo knockback (simetrico ao Enemy)
##  - Golpe fatal nao aplica knockback (morte tem prioridade)
##  - EnemyStateMachine pausada durante o knockback e retomada depois
##    (volta pra Chase se o Player ainda estiver detectado, senao Wander)
##  - Um ataque = um knockback (nao duplica enquanto a HurtBox fica ligada)
##  - Knockback contra parede: nao atravessa um StaticBody2D
## Rode a cena (F6). Resultado no Output e, em uma unica mensagem, no
## debugger do Claudot.

const PLAYER_SCENE : PackedScene = preload("res://Player/player.tscn")
const SLIME_SCENE : PackedScene = preload("res://Enemies/Slime/slime.tscn")

var _failures : int = 0
var _lines : PackedStringArray = []

func _ready() -> void:
	await _run()
	_lines.append("RESULTADO: " + ("OK" if _failures == 0 else "%d FALHA(S)" % _failures))
	for line in _lines:
		print(line)
	var capture : Node = get_node_or_null("/root/OutputCapture")
	if capture:
		capture.capture_print(" | ".join(_lines))

func _run() -> void:
	await _test_enemy_directions()
	await _test_player_knockback()
	await _test_fatal_hit_no_knockback()
	await _test_ai_pause_and_resume()
	await _test_single_knockback_per_attack()
	await _test_wall_collision()

func _spawn_frozen_slime(pos : Vector2) -> Enemy:
	var slime : Enemy = SLIME_SCENE.instantiate()
	slime.position = pos
	add_child(slime)
	slime.state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	slime.velocity = Vector2.ZERO
	return slime

# ---------- Direcao: 4 casos cardeais, aplicados diretamente no Enemy ----------
# Usa a mesma formula do HurtBox (alvo.global_position - origem) para nao
# depender da geometria fixa do AttackHurtBox do Player.
func _test_enemy_directions() -> void:
	var cases : Array[Dictionary] = [
		{"label": "Player acima -> Enemy empurrado para baixo", "attacker_offset": Vector2(0, -40), "expect": Vector2.DOWN},
		{"label": "Player abaixo -> Enemy empurrado para cima", "attacker_offset": Vector2(0, 40), "expect": Vector2.UP},
		{"label": "Player a esquerda -> Enemy empurrado para direita", "attacker_offset": Vector2(-40, 0), "expect": Vector2.RIGHT},
		{"label": "Player a direita -> Enemy empurrado para esquerda", "attacker_offset": Vector2(40, 0), "expect": Vector2.LEFT},
	]
	for c in cases:
		var slime : Enemy = _spawn_frozen_slime(Vector2.ZERO)
		var attacker_pos : Vector2 = slime.global_position + c["attacker_offset"]
		var direction : Vector2 = slime.global_position - attacker_pos
		var before : Vector2 = slime.global_position
		slime.hit_box.TakeDamage(1, direction, 120.0)
		await _frames(6)
		var moved : Vector2 = slime.global_position - before
		_check("%s (deslocamento %s)" % [c["label"], moved], moved.length() > 0.5 and moved.normalized().dot(c["expect"]) > 0.5)
		slime.queue_free()
	await _frames(2)

# ---------- Player recebendo knockback (simetrico) ----------
func _test_player_knockback() -> void:
	var player : Player = PLAYER_SCENE.instantiate()
	add_child(player)
	var attacker_pos : Vector2 = player.global_position + Vector2(0, -50)
	var direction : Vector2 = player.global_position - attacker_pos
	var before : Vector2 = player.global_position
	var hit_box : HitBox = player.get_node("HitBox")
	hit_box.TakeDamage(1, direction, 150.0)
	_check("Durante o knockback: PlayerStateMachine pausada", player.state_machine.process_mode == Node.PROCESS_MODE_DISABLED)
	await _frames(6)
	var moved : Vector2 = player.global_position - before
	_check("Enemy acima -> Player empurrado para baixo (deslocamento %s)" % moved, moved.length() > 0.5 and moved.normalized().dot(Vector2.DOWN) > 0.5)
	await _frames(20)
	_check("Depois do knockback: PlayerStateMachine retomada", player.state_machine.can_process())
	player.queue_free()
	await _frames(2)

# ---------- Golpe fatal nao aplica knockback ----------
func _test_fatal_hit_no_knockback() -> void:
	var slime : Enemy = _spawn_frozen_slime(Vector2(200, 0))
	slime.health_component.take_damage(2)  # 3 -> 1, chamada direta, sem knockback
	slime.hit_box.TakeDamage(1, Vector2.RIGHT, 300.0)  # golpe fatal: 1 -> 0
	# queue_free() so libera o no no fim do frame: le velocity JA (o died() a
	# zera de forma sincrona) antes de esperar qualquer frame.
	_check("Golpe fatal nao aplica knockback (velocity continua zerada)", slime.velocity == Vector2.ZERO)
	await _frames(2)

# ---------- IA pausada durante o knockback e retomada depois ----------
func _test_ai_pause_and_resume() -> void:
	var player : Player = PLAYER_SCENE.instantiate()
	add_child(player)
	var slime : Enemy = SLIME_SCENE.instantiate()
	slime.position = Vector2(30, 0)
	add_child(slime)
	slime.chase_state.attack_state = null
	await _frames(10)
	_check("Setup: Enemy detectou o Player antes do teste de IA", slime.player_detected)

	var direction : Vector2 = slime.global_position - player.global_position
	slime.hit_box.TakeDamage(1, direction, 120.0)
	await _frames(2)
	_check("Durante o knockback: EnemyStateMachine pausada (Chase/Wander/Attack nao mexem na velocity)", slime.state_machine.process_mode == Node.PROCESS_MODE_DISABLED)

	await _frames(20)  # duration (0.18s) ja passou (~11 frames a 60fps)
	_check("Depois do knockback: EnemyStateMachine retomada", slime.state_machine.can_process())
	_check("Depois do knockback: Enemy voltou a perseguir (Player ainda detectado)", slime.state_machine.current_state == slime.chase_state)

	slime.queue_free()
	player.queue_free()
	await _frames(2)

# ---------- Um ataque = um knockback ----------
func _test_single_knockback_per_attack() -> void:
	var player : Player = PLAYER_SCENE.instantiate()
	add_child(player)
	var slime : Enemy = SLIME_SCENE.instantiate()
	slime.position = Vector2(0, -25)  # mesma posicao usada no enemy_attack_test/combat_damage_test
	add_child(slime)
	slime.state_machine.process_mode = Node.PROCESS_MODE_DISABLED

	var knockback_component : KnockbackComponent = player.get_node("KnockbackComponent")
	var hits : Array[int] = [0]
	knockback_component.knockback_started.connect(func() -> void: hits[0] += 1)

	slime.attack_hurt_box.activate()
	await _frames(15)  # HurtBox fica ligado por varios frames seguidos, mesmo overlap
	slime.attack_hurt_box.deactivate()
	_check("Um ataque = um knockback (contagem = %d)" % hits[0], hits[0] == 1)

	slime.queue_free()
	player.queue_free()
	await _frames(2)

# ---------- Knockback contra parede: nao atravessa ----------
func _test_wall_collision() -> void:
	var wall := StaticBody2D.new()
	wall.collision_layer = 16  # mesma layer que o mask=16 do Player/Enemy enxerga
	wall.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 200)
	shape.shape = rect
	wall.add_child(shape)
	wall.position = Vector2(50, 0)
	add_child(wall)
	await _frames(2)

	var slime : Enemy = _spawn_frozen_slime(Vector2(20, 0))  # entre o centro (0,0) e a parede (x=40..60)
	slime.hit_box.TakeDamage(1, Vector2.RIGHT, 600.0)  # forca alta de proposito
	await _frames(30)  # bem mais que os 0.18s do knockback
	_check("Knockback nao atravessa parede (Enemy ficou em x=%.1f, parede comeca em x=40)" % slime.global_position.x, slime.global_position.x < 40.0)

	wall.queue_free()
	slime.queue_free()
	await _frames(2)

func _frames(count : int) -> void:
	for i in count:
		await get_tree().physics_frame

func _check(label : String, condition : bool) -> void:
	if not condition:
		_failures += 1
	_lines.append(("[OK] " if condition else "[FALHOU] ") + label)
