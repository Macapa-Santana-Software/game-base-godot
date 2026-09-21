extends Node
## Teste de integracao do dano: ataque real do Player (input + State_Attack +
## AttackHurtBox) -> HitBox do Slime -> HealthComponent. Rode a cena (F6).
## Resultado no Output e, em uma unica mensagem, no debugger do Claudot.

const PLAYER_SCENE : PackedScene = preload("res://Player/player.tscn")
const SLIME_SCENE : PackedScene = preload("res://Enemies/Slime/slime.tscn")
const PLANT_SCENE : PackedScene = preload("res://Props/Plants/plant.tscn")

var _failures : int = 0
var _lines : PackedStringArray = []

var _hitbox_hits : int = 0
var _health_hits : int = 0
var _died_count : int = 0
var _attack_touches : int = 0
var _death : Dictionary = {}

func _ready() -> void:
	await _run()
	_lines.append("RESULTADO: " + ("OK" if _failures == 0 else "%d FALHA(S)" % _failures))
	for line in _lines:
		print(line)
	var capture : Node = get_node_or_null("/root/OutputCapture")
	if capture:
		capture.capture_print(" | ".join(_lines))

func _run() -> void:
	var player : Player = PLAYER_SCENE.instantiate()
	add_child(player)
	var slime_a : Enemy = _spawn_slime(Vector2(60, 0), false)

	# ---------- Auditoria de layers/masks/monitoring ----------
	var p_hit : HitBox = player.get_node("HitBox")
	var p_attack : HurtBox = player.get_node("Sprite2D/AttackHurtBox")
	var e_hit : HitBox = slime_a.get_node("HitBox")
	var e_hurt : HurtBox = slime_a.get_node("AttackHurtBox")
	var e_detect : Area2D = slime_a.get_node("DetectionArea")
	_check("Player body: layer 1 / mask 16", player.collision_layer == 1 and player.collision_mask == 16)
	_check("Enemy body: layer 256 / mask 16", slime_a.collision_layer == 256 and slime_a.collision_mask == 16)
	_check("Player HitBox: layer 2 / mask 0 / sem monitoring / monitorable", p_hit.collision_layer == 2 and p_hit.collision_mask == 0 and not p_hit.monitoring and p_hit.monitorable)
	_check("Enemy HitBox: layer 256 / mask 0 / sem monitoring / monitorable", e_hit.collision_layer == 256 and e_hit.collision_mask == 0 and not e_hit.monitoring and e_hit.monitorable)
	_check("Player AttackHurtBox: layer 0 / mask 256 / nao detectavel", p_attack.collision_layer == 0 and p_attack.collision_mask == 256 and not p_attack.monitorable)
	_check("Enemy HurtBox: layer 0 / mask 2 / nao detectavel / desligado", e_hurt.collision_layer == 0 and e_hurt.collision_mask == 2 and not e_hurt.monitorable and not e_hurt.monitoring)
	_check("DetectionArea: layer 0 / mask 1", e_detect.collision_layer == 0 and e_detect.collision_mask == 1)
	_check("HitBox do Player aponta para o HealthComponent do Player", p_hit.health_component == player.health_component)
	_check("HitBox do Enemy aponta para o HealthComponent do Enemy", e_hit.health_component == slime_a.health_component)

	# ---------- DetectionArea / IA ----------
	await _frames(10)
	_check("DetectionArea detectou o Player", slime_a.player_detected)
	_check("Enemy entrou em Chase", slime_a.state_machine.current_state == slime_a.chase_state)
	await get_tree().create_timer(1.5).timeout
	var dist : float = slime_a.global_position.distance_to(player.global_position)
	_check("Enemy parou na distancia definida (<= 17), dist=%.1f" % dist, dist <= 17.0 and slime_a.velocity == Vector2.ZERO)
	_check("Nenhum dano durante a deteccao/chase (Player 10, Enemy 3)", player.health_component.current_health == 10 and slime_a.health_component.current_health == 3)
	player.global_position = slime_a.global_position + Vector2(600, 0)
	await _frames(5)
	_check("Player saiu da DetectionArea", not slime_a.player_detected)
	_check("Enemy voltou para Wander", slime_a.state_machine.current_state == slime_a.wander_state)
	slime_a.queue_free()
	player.global_position = Vector2.ZERO
	await _frames(3)

	# ---------- PLAYER -> ENEMY (ataque real) ----------
	# slime_b fica com a IA ligada (nao congelado): a morte precisa parar a IA de verdade.
	var slime_b : Enemy = _spawn_slime(Vector2(0, 20), false)
	var b_health : HealthComponent = slime_b.health_component
	var b_hp_at_death : Array[int] = [-1]
	slime_b.get_node("HitBox").Damaged.connect(func(_d: int) -> void: _hitbox_hits += 1)
	p_attack.area_entered.connect(func(_a: Area2D) -> void: _attack_touches += 1)
	b_health.damaged.connect(func(_a: int, _c: int) -> void: _health_hits += 1)
	# Conectado depois do handler do proprio Enemy, entao _sample_death (deferred)
	# roda depois do desligamento e antes do queue_free ser efetivado.
	b_health.died.connect(func() -> void:
		_died_count += 1
		b_hp_at_death[0] = b_health.current_health
		_sample_death.call_deferred(slime_b))
	_check("Enemy comeca com 3 HP", b_health.current_health == 3)
	_check("Enemy vivo: IA ligada e is_dead falso", not slime_b.is_dead and slime_b.state_machine.can_process())
	await _frames(20)
	_check("HitBox sobreposto a HitBox nao causa dano (Player 10, Enemy 3)", player.health_component.current_health == 10 and b_health.current_health == 3)

	await _attack()
	_check("ataque 1: Enemy 3 -> 2, 1 golpe no HitBox, 1 no componente", b_health.current_health == 2 and _hitbox_hits == 1 and _health_hits == 1)
	await _attack()
	_check("ataque 2: Enemy 2 -> 1", b_health.current_health == 1 and _hitbox_hits == 2 and _health_hits == 2)
	_check("ainda nao morreu apos 2 ataques", not b_health.is_dead() and _died_count == 0)
	await _attack()
	_check("ataque 3: Enemy 1 -> 0, died() emitido 1 vez", b_hp_at_death[0] == 0 and _hitbox_hits == 3 and _health_hits == 3 and _died_count == 1)
	_check("morte: Enemy marcou is_dead", _death.get("is_dead", false))
	_check("morte: velocity zerada", _death.get("velocity_zero", false))
	_check("morte: EnemyStateMachine parada (process_mode DISABLED, can_process falso)", _death.get("sm_disabled", false))
	_check("morte: DetectionArea desligada (monitoring falso)", _death.get("detect_off", false))
	_check("morte: HitBox desligado (monitorable falso, layer 0)", _death.get("hit_off", false))
	_check("morte: HitBox ignora TakeDamage direto", _death.get("ignores_damage", false))
	_check("Enemy foi removido da cena", not is_instance_valid(slime_b))
	_check("Nenhum Slime restante na arvore", _count_enemies() == 0)
	await _attack()
	await _attack()
	_check("ataques 4 e 5 (Enemy morto): nenhum toque, golpe, dano ou died novo", _attack_touches == 3 and _hitbox_hits == 3 and _health_hits == 3 and _died_count == 1)
	_check("Player nao tomou dano do proprio ataque (10 HP)", player.health_component.current_health == 10)
	_check("Player continua funcionando (state machine ativa)", player.state_machine.can_process() and player.state_machine.current_state != null)

	# ---------- ENEMY -> PLAYER (infraestrutura; ataque forcado) ----------
	var slime_c : Enemy = _spawn_slime(Vector2(0, -25), true)
	var player_hits : Array[int] = [0]
	player.health_component.damaged.connect(func(_a: int, _c: int) -> void: player_hits[0] += 1)
	await _frames(5)
	var c_hurt : HurtBox = slime_c.get_node("AttackHurtBox")
	c_hurt.monitoring = true
	await _frames(15)
	c_hurt.monitoring = false
	_check("Enemy HurtBox -> Player HitBox: Player 10 -> 9, um unico golpe", player.health_component.current_health == 9 and player_hits[0] == 1)
	_check("Enemy nao tomou dano do proprio ataque (3 HP)", slime_c.health_component.current_health == 3)

	# ---------- Regressao: Plant continua usando HitBox ----------
	var plant : Plant = PLANT_SCENE.instantiate()
	plant.position = Vector2(300, 0)
	add_child(plant)
	var plant_hit : Node = plant.get_node("HitBox")
	_check("HitBox da Plant e o HitBox generico (layer 256 / mask 0)", plant_hit is HitBox and plant_hit.collision_layer == 256 and plant_hit.collision_mask == 0)
	plant_hit.TakeDamage(1)
	_check("Plant reage a Damaged (sem HealthComponent)", plant.is_queued_for_deletion())

