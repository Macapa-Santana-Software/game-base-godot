class_name TutoraMural extends TutoraFase1
## A IA da Fase 3 ("O Mural Corrompido"): mesma tutora da Fase 1 (quadro, balão, falas no
## terminal), com o roteiro de `diff` e `restore`. A etapa vem dos fatos do ModeloMural.
##
## História: os Escribas gravaram o Selo nas runas do Mural. Na noite passada a Corrupção
## passou e trocou a cor de várias runas por "ruído". Uma das mudanças, porém, é BOA: foi o
## próprio jogador que corrigiu a runa do mar. Descartar tudo no escuro apagaria esse trabalho.
##
## Metáfora (a mesma das fases anteriores + uma nova): a OFICINA é onde se mexe nas runas, o
## PALCO (staging area) é onde se separa o que vai para o registro, e o ARQUIVO é o commit.
##
## Etapas: status -> diff -> restore (-> reescrever) -> palco -> tirar_palco -> descartar
##         -> preparar (-> reescrever) -> concluido.

const INTRO := "Os Escribas gravaram o Selo nestas runas. Na noite passada a Corrupção passou e trocou a cor de várias delas por ruído. Vamos ver o que mudou e desfazer o estrago, sem perder o que está certo."

var _modelo: ModeloMural


func _ready() -> void:
	_modelo = ModeloMural.ativo()
	super._ready()
	if _modelo == null:
		return
	_modelo.mudou.connect(_atualizar_quadro)
	_modelo.status_executado.connect(_on_status_mural)
	_modelo.diff_executado.connect(_on_diff_mural)
	_modelo.runa_restaurada.connect(_on_restaurada)
	_modelo.runa_preparada.connect(_on_preparada)
	_modelo.trabalho_descartado.connect(_on_trabalho_descartado)
	_dizer.call_deferred(INTRO + " Abra o terminal no Obelisco (T).")


# ---------------------------------------------------------------------------
# Estado do jogador -> etapa
# ---------------------------------------------------------------------------

func _estado() -> String:
	if _modelo == null:
		return ""
	if _modelo.zona_3_ok():
		return "concluido"
	if not _modelo.flag("status_visto"):
		return "status"
	if not _modelo.flag("diff_visto"):
		return "diff"
	if not _modelo.zona_2_ok():
		return "reescrever" if _modelo.boa_perdida("mar.runa") else "restore"
	if not _modelo.flag("status_palco"):
		return "palco"
	if _modelo.preparada("eclipse.runa"):
		return "tirar_palco"
	if not _modelo.limpa("eclipse.runa"):
		return "descartar"
	return "reescrever" if _modelo.boa_perdida("aurora.runa") else "preparar"


func _sincronizar_comandos() -> void:
	if _modelo == null:
		return
	var liberados: Array[String] = ["status"]
	if _modelo.flag("status_visto"):
		liberados.append("diff")
	if _modelo.flag("diff_visto"):
		liberados.append("restore")
	if _modelo.zona_2_ok():
		liberados.append("add")
	var mudou := not GameState.liberacao_progressiva or liberados != GameState.comandos_liberados
	GameState.liberacao_progressiva = true
	GameState.comandos_liberados = liberados
	if mudou:
		GameState.comandos_atualizados.emit()


# ---------------------------------------------------------------------------
# Roteiro
# ---------------------------------------------------------------------------

func _proximo_passo_terminal(estado: String, _forcar_comando: bool = false) -> String:
	match estado:
		"status":
			return "Primeiro, veja o estrago: digite %s. Ele lista as runas que mudaram." % _cmd("git status")
		"diff":
			return "O status diz QUAIS runas mudaram, não COMO. Para ver a diferença, digite %s." % _cmd("git diff")
		"restore":
			return "Linhas com %s são a versão antiga; com %s, a atual. Quem tem %s é corrupção: descarte com %s. Mas olhe antes: %s tem uma mudança BOA, e ela deve ficar." % [_cmd("-"), _cmd("+"), _cmd("ruído"), _cmd("git restore nome.runa"), _cmd("mar.runa")]
		"reescrever":
			return "Você descartou uma mudança boa (restore não tem volta). Vá ao Altar da Reescrita (ENTER perto dele) para refazer o trabalho."
		"palco":
			return "Passe pela porta aberta até o Palco e veja a situação com %s." % _cmd("git status")
		"tirar_palco":
			return "A %s entrou no Palco por engano (um %s apressado). Tire-a de lá: %s." % [_cmd("eclipse.runa"), _cmd("git add ."), _cmd("git restore --staged eclipse.runa")]
		"descartar":
			return "A %s saiu do Palco, mas a corrupção continua na Oficina. Descarte-a: %s." % [_cmd("eclipse.runa"), _cmd("git restore eclipse.runa")]
		"preparar":
			return "A %s já está limpa. Se você a tirou do Palco sem querer, devolva com %s." % [_cmd("aurora.runa"), _cmd("git add aurora.runa")]
		"concluido":
			return "Mural restaurado! Saia do terminal (Esc) e vá até o portal."
	return ""


