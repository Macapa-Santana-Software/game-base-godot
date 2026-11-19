extends Node
## Teste da história da Fase 6 (Ponto de Retorno): a escolha da Fase 5 atravessa a montagem da fase, o commit
## fantasma aparece (órfão, com autor codificado) no `git log`, a poeira, o Eidolon (eco que foge e fala no fim),
## as notas, a HUD e a mensagem final sem promessa. Sai com código 1 se algo falhar.

const CenaFase6 := preload("res://fases/fase_6/fase_6.tscn")

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
	var persistia: bool = Diario.persistir
	var diario_antes: Dictionary = Diario.estado()
	Diario.persistir = false
	await _testar()
	Diario.restaurar(diario_antes)
	Diario.persistir = persistia
	GameState.resetar_repositorio()
	print("[TESTE FASE 6 HISTÓRIA] %d verificações, %d falhas" % [_total, _falhas])
	get_tree().quit(1 if _falhas > 0 else 0)


func _novo_terminal() -> TerminalCommandInterpreter:
	var terminal := TerminalCommandInterpreter.new()
	add_child(terminal)
	terminal.configurar_comandos(["help", "status", "log", "add", "commit", "revert", "stash", "reset"])
	return terminal


func _testar() -> void:
	print("— Escolha da Fase 5 e HUD —")
	GameState.resetar_repositorio()
	GameState.registrar_escolha(GameState.ESCOLHA_CONFLITO, "ambas")
	var fase := CenaFase6.instantiate()
	add_child(fase)
	await _frames(5)
	_ok(GameState.escolha_historia(GameState.ESCOLHA_CONFLITO) == "ambas", "a escolha da Fase 5 sobrevive à montagem da Fase 6")
	_ok(fase.get_node_or_null("PainelObjetivos") == null, "sem painel de objetivos (HUD igual à das outras fases)")
	var tutora: TutoraRetorno
	for filho in fase.get_children():
		if filho is TutoraRetorno:
			tutora = filho
	_ok(tutora != null and tutora._lembrar_escolha().contains("juntou as duas"), "a IA lembra a escolha 'ambas'")
	GameState.registrar_escolha(GameState.ESCOLHA_CONFLITO, "minha")
	_ok(tutora._lembrar_escolha().contains("sua versão"), "a IA lembra a escolha 'minha'")
	GameState.registrar_escolha(GameState.ESCOLHA_CONFLITO, "ambas")

	print("— Cena, notas e Eidolon —")
	for id in [&"f6_placa_estacao", &"f6_carta_revert", &"f6_ata_purga"]:
		_ok(not NotasHistoria.obter(id).is_empty(), "a nota %s está no catálogo" % id)
	_ok(fase.get_node_or_null("NotaPlaca") != null and fase.get_node_or_null("NotaCarta") != null and fase.get_node_or_null("NotaAta") != null, "as 3 notas estão na cena")
	_ok(fase.eco != null and fase.eco.pontos.size() >= 3, "o eco do Eidolon está no corredor")
	_ok(not fase.caixa_dialogo.visible, "o diálogo do Eidolon começa fechado")
	# O eco foge do jogador
	var jogador := PlayerManager.player
	var fugiu: Array = [false]
	fase.eco.fugiu.connect(func() -> void: fugiu[0] = true)
	var antes: Vector2 = fase.eco.global_position
	jogador.global_position = antes + Vector2(10, 0)
	await get_tree().create_timer(1.6).timeout
	_ok(fugiu[0] and fase.eco.global_position.distance_to(antes) > 20.0, "o eco foge quando o jogador chega perto")
	jogador.global_position = Vector2(40, 128)

	print("— Jornada até o reset --hard —")
	var terminal := _novo_terminal()
	terminal.execute_command("git log")
	terminal.execute_command("git revert HEAD")
	await _frames()
	terminal.execute_command("git revert HEAD~1")
	await _frames()
	_ok(EstadoRetorno.flag("z1_ok"), "ponte consertada com o revert")
	terminal.execute_command("git stash")
	await _frames()
	EstadoRetorno.marcar("emergencia")
	fase.notificar()
	terminal.execute_command("git stash pop")
	await _frames()
	terminal.execute_command("git reset --soft HEAD~1")
	await _frames()
	terminal.execute_command("git commit -m \"planta\"")
	await _frames()
	var experimento: ObjetoRetorno = fase.get_node("Experimento")
	_ok(EstadoRetorno.flag("z3b_setup") and experimento._estado() == "historico", "o experimento aparece no histórico")
	terminal.execute_command("git reset --hard HEAD~1")
	await _frames(3)
	_ok(experimento._estado() == "destruido", "o reset --hard destrói o experimento")
	var poeira: CPUParticles2D = experimento._poeira
	_ok(poeira != null and poeira.emitting, "o experimento vira poeira")

	print("— Commit fantasma no git log —")
	var saida := terminal.execute_command("git log")
	_ok(saida.contains("órfão") and saida.contains("RS4="), "o git log mostra o commit órfão com o autor codificado (E.)")
	_ok(Marshalls.base64_to_utf8("RS4=") == "E.", "o autor decodifica para 'E.'")
	_ok(saida.contains("Estrutura da ponte"), "o histórico normal continua no log")
	var oneline := terminal.execute_command("git log --oneline")
	_ok(oneline.contains("órfão"), "o log resumido também mostra o órfão")

	print("— Fala final do Eidolon —")
	_ok(fase.caixa_dialogo.visible, "o Eidolon diz a sua frase quando o terminal está fechado")
	_ok(fase.eco.visible, "o eco aparece para vê-lo")
	fase.caixa_dialogo.finalizar()
	await get_tree().create_timer(2.0).timeout
	_ok(not fase.eco.visible, "depois da frase, o Eidolon some")
	_ok(not get_tree().paused, "o jogo volta ao normal")

	fase.queue_free()
	terminal.queue_free()
	await _frames()

	print("— Mensagem final sem promessa —")
	_ok(VictoryScreenMensagem.sem_promessa(), "a tela final não promete continuação")


class VictoryScreenMensagem:
	static func sem_promessa() -> bool:
		var vitoria := preload("res://GeneralNodes/VictoryScreen/victory_screen.gd")
		return vitoria.MENSAGEM_FIM.contains("Nenhuma branch") and not vitoria.MENSAGEM_FIM.to_lower().contains("obrigado") and vitoria.TITULO_FIM == "PONTO DE RETORNO"