## Fotografia do Enemy logo depois de desligado e antes de ser liberado.
func _sample_death(enemy : Enemy) -> void:
	_death["is_dead"] = enemy.is_dead
	_death["velocity_zero"] = enemy.velocity == Vector2.ZERO
	_death["sm_disabled"] = enemy.state_machine.process_mode == Node.PROCESS_MODE_DISABLED and not enemy.state_machine.can_process()
	_death["detect_off"] = not enemy.detection_area.monitoring
	_death["hit_off"] = not enemy.hit_box.monitorable and enemy.hit_box.collision_layer == 0
	var hits_before : int = _hitbox_hits
	enemy.hit_box.TakeDamage(1)
	_death["ignores_damage"] = _hitbox_hits == hits_before

func _count_enemies() -> int:
	var count : int = 0
	for child in get_children():
		if child is Enemy and not child.is_queued_for_deletion():
			count += 1
	return count

func _spawn_slime(pos : Vector2, frozen : bool) -> Enemy:
	var slime : Enemy = SLIME_SCENE.instantiate()
	slime.position = pos
	add_child(slime)
	# Este teste isola o dano Player -> Enemy: tira o ataque do Enemy do caminho
	# (ele e coberto em enemy_attack_test.tscn).
	slime.chase_state.attack_state = null
	if frozen:
		# Mantem o slime parado para isolar o teste de dano da IA.
		slime.state_machine.process_mode = Node.PROCESS_MODE_DISABLED
		slime.velocity = Vector2.ZERO
	return slime

func _attack() -> void:
	_send_attack(true)
	await get_tree().create_timer(0.1).timeout
	_send_attack(false)
	await get_tree().create_timer(0.7).timeout

func _send_attack(pressed : bool) -> void:
	var event : InputEventAction = InputEventAction.new()
	event.action = &"attack"
	event.pressed = pressed
	Input.parse_input_event(event)

func _frames(count : int) -> void:
	for i in count:
		await get_tree().physics_frame

func _check(label : String, condition : bool) -> void:
	if not condition:
		_failures += 1
	_lines.append(("[OK] " if condition else "[FALHOU] ") + label)