func _on_terminal_aberto() -> void:
	_terminal_aberto = true
	if _balao_tween:
		_balao_tween.kill()
	_balao.hide()

	var linhas: Array = []
	if _primeira_vez("terminal"):
		linhas.append(INTRO)
		linhas.append("Três lugares importam: a %s (onde se mexe nas runas), o %s (%s: o que vai para o registro) e o %s (o commit, a versão guardada)." % [_conceito("Oficina"), _conceito("Palco"), _conceito("staging area"), _conceito("Arquivo")])
	linhas.append(_proximo_passo_terminal(_estado()))
	_falar(linhas)
	_atualizar_quadro()


func _on_status_mural() -> void:
	GameState.progresso_tutoria["erros_consecutivos"] = 0
	var linhas: Array = []
	if _primeira_vez("status_mural"):
		linhas.append("O %s mostra quais runas mudaram desde a última versão guardada. Em vermelho: mudanças na %s (ainda não preparadas). Em verde: mudanças no %s." % [_cmd("git status"), _conceito("Oficina"), _conceito("Palco")])
	linhas.append(_proximo_passo_terminal(_estado()))
	_falar(linhas)
	_atualizar_quadro()


func _on_diff_mural(nomes: Array) -> void:
	GameState.progresso_tutoria["erros_consecutivos"] = 0
	var linhas: Array = []
	if _primeira_vez("diff"):
		linhas.append("O %s compara a runa com a versão guardada. %s é como estava; %s é como ficou. As runas que mudaram brilharam no mural." % [_cmd("git diff"), _cmd("-cor"), _cmd("+cor")])
		linhas.append("Repare: algumas trocaram para %s (a Corrupção), mas uma delas mudou para uma cor de verdade: foi trabalho SEU. O diff serve para não confundir as duas." % _cmd("ruído"))
	elif nomes.is_empty():
		linhas.append("Sem diferenças aí: nada mudou nesse arquivo.")
	linhas.append(_proximo_passo_terminal(_estado()))
	_falar(linhas)
	_atualizar_quadro()


func _on_restaurada(_nome: String, da_staging: bool) -> void:
	GameState.progresso_tutoria["erros_consecutivos"] = 0
	var linhas: Array = []
	if da_staging:
		if _primeira_vez("restore_staged"):
			linhas.append("%s tirou a runa do %s, mas NÃO apagou a mudança: ela voltou para a %s. Serve para desfazer um %s dado por engano." % [_cmd("git restore --staged"), _conceito("Palco"), _conceito("Oficina"), _cmd("git add")])
	else:
		if _primeira_vez("restore"):
			linhas.append("O %s descartou a mudança da %s e devolveu a runa à versão anterior. Atenção: o que foi descartado %s." % [_cmd("git restore"), _conceito("Oficina"), _conceito("não volta")])
	linhas.append(_proximo_passo_terminal(_estado()))
	_falar(linhas)
	_atualizar_quadro()


func _on_preparada(_nome: String) -> void:
	GameState.progresso_tutoria["erros_consecutivos"] = 0
	var linhas: Array = ["No Palco de novo: o %s separa a mudança para o próximo registro." % _cmd("git add")]
	linhas.append(_proximo_passo_terminal(_estado()))
	_falar(linhas)
	_atualizar_quadro()


func _on_trabalho_descartado(nome: String) -> void:
	_falar(["Opa! A mudança de %s era boa, e o %s a apagou. É por isso que se olha o %s antes de descartar." % [_cmd(nome), _cmd("git restore"), _cmd("git diff")],
		_proximo_passo_terminal(_estado())])
	_atualizar_quadro()


