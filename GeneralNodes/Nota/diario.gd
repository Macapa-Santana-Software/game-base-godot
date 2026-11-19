extends Node
## Autoload `Diario`: guarda quais notas da história o jogador já leu e abre a tela de leitura.
##
## - `ler(id, dados)`: abre uma nota (chamado pelo nó `Nota` ao interagir) e a registra como lida.
## - `abrir_diario()`: abre a lista de tudo o que já foi lido (usado pelo menu de pausa).
## - As notas lidas ficam salvas em `user://diario.json`, então sobrevivem a trocar de fase e a
##   fechar o jogo. `limpar()` apaga tudo (novo jogo / testes).
##
## O Diário NÃO mexe no repositório Git nem no GameState: é só leitura de história.
## Reações da história a uma nota (ex.: o Eidolon comentar) escutam o sinal `nota_lida`.

## Emitido toda vez que uma nota é aberta. `primeira_vez` é true só na primeira leitura de verdade.
signal nota_lida(id: StringName, primeira_vez: bool)
## A lista de notas lidas mudou.
signal diario_mudou
## A tela de leitura/lista foi fechada.
signal diario_fechado

const ARQUIVO := "user://diario.json"
const Catalogo := preload("res://GeneralNodes/Nota/notas_historia.gd")
const UIScript := preload("res://GeneralNodes/Nota/diario_ui.gd")

## false nos testes: não lê nem grava o arquivo do jogador.
var persistir: bool = true

var _lidas: Array[StringName] = []
## MARCA NO MAPA ("já li esta nota", ícone translúcido com visto). Separada do Diário:
##  - `_marcadas`: confirmadas (a fase foi concluída). Nunca mais somem.
##  - `_marcadas_tentativa`: lidas na tentativa atual da fase. Se o jogador morre, são descartadas
##    (a fase recomeça do zero e a nota volta a aparecer não lida); ao concluir a fase viram definitivas.
## O Diário (`_lidas`) não é afetado por nada disso: quem leu, leu.
var _marcadas: Array[StringName] = []
var _marcadas_tentativa: Array[StringName] = []
## Notas definidas só na cena (fora do catálogo): guardamos uma cópia para o Diário poder reexibi-las.
var _copias: Dictionary = {}
var _ui: UIScript = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_carregar()


func foi_lida(id: StringName) -> bool:
	return id in _lidas


## A nota deve aparecer como "lida" no mapa?
func foi_marcada(id: StringName) -> bool:
	return id in _marcadas or id in _marcadas_tentativa


## O jogador morreu: as notas lidas nesta tentativa voltam a aparecer não lidas no mapa.
func descartar_tentativa() -> void:
	if _marcadas_tentativa.is_empty():
		return
	_marcadas_tentativa.clear()
	diario_mudou.emit()


## A fase foi concluída: as marcas da tentativa viram definitivas.
func confirmar_tentativa() -> void:
	if _marcadas_tentativa.is_empty():
		return
	for id in _marcadas_tentativa:
		if not id in _marcadas:
			_marcadas.append(id)
	_marcadas_tentativa.clear()
	_salvar()
	diario_mudou.emit()


func total_lidas() -> int:
	return _lidas.size()


func ids_lidas() -> Array[StringName]:
	return _lidas.duplicate()


## true enquanto a tela de leitura/lista está aberta.
func ocupado() -> bool:
	return _ui != null and is_instance_valid(_ui) and _ui.esta_aberto()


## Dados completos de uma nota (catálogo primeiro; senão a cópia guardada). {} se não existir.
func dados_de(id: StringName) -> Dictionary:
	var info: Dictionary = Catalogo.obter(id)
	if info.is_empty():
		info = _copias.get(id, {})
	return info


