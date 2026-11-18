class_name TutoraRetorno extends TutoraFase1
## A IA da Fase 6 ("Ponto de Retorno"): mesma tutora da Fase 1 (quadro, balão, falas no terminal),
## com o roteiro de revert, stash e reset. A etapa vem do EstadoRetorno (fatos do repositório real).
##
## História: todo commit é um marco no tempo. Errar é normal; o Git deixa voltar atrás, mas cada
## jeito de voltar tem um custo. Três jeitos, três áreas:
##   revert  desfaz um commit CRIANDO outro (a história continua inteira)
##   stash   guarda o trabalho pela metade numa prateleira para resolver outra coisa
##   reset   volta o ponteiro no tempo: --soft mantém o trabalho, --hard o destrói
##
## A fase não fecha a história: no fim aparece um commit fantasma que não é do jogador.
##
## Etapas: log -> revert (-> desfazer_revert) -> stash -> alavanca -> pop -> soft
##         -> add_planta/commit -> hard -> concluido (e "restaurar" quando uma câmara fica sem saída).

const INTRO := "Todo commit é um marco no tempo, e errar é normal: o Git deixa voltar atrás. Mas cada jeito de voltar tem um custo, e hoje você vai conhecer três: revert, stash e reset."

var _fase: Node


func _ready() -> void:
	super._ready()
	_fase = get_tree().get_first_node_in_group("fase_6")
	GameState.log_consultado.connect(_on_log)
	GameState.revert_realizado.connect(_on_revert)
	GameState.reset_realizado.connect(_on_reset)
	GameState.stash_guardado.connect(_on_stash_guardado)
	GameState.stash_aplicado.connect(_on_stash_aplicado)
	if _fase:
		_fase.mudou.connect(_atualizar_quadro)
		_fase.evento.connect(_on_evento)
	_dizer.call_deferred(INTRO + " Abra o terminal no Obelisco (T).")


# ---------------------------------------------------------------------------
# Estado do jogador -> etapa
# ---------------------------------------------------------------------------

func _estado() -> String:
	return EstadoRetorno.etapa()


func _sincronizar_comandos() -> void:
	var liberados: Array[String] = ["status", "log", "revert"]
	if EstadoRetorno.flag("z1_ok"):
		liberados.append("stash")
	if EstadoRetorno.flag("z2_ok"):
		liberados.append("reset")
	if EstadoRetorno.flag("soft_ok"):
		liberados.append_array(["add", "commit"])
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
		"log":
			return "A ponte foi sabotada por um commit ruim. Primeiro, leia o histórico: %s. O mais recente (%s) é o suspeito." % [_cmd("git log"), _conceito("HEAD")]
		"revert":
			return "Desfaça o commit ruim SEM apagar a história: %s." % _cmd("git revert HEAD")
		"desfazer_revert":
			return "Você desfez um commit bom. Sem pânico: o revert também pode ser desfeito. Desfaça o desfazer: %s. Depois, veja no %s qual commit é o ruim (%s)." % [_cmd("git revert HEAD"), _cmd("git log"), _cmd("Tábuas novas")]
		"stash":
			return "A lanterna está na caixa (trabalho pela metade) e o portão só deixa passar pasta limpa. Guarde-a: %s." % _cmd("git stash")
		"alavanca":
			return "A pasta está limpa e o portão de inspeção abriu. Saia do terminal (Esc), passe por ele e puxe a alavanca (ENTER)."
		"pop":
			return "Emergência resolvida! Recupere a lanterna: %s." % _cmd("git stash pop")
		"restaurar":
			return "A câmara ficou sem saída (um reset levou embora o que você precisava). O %s (ENTER perto dele) a recoloca como estava. Aprendizado: o reset não pergunta." % _conceito("Altar de Retorno")
		"soft":
			return "A planta foi commitada cedo demais. Volte um commit mas MANTENHA o trabalho: %s." % _cmd("git reset --soft HEAD~1")
		"add_planta":
			return "A planta ficou solta na pasta (o modo %s não a deixa na caixa). Ponha-a de volta: %s." % [_cmd("--mixed"), _cmd("git add planta.map")]
		"commit":
			return "A planta está na caixa. Registre-a como deve ser: %s." % _cmd("git commit -m \"planta\"")
		"hard":
			return "O experimento é lixo. Volte um commit E jogue-o fora de vez: %s. Cuidado: o %s não pergunta." % [_cmd("git reset --hard HEAD~1"), _cmd("--hard")]
		"concluido":
			return "Câmara limpa! Saia do terminal (Esc) e vá até o portal."
	return ""