func _explicar_falha(comando: String, motivo: String) -> String:
	if motivo == ModeloMural.FALHA_SEM_MUDANCAS:
		return "Essa runa não tem nada a desfazer desse jeito. Confira com %s: sem %s, o %s trata da Oficina; com %s, do Palco." % [_cmd("git status"), _cmd("--staged"), _cmd("restore"), _cmd("--staged")]
	if motivo == GameState.FALHA_ARQUIVO_INEXISTENTE:
		return "Esse nome não é uma runa do mural. Os nomes certos aparecem no %s (ex.: %s)." % [_cmd("git status"), _cmd("sol.runa")]
	if motivo == GameState.FALHA_NADA_PARA_ADICIONAR:
		return "Não há mudança na Oficina para preparar. O %s só leva ao Palco o que mudou." % _cmd("git add")
	if motivo == GameState.FALHA_USO_INCORRETO:
		if comando == "restore":
			return "O %s precisa saber qual runa: %s ou, para tirar do Palco, %s." % [_cmd("git restore"), _cmd("git restore sol.runa"), _cmd("git restore --staged nome.runa")]
		if comando == "diff":
			return "Use %s para tudo, ou %s para uma runa." % [_cmd("git diff"), _cmd("git diff sol.runa")]
		return "Esse comando precisa de mais informações. Veja o exemplo no quadro."
	if motivo == GameState.FALHA_COMANDO_BLOQUEADO:
		return "Calma, o %s ainda não entrou na história. Um passo de cada vez." % _cmd("git " + comando)
	if motivo == GameState.FALHA_COMANDO_INDISPONIVEL:
		return "Esse comando existe no Git, mas não é usado nesta fase. Foque nos passos do quadro."
	return super(comando, motivo)


# ---------------------------------------------------------------------------
# Quadro da IA (HUD)
# ---------------------------------------------------------------------------

func _texto_balao_para(estado: String) -> String:
	match estado:
		"palco":
			return "Atravesse a porta aberta até o Palco e use o terminal de lá."
		"concluido":
			return "Mural restaurado! Atravesse até o portal."
		"reescrever":
			return "Perdeu uma mudança boa. Use o Altar da Reescrita (ENTER)."
	return "O próximo passo está no quadro. Volte a um Obelisco (T) quando quiser."


func _texto_do_quadro(estado: String) -> String:
	match estado:
		"status":
			return "Veja o estrago:\n%s" % _cmd("git status")
		"diff":
			return "Veja COMO cada runa mudou:\n%s" % _cmd("git diff")
		"restore":
			return "Descarte só a corrupção (%s):\n%s\nSalve a %s!" % [_cmd("ruído"), _cmd("git restore nome.runa"), _cmd("mar.runa")]
		"reescrever":
			return "Mudança boa perdida.\nRefaça no Altar da Reescrita (ENTER)."
		"palco":
			return "A porta abriu. No Palco, veja:\n%s" % _cmd("git status")
		"tirar_palco":
			return "A eclipse está no Palco por engano:\n%s" % _cmd("git restore --staged eclipse.runa")
		"descartar":
			return "Agora descarte a corrupção:\n%s" % _cmd("git restore eclipse.runa")
		"preparar":
			return "Deixe a aurora no Palco:\n%s" % _cmd("git add aurora.runa")
		"concluido":
			return "Mural restaurado!\nVá até o portal, que acendeu."
	return ""


func _comandos_revelados(_estado_atual: String) -> Array[String]:
	var linhas: Array[String] = []
	var liberados := GameState.comandos_liberados
	if "status" in liberados:
		linhas.append("%s: o que mudou (quais)" % _cmd("git status"))
	if "diff" in liberados:
		linhas.append("%s: como mudou (-/+)" % _cmd("git diff"))
	if "restore" in liberados:
		linhas.append("%s: descarta (sem volta)" % _cmd("git restore nome"))
		linhas.append("%s: tira do Palco" % _cmd("git restore --staged nome"))
	if "add" in liberados:
		linhas.append("%s: põe no Palco" % _cmd("git add nome"))
	if not linhas.is_empty():
		linhas.append("%s: lista os comandos" % _cmd("git help"))
	return linhas
