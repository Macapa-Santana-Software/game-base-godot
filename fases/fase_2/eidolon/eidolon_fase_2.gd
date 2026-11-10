class_name EidolonFase2 extends Node
## Eidolon: consciência fragmentada de um arquivista Codex que vive no Atlas.
##
## Esta é a BASE narrativa (Etapa 1): estado persistido, canais de fala, controle de
## mensagens, o despertar e as primeiras reações a `git log` e `git branch`. As dicas
## graduais, as reações a switch/add/commit/merge e o resto do arco vêm nas etapas seguintes.
##
## O texto fica em RoteiroEidolonFase2; o estado em EidolonEstado (GameState.progresso_tutoria,
## namespace próprio). Aqui só há a lógica.
##
## CANAIS DE FALA (reaproveitam o que existe; nenhum sistema novo):
##   * diálogo bloqueante  -> CaixaDialogo (só 3 momentos na fase; este arquivo faz o 1º).
##                            Nunca abre com o jogo pausado (terminal, Atlas, menu, derrota):
##                            o CaixaDialogo despausa tudo ao terminar, então ele espera.
##   * terminal            -> TerminalUI.escrever_no_terminal, logo depois da saída do comando,
##                            com o prefixo [EIDOLON] e a nota técnica "Em Git:" à parte.
##   * balão no mundo      -> MensagemHud (fala com prioridade), quando o terminal está fechado.
##
## CONTROLE DE MENSAGENS (o silêncio faz parte da personalidade dele):
##   * falas únicas nunca se repetem (nem depois de recarregar a cena);
##   * eventos quase simultâneos são agrupados e só o de maior prioridade fala;
##   * o balão tem cooldown; só prioridade alta o ignora;
##   * repetir o mesmo comando não gera nova fala (ex.: `git log` de novo = silêncio).

const PREFIXO_TERMINAL := "[color=#9BE7FF][EIDOLON][/color] "
const COR_NOTA := "#8AA0B8"
const COR_COMANDO := "#FFE08A"
## Branch da segunda realidade (a que o Eidolon "aponta" nos registros dele).
const BRANCH_ALVO := "vida-alternativa"
const PRIORIDADE_ALTA := 3
const GRUPO := &"eidolon_fase2"

## O diálogo de fechamento terminou (a Área 5 libera o portal de saída só depois dele).
signal fechamento_concluido

## Áreas de interação (relativas a este nó) cuja aproximação desperta o Eidolon.
@export var gatilhos_despertar: Array[NodePath] = []
## Tempo mínimo entre dois balões (só prioridade alta o ignora).
@export var cooldown_balao_s: float = 12.0
## Janela em que eventos quase simultâneos são agrupados em uma única fala.
@export var janela_agrupamento_s: float = 0.4
@export var intervalo_tentativa_dialogo_s: float = 0.6

@onready var _caixa: Control = get_node_or_null("../DialogoEidolon/CaixaDialogo")

var _terminal_aberto: bool = false
var _atlas_aberto: bool = false
var _em_dialogo: bool = false
var _dialogo_pendente: StringName = &""
var _dialogo_pendente_contexto: Dictionary = {}
var _dialogo_atual: StringName = &""
var _atraso_fechamento_s: float = 2.0  # tempo para ler o registro (ajustado quando o texto é conhecido)
var _merge_inspecionado: Dictionary = {}  # contexto da reflexão do merge, à espera de o Atlas fechar
var _silencio_ate_ms: int = 0
var _ultima_fala_ms: Dictionary = {}
var _fila: Array[Dictionary] = []
var _agrupando: bool = false
var _tentativa: Timer
var _atlas: AtlasUI
var _progresso: ProgressoFase2
var _area_id: StringName = &""  # área em que o jogador está agora (ids de AreaFase2)
var _inspecao_pendente: Dictionary = {}  # nó do Atlas inspecionado, à espera de o Atlas fechar