func _on_terminal_aberto() -> void:
	_terminal_aberto = true
	if _balao_tween:
		_balao_tween.kill()
	_balao.hide()

	var linhas: Array = []
	if _primeira_vez("terminal"):
		linhas.append(INTRO)
		linhas.append("A linha do tempo, embaixo, mostra os commits. %s é onde você está agora; fantasmas são marcos que ficaram para trás." % _conceito("HEAD"))
	linhas.append(_proximo_passo_terminal(_estado()))
	_falar(linhas)
	_atualizar_quadro()


func _on_log(_branch: String) -> void:
	GameState.progresso_tutoria["erros_consecutivos"] = 0
	var linhas: Array = []
	if _primeira_vez("log"):
		linhas.append("Cada linha é um %s, do mais recente ao mais antigo. O último, %s, é o culpado pela ponte quebrada." % [_conceito("commit"), _cmd("Tábuas novas (ruins)")])
	linhas.append(_proximo_passo_terminal(_estado()))
	_falar(linhas)
	_atualizar_quadro()


func _on_status_consultado(_tinha_staging: bool, _tinha_nao_rastreados: bool) -> void:
	GameState.progresso_tutoria["erros_consecutivos"] = 0
	var linhas: Array = []
	if _primeira_vez("status"):
		linhas.append("O %s mostra a caixa (%s) e a pasta. É o seu olhar para conferir o efeito de cada comando de hoje." % [_cmd("git status"), _conceito("staging area")])
	linhas.append(_proximo_passo_terminal(_estado()))
	_falar(linhas)
	_atualizar_quadro()


func _on_revert(original: String, _novo: String) -> void:
	GameState.progresso_tutoria["erros_consecutivos"] = 0
	var linhas: Array = []
	if EstadoRetorno.flag("z1_ok"):
		linhas.append("O %s NÃO apagou o commit ruim: criou um commit NOVO que o desfaz (veja o nó ciano na linha do tempo). A história continua inteira, o que é seguro para quem trabalha em equipe." % _cmd("git revert"))
	else:
		linhas.append("O revert desfez o commit %s, mas ele não era o ruim. Isso também fica registrado." % _cmd(original))
	linhas.append(_proximo_passo_terminal(_estado()))
	_falar(linhas)
	_atualizar_quadro()


func _on_stash_guardado(_arquivos: Array) -> void:
	GameState.progresso_tutoria["erros_consecutivos"] = 0
	var linhas: Array = []
	if _primeira_vez("stash"):
		linhas.append("O %s guardou o trabalho pela metade na prateleira e deixou a pasta limpa, sem precisar de um commit. O portão de inspeção reconheceu a pasta limpa e abriu." % _cmd("git stash"))
	else:
		linhas.append("Trabalho guardado na prateleira.")
	linhas.append(_proximo_passo_terminal(_estado()))
	_falar(linhas)
	_atualizar_quadro()


func _on_stash_aplicado(_arquivos: Array) -> void:
	GameState.progresso_tutoria["erros_consecutivos"] = 0
	var linhas: Array = []
	if _primeira_vez("pop"):
		linhas.append("O %s devolveu o trabalho exatamente como estava na caixa. O stash serve para interromper o que você faz e voltar depois." % _cmd("git stash pop"))
	linhas.append(_proximo_passo_terminal(_estado()))
	_falar(linhas)
	_atualizar_quadro()


