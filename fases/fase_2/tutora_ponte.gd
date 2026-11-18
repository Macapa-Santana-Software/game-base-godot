class_name TutoraPonte extends TutoraFase1
## A mesma IA da Fase 1 (quadro "PRÓXIMO PASSO", balão, falas no terminal, andaime de
## ajuda), agora guiando a Fase 2. Reaproveita toda a parte visual da TutoraFase1 e
## só troca o roteiro: a etapa vem dos fatos reais do GameState (EstadoPonte).
##
## Metáfora: o mundo é uma sala; a BRANCH é uma cópia segura (uma linha paralela) onde se
## mexe sem arriscar a main; o SWITCH é passar de uma linha para a outra; o MERGE traz
## o conserto de volta. Os termos reais do Git sempre vêm junto da metáfora.
##
## Etapas: log -> branch -> switch -> coletar -> add -> commit -> voltar -> merge -> concluido.

const ARQUIVO := EstadoPonte.ARQUIVO
const RAMO := EstadoPonte.BRANCH


func _ready() -> void:
	super._ready()
	GameState.log_consultado.connect(_on_log_consultado)
	GameState.branch_criada.connect(_on_branch_criada)
	GameState.branch_ativa_mudou.connect(_on_branch_ativa_mudou)
	GameState.merge_realizado.connect(_on_merge_realizado)


# ---------------------------------------------------------------------------
# Estado do jogador -> etapa
# ---------------------------------------------------------------------------

func _estado() -> String:
	if EstadoPonte.na_main():
		return "concluido"
	if not GameState.branch_existe(RAMO):
		return "log" if not EstadoPonte.log_visto() else "branch"
	if EstadoPonte.na_ponte():
		return "merge" if GameState.branch_ativa == GameState.BRANCH_PADRAO else "voltar"
	if GameState.branch_ativa != RAMO:
		return "switch"
	if not ARQUIVO in GameState.inventario_player:
		return "coletar"
	if ARQUIVO in GameState.staging_area:
		return "commit"
	return "add"


# Libera os comandos um de cada vez, conforme a etapa
func _sincronizar_comandos() -> void:
	var liberados: Array[String] = ["log"]
	if EstadoPonte.log_visto() or GameState.branch_existe(RAMO):
		liberados.append("branch")
	if GameState.branch_existe(RAMO):
		liberados.append("switch")
	if EstadoPonte.entrou_na_ponte():
		liberados.append_array(["status", "add", "commit"])
	if EstadoPonte.na_ponte():
		liberados.append("merge")
	var mudou := not GameState.liberacao_progressiva or liberados != GameState.comandos_liberados
	GameState.liberacao_progressiva = true
	GameState.comandos_liberados = liberados
	if mudou:
		GameState.comandos_atualizados.emit()


# ---------------------------------------------------------------------------
# Roteiro: frase curta do próximo passo (fala no terminal)
# ---------------------------------------------------------------------------

func _proximo_passo_terminal(estado: String, _forcar_comando: bool = false) -> String:
	match estado:
		"log":
			return "Primeiro, olhe o passado desta ponte: digite %s." % _cmd("git log")
		"branch":
			return "Para consertar sem arriscar o mundo principal, crie uma cópia segura: %s." % _cmd("git branch " + RAMO)
		"switch":
			return "A cópia existe, mas você ainda está na %s. Entre nela: %s." % [_conceito("main"), _cmd("git switch " + RAMO)]
		"coletar":
			return "Você está na branch %s. Saia do terminal (Esc) e pegue a peça %s perto da borda do abismo." % [_conceito(RAMO), _cmd(ARQUIVO)]
		"add":
			return "Separe a peça na caixa: %s." % _cmd("git add " + ARQUIVO)
		"commit":
			return "Tire a foto: %s." % _cmd("git commit -m \"conserta a ponte\"")
		"voltar":
			return "A ponte está pronta, mas só na cópia. Volte ao mundo principal: %s." % _cmd("git switch main")
		"merge":
			return "Agora traga o conserto para a main: %s." % _cmd("git merge " + RAMO)
		"concluido":
			return "A ponte está inteira! Saia do terminal (Esc) e atravesse até o portal."
	return ""


