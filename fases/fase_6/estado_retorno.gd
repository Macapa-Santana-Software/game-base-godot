class_name EstadoRetorno extends RefCounted
## Fase 6 — "Ponto de Retorno": fatos e progresso da fase.
##
## Esta fase usa o repositório REAL (GameState: revert, reset, stash). Aqui ficam:
##   * as consultas ("a ponte está sólida?", "o experimento foi destruído?"), sempre lidas do GameState;
##   * as flags de progresso da fase (em GameState.progresso_tutoria["retorno"]), que só avançam;
##   * `avancar()`, que é chamado a cada mudança do repositório: marca as etapas concluídas e
##     monta as situações da fase (o trabalho pela metade, os commits apressados da Câmara do Reset).
##
## Jornada (3 áreas, um comando por área):
##   1. Ponte      git log -> git revert HEAD            (desfaz um commit SEM apagar a história)
##   2. Corredor   git stash -> alavanca -> stash pop    (guarda o trabalho pela metade)
##   3. Câmara     reset --soft (mantém o trabalho) -> commit -> reset --hard (destrói de vez)

const CHAVE := "retorno"

const ARQ_BASE := "ponte_base.map"
const ARQ_REFORCO := "reforco.map"
const ARQ_RUIM := "tabuas_ruins.map"
const ARQ_LANTERNA := "lanterna.map"
const ARQ_PLANTA := "planta.map"
const ARQ_EXPERIMENTO := "experimento.map"

## O autor do commit fantasma, em base64 ("E." → "RS4="): a assinatura de Elian, codificada. A Fase 7 a decifra.
const AUTOR_FANTASMA := "RS4="

const MSG_RUIM := "Tábuas novas (ruins)"
const MSG_PLANTA := "Planta apressada"
const MSG_EXPERIMENTO := "Experimento arriscado"

static var _ocupado: bool = false


# ---------------------------------------------------------------------------
# Estado persistido (sobrevive a recarregar a cena; zerado em reset_fase)
# ---------------------------------------------------------------------------

static func construido() -> bool:
	return GameState.progresso_tutoria.has(CHAVE)


static func _dados() -> Dictionary:
	return GameState.progresso_tutoria.get(CHAVE, {"flags": {}, "ids": {}})


static func flag(chave: String) -> bool:
	return bool(_dados()["flags"].get(chave, false))


static func marcar(chave: String) -> void:
	if construido():
		GameState.progresso_tutoria[CHAVE]["flags"][chave] = true


static func id_guardado(chave: String) -> String:
	return str(_dados()["ids"].get(chave, ""))


static func guardar_id(chave: String, valor: String) -> void:
	if construido():
		GameState.progresso_tutoria[CHAVE]["ids"][chave] = valor


# ---------------------------------------------------------------------------
# Montagem do repositório da fase
# ---------------------------------------------------------------------------

## Cria o histórico inicial da fase (zera o repositório: cada tutorial é independente).
## Só age se a fase ainda não foi montada, então recarregar a cena (derrota) não refaz nada.
static func construir() -> void:
	if construido():
		return
	# As escolhas da história (ex.: como o jogador resolveu o conflito da Fase 5) atravessam este reset.
	var escolhas := GameState.escolhas_historia.duplicate(true)
	GameState.resetar_repositorio()
	GameState.escolhas_historia = escolhas
	GameState.progresso_tutoria[CHAVE] = {"flags": {}, "ids": {}}
	GameState.git_inicializado = true
	_commitar(ARQ_BASE, "Estrutura da ponte")
	_commitar(ARQ_REFORCO, "Reforço da ponte")
	_commitar(ARQ_RUIM, MSG_RUIM)


## Commit direto no repositório (sem passar pelo terminal): coloca o arquivo na staging e commita.
## A staging do jogador (ex.: a lanterna) é posta de lado e devolvida: o commit leva só o arquivo.
static func _commitar(arquivo: String, mensagem: String) -> String:
	var da_caixa := GameState.staging_area.duplicate()
	GameState.staging_area.clear()
	GameState.staging_area.append(arquivo)
	GameState.criar_commit(mensagem)
	for item in da_caixa:
		GameState.staging_area.append(item)
	return GameState.obter_head()


# ---------------------------------------------------------------------------
# Consultas (tudo lido do repositório real)
# ---------------------------------------------------------------------------

static func versionado(arquivo: String) -> bool:
	return GameState.esta_versionado(arquivo)


## O arquivo existe em algum lugar (no histórico, na caixa ou solto na pasta)?
static func existe(arquivo: String) -> bool:
	return versionado(arquivo) or arquivo in GameState.staging_area or arquivo in GameState.inventario_player


static func na_caixa(arquivo: String) -> bool:
	return arquivo in GameState.staging_area


static func ponte_solida() -> bool:
	return versionado(ARQ_BASE) and versionado(ARQ_REFORCO) and not versionado(ARQ_RUIM)


## A pasta está limpa: nada na caixa (staging) e nada solto?
static func pasta_limpa() -> bool:
	GameState.sincronizar_inventario_com_git()
	return GameState.staging_area.is_empty() and GameState.working_directory.is_empty()


static func planta_preservada() -> bool:
	return flag("z3a_setup") and not versionado(ARQ_PLANTA) \
		and (na_caixa(ARQ_PLANTA) or ARQ_PLANTA in GameState.inventario_player) \
		and GameState.obter_head() == id_guardado("base_z3")


static func experimento_destruido() -> bool:
	return flag("z3b_setup") and not existe(ARQ_EXPERIMENTO)


