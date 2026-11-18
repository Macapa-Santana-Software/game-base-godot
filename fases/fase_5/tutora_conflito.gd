class_name TutoraConflito extends TutoraFase1
## A IA da Fase 5 ("Linhas Cruzadas"): mesma tutora da Fase 1 (quadro, balão, falas no
## terminal), com o roteiro do merge COM CONFLITO. A etapa vem do ModeloConflito.
##
## História: o selo que guarda a passagem foi mexido por duas equipes ao mesmo tempo. A sua
## linha (main) o pintou de dourado; a outra equipe (branch `ajuste`) o pintou de azul. Para
## a passagem abrir, as duas linhas precisam se encontrar, e alguém precisa decidir a cor.
##
## Ideia central: conflito NÃO é erro. O Git junta sozinho tudo o que pode (porta.runa) e para
## só no que as duas linhas mudaram do mesmo jeito impossível de adivinhar. Resolver é
## escolher o conteúdo final, marcar com `git add` e fechar com `git commit`.
##
## Etapas: status -> merge -> diff -> escolher -> add -> commit -> concluido.
## `git merge --abort` é a saída de emergência em qualquer ponto do conflito.

const INTRO := "Duas equipes pintaram o mesmo selo ao mesmo tempo: a sua linha (main) de dourado, a outra (ajuste) de azul. Para a passagem abrir, as linhas precisam se encontrar."

var _modelo: ModeloConflito


func _ready() -> void:
	_modelo = ModeloConflito.ativo()
	super._ready()
	if _modelo == null:
		return
	_modelo.mudou.connect(_atualizar_quadro)
	_modelo.status_executado.connect(_on_status_conflito)
	_modelo.merge_tentado.connect(_on_merge_tentado)
	_modelo.diff_executado.connect(_on_diff_conflito)
	_modelo.escolha_feita.connect(_on_escolha)
	_modelo.conflito_preparado.connect(_on_preparado)
	_modelo.merge_concluido.connect(_on_concluido)
	_modelo.merge_abortado.connect(_on_abortado)
	_dizer.call_deferred(INTRO + " Abra o terminal no Obelisco (T).")


# ---------------------------------------------------------------------------
# Estado do jogador -> etapa
# ---------------------------------------------------------------------------

func _estado() -> String:
	if _modelo == null:
		return ""
	match _modelo.estado():
		ModeloConflito.CONCLUIDO:
			return "concluido"
		ModeloConflito.PREPARADO:
			return "commit"
		ModeloConflito.RESOLVIDO:
			return "add"
		ModeloConflito.CONFLITO:
			return "escolher" if _modelo.flag("diff_conflito") else "diff"
	return "merge" if _modelo.flag("status_visto") else "status"


func _sincronizar_comandos() -> void:
	if _modelo == null:
		return
	var liberados: Array[String] = ["status", "merge"]
	if _modelo.estado() != ModeloConflito.PRE:
		liberados.append("diff")
	if _modelo.estado() in [ModeloConflito.RESOLVIDO, ModeloConflito.PREPARADO]:
		liberados.append("add")
	if _modelo.estado() == ModeloConflito.PREPARADO:
		liberados.append("commit")
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
			return "Primeiro, olhe o terreno: digite %s." % _cmd("git status")
		"merge":
			return "A outra equipe trabalhou na branch %s. Traga o trabalho dela para a sua linha: %s." % [_conceito("ajuste"), _cmd("git merge ajuste")]
		"diff":
			return "O merge parou. Veja ONDE as linhas discordam: %s. (Se quiser desistir, %s desfaz tudo.)" % [_cmd("git diff"), _cmd("git merge --abort")]
		"escolher":
			return "Agora a decisão é sua. Saia do terminal (Esc), vá a um dos %s e aperte ENTER: ficar com a sua cor, aceitar a deles ou juntar as duas." % _conceito("pedestais")
		"add":
			return "O arquivo já não tem marcadores, mas o Git ainda não sabe. Marque como resolvido: %s." % _cmd("git add selo.runa")
		"commit":
			return "Tudo resolvido. Feche o merge: %s." % _cmd("git commit -m \"junta as duas linhas\"")
		"concluido":
			return "As linhas se encontraram! Saia do terminal (Esc) e atravesse até o portal."
	return ""


func _on_terminal_aberto() -> void:
	_terminal_aberto = true
	if _balao_tween:
		_balao_tween.kill()
	_balao.hide()

	var linhas: Array = []
	if _primeira_vez("terminal"):
		linhas.append(INTRO)
		linhas.append("Na Fase 2 você viu um %s dar certo. Hoje ele vai dar errado, de propósito: um %s não é um defeito, é o Git pedindo que VOCÊ decida." % [_cmd("git merge"), _conceito("conflito")])
	linhas.append(_proximo_passo_terminal(_estado()))
	_falar(linhas)
	_atualizar_quadro()


