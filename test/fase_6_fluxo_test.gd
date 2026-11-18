extends Node
## Teste da Fase 6 ("Ponto de Retorno"): joga a fase inteira pelo INTERPRETADOR do terminal (o
## caminho real do jogador), com os erros típicos no meio: revert do commit errado, reset --hard
## que destrói a planta, reset --soft no lugar do --hard. Rode a cena (F6) e leia o Output; o
## resultado também vai para %TEMP%/fase6_fluxo_teste.txt. Sai com código 1 se algo falhar.

const ARQUIVO_SAIDA := "fase6_fluxo_teste.txt"

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


func _ready() -> void:
	var pasta := OS.get_environment("TEMP") if OS.get_environment("TEMP") != "" else "/tmp"
	_saida = FileAccess.open(pasta.path_join(ARQUIVO_SAIDA), FileAccess.WRITE)
	await _jornada_completa()
	await _caminho_direto()
	_log("[TESTE FASE 6] %d verificações, %d falhas" % [_total, _falhas])
	GameState.resetar_repositorio()
	get_tree().quit(1 if _falhas > 0 else 0)


func _frames() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _novo_terminal() -> TerminalCommandInterpreter:
	var terminal := TerminalCommandInterpreter.new()
	add_child(terminal)
	terminal.configurar_comandos(["help", "status", "log", "add", "commit", "revert", "stash", "reset"])
	return terminal


func _jornada_completa() -> void:
	_log("== Jornada completa, com erros pelo caminho ==")
	GameState.resetar_repositorio()
	var fase := (load("res://fases/fase_6/fase_6.tscn") as PackedScene).instantiate()
	add_child(fase)
	await _frames()
	var terminal := _novo_terminal()
	var inspecao: PortaMural = fase.get_node("Portas/PortaInspecao")
	var camara: PortaMural = fase.get_node("Portas/PortaCamara")
	var portal: ExitArea = fase.get_node("PortalSaida")

	# --- montagem
	_ok(EstadoRetorno.construido() and GameState.commits.size() == 3, "a fase monta o histórico inicial (3 commits)")
	_ok(not EstadoRetorno.ponte_solida() and EstadoRetorno.etapa() == "log", "a ponte começa sabotada; primeira etapa é ler o histórico")
	_ok("ainda não foi apresentado" in terminal.execute_command("git stash"), "stash bloqueado antes da hora")
	_ok("ainda não foi apresentado" in terminal.execute_command("git reset --hard HEAD~1"), "reset bloqueado antes da hora")

	# --- Área 1: revert
	_ok("Tábuas" in terminal.execute_command("git log"), "git log mostra o commit ruim")
	await _frames()
	_ok(EstadoRetorno.flag("log_visto") and EstadoRetorno.etapa() == "revert", "ler o log libera a etapa do revert")
	terminal.execute_command("git revert HEAD~1")
	await _frames()
	_ok(not EstadoRetorno.versionado("reforco.map") and EstadoRetorno.etapa() == "desfazer_revert", "reverter o commit errado tira o reforço e a IA manda desfazer")
	terminal.execute_command("git revert HEAD")
	await _frames()
	_ok(EstadoRetorno.versionado("reforco.map") and EstadoRetorno.etapa() == "revert", "desfazer o revert devolve o reforço")
	_ok(GameState.historico().size() == 5, "nenhum commit foi apagado (5 no histórico)")
	terminal.execute_command("git revert HEAD~2")
	await _frames()
	_ok(EstadoRetorno.flag("z1_ok") and EstadoRetorno.ponte_solida(), "reverter o commit ruim (HEAD~2) conserta a ponte")
	_ok("lanterna.map" in GameState.staging_area and EstadoRetorno.flag("wip_dado"), "o jogador chega à Área 2 com a lanterna (trabalho pela metade) na caixa")
	_ok(not inspecao.aberta, "o portão de inspeção está fechado (pasta suja)")

	# --- Área 2: stash
	_ok("stash" in GameState.comandos_liberados and "reset" not in GameState.comandos_liberados, "a IA libera o stash e ainda não o reset")
	_ok("Nada para guardar" not in terminal.execute_command("git stash"), "git stash guarda o trabalho")
	await _frames()
	_ok(GameState.staging_area.is_empty() and GameState.stash_pilha.size() == 1, "a caixa fica limpa e o stash guarda 1 item")
	_ok(EstadoRetorno.flag("inspecao_ok") and inspecao.aberta, "pasta limpa: o portão de inspeção abre")
	_ok(EstadoRetorno.etapa() == "alavanca", "próxima etapa: alavanca")
	EstadoRetorno.marcar("emergencia")
	fase.notificar()
	await _frames()
	_ok(EstadoRetorno.etapa() == "pop", "alavanca puxada: falta recuperar o trabalho")
	terminal.execute_command("git stash pop")
	await _frames()
	_ok(EstadoRetorno.flag("z2_ok") and "lanterna.map" in GameState.staging_area, "stash pop devolve a lanterna e conclui a Área 2")
	_ok(camara.aberta, "o portão da Câmara do Reset abre")
	_ok(EstadoRetorno.flag("z3a_setup") and GameState.historico()[0]["mensagem"] == "Planta apressada", "a Câmara monta o commit apressado da planta")
	_ok(EstadoRetorno.etapa() == "soft", "etapa: reset --soft")

	# --- Área 3: reset (erro primeiro: --hard destrói a planta)
	terminal.execute_command("git reset --hard HEAD~1")
	await _frames()
	_ok(not EstadoRetorno.existe("planta.map") and EstadoRetorno.etapa() == "restaurar", "reset --hard destrói a planta e a câmara fica sem saída")
	_ok(EstadoRetorno.restaurar_camara(), "o Altar de Retorno restaura a câmara")
	await _frames()
	_ok(EstadoRetorno.etapa() == "soft" and EstadoRetorno.versionado("planta.map"), "a câmara volta ao começo")

	terminal.execute_command("git reset --soft HEAD~1")
	await _frames()
	_ok(EstadoRetorno.flag("soft_ok") and EstadoRetorno.na_caixa("planta.map"), "reset --soft volta o commit e mantém a planta na caixa")
	_ok(EstadoRetorno.etapa() == "commit" and "commit" in GameState.comandos_liberados, "etapa: recommit (comando liberado)")
	terminal.execute_command("git commit -m \"planta\"")
	await _frames()
	_ok(EstadoRetorno.flag("commit_ok") and EstadoRetorno.versionado("planta.map"), "a planta é registrada direito")
	_ok(EstadoRetorno.flag("z3b_setup") and GameState.historico()[0]["mensagem"] == "Experimento arriscado", "aparece o commit do experimento")
	_ok(EstadoRetorno.etapa() == "hard", "etapa: reset --hard")

	# --- erro: --soft no lugar do --hard
	terminal.execute_command("git reset --soft HEAD~1")
	await _frames()
	_ok(EstadoRetorno.na_caixa("experimento.map") and EstadoRetorno.etapa() == "restaurar", "reset --soft não destrói o experimento: a câmara pede restauração")
	_ok(EstadoRetorno.restaurar_camara(), "o altar restaura de novo")
	await _frames()
	_ok(EstadoRetorno.etapa() == "hard", "de volta à etapa do --hard")
	_ok(portal.locked, "o portal ainda está bloqueado")

	terminal.execute_command("git reset --hard HEAD~1")
	await _frames()
	_ok(EstadoRetorno.flag("hard_ok") and not EstadoRetorno.existe("experimento.map"), "reset --hard destrói o experimento")
	_ok(EstadoRetorno.versionado("planta.map"), "a planta continua no histórico")
	_ok(not portal.locked and EstadoRetorno.etapa() == "concluido", "o portal abre e a fase conclui")
	var fantasma: Dictionary = GameState.commits.back()
	_ok(fantasma.get("misterio", false) and GameState.obter_head() != fantasma["id"], "o gancho aberto: um commit fantasma ilegível que o jogador não criou")
	_ok(GameState.historico().filter(func(c): return c["id"] == fantasma["id"]).is_empty(), "o fantasma não faz parte do histórico (nenhuma branch o alcança)")

	fase.queue_free()
	terminal.queue_free()
	await _frames()