func _enter_tree() -> void:
	add_to_group(GRUPO)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # reage também com o jogo pausado (terminal aberto)
	_tentativa = Timer.new()
	_tentativa.one_shot = true
	_tentativa.wait_time = intervalo_tentativa_dialogo_s
	_tentativa.timeout.connect(_tentar_dialogo_pendente)
	add_child(_tentativa)

	for caminho in gatilhos_despertar:
		var gatilho := get_node_or_null(caminho) as Area2D
		if gatilho:
			gatilho.body_entered.connect(_on_gatilho_despertar)
		else:
			push_warning("[EIDOLON] gatilho de despertar não encontrado: %s" % caminho)

	GameState.terminal_aberto.connect(_on_terminal_aberto)
	GameState.terminal_fechado.connect(_on_terminal_fechado)
	GameState.log_consultado.connect(_on_log_consultado)
	GameState.branch_criada.connect(_on_branch_criada)
	GameState.branch_ativa_mudou.connect(_on_branch_ativa_mudou)
	GameState.arquivos_preparados.connect(_on_arquivos_preparados)
	GameState.commit_realizado.connect(_on_commit_realizado)
	GameState.merge_realizado.connect(_on_merge_realizado)
	_atlas = get_tree().get_first_node_in_group(AtlasUI.GRUPO) as AtlasUI
	if _atlas:
		_atlas.aberto.connect(_on_atlas_aberto)
		_atlas.fechado.connect(_on_atlas_fechado)
		_atlas.no_inspecionado.connect(_on_no_inspecionado)

	# Etapa 3: onde o jogador está, fragmentos de memória e ecos
	_progresso = get_node_or_null("../Progresso") as ProgressoFase2
	for no in get_tree().get_nodes_in_group(AreaFase2.GRUPO):
		var area := no as AreaFase2
		area.jogador_entrou.connect(_on_jogador_entrou)
		area.jogador_saiu.connect(_on_jogador_saiu)
	for no in get_tree().get_nodes_in_group(FragmentoMemoria.GRUPO):
		(no as FragmentoMemoria).lido.connect(_on_fragmento_lido)
	for no in get_tree().get_nodes_in_group(RegistroFinalFase2.GRUPO):
		(no as RegistroFinalFase2).observado.connect(_on_registro_observado)
		(no as RegistroFinalFase2).consulta_sem_reflexao.connect(_on_registro_sem_reflexao)
	if _progresso:
		_progresso.flag_alterada.connect(_on_flag_alterada)
		_recuperar_pendentes()


func _exit_tree() -> void:
	# O GameState é autoload e sobrevive à cena: solta as ligações.
	var sinais: Array[Array] = [
		[GameState.terminal_aberto, _on_terminal_aberto],
		[GameState.terminal_fechado, _on_terminal_fechado],
		[GameState.log_consultado, _on_log_consultado],
		[GameState.branch_criada, _on_branch_criada],
		[GameState.branch_ativa_mudou, _on_branch_ativa_mudou],
		[GameState.arquivos_preparados, _on_arquivos_preparados],
		[GameState.commit_realizado, _on_commit_realizado],
		[GameState.merge_realizado, _on_merge_realizado],
	]
	for par in sinais:
		if par[0].is_connected(par[1]):
			par[0].disconnect(par[1])


# --- Pedido de fala: agrupamento, prioridade e descarte ----------------------------------------
## Único ponto de entrada das falas. Não fala na hora: agrupa eventos próximos e fala só o mais
## importante; o resto é descartado (redundante).
func solicitar(id: StringName, contexto: Dictionary = {}) -> void:
	var entrada := RoteiroEidolonFase2.obter(id)
	if entrada.is_empty():
		push_warning("[EIDOLON] fala inexistente no roteiro: %s" % id)
		return
	if entrada.get("unica", false) and EidolonEstado.ja_disse(id):
		return
	var intervalo_ms := int(float(entrada.get("intervalo_s", 0.0)) * 1000.0)
	if intervalo_ms > 0 and Time.get_ticks_msec() - int(_ultima_fala_ms.get(id, -intervalo_ms)) < intervalo_ms:
		return
	_enfileirar(id, entrada, contexto)


