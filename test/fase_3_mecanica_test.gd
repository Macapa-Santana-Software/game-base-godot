extends Node
## Teste da Fase 3 (O Mural Corrompido): fluxo status -> diff -> restore -> restore --staged, a armadilha da
## mudança boa e os Altares, a história (assinatura W-3, lei original, notas) e o reinício do zero pelo menu.
## Rode a cena (F6) ou headless; o resultado também vai para %TEMP%/fase_3_teste.txt. Sai com código 1 se algo falhar.

const ARQUIVO_SAIDA := "fase_3_teste.txt"
const CenaFase3 := preload("res://fases/fase_3/fase_3.tscn")

var _falhas: int = 0
var _total: int = 0
var _saida: FileAccess


func _log(linha: String) -> void:
	print(linha)
	if _saida:
		_saida.store_line(linha)
		_saida.flush()


func _ok(condicao: bool, descricao: String) -> void:
	_total += 1
	if condicao:
		_log("  OK     " + descricao)
	else:
		_falhas += 1
		_log("  FALHA  " + descricao)


func _frames(n: int = 4) -> void:
	for _i in range(n):
		await get_tree().process_frame


func _ready() -> void:
	var pasta := OS.get_environment("TEMP") if OS.get_environment("TEMP") != "" else "/tmp"
	_saida = FileAccess.open(pasta.path_join(ARQUIVO_SAIDA), FileAccess.WRITE)
	var persistia: bool = Diario.persistir
	var diario_antes: Dictionary = Diario.estado()
	Diario.persistir = false
	await _testar()
	Diario.restaurar(diario_antes)
	Diario.persistir = persistia
	GameState.resetar_repositorio()
	_log("[TESTE FASE 3] %d verificações, %d falhas" % [_total, _falhas])
	get_tree().quit(1 if _falhas > 0 else 0)


func _a(args: Array) -> Array[String]:
	var r: Array[String] = []
	r.assign(args)
	return r


func _testar() -> void:
	GameState.resetar_repositorio()
	var fase := CenaFase3.instantiate()
	add_child(fase)
	await _frames(5)
	var m: ModeloMural = ModeloMural.ativo()

	_log("— Estado inicial e HUD —")
	_ok(m != null, "a fase tem o ModeloMural")
	_ok(fase.get_node_or_null("PainelObjetivos") == null, "sem painel de objetivos (HUD igual à da Fase 1)")
	_ok(fase.portal.locked, "o portal começa trancado")
	_ok(not fase.porta_1.get_node("Forma").disabled, "a porta 1 começa fechada")
	_ok(GameState.commits.back().get("autor", "") == "Os Escribas", "o commit 'Mural original' é dos Escribas")
	_ok(fase.assinatura.modulate.a == 0.0, "a assinatura W-3 começa escondida")
	_ok(fase.lei.text != fase.TEXTO_LEI, "a lei original começa coberta pelo ruído")

	_log("— Zona 1: status e diff —")
	m.texto_status()
	m.texto_diff(_a([]))
	await _frames()
	_ok(m.flag("diff_visto"), "o diff foi visto")
	_ok(fase.porta_1.get_node("Forma").disabled, "a porta 1 abre depois do diff")

	_log("— Zona 2: armadilha da mudança boa —")
	m.restaurar(_a(["."]))
	_ok(m.boa_perdida("mar.runa"), "restore . apagou a mudança boa do mar")
	_ok(not m.zona_2_ok(), "com o mar perdido a zona 2 não fecha")
	m.refazer_boas()
	_ok(m.zona_2_ok(), "o Altar da Reescrita devolve o mar e a zona 2 fecha")
	await _frames()
	_ok(fase.porta_2.get_node("Forma").disabled, "a porta 2 abre")
	await get_tree().create_timer(1.7).timeout
	_ok(fase.assinatura.modulate.a >= 0.99, "a assinatura W-3 reaparece ao lado do mar")

	_log("— Zona 3: Palco —")
	m.texto_status()
	_ok(m.preparada("eclipse.runa"), "a eclipse começa no Palco")
	m.restaurar(_a(["--staged", "eclipse.runa"]))
	m.restaurar(_a(["eclipse.runa"]))
	_ok(m.limpa("eclipse.runa"), "a eclipse fica limpa")
	_ok(m.zona_3_ok() and not fase.portal.locked, "a zona 3 fecha e o portal abre")
	await get_tree().create_timer(2.8).timeout
	_ok(fase.lei.text == fase.TEXTO_LEI, "a lei original aparece no lugar do ruído")

	_log("— Notas —")
	for id in [&"f3_placa_escribas", &"f3_ata_corrupcao", &"f3_diario_mar"]:
		_ok(not NotasHistoria.obter(id).is_empty(), "a nota %s está no catálogo" % id)
	_ok(fase.get_node_or_null("NotaPlaca") != null and fase.get_node_or_null("NotaAta") != null and fase.get_node_or_null("NotaDiario") != null, "as 3 notas estão na cena")

	_log("— Reiniciar fase (menu de pausa) —")
	var pausa: Node = fase.get_node("PauseMenu")
	_ok(pausa.reiniciar_button != null, "o menu de pausa tem o botão REINICIAR FASE")
	pausa.reiniciar_button.pressed.emit()
	_ok(pausa._confirmando_reinicio and pausa.reiniciar_button.text.begins_with("CONFIRMAR"), "o primeiro clique pede confirmação")
	pausa._cancelar_confirmacao()
	_ok(pausa.reiniciar_button.text == "REINICIAR FASE", "a confirmação pode ser cancelada")
	GameState.restaurar_checkpoint()
	var inicial: Dictionary = GameState.progresso_tutoria["mural"]["runas"]
	_ok(inicial["sol.runa"]["atual"] == ModeloMural.RUIDO and inicial["mar.runa"]["atual"] == "verde",
		"restaurar o checkpoint devolve as runas ao começo da fase")
	_ok(not GameState.progresso_tutoria["mural"]["flags"].has("diff_visto"), "e zera o progresso (flags)")

	fase.queue_free()
	await _frames()