# ---------------------------------------------------------------------------
# Reações aos eventos do jogo
# ---------------------------------------------------------------------------

func _on_terminal_aberto() -> void:
	_terminal_aberto = true
	if _balao_tween:
		_balao_tween.kill()
	_balao.hide()

	var linhas: Array = []
	if _primeira_vez("terminal"):
		linhas.append("A ponte está quebrada, e não vamos mexer direto no mundo principal. Vamos consertá-la numa cópia segura (uma %s) e só depois trazer o conserto de volta." % _conceito("branch"))
	linhas.append(_proximo_passo_terminal(_estado()))
	_falar(linhas)
	_atualizar_quadro()


func _on_arquivo_coletado(nome: String) -> void:
	_atualizar_quadro()
	if nome == ARQUIVO:
		_dizer("Achou a peça %s! Volte ao Obelisco (T) e registre-a: %s e %s." % [_cmd(nome), _cmd("git add"), _cmd("git commit")])


func _on_log_consultado(_branch: String) -> void:
	GameState.progresso_tutoria["erros_consecutivos"] = 0
	EstadoPonte.marcar(EstadoPonte.FLAG_LOG)
	var linhas: Array = []
	if _primeira_vez("log"):
		linhas.append("O %s lê o histórico: cada linha é um %s, uma foto do passado, do mais recente para o mais antigo. A linha principal do mundo se chama %s." % [_cmd("git log"), _conceito("commit"), _conceito("main")])
	else:
		linhas.append("Esse é o histórico da branch em que você está.")
	linhas.append(_proximo_passo_terminal(_estado()))
	_falar(linhas)
	_atualizar_quadro()


func _on_branch_criada(nome: String, commit_id: String) -> void:
	GameState.progresso_tutoria["erros_consecutivos"] = 0
	var linhas: Array = []
	linhas.append("Pronto! O %s criou a branch %s: uma linha paralela, cópia segura do mundo no commit %s. Você ainda está na main: nada mudou." % [_cmd("git branch"), _conceito(nome), _cmd(commit_id)])
	linhas.append(_proximo_passo_terminal(_estado()))
	_falar(linhas)
	_atualizar_quadro()


func _on_branch_ativa_mudou(_anterior: String, nova: String) -> void:
	GameState.progresso_tutoria["erros_consecutivos"] = 0
	var linhas: Array = []
	if nova == RAMO:
		EstadoPonte.marcar(EstadoPonte.FLAG_ENTROU)
		if _primeira_vez("switch"):
			linhas.append("O %s passou você para a outra linha. Nesta realidade a peça da ponte existe, e o que você fizer aqui não afeta a main." % _cmd("git switch"))
		else:
			linhas.append("Você está na branch %s." % _conceito(RAMO))
	else:
		if EstadoPonte.na_ponte():
			linhas.append("De volta à %s. Repare: a ponte continua quebrada aqui. O conserto só existe na branch %s, por enquanto." % [_conceito("main"), _conceito(RAMO)])
		else:
			linhas.append("De volta à %s." % _conceito("main"))
	linhas.append(_proximo_passo_terminal(_estado()))
	_falar(linhas)
	_atualizar_quadro()


func _on_status_consultado(_tinha_staging: bool, _tinha_nao_rastreados: bool) -> void:
	GameState.progresso_tutoria["erros_consecutivos"] = 0
	GameState.progresso_tutoria["status_visto"] = true
	_falar([_proximo_passo_terminal(_estado())])
	_atualizar_quadro()