func _on_reset(modo: String, _de: String, _para: String) -> void:
	GameState.progresso_tutoria["erros_consecutivos"] = 0
	var linhas: Array = []
	match modo:
		"soft":
			if _primeira_vez("reset_soft"):
				linhas.append("O %s voltou o ponteiro (o commit apressado virou fantasma na linha do tempo), mas o trabalho continuou na caixa: nada se perdeu." % _cmd("git reset --soft"))
		"hard":
			if _primeira_vez("reset_hard"):
				linhas.append("O %s voltou o ponteiro E apagou o trabalho dos commits descartados. Diferente do revert, aqui o conteúdo some de verdade." % _cmd("git reset --hard"))
		_:
			if _primeira_vez("reset_mixed"):
				linhas.append("O %s voltou o ponteiro e esvaziou a caixa: o trabalho ficou solto na pasta, sem ser acompanhado." % _cmd("git reset --mixed"))
	linhas.append(_proximo_passo_terminal(_estado()))
	_falar(linhas)
	_atualizar_quadro()


# Os commits e a caixa da fase são montados pelo próprio código: só os eventos da história falam.
func _on_arquivos_preparados(nomes: Array[String]) -> void:
	if EstadoRetorno.ARQ_PLANTA in nomes:
		GameState.progresso_tutoria["erros_consecutivos"] = 0
		_falar(["A planta voltou para a caixa. %s" % _proximo_passo_terminal(_estado())])
	_atualizar_quadro()


func _on_commit_realizado(_info: Dictionary) -> void:
	_atualizar_quadro()


func _on_evento(nome: String) -> void:
	var linhas: Array = []
	match nome:
		"z1_ok":
			linhas.append("A ponte está inteira! Agora, o Corredor: você chegou com a lanterna já na caixa. Observe a prateleira do %s." % _conceito("stash"))
			linhas.append(_proximo_passo_terminal(_estado()))
		"alavanca":
			linhas.append("Emergência resolvida. Agora volte ao terminal e recupere o seu trabalho.")
		"z2_ok":
			linhas.append("Trabalho de volta, e o caminho para a Câmara do Reset abriu. Aqui estão dois commits apressados e dois destinos diferentes. Um está pela frente: a planta.")
		"soft_ok":
			linhas.append("O commit sumiu da linha, mas o trabalho está salvo. Era a ideia: refazer o commit direito.")
			linhas.append(_proximo_passo_terminal(_estado()))
		"commit_ok":
			linhas.append("Planta registrada como deve ser. Mas apareceu outro commit apressado, o do experimento: ele não presta e precisa sumir.")
		"z3b_setup":
			linhas.append(_proximo_passo_terminal(_estado()))
		"hard_ok":
			linhas.append("O experimento sumiu de vez. Veja a linha do tempo: um marco deixado para trás não desaparece, vira fantasma. E há um fantasma que NÃO é seu, com a mensagem ilegível.")
			linhas.append("Isso não era nosso... Mas fica para depois. Por hoje, vá até o portal.")
		"restaurou":
			linhas.append("A câmara voltou ao começo. Sem problema: errar faz parte, e agora você viu o que o reset faz.")
			linhas.append(_proximo_passo_terminal(_estado()))
	if linhas.is_empty():
		return
	_dizer(linhas[0])
	_falar(linhas)
	_atualizar_quadro()