## Fala DINÂMICA (montada por outro componente, ex.: DicasEidolon), com o mesmo agrupamento,
## prioridade e cooldown das falas do roteiro. `entrada` tem o mesmo formato do roteiro e pode
## trazer dois callbacks:
##   ao_entregar   Callable chamado quando a fala foi MESMO apresentada
##   ao_descartar  Callable chamado quando não foi (agrupamento, cooldown, prioridade, sem canal):
##                 quem pediu pode continuar a considerá-la elegível para depois
func entregar(id: StringName, entrada: Dictionary, contexto: Dictionary = {}) -> void:
	_enfileirar(id, entrada, contexto)


func _enfileirar(id: StringName, entrada: Dictionary, contexto: Dictionary) -> void:
	_fila.append({"id": id, "entrada": entrada, "contexto": contexto})
	if not _agrupando:
		_agrupando = true
		# process_always = true: precisa andar com o jogo pausado (terminal aberto).
		get_tree().create_timer(janela_agrupamento_s, true).timeout.connect(_processar_fila)


func _processar_fila() -> void:
	_agrupando = false
	if _fila.is_empty():
		return
	var indice := 0
	for i in _fila.size():
		if int(_fila[i]["entrada"]["prioridade"]) > int(_fila[indice]["entrada"]["prioridade"]):
			indice = i  # empate: fica o mais antigo
	var escolhida := _fila[indice]
	var descartadas: Array[Dictionary] = []
	for i in _fila.size():
		if i != indice:
			descartadas.append(_fila[i])
	_fila.clear()
	for item in descartadas:  # redundantes: nunca falam, mas quem pediu fica sabendo
		_avisar(item, "ao_descartar")
	if not _despachar(escolhida):
		_avisar(escolhida, "ao_descartar")


## Devolve false se a fala não foi apresentada.
func _despachar(item: Dictionary) -> bool:
	var id: StringName = item["id"]
	var entrada: Dictionary = item["entrada"]
	match String(entrada["canal"]):
		"dialogo":
			_abrir_dialogo(id, entrada, item["contexto"])
			return true  # abre agora ou fica pendente até a interface liberar
		"terminal":
			if _terminal_aberto:
				_falar_no_terminal(id, entrada, item["contexto"])
				return true
			return _falar_no_balao(id, entrada, item["contexto"])
	return false


func _avisar(item: Dictionary, chave: String) -> void:
	var callback: Variant = item["entrada"].get(chave)
	if callback is Callable and (callback as Callable).is_valid():
		(callback as Callable).call()


func _registrar_fala(id: StringName, entrada: Dictionary) -> void:
	if entrada.get("unica", false):
		EidolonEstado.marcar_dita(id)
	_ultima_fala_ms[id] = Time.get_ticks_msec()
	if entrada.has("etapa"):
		EidolonEstado.avancar_etapa(int(entrada["etapa"]))
	if entrada.has("evidencia"):
		EidolonEstado.registrar_evidencia(StringName(entrada["evidencia"]))
	var ao_entregar: Variant = entrada.get("ao_entregar")
	if ao_entregar is Callable and (ao_entregar as Callable).is_valid():
		(ao_entregar as Callable).call()


# --- Canal: terminal -------------------------------------------------------------------------------
func _falar_no_terminal(id: StringName, entrada: Dictionary, contexto: Dictionary) -> void:
	_registrar_fala(id, entrada)
	var linhas: Array[String] = []
	for linha in entrada.get("linhas", []):
		linhas.append(PREFIXO_TERMINAL + _destacar(_formatar(str(linha), contexto)))
	if entrada.has("nota"):
		linhas.append(_linha_de_nota(str(entrada["nota"])))
		EidolonEstado.remover_nota_pendente(id)
	# Adiado para sair DEPOIS da saída do próprio comando (que o terminal imprime em seguida).
	_escrever_no_terminal.bind(linhas).call_deferred()


func _escrever_no_terminal(linhas: Array[String]) -> void:
	var terminal := get_tree().get_first_node_in_group("terminal_ui")
	if terminal == null:
		return
	for linha in linhas:
		terminal.escrever_no_terminal(linha)


func _linha_de_nota(nota: String) -> String:
	return "[color=%s]%s[/color]" % [COR_NOTA, _destacar(nota)]


