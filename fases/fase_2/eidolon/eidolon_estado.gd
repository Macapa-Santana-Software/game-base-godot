class_name EidolonEstado extends RefCounted
## Estado narrativo do Eidolon (Fase 2), guardado em `GameState.progresso_tutoria` sob um
## NAMESPACE próprio: as chaves da Fase 1 (e as do Manual) não são tocadas.
##
## Persistência:
##   * recarga por derrota (reload_current_scene): o GameState sobrevive, então o estado também;
##   * `GameState.reset_fase()` substitui o dicionário inteiro: o namespace some. Isso só
##     acontece ao fim da Fase 1 (antes de a Fase 2 começar) e em `resetar_repositorio()`
##     (novo jogo), que é exatamente quando a narrativa deve recomeçar. `dados()` recria o
##     namespace vazio quando ele não existe.
##
## É um conjunto de funções estáticas sobre esse dicionário (sem estado próprio), então não há
## nada para "perder" quando a cena é recriada.

const CHAVE := "eidolon_fase_2"
const VERSAO := 1

## Etapas do arco do Eidolon (só avançam):
const ETAPA_INICIAL := 0
const ETAPA_CERTEZA := 1       # Área 1
const ETAPA_DESCONFORTO := 2   # Área 2
const ETAPA_DUVIDA := 3        # Área 3
const ETAPA_CONFLITO := 4      # Área 4
const ETAPA_REINTERPRETACAO := 5  # Área 5


static func dados() -> Dictionary:
	var tutoria := GameState.progresso_tutoria
	var atual: Variant = tutoria.get(CHAVE)
	if not (atual is Dictionary) or atual.get("versao", 0) != VERSAO:
		tutoria[CHAVE] = _novo()
	return tutoria[CHAVE]


static func _novo() -> Dictionary:
	return {
		"versao": VERSAO,
		"ditas": {},            # id da fala -> true (falas únicas já ditas)
		"etapa": ETAPA_INICIAL, # etapa do arco
		"notas_pendentes": [],  # ids cujas notas "Em Git:" ainda não foram mostradas no terminal
	}


static func ja_disse(id: StringName) -> bool:
	return dados()["ditas"].has(String(id))


static func marcar_dita(id: StringName) -> void:
	dados()["ditas"][String(id)] = true


static func etapa() -> int:
	return dados()["etapa"]


## A etapa só avança, nunca volta (o arco do Eidolon não retrocede).
static func avancar_etapa(nova: int) -> void:
	var d := dados()
	d["etapa"] = maxi(d["etapa"], nova)


# --- Evidências -------------------------------------------------------------------------------------
## O arco do Eidolon avança por EVIDÊNCIAS concretas encontradas pelo jogador (fragmentos,
## diferenças entre as realidades...), não por tempo nem por um único evento. Cada evidência
## conta uma vez. Com EVIDENCIAS_PARA_DUVIDA ou mais, ele passa do desconforto à dúvida.
const EVIDENCIAS_PARA_DUVIDA := 2


static func evidencias() -> Array:
	var d := dados()
	if not d.has("evidencias"):
		d["evidencias"] = []
	return d["evidencias"]


## Registra uma evidência (ignora repetida) e devolve quantas existem. Avança a etapa do arco.
static func registrar_evidencia(id: StringName) -> int:
	var lista := evidencias()
	if String(id) not in lista:
		lista.append(String(id))
	if lista.size() >= EVIDENCIAS_PARA_DUVIDA:
		avancar_etapa(ETAPA_DUVIDA)
	return lista.size()


# --- Dicas graduais (DicasEidolon) ------------------------------------------------------------------
## Subdicionário das dicas, criado sob demanda (estados da Etapa 1 continuam válidos):
##   etapa_atual          id da etapa em que o jogador está
##   sem_ajuda_seguidas   etapas concluídas em sequência sem ajuda nem falhas de ordem/compreensão
##   ultimo_pesado        a última etapa concluída exigiu o nível 3 ou 2+ falhas conceituais
##   etapas               id da etapa -> registro (ver registro_dica)
static func dicas() -> Dictionary:
	var d := dados()
	if not d.has("dicas"):
		d["dicas"] = {"etapa_atual": "", "sem_ajuda_seguidas": 0, "ultimo_pesado": false, "etapas": {}}
	return d["dicas"]


## Registro de uma etapa: nível mais alto já dado, falhas por categoria, dicas já ditas,
## quantas foram automáticas, última falha (para um pedido de ajuda explicar ESSA falha).
static func registro_dica(etapa: StringName) -> Dictionary:
	var etapas: Dictionary = dicas()["etapas"]
	if not etapas.has(String(etapa)):
		etapas[String(etapa)] = {
			"nivel": 0, "falhas": {}, "ditas": [], "automaticas": 0,
			"concluida": false, "ultima_falha": {},
		}
	return etapas[String(etapa)]


static func adicionar_nota_pendente(id: StringName) -> void:
	var pendentes: Array = dados()["notas_pendentes"]
	if String(id) not in pendentes:
		pendentes.append(String(id))


static func remover_nota_pendente(id: StringName) -> void:
	dados()["notas_pendentes"].erase(String(id))


static func notas_pendentes() -> Array:
	return dados()["notas_pendentes"]