func _on_status_conflito() -> void:
	GameState.progresso_tutoria["erros_consecutivos"] = 0
	var linhas: Array = []
	match _modelo.estado():
		ModeloConflito.PRE:
			if _primeira_vez("status_pre"):
				linhas.append("Tudo limpo na sua linha, a %s. A outra equipe mexeu em arquivos na branch %s, mas isso ainda não chegou até você." % [_conceito("main"), _conceito("ajuste")])
		ModeloConflito.CONFLITO, ModeloConflito.RESOLVIDO:
			if _primeira_vez("status_conflito"):
				linhas.append("Dois grupos aparecem: %s (o Git juntou sozinho) e %s (%s: as duas linhas mudaram o mesmo arquivo)." % [_cmd("porta.runa"), _cmd("selo.runa"), _conceito("both modified")])
	linhas.append(_proximo_passo_terminal(_estado()))
	_falar(linhas)
	_atualizar_quadro()


func _on_merge_tentado() -> void:
	GameState.progresso_tutoria["erros_consecutivos"] = 0
	var linhas: Array = []
	if _primeira_vez("conflito"):
		linhas.append("Isto é um %s, e não um erro. O Git juntou sozinho o que pôde (%s), mas parou em %s: as duas linhas pintaram o mesmo selo de cores diferentes, e o Git não sabe qual vale." % [_conceito("conflito"), _cmd("porta.runa"), _cmd("selo.runa")])
		linhas.append("Enquanto o conflito durar, você está \"no meio de um merge\". Nada se perdeu: a sua main continua como estava.")
	else:
		linhas.append("O conflito voltou a aparecer, como esperado.")
	linhas.append(_proximo_passo_terminal(_estado()))
	_falar(linhas)
	_atualizar_quadro()


func _on_diff_conflito() -> void:
	GameState.progresso_tutoria["erros_consecutivos"] = 0
	var linhas: Array = []
	if _primeira_vez("diff_conflito"):
		linhas.append("Os %s mostram as duas versões lado a lado: acima de %s está a SUA (%s, dourado); abaixo, a DELES (%s, azul)." % [_conceito("marcadores"), _cmd("======="), _cmd("HEAD"), _cmd("ajuste")])
		linhas.append("Resolver um conflito é decidir o conteúdo final do arquivo: ficar com um lado, com o outro, ou juntar os dois.")
	linhas.append(_proximo_passo_terminal(_estado()))
	_falar(linhas)
	_atualizar_quadro()


func _on_escolha(lado: String) -> void:
	var texto := ""
	match lado:
		ModeloConflito.LADO_MINHA:
			texto = "ficou com a SUA versão (dourado)"
		ModeloConflito.LADO_DELES:
			texto = "aceitou a versão DELES (azul)"
		_:
			texto = "juntou as DUAS versões (dourado + azul)"
	var linhas: Array = ["Você %s. O arquivo não tem mais marcadores, mas isso só aconteceu na sua pasta. Quando mudar de ideia, escolha outro pedestal." % texto]
	linhas.append(_proximo_passo_terminal(_estado()))
	# Fora do terminal: balão curto. Dentro: no histórico (a escolha acontece com o terminal fechado).
	_dizer("Escolha feita. Volte ao terminal (T) e marque como resolvido: git add selo.runa")
	_falar(linhas)
	_atualizar_quadro()


func _on_preparado() -> void:
	GameState.progresso_tutoria["erros_consecutivos"] = 0
	var linhas: Array = []
	if _primeira_vez("add_conflito"):
		linhas.append("Aqui o %s tem outro papel: marca o conflito como %s. É o seu \"pode seguir\" ao Git." % [_cmd("git add"), _conceito("resolvido")])
	linhas.append(_proximo_passo_terminal(_estado()))
	_falar(linhas)
	_atualizar_quadro()


func _on_concluido() -> void:
	GameState.progresso_tutoria["erros_consecutivos"] = 0
	var linhas: Array = []
	linhas.append("O %s do merge juntou as duas linhas num só histórico, com a sua decisão registrada. Conflito resolvido!" % _cmd("git commit"))
	linhas.append("Resumo: %s tenta juntar; se houver conflito, %s mostra; você escolhe o conteúdo; %s marca; %s fecha." % [_cmd("git merge"), _cmd("git diff"), _cmd("git add"), _cmd("git commit")])
	linhas.append(_proximo_passo_terminal("concluido"))
	_falar(linhas)
	_atualizar_quadro()


