extends Node
## Teste da história da Fase 5 (Linhas Cruzadas): escolha guardada para as fases seguintes, o abalo do Eidolon
## (diálogo obrigatório que espera o terminal fechar), as vozes no terminal, as notas e a HUD.
## Rode a cena (F6) ou headless; sai com código 1 se algo falhar.

const CenaFase5 := preload("res://fases/fase_5/fase_5.tscn")

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


func _a(args: Array) -> Array[String]:
	var r: Array[String] = []
	r.assign(args)
	return r


func _ready() -> void:
	var persistia: bool = Diario.persistir
	var diario_antes: Dictionary = Diario.estado()
	Diario.persistir = false
	await _testar()
	Diario.restaurar(diario_antes)
	Diario.persistir = persistia
	GameState.resetar_repositorio()
	print("[TESTE FASE 5 HISTÓRIA] %d verificações, %d falhas" % [_total, _falhas])
	get_tree().quit(1 if _falhas > 0 else 0)


func _abrir_fase() -> Node:
	GameState.resetar_repositorio()
	var fase := CenaFase5.instantiate()
	add_child(fase)
	return fase


func _jogar_ate_o_conflito(modelo: ModeloConflito, lado: String) -> void:
	modelo.texto_status()
	modelo.mesclar(_a(["ajuste"]))
	modelo.texto_diff(_a([]))
	modelo.escolher(lado)
	modelo.adicionar(_a(["selo.runa"]))


func _testar() -> void:
	_log("— Cena e HUD —")
	var fase := _abrir_fase()
	await _frames(5)
	var m: ModeloConflito = fase.modelo
	_ok(fase.get_node_or_null("PainelObjetivos") == null, "sem painel de objetivos (HUD igual à das outras fases)")
	_ok(fase.get_node_or_null("NotaPlaca") != null and fase.get_node_or_null("NotaCarta") != null and fase.get_node_or_null("NotaAta") != null, "as 3 notas estão na cena")
	for id in [&"f5_placa_selo", &"f5_carta_ler_as_duas", &"f5_ata_unificacao"]:
		_ok(not NotasHistoria.obter(id).is_empty(), "a nota %s está no catálogo" % id)
	_ok(not fase.caixa_dialogo.visible, "o diálogo do abalo começa fechado")

	_log("— Roteiro —")
	for lado in ["minha", "deles", "ambas"]:
		_ok(RoteiroConflito.REACOES.has(lado) and RoteiroConflito.REACOES[lado].size() == 2, "reação para a escolha '%s'" % lado)
	_ok(RoteiroConflito.ABALO[-1] == "IA: Bora seguir, Walker." and RoteiroConflito.ABALO[0].begins_with("Eidolon: Eu disse que uma"), "o abalo começa e termina como no roteiro")

	_log("— Abalo do Eidolon e escolha guardada (terminal fechado) —")
	_ok(GameState.escolha_historia(GameState.ESCOLHA_CONFLITO) == "", "antes de resolver, não há escolha guardada")
	_jogar_ate_o_conflito(m, "ambas")
	m.commitar(_a(["-m", "resolve o selo"]))
	await _frames()
	_ok(GameState.escolha_historia(GameState.ESCOLHA_CONFLITO) == "ambas", "a escolha 'ambas' ficou guardada")
	_ok(fase.caixa_dialogo.visible, "o diálogo do abalo abriu")
	_ok(m.abalo_dito(), "o abalo foi marcado como dito")
	fase.caixa_dialogo.finalizar()
	await _frames()
	_ok(not get_tree().paused, "ao terminar o diálogo o jogo volta ao normal")
	GameState.reset_fase()
	_ok(GameState.escolha_historia(GameState.ESCOLHA_CONFLITO) == "ambas", "a escolha sobrevive à troca de fase (reset_fase)")
	GameState.restaurar_checkpoint()
	_ok(GameState.escolha_historia(GameState.ESCOLHA_CONFLITO) == "", "reiniciar a fase desfaz a escolha")
	GameState.registrar_escolha(GameState.ESCOLHA_CONFLITO, "deles")
	GameState.resetar_repositorio()
	_ok(GameState.escolha_historia(GameState.ESCOLHA_CONFLITO, "nada") == "nada", "jogo novo apaga as escolhas")
	fase.queue_free()
	await _frames()

	_log("— Com o terminal aberto: vozes no terminal e abalo adiado —")
	fase = _abrir_fase()
	await _frames(5)
	m = fase.modelo
	GameState.terminal_aberto.emit()
	await _frames()
	m.texto_status()
	m.mesclar(_a(["ajuste"]))
	m.texto_diff(_a([]))
	m.escolher("minha")
	await _frames(3)
	var terminal := get_tree().get_first_node_in_group("terminal_ui")
	var texto: String = terminal.historico.get_parsed_text()
	_ok(texto.contains("EIDOLON"), "a voz do Eidolon aparece no terminal")
	_ok(texto.contains("Correto. A sua linha prevalece"), "reação do Eidolon à escolha 'minha'")
	_ok(texto.contains("já vi isso"), "a IA paralisa diante do conflito")
	m.adicionar(_a(["selo.runa"]))
	m.commitar(_a(["-m", "fecha"]))
	await _frames()
	_ok(not fase.caixa_dialogo.visible, "com o terminal aberto o abalo espera")
	GameState.terminal_fechado.emit()
	await _frames(3)
	_ok(fase.caixa_dialogo.visible, "ao fechar o terminal o abalo aparece")
	_ok(GameState.escolha_historia(GameState.ESCOLHA_CONFLITO) == "minha", "a escolha 'minha' ficou guardada")
	fase.caixa_dialogo.finalizar()
	get_tree().paused = false
	fase.queue_free()
	await _frames()

	_log("— A parede cai conforme a escolha —")
	fase = _abrir_fase()
	await _frames(5)
	m = fase.modelo
	_jogar_ate_o_conflito(m, "ambas")
	m.commitar(_a(["-m", "x"]))
	await _frames()
	fase.caixa_dialogo.finalizar()
	await get_tree().create_timer(0.5).timeout
	_ok(fase.rachaduras.visible, "'ambas': as rachaduras de luz verde-água aparecem")
	_ok(not fase.parede.aberta, "'ambas': a parede ainda está de pé enquanto racha")
	await get_tree().create_timer(3.2).timeout
	_ok(fase.parede.aberta, "'ambas': depois de rachar, a parede cai")
	fase.queue_free()
	await _frames()
	fase = _abrir_fase()
	await _frames(5)
	m = fase.modelo
	_jogar_ate_o_conflito(m, "minha")
	m.commitar(_a(["-m", "x"]))
	await _frames()
	fase.caixa_dialogo.finalizar()
	await get_tree().create_timer(0.9).timeout
	_ok(fase.parede.aberta and not fase.rachaduras.visible, "'minha': a parede treme e cai, sem rachaduras")
	fase.queue_free()
	await _frames()


func _log(linha: String) -> void:
	print(linha)
