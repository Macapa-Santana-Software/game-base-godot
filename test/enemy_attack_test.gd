extends Node
## Teste da Parte 6: Enemy -> ataque -> AttackHurtBox -> Player HitBox -> HealthComponent.
## Usa a IA real do Slime (deteccao -> Chase -> Attack), sem forcar nada.
## Roda ~15 s. Resultado no Output e, em uma unica mensagem, no debugger do Claudot.

const PLAYER_SCENE : PackedScene = preload("res://Player/player.tscn")
const SLIME_SCENE : PackedScene = preload("res://Enemies/Slime/slime.tscn")

var _failures : int = 0
var _lines : PackedStringArray = []

var _player_hits : int = 0
var _player_died : int = 0
var _windows : Array[Dictionary] = []   # {open: float, close: float, hits: int}
var _attack_touches : int = 0
var _now : float = 0.0
var _prev_monitoring : bool = false
var _monitoring_outside_window : bool = false
var _watch : Enemy = null

func _ready() -> void:
	await _run()
	_lines.append("RESULTADO: " + ("OK" if _failures == 0 else "%d FALHA(S)" % _failures))
	for line in _lines:
		print(line)
	var capture : Node = get_node_or_null("/root/OutputCapture")
	if capture:
		capture.capture_print(" | ".join(_lines))

func _physics_process(delta : float) -> void:
	_now += delta
	if _watch == null or not is_instance_valid(_watch):
		return
	var monitoring : bool = _watch.attack_hurt_box.monitoring
	var in_attack : bool = _watch.state_machine.current_state is EnemyStateAttack
	if monitoring and not _prev_monitoring:
		_windows.append({"open": _now, "close": -1.0})
	elif not monitoring and _prev_monitoring and not _windows.is_empty():
		_windows[-1]["close"] = _now
	if monitoring and not in_attack:
		_monitoring_outside_window = true
	_prev_monitoring = monitoring

func _run() -> void:
	var player : Player = PLAYER_SCENE.instantiate()
	add_child(player)
	var p_health : HealthComponent = player.health_component
	p_health.damaged.connect(func(_a: int, _c: int) -> void:
		_player_hits += 1)
	p_health.died.connect(func() -> void: _player_died += 1)

	var slime : Enemy = SLIME_SCENE.instantiate()
	slime.position = Vector2(60, 0)
	add_child(slime)
	_watch = slime
	var s_health : HealthComponent = slime.health_component
	var hurt : HurtBox = slime.attack_hurt_box
	hurt.area_entered.connect(func(_a: Area2D) -> void: _attack_touches += 1)

	# ---------- Estado inicial e configuracao ----------
	_check("Player comeca com 10 HP", p_health.current_health == 10)
	_check("Enemy comeca com 3 HP", s_health.current_health == 3)
	_check("Chase tem attack_state ligado ao EnemyStateAttack", slime.chase_state.attack_state is EnemyStateAttack)
	_check("AttackHurtBox: layer 0 / mask 2 / nao detectavel / desligado / dano 1", hurt.collision_layer == 0 and hurt.collision_mask == 2 and not hurt.monitorable and not hurt.monitoring and hurt.damage == 1)
	_check("Player HitBox: layer 2 (o que a mask 2 do ataque enxerga)", (player.get_node("HitBox") as HitBox).collision_layer == 2)
	_check("Enemy HitBox: layer 256 (fora da mask do ataque)", (slime.hit_box.collision_layer & hurt.collision_mask) == 0)

	# ---------- Deteccao -> Chase -> Attack (IA real) ----------
	var reached_attack : bool = await _wait_until(func() -> bool: return slime.state_machine.current_state is EnemyStateAttack, 4.0)
	_check("DetectionArea -> Chase -> Attack: Enemy entrou em Attack", reached_attack)
	_check("Fora da janela de ataque: AttackHurtBox desligado", not hurt.monitoring)

	# ---------- Ataque 1 ----------
	await _wait_until(func() -> bool: return _windows.size() >= 1 and _windows[0]["close"] > 0.0, 3.0)
	_check("Ataque 1: janela abriu e fechou", _windows.size() >= 1 and _windows[0]["close"] > 0.0)
	await _frames(10)
	_check("Ataque 1: Player 10 -> 9 (1 de dano)", p_health.current_health == 9)
	_check("Ataque 1: apenas 1 dano nessa janela", _windows.size() >= 1 and _player_hits == 1)
	_check("Ataque 1: janela ~0.2 s (medido %.2f)" % _window_len(0), absf(_window_len(0) - 0.2) < 0.1)

	# ---------- Ataque 2, depois do cooldown ----------
	await _wait_until(func() -> bool: return _windows.size() >= 2 and _windows[1]["close"] > 0.0, 5.0)
	await _frames(10)
	_check("Ataque 2 (apos cooldown): Player 9 -> 8", p_health.current_health == 8)
	_check("Ataque 2: apenas 1 dano nessa janela", _windows.size() >= 2 and _player_hits == 2)
	if _windows.size() >= 2:
		var gap : float = _windows[1]["open"] - _windows[0]["open"]
		_check("Intervalo entre ataques ~ duracao+cooldown = 2.0 s (medido %.2f)" % gap, absf(gap - 2.0) < 0.3)
	_check("AttackHurtBox nunca ficou ligado fora do estado Attack", not _monitoring_outside_window)
	_check("Enemy nao tomou dano do proprio ataque (3 HP)", s_health.current_health == 3)
	_check("Toques do AttackHurtBox = 2 (um por ataque)", _attack_touches == 2)

	# ---------- Player ainda ataca o Enemy; Enemy ainda morre ----------
	for i in 3:
		await _attack()
	await _frames(5)
	_check("Player atacou 3x: Enemy morreu e foi removido", not is_instance_valid(slime))
	_watch = null
	var hp_after_fight : int = p_health.current_health
	_check("Player continua funcionando (HP %d, vivo)" % hp_after_fight, hp_after_fight > 0 and player.state_machine.can_process())

	# ---------- Enemy mata o Player: apenas died(), sem reacao ----------
	_lines.append("INFO: reduzindo o Player a 1 HP para o teste de morte")
	p_health.take_damage(p_health.current_health - 1)
	var hits_before : int = _player_hits
	var slime2 : Enemy = SLIME_SCENE.instantiate()
	slime2.position = Vector2(60, 0)
	add_child(slime2)
	await _wait_until(func() -> bool: return _player_died > 0, 8.0)
	_check("Ataque do Enemy levou o Player a 0 HP e died() foi emitido 1 vez", p_health.current_health == 0 and p_health.is_dead() and _player_died == 1)
	_check("Player NAO foi removido nem reagiu (Parte 7 ainda nao existe)", is_instance_valid(player) and player.is_inside_tree() and player.state_machine.can_process())
	await get_tree().create_timer(2.5).timeout
	_check("Novos ataques do Enemy nao repetem died() nem mudam a vida", _player_died == 1 and p_health.current_health == 0)
	_lines.append("INFO: hits totais no Player = %d (antes da morte: %d)" % [_player_hits, hits_before])

func _window_len(index : int) -> float:
	if _windows.size() <= index or _windows[index]["close"] < 0.0:
		return -1.0
	return _windows[index]["close"] - _windows[index]["open"]

func _wait_until(condition : Callable, timeout : float) -> bool:
	var waited : float = 0.0
	while waited < timeout:
		if condition.call():
			return true
		await get_tree().physics_frame
		waited += get_physics_process_delta_time()
	return condition.call()

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
