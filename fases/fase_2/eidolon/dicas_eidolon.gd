class_name DicasEidolon extends Node
## Dicas graduais do Eidolon (tutoria adaptativa da Fase 2). Independente da narrativa
## principal: decide O QUE dizer; quem fala (canais, agrupamento, prioridade, cooldown) é o
## EidolonFase2, que recebe a dica por `entregar()`. O texto está em RoteiroDicasEidolon.
##
## TRÊS NÍVEIS (cada gatilho entrega UM; os seguintes só vêm em gatilhos seguintes):
##   1 orientação · 2 explicação conceitual · 3 ajuda prática (indica o comando, não o executa)
##
## GATILHOS (sem detecção de estagnação por tempo):
##   * `git help` (ajuda_pedida): pedido explícito. Sobe um nível por pedido; se a última falha
##     foi conceitual/de ordem, explica ESSA falha.
##   * `comando_falhou`: classificado por categoria, e cada uma é tratada de um jeito:
##       sintaxe     (forma do comando)   o terminal já mostra o erro: só fala se repetir (ou se
##                                        puder acrescentar algo, como a grafia da branch)
##       ordem       (fora de ordem)      orienta o que falta antes; escala 1 -> 2 -> 3 se repetir
##       compreensão (conceito errado)    explica o conceito daquela falha; depois, a prática
##
## ADAPTAÇÃO (não é só contar erros): o apoio sobe ou desce conforme como as etapas foram
## concluídas. Duas etapas seguidas sem ajuda nem falhas de ordem/compreensão reduzem o apoio
## (as dicas começam no nível mais baixo); se a última exigiu o nível 3 ou 2+ falhas conceituais,
## ele aumenta (começam mais fundo). Dicas de etapas já vencidas nunca voltam.
##
## CONTROLE: no máximo MAX_AUTOMATICAS_POR_ETAPA dicas automáticas por etapa, com intervalo
## mínimo entre elas; nenhuma dica se repete (a cada gatilho o nível sobe). Uma dica que o
## EidolonFase2 descartar (agrupamento, prioridade) NÃO é contada: continua elegível.
##
## Estado em GameState.progresso_tutoria["eidolon_fase_2"]["dicas"] (EidolonEstado.dicas()).

const PRIORIDADE := 1  # abaixo das falas narrativas (2) e dos diálogos (3)
const MAX_AUTOMATICAS_POR_ETAPA := 2
const INTERVALO_AUTOMATICA_S := 15.0
const INTERVALO_AJUDA_S := 3.0
const MAX_TENTATIVAS_AJUDA := 2
const BRANCH_ALVO := "vida-alternativa"
const ARQUIVO_VIDA := "eco_vida.eco"
const ARQUIVO_MAIN := "eco_main.eco"
const DISTANCIA_PARECIDA := 3

@onready var _progresso: ProgressoFase2 = $"../Progresso"
@onready var _eidolon: EidolonFase2 = $"../Eidolon"

var _ultima_automatica_ms: int = -1000000
var _ultima_ajuda_ms: int = -1000000


func _ready() -> void:
	GameState.comando_falhou.connect(_on_comando_falhou)
	GameState.ajuda_pedida.connect(_on_ajuda_pedida)
	GameState.arquivo_coletado.connect(_on_arquivo_coletado)
	GameState.arquivos_preparados.connect(_on_arquivos_preparados)
	_progresso.flag_alterada.connect(_on_flag_alterada)
	_progresso.branch_ativa_mudou.connect(_on_branch_ativa_mudou)
	_recalcular()


func _exit_tree() -> void:
	# O GameState é autoload e sobrevive à cena: solta as ligações.
	var sinais: Array[Array] = [
		[GameState.comando_falhou, _on_comando_falhou],
		[GameState.ajuda_pedida, _on_ajuda_pedida],
		[GameState.arquivo_coletado, _on_arquivo_coletado],
		[GameState.arquivos_preparados, _on_arquivos_preparados],
	]
	for par in sinais:
		if par[0].is_connected(par[1]):
			par[0].disconnect(par[1])