# --- Canal: balão (terminal fechado) ----------------------------------------------------------------
func _falar_no_balao(id: StringName, entrada: Dictionary, contexto: Dictionary) -> bool:
	if not entrada.has("balao"):
		return false  # sem versão curta: fica em silêncio fora do terminal
	var prioridade := int(entrada["prioridade"])
	if Time.get_ticks_msec() < _silencio_ate_ms and prioridade < PRIORIDADE_ALTA:
		return false  # cooldown do balão: descarta em vez de enfileirar
	var texto := _formatar(str(entrada["balao"]), contexto).replace("`", "")
	if not MensagemHud.falar_em(self, "Eidolon", texto, MensagemHud.COR_EIDOLON, prioridade):
		return false  # havia uma mensagem mais importante na tela
	_silencio_ate_ms = Time.get_ticks_msec() + int(cooldown_balao_s * 1000.0)
	_registrar_fala(id, entrada)
	# A nota técnica não cabe no balão. Nas reflexões do Atlas (`nota_no_balao`) ela vem logo depois
	# da fala, como mensagem SEPARADA (neutra, sem a voz do Eidolon); nas demais, espera o terminal.
	if entrada.has("nota"):
		if entrada.get("nota_no_balao", false):
			_mostrar_nota_depois(str(entrada["nota"]), _duracao_da_leitura(texto))
		else:
			EidolonEstado.adicionar_nota_pendente(id)
	return true


func _mostrar_nota_depois(nota: String, atraso_s: float) -> void:
	await get_tree().create_timer(atraso_s, true).timeout
	MensagemHud.mostrar_em(self, nota.replace("`", ""), 3)


# --- Canal: diálogo bloqueante (CaixaDialogo) -----------------------------------------------------
func _pode_abrir_dialogo() -> bool:
	return _caixa != null and not _caixa.visible and not _em_dialogo \
		and not get_tree().paused and not _terminal_aberto and not _atlas_aberto


func _abrir_dialogo(id: StringName, entrada: Dictionary, contexto: Dictionary) -> void:
	if not _pode_abrir_dialogo():
		# Terminal, Atlas, menu de pausa etc. ativos: o CaixaDialogo despausaria o jogo por
		# baixo deles. Espera ficar livre.
		_dialogo_pendente = id
		_dialogo_pendente_contexto = contexto
		_tentativa.start()
		return
	_dialogo_pendente = &""
	_dialogo_pendente_contexto = {}
	_dialogo_atual = id
	_registrar_fala(id, entrada)  # antes de abrir: recarregar no meio não repete o diálogo
	var falas: Array[String] = []
	for linha in entrada["linhas"]:
		falas.append(RoteiroEidolonFase2.PREFIXO_DIALOGO + _formatar(str(linha), contexto).replace("`", ""))
	_em_dialogo = true
	_caixa.dialogo_finalizado.connect(_on_dialogo_finalizado, CONNECT_ONE_SHOT)
	_caixa.iniciar_dialogo(falas)


func _tentar_dialogo_pendente() -> void:
	if _dialogo_pendente == &"":
		return
	var entrada := RoteiroEidolonFase2.obter(_dialogo_pendente)
	if _pode_abrir_dialogo():
		_abrir_dialogo(_dialogo_pendente, entrada, _dialogo_pendente_contexto)
	else:
		_tentativa.start()


func _on_dialogo_finalizado() -> void:
	_em_dialogo = false
	if _dialogo_atual == &"fechamento":
		fechamento_concluido.emit()
	_dialogo_atual = &""


# --- Gatilhos ------------------------------------------------------------------------------------------
func _on_gatilho_despertar(corpo: Node2D) -> void:
	if corpo is Player and not EidolonEstado.ja_disse(&"despertar"):
		solicitar(&"despertar")


func _on_log_consultado(_branch: String) -> void:
	var historico := GameState.historico()
	var mais_antiga := str(historico[historico.size() - 1]["mensagem"]) if not historico.is_empty() else ""
	solicitar(&"log_primeira", {
		"mensagem": mais_antiga.replace("[", "[lb]"),
		"branch_alvo": BRANCH_ALVO,
	})


