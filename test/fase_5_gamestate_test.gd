extends Node
## Teste da Fase 5 e das novas capacidades do GameState (reflog, reset, revert, cherry-pick,
## stash, conteúdos). Rode a cena (F6) e leia o Output. O resultado também vai para
## %TEMP%/fase5_gamestate_teste.txt. Sai com código 1 se alguma verificação falhar.
##
## Parte 1: GameState puro (sem cena).
## Parte 2: a Fase 5 inteira, pelo INTERPRETADOR do terminal (o caminho real do jogador).

const ARQUIVO_SAIDA := "fase5_gamestate_teste.txt"

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

	_log("== Parte 1: GameState ==")
	_testar_gamestate()
	_log("== Parte 2: Fase 5 pelo terminal ==")
	await _testar_fase_5()

	_log("[TESTE FASE 5 + GAMESTATE] %d verificações, %d falhas" % [_total, _falhas])
	GameState.resetar_repositorio()
	get_tree().quit(1 if _falhas > 0 else 0)


# ---------------------------------------------------------------------------
# Parte 1
# ---------------------------------------------------------------------------

func _commitar(arquivo: String, mensagem: String, conteudos: Dictionary = {}) -> String:
	GameState.coletar_arquivo_no_mapa(arquivo)
	GameState.sincronizar_inventario_com_git()
	GameState.adicionar_ao_stage(arquivo)
	GameState.criar_commit(mensagem, conteudos)
	return GameState.obter_head()


func _testar_gamestate() -> void:
	GameState.resetar_repositorio()
	GameState.inicializar_repositorio()
	var c1 := _commitar("a", "primeiro")
	var c2 := _commitar("b", "segundo")
	var c3 := _commitar("c", "terceiro", {"c": "cor: azul"})

	_ok(GameState.historico().size() == 3, "3 commits no histórico")
	_ok(GameState.reflog.size() == 3 and GameState.reflog[2]["acao"] == "commit", "o reflog registra cada commit")
	_ok(GameState.conteudo_em("c") == "cor: azul" and GameState.conteudo_em("a") == "", "conteudo_em lê o texto guardado no commit")
	_ok(GameState.resolver_referencia("HEAD~1") == c2 and GameState.resolver_referencia("HEAD^") == c2, "HEAD~1 e HEAD^ apontam para o commit anterior")
	_ok(GameState.resolver_referencia("HEAD~9") == "" and GameState.resolver_referencia("zzz") == "", "referência inexistente devolve vazio")
	_ok(GameState.resolver_referencia("main") == c3 and GameState.resolver_referencia(c1) == c1, "branch e id resolvem")

	# revert: commit novo que desfaz, história preservada
	var r := GameState.reverter(c3)
	_ok(r["ok"], "revert do último commit funciona")
	_ok(GameState.historico().size() == 4, "revert ADICIONA um commit (a história não é apagada)")
	_ok(not GameState.esta_versionado("c") and GameState.esta_versionado("b"), "revert tira só o arquivo do commit desfeito")
	_ok(GameState.reflog.back()["acao"] == "revert", "o reflog registra o revert")
	_ok(not GameState.reverter("nao_existe")["ok"], "revert de commit inexistente falha")

	# reset: volta o ponteiro; --hard destrói arquivos; o reflog permite recuperar
	var cabeca_revert := GameState.obter_head()
	_ok(GameState.resetar_para(c3, "hard")["ok"] and GameState.esta_versionado("c"), "reset --hard para antes do revert devolve o arquivo")
	_ok(not GameState.resetar_para(c3, "xyz")["ok"], "modo de reset inválido falha")
	_ok(GameState.resetar_para(c1, "soft")["ok"], "reset --soft move o HEAD")
	_ok(GameState.obter_head() == c1 and "b" in GameState.staging_area and "c" in GameState.staging_area, "soft deixa os arquivos descartados na staging")
	_ok(GameState.resetar_para(c1, "mixed")["ok"] and GameState.staging_area.is_empty(), "mixed esvazia a staging")
	_ok("b" in GameState.working_directory and "c" in GameState.working_directory, "mixed devolve os arquivos como não rastreados")
	GameState.resetar_para(c3, "hard")  # volta a frente para o hard ter o que descartar
	_ok(GameState.resetar_para(c1, "hard")["ok"] and "b" not in GameState.inventario_player, "hard destrói os arquivos dos commits descartados")
	_ok(GameState.obter_commit(c3).size() > 0, "os commits descartados continuam no object store")
	_ok(GameState.resetar_para(cabeca_revert, "hard")["ok"] and GameState.obter_head() == cabeca_revert, "dá para voltar a um commit 'perdido' (é o que o reflog mostra)")
	_ok(GameState.formatar_reflog()["ok"] and GameState.reflog.back()["acao"] == "reset", "reflog lista os resets")

	# cherry-pick
	GameState.resetar_para(c1, "hard")
	GameState.criar_branch("alt")
	GameState.trocar_branch("alt")
	var c4 := _commitar("d", "so na alt")
	GameState.trocar_branch("main")
	_ok(not GameState.esta_versionado("d"), "o arquivo da alt não existe na main")
	var cp := GameState.escolher_commit(c4)
	_ok(cp["ok"] and GameState.esta_versionado("d"), "cherry-pick copia o commit para a branch ativa")
	_ok(GameState.historico().size() == 2 and GameState.historico()[0]["mensagem"] == "so na alt", "a cópia mantém a mensagem")
	_ok(not GameState.escolher_commit("nao_existe")["ok"], "cherry-pick de commit inexistente falha")

	# stash
	GameState.coletar_arquivo_no_mapa("e")
	GameState.sincronizar_inventario_com_git()
	_ok(GameState.guardar_stash("wip")["ok"] and "e" not in GameState.inventario_player, "stash guarda e limpa a pasta")
	_ok(GameState.stash_pilha.size() == 1, "o stash entra na pilha")
	_ok(GameState.aplicar_stash()["ok"] and "e" in GameState.inventario_player and GameState.stash_pilha.is_empty(), "stash pop devolve o trabalho")
	_ok(not GameState.aplicar_stash()["ok"], "stash pop vazio falha")

	GameState.resetar_repositorio()
	_ok(GameState.reflog.is_empty() and GameState.stash_pilha.is_empty(), "resetar_repositorio limpa reflog e stash")