func _on_abortado() -> void:
	GameState.progresso_tutoria["erros_consecutivos"] = 0
	var linhas: Array = ["Voltamos ao começo: o %s desfez a tentativa e a sua linha está como antes. É a saída segura quando bate o medo." % _cmd("git merge --abort")]
	linhas.append(_proximo_passo_terminal(_estado()))
	_falar(linhas)
	_atualizar_quadro()


# O commit real do GameState não precisa de reação própria: o fim do merge vem do modelo.
func _on_commit_realizado(_info: Dictionary) -> void:
	pass


func _explicar_falha(comando: String, motivo: String) -> String:
	if motivo == ModeloConflito.FALHA_MERGE_EM_ANDAMENTO:
		return "Você já está no meio de um merge. Resolva o conflito, ou desista com %s." % _cmd("git merge --abort")
	if motivo == ModeloConflito.FALHA_SEM_MERGE:
		return "Não há merge em andamento para abortar. Ele só existe enquanto o conflito está aberto."
	if motivo == ModeloConflito.FALHA_CONFLITO_ABERTO:
		if comando == "add":
			return "O Git não aceita o arquivo com marcadores. Antes, decida o conteúdo escolhendo um pedestal no mundo."
		return "O merge só fecha depois que todos os conflitos forem resolvidos e marcados com %s." % _cmd("git add")
	if motivo == GameState.FALHA_BRANCH_INEXISTENTE:
		return "Essa branch não existe aqui. A da outra equipe se chama %s." % _cmd("ajuste")
	if motivo == GameState.FALHA_MESMA_BRANCH:
		return "Não dá para juntar uma branch nela mesma. Traga a %s." % _cmd("ajuste")
	if motivo == GameState.FALHA_ARQUIVO_INEXISTENTE:
		return "Esse nome não é uma runa daqui. Os nomes certos aparecem no %s." % _cmd("git status")
	if motivo == GameState.FALHA_NADA_PARA_ADICIONAR or motivo == GameState.FALHA_STAGING_VAZIA:
		return "Não há conflito para resolver agora. Veja a situação com %s." % _cmd("git status")
	if motivo == GameState.FALHA_JA_NA_STAGING:
		return "O conflito já está marcado como resolvido. Falta fechar o merge com %s." % _cmd("git commit")
	if motivo == GameState.FALHA_USO_INCORRETO:
		if comando == "commit":
			return "O %s precisa de uma mensagem entre aspas: %s." % [_cmd("git commit"), _cmd("-m \"texto\"")]
		if comando == "merge":
			return "O %s precisa do nome da branch: %s." % [_cmd("git merge"), _cmd("git merge ajuste")]
		if comando == "add":
			return "O %s precisa do arquivo: %s." % [_cmd("git add"), _cmd("git add selo.runa")]
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
		"escolher":
			return "Escolha o lado num pedestal (ENTER perto dele)."
		"concluido":
			return "As linhas se encontraram! Atravesse até o portal."
	return "O próximo passo está no quadro. Volte ao Obelisco (T) quando quiser."


func _texto_do_quadro(estado: String) -> String:
	match estado:
		"status":
			return "Olhe o terreno:\n%s" % _cmd("git status")
		"merge":
			return "Traga a linha da outra equipe:\n%s" % _cmd("git merge ajuste")
		"diff":
			return "O merge parou (conflito).\nVeja onde:\n%s\nOu desista: %s" % [_cmd("git diff"), _cmd("git merge --abort")]
		"escolher":
			return "Decida a cor do selo.\nSaia (Esc) e aperte ENTER num\npedestal: sua, deles ou as duas."
		"add":
			return "Marque como resolvido:\n%s" % _cmd("git add selo.runa")
		"commit":
			return "Feche o merge:\n%s" % _cmd("git commit -m \"msg\"")
		"concluido":
			return "As linhas se encontraram!\nVá até o portal, que acendeu."
	return ""


func _comandos_revelados(_estado_atual: String) -> Array[String]:
	var linhas: Array[String] = []
	var liberados := GameState.comandos_liberados
	if "status" in liberados:
		linhas.append("%s: a situação" % _cmd("git status"))
	if "merge" in liberados:
		linhas.append("%s: junta a outra linha" % _cmd("git merge nome"))
		if _modelo != null and _modelo.em_merge():
			linhas.append("%s: desiste do merge" % _cmd("git merge --abort"))
	if "diff" in liberados:
		linhas.append("%s: mostra o conflito" % _cmd("git diff"))
	if "add" in liberados:
		linhas.append("%s: marca como resolvido" % _cmd("git add nome"))
	if "commit" in liberados:
		linhas.append("%s: fecha o merge" % _cmd("git commit -m \"msg\""))
	if not linhas.is_empty():
		linhas.append("%s: lista os comandos" % _cmd("git help"))
	return linhas