func _on_branch_criada(nome: String, _commit_id: String) -> void:
	if nome == BRANCH_ALVO:
		solicitar(&"branch_criada", {"ativa": GameState.branch_ativa})
		if _area_id == &"ramificacao":
			_checar_desconforto_da_area_2()
	else:
		solicitar(&"branch_criada_outra", {"nome": nome.replace("[", "[lb]"), "branch_alvo": BRANCH_ALVO})


# --- Etapa 3: onde o jogador está ------------------------------------------------------------------------
func _on_jogador_entrou(area: AreaFase2) -> void:
	_area_id = area.id_area
	if _area_id == &"ramificacao":
		_checar_desconforto_da_area_2()
	elif _area_id == &"convergencia":
		_checar_doutrina_da_area_4()


func _on_jogador_saiu(area: AreaFase2) -> void:
	if _area_id == area.id_area:
		_area_id = &""


## Área 4, antes do merge: Eidolon defende a doutrina (uma linha deve prevalecer), com a
## hesitação das lacunas de memória. Depois do merge real isto não faz mais sentido.
func _checar_doutrina_da_area_4() -> void:
	if _convergiu():
		return
	await get_tree().create_timer(0.8, true).timeout
	if not _convergiu():  # o merge pode ter acontecido durante a espera: aí a doutrina não cabe mais
		solicitar(&"a4_prevalecer")


func _convergiu() -> bool:
	return _progresso != null and _progresso.obter(ProgressoFase2.CONVERGENCIA_CONCLUIDA)


## Área 2: a trilha verde existe porque a branch existe. Eidolon percebe uma possibilidade fora
## dos registros dele: desconforto, não mudança de opinião. Só depois que a branch foi criada.
func _checar_desconforto_da_area_2() -> void:
	if not GameState.branch_existe(BRANCH_ALVO):
		return
	if EidolonEstado.ja_disse(&"a2_desconforto_main") or EidolonEstado.ja_disse(&"a2_desconforto_vida"):
		return
	var id := &"a2_desconforto_vida" if GameState.branch_ativa == BRANCH_ALVO else &"a2_desconforto_main"
	_solicitar_depois(id, {"ativa": GameState.branch_ativa}, 0.8)


# --- Etapa 3: reações aos comandos (sempre depois do sucesso: vêm dos sinais do GameState) -----------
func _on_branch_ativa_mudou(_anterior: String, nova: String) -> void:
	var contexto := {"ativa": nova}
	if nova == "main":
		var exclusivos := GameState.commits_exclusivos(BRANCH_ALVO, "main")
		if not exclusivos.is_empty() and not EidolonEstado.ja_disse(&"switch_main_apos_commit"):
			# Descoberta real: o arquivo registrado na outra linha não existe nesta.
			var arquivos: Array = exclusivos[0]["arquivos"]
			var um := arquivos.size() == 1
			contexto["sujeito"] = ("O arquivo " if um else "Os arquivos ") + _juntar(arquivos)
			contexto["nao_existe"] = "não existe" if um else "não existem"
			contexto["registrado"] = "Está registrado" if um else "Estão registrados"
			contexto["arquivos"] = _juntar(arquivos)
			EidolonEstado.marcar_dita(&"switch_primeira")
			solicitar(&"switch_main_apos_commit", contexto)
			return
	if _area_id in [&"main", &"vida"] and not EidolonEstado.ja_disse(&"switch_a3_primeira"):
		EidolonEstado.marcar_dita(&"switch_primeira")
		solicitar(&"switch_a3_primeira", contexto)
	elif not EidolonEstado.ja_disse(&"switch_primeira"):
		solicitar(&"switch_primeira", contexto)


func _on_arquivos_preparados(nomes: Array[String]) -> void:
	solicitar(&"add_primeira", {
		"arquivos": _juntar(nomes),
		"espera": "espera" if nomes.size() == 1 else "esperam",
	})


func _on_commit_realizado(info: Dictionary) -> void:
	if GameState.branch_ativa != BRANCH_ALVO:
		return
	solicitar(&"commit_vida", {
		"mensagem": str(info.get("mensagem", "")).replace("[", "[lb]"),
		"id": str(info.get("id", "")),
		"arquivos": _juntar(info.get("arquivos", [])),
		"ativa": GameState.branch_ativa,
	})