func _on_arquivos_preparados(nomes: Array[String]) -> void:
	GameState.progresso_tutoria["erros_consecutivos"] = 0
	var linhas: Array = []
	if _primeira_vez("add"):
		linhas.append("Feito! %s está na %s: a caixa onde você separa o que vai entrar no próximo registro. (Você já viu isso na Fase 1.)" % [_lista(nomes), _conceito("staging area")])
	else:
		linhas.append("Na caixa: %s." % _lista(nomes))
	linhas.append(_proximo_passo_terminal(_estado()))
	_falar(linhas)
	_atualizar_quadro()


func _on_commit_realizado(info: Dictionary) -> void:
	GameState.progresso_tutoria["erros_consecutivos"] = 0
	var linhas: Array = []
	if info.get("arquivos", []).has(ARQUIVO):
		linhas.append("Foto tirada! O conserto ficou registrado só na branch %s. A %s continua intacta." % [_conceito(RAMO), _conceito("main")])
	else:
		linhas.append("Novo save point criado.")
	var proximo := _proximo_passo_terminal(_estado())
	if not proximo.is_empty():
		linhas.append(proximo)
	_falar(linhas)
	_atualizar_quadro()


func _on_merge_realizado(origem: String, destino: String, _commit_id: String, fast_forward: bool) -> void:
	GameState.progresso_tutoria["erros_consecutivos"] = 0
	var linhas: Array = []
	if fast_forward:
		linhas.append("%s trouxe a branch %s para a %s. Foi um %s: a main estava parada, então só andou até o commit da ponte." % [_cmd("git merge"), _conceito(origem), _conceito(destino), _conceito("fast-forward")])
	else:
		linhas.append("%s juntou as duas linhas: o conserto agora também vive na %s." % [_cmd("git merge"), _conceito(destino)])
	linhas.append(_proximo_passo_terminal(_estado()))
	_falar(linhas)
	_atualizar_quadro()


func _explicar_falha(comando: String, motivo: String) -> String:
	if motivo == GameState.FALHA_SEM_REPOSITORIO:
		return "O Git ainda não está acompanhando esta pasta."
	if motivo == GameState.FALHA_SEM_COMMITS:
		return "Ainda não há histórico para esse comando. Uma branch nasce de um commit existente."
	if motivo == GameState.FALHA_NOME_INVALIDO:
		return "Esse nome de branch não vale: use letras minúsculas, números, '-' e '_'. O nome desta fase é %s." % _cmd(RAMO)
	if motivo == GameState.FALHA_BRANCH_JA_EXISTE:
		return "Essa branch já existe. Para entrar nela, use %s." % _cmd("git switch " + RAMO)
	if motivo == GameState.FALHA_BRANCH_INEXISTENTE:
		return "Essa branch não existe. Veja as que existem com %s." % _cmd("git branch")
	if motivo == GameState.FALHA_MESMA_BRANCH:
		return "Não dá para juntar uma branch nela mesma. Você precisa estar na %s e trazer a %s." % [_conceito("main"), _conceito(RAMO)]
	if motivo == GameState.FALHA_STAGING_PENDENTE:
		return "Há arquivos na caixa (staging area). Tire a foto com %s antes de juntar as linhas." % _cmd("git commit")
	if motivo == GameState.FALHA_ARQUIVO_INEXISTENTE:
		return "Esse nome não está entre os arquivos soltos. A peça só existe na branch %s: entre nela, pegue a peça e abra o terminal de novo." % _conceito(RAMO)
	if motivo == GameState.FALHA_JA_NA_STAGING:
		return "Esse arquivo já está na caixa. Falta só tirar a foto: %s." % _cmd("git commit -m \"mensagem\"")
	if motivo == GameState.FALHA_JA_VERSIONADO:
		return "Esse arquivo já foi registrado."
	if motivo == GameState.FALHA_NADA_PARA_ADICIONAR:
		return "Não há arquivos soltos para adicionar. Pegue a peça da ponte no mapa (na branch %s) e volte." % _conceito(RAMO)
	if motivo == GameState.FALHA_STAGING_VAZIA:
		return "A caixa (staging area) está vazia. Primeiro separe a peça com %s." % _cmd("git add " + ARQUIVO)
	if motivo == GameState.FALHA_USO_INCORRETO:
		if comando == "commit":
			return "O %s precisa de uma mensagem entre aspas: %s." % [_cmd("git commit"), _cmd("-m \"texto\"")]
		if comando == "switch":
			return "O %s precisa do nome da branch: %s." % [_cmd("git switch"), _cmd("git switch " + RAMO)]
		if comando == "merge":
			return "O %s precisa do nome da branch a trazer: %s." % [_cmd("git merge"), _cmd("git merge " + RAMO)]
		return "Esse comando precisa de mais informações. Veja o exemplo no quadro."
	if motivo == GameState.FALHA_COMANDO_BLOQUEADO:
		return "Calma, o %s ainda não entrou na história. Um passo de cada vez." % _cmd("git " + comando)
	if motivo == GameState.FALHA_COMANDO_INDISPONIVEL:
		return "Esse comando existe no Git, mas não é usado nesta fase. Foque nos passos do quadro."
	if motivo == GameState.FALHA_COMANDO_INEXISTENTE:
		return "Não reconheci esse comando. Veja no quadro os que já usamos."
	if motivo == GameState.FALHA_NAO_E_GIT:
		return "Aqui só funcionam comandos do Git, e todos começam com a palavra %s." % _cmd("git")
	return "Algo não saiu como esperado. Veja o quadro para o próximo passo."


