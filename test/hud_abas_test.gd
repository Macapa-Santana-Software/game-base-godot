extends Node
## Teste da HUD recolhível (abas do Manual, da IA, dos Objetivos e dos Conceitos): regra de transparência
## das abas e o quadro da IA que abre/recolhe. Sai com código 1 se algo falhar.

var _falhas: int = 0
var _total: int = 0


func _ok(condicao: bool, descricao: String) -> void:
	_total += 1
	print(("  OK     " if condicao else "  FALHA  ") + descricao)
	if not condicao:
		_falhas += 1


func _frames(n: int = 4) -> void:
	for _i in range(n):
		await get_tree().process_frame


func _ready() -> void:
	_ok(AbaHud.alfa_da_aba(true, false, false, false) == 1.0, "painel aberto: aba opaca")
	_ok(AbaHud.alfa_da_aba(false, false, false, true) == 1.0, "mouse em cima: aba opaca")
	_ok(AbaHud.alfa_da_aba(false, false, false, false) == AbaHud.ALFA_RECOLHIDA, "recolhido: aba translúcida")
	_ok(AbaHud.alfa_da_aba(false, true, false, false) == AbaHud.ALFA_NO_TERMINAL, "recolhido no terminal: ainda mais translúcida")
	_ok(AbaHud.ALFA_NO_TERMINAL < AbaHud.ALFA_RECOLHIDA and AbaHud.ALFA_RECOLHIDA < 1.0, "ordem: terminal < recolhido < opaco")
	_ok(AbaHud.alfa_da_aba(false, false, true, false) < 1.0, "com aviso pendente a aba continua translúcida")

	GameState.resetar_repositorio()
	var fase := (load("res://fases/fase_2/fase_2.tscn") as PackedScene).instantiate()
	add_child(fase)
	await _frames()
	var tutora: TutoraFase1
	for filho in fase.get_children():
		if filho is TutoraFase1:
			tutora = filho
	_ok(tutora != null, "a fase tem o quadro da IA")
	_ok(tutora._aberto and tutora._aba.modulate.a >= 0.99, "o quadro começa aberto, com a aba opaca")
	tutora.alternar_quadro()
	await get_tree().create_timer(0.4).timeout
	_ok(not tutora._aberto and tutora._aba.modulate.a < 0.5, "recolhido: a aba fica translúcida")
	_ok(tutora._painel.position.x > tutora._raiz.size.x - 1.0, "recolhido: o painel sai da tela")
	GameState.terminal_aberto.emit()
	await get_tree().create_timer(0.3).timeout
	_ok(tutora._aba.modulate.a < AbaHud.ALFA_RECOLHIDA, "no terminal: a aba fica ainda mais translúcida")
	GameState.terminal_fechado.emit()
	tutora.alternar_quadro()
	await get_tree().create_timer(0.4).timeout
	_ok(tutora._aberto and tutora._aba.modulate.a >= 0.99, "reabrir: aba opaca de novo")
	tutora.alternar_quadro()  # deixa como o jogador deixaria; restaura o padrão estático abaixo
	TutoraFase1._aberto_na_sessao = true

	fase.queue_free()
	await _frames()
	GameState.resetar_repositorio()
	print("[TESTE HUD] %d verificações, %d falhas" % [_total, _falhas])
	get_tree().quit(1 if _falhas > 0 else 0)