## Só reage a um merge REAL de vida-alternativa em main (commit de merge criado pelo GameState).
## O diálogo do ponto de virada vem um pouco depois e espera o terminal fechar (CaixaDialogo).
func _on_merge_realizado(origem: String, destino: String, commit_id: String, fast_forward: bool) -> void:
	if fast_forward or origem != BRANCH_ALVO or destino != "main":
		return
	solicitar(&"merge_terminal", {"origem": origem, "id": commit_id})
	_solicitar_depois(&"merge_virada", {}, 1.0)


## Lista de nomes de arquivo como texto ("a, b"), com `[` escapado para o BBCode do terminal.
func _juntar(nomes: Array) -> String:
	var itens: Array[String] = []
	for nome in nomes:
		itens.append(str(nome).replace("[", "[lb]"))
	return ", ".join(itens)


# --- Etapa 3: fragmentos de memória e ecos -------------------------------------------------------------
func _on_fragmento_lido(id: StringName, texto: String) -> void:
	# A leitura em si já é a evidência (mesmo que a reação seja descartada por estar quieto).
	EidolonEstado.registrar_evidencia(id)
	_solicitar_depois(id, {}, _duracao_da_leitura(texto))


func _on_flag_alterada(nome: StringName, valor: bool) -> void:
	if not valor:
		return
	if nome == ProgressoFase2.REGISTRO_OBSERVADO:
		_solicitar_depois(&"fechamento", {}, _atraso_fechamento_s)
	elif nome == ProgressoFase2.ECO_VIDA:
		EidolonEstado.registrar_evidencia(&"eco_vida")
		_solicitar_depois(&"eco_vida_reacao", {}, 7.0)
	elif nome == ProgressoFase2.ECO_MAIN:
		EidolonEstado.registrar_evidencia(&"eco_main")
		_solicitar_depois(&"eco_main_reacao", {}, 7.0)


## Primeira observação do registro: o fechamento espera o jogador terminar de LER os dados.
func _on_registro_observado(texto: String) -> void:
	_atraso_fechamento_s = _duracao_da_leitura(texto)


## Tentou o registro com o merge feito, mas sem ter inspecionado o commit de merge no Atlas:
## Eidolon orienta (sem dizer como), no máximo uma vez a cada 25 s.
func _on_registro_sem_reflexao() -> void:
	solicitar(&"registro_sem_reflexao")


## Depois de uma derrota o pedido em memória some: refaz os momentos que o estado persistido
## mostra que ficaram pendentes (o merge aconteceu, ou o registro foi observado, e o diálogo
## correspondente ainda não foi dito).
func _recuperar_pendentes() -> void:
	if _progresso.obter(ProgressoFase2.CONVERGENCIA_CONCLUIDA) and not EidolonEstado.ja_disse(&"merge_virada"):
		_solicitar_depois(&"merge_virada", {}, 1.0)
	if _progresso.obter(ProgressoFase2.REGISTRO_OBSERVADO) and not EidolonEstado.ja_disse(&"fechamento"):
		_solicitar_depois(&"fechamento", {}, 2.0)


## Tempo para o jogador terminar de ler o texto do HUD antes de Eidolon comentar.
func _duracao_da_leitura(texto: String) -> float:
	return maxf(MensagemHud.DURACAO_MINIMA, texto.length() / MensagemHud.CARACTERES_POR_SEGUNDO) + 0.6


func _solicitar_depois(id: StringName, contexto: Dictionary, atraso_s: float) -> void:
	await get_tree().create_timer(atraso_s, true).timeout
	solicitar(id, contexto)


# --- Etapa 3: reflexão pelo Atlas --------------------------------------------------------------------------
## O jogador inspecionou um nó. A reflexão usa só dados REAIS do nó (nada inventado) e só vale
## para a memória registrada na branch alternativa; não é uma prova de compreensão.
func _on_no_inspecionado(no: Dictionary) -> void:
	if no.get("merge", false):
		_avaliar_no_de_merge(no)
		return
	if no.get("branch", "") != BRANCH_ALVO or no.get("merge", false) or no.get("pais", []).is_empty():
		return
	if EidolonEstado.ja_disse(&"atlas_commit_vida"):
		return
	_inspecao_pendente = no  # Eidolon fala quando o Atlas fechar (com o Atlas aberto o jogo está pausado)