# --- Etapa atual (derivada de fatos reais) ----------------------------------------------------------
func etapa_atual() -> StringName:
	var p := _progresso
	var ativa := GameState.branch_ativa
	var tem_staging := not GameState.staging_area.is_empty()
	if p.obter(ProgressoFase2.REGISTRO_OBSERVADO):
		return &"concluido"
	if p.obter(ProgressoFase2.CONVERGENCIA_CONCLUIDA):
		# A reflexão (inspecionar o nó de merge no Atlas) vem antes do registro final, mas não o bloqueia.
		if not p.obter(ProgressoFase2.MERGE_INSPECIONADO):
			return &"inspecionar_merge"
		return &"observar_registro"
	if not p.obter(ProgressoFase2.LOG_CONSULTADO) and not p.obter(ProgressoFase2.BRANCH_CRIADA):
		return &"consultar_log"
	if not p.obter(ProgressoFase2.BRANCH_CRIADA):
		return &"criar_branch"
	if p.obter(ProgressoFase2.COMMIT_VIDA):
		if ativa != ProgressoFase2.BRANCH_MAIN:
			return &"voltar_main"
		if tem_staging:
			return &"registrar_main_commit"
		if p.obter(ProgressoFase2.COMMIT_MAIN):
			return &"integrar"
		if ARQUIVO_MAIN in GameState.inventario_player:
			return &"registrar_main_add"
		return &"coletar_eco_main"
	if not p.obter(ProgressoFase2.NA_VIDA_ALTERNATIVA):
		return &"entrar_vida"
	if tem_staging:
		return &"registrar_vida_commit"
	if ARQUIVO_VIDA in GameState.inventario_player:
		return &"registrar_vida_add"
	return &"coletar_eco_vida"


# --- Conclusão de etapas e apoio adaptativo --------------------------------------------------------
func _on_flag_alterada(_nome: StringName, _valor: bool) -> void:
	_recalcular()


func _on_branch_ativa_mudou(_anterior: StringName, _nova: StringName) -> void:
	_recalcular()


func _on_arquivo_coletado(_nome: String) -> void:
	_recalcular()


func _on_arquivos_preparados(_nomes: Array[String]) -> void:
	_recalcular()


func _recalcular() -> void:
	var nova := etapa_atual()
	var d := EidolonEstado.dicas()
	var antiga := StringName(d["etapa_atual"])
	if nova == antiga:
		return
	d["etapa_atual"] = String(nova)
	# Só conta como conclusão se o jogador AVANÇOU (voltar de etapa não é progresso).
	if antiga != &"" and RoteiroDicasEidolon.ETAPAS.find(nova) > RoteiroDicasEidolon.ETAPAS.find(antiga):
		_concluir(antiga)


func _concluir(etapa: StringName) -> void:
	var reg := EidolonEstado.registro_dica(etapa)
	if reg["concluida"]:
		return
	reg["concluida"] = true
	var falhas: Dictionary = reg["falhas"]
	var problemas := int(falhas.get("ordem", 0)) + int(falhas.get("compreensao", 0))
	var d := EidolonEstado.dicas()
	var sem_ajuda := int(reg["nivel"]) == 0 and problemas == 0
	d["sem_ajuda_seguidas"] = int(d["sem_ajuda_seguidas"]) + 1 if sem_ajuda else 0
	d["ultimo_pesado"] = int(reg["nivel"]) >= 3 or int(falhas.get("compreensao", 0)) >= 2


## +1 = mais apoio (começa mais fundo) · -1 = menos apoio · 0 = padrão.
func ajuste_de_apoio() -> int:
	var d := EidolonEstado.dicas()
	if d["ultimo_pesado"]:
		return 1
	if int(d["sem_ajuda_seguidas"]) >= 2:
		return -1
	return 0


# --- Gatilho: pedido explícito de ajuda (git help) ------------------------------------------------
func _on_ajuda_pedida() -> void:
	var agora := Time.get_ticks_msec()
	if agora - _ultima_ajuda_ms < int(INTERVALO_AJUDA_S * 1000.0):
		return
	_ultima_ajuda_ms = agora
	var etapa := etapa_atual()
	if etapa == &"concluido":
		return
	var reg := EidolonEstado.registro_dica(etapa)
	var proposto := 1 + maxi(ajuste_de_apoio(), 0)
	var chave := ""
	var ultima: Dictionary = reg["ultima_falha"]
	if not ultima.is_empty() and ultima["categoria"] != "sintaxe":
		# Apoio no ponto em que o jogador está: explica a falha que ele acabou de cometer.
		chave = ultima["chave"]
		proposto = maxi(proposto, 2 if ultima["categoria"] == "compreensao" else 1)
	_pedir_dica(chave, etapa, proposto, _contexto("help"), false, 0)