func _caminho_direto() -> void:
	_log("== Caminho direto: revert certo de primeira ==")
	GameState.resetar_repositorio()
	var fase := (load("res://fases/fase_6/fase_6.tscn") as PackedScene).instantiate()
	add_child(fase)
	await _frames()
	var terminal := _novo_terminal()
	terminal.execute_command("git log")
	terminal.execute_command("git revert HEAD")
	await _frames()
	_ok(EstadoRetorno.flag("z1_ok") and EstadoRetorno.etapa() == "stash", "revert do HEAD conserta a ponte direto")
	_ok(GameState.commits.back()["mensagem"].begins_with("Revert"), "o revert criou um commit novo")
	_ok(not terminal.execute_command("git revert nao_existe").is_empty() and EstadoRetorno.flag("z1_ok"), "revert de commit inexistente não quebra nada")
	_ok(not GameState.progresso_tutoria.is_empty(), "o progresso fica em progresso_tutoria")

	# recarregar a cena (derrota) não refaz a montagem nem perde o progresso
	var antes := GameState.commits.size()
	fase.queue_free()
	await _frames()
	var fase_b := (load("res://fases/fase_6/fase_6.tscn") as PackedScene).instantiate()
	add_child(fase_b)
	await _frames()
	_ok(GameState.commits.size() == antes and EstadoRetorno.flag("z1_ok"), "recarregar a cena preserva o repositório e o progresso")
	fase_b.queue_free()
	terminal.queue_free()