## Abre a nota `id` e a marca como lida. `dados` é o texto vindo da cena, usado só se `id` não
## estiver no catálogo. Devolve true se foi a PRIMEIRA leitura; false se já tinha sido lida
## (ou se a nota não tem texto algum, caso em que também avisa no Output).
func ler(id: StringName, dados: Dictionary = {}) -> bool:
	var info: Dictionary = Catalogo.obter(id)
	if info.is_empty():
		info = dados
	if info.is_empty() or String(info.get("texto", "")).strip_edges() == "":
		push_warning("Diario: a nota '%s' não tem texto (nem no catálogo, nem na cena)." % id)
		return false

	var primeira := not foi_lida(id)
	if primeira:
		_lidas.append(id)
		if Catalogo.obter(id).is_empty():
			_copias[id] = dados.duplicate()
		_salvar()
	if not foi_marcada(id):
		_marcadas_tentativa.append(id)
	if primeira or _marcadas_tentativa.has(id):
		diario_mudou.emit()

	_garantir_ui().abrir_nota(info)
	nota_lida.emit(id, primeira)
	return primeira


## Abre a lista com todas as notas já lidas.
func abrir_diario() -> void:
	_garantir_ui().abrir_lista(entradas())


func fechar() -> void:
	if ocupado():
		_ui.fechar()


## As notas lidas, na ordem do Diário (por fase; dentro da fase, na ordem em que foram achadas).
## Cada item: o dicionário da nota + "id".
func entradas() -> Array[Dictionary]:
	var itens: Array[Dictionary] = []
	for ordem in range(_lidas.size()):
		var id := _lidas[ordem]
		var info := dados_de(id).duplicate()
		if info.is_empty():
			continue
		info["id"] = id
		info["_ordem"] = ordem
		itens.append(info)
	itens.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var fa := int(a.get("fase", 0))
		var fb := int(b.get("fase", 0))
		if fa != fb:
			return fa < fb
		return int(a["_ordem"]) < int(b["_ordem"]))
	return itens


## Apaga todas as notas lidas (novo jogo, testes).
func limpar() -> void:
	_lidas.clear()
	_marcadas.clear()
	_marcadas_tentativa.clear()
	_copias.clear()
	_salvar()
	diario_mudou.emit()


## Cópia do estado, para um teste poder restaurar o diário do jogador depois.
func estado() -> Dictionary:
	return {"lidas": _lidas.duplicate(), "copias": _copias.duplicate(true),
		"marcadas": _marcadas.duplicate(), "tentativa": _marcadas_tentativa.duplicate()}


func restaurar(estado_salvo: Dictionary) -> void:
	_lidas.clear()
	for id in estado_salvo.get("lidas", []):
		_lidas.append(StringName(id))
	_marcadas.clear()
	for id in estado_salvo.get("marcadas", []):
		_marcadas.append(StringName(id))
	_marcadas_tentativa.clear()
	for id in estado_salvo.get("tentativa", []):
		_marcadas_tentativa.append(StringName(id))
	# As chaves viram StringName (o JSON as devolve como String).
	_copias = {}
	var copias_salvas: Dictionary = estado_salvo.get("copias", {})
	for id in copias_salvas:
		_copias[StringName(id)] = copias_salvas[id].duplicate(true)
	diario_mudou.emit()


## O estado como texto JSON (é o conteúdo do arquivo salvo). Os ids viram String.
func como_json() -> String:
	var ids: Array[String] = []
	for id in _lidas:
		ids.append(String(id))
	var copias: Dictionary = {}
	for id in _copias:
		copias[String(id)] = _copias[id]
	var marcadas: Array[String] = []
	for id in _marcadas:
		marcadas.append(String(id))
	return JSON.stringify({"lidas": ids, "copias": copias, "marcadas": marcadas})


func _garantir_ui() -> UIScript:
	if _ui == null or not is_instance_valid(_ui):
		_ui = UIScript.new()
		_ui.fechado.connect(func() -> void: diario_fechado.emit())
		add_child(_ui)
	return _ui


func _salvar() -> void:
	if not persistir:
		return
	var arquivo := FileAccess.open(ARQUIVO, FileAccess.WRITE)
	if arquivo == null:
		push_warning("Diario: não foi possível salvar em %s." % ARQUIVO)
		return
	arquivo.store_string(como_json())


func _carregar() -> void:
	if not persistir or not FileAccess.file_exists(ARQUIVO):
		return
	var texto := FileAccess.get_file_as_string(ARQUIVO)
	var lido: Variant = JSON.parse_string(texto)
	if lido is Dictionary:
		restaurar(lido)