## O nó inspecionado é o commit de merge de main com a vida-alternativa? Confere com o GameState:
## mesmo id do commit de merge real, exatamente os dois pais dele, o primeiro da linha de main e o
## segundo da linha da vida. Qualquer outro nó (ou um merge que não seja este) NÃO conclui nada.
func _avaliar_no_de_merge(no: Dictionary) -> void:
	if _progresso == null or _progresso.obter(ProgressoFase2.MERGE_INSPECIONADO):
		return
	var dados := _progresso.dados_convergencia()
	if dados.is_empty():
		return
	var merge: Dictionary = dados["merge"]
	var pais := GameState.pais_de(merge)
	if str(no.get("id", "")) != str(merge["id"]) or pais.size() != 2:
		return
	var pais_do_no: Array = no.get("pais", [])
	if pais_do_no.size() != 2 or str(pais_do_no[0]) != pais[0] or str(pais_do_no[1]) != pais[1]:
		return
	if not _ids_de(dados["linha_main"]).has(pais[0]) or not _ids_de(dados["linha_vida"]).has(pais[1]):
		return
	# Inspeção VÁLIDA: vira fato persistido agora (requisito do registro final), mesmo que a fala
	# de Eidolon seja adiada ou descartada.
	_progresso.definir(ProgressoFase2.MERGE_INSPECIONADO, true)
	if not EidolonEstado.ja_disse(&"atlas_merge_reflexao"):
		_merge_inspecionado = {"pai_main": pais[0], "pai_vida": pais[1]}


func _ids_de(commits: Array) -> Array:
	var ids: Array = []
	for commit in commits:
		ids.append(str(commit["id"]))
	return ids


func _on_terminal_aberto() -> void:
	_terminal_aberto = true
	if _area_id == &"convergencia" and EidolonEstado.ja_disse(&"a4_prevalecer") \
			and not (_progresso and _progresso.obter(ProgressoFase2.CONVERGENCIA_CONCLUIDA)):
		solicitar(&"a4_prevalecer_terminal")
	# Notas técnicas que não couberam no balão: uma por abertura, sem encher o terminal.
	var pendentes := EidolonEstado.notas_pendentes()
	if pendentes.is_empty():
		return
	var id := StringName(pendentes[0])
	var entrada := RoteiroEidolonFase2.obter(id)
	EidolonEstado.remover_nota_pendente(id)
	if entrada.has("nota"):
		_escrever_no_terminal.bind([_linha_de_nota(str(entrada["nota"]))] as Array[String]).call_deferred()


func _on_terminal_fechado() -> void:
	_terminal_aberto = false
	_tentar_dialogo_pendente.call_deferred()


func _on_atlas_aberto() -> void:
	_atlas_aberto = true


func _on_atlas_fechado() -> void:
	_atlas_aberto = false
	_tentar_dialogo_pendente.call_deferred()
	if not _merge_inspecionado.is_empty():
		var contexto := _merge_inspecionado
		_merge_inspecionado = {}
		solicitar(&"atlas_merge_reflexao", contexto)
	if not _inspecao_pendente.is_empty():
		var no := _inspecao_pendente
		_inspecao_pendente = {}
		solicitar(&"atlas_commit_vida", {
			"branch": no["branch"],
			"mensagem": str(no["mensagem"]).replace("[", "[lb]"),
			"pai": str(no["pais"][0]),
		})


# --- Formatação ---------------------------------------------------------------------------------------
func _formatar(texto: String, contexto: Dictionary) -> String:
	return texto.format(contexto)


## `comando` entre crases vira texto destacado (BBCode do terminal).
func _destacar(texto: String) -> String:
	var regex := RegEx.create_from_string("`([^`]+)`")
	return regex.sub(texto, "[color=%s]$1[/color]" % COR_COMANDO, true)
