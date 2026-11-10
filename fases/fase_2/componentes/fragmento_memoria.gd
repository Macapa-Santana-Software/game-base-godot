class_name FragmentoMemoria extends ZonaInteracao
## Fragmento de memória OPCIONAL: um achado do cenário que acrescenta uma pequena informação
## sobre os Codex. Interagir mostra o texto (`mensagem`, no HUD) e pode ser repetido.
##
## A PRIMEIRA leitura é persistida em `branches[realidade].mundo["fragmentos"]` (a realidade
## vem da AreaFase2 pai), então depois de uma derrota ou reload o fragmento já nasce "lido":
## o brilho do `visual` fica apagado e `lido` não é emitido de novo (o Eidolon não repete a
## reação). Não define flag nem libera nada: não é caminho crítico.
##
## PLACEHOLDER visual: o `visual` é um prop de cor lisa, substituível por arte.

const GRUPO := &"fragmento_fase2"
const BRILHO_LIDO := 0.35

## Emitido só na primeira leitura de verdade (nunca ao restaurar o estado salvo).
signal lido(id: StringName, texto: String)

@export var id_fragmento: StringName = &""
## Nó (relativo a esta zona) que brilha enquanto não foi lido.
@export var visual: NodePath = NodePath()

var realidade: String = ""
var _ja_lido: bool = false


func _enter_tree() -> void:
	add_to_group(GRUPO)


func _ready() -> void:
	super()
	var no := get_parent()
	while no:
		if no is AreaFase2:
			realidade = (no as AreaFase2).realidade
			break
		no = no.get_parent()
	if Engine.is_editor_hint():
		return
	var progresso := ProgressoFase2.de(self)
	if progresso and String(id_fragmento) in progresso.mundo_de(StringName(realidade)).get("fragmentos", []):
		_marcar_lido(false)


func _aplicar_efeitos() -> void:
	if mensagem != "":
		MensagemHud.mostrar_em(self, mensagem, 3)
	if not _ja_lido:
		_marcar_lido(true)


func _marcar_lido(primeira_vez: bool) -> void:
	_ja_lido = true
	var brilho := get_node_or_null(visual) as CanvasItem
	if brilho:
		brilho.modulate.a = BRILHO_LIDO
	if not primeira_vez:
		return
	var progresso := ProgressoFase2.de(self)
	if progresso:
		var lista: Array = progresso.mundo_de(StringName(realidade)).get("fragmentos", []).duplicate()
		lista.append(String(id_fragmento))
		progresso.guardar_mundo(StringName(realidade), "fragmentos", lista)
	lido.emit(id_fragmento, mensagem)
