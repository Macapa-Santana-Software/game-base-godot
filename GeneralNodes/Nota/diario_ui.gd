extends CanvasLayer
## Tela do Diário, montada por código (como o Manual do Sistema). Dois modos:
##   LEITURA  uma nota só, centralizada: aparece quando o jogador lê uma nota no mundo.
##   LISTA    todas as notas já lidas (esquerda) e o texto da selecionada (direita): abre pelo menu de pausa.
##
## Pausa o jogo enquanto está aberta e devolve o estado anterior ao fechar (se o jogo já estava
## pausado, como no menu de pausa, continua pausado). Esc fecha; na leitura, a tecla de
## interagir também. Quem abre é o autoload `Diario`; esta tela não conhece o Diário (só recebe dados).

signal fechado

const TEMA := preload("res://GeneralNodes/UI/tema_santuario.tres")
const FONTE := preload("res://Dialogo/MonospacePixel.ttf")
const Catalogo := preload("res://GeneralNodes/Nota/notas_historia.gd")

const LARGURA := 400.0
const ALTURA := 236.0
const LARGURA_LISTA := 132.0
const COR_CIANO := Color("36D6E9")
const COR_TEXTO := Color("E4F2F5")
const COR_DISCRETA := Color(0.357, 0.408, 0.498)
const ACAO_INTERAGIR := &"interagir_porta"

enum Modo { LISTA, LEITURA }

var _aberto: bool = false
var _modo: Modo = Modo.LEITURA
var _pausado_antes: bool = false
var _entradas: Array[Dictionary] = []

var _raiz: Control
var _cabecalho: Label
var _coluna_lista: VBoxContainer
var _lista: ItemList
var _titulo_nota: Label
var _meta: Label
var _texto: RichTextLabel
var _dica: Label


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	_montar()
	hide()


func esta_aberto() -> bool:
	return _aberto


## Mostra UMA nota (modo leitura). `dados`: titulo, autor, tipo, fase, texto.
func abrir_nota(dados: Dictionary) -> void:
	_mostrar_dados(dados)
	_abrir(Modo.LEITURA)
	_texto.grab_focus()


## Mostra a lista de notas lidas (modo lista). `entradas`: dados de cada nota, já ordenados.
func abrir_lista(entradas: Array[Dictionary]) -> void:
	_entradas = entradas
	_lista.clear()
	for entrada in _entradas:
		var fase := int(entrada.get("fase", 0))
		var prefixo := "F%d  " % fase if fase > 0 else ""
		var indice := _lista.add_item(prefixo + String(entrada.get("titulo", "(sem título)")))
		_lista.set_item_custom_fg_color(indice, Catalogo.tipo(String(entrada.get("tipo", "carta")))["cor"])
	_abrir(Modo.LISTA)
	if _entradas.is_empty():
		_mostrar_vazio()
	else:
		_lista.select(0)
		_mostrar_dados(_entradas[0])
	_lista.grab_focus()


func fechar() -> void:
	if not _aberto:
		return
	_aberto = false
	hide()
	get_tree().paused = _pausado_antes
	fechado.emit()


func _input(event: InputEvent) -> void:
	if not _aberto:
		return
	var fechar_agora := event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_cancel")
	if _modo == Modo.LEITURA and event.is_action_pressed(ACAO_INTERAGIR):
		fechar_agora = true
	if fechar_agora:
		fechar()
		get_viewport().set_input_as_handled()


func _abrir(modo: Modo) -> void:
	if not _aberto:
		_pausado_antes = get_tree().paused
		get_tree().paused = true
		_aberto = true
	_modo = modo
	_coluna_lista.visible = modo == Modo.LISTA
	_cabecalho.text = ("DIÁRIO  (%d)" % _entradas.size()) if modo == Modo.LISTA else "NOTA"
	_dica.text = "Setas: escolher  ·  Esc: fechar" if modo == Modo.LISTA \
			else "[%s] ou Esc: fechar  ·  Setas: rolar" % _nome_tecla(ACAO_INTERAGIR)
	show()


