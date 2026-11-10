class_name ProgressoFase2 extends Node
## Estado de progressão da Fase 2 "Ecos de Possibilidades".
##
## É o ÚNICO ponto da fase que conversa com o GameState (adaptador). Os demais nós
## (barreiras, zonas, gerenciador de realidades) só falam com este nó, então a lógica
## Git e a lógica visual do mapa permanecem separadas.
##
## Dois tipos de flag:
##   * DERIVADAS do Git: refletem fatos reais do repositório (branches, histórico, merge)
##     e só este nó as altera, ao receber os sinais do GameState. `definir()` as recusa.
##     Nenhuma interação do mapa consegue ligá-las: só a operação Git de verdade.
##   * De exploração/observação (ECO_*, REGISTRO_OBSERVADO): ligadas por interações do
##     mapa. Também gravadas em `branches[x].mundo`, então sobrevivem ao reload da cena.

const GRUPO := &"progresso_fase2"

# Nomes das branches das duas realidades (iguais aos nomes reais no Git).
const BRANCH_MAIN := &"main"
const BRANCH_VIDA := &"vida-alternativa"

# --- Derivadas do Git ---------------------------------------------------------------
const LOG_CONSULTADO := &"log_consultado"            # `git log` foi executado
const BRANCH_CRIADA := &"branch_criada"              # a branch vida-alternativa existe
const NA_VIDA_ALTERNATIVA := &"na_vida_alternativa"  # a branch ativa é vida-alternativa
const COMMIT_VIDA := &"commit_vida"                  # vida-alternativa tem commit próprio
const COMMIT_MAIN := &"commit_main"                  # main tem commit próprio (divergiu)
const CONVERGENCIA_CONCLUIDA := &"convergencia_concluida"  # merge de vida-alternativa em main

# --- Exploração / observação ----------------------------------------------------------
const ECO_MAIN := &"eco_main"
const ECO_VIDA := &"eco_vida"
## O jogador inspecionou NO ATLAS o commit de merge real (ver EidolonFase2._avaliar_no_de_merge:
## mesmo id do merge do GameState e os dois pais exatos). É requisito do registro final. A flag é
## ligada no instante da inspeção válida, não quando o Eidolon fala sobre ela.
const MERGE_INSPECIONADO := &"merge_inspecionado"
const REGISTRO_OBSERVADO := &"registro_observado"    # interação narrativa com o registro final

const FLAGS_DERIVADAS: Array[StringName] = [
	LOG_CONSULTADO, BRANCH_CRIADA, NA_VIDA_ALTERNATIVA, COMMIT_VIDA, COMMIT_MAIN,
	CONVERGENCIA_CONCLUIDA,
]

## Ordem natural de progressão (usada pela ferramenta de debug).
const ORDEM_FLAGS: Array[StringName] = [
	LOG_CONSULTADO, BRANCH_CRIADA, NA_VIDA_ALTERNATIVA, ECO_VIDA, COMMIT_VIDA,
	ECO_MAIN, COMMIT_MAIN, CONVERGENCIA_CONCLUIDA, MERGE_INSPECIONADO, REGISTRO_OBSERVADO,
]

## Flags de exploração que sobrevivem ao reload: flag -> [branch dona, chave em `mundo`].
const PERSISTENCIA := {
	&"eco_main": [&"main", "eco_coletado"],
	&"eco_vida": [&"vida-alternativa", "eco_coletado"],
	&"merge_inspecionado": [&"main", "merge_inspecionado"],
	&"registro_observado": [&"main", "registro_observado"],
}

signal flag_alterada(nome: StringName, valor: bool)
## Repasse dos sinais do GameState, para o resto da fase não depender dele.
signal branch_ativa_mudou(anterior: StringName, nova: StringName)
signal branch_criada(nome: StringName)

var _flags: Dictionary = {}
var _sincronizando: bool = false


func _enter_tree() -> void:
	# No _enter_tree para que todos os nós já o encontrem quando rodarem o _ready.
	add_to_group(GRUPO)


func _ready() -> void:
	_restaurar_exploracao()
	_sincronizar_derivadas()
	GameState.branch_criada.connect(_on_git_branch_criada)
	GameState.branch_ativa_mudou.connect(_on_git_branch_ativa_mudou)
	GameState.commit_realizado.connect(_on_git_commit_realizado)
	GameState.merge_realizado.connect(_on_git_merge_realizado)
	GameState.log_consultado.connect(_on_git_log_consultado)


func _exit_tree() -> void:
	# O GameState é autoload e sobrevive à cena: solta as ligações para não vazar.
	if GameState.branch_criada.is_connected(_on_git_branch_criada):
		GameState.branch_criada.disconnect(_on_git_branch_criada)
	if GameState.branch_ativa_mudou.is_connected(_on_git_branch_ativa_mudou):
		GameState.branch_ativa_mudou.disconnect(_on_git_branch_ativa_mudou)
	if GameState.commit_realizado.is_connected(_on_git_commit_realizado):
		GameState.commit_realizado.disconnect(_on_git_commit_realizado)
	if GameState.merge_realizado.is_connected(_on_git_merge_realizado):
		GameState.merge_realizado.disconnect(_on_git_merge_realizado)
	if GameState.log_consultado.is_connected(_on_git_log_consultado):
		GameState.log_consultado.disconnect(_on_git_log_consultado)