func _explicar_falha(comando: String, motivo: String) -> String:
	if motivo == GameState.FALHA_COMMIT_INEXISTENTE:
		return "Esse commit não existe nesta linha. Use %s, %s (o anterior) ou um id do %s." % [_cmd("HEAD"), _cmd("HEAD~1"), _cmd("git log")]
	if motivo == GameState.FALHA_STAGING_PENDENTE:
		return "Há arquivos na caixa (staging area). Resolva isso antes: guarde com %s ou registre com %s." % [_cmd("git stash"), _cmd("git commit")]
	if motivo == GameState.FALHA_STASH_VAZIO:
		return "Não há nada guardado. O %s só devolve o que o %s guardou antes." % [_cmd("stash pop"), _cmd("git stash")]
	if motivo == GameState.FALHA_NADA_PARA_GUARDAR:
		return "Não há trabalho em andamento para guardar: a pasta e a caixa já estão limpas."
	if motivo == GameState.FALHA_MODO_INVALIDO:
		return "Os modos do reset são %s, %s e %s." % [_cmd("--soft"), _cmd("--mixed"), _cmd("--hard")]
	if motivo == GameState.FALHA_MERGE_COMMIT:
		return "Esse commit é de merge, e isso o jogo ainda não desfaz."
	if motivo == GameState.FALHA_ARQUIVO_INEXISTENTE:
		return "Esse arquivo não está entre os que estão soltos. Confira os nomes com %s." % _cmd("git status")
	if motivo == GameState.FALHA_JA_NA_STAGING:
		return "Esse arquivo já está na caixa."
	if motivo == GameState.FALHA_USO_INCORRETO:
		if comando == "revert":
			return "O %s precisa do commit a desfazer: %s." % [_cmd("git revert"), _cmd("git revert HEAD")]
		if comando == "reset":
			return "O %s precisa do modo e do commit: %s." % [_cmd("git reset"), _cmd("git reset --soft HEAD~1")]
		if comando == "stash":
			return "Use %s para guardar e %s para recuperar." % [_cmd("git stash"), _cmd("git stash pop")]
		if comando == "commit":
			return "O %s precisa de uma mensagem entre aspas: %s." % [_cmd("git commit"), _cmd("-m \"texto\"")]
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
		"alavanca":
			return "Passe pelo portão aberto e puxe a alavanca (ENTER)."
		"restaurar":
			return "Câmara sem saída. Use o Altar de Retorno (ENTER)."
		"concluido":
			return "Câmara limpa! Atravesse até o portal."
	return "O próximo passo está no quadro. Volte a um Obelisco (T) quando quiser."


func _texto_do_quadro(estado: String) -> String:
	match estado:
		"log":
			return "Leia o histórico:\n%s" % _cmd("git log")
		"revert":
			return "Desfaça o commit ruim:\n%s" % _cmd("git revert HEAD")
		"desfazer_revert":
			return "Desfez o commit errado.\nDesfaça o desfazer:\n%s" % _cmd("git revert HEAD")
		"stash":
			return "Guarde o trabalho pela\nmetade (lanterna):\n%s" % _cmd("git stash")
		"alavanca":
			return "Pasta limpa! Passe pelo\nportão e puxe a alavanca\n(ENTER)."
		"pop":
			return "Recupere o trabalho:\n%s" % _cmd("git stash pop")
		"restaurar":
			return "Câmara sem saída.\nUse o Altar de Retorno\n(ENTER)."
		"soft":
			return "Volte, mas mantenha a\nplanta:\n%s" % _cmd("git reset --soft HEAD~1")
		"add_planta":
			return "A planta ficou solta:\n%s" % _cmd("git add planta.map")
		"commit":
			return "Registre a planta:\n%s" % _cmd("git commit -m \"planta\"")
		"hard":
			return "Volte e jogue o\nexperimento fora:\n%s" % _cmd("git reset --hard HEAD~1")
		"concluido":
			return "Câmara limpa!\nVá até o portal, que acendeu."
	return ""


func _comandos_revelados(_estado_atual: String) -> Array[String]:
	var linhas: Array[String] = []
	var liberados := GameState.comandos_liberados
	if "log" in liberados:
		linhas.append("%s: lê o histórico" % _cmd("git log"))
	if "revert" in liberados:
		linhas.append("%s: desfaz criando outro" % _cmd("git revert nome"))
	if "stash" in liberados:
		linhas.append("%s: guarda / devolve" % _cmd("git stash [pop]"))
	if "reset" in liberados:
		linhas.append("%s: volta o HEAD" % _cmd("git reset --soft|--hard"))
	if "add" in liberados:
		linhas.append("%s: põe na caixa" % _cmd("git add nome"))
	if "commit" in liberados:
		linhas.append("%s: registra" % _cmd("git commit -m \"msg\""))
	if "status" in liberados:
		linhas.append("%s: caixa e pasta" % _cmd("git status"))
	if not linhas.is_empty():
		linhas.append("%s: lista os comandos" % _cmd("git help"))
	return linhas
