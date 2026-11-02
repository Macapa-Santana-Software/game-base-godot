extends Node
## Teste manual dos sinais semânticos do GameState (Etapa 1 da tutora).
## Rode a cena (F6) e veja o Output. Ao final, o GameState é zerado.

var _init_count: int = 0
var _status_count: int = 0
var _ultimo_status: Array = []
var _prep_count: int = 0
var _ultimo_prep: Array = []
var _commit_count: int = 0
var _falhas: Array[String] = []
var _failures: int = 0

func _ready() -> void:
	GameState.reset_fase()
	GameState.repositorio_inicializado.connect(func() -> void: _init_count += 1)
	GameState.status_consultado.connect(func(staging: bool, solto: bool) -> void:
		_status_count += 1
		_ultimo_status = [staging, solto])
	GameState.arquivos_preparados.connect(func(nomes: Array[String]) -> void:
		_prep_count += 1
		_ultimo_prep = nomes.duplicate())
	GameState.commit_realizado.connect(func(_info: Dictionary) -> void: _commit_count += 1)
	GameState.comando_falhou.connect(func(_cmd: String, motivo: String) -> void: _falhas.append(motivo))

	GameState.coletar_arquivo_no_mapa("a.gd")
	GameState.coletar_arquivo_no_mapa("b.gd")
	GameState.sincronizar_inventario_com_git()

	# --- Sem repositório: nenhum sinal ---
	GameState.obter_status()
	GameState.adicionar_ao_stage("a.gd")
	GameState.adicionar_todos_ao_stage()
	GameState.criar_commit("x")
	_check("sem init: status não emite", _status_count == 0)
	_check("sem init: add não emite", _prep_count == 0)
	_check("sem init: commit não emite", _commit_count == 0)

	# --- init ---
	GameState.inicializar_repositorio()
	_check("init emite 1 vez", _init_count == 1)
	GameState.inicializar_repositorio()
	_check("init repetido não emite", _init_count == 1)

	# --- status com arquivos soltos ---
	GameState.obter_status()
	_check("status emite", _status_count == 1)
	_check("status: sem staging, com não rastreados", _ultimo_status == [false, true])

	# --- add ---
	GameState.adicionar_ao_stage("nao_existe.gd")
	_check("add de arquivo inexistente não emite", _prep_count == 0)
	GameState.adicionar_ao_stage("a.gd")
	_check("add emite 1 vez", _prep_count == 1)
	_check("add informa os nomes", _mesmos_itens(_ultimo_prep, ["a.gd"]))
	GameState.adicionar_ao_stage("a.gd")
	_check("add repetido não emite", _prep_count == 1)

	GameState.obter_status()
	_check("status: com staging e com não rastreados", _ultimo_status == [true, true])

	GameState.adicionar_todos_ao_stage()
	_check("add . emite", _prep_count == 2)
	_check("add . informa só o que faltava", _mesmos_itens(_ultimo_prep, ["b.gd"]))
	GameState.adicionar_todos_ao_stage()
	_check("add . sem nada novo não emite", _prep_count == 2)

	# --- commit ---
	GameState.criar_commit("primeiro")
	_check("commit emite 1 vez", _commit_count == 1)
	GameState.obter_status()
	_check("status pós-commit: limpo", _ultimo_status == [false, false])

	# --- comando_falhou ---
	_check("falha: sem repositório foi sinalizada", GameState.FALHA_SEM_REPOSITORIO in _falhas)
	_check("falha: arquivo inexistente foi sinalizada", GameState.FALHA_ARQUIVO_INEXISTENTE in _falhas)
	_check("falha: já na staging foi sinalizada", GameState.FALHA_JA_NA_STAGING in _falhas)
	_check("falha: nada para adicionar foi sinalizada", GameState.FALHA_NADA_PARA_ADICIONAR in _falhas)
	var antes := _falhas.size()
	GameState.adicionar_ao_stage("a.gd")
	_check("falha: já versionado foi sinalizada", _falhas.size() == antes + 1 and _falhas[-1] == GameState.FALHA_JA_VERSIONADO)
	GameState.criar_commit("sem nada na caixa")
	_check("falha: staging vazia foi sinalizada", _falhas[-1] == GameState.FALHA_STAGING_VAZIA)

	# --- arquivos_pendentes (condição de saída da fase) ---
	_check("pendentes: tudo commitado", GameState.arquivos_pendentes(["a.gd", "b.gd"]).is_empty())
	_check("pendentes: aponta o que falta", _mesmos_itens(GameState.arquivos_pendentes(["a.gd", "c.gd"]), ["c.gd"]))

	# --- liberação progressiva de comandos ---
	_check("sem liberação progressiva: tudo liberado", GameState.comando_liberado("commit"))
	GameState.liberacao_progressiva = true
	GameState.comandos_liberados = ["init"]
	_check("progressiva: init liberado", GameState.comando_liberado("init"))
	_check("progressiva: commit bloqueado", not GameState.comando_liberado("commit"))
	_check("progressiva: help sempre liberado", GameState.comando_liberado("help"))

	# --- progresso_tutoria ---
	_check("progresso começa sem dicas", GameState.progresso_tutoria["dicas_usadas"] == 0)
	_check("progresso começa no nível completo", GameState.progresso_tutoria["nivel_explicacao"] == "completo")
	GameState.progresso_tutoria["dicas_usadas"] = 3
	GameState.progresso_tutoria["explicados"]["init"] = true
	GameState.reset_fase()
	_check("reset zera dicas", GameState.progresso_tutoria["dicas_usadas"] == 0)
	_check("reset zera explicados", GameState.progresso_tutoria["explicados"].is_empty())
	_check("constante inicial não foi alterada", GameState.PROGRESSO_INICIAL["explicados"].is_empty())
	_check("reset desliga a liberação progressiva", not GameState.liberacao_progressiva and GameState.comandos_liberados.is_empty())
	_check("progresso começa sem erros consecutivos", GameState.progresso_tutoria["erros_consecutivos"] == 0)

	print("RESULTADO: ", "OK" if _failures == 0 else "%d FALHA(S)" % _failures)

func _mesmos_itens(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in range(a.size()):
		if str(a[i]) != str(b[i]):
			return false
	return true

func _check(label: String, condition: bool) -> void:
	if not condition:
		_failures += 1
	print(("[OK]    " if condition else "[FALHOU] ") + label)