static func de(no: Node) -> ProgressoFase2:
	if not no.is_inside_tree():
		return null
	return no.get_tree().get_first_node_in_group(GRUPO) as ProgressoFase2


# --- Flags ---------------------------------------------------------------------------
func obter(nome: StringName) -> bool:
	return _flags.get(nome, false)


## `flags` aceita PackedStringArray ou Array. Lista vazia = sem requisitos.
func todas_ativas(flags) -> bool:
	for flag in flags:
		if not obter(StringName(flag)):
			return false
	return true


func definir(nome: StringName, valor: bool = true) -> void:
	if nome in FLAGS_DERIVADAS and not _sincronizando:
		push_warning("[FASE 2] '%s' é derivada do Git e não pode ser definida diretamente." % nome)
		return
	if obter(nome) == valor:
		return
	_flags[nome] = valor
	print("[FASE 2] flag '%s' = %s" % [nome, valor])
	if PERSISTENCIA.has(nome):
		guardar_mundo(PERSISTENCIA[nome][0], PERSISTENCIA[nome][1], valor)
	flag_alterada.emit(nome, valor)


## Zera as flags que NÃO vêm do Git (exploração/observação). Não toca no repositório.
func resetar() -> void:
	for nome in ORDEM_FLAGS:
		if nome not in FLAGS_DERIVADAS:
			definir(nome, false)


func listar() -> Dictionary:
	var resultado := {}
	for nome in ORDEM_FLAGS:
		resultado[nome] = obter(nome)
	return resultado


# --- Leitura do estado Git (somente leitura) ---------------------------------------------
func branch_ativa() -> StringName:
	return StringName(GameState.branch_ativa)


func branch_existe(nome: StringName) -> bool:
	return GameState.branch_existe(String(nome))


## Dados REAIS da convergência para o registro final: o commit de merge e as duas linhas
## que foram integradas ({} se o merge ainda não aconteceu).
##   { "merge": commit, "linha_main": [commits só de main], "linha_vida": [commits só de vida] }
func dados_convergencia() -> Dictionary:
	var merge := GameState.obter_commit_de_merge(String(BRANCH_MAIN), String(BRANCH_VIDA))
	if merge.is_empty():
		return {}
	var pais := GameState.pais_de(merge)
	return {
		"merge": merge,
		"linha_main": GameState.commits_sem(pais[0], pais[1]),
		"linha_vida": GameState.commits_sem(pais[1], pais[0]),
	}


## Libera no terminal exatamente os comandos de `lista` (+ help, sempre livre). Usa o
## mecanismo de liberação progressiva que já existe no GameState.
func publicar_comandos(lista: Array[String]) -> void:
	GameState.liberacao_progressiva = true
	GameState.comandos_liberados = lista
	GameState.comandos_atualizados.emit()


# --- Estado do mundo de cada realidade (em branches[x].mundo) ------------------------------
## Referência viva do dicionário da realidade, ou {} se a branch ainda não existe.
func mundo_de(branch: StringName) -> Dictionary:
	return GameState.obter_mundo_branch(String(branch))


func guardar_mundo(branch: StringName, chave: String, valor: Variant) -> void:
	GameState.definir_mundo_branch(String(branch), chave, valor)


# --- Internos -------------------------------------------------------------------------------
func _restaurar_exploracao() -> void:
	for nome in PERSISTENCIA:
		if mundo_de(PERSISTENCIA[nome][0]).get(PERSISTENCIA[nome][1], false):
			_flags[nome] = true


## Recalcula todas as flags derivadas a partir do estado REAL do GameState.
func _sincronizar_derivadas() -> void:
	var convergiu := not GameState.obter_commit_de_merge(String(BRANCH_MAIN), String(BRANCH_VIDA)).is_empty()
	var divergiu_vida := not GameState.commits_exclusivos(String(BRANCH_VIDA), String(BRANCH_MAIN)).is_empty()
	var divergiu_main := not GameState.commits_exclusivos(String(BRANCH_MAIN), String(BRANCH_VIDA)).is_empty()
	_sincronizando = true
	definir(LOG_CONSULTADO, mundo_de(BRANCH_MAIN).get("log_consultado", false))
	definir(BRANCH_CRIADA, branch_existe(BRANCH_VIDA))
	definir(NA_VIDA_ALTERNATIVA, branch_ativa() == BRANCH_VIDA)
	definir(COMMIT_VIDA, convergiu or divergiu_vida)
	definir(COMMIT_MAIN, convergiu or divergiu_main)
	definir(CONVERGENCIA_CONCLUIDA, convergiu)
	_sincronizando = false


func _on_git_branch_criada(nome: String, _commit_id: String) -> void:
	_sincronizar_derivadas()
	branch_criada.emit(StringName(nome))


func _on_git_branch_ativa_mudou(anterior: String, nova: String) -> void:
	_sincronizar_derivadas()
	branch_ativa_mudou.emit(StringName(anterior), StringName(nova))


func _on_git_commit_realizado(_commit: Dictionary) -> void:
	_sincronizar_derivadas()


func _on_git_merge_realizado(_origem: String, _destino: String, _commit_id: String, _ff: bool) -> void:
	_sincronizar_derivadas()


func _on_git_log_consultado(_branch: String) -> void:
	# Fato não derivável do grafo: fica guardado no mundo de main (sobrevive ao reload).
	guardar_mundo(BRANCH_MAIN, "log_consultado", true)
	_sincronizar_derivadas()