# --- Gatilho: falha do GameState ---------------------------------------------------------------------
func _on_comando_falhou(comando: String, motivo: String) -> void:
	var etapa := etapa_atual()
	if etapa == &"concluido":
		return
	var contexto := _contexto(comando)
	var chave := _chave_do_catalogo(motivo, comando, contexto)
	if chave.is_empty():
		return
	var espec: Dictionary = RoteiroDicasEidolon.CATALOGO[chave]
	var categoria: String = espec["categoria"]
	var reg := EidolonEstado.registro_dica(etapa)
	var falhas: Dictionary = reg["falhas"]
	falhas[categoria] = int(falhas.get(categoria, 0)) + 1
	var ocorrencia: int = falhas[categoria]
	reg["ultima_falha"] = {"chave": chave, "categoria": categoria}

	var proposto := 1
	match categoria:
		"sintaxe":
			var fala_na_primeira: bool = espec.get("fala_na_primeira", false)
			if ocorrencia == 1 and not fala_na_primeira:
				return  # o terminal já disse o que há para dizer; só fala se o jogador repetir
			proposto = 1 if (fala_na_primeira and ocorrencia == 1) else 3
		"ordem":
			proposto = ocorrencia + ajuste_de_apoio()
		_:
			proposto = ocorrencia + 1 + ajuste_de_apoio()
	proposto = clampi(proposto, 1, 3)

	if int(reg["automaticas"]) >= MAX_AUTOMATICAS_POR_ETAPA:
		return  # chega de dicas automáticas nesta etapa: só pedindo ajuda
	if Time.get_ticks_msec() - _ultima_automatica_ms < int(INTERVALO_AUTOMATICA_S * 1000.0):
		return
	_pedir_dica(chave, etapa, proposto, contexto, true, 0)


## Qual entrada do catálogo explica esta falha ("" = nenhuma).
func _chave_do_catalogo(motivo: String, comando: String, contexto: Dictionary) -> String:
	match motivo:
		"comando_bloqueado":
			return "merge_bloqueado" if comando == "merge" else "comando_bloqueado"
		"arquivo_inexistente":
			# Há arquivos na pasta? Então o nome é que está errado; senão falta o que adicionar.
			return "arquivo_inexistente" if not GameState.working_directory.is_empty() else "nada_para_adicionar"
		"branch_inexistente":
			if _nome_parecido(String(contexto["nome_cru"])):
				return "branch_inexistente_parecida"
			var especifica := "branch_inexistente:" + comando
			return especifica if RoteiroDicasEidolon.CATALOGO.has(especifica) else "branch_inexistente"
		"uso_incorreto":
			var especifico := "uso_incorreto:" + comando
			return especifico if RoteiroDicasEidolon.CATALOGO.has(especifico) else "uso_incorreto"
	return motivo if RoteiroDicasEidolon.CATALOGO.has(motivo) else ""


# --- Escolha do nível e entrega --------------------------------------------------------------------------
## Entrega UM nível: nunca menor nem igual ao que já foi dado nesta etapa (sem repetir e sem
## despejar os três em sequência). `proposto` é o nível que o gatilho sugere.
func _pedir_dica(chave: String, etapa: StringName, proposto: int, contexto: Dictionary,
		automatica: bool, tentativa: int) -> void:
	var reg := EidolonEstado.registro_dica(etapa)
	var nivel := maxi(proposto, int(reg["nivel"]) + 1)
	if nivel > 3:
		if not automatica:
			_pedir_esgotado(etapa, contexto)
		return
	var texto := _resolver(chave, etapa, nivel, chave_merge_falta())
	if texto.is_empty():
		return
	var id := StringName("dica:%s:%s:%d" % [etapa, chave if not chave.is_empty() else "etapa", nivel])
	var entrada := {
		"canal": "terminal", "prioridade": PRIORIDADE, "unica": false,
		"linhas": [texto["fala"]],
		"ao_entregar": _ao_entregar.bind(etapa, nivel, id, automatica),
		"ao_descartar": _ao_descartar.bind(chave, etapa, proposto, contexto, automatica, tentativa),
	}
	if texto.has("nota"):
		entrada["nota"] = texto["nota"]
	_eidolon.entregar(id, entrada, contexto)


func _pedir_esgotado(etapa: StringName, contexto: Dictionary) -> void:
	var reg := EidolonEstado.registro_dica(etapa)
	if "esgotado" in reg["ditas"]:
		return
	_eidolon.entregar(&"dica:esgotado", {
		"canal": "terminal", "prioridade": PRIORIDADE, "unica": false,
		"linhas": [RoteiroDicasEidolon.ESGOTADO],
		"ao_entregar": func() -> void: reg["ditas"].append("esgotado"),
	}, contexto)