# ---------------------------------------------------------------------------
# Parte 2
# ---------------------------------------------------------------------------

func _testar_fase_5() -> void:
	GameState.resetar_repositorio()
	var fase := (load("res://fases/fase_5/fase_5.tscn") as PackedScene).instantiate()
	add_child(fase)
	await get_tree().process_frame
	await get_tree().process_frame

	var modelo: ModeloConflito = fase.get_node("ModeloConflito")
	var parede: PortaMural = fase.get_node("ParedeGlitch")
	var portal: ExitArea = fase.get_node("PortalSaida")
	var terminal := TerminalCommandInterpreter.new()
	add_child(terminal)
	terminal.configurar_comandos(["help", "status", "diff", "merge", "add", "commit"])

	_ok(modelo.estado() == ModeloConflito.PRE, "começa sem merge")
	_ok(GameState.liberacao_progressiva and "merge" in GameState.comandos_liberados, "a IA libera status e merge no início")
	_ok(parede.aberta == false and portal.locked, "a parede está fechada e o portal bloqueado")

	_ok("ainda não foi apresentado" in terminal.execute_command("git diff"), "diff bloqueado antes do conflito")
	_ok("working tree limpa" in terminal.execute_command("git status") and modelo.flag("status_visto"), "status limpo registra a consulta")
	_ok("não é algo" in terminal.execute_command("git merge xyz") and modelo.estado() == ModeloConflito.PRE, "merge de branch errada falha sem mudar nada")
	_ok(not terminal.execute_command("git merge --abort").is_empty() and modelo.estado() == ModeloConflito.PRE, "abort sem merge em andamento é recusado")

	var saida_merge := terminal.execute_command("git merge ajuste")
	_ok("CONFLICT" in saida_merge and "porta.runa" in saida_merge, "merge para com CONFLICT e mescla porta.runa sozinho")
	_ok(modelo.estado() == ModeloConflito.CONFLITO, "estado: conflito")
	_ok("no meio de um merge" in terminal.execute_command("git merge ajuste"), "merge repetido durante o conflito é recusado")
	_ok("unmerged" in terminal.execute_command("git status"), "status mostra os caminhos não mesclados")
	_ok("ainda não foi apresentado" in terminal.execute_command("git add selo.runa"), "add ainda bloqueado antes de escolher o lado")

	var saida_diff := terminal.execute_command("git diff")
	_ok("<<<<<<<" in saida_diff and "=======" in saida_diff and ">>>>>>>" in saida_diff, "diff mostra os marcadores")
	_ok(modelo.flag("diff_conflito"), "diff registrado")

	_ok("Merge abortado" in terminal.execute_command("git merge --abort") and modelo.estado() == ModeloConflito.PRE, "merge --abort volta ao início")
	terminal.execute_command("git merge ajuste")
	_ok(modelo.estado() == ModeloConflito.CONFLITO, "dá para tentar de novo depois do abort")

	modelo.escolher(ModeloConflito.LADO_AMBAS)
	await get_tree().process_frame
	_ok(modelo.estado() == ModeloConflito.RESOLVIDO, "escolher um pedestal resolve na pasta")
	_ok("ainda não sabe" in terminal.execute_command("git status"), "o status avisa que falta o git add")
	_ok("dourado + azul" in terminal.execute_command("git diff"), "o diff mostra o resultado escolhido")
	_ok("ainda não foi apresentado" in terminal.execute_command("git commit -m x"), "commit bloqueado antes do add")

	_ok("resolvido" in terminal.execute_command("git add selo.runa") or modelo.estado() == ModeloConflito.PREPARADO, "add marca o conflito como resolvido")
	_ok(modelo.estado() == ModeloConflito.PREPARADO, "estado: preparado")
	_ok("ainda tem marcadores" not in terminal.execute_command("git add selo.runa"), "segundo add não reclama de marcadores")
	_ok(not parede.aberta, "a parede só cai depois do commit")

	var saida_commit := terminal.execute_command("git commit -m \"junta as duas linhas\"")
	await get_tree().process_frame
	await get_tree().process_frame
	_ok("concluído" in saida_commit and modelo.estado() == ModeloConflito.CONCLUIDO, "commit fecha o merge")
	_ok(GameState.commits.size() > 0 and GameState.commits.back()["mensagem"] == "junta as duas linhas", "o commit real foi registrado no GameState")
	_ok(GameState.conteudo_em("selo.runa") == "cor: dourado + azul", "o conteúdo resolvido fica no commit (conteudo_em)")
	_ok(parede.aberta and not portal.locked, "a parede cai e o portal abre")
	_ok("Already up to date" in terminal.execute_command("git merge ajuste"), "merge depois de concluído: já está integrado")

	# caminho curto: --abort depois de preparado volta ao início
	GameState.resetar_repositorio()
	fase.queue_free()
	await get_tree().process_frame
	var fase_b := (load("res://fases/fase_5/fase_5.tscn") as PackedScene).instantiate()
	add_child(fase_b)
	await get_tree().process_frame
	await get_tree().process_frame
	var m2: ModeloConflito = fase_b.get_node("ModeloConflito")
	terminal.execute_command("git merge ajuste")
	m2.escolher(ModeloConflito.LADO_MINHA)
	terminal.execute_command("git add selo.runa")
	_ok(m2.estado() == ModeloConflito.PREPARADO, "(2) preparado com a versão da main")
	terminal.execute_command("git merge --abort")
	_ok(m2.estado() == ModeloConflito.PRE and m2.escolha() == "", "(2) abort depois do add volta ao início e limpa a escolha")