func _mostrar_dados(dados: Dictionary) -> void:
	var tipo := Catalogo.tipo(String(dados.get("tipo", "carta")))
	var cor: Color = tipo["cor"]
	_titulo_nota.text = String(dados.get("titulo", ""))
	_titulo_nota.add_theme_color_override("font_color", cor)
	var partes: Array[String] = [String(tipo["rotulo"])]
	var autor := String(dados.get("autor", ""))
	if autor != "":
		partes.append("de " + autor)
	var fase := int(dados.get("fase", 0))
	if fase > 0:
		partes.append("Fase %d" % fase)
	_meta.text = "  ·  ".join(partes)
	_texto.text = String(dados.get("texto", ""))
	_texto.scroll_to_line(0)


func _mostrar_vazio() -> void:
	_titulo_nota.text = "Nenhuma nota ainda"
	_titulo_nota.add_theme_color_override("font_color", COR_DISCRETA)
	_meta.text = ""
	_texto.text = "[color=#5B6880]Cartas, placas e registros espalhados pelas fases ficam guardados aqui depois que você os lê.[/color]"


func _on_item_selecionado(indice: int) -> void:
	if indice >= 0 and indice < _entradas.size():
		_mostrar_dados(_entradas[indice])


func _nome_tecla(acao: StringName) -> String:
	for evento in InputMap.action_get_events(acao):
		if evento is InputEventKey:
			return (evento as InputEventKey).as_text_physical_keycode()
	return "?"


func _montar() -> void:
	_raiz = Control.new()
	_raiz.theme = TEMA
	add_child(_raiz)
	_raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var fundo := ColorRect.new()
	fundo.color = Color(0.027, 0.043, 0.086, 0.88)
	_raiz.add_child(fundo)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var centro := CenterContainer.new()
	_raiz.add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var painel := PanelContainer.new()
	painel.custom_minimum_size = Vector2(LARGURA, ALTURA)
	centro.add_child(painel)

	var margem := MarginContainer.new()
	for lado in ["left", "top", "right", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 8)
	painel.add_child(margem)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 5)
	margem.add_child(coluna)

	_cabecalho = _criar_label(10, COR_CIANO)
	_cabecalho.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(_cabecalho)
	coluna.add_child(HSeparator.new())

	var corpo := HBoxContainer.new()
	corpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corpo.add_theme_constant_override("separation", 8)
	coluna.add_child(corpo)

	_coluna_lista = VBoxContainer.new()
	_coluna_lista.custom_minimum_size = Vector2(LARGURA_LISTA, 0)
	corpo.add_child(_coluna_lista)
	_lista = ItemList.new()
	_lista.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lista.add_theme_font_override("font", FONTE)
	_lista.add_theme_font_size_override("font_size", 8)
	_lista.item_selected.connect(_on_item_selecionado)
	_coluna_lista.add_child(_lista)

	var leitura := VBoxContainer.new()
	leitura.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	leitura.add_theme_constant_override("separation", 3)
	corpo.add_child(leitura)

	_titulo_nota = _criar_label(10, COR_CIANO)
	_titulo_nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	leitura.add_child(_titulo_nota)
	_meta = _criar_label(8, COR_DISCRETA)
	leitura.add_child(_meta)
	leitura.add_child(HSeparator.new())

	_texto = RichTextLabel.new()
	_texto.bbcode_enabled = true
	_texto.scroll_active = true
	_texto.focus_mode = Control.FOCUS_ALL
	_texto.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_texto.add_theme_color_override("default_color", COR_TEXTO)
	for fonte in ["normal_font", "bold_font", "italics_font", "bold_italics_font", "mono_font"]:
		_texto.add_theme_font_override(fonte, FONTE)
		_texto.add_theme_font_size_override(fonte + "_size", 8)
	leitura.add_child(_texto)

	_dica = _criar_label(8, COR_DISCRETA)
	_dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(_dica)


func _criar_label(tamanho: int, cor: Color) -> Label:
	var rotulo := Label.new()
	rotulo.add_theme_font_override("font", FONTE)
	rotulo.add_theme_font_size_override("font_size", tamanho)
	rotulo.add_theme_color_override("font_color", cor)
	return rotulo