func _resolver(chave: String, etapa: StringName, nivel: int, falta_merge: String) -> Dictionary:
	var espec: Dictionary = RoteiroDicasEidolon.CATALOGO.get(chave, {})
	var niveis: Dictionary = espec.get("niveis", {})
	if niveis.has(nivel):
		return niveis[nivel]
	if chave == "merge_bloqueado" and nivel == 1:
		return {"fala": RoteiroDicasEidolon.MERGE_FALTA[falta_merge]}
	var etapa_dicas: StringName = espec.get("etapa_fallback", etapa)
	return RoteiroDicasEidolon.DICAS_ETAPA.get(etapa_dicas, {}).get(nivel, {})


## O que falta para o merge ser possível (vida, main ou destino).
func chave_merge_falta() -> String:
	if not _progresso.obter(ProgressoFase2.COMMIT_VIDA):
		return "vida"
	if not _progresso.obter(ProgressoFase2.COMMIT_MAIN):
		return "main"
	return "destino"


func _ao_entregar(etapa: StringName, nivel: int, id: StringName, automatica: bool) -> void:
	var reg := EidolonEstado.registro_dica(etapa)
	reg["nivel"] = maxi(int(reg["nivel"]), nivel)
	reg["ditas"].append(String(id))
	if automatica:
		reg["automaticas"] = int(reg["automaticas"]) + 1
		_ultima_automatica_ms = Time.get_ticks_msec()


## Não foi apresentada (agrupamento, prioridade...): NADA foi registrado, continua elegível.
## Um pedido explícito de ajuda é tentado de novo, poucas vezes; as automáticas voltam
## sozinhas se a falha se repetir.
func _ao_descartar(chave: String, etapa: StringName, proposto: int, contexto: Dictionary,
		automatica: bool, tentativa: int) -> void:
	if automatica or tentativa >= MAX_TENTATIVAS_AJUDA:
		return
	await get_tree().create_timer(1.0, true).timeout
	if etapa_atual() == etapa:
		_pedir_dica(chave, etapa, proposto, contexto, false, tentativa + 1)


# --- Contexto (nomes digitados, arquivo de exemplo) -------------------------------------------------
func _contexto(comando: String) -> Dictionary:
	var argumentos := _argumentos_do_ultimo_comando()
	var nome := argumentos[0] if not argumentos.is_empty() else ""
	return {
		"nome": nome.replace("[", "[lb]"), "nome_cru": nome, "origem": nome.replace("[", "[lb]"),
		"branch_alvo": BRANCH_ALVO, "ativa": GameState.branch_ativa, "comando": comando,
		"arquivo": ARQUIVO_MAIN if _progresso.obter(ProgressoFase2.COMMIT_VIDA) else ARQUIVO_VIDA,
	}


## Argumentos do último comando digitado (depois de "git <comando>").
func _argumentos_do_ultimo_comando() -> Array[String]:
	var resultado: Array[String] = []
	var terminal := get_tree().get_first_node_in_group("terminal_ui")
	if terminal == null or not terminal.has_method("ultimo_comando"):
		return resultado
	var partes: PackedStringArray = str(terminal.ultimo_comando()).split(" ", false)
	for i in range(2, partes.size()):
		resultado.append(partes[i])
	return resultado


func _nome_parecido(nome: String) -> bool:
	if nome.is_empty():
		return false
	var existentes: Array[String] = GameState.listar_branches()
	if BRANCH_ALVO not in existentes:
		existentes.append(BRANCH_ALVO)
	for existente in existentes:
		if _distancia(nome, existente) <= DISTANCIA_PARECIDA:
			return true
	return false


## Distância de Levenshtein (quantas edições separam duas palavras).
static func _distancia(a: String, b: String) -> int:
	var anterior: Array[int] = []
	for j in range(b.length() + 1):
		anterior.append(j)
	for i in range(1, a.length() + 1):
		var atual: Array[int] = [i]
		for j in range(1, b.length() + 1):
			var custo := 0 if a[i - 1] == b[j - 1] else 1
			atual.append(mini(mini(anterior[j] + 1, atual[j - 1] + 1), anterior[j - 1] + custo))
		anterior = atual
	return anterior[b.length()]