# ---------------------------------------------------------------------------
# Quadro da IA (HUD)
# ---------------------------------------------------------------------------

func _texto_balao_para(estado: String) -> String:
	match estado:
		"coletar":
			return "Pegue a peça %s perto da borda do abismo." % _cmd(ARQUIVO)
		"concluido":
			return "A ponte está inteira! Atravesse até o portal."
	return "O próximo passo está no quadro. Volte ao Obelisco (T) quando quiser."


func _texto_do_quadro(estado: String) -> String:
	match estado:
		"log":
			return "Vá ao terminal (T) e leia o histórico:\n%s" % _cmd("git log")
		"branch":
			return "Crie uma cópia segura do mundo:\n%s" % _cmd("git branch " + RAMO)
		"switch":
			return "Entre na cópia:\n%s" % _cmd("git switch " + RAMO)
		"coletar":
			return "Pegue a peça %s perto da borda do abismo.\nDepois volte ao terminal (T)." % _cmd(ARQUIVO)
		"add":
			return "Separe a peça na caixa:\n%s" % _cmd("git add " + ARQUIVO)
		"commit":
			return "Tire a foto (save point):\n%s" % _cmd("git commit -m \"mensagem\"")
		"voltar":
			return "A ponte só existe na cópia.\nVolte ao mundo principal:\n%s" % _cmd("git switch main")
		"merge":
			return "Traga o conserto para a main:\n%s" % _cmd("git merge " + RAMO)
		"concluido":
			return "A ponte está inteira!\nAtravesse até o portal, que acendeu."
	return ""


# Cola dos comandos: só os que já foram liberados
func _comandos_revelados(_estado_atual: String) -> Array[String]:
	var linhas: Array[String] = []
	var liberados := GameState.comandos_liberados
	if "log" in liberados:
		linhas.append("%s: lê o histórico" % _cmd("git log"))
	if "branch" in liberados:
		linhas.append("%s: cria uma cópia (linha paralela)" % _cmd("git branch nome"))
	if "switch" in liberados:
		linhas.append("%s: passa para outra linha" % _cmd("git switch nome"))
	if "add" in liberados:
		linhas.append("%s: põe na caixa" % _cmd("git add nome"))
	if "commit" in liberados:
		linhas.append("%s: tira a foto" % _cmd("git commit -m \"msg\""))
	if "merge" in liberados:
		linhas.append("%s: traz o conserto" % _cmd("git merge nome"))
	if not linhas.is_empty():
		linhas.append("%s: lista os comandos" % _cmd("git help"))
	return linhas