## A câmara ficou num estado em que o jogador não consegue mais cumprir o objetivo (ex.: um
## `reset --hard` destruiu a planta). O Altar de Retorno a coloca de volta como estava.
static func precisa_restaurar() -> bool:
	if not flag("z2_ok") or flag("hard_ok"):
		return false
	var alvo := id_guardado("alvo_camara")
	if alvo.is_empty() or GameState.obter_head() == alvo:
		return false
	if not flag("soft_ok"):
		return not planta_preservada()
	if not flag("z3b_setup"):
		return false
	return not (experimento_destruido() and versionado(ARQ_PLANTA))


static func restaurar_camara() -> bool:
	if not precisa_restaurar():
		return false
	var alvo := id_guardado("alvo_camara")
	var resultado := GameState.resetar_para(alvo, "hard")
	avancar()
	return bool(resultado["ok"])


## Etapa atual da jornada (a IA, o painel e o mundo leem daqui).
static func etapa() -> String:
	if flag("hard_ok"):
		return "concluido"
	if not flag("z1_ok"):
		if not flag("log_visto"):
			return "log"
		if not (versionado(ARQ_BASE) and versionado(ARQ_REFORCO)):
			return "desfazer_revert"
		return "revert"
	if not flag("z2_ok"):
		if not flag("stash_usado"):
			return "stash"
		if not flag("emergencia"):
			return "alavanca"
		return "pop"
	if precisa_restaurar():
		return "restaurar"
	if not flag("soft_ok"):
		return "soft"
	if not flag("commit_ok"):
		return "commit" if na_caixa(ARQ_PLANTA) else "add_planta"
	return "hard"


# ---------------------------------------------------------------------------
# Progresso
# ---------------------------------------------------------------------------

## Chamado a cada mudança do repositório. Idempotente: marca o que já foi cumprido e monta o que
## a próxima etapa precisa. (Montar um commit emite sinais, que o chamam de novo: `_ocupado` evita
## a recursão.)
static func avancar() -> void:
	if _ocupado or not construido():
		return
	_ocupado = true

	# 1) Ponte: o commit ruim foi desfeito (e nada de bom se perdeu)
	if not flag("z1_ok") and ponte_solida():
		marcar("z1_ok")

	# 2) Corredor: o jogador chega com trabalho pela metade na caixa (a lanterna)
	if flag("z1_ok") and not flag("wip_dado"):
		marcar("wip_dado")
		GameState.coletar_arquivo_no_mapa(ARQ_LANTERNA)
		GameState.sincronizar_inventario_com_git()
		GameState.adicionar_ao_stage(ARQ_LANTERNA)
	if not GameState.stash_pilha.is_empty():
		marcar("stash_usado")
	if flag("stash_usado") and not flag("inspecao_ok") and pasta_limpa():
		marcar("inspecao_ok")
	if not flag("z2_ok") and flag("emergencia") and flag("stash_usado") \
			and GameState.stash_pilha.is_empty() and na_caixa(ARQ_LANTERNA):
		marcar("z2_ok")

	# 3) Câmara do Reset, parte 1: um commit apressado que deve voltar mantendo o trabalho
	if flag("z2_ok") and not flag("z3a_setup"):
		marcar("z3a_setup")
		guardar_id("base_z3", GameState.obter_head())
		guardar_id("alvo_camara", _commitar(ARQ_PLANTA, MSG_PLANTA))
	if flag("z3a_setup") and not flag("soft_ok") and planta_preservada():
		marcar("soft_ok")
	if flag("soft_ok") and not flag("commit_ok") and versionado(ARQ_PLANTA):
		marcar("commit_ok")

	# 4) Câmara do Reset, parte 2: um experimento arriscado que deve sumir de vez
	if flag("commit_ok") and not flag("z3b_setup"):
		marcar("z3b_setup")
		guardar_id("alvo_camara", _commitar(ARQ_EXPERIMENTO, MSG_EXPERIMENTO))
	if flag("z3b_setup") and not flag("hard_ok") and experimento_destruido() and versionado(ARQ_PLANTA):
		marcar("hard_ok")
		_criar_fantasma()

	_ocupado = false


## O gancho aberto da fase: um commit que o jogador não criou, que nenhuma branch alcança e cuja
## mensagem é ilegível. Fica no repositório (e na linha do tempo, como fantasma).
static func _criar_fantasma() -> void:
	if flag("fantasma"):
		return
	marcar("fantasma")
	var primeiro := ""
	if not GameState.commits.is_empty():
		primeiro = str(GameState.commits[0]["id"])
	GameState.commits.append({
		"id": "c0x" + str(GameState.commits.size() + 1),
		"mensagem": "▓▓▓▓▓▓▓▓",
		"arquivos": [],
		"pai": primeiro,
		"pais": [] if primeiro.is_empty() else [primeiro],
		"misterio": true,
		"autor": AUTOR_FANTASMA,
	})


## Conecta `alvo` (sem argumentos) a tudo que muda o repositório ou a jornada.
static func conectar_mudancas(alvo: Callable) -> void:
	GameState.commit_realizado.connect(alvo.unbind(1))
	GameState.reset_realizado.connect(alvo.unbind(3))
	GameState.revert_realizado.connect(alvo.unbind(2))
	GameState.stash_guardado.connect(alvo.unbind(1))
	GameState.stash_aplicado.connect(alvo.unbind(1))
	GameState.arquivos_preparados.connect(alvo.unbind(1))
	GameState.arquivo_coletado.connect(alvo.unbind(1))
	var arvore := Engine.get_main_loop() as SceneTree
	var fase := arvore.get_first_node_in_group("fase_6") if arvore else null
	if fase:
		fase.mudou.connect(alvo)
